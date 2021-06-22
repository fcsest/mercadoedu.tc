#==================================================================================================#
# Stopwords ####
#==========================================================#
FCSUtils::title_ascii("Stopwords",
                      text_color = "green")
#==========================================================#
#--------------------------------------------------------------------------------------------------#
## Connection ####
#----------------------------------------------------------#
FCSUtils::title_ascii("Connection",
                      text_color = "blue")
#----------------------------------------------------------#

### Model connection ####
conex_MODEL <- odbc::odbc() |>
  DBI::dbConnect("Amazon RDS Model",
                 timeout = 0)

#--------------------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------------------#
## Get stopwords ####
#----------------------------------------------------------#
c("Get",
  "Stopwords") |>
  FCSUtils::title_ascii(text_color = "blue")
#----------------------------------------------------------#

### My stopwords ####
sw <- c("abi",
        "lins",
        "distância",
        "presencial",
        "semipresencial",
        "cidade universitária",
        "centro universitário",
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
        "pe")

### PT-BR Stopwords ####
sw_br <- "pt" |>
  rep(3) |>
  c("br") |>
  purrr::map2(.y = "nltk" |>
                c("snowball",
                  rep("stopwords-iso",
                      2)),
              stopwords::stopwords) |>
  unlist() |>
  sort() |>
  unique() |>
  stringr::str_subset("(sistema)|(viagem)|(trabalho)|(conselho)|(meio)|(estado)",
                      negate = T) |>
  stringr::str_squish()

### All stopwords ####
sws <- sw |>
  append(sw_br) |>
  sort() |>
  unique()

### Stopwords with and without accents ####
sws_ready <- sws |>
  abjutils::rm_accent() |>
  c(sws) |>
  sort() |>
  unique()

### Database ready ####
model_stopwords <- data.frame("words" = sws_ready)

#--------------------------------------------------------------------------------------------------#

#--------------------------------------------------------------------------------------------------#
## Insert Stopwords DB ####
#----------------------------------------------------------#
c("Insert",
  "Stopwords",
  "DB") |>
  FCSUtils::title_ascii(text_color = "blue")
#----------------------------------------------------------#

### Writing database in RDS ####
conex_MODEL |>
  odbc::dbWriteTable("model_stopwords",
                     model_stopwords,
                     overwrite = TRUE,
                     row.names = FALSE)

#--------------------------------------------------------------------------------------------------#

#--------------------------------------------------------------------------------------------------#
## Check Database ####
#----------------------------------------------------------#
c("Check",
  "Database") |>
  FCSUtils::title_ascii(text_color = "blue")
#----------------------------------------------------------#

### Checking writed database in RDS ####
conex_MODEL |>
  dplyr::tbl("model_stopwords") |>
  dplyr::pull(words)

#--------------------------------------------------------------------------------------------------#
#==================================================================================================#
