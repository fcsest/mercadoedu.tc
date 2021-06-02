library(dplyr)

# c("tecnologo",
#   "tecnologico",
#   "premium",
#   "novo",
#   "zona norte",
#   "presencial",
#   "ead",
#   "semipresencial",
#   "xv",
#   "licenciatura",
#   "fgv",
#   "ead",
#   "semestre",
#   "semestres",
#   "bacharel",
#   "bacharelado",
#   "graduação",
#   "cidade universitaria",
#   "ads",
#   "ª",
#   "º",
#   "°",
#   "sup",
#   "superior",
#   "tec",
#   "plena",
#   "distancia",
#   "curso",
#   "cst",
#   "novembro",
#   "mg",
#   "modalidade",
#   "ensino",
#   "lins",
#   "lic",
#   "bachar",
#   "licenc",
#   "pe") |>
#   {\(words) data.table::data.table("stopwords" = words)}() |>
#   {\(df) odbc::dbWriteTable(conn = conex_MODEL,
#                             name = "model_stopwords",
#                             value = df)}()

format_name <- function(string, stopwords) {
  string %>%
    stringr::str_replace_all("([:punct:])|([:digit:])|(\\|)|(ª)|(º)|(°)", " ") %>%
    abjutils::rm_accent() %>%
    stringr::str_to_lower(locale = "br") %>%
    purrr::map(~removeWords(.x, stopwords)) %>%
    purrr::flatten_chr() %>%
    stringr::str_squish()
}

removeWords <- function(str, stopwords) {
  x <- unlist(strsplit(str, " "))
  paste(x[!x %in% stopwords], collapse = " ")
}

conex_MODEL |>
  tbl("course_names") |>
  arrange(desc(name)) |>
  head() |>
  collect()

conex_RDS |>
  tbl("course") |>
  select(name, name_detail) |>
  collect()

conex_RDS |>
  tbl("pricing_course") |>
  filter(!is.na(alias_id)) |>
  arrange(desc(alias_id)) |>
  head() |>
  collect()

