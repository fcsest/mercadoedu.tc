get_course <- function(name) {
  "http://localhost:5000/course/classifier/'" |>
    paste0(stringr::str_replace_all(name,
                                    " ",
                                    "%"),
           "'") |>
    httr::POST()  |>
    httr::content()  |>
    purrr::chuck("body") |>
    jsonlite::fromJSON()  |>
    data.frame("name_detail" = name)  |>
    dplyr::select("name_detail", dplyr::everything()) |>
    janitor::clean_names()
}

correct_strings <- function(string) {
  string |>
    stringr::str_replace_all(r"(\u00e3\u00aa)", r"(\u00ea)") |>
    stringr::str_replace_all(r"(\u00e3\u00a1)", r"(\u00e1)") |>
    stringr::str_replace_all(r"(\u00e3\u00a3)", r"(\u00e3)") |>
    stringr::str_replace_all(r"(\u00e3\u00a7)", r"(\u00e7)") |>
    stringr::str_replace_all(r"(\u00e3\u00a9)", r"(\u00e9)") |>
    stringr::str_replace_all(r"(\u00e3\u00ad)", r"(\u00ed)") |>
    stringr::str_replace_all(r"(\u00e3\u00ba)", r"(\u00fa)") |>
    stringr::str_replace_all(r"(\u00e3\u00b3)", r"(\u00f3)") |>
    stringr::str_replace_all("\\(tecnologia\\)", " ") |>
    stringr::str_replace_all("alimentosnovo", "alimentos") |>
    stringr::str_replace_all(r"(superiorgest\u00e3o)", r"(superior gest\u00e3o)") |>
    stringr::str_replace_all("superior de tecnologia", " ")
}
