#' @title Get stopwords table
#'
#' @description Get stopwords table from mercadoedu's database(AWS RDS).
#'
#' @param con A database connection;
#'
#' @param tbl_name A string of table name in database;\strong{
#' ```
#' Default: "model_stopwords"
#' ```
#' }
#'
#' @return The stopwords table from database in data frame format.
#'
#' @details Sometimes you will have to reconnect to the database.
#'
#' @examples
#' \dontrun{
#'   if(interactive()){
#'     odbc::odbc() |>
#'       DBI::dbConnect("Amazon RDS Model",
#'                      timeout = 0) |>
#'       mercadoedu.tc::get_stopwords()
#'   }
#' }
#'
#' @seealso
#'  \code{\link[dplyr]{tbl}},\code{\link[dplyr]{arrange}},\code{\link[dplyr]{collect}}
#'
#' @rdname get_stopwords
#'
#' @export
#'
#' @importFrom dplyr tbl arrange collect
get_stopwords <- function(con,
                          tbl_name = "model_stopwords") {
  ### Stopwords table ####
  con |>
    dplyr::tbl(tbl_name) |>
    dplyr::arrange(words) |>
    dplyr::collect()
}

#' @title Get coursealias table
#'
#' @description Get coursealias table from mercadoedu's database(AWS Redshift).
#'
#' @param con A database connection;
#'
#' @param tbl_name A string of table name in database;\strong{
#' ```
#' Default: "coursealias"
#' ```
#' }
#'
#' @return The coursealias table from database in data frame format.
#'
#' @details Sometimes you will have to reconnect to the database.
#'
#' @examples
#' \dontrun{
#'   if(interactive()){
#'     odbc::odbc() |>
#'       DBI::dbConnect("Amazon RDS Model",
#'                      timeout = 0) |>
#'       mercadoedu.tc::get_csalias()
#'   }
#' }
#'
#' @seealso
#'  \code{\link[dplyr]{tbl}},\code{\link[dplyr]{rename}},\code{\link[dplyr]{filter}},\code{\link[dplyr]{arrange}},\code{\link[dplyr]{collect}}
#'
#' @rdname get_csalias
#'
#' @export
#'
#' @importFrom dplyr tbl rename filter arrange collect
get_csalias <- function(con,
                        tbl_name = "coursealias") {
  ### coursealias table(labels from mercadoedu) ####
  con |>
    dplyr::tbl(tbl_name) |>
    dplyr::rename("alias_id" = id) |>
    dplyr::filter(name != "N/C") |>
    dplyr::arrange(name) |>
    dplyr::collect()
}

#' @title Get course table
#'
#' @description Get course table from mercadoedu's database(AWS Redshift).
#'
#' @param con A database connection;
#'
#' @param tbl_name A string of table name in database;\strong{
#' ```
#' Default: "course"
#' ```
#' }
#'
#' @return The course table from database in data frame format.
#'
#' @details Sometimes you will have to reconnect to the database.
#'
#' @examples
#' \dontrun{
#'   if(interactive()){
#'     odbc::odbc() |>
#'       DBI::dbConnect("Amazon RDS Model",
#'                      timeout = 0) |>
#'       mercadoedu.tc::get_cs()
#'   }
#' }
#'
#' @seealso
#'  \code{\link[dplyr]{tbl}},\code{\link[dplyr]{select}},\code{\link[dplyr]{arrange}},\code{\link[dplyr]{collect}}
#'
#' @rdname get_cs
#'
#' @export
#'
#' @importFrom dplyr tbl select arrange collect
get_cs <- function(con,
                   tbl_name = "course") {
  ### course table(censo data) ####
  con |>
    dplyr::tbl(tbl_name) |>
    dplyr::select(name,
                  name_detail,
                  alias_id,
                  "cs_id" = id) |>
    dplyr::arrange(alias_id) |>
    dplyr::collect()
}

#' @title Get pricing_course table
#'
#' @description Get pricing_course table from mercadoedu's database(AWS Redshift).
#'
#' @param con A database connection;
#'
#' @param tbl_name A string of table name in database;\strong{
#' ```
#' Default: "pricing_course"
#' ```
#' }
#'
#' @return The pricing_course table from database in data frame format.
#'
#' @details Sometimes you will have to reconnect to the database.
#'
#' @examples
#' \dontrun{
#'   if(interactive()){
#'     odbc::odbc() |>
#'       DBI::dbConnect("Amazon RDS Model",
#'                      timeout = 0) |>
#'       mercadoedu.tc::get_pc()
#'   }
#' }
#'
#' @seealso
#'  \code{\link[dplyr]{tbl}},\code{\link[dplyr]{select}},\code{\link[dplyr]{filter}},\code{\link[dplyr]{distinct}},\code{\link[dplyr]{arrange}},\code{\link[dplyr]{collect}}
#'
#' @rdname get_pc
#'
#' @export
#'
#' @importFrom dplyr tbl select filter distinct arrange collect
get_pc <- function(con,
                   tbl_name = "pricing_course") {
  ### pricing_course table(labels from quarentine) ####
  con |>
    dplyr::tbl(tbl_name) |>
    dplyr::select("pc_discr_id" = id,
                  alias_id,
                  name_detail = name,
                  "pc_human_match" = human_match) |>
    dplyr::filter(!is.na(alias_id)) |>
    dplyr::distinct() |>
    dplyr::arrange(alias_id) |>
    dplyr::collect()
}

#' @title Get fromtokey table
#'
#' @description Get fromtokey table with alias_id(merged) from mercadoedu's database(AWS Redshift).
#'
#' @param con A database connection;
#'
#' @param tbl_name A string of table name in database;\strong{
#' ```
#' Default: "me_v3_pricing_fromtokey"
#' ```
#' }
#'
#' @return The fromtokey table from database in data frame format.
#'
#' @details Sometimes you will have to reconnect to the database.
#'
#' @examples
#' \dontrun{
#'   if(interactive()){
#'     odbc::odbc() |>
#'       DBI::dbConnect("Amazon RDS Model",
#'                      timeout = 0) |>
#'       mercadoedu.tc::get_ftk()
#'   }
#' }
#'
#' @seealso
#'  \code{\link[dplyr]{tbl}},\code{\link[dplyr]{filter}},\code{\link[dplyr]{select}},\code{\link[dplyr]{distinct}},\code{\link[dplyr]{arrange}},\code{\link[dplyr]{collect}},\code{\link[dplyr]{mutate-joins}}
#'
#' @rdname get_ftk
#'
#' @export
#'
#' @importFrom dplyr tbl filter select distinct arrange collect left_join
get_ftk <- function(con,
                    tbl_name = "me_v3_pricing_fromtokey") {
  ### fromtokey table(course names from robots) ####
  con |>
    dplyr::tbl(tbl_name) |>
    dplyr::filter(discr == "pricing_course_level_1",
                  arg != "n/c",
                  arg != "-new-") |>
    dplyr::select("name_detail" = arg,
                  "ftk_robot_id" = robot_id,
                  "ftk_discr_id" = discr_id) |>
    dplyr::distinct() |>
    dplyr::arrange(ftk_discr_id) |>
    dplyr::collect() |>
    dplyr::left_join(con |>
                       get_pc() |>
                       dplyr::select(alias_id,
                                     pc_discr_id) |>
                       dplyr::arrange(pc_discr_id),
                     by = c("ftk_discr_id" = "pc_discr_id")) |>
    dplyr::filter(!is.na(alias_id)) |>
    dplyr::arrange(alias_id)
}
