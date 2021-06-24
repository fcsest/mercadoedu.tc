#' @title Correct wrong characters
#'
#' @description Correct some characters errors with str_replace_all.
#'
#' @param string A vector character;
#'
#' @return A string corrected.
#'
#' @details Some strings are wrong in mercadoedu databases, so we replace this characters by correct characters.
#'
#' @examples
#' \dontrun{
#'   if(interactive()){
#'     dplyr::mutate(data,
#'                   "correct_name" = name |>
#'                                    correct_strings())
#'   }
#' }
#' @seealso
#'  \code{\link[stringr]{str_replace_all}}
#'
#' @rdname correct_strings
#'
#' @export
#'
#' @importFrom stringr str_replace_all
correct_wrong_chars <- function(string) {
  string |>
    str_replace_all(r"(\u00e3\u00aa)", r"(\u00ea)") |>
    str_replace_all(r"(\u00e3\u00a1)", r"(\u00e1)") |>
    str_replace_all(r"(\u00e3\u00a3)", r"(\u00e3)") |>
    str_replace_all(r"(\u00e3\u00a7)", r"(\u00e7)") |>
    str_replace_all(r"(\u00e3\u00a9)", r"(\u00e9)") |>
    str_replace_all(r"(\u00e3\u00ad)", r"(\u00ed)") |>
    str_replace_all(r"(\u00e3\u00ba)", r"(\u00fa)") |>
    str_replace_all(r"(\u00e3\u00b3)", r"(\u00f3)") |>
    str_replace_all("\\(tecnologia\\)", " ") |>
    str_replace_all("alimentosnovo", "alimentos") |>
    str_replace_all(r"(superiorgest\u00e3o)", r"(superior gest\u00e3o)") |>
    str_replace_all("superior de tecnologia", " ")
}
