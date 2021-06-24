#' @title Update stopwords table
#'
#' @description Update a stopwords table from database with new stopwords.
#'
#' @param con A database connection;
#'
#' @param stopwords A list/vector of strings;
#'
#' @param db_tbl_name A string of table name in database;\strong{
#' ```
#' Default: "model_stopwords"
#' ```
#' }
#'
#' @param ptbr_stopwords A logical that defines when to add PT-BR stopwords;\strong{
#' ```
#' Default: TRUE
#' ```
#' }
#'
#' @param append A logical that defines when to append or overwrite;\strong{
#' ```
#' Default: FALSE
#' ```
#' }
#'
#' @return A logical that warnings if stopwords database was updated or not.
#'
#' @details This function adds the same stopwords inputted but without accent.
#'
#' @examples
#' \dontrun{
#'   if(interactive()){
#'     ### Updating a stopwords table of Amazon RDS Model Database####
#'     odbc::odbc() |>
#'       DBI::dbConnect("Amazon RDS Model",
#'                      timeout = 0) |>
#'       mercadoedu.tc::update_stopwords(stopwords = c("abi",
#'                                                     "lins",
#'                                                     "distância",
#'                                                     "presencial",
#'                                                     "semipresencial",
#'                                                     "cidade universitária",
#'                                                     "centro universitário",
#'                                                     "modalidade",
#'                                                     "modalidade ensino"))
#'   }
#' }
#'
#' @seealso
#'  [get_stopwords()]
#'  \code{\link[purrr]{map2}}
#'  \code{\link[stopwords]{stopwords}}
#'  \code{\link[stringr]{str_subset}}, \code{\link[stringr]{str_trim}}
#'  \code{\link[abjutils]{rm_accent}}
#'  \code{\link[dplyr]{filter-joins}}
#'
#' @rdname update_stopwords
#'
#' @export
#'
#' @importFrom purrr map2
#' @importFrom stopwords stopwords
#' @importFrom stringr str_subset str_squish
#' @importFrom abjutils rm_accent
#' @importFrom dplyr anti_join
#' @importFrom FCSUtils ui_color_warning ui_start ui_warning ui_step ui_step_list ui_error ui_error_list ui_end
#' @importFrom odbc dbAppendTable dbWriteTable
update_stopwords <- function(con,
                             stopwords,
                             db_tbl_name = "model_stopwords",
                             ptbr_stopwords = TRUE,
                             append = FALSE) {
  FCSUtils::ui_start(function_name = "mercadoedu.tc::update_stopwords",
                     title = "Updating Stopwords",
                     description = paste("Insert or updating the stopwords table",
                                         "from mercadoedu's database:"))

  ### Save original stopword ####
  original_stopwords <- con |>
    get_stopwords(db_tbl_name) |>
    dplyr::arrange(words)

  ### Append pt_br stopwords if necessary ####
  if (ptbr_stopwords) {
    paste("The",
          FCSUtils::ui_color_warning("ptbr_stopwords"),
          "parameter was defined as",
          FCSUtils::ui_color_warning("TRUE"),
          ", so...") |>
      FCSUtils::ui_info()

    FCSUtils::ui_step("Adding stopwords in PT-BR with the stopwords inputed;")

    ### PT-BR Stopwords and stopwords ####
    sws <- "pt" |>
      rep(3) |>
      c("br") |>
      purrr::map2(.y = "nltk" |>
                    c("snowball",
                      rep("stopwords-iso",
                          2)),
                  stopwords::stopwords) |>
      unlist() |>
      sort() |>
      unique() |>
      stringr::str_subset("(sistema)|(viagem)|(trabalho)|(conselho)|(meio)|(estado)",
                          negate = T) |>
      stringr::str_squish() |>
      append(stopwords) |>
      sort() |>
      unique()
  }
  else {
    paste("The",
          FCSUtils::ui_color_warning("ptbr_stopwords"),
          "parameter was defined as",
          FCSUtils::ui_color_warning("FALSE"),
          ", so...") |>
      FCSUtils::ui_info()

    FCSUtils::ui_step("Sorting and removing duplicate inputed stopwords;")

    sws <- stopwords |>
      sort() |>
      unique()
  }

  c("Adding the same stopwords without accent;",
    "Sorting stopwords;",
    "Removing duplicates;") |>
    FCSUtils::ui_step_list(header = "Creating our stopwords table:")

  ### Stopwords with and without accents in a database ####
  stopwords_df <- data.frame("words" = sws |>
                               abjutils::rm_accent() |>
                               c(sws) |>
                               sort() |>
                               unique())

  ### Append if necessary ####
  if (append) {
    paste("The",
          FCSUtils::ui_color_warning("append"),
          "parameter was defined as",
          FCSUtils::ui_color_warning("TRUE"),
          ", so...") |>
      FCSUtils::ui_info()

    paste("Removing duplicates from our stopwords table from",
          "the mercadoedu's database stopword table;") |>
      c("Appending our stopwords table in stopwords table from mercadoedu's database;") |>
      FCSUtils::ui_step()

    ### Append in database ####
    stopwords_df |>
      dplyr::anti_join(con |>
                         get_stopwords(db_tbl_name),
                       by = "words") |>
      odbc::dbAppendTable(conn = con,
                          name = db_tbl_name,
                          row.names = FALSE)
  }
  else {
    paste("The",
          FCSUtils::ui_color_warning("append"),
          "parameter was defined as",
          FCSUtils::ui_color_warning("FALSE"),
          ", so...") |>
      FCSUtils::ui_info()

    FCSUtils::ui_step("Overwrite the stopwords table from mercadoedu's database;")

    ### Write in database ####
    con |>
      odbc::dbWriteTable(name = db_tbl_name,
                         value = stopwords_df,
                         overwrite = TRUE,
                         row.names = FALSE)
  }

  new_stopwords <- con |>
    get_stopwords(db_tbl_name) |>
    dplyr::arrange(words)

  if (identical(original_stopwords, new_stopwords)) {
    paste("The number of rows is the same, so you might have",
          "forgotten to change something in the",
          FCSUtils::ui_color_warning("stopwords"),
          "...") |>
      FCSUtils::ui_error()

    FCSUtils::ui_end("mercadoedu.tc::update_stopwords")

    invisible(FALSE)
  }
  else if (!identical(original_stopwords, new_stopwords)) {
    "Successfully updated, the stopword table has changed..." |>
      FCSUtils::ui_success()

    FCSUtils::ui_end("mercadoedu.tc::update_stopwords")

    invisible(TRUE)
  }
  else {
    paste("The",
          FCSUtils::ui_color_warning("con"),
          "parameter must be a valid connection, test it first;") |>
      c(paste("The",
               FCSUtils::ui_color_warning("stopwords"),
               "parameter must be a list/vector of strings(list of character vectors);"),
        paste("Check if",
              FCSUtils::ui_color_warning("db_tbl_name"),
              "exists in your database;")) |>
      FCSUtils::ui_error_list(header = "Something goes wrong, you may have done something wrong:")

    FCSUtils::ui_end("mercadoedu.tc::update_stopwords")

    invisible(FALSE)
  }
}
