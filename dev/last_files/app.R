ui <- bs4Dash::dashboardPage(header = bs4Dash::dashboardHeader(
  compact = F,
  border = T,
  fixed = T,
  htmltools::div(style = "margin: 0 0 0 -30px;",
    bs4Dash::actionButton("clear_btn",
                          "Limpar todas seleções",
                          style = "margin-right:16px;",
                          status = "danger"),
    bs4Dash::actionButton("expand_btn",
                          "Expandir linhas",
                          style = "margin-right:16px;",
                          status = "info"),
    bs4Dash::actionButton("collapse_btn",
                          "Retrair linhas",
                          style = "margin-right:16px;",
                          status = "primary"),
    bs4Dash::actionButton("check_btn",
                          "Conferir seleções",
                          style = "margin-right:16px;",
                          status = "success"),
    bs4Dash::actionButton("modify_btn",
                          "Modificar no banco",
                          status = "warning")
  )
),
sidebar = bs4Dash::dashboardSidebar(disable = T),
body = bs4Dash::dashboardBody(
  reactable::reactableOutput("table")
),
controlbar = bs4Dash::dashboardControlbar(
  collapsed = TRUE,
  htmltools::div(class = "p-3", bs4Dash::skinSelector()),
  pinned = FALSE
),
title = "mercadoedu CRUD",
scrollToTop = TRUE,
dark = TRUE
)

server <- function(input, output) {
  x <- as.list(rep("NULL", nrow(data)))
  names(x) <- paste0("tbl_", 1:nrow(data))

  selected <- do.call("reactiveValues", x)

  output$table <- reactable::renderReactable({
    reactable::reactable(data,
              wrap = FALSE,
              striped = FALSE,
              pagination = FALSE,
              searchable = FALSE,
              showPageInfo = FALSE,
              showPagination = FALSE,
              bordered = TRUE,
              resizable = TRUE,
              highlight = TRUE,
              filterable = TRUE,
              onClick = "expand",
              rowStyle = list(cursor = "pointer"),
              columns = list(
                names_distinct = reactable::colDef(name = "Possíveis nomes agregados",
                                        minWidth = 100,
                                        maxWidth = 300,
                                        align = "center"),
                clean_name = reactable::colDef(name = "Nome detalhado limpo")),
              theme = reactable::reactableTheme(
                color = "hsl(233, 9%, 87%)",
                backgroundColor = "hsl(233, 9%, 19%)",
                borderColor = "hsl(233, 9%, 22%)",
                stripedColor = "hsl(233, 12%, 22%)",
                highlightColor = "hsl(233, 12%, 24%)",
                inputStyle = list(backgroundColor = "hsl(233, 9%, 25%)"),
                selectStyle = list(backgroundColor = "hsl(233, 9%, 25%)"),
                pageButtonHoverStyle = list(backgroundColor = "hsl(233, 9%, 25%)"),
                pageButtonActiveStyle = list(backgroundColor = "hsl(233, 9%, 28%)"),
                rowSelectedStyle = list(backgroundColor = "hsl(233, 12%, 24%)",
                                        boxShadow = "inset 2px 0 0 0 #ffa62d"),
                searchInputStyle = list(width = "100%")),
              details = function(index, rowInfo) {
                htmltools::div(style = "padding: 16px",
                               reactable::reactableOutput(paste0("tbl_", index))
                )
              }
    )
  })

  lapply(seq_len(nrow(data)), function(index) {
    observe({
      selected[[paste0("tbl_", index)]] <- reactable::getReactableState(paste0("tbl_",
                                                                               index),
                                                                        "selected")
    })

    observeEvent(input$clear_btn, {
      # Clear row selection using NA or integer(0)
      selected[[paste0("tbl_", index)]] <- NULL
    })

    output[[paste0("tbl_", index)]] <- reactable::renderReactable({
      specific_data <- check_2_all_dbs[check_2_all_dbs$clean_name == data$clean_name[index], ] |>
        dplyr::select(n,
                      name,
                      alias_id)

      reactable::reactable(specific_data,
                wrap = FALSE,
                striped = FALSE,
                filterable = FALSE,
                searchable = FALSE,
                pagination = FALSE,
                showPageInfo = FALSE,
                showPagination = FALSE,
                bordered = TRUE,
                resizable = TRUE,
                highlight = TRUE,
                onClick = "select",
                selection = "single",
                rowStyle = list(cursor = "pointer"),
                defaultSelected = selected[[paste0("tbl_", index)]],
                columns = list(
                  alias_id = reactable::colDef(name = "Alias ID",
                                    minWidth = 100,
                                    maxWidth = 100,
                                    align = "left"),
                  name = reactable::colDef(name = "Nome agregado do curso",
                                minWidth = 200),
                  n = reactable::colDef(name = "Quantidade de classificações",
                             minWidth = 100,
                             maxWidth = 250,
                             align = "center")),
                theme = reactable::reactableTheme(
                  color = "hsl(233, 9%, 87%)",
                  backgroundColor = "hsl(233, 9%, 19%)",
                  borderColor = "hsl(233, 9%, 22%)",
                  stripedColor = "hsl(233, 12%, 22%)",
                  highlightColor = "hsl(233, 12%, 24%)",
                  inputStyle = list(backgroundColor = "hsl(233, 9%, 25%)"),
                  selectStyle = list(backgroundColor = "hsl(233, 9%, 25%)"),
                  pageButtonHoverStyle = list(backgroundColor = "hsl(233, 9%, 25%)"),
                  pageButtonActiveStyle = list(backgroundColor = "hsl(233, 9%, 28%)"),
                  rowSelectedStyle = list(backgroundColor = "hsl(233, 12%, 24%)",
                                          boxShadow = "inset 2px 0 0 0 #ffa62d"))
      )
    })
  })

  observeEvent(input$expand_btn, {
    # Expand all rows
    reactable::updateReactable("table", expanded = TRUE)
  })

  observeEvent(input$collapse_btn, {
    # Collapse all rows
    reactable::updateReactable("table", expanded = FALSE)
  })

  observeEvent(input$collapse_btn, {
    # Collapse all rows
    reactable::updateReactable("table", expanded = FALSE)
  })
}

shiny::shinyApp(ui, server, options = list("launch.browser" = T))
