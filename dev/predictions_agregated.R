library(dplyr)
library(stringr)
library(abjutils)
library(stopwords)
library(httr)
library(purrr)
library(jsonlite)
library(stringi)
library(janitor)

#==================================================================================================#

conex_RDS <- DBI::dbDriver("PostgreSQL") %>%
  RPostgreSQL::dbConnect(host = Sys.getenv("AWS_HOST_RDS"),
                         port = Sys.getenv("AWS_PORT_RDS"),
                         dbname = Sys.getenv("AWS_DB_RDS"),
                         user = Sys.getenv("AWS_USER"),
                         password = Sys.getenv("AWS_PASSWORD"))

conex_MODEL <- DBI::dbDriver("PostgreSQL") %>%
  RPostgreSQL::dbConnect(host = Sys.getenv("AWS_HOST_RDS"),
                         port = Sys.getenv("AWS_PORT_RDS"),
                         dbname = Sys.getenv("AWS_DB_MODEL"),
                         user = Sys.getenv("AWS_USER"),
                         password = Sys.getenv("AWS_PASSWORD"))

#==================================================================================================#


my_sw <- c("tecnologo",
           "tecnologico",
           "premium",
           "novo",
           "zona norte",
           "presencial",
           "ead",
           "semipresencial",
           "xv",
           "licenciatura",
           "fgv",
           "ead",
           "semestre",
           "semestres",
           "bacharel",
           "bacharelado",
           "graduação",
           "cidade universitaria",
           "ads",
           "ª",
           "º",
           "°",
           "sup",
           "superior",
           "tec",
           "plena",
           "distancia",
           "curso",
           "cst",
           "novembro",
           "mg",
           "modalidade",
           "ensino",
           "lins",
           "lic",
           "bachar",
           "licenc",
           "pe")

sw_default <- stopwords("pt", "nltk") %>%
  append(stopwords("pt", "snowball")) %>%
  append(stopwords("pt", "stopwords-iso")) %>%
  append(stopwords("br", "stopwords-iso")) %>%
  append(my_sw) %>%
  rm_accent() %>%
  sort() %>%
  unique() %>%
  str_remove("(sistema)|(viagem)|(trabalho)|(conselho)|(meio)") %>%
  str_squish() %>%
  discard(~(.x) == "")

# sw <- sw_default %>%
#   paste(collapse = '\\b|\\b') %>%
#   paste0('\\b', ., '\\b')

get_course <- function(name) {
  POST(paste0("http://localhost:5000/course/classifier/'", str_replace_all(name, " ", "%"), "'")) %>%
    content() %>%
    chuck("body") %>%
    fromJSON() %>%
    data.frame("name_detail" = name) %>%
    select("name_detail", everything()) %>%
    clean_names()
}

#==================================================================================================#

# Pegando os nomes de cursos agregados dos preços(com alias_id errado)
pricing_courses <- conex_RDS %>%
  tbl("pricing_course") %>%
  filter(level == 1) %>%
  collect() %>%
  arrange(name) %>%
  mutate("name" = str_replace_all(name,
                                  "TRANPORTES",
                                  "TRANSPORTES"),
         "clean_names" = name %>%
                          format_name(sw_default))

# Nomes agregados e detalhados dos cursos do censo
courses <- conex_RDS %>%
  tbl("course") %>%
  collect() %>%
  select(name, alias_id, name_detail)

# Primeiro merge com nomes agregados
first_merge <- pricing_courses %>%
  arrange("clean_names") %>%
  distinct(clean_names) %>%
  left_join(courses %>%
              select(name, alias_id) %>%
              mutate("origin" = "agregated",
                     "clean_agregated_names" = format_name(name, sw_default)) %>%
              arrange(clean_agregated_names) %>%
              distinct(),
            by = c("clean_names" = "clean_agregated_names"),
            suffix = c(".pricing_courses", ".agregated_names")) %>%
  mutate("name_detail" = NA)

# Segundo merge com nomes detalhados
second_merge <- pricing_courses %>%
  arrange("clean_names") %>%
  distinct(clean_names) %>%
  left_join(courses %>%
              select(name, name_detail, alias_id) %>%
              mutate("origin" = "detail",
                     "clean_detail_names" = format_name(name_detail, sw_default)) %>%
              arrange(clean_detail_names) %>%
              distinct(),
            by = c("clean_names" = "clean_detail_names"),
            suffix = c(".pricing_courses", ".detail_names"))

# Vinculos feitos com merge, em que preferimos o merge com os nomes agregados
merged <- first_merge %>%
  add_row(second_merge) %>%
  filter(!is.na(alias_id)) %>%
  arrange(clean_names) %>%
  distinct(clean_names,
           .keep_all = T) %>%
  select(clean_names, alias_id, origin)

# Nomes de cursos que o merge não conseguiu
remaining <- pricing_courses %>%
  anti_join(merged,
            by = "clean_names")

# Predizendo os remainings
predicts <- remaining %>%
  arrange(clean_names) %>%
  pull(clean_names) %>%
  unique() %>%
  map_dfr(get_course) %>%
  select(1:4)

# Merge dos preditos com o alias_id do courses
predict_with_alias <- predicts %>%
  filter(trusty == T) %>%
  mutate("clean_agregated_names" = format_name(first_name, sw_default)) %>%
  left_join(courses %>%
              select(name, alias_id) %>%
              mutate("origin" = "predicted",
                     "clean_agregated_names" = format_name(name, sw_default)) %>%
              arrange(clean_agregated_names) %>%
              distinct(),
            by = "clean_agregated_names") %>%
  rename("clean_names" = name_detail) %>%
  select(clean_names, alias_id, origin)

# Todos os cursos que conseguimos vinculo com alias_id
ready <- merged %>%
  add_row(predict_with_alias) %>%
  arrange(clean_names) %>%
  distinct(clean_names,
           .keep_all = T) %>%
  rename("new_alias_id" = alias_id)

# Faltantes(Quarentena?)
missing_clfs <- pricing_courses %>%
  anti_join(ready,
            by = "clean_names")

#==================================================================================================#

# Nomes de cursos do censo com nome agregado e detalhado limpos para facilitar conferência
courses_check <- courses %>%
  distinct() %>%
  mutate("clean_names" = name %>% format_name(sw_default),
         "clean_detail_names" = name_detail %>% format_name(sw_default))

# Proporção do alias_id encontrado em relação ao total de clean_names(nomes de cursos normalizados do pricing_course)
nrow(ready) %>%
  "*"(100) %>%
  "/"(pricing_courses %>%
        distinct(clean_names, .keep_all = T) %>%
        tally() %>%
        pull(n)) %>%
  cat("\nProporção do alias_id encontrado em relação ao total de clean_names(nomes de cursos normalizados do pricing_course): \n",
      .,
      "%")

# Proporção do nomes de cursos normalizados do pricing_course(clean_names) que não haviam alias_id antes e agora tem
nrow(missing_clfs) %>%
  "*"(100) %>%
  "/"(pricing_courses %>%
        distinct(clean_names, .keep_all = T) %>%
        group_by(alias_id) %>%
        tally() %>%
        filter(is.na(alias_id)) %>%
        pull(n)) %>%
  "*"(-1) %>%
  "+"(100) %>%
  cat("\nProporção do nomes de cursos normalizados do pricing_course(clean_names) que não haviam alias_id antes e agora tem: \n",
      .,
      "%")

#==================================================================================================#

# Nova tabela de pricing course
new_pricing_course <- pricing_courses %>%
  left_join(ready,
            by = "clean_names")

# Removendo a table de teste
DBI::dbGetQuery(conex_RDS, "DROP TABLE new_pricing_course;")

# Tabela original de pricing course
original_pricing_course <- conex_RDS %>%
  tbl("pricing_course") %>%
  collect()

# Copiando a pricing_course original
# DBI::dbWriteTable(conex_RDS, "new_pricing_course", original_pricing_course, row.names = FALSE)

# Conferindo nova pricing_course que foi criada com o banco original
old_pc <- conex_RDS %>%
  tbl("new_pricing_course") %>%
  collect()

# Função para criar a query em SQL
update_where_sql <- function(data, table_name) {
  paste("UPDATE ",
        table_name,
        " AS t SET alias_id = c.alias_id from (VALUES ",
        paste0("(", data$id, ",", data$alias_id, ")", collapse = ","),
        ") AS c(id, alias_id) WHERE c.id = t.id;", sep = "")
}

# Função para criar a query em SQL
update_where_names_sql <- function(data, table_name) {
  paste("UPDATE ",
        table_name,
        " AS t SET clean_name = c.clean_name from (VALUES ",
        paste0("(", data$id, ", '", data$clean_name, "')", collapse = ","),
        ") AS c(id, clean_name) WHERE c.id = t.id;", sep = "")
}

# Atualizando os dados do novo banco criado com os predicts
queries <- new_pricing_course %>%
  select(clean_name = clean_names, id) %>%
  update_where_names_sql("pricing_course")

# Rodando a query
DBI::dbGetQuery(conex_RDS, queries)

# Com as atualizações as linhas mudaram de ordem e foram pro final
new_pc <- conex_RDS %>%
  tbl("pricing_course") %>%
  collect()

#==================================================================================================#

# pricing_course completa com os predicts
ready_table <- original_pricing_course %>%
  left_join(new_pricing_course,
            by = c("name", "level", "id")) %>%
  select(id, name, level, new_alias_id, origin) %>%
  rename("alias_id" = new_alias_id)
