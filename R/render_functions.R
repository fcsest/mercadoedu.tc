render_readme_rmd <- function() {
  "README.md" |>
    here::here() |>
    file.remove()

  rmarkdown::render("./README.Rmd")
}
