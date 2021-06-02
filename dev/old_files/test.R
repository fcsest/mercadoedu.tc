library(dplyr)

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

sw_default <- stopwords::stopwords("pt", "nltk") %>%
  append(stopwords::stopwords("pt", "snowball")) %>%
  append(stopwords::stopwords("pt", "stopwords-iso")) %>%
  append(stopwords::stopwords("br", "stopwords-iso")) %>%
  append(my_sw) %>%
  abjutils::rm_accent() %>%
  sort() %>%
  unique() %>%
  stringr::str_remove("(sistema)|(viagem)|(trabalho)|(conselho)|(meio)") %>%
  stringr::str_squish() %>%
  purrr::discard(~(.x) == "")

course_names <- conex_RED %>%
  tbl("course") %>%
  collect()

pricing_course <- conex_RDS %>%
  tbl("pricing_course") %>% collect()
  filter(level == 1,
         !is.na(alias_id)) %>%
  rename("name_detail" = name) %>%
  select("name_detail", "alias_id") %>%
  collect()

courses <- conex_RDS %>%
  tbl("course") %>%
  select("name", "name_detail", "alias_id") %>%
  collect()

merged <- pricing_course %>%
  left_join(courses %>%
              select("name", "alias_id") %>%
              distinct(),
            by = "alias_id") %>%
  mutate(name = case_when(is.na(name) ~ stringr::str_to_upper(name_detail, locale = "br"),
                          TRUE ~ name)) %>%
  bind_rows(courses) %>%
  arrange(alias_id, name)


without_dup <- merged %>%
  select(name, alias_id) %>%
  distinct() %>%
  arrange(name) %>%
  anti_join(merged %>%
              filter(name == name_detail) %>%
              arrange(name) %>%
              distinct(),
            by = "name") %>%
  mutate(name_detail = name)

ready <- merged %>%
  bind_rows(without_dup) %>%
  select(name, name_detail, alias_id) %>%
  arrange(alias_id, name, name_detail)

rm(list = ls() %>% purrr::discard(~(.x == "ready" | .x == "conex_MODEL" | .x == "conex_RDS")))


ready %>%
  group_by(name, alias_id) %>%
  tally()




clean_df <- ready %>%
  mutate("clean_name" = format_name(name, sw_default),
         "clean_name_detail" = format_name(name_detail, sw_default))

count_dif <- clean_df %>%
  group_by(alias_id) %>%
  summarise(n = n_distinct(clean_name))
