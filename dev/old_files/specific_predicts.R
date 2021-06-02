library(dplyr)
library(stringr)
library(abjutils)
library(stopwords)
library(httr)
library(purrr)
library(jsonlite)
library(stringi)

#==================================================================================================#

format_name <- function(string) {
  string %>%
    rm_accent() %>%
    str_squish() %>%
    str_to_lower(locale = "br")
}

removeWords <- function(str, stopwords) {
  x <- unlist(strsplit(str, " "))
  paste(x[!x %in% stopwords], collapse = " ")
}

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
  format_name() %>%
  sort() %>%
  unique() %>%
  str_remove("(sistema)|(viagem)|(trabalho)|(conselho)|(meio)")

sw <- sw_default %>%
  paste(collapse = '\\b|\\b') %>%
  paste0('\\b', ., '\\b')

get_course <- function(name) {
  POST(paste0("http://localhost:5000/course/classifier/'", str_replace_all(name, " ", "%"), "'")) %>%
    content() %>%
    chuck("body") %>%
    jsonlite::fromJSON() %>%
    data.frame("name_detail" = name)
}

#==================================================================================================#

my_courses <- c("ENGENHARIA ELETRÔNICA",
  "ENGENHARIA MECATRÔNICA",
  "ENGENHARIA ELÉTRICA",
  "ENGENHARIA DE GESTÃO",
  "ENGENHARIA BIOMÉDICA",
  "ENGENHARIA DE PRODUÇÃO",
  "ENGENHARIA CIVIL",
  "ENGENHARIA QUÍMICA",
  "ENGENHARIA DE CONTROLE E AUTOMAÇÃO",
  "ENGENHARIA DA COMPUTAÇÃO",
  "ENGENHARIA AMBIENTAL E SANITÁRIA",
  "ENGENHARIA DE ALIMENTOS",
  "ENGENHARIA DE INFORMAÇÃO",
  "ENGENHARIA DE MATERIAIS",
  "ENGENHARIA DE INOVAÇÃO",
  "ENGENHARIA METALÚRGICA",
  "ENGENHARIA DE ENERGIA",
  "ENGENHARIA DE SOFTWARE",
  "ENGENHARIA AEROESPACIAL",
  "ENGENHARIA MECÂNICA",
  "ENGENHARIA NAVAL",
  "ENGENHARIA DE MINAS",
  "ENGENHARIA DE INSTRUMENTAÇÃO, AUTOMAÇÃO E ROBÓTICA",
  "ENGENHARIA DE TELECOMUNICAÇÕES") %>%
  data.frame(original_name = .) %>%
  mutate(clean_name = original_name %>%
               str_replace_all("([:punct:])|([:digit:])|(\\|)|(ª)|(º)|(°)",
                               "") %>%
               format_name() %>%
               map(~removeWords(.x, sw_default)) %>%
               flatten_chr() %>%
               str_replace("digitalnovo", "digital") %>%
               str_replace("superiorgestao", "gestao") %>%
               str_remove_all("(parceria centro universitario lucas unisl)|
                               (parceria centro universitario lucas)|
                               (zona norte)|
                               (cidade universitaria)") %>%
               str_replace_all("(^(tecnologia)|(superior tecnologia))|( tecnologia$)",
                               "") %>%
               str_remove_all("(xv de novembro)|
                               (fgv)|
                               (xv)$") %>%
               str_squish()) %>%
  arrange(clean_name)

#==================================================================================================#

df_clean <- conex_RDS %>%
  tbl('me_v3_pricing_fromtokey') %>%
  filter(discr == "pricing_course_level_1") %>%
  filter(arg != "-new-" | arg != "n/c") %>%
  collect() %>%
  mutate(clean_name = arg %>%
           str_replace("comã©rcio", "comércio") %>%
           str_replace("gerenciaisgestemp", "gerenciais gest emp") %>%
           str_remove_all("£")) %>%
  arrange(arg) %>%
  mutate(clean_name = clean_name %>%
           str_replace_all("([:punct:])|([:digit:])|(\\|)|(ª)|(º)|(°)", "") %>%
           format_name() %>%
           map(~removeWords(.x, sw_default)) %>%
           flatten_chr() %>%
           str_replace("digitalnovo", "digital") %>%
           str_replace("superiorgestao", "gestao") %>%
           str_remove_all("(parceria centro universitario lucas unisl)|(parceria centro universitario lucas)|(zona norte)|(cidade universitaria)") %>%
           str_replace_all("(^(tecnologia)|(superior tecnologia))|( tecnologia$)", "") %>%
           str_remove_all("(xv de novembro)|(fgv)|(xv)$") %>%
           str_squish()) %>%
  arrange(clean_name)

#==================================================================================================#

predicts <- df_clean %>%
  arrange(clean_name) %>%
  pull(clean_name) %>%
  unique() %>%
  map_dfr(get_course) %>%
  janitor::clean_names() %>%
  filter(trusty == T) %>%
  select(name_detail, trusty, first_name, first_probability) %>%
  mutate(clean_name = first_name %>%
           str_replace_all("([:punct:])|([:digit:])|(\\|)|(ª)|(º)|(°)", "") %>%
           format_name() %>%
           map(~removeWords(.x, sw_default)) %>%
           flatten_chr() %>%
           str_replace("digitalnovo", "digital") %>%
           str_replace("superiorgestao", "gestao") %>%
           str_remove_all("(parceria centro universitario lucas unisl)|(parceria centro universitario lucas)|(zona norte)|(cidade universitaria)") %>%
           str_replace_all("(^(tecnologia)|(superior tecnologia))|( tecnologia$)", "") %>%
           str_remove_all("(xv de novembro)|(fgv)|(xv)$") %>%
           str_squish())

joined <- my_courses %>%
  left_join(df_clean,
            by = "clean_name") %>%
  mutate("origin" = "joined") %>%
  select(original_name, arg, origin) %>%
  arrange(original_name)

predicted <- my_courses %>%
  left_join(predicts, by = "clean_name") %>%
  left_join(df_clean, by = c("name_detail" = "clean_name")) %>%
  mutate("origin" = "predicted") %>%
  select(original_name, arg, origin) %>%
  arrange(original_name)

df_ready <- predicted %>%
  filter(arg != "") %>%
  bind_rows(joined) %>%
  arrange(original_name, arg, origin) %>%
  distinct(original_name, arg, .keep_all = T)

df_ready %>%
  vroom::vroom_write("/mnt/d/FCS/Data Science/Databases/predicted_courses.csv", delim = ";")
