#==================================================================================================#
# CRUD ####
#==========================================================#
FCSUtils::title_ascii("CRUD",
                      text_color = "green")
#==========================================================#
#--------------------------------------------------------------------------------------------------#
## Connection ####
#----------------------------------------------------------#
FCSUtils::title_ascii("Connection",
                      text_color = "blue")
#----------------------------------------------------------#

### RDS connection ####
conex_RDS <- odbc::odbc() |>
  DBI::dbConnect("Amazon RDS mercadoedu",
                 timeout = 0)

### Model connection ####
conex_MODEL <- odbc::odbc() |>
  DBI::dbConnect("Amazon RDS Model",
                 timeout = 0)

#--------------------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------------------#
## First Databases ####
#----------------------------------------------------------#
c("First",
  "Databases") |>
  FCSUtils::title_ascii(text_color = "blue")
#----------------------------------------------------------#

### coursealias database(labels from mercadoedu) ####
csalias <- conex_RDS |>
  dplyr::tbl("coursealias") |>
  dplyr::rename("alias_id" = id) |>
  dplyr::filter(name != "N/C") |>
  dplyr::arrange(name) |>
  dplyr::collect()

### course database(censo data) ####
cs <- conex_RDS |>
  dplyr::tbl("course") |>
  dplyr::select(name,
                name_detail,
                alias_id,
                "cs_id" = id) |>
  dplyr::arrange(alias_id) |>
  dplyr::collect()

### pricing_course database(labels from quarentine) ####
pc <- conex_RDS |>
  dplyr::tbl("pricing_course") |>
  dplyr::select("pc_discr_id" = id,
                alias_id,
                name_detail = name,
                "pc_human_match" = human_match) |>
  dplyr::filter(!is.na(alias_id)) |>
  dplyr::distinct() |>
  dplyr::collect()

### fromtokey database(course names from robots) ####
ftk <- conex_RDS |>
  dplyr::tbl("me_v3_pricing_fromtokey") |>
  dplyr::filter(discr == "pricing_course_level_1",
                arg != "n/c",
                arg != "-new-") |>
  dplyr::select("name_detail" = arg,
                "ftk_robot_id" = robot_id,
                "ftk_discr_id" = discr_id) |>
  dplyr::distinct() |>
  dplyr::collect() |>
  dplyr::left_join(pc |>
                     dplyr::select(alias_id,
                                   pc_discr_id),
                   by = c("ftk_discr_id" = "pc_discr_id")) |>
  dplyr::filter(!is.na(alias_id))

### coursealias(labels from mercadoedu) with course(censo data) ####
csalias_cs <- csalias |>
  dplyr::left_join(cs |>
                     dplyr::select(-name),
                   by = "alias_id") |>
  dplyr::mutate("source" = "course")

### IN coursealias(labels from mercadoedu) AND NOT IN course(censo) ####
anti_csalias_cs <- csalias |>
  dplyr::anti_join(cs,
                   by = "alias_id")

### IN course(censo) AND NOT IN coursealias(labels from mercadoedu) ####
anti_cs_csalias <- cs |>
  dplyr::anti_join(csalias,
                   by = "alias_id")

### csalias(labels from mercadoedu)  with pricing_course(labels from quarentine) ####
csalias_pc <- csalias |>
  dplyr::left_join(pc,
                   by = "alias_id") |>
  dplyr::mutate("source" = "pricing_course")

### IN coursealias(labels from mercadoedu) AND NOT IN pricing_course(labels from quarentine) ####
anti_csalias_pc <- csalias |>
  dplyr::anti_join(pc,
                   by = "alias_id")

### IN pricing_course(labels from quarentine) AND NOT IN coursealias(labels from mercadoedu) ####
anti_pc_csalias <- pc |>
  dplyr::anti_join(csalias,
                   by = "alias_id")

### csalias(labels from mercadoedu) with fromtokey(course names from robots) ####
csalias_ftk <- csalias |>
  dplyr::left_join(ftk,
                   by = "alias_id") |>
  dplyr::mutate("source" = "fromtokey")

### IN coursealias(labels from mercadoedu) AND NOT IN fromtokey(course names from robots) ####
anti_csalias_ftk <- csalias |>
  dplyr::anti_join(ftk,
                   by = "alias_id")

### IN fromtokey(course names from robots) AND NOT IN coursealias(labels from mercadoedu) ####
anti_ftk_csalias <- ftk |>
  dplyr::anti_join(csalias,
                   by = "alias_id")

all_dbs <- csalias_cs |>
  dplyr::bind_rows(csalias_pc,
                   csalias_ftk) |>
  dplyr::arrange(alias_id)

all_dbs_dist <- all_dbs |>
  dplyr::distinct(alias_id,
                  name,
                  name_detail,
                  source)


#--------------------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------------------#
## Check databases ####
#----------------------------------------------------------#
c("Check",
  "Databases") |>
  FCSUtils::title_ascii(text_color = "blue")
#----------------------------------------------------------#

### Stopwords ####
db_stopwords <- conex_MODEL |>
  dplyr::tbl("model_stopwords") |>
  dplyr::pull("words")

### First database ####
check_all_dbs <- all_dbs |>
  dplyr::mutate("clean_name" = name_detail |>
                  mercadoedu.tc::correct_strings() |>
                  stringr::str_replace_all("([:punct:])|([:digit:])|(\\|)|(ª)|(º)|(°)",
                                           " ") |>
                  stringr::str_to_lower(locale = "br") |>
                  tm::removeWords(db_stopwords) |>
                  stringr::str_squish()) |>
  dplyr::arrange(clean_name)

### clean_name blanks ####
check_1_all_dbs <- check_all_dbs |>
  dplyr::filter(clean_name == "")

### freq for which group(name, name_detail) ####
check_2_all_dbs <- check_all_dbs |>
  dplyr::select(alias_id,
                name,
                clean_name) |>
  dplyr::filter(clean_name != "") |>
  dplyr::arrange(clean_name) |>
  dplyr::count(alias_id,
               name,
               clean_name) |>
  dplyr::arrange(clean_name) |>
  dplyr::group_by(clean_name) |>
  dplyr::filter(dplyr::n_distinct(name) > 1) |>
  dplyr::ungroup() |>
  dplyr::arrange(clean_name)

### number of differents name for which clean_name ####
check_3_all_dbs <- check_all_dbs |>
  dplyr::filter(clean_name != "") |>
  dplyr::arrange(clean_name) |>
  dplyr::group_by(clean_name) |>
  dplyr::summarise("names_distinct" = dplyr::n_distinct(name)) |>
  dplyr::ungroup() |>
  dplyr::filter(names_distinct > 1) |>
  dplyr::arrange(clean_name)

### Correct wrong alias_id from clean_name ####
correct <- check_2_all_dbs |>
  dplyr::arrange(clean_name,
                 dplyr:::desc(n)) |>
  dplyr::distinct(clean_name,
                  .keep_all = T)

check_all_dbs_corrected <- check_all_dbs |>
  dplyr::left_join(correct |>
                     dplyr::select(-n) |>
                     dplyr::rename("corrected_alias_id" = alias_id,
                                   "corrected_name" = name),
                   by = "clean_name") |>
  dplyr::mutate("changed" = dplyr::case_when(name != corrected_name &
                                             alias_id != corrected_alias_id ~ TRUE,
                                             TRUE ~ FALSE),
                "new_name" = dplyr::case_when(changed ~ corrected_name,
                                              TRUE ~ name),
                "new_alias_id" = dplyr::case_when(changed ~ corrected_alias_id,
                                                  TRUE ~ alias_id)) |>
  dplyr::select(changed,
                new_alias_id,
                alias_id,
                new_name,
                name,
                name_detail,
                clean_name,
                source,
                dplyr::starts_with("cs_"),
                dplyr::starts_with("pc_"),
                dplyr::starts_with("ftk_")) |>
  dplyr::arrange(alias_id)

data <- check_3_all_dbs

#--------------------------------------------------------------------------------------------------#
#==================================================================================================#
