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

my_sw <- c("tecnologia em",
           "tecnologo",
           "tecnólogo",
           "tecnologico",
           "tecnológico",
           "tec",
           "licenciatura",
           "licenciado",
           "licenciados",
           "licenc",
           "lins",
           "lic",
           "graduação",
           "graduacao",
           "graduados",
           "bacharelado",
           "bacharel",
           "bachar",
           "distancia",
           "distância",
           "presencial",
           "semipresencial",
           "cidade universitaria",
           "cidade universitária",
           "centro universitario",
           "centro universitário",
           "formacao pedagogica",
           "formação pedagógica",
           "modalidade",
           "modalidade ensino",
           "ensino superior",
           "sup",
           "superior",
           "curso",
           "cst",
           "ead",
           "semestre",
           "semestres",
           "fgv",
           "premium",
           "plena",
           "novo",
           "parceria",
           "zona norte",
           "xv",
           "novembro",
           "lucas",
           "unisl",
           "mg",
           "pe",
           letters) |>
  append(stopwords::stopwords("pt", "nltk")) |>
  append(stopwords::stopwords("pt", "snowball")) |>
  append(stopwords::stopwords("pt", "stopwords-iso")) |>
  append(stopwords::stopwords("br", "stopwords-iso")) |>
  sort() |>
  unique() |>
  stringr::str_remove("(sistema)|(viagem)|(trabalho)|(conselho)|(meio)") |>
  stringr::str_squish() |>
  purrr::discard(~(.x) == "")

#==================================================================================================#
# Modeling ####
#==========================================================#
FCSUtils::title_ascii("Modeling",
                      text_color = "green")
#==========================================================#
#--------------------------------------------------------------------------------------------------#
## Imports and Cleaning ####
#----------------------------------------------------------#
c("Imports",
  "and",
  "Cleaning") |>
  FCSUtils::title_ascii(text_color = "blue")
#----------------------------------------------------------#

# ### DB Connection ####
# conex_RDS <- odbc::odbc() |>
#   DBI::dbConnect("Amazon RDS mercadoedu",
#                  timeout = 0)

### Setting a seed ####
set.seed(Sys.time())

### Cleaning data ####
data_courses <- ftk_ca |>
  dplyr::select("original_name" = name_detail, "name" = ca_name, alias_id) |>
  dplyr::mutate("cleaned_name" = original_name |>
                  stringr::str_to_lower(locale = "br") |>
                  mercadoedu.tc::correct_strings() |>
                  stringr::str_replace_all("[:number:]|[:punct:]", " ") |>
                  stringr::str_replace_all("°|º|ª"," ") |>
                  tm::removeWords(my_sw) |>
                  stringr::str_squish()) |>
  tibble::view("my_df")

#--------------------------------------------------------------------------------------------------#

#--------------------------------------------------------------------------------------------------#
## Data Visualization ####
#----------------------------------------------------------#
c("Data", "Visualization") |>
  FCSUtils::title_ascii(text_color = "blue")
#----------------------------------------------------------#

### Freq names ####
data_courses |>
  dplyr::count(name) |>
  tibble::view("names_count") |>
  ggplot2::ggplot(ggplot2::aes(x = name,
                               y = n)) +
  ggplot2::geom_col()

#--------------------------------------------------------------------------------------------------#

#--------------------------------------------------------------------------------------------------#
## Preprocessing ####
#----------------------------------------------------------#
FCSUtils::title_ascii("Preprocessing",
                      text_color = "blue")
#----------------------------------------------------------#

### Splitting data ####
my_df <- data_courses |>
  rsample::initial_split(strata = name)

### Create a recipe ####
rec <- recipes::recipe(name ~ .,
                       data = my_df |>
                         rsample::training()) |>
  textrecipes::step_tokenize(cleaned_name) |>
  textrecipes::step_stem(cleaned_name, options = list(language = "portuguese")) |>
  textrecipes::step_stem(cleaned_name, custom_stemmer = abjutils::rm_accent) |>
  textrecipes::step_ngram(cleaned_name, num_tokens = 3, min_num_tokens = 1) |>
  textrecipes::step_tfidf(cleaned_name)

### Prepare recipe ####
prepped <- rec |>
  recipes::prep()

### Make recipe ####
baked <- recipes::bake(prepped, new_data = NULL)

### Checking tfidf results ####
baked |>
  dplyr::select(name,
                dplyr::starts_with("tfidf")) |>
  dplyr::group_by(name) |>
  dplyr::summarise(dplyr::across(dplyr::everything(), ~sum(., is.na(.), 0))) |>
  tidyr::pivot_longer(cols = dplyr::starts_with("tfidf"),
                      names_to = "tokens",
                      values_to = "tfidf") |>
  tidyr::pivot_wider(names_from = name,
                     values_from = tfidf) |>
  dplyr::mutate("tokens" = tokens |> stringr::str_extract(("(?<=name_).*"))) |>
  tibble::view("most")

#--------------------------------------------------------------------------------------------------#

#==================================================================================================#




  colnames() |>
  stringr::str_extract("(?<=name_).*") |>
  tibble::view("tfidf")
