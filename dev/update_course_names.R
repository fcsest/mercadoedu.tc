conex_RDS <- DBI::dbDriver("PostgreSQL") %>%
  RPostgreSQL::dbConnect(host = Sys.getenv("AWS_HOST_RDS"),
                         port = Sys.getenv("AWS_PORT_RDS"),
                         dbname = Sys.getenv("AWS_DB_RDS"),
                         user = Sys.getenv("AWS_USER"),
                         password = Sys.getenv("AWS_PASSWORD"))

conex_REDSHIFT <- DBI::dbDriver("PostgreSQL") %>%
  RPostgreSQL::dbConnect(host = Sys.getenv("AWS_HOST_REDSHIFT"),
                         port = Sys.getenv("AWS_PORT_REDSHIFT"),
                         dbname = Sys.getenv("AWS_DB_REDSHIFT"),
                         user = Sys.getenv("AWS_USER"),
                         password = Sys.getenv("AWS_PASSWORD"))

conex_MODEL <- DBI::dbDriver("PostgreSQL") %>%
  RPostgreSQL::dbConnect(host = Sys.getenv("AWS_HOST_RDS"),
                         port = Sys.getenv("AWS_PORT_RDS"),
                         dbname = Sys.getenv("AWS_DB_MODEL"),
                         user = Sys.getenv("AWS_USER"),
                         password = Sys.getenv("AWS_PASSWORD"))

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

# course_names <- conex_MODEL %>%
#   tbl("course_names") %>%
#   collect()

courses_red <- conex_REDSHIFT %>%
  tbl("course") %>%
  collect()

courses <- conex_RDS %>%
  tbl("course") %>%
  select(name, name_detail, alias_id, degree) %>%
  collect()

pricing_course <- conex_RDS %>%
  tbl("pricing_course") %>% collect()
  filter(level == 1) %>%
  rename("name_detail" = name) %>%
  # select("name_detail", "alias_id") %>%
  collect()

courses <- conex_RDS %>%
  tbl("course") %>%
  select("name", "name_detail", "alias_id") %>%
  collect()

ready_bind <- pricing_course %>%
  left_join(courses %>%
  select("name", "alias_id"),
  by = "alias_id") %>%
  bind_rows(courses) %>%
  arrange(alias_id, name)

ready_bind <- pricing_course %>%
  left_join(courses %>%
              select("name", "alias_id"),
            by = "alias_id") %>%
  bind_rows(courses) %>%
  arrange(alias_id, name) %>%
  filter(name == name_detail)


update_where_names_sql <- function(table_name) {
  paste("UPDATE ",
        table_name,
        " SET alias_id = 25 WHERE id = 25", sep = "")
}

conex_RDS %>%
  dbGetQuery(update_where_names_sql("pricing_course"))

