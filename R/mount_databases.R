#' @title Mount frankenstein table
#'
#' @description Join and append multiples table from mercadoedu's database.
#'
#' @param con A database connection;
#'
#' @param stopwords_con A database connection of stopwords table;
#'
#' #' @param stopwords_tbl_name A string of table name in database;\strong{
#' ```
#' Default: "model_stopwords"
#' ```
#' }
#'
#' @param checks A logical that defines when to check tables;\strong{
#' ```
#' Default: FALSE
#' ```
#' }
#'
#' @return A frankenstein table from mercadoedu's database.
#'
#' @details This function adds the same stopwords inputted but without accent.
#'
#' @examples
#' \dontrun{
#'   if(interactive()){
#'     frankenstein <- odbc::odbc() |>
#'       DBI::dbConnect("Amazon RDS mercadoedu",
#'                      timeout = 0) |>
#'         mercadoedu.tc::mount_frankenstein(stopwords_con = odbc::odbc() |>
#'                                             DBI::dbConnect("Amazon RDS Model",
#'                                                            timeout = 0))
#'  }
#' }
#'
#' @seealso
#'  \code{\link[dplyr]{filter-joins}},\code{\link[dplyr]{mutate-joins}},\code{\link[dplyr]{select}},\code{\link[dplyr]{mutate}},\code{\link[dplyr]{bind}},\code{\link[dplyr]{arrange}},\code{\link[dplyr]{pull}},\code{\link[dplyr]{reexports}}
#'  \code{\link[stringr]{str_replace}},\code{\link[stringr]{case}},\code{\link[stringr]{str_trim}}
#'  \code{\link[tm]{removeWords}}
#'
#' @rdname mount_frankenstein
#'
#' @export
#'
#' @importFrom FCSUtils ui_start ui_color_warning ui_info ui_step ui_warning ui_info_list
#' @importFrom dplyr anti_join left_join select mutate bind_rows arrange pull everything
#' @importFrom stringr str_replace_all str_to_lower str_squish
#' @importFrom tm removeWords
mount_frankenstein <- function(con,
                               stopwords_con,
                               stopwords_tbl_name = "model_stopwords",
                               checks = FALSE) {
  FCSUtils::ui_start(function_name = "mercadoedu.tc::mount_frankenstein",
                     title = "Mount frankenstein table",
                     description = paste("Mounting the frankenstein table, joining and appending",
                                         "tables from mercadoedu's database:"))

  if (checks) {
    paste("The",
          FCSUtils::ui_color_warning("checks"),
          "parameter was defined as",
          FCSUtils::ui_color_warning("TRUE"),
          ", so...") |>
      FCSUtils::ui_info()

    paste("Checking the coursealias or course tables if there",
          "is a name that is in one and not in the other;") |>
      FCSUtils::ui_step()

    ### IN course(censo) AND NOT IN coursealias(labels from mercadoedu) ####
    anti_cs_csalias <- con |>
      get_cs() |>
      dplyr::anti_join(con |>
                         get_csalias(),
                       by = "alias_id")

    if (nrow(anti_cs_csalias) > 0) {
      FCSUtils::ui_warning("Row(s) that are not in coursealias and are in course table...")
      anti_cs_csalias
    }

    paste("Checking the coursealias or pricing_course tables if there",
          "is a name that is in one and not in the other;") |>
      FCSUtils::ui_step()

    ### IN pricing_course(quarentine) AND NOT IN coursealias(mercadoedu) ####
    anti_pc_csalias <- con |>
      get_pc() |>
      dplyr::anti_join(con |>
                         get_csalias(),
                       by = "alias_id")

    if (nrow(anti_pc_csalias) > 0) {
      FCSUtils::ui_warning("Row(s) that are not in coursealias and are in pricing_course table...")
      anti_pc_csalias
    }

    paste("Checking the coursealias or fromtokey tables if there",
          "is a name that is in one and not in the other;") |>
      FCSUtils::ui_step()

    ### IN fromtokey(course names from robots) AND NOT IN coursealias(mercadoedu) ####
    anti_ftk_csalias <- con |>
      get_ftk() |>
      dplyr::anti_join(con |>
                         get_csalias(),
                       by = "alias_id")

    if (nrow(anti_ftk_csalias) > 0) {
      FCSUtils::ui_warning("Row(s) that are not in coursealias and are in fromtokey table...")
      anti_ftk_csalias
    }
  }

  "course" |>
    c("pricing_course",
      "fromtokey") |>
    FCSUtils::ui_info_list(header = "Joining tables below by alias_id with coursealias table...")

  "coursealias + course" |>
    c("coursealias + pricing_course",
      "coursealias + fromtokey") |>
    FCSUtils::ui_info_list(header = "Appending joined tables below...")

  frank <- con |>
    get_csalias() |>
    dplyr::left_join(con |>
                       get_cs() |>
                       dplyr::select(-name),
                     by = "alias_id") |>
    dplyr::mutate("source" = "course") |>
    dplyr::bind_rows(con |>
                       get_csalias() |>
                       dplyr::left_join(con |>
                                          get_pc(),
                                        by = "alias_id") |>
                       dplyr::mutate("source" = "pricing_course"),
                     con |>
                       get_csalias() |>
                       dplyr::left_join(con |>
                                          get_ftk(),
                                        by = "alias_id") |>
                       dplyr::mutate("source" = "fromtokey")) |>
    dplyr::arrange(alias_id) |>
    dplyr::mutate("clean_name" = name_detail |>
                    correct_wrong_chars() |>
                    stringr::str_replace_all(paste0("([:punct:])|",
                                                    "([:digit:])|",
                                                    "(\\|)|",
                                                    "(\u00aa)|",
                                                    "(\u00ba)|",
                                                    "(\u00b0)"),
                                             " ") |>
                    stringr::str_to_lower(locale = "br") |>
                    tm::removeWords(stopwords_con |>
                                      get_stopwords(tbl_name = stopwords_tbl_name) |>
                                      dplyr::pull(words)) |>
                    stringr::str_squish()) |>
    dplyr::select(alias_id,
                  name,
                  name_detail,
                  clean_name,
                  source,
                  dplyr::everything()) |>
    dplyr::arrange(clean_name,
                   alias_id)

  if (nrow(frank) > 1) {
    "Frankenstein table successfully mounted!!" |>
      FCSUtils::ui_success()

    FCSUtils::ui_end("mercadoedu.tc::mount_frankenstein")

    invisible(frank)
  }
  else {
    paste("The",
          FCSUtils::ui_color_warning("con"),
          "parameter must be a valid connection, test it first;") |>
      c(paste("The",
              FCSUtils::ui_color_warning("stopwords_con"),
              "parameter must be a valid connection too, test it first;"),
        paste("The",
              FCSUtils::ui_color_warning("stopwords_tbl_name"),
              "parameter must be the name of an existing table in the database;")) |>
      FCSUtils::ui_error_list(header = "Something goes wrong, you may have done something wrong:")

    FCSUtils::ui_end("mercadoedu.tc::mount_frankenstein")

    invisible(FALSE)
  }
}

mount_frank_dups <- function(frank_db) {
  ### clean_name blanks ####
  check_blanks <- frank_db |>
    dplyr::filter(clean_name == "" | clean_name == " ")

  if (nrow(check_blanks) > 0) {
    mercadoedu.tc::ui_warning("Frankenstein has normalized names that are blank!!")

    check_blanks
  }

  frank_db |>
    dplyr::select(alias_id,
                  name,
                  name_detail,
                  clean_name) |>
    dplyr::filter(clean_name != "" | clean_name != " ") |>
    dplyr::group_by(clean_name) |>
    dplyr::filter(dplyr::n_distinct(name) > 1) |>
    dplyr::ungroup() |>
    dplyr::arrange(clean_name)
}
