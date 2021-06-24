# conex_MODEL <- odbc::odbc() |>
#   DBI::dbConnect("Amazon RDS Model",
#                  timeout = 10)

conex_RDS <- odbc::odbc() |>
  DBI::dbConnect("Amazon RDS mercadoedu",
                 timeout = 10)

# Nomes agregados da mercadoedu
pricing_course <- conex_RDS |>
  dplyr::tbl("pricing_course") |>
  dplyr::filter(!is.na(alias_id)) |>
  dplyr::select("name", "alias_id", "id") |>
  dplyr::distinct() |>
  dplyr::collect()

# Nomes detalhados coletados da web
names_web <- conex_RDS |>
  dplyr::tbl("me_v3_pricing_fromtokey") |>
  dplyr::filter(discr == "pricing_course_level_1") |>
  dplyr::select("id" = discr_id, "name_detail" = arg, robot_id) |>
  dplyr::collect()

# automation_price <- conex_RDS |>
#   dplyr::tbl("me_v3_pricing_automation_price") |>
#   dplyr::tally()

pc <- pricing_course |>
  dplyr::left_join(names_web,
                   by = "id") |>
  dplyr::filter(!is.na(name_detail)) |>
  dplyr::arrange(alias_id, name, name_detail) |>
  dplyr::filter(id != alias_id) |>
  tibble::view(title = "pc")

names_dup <- pc |>
  dplyr::group_by(name_detail) |>
  dplyr::mutate("www" = dplyr::n_distinct(id)) |>
  dplyr::ungroup() |>
  dplyr::filter(www > 1) |>
  dplyr::arrange(name_detail)


pc_check1 <- pricing_course |>
  dplyr::arrange(alias_id) |>
  dplyr::group_by(alias_id) |>
  dplyr::filter(dplyr::n_distinct(name) > 1) |>
  dplyr::arrange(alias_id, name) |>
  tibble::view("pc_check1")
