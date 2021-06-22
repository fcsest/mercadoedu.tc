#==================================================================================================#
conex_RDS <- odbc::odbc() |>
  DBI::dbConnect("Amazon RDS mercadoedu",
                 timeout = 0)

fromtokey_sw <- c("tecnologia em",
                  "tecnologo",
                  "modalidade ensino",
                  "ensino superior",
                  "tecnologico",
                  "premium",
                  "novo",
                  "zona norte",
                  "presencial",
                  "ead",
                  "semipresencial",
                  "xv",
                  "licenciatura",
                  "licenciado",
                  "licenciados",
                  "fgv",
                  "ead",
                  "semestre",
                  "semestres",
                  "bacharel",
                  "bacharelado",
                  "graduação",
                  "cidade universitaria",
                  "centro universitario",
                  "formacao pedagogica",
                  "lucas",
                  "unisl",
                  "graduados",
                  "parceria",
                  letters,
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
                  "lins",
                  "lic",
                  "bachar",
                  "licenc",
                  "pe") |>
  append(stopwords::stopwords("pt", "nltk")) |>
  append(stopwords::stopwords("pt", "snowball")) |>
  append(stopwords::stopwords("pt", "stopwords-iso")) |>
  append(stopwords::stopwords("br", "stopwords-iso")) |>
  abjutils::rm_accent() |>
  sort() |>
  unique() |>
  stringr::str_remove("(sistema)|(viagem)|(trabalho)|(conselho)|(meio)") |>
  stringr::str_squish() |>
  purrr::discard(~(.x) == "")

get_course <- function(name) {
  "http://localhost:5000/course/classifier/'" |>
    paste0(str_replace_all(name,
                           " ",
                           "%"),
           "'") |>
    httr::POST() %>%
    httr::content() %>%
    purrr::chuck("body") %>%
    jsonlite::fromJSON() %>%
    data.frame("name_detail" = name) %>%
    dplyr::select("name_detail", everything()) %>%
    janitor::clean_names()
}

correct_strings <- function(string) {
  string |>
    stringr::str_replace_all("ãª", "ê") |>
    stringr::str_replace_all("ã¡", "á") |>
    stringr::str_replace_all("ã£", "ã") |>
    stringr::str_replace_all("ã§", "ç") |>
    stringr::str_replace_all("ã©", "é") |>
    stringr::str_replace_all("ã­", "í") |>
    stringr::str_replace_all("ãº", "ú") |>
    stringr::str_replace_all("ã³", "ó") |>
    stringr::str_replace_all("\\(tecnologia\\)", " ") |>
    stringr::str_replace_all("alimentosnovo", "alimentos") |>
    stringr::str_replace_all("superiorgestão", "superior gestão") |>
    stringr::str_replace_all("superior de tecnologia", " ")
}

#==================================================================================================#
# pricing_course
pc <- conex_RDS |>
  dplyr::tbl("pricing_course") |>
  dplyr::select("discr_id" = id, alias_id, name, human_match) |>
  dplyr::filter(!is.na(alias_id)) |>
  dplyr::distinct() |>
  dplyr::collect() |>
  tibble::view("pricing_course")

# Pegando os nomes de cursos detalhados dos sites e limpando para predicts
ftk <- conex_RDS |>
  dplyr::tbl("me_v3_pricing_fromtokey") |>
  dplyr::filter(discr == "pricing_course_level_1", arg != "n/c", arg != "-new-") |>
  dplyr::select("name_detail" = arg, robot_id, discr_id) |>
  dplyr::distinct() |>
  dplyr::collect() |>
  dplyr::mutate("clean_names" = name_detail |>
                  correct_strings() |>
                  stringr::str_replace_all("([:punct:])|([:digit:])|(\\|)|(ª)|(º)|(°)",
                                           " ") |>
                  stringr::str_to_lower(locale = "br") |>
                  tm::removeWords(fromtokey_sw) |>
                  stringr::str_squish()) |>
  dplyr::arrange(clean_names) |>
  tibble::view("fromtokey")

ca <- conex_RDS |>
  dplyr::tbl("coursealias") |>
  dplyr::rename("alias_id" = id) |>
  dplyr::filter(name != "N/C") |>
  dplyr::arrange(name) |>
  dplyr::collect() |>
  dplyr::mutate("clean_names" = name |>
           stringr::str_replace_all("([:punct:])|([:digit:])|(\\|)|(ª)|(º)|(°)", " ") |>
           abjutils::rm_accent() |>
           stringr::str_to_lower(locale = "br") |>
           tm::removeWords(fromtokey_sw) |>
           stringr::str_squish()) |>
  dplyr::arrange(clean_names) |>
  tibble::view("coursealias")

# Nomes agregados dos cursos do censo e nomes detalhados dos cursos da fromtokey
ftk_ca <- ftk |>
  dplyr::left_join(pc |>
                     dplyr::rename("pc_name" = name),
            by = "discr_id") |>
  dplyr::left_join(ca |>
                     dplyr::rename("ca_name" = name,
                     "ca_clean_names" = clean_names),
            by = "alias_id") |>
  dplyr::select(clean_names,
         name_detail,
         ca_name,
         pc_name,
         alias_id,
         discr_id,
         robot_id,
         human_match,
         ca_clean_names) |>
  tibble::view("fromtokey_coursealias")

ftk_ca |>
  dplyr::filter(is.na(ca_name))
ftk_ca |>
  dplyr::filter(is.na(pc_name))

ftk_ca <- ftk_ca |>
  dplyr::filter(!is.na(ca_name),
                !is.na(pc_name))

# Conferencia de quantos alias_id tem para cada clean_name
ftk_ca_check <- ftk_ca |>
  dplyr::group_by(clean_names) |>
  dplyr::mutate("n_dist" = dplyr::n_distinct(alias_id)) |>
  dplyr::ungroup() |>
  dplyr::filter(n_dist > 1) |>
  tibble::view("ftk_pc_ca_check")

ftk_ca_by_clean <- ftk |>
  dplyr::left_join(ca,
            by = "clean_names") |>
  dplyr::filter(!is.na(name))

ftk_ca_by_clean |>
  dplyr::anti_join(ftk_ca,
            by = "name_detail")

teste <- ftk_ca_by_clean |>
  dplyr::left_join(ftk_ca,
            by = c("clean_names"))




# Importando automation_price
ncc <- vroom::vroom("~/Downloads/me.csv")

# automation_price limpos
new_courses_collected <- ncc |>
  dtplyr:lazy_dt() |>
  dplyr::select(course_name, ies_sigle) |>
  dplyr::filter(!is.na(course_name)) |>
  dplyr::distinct() |>
  dplyr::mutate("clean_names" = course_name |>
           stringr::str_to_lower(locale = "br") |>
           correct_strings() |>
           stringr::str_replace_all("([:punct:])|([:digit:])|(\\|)|(ª)|(º)|(°)", " ") |>
           abjutils::rm_accent() |>
           tm::removeWords(fromtokey_sw) |>
           stringr::str_squish()) |>
  data.table::as.data.table()

#
first_merge <- conex_RDS |>
  dplyr::tbl("coursealias") |>
  dplyr::rename("alias_id" = id) |>
  dplyr::filter(name != "N/C") |>
  dplyr::arrange(name) |>
  dplyr::collect() |>
  dplyr::mutate("clean_names" = name |>
           stringr::str_replace_all("([:punct:])|([:digit:])|(\\|)|(ª)|(º)|(°)", " ") |>
           abjutils::rm_accent() |>
           stringr::str_to_lower(locale = "br") |>
           tm::removeWords(fromtokey_sw) |>
           stringr::str_squish()) |>
  dplyr::arrange(clean_names) |>
  dplyr::right_join(new_courses_collected,
             by = "clean_names") |>
  dplyr::filter(!is.na(name))

# # Primeiro merge com nomes agregados
# first_merge <- pricing_courses %>%
#   arrange("clean_names") %>%
#   distinct(clean_names) %>%
#   left_join(courses %>%
#               select(name, alias_id) %>%
#               mutate("origin" = "agregated",
#                      "clean_agregated_names" = format_name(name, sw_default)) %>%
#               arrange(clean_agregated_names) %>%
#               distinct(),
#             by = c("clean_names" = "clean_agregated_names"),
#             suffix = c(".pricing_courses", ".agregated_names")) %>%
#   mutate("name_detail" = NA)
#
# # Segundo merge com nomes detalhados
# second_merge <- pricing_courses %>%
#   arrange("clean_names") %>%
#   distinct(clean_names) %>%
#   left_join(courses %>%
#               select(name, name_detail, alias_id) %>%
#               mutate("origin" = "detail",
#                      "clean_detail_names" = format_name(name_detail, sw_default)) %>%
#               arrange(clean_detail_names) %>%
#               distinct(),
#             by = c("clean_names" = "clean_detail_names"),
#             suffix = c(".pricing_courses", ".detail_names"))
#
# # Vinculos feitos com merge, em que preferimos o merge com os nomes agregados
# merged <- first_merge %>%
#   add_row(second_merge) %>%
#   filter(!is.na(alias_id)) %>%
#   arrange(clean_names) %>%
#   distinct(clean_names,
#            .keep_all = T) %>%
#   select(clean_names, alias_id, origin)
#
# # Nomes de cursos que o merge não conseguiu
# remaining <- pricing_courses %>%
#   anti_join(merged,
#             by = "clean_names")
#
# # Predizendo os remainings
# predicts <- remaining %>%
#   arrange(clean_names) %>%
#   pull(clean_names) %>%
#   unique() %>%
#   map_dfr(get_course) %>%
#   select(1:4)
#
# # Merge dos preditos com o alias_id do courses
# predict_with_alias <- predicts %>%
#   filter(trusty == T) %>%
#   mutate("clean_agregated_names" = format_name(first_name, sw_default)) %>%
#   left_join(courses %>%
#               select(name, alias_id) %>%
#               mutate("origin" = "predicted",
#                      "clean_agregated_names" = format_name(name, sw_default)) %>%
#               arrange(clean_agregated_names) %>%
#               distinct(),
#             by = "clean_agregated_names") %>%
#   rename("clean_names" = name_detail) %>%
#   select(clean_names, alias_id, origin)
#
# # Todos os cursos que conseguimos vinculo com alias_id
# ready <- merged %>%
#   add_row(predict_with_alias) %>%
#   arrange(clean_names) %>%
#   distinct(clean_names,
#            .keep_all = T) %>%
#   rename("new_alias_id" = alias_id)
#
# # Faltantes(Quarentena?)
# missing_clfs <- pricing_courses %>%
#   anti_join(ready,
#             by = "clean_names")
#
# #==================================================================================================#
#
# # Nomes de cursos do censo com nome agregado e detalhado limpos para facilitar conferência
# courses_check <- courses %>%
#   distinct() %>%
#   mutate("clean_names" = name %>% format_name(sw_default),
#          "clean_detail_names" = name_detail %>% format_name(sw_default))
#
# # Proporção do alias_id encontrado em relação ao total de clean_names(nomes de cursos normalizados do pricing_course)
# nrow(ready) %>%
#   "*"(100) %>%
#   "/"(pricing_courses %>%
#         distinct(clean_names, .keep_all = T) %>%
#         tally() %>%
#         pull(n)) %>%
#   cat("\nProporção do alias_id encontrado em relação ao total de clean_names(nomes de cursos normalizados do pricing_course): \n",
#       .,
#       "%")
#
# # Proporção do nomes de cursos normalizados do pricing_course(clean_names) que não haviam alias_id antes e agora tem
# nrow(missing_clfs) %>%
#   "*"(100) %>%
#   "/"(pricing_courses %>%
#         distinct(clean_names, .keep_all = T) %>%
#         group_by(alias_id) %>%
#         tally() %>%
#         filter(is.na(alias_id)) %>%
#         pull(n)) %>%
#   "*"(-1) %>%
#   "+"(100) %>%
#   cat("\nProporção do nomes de cursos normalizados do pricing_course(clean_names) que não haviam alias_id antes e agora tem: \n",
#       .,
#       "%")
#
# #==================================================================================================#
#
# # Nova tabela de pricing course
# new_pricing_course <- pricing_courses %>%
#   left_join(ready,
#             by = "clean_names")
#
# # Removendo a table de teste
# DBI::dbGetQuery(conex_RDS, "DROP TABLE new_pricing_course;")
#
# # Tabela original de pricing course
# original_pricing_course <- conex_RDS %>%
#   tbl("pricing_course") %>%
#   collect()
#
# # Copiando a pricing_course original
# # DBI::dbWriteTable(conex_RDS, "new_pricing_course", original_pricing_course, row.names = FALSE)
#
# # Conferindo nova pricing_course que foi criada com o banco original
# old_pc <- conex_RDS %>%
#   tbl("new_pricing_course") %>%
#   collect()
#
# # Função para criar a query em SQL
# update_where_sql <- function(data, table_name) {
#   paste("UPDATE ",
#         table_name,
#         " AS t SET alias_id = c.alias_id from (VALUES ",
#         paste0("(", data$id, ",", data$alias_id, ")", collapse = ","),
#         ") AS c(id, alias_id) WHERE c.id = t.id;", sep = "")
# }
#
# # Função para criar a query em SQL
# update_where_names_sql <- function(data, table_name) {
#   paste("UPDATE ",
#         table_name,
#         " AS t SET clean_name = c.clean_name from (VALUES ",
#         paste0("(", data$id, ", '", data$clean_name, "')", collapse = ","),
#         ") AS c(id, clean_name) WHERE c.id = t.id;", sep = "")
# }
#
# # Atualizando os dados do novo banco criado com os predicts
# queries <- new_pricing_course %>%
#   select(clean_name = clean_names, id) %>%
#   update_where_names_sql("pricing_course")
#
# # Rodando a query
# DBI::dbGetQuery(conex_RDS, queries)
#
# # Com as atualizações as linhas mudaram de ordem e foram pro final
# new_pc <- conex_RDS %>%
#   tbl("pricing_course") %>%
#   collect()
#
# #==================================================================================================#
#
# # pricing_course completa com os predicts
# ready_table <- original_pricing_course %>%
#   left_join(new_pricing_course,
#             by = c("name", "level", "id")) %>%
#   select(id, name, level, new_alias_id, origin) %>%
#   rename("alias_id" = new_alias_id)
