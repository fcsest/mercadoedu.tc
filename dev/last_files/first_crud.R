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

all_dbs <- conex_RDS |>
  mercadoedu.tc::mount_frankenstein(stopwords_con = conex_MODEL)

# all_dbs_dist <- all_dbs |>
#   dplyr::distinct(alias_id,
#                   name,
#                   name_detail,
#                   source)

#--------------------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------------------#
## Check databases ####
#----------------------------------------------------------#
c("Check",
  "Databases") |>
  FCSUtils::title_ascii(text_color = "blue")
#----------------------------------------------------------#

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
