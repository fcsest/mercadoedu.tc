# Function to correct htmls
correct_html <- function(html_file) {
  html_file |>
    readLines() |>
    stringr::str_subset(pattern = r'{<span class="version label label-default" data-toggle="tooltip" data-placement="bottom" title="Released version">0.0.1</span>}',
                        negate = T) |>
    stringr::str_replace_all(r'{<span class="navbar-brand">}',
                             r'{<span class="navbar-brand" style="padding-top:5px;">}') |>
    stringr::str_replace_all(r'{index.html">Text Classification</a>}',
                             r'{index.html"><img src="https://raw.githubusercontent.com/fcsest/mercadoedu.tc/main/inst/images/logo.png" style="padding-right: 10px;">Text Classification</a>}') |>
    writeLines(html_file)
}

# Remove md from root
"pkgdown" |>
  here::here("index.md") |>
  file.remove()

# Render md for pkgdown
"pkgdown" |>
  here::here("index.Rmd") |>
  rmarkdown::render(output_file = "pkgdown" |>
                      here::here("index.md"),
                    output_format = "md_document",
                    encoding = "UTF-8")

?rmarkdown::github_document()

# Render website
pkgdown::clean_site()
pkgdown::build_site()

# Correcting htmls
"docs" |>
  here::here() |>
  list.files(pattern = ".html",
             recursive = T,
             full.names = T) |>
  purrr::map(correct_html)

"pkgdown" |>
  here::here("index.md") |>
  file.remove()

