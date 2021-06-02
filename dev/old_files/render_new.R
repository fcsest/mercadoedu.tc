# Render HTML Page
"docs" |>
  here::here() |>
  list.files(pattern = "index.html",
             full.names = TRUE) |>
  c(list.files(here::here(),
               pattern = "README.html|README.md",
               full.names = TRUE)) |>
  purrr::map(file.remove)

"README.Rmd" |>
  here::here() |>
  rmarkdown::render("html_document",
                    output_file = here::here("docs",
                                             "index.html"),
                    encoding = "UTF-8")
#==================================================================================================#

# Render README.md
"index.html" |>
  here::here() |>
  file.remove()

# Parei aqui
"index.Rmd" |>
  readLines(encoding = "UTF-8") |>
  purrr::discard(stringr::str_detect(.x, "title: ")) |>
  stringr::str_replace_all("./images/",
                           "./inst/readme/images/") |>
  stringr::str_conv(encoding = "UTF-8") |>
  writeLines(con = here::here("inst",
                              "readme",
                              "README_md.Rmd"))

rmarkdown::render(here::here("inst",
                             "readme",
                             "README_md.Rmd"),
                  "github_document",
                  output_file = here::here("README.md"))

readLines(here::here("README.md"),
          encoding = "UTF-8") %>%
  vctrs::vec_slice(21:length(.)) %>%
  stringr::str_conv(encoding = "UTF-8") %>%
  writeLines(con = here::here("README.md"))


file.remove(here::here("inst",
                       "readme",
                       "README_md.Rmd"))

file.remove(here::here("README.html"))
