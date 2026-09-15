library(shiny)

redirect_url <- "https://carlosespinozacruz-retro-bac.share.connect.posit.cloud"

ui <- fluidPage(
  tags$head(
    # Fallback redirect in case JS is disabled
    tags$meta(
      `http-equiv` = "refresh",
      content = paste0("2; url=", redirect_url)
    )
  ),
  tags$div(
    style = "text-align: center; margin-top: 20vh; font-family: sans-serif; opacity: 0.7;",
    tags$h3("Redirecting to updated app"),
    tags$p(
      "If you are not redirected automatically, ",
      tags$a(href = redirect_url, "click here.")
    )
  ),
  tags$script(HTML(sprintf(
    "setTimeout(function() { window.location.replace('%s'); }, 2000);",
    redirect_url
  )))
)

server <- function(input, output, session) {}

shinyApp(ui, server)
