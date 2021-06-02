#==================================================================================================#
library(dplyr)
library(dtplyr)
library(data.table)
library(highcharter)
library(tidyr)
#==================================================================================================#
format_name <- function(string, stopwords) {
  string %>%
    str_replace_all("([:punct:])|([:digit:])|(\\|)|(ª)|(º)|(°)", " ") %>%
    rm_accent() %>%
    str_to_lower(locale = "br") %>%
    map(~removeWords(.x, stopwords)) %>%
    flatten_chr() %>%
    str_squish()
}

removeWords <- function(str, stopwords) {
  x <- unlist(strsplit(str, " "))
  paste(x[!x %in% stopwords], collapse = " ")
}
#==================================================================================================#
conex_MODEL <- DBI::dbDriver("PostgreSQL") %>%
  RPostgreSQL::dbConnect(host = Sys.getenv("AWS_HOST_RDS"),
                         port = Sys.getenv("AWS_PORT_RDS"),
                         dbname = Sys.getenv("AWS_DB_MODEL"),
                         user = Sys.getenv("AWS_USER"),
                         password = Sys.getenv("AWS_PASSWORD"))

conex_RDS <- DBI::dbDriver("PostgreSQL") %>%
  RPostgreSQL::dbConnect(host = Sys.getenv("AWS_HOST_RDS"),
                         port = Sys.getenv("AWS_PORT_RDS"),
                         dbname = Sys.getenv("AWS_DB_RDS"),
                         user = Sys.getenv("AWS_USER"),
                         password = Sys.getenv("AWS_PASSWORD"))

RPostgreSQL::dbListTables(conex_MODEL)

RPostgreSQL::dbListTables(conex_RDS)

my_df <- conex_MODEL %>%
  dplyr::tbl('course_names') %>%
  dplyr::collect()

distinct_df <- my_df %>%
  group_by(name) %>%
  summarise("n_distinct" = n_distinct(name_detail)) %>%
  ungroup() %>%
  mutate("percent" = (n_distinct/sum(n_distinct))*100)

count_df <- my_df %>%
  group_by(name) %>%
  tally() %>%
  ungroup() %>%
  mutate("percent" = (n/sum(n))*100)

merged_dfs <- distinct_df %>%
  left_join(count_df,
            by = "name") %>%
  gather(key = "category", "n", -name) %>%
  arrange(name)

hchart(distinct_df,
       "bar",
       hcaes(x = name,
             y = n_distinct)) %>%
  hc_yAxis(title = list(text = "Contagem")) %>%
  hc_size(height = 5000)

hchart(count_df,
       "bar",
       hcaes(x = name,
             y = n)) %>%
  hc_yAxis(title = list(text = "Contagem"),
           tickPositions = c(0,1,2,3,4,5,100,1000,3000)) %>%
  hc_size(height = 5000)

hchart(
  merged_dfs,
  "bar",
  hcaes(x = name, y = n, group = category),
  color = c("#7CB5EC", "#F7A35C"),
  name = c("Distintos", "Total"),
  showInLegend = c(TRUE, FALSE) # only show the first one in the legend
) %>%
  hc_size(
    height = 5000
  )

x <- c("n_distinct", "n", "name")
y <- sprintf("{point.%s:.2f}", c("n_distinct", "n", "name"))

tltip <- tooltip_table(x, y)

hchart(
  merged_dfs,
  "bar",
  hcaes(
    x = name,
    y = n,
    group = category
  ),
  minSize = 0
) %>%
  hc_xAxis(
    title = list(text = "Nomes de curso")
  ) %>%
  hc_yAxis(
    title = list(text = "Contagem"),
    type = "logarithm"
  ) %>%
  hc_tooltip(
    useHTML = TRUE,
    headerFormat = "",
    pointFormat = tltip
  ) %>%
  hc_size(
    height = 4000
  )
