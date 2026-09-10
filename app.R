library(shiny)
library(bslib)
library(lubridate)
library(shinyvalidate)
library(ggplot2)
library(shinyjs)
library(shinydisconnect)
library(officer)
library(sass)

version <- "1.2"
source("R/calculos.R")
source("R/grafico.R")
source("R/otros.R")

# --- Constantes ---
# BETA_MIN y BETA_MAX se definen en R/calculos.R (fuente única de verdad).
# DENSIDAD_ETANOL <- 0.789 # g/mL
#
# # Definición de bebidas estándar (aproximadamente 1 UBE = 10g de etanol)
# beverages_data <- list(
#   "Cerveza (Caña/Tercio, 300ml, 5%)" = list(
#     vol_ml = 300,
#     abv = 5,
#     etiqueta_ube = "~1 UBE"
#   ),
#   "Vino (Copa, 125ml, 13%)" = list(
#     vol_ml = 125,
#     abv = 13,
#     etiqueta_ube = "~1.3 UBE"
#   ),
#   "Destilado (Combinado/Chupito, 50ml, 40%)" = list(
#     vol_ml = 50,
#     abv = 40,
#     etiqueta_ube = "~1.6 UBE"
#   ),
#   "Vermut/Jerez (Copa, 70ml, 15%)" = list(
#     vol_ml = 70,
#     abv = 15,
#     etiqueta_ube = "~0.8 UBE"
#   )
# )
#
# # Calcular gramos de etanol para cada bebida
# for (bev_name in names(beverages_data)) {
#   bev <- beverages_data[[bev_name]]
#   beverages_data[[bev_name]]$gramos_etanol <- round(
#     bev$vol_ml * (bev$abv / 100) * DENSIDAD_ETANOL,
#     1
#   )
# }

# --- UI ---
ui <- page_sidebar(
  lang = "en",
  title = div(
    class = "app-title-wrapper",
    h1("Retro-BAC", class = "app-title"),
    h5("Retrograde extrapolation alcohol calculation", class = "app-subtitle")
  ),

  theme = bs_theme(
    version = 5,
    bootswatch = "flatly",
    base_font = "Hedvig Letters Sans",
    heading_font = "Hedvig Letters Sans",
    primary = "#2C3E50",
    fg = "#19222A",
    bg = "#F5F8FA",
    secondary = "#67839A"
  ),

  # gfonts::setup_font("hedvig-letters-sans", "www/")
  gfonts::use_font(
    id = "hedvig-letters-sans",
    css_path = "www/css/hedvig-letters-sans.css",
    css = "font-family: 'Hedvig Letters Sans';"
  ),

  useShinyjs(),

  withMathJax(),

  disconnectMessage(
    text = "The app has been disconnected. Please reconnect to continue your session.",
    refresh = "Reconnect app",
    background = "#2C3E50",
    colour = "white",
    overlayColour = "white"
  ),

  # css
  tags$head(
    tags$style(HTML(sass(sass_file("estilos.scss")))),
    # captura el ancho de la ventana como input$window_width
    tags$script(HTML(
      "$(document).on('shiny:connected', function() {
         Shiny.setInputValue('window_width', window.innerWidth);
       });
       $(window).on('resize', function() {
         Shiny.setInputValue('window_width', window.innerWidth);
       });"
    ))
  ),

  # sidebar ----
  sidebar = sidebar(
    open = list(
      desktop = "open",
      mobile = "always-above"
    ),

    width = 350,

    h6("Sample:"),

    numericInput(
      "bac_medido",
      HTML(
        "Blood Alcohol Concentration tested: <span class='input-format'>(g/L)</span>"
      ),
      value = 0.8,
      min = 0,
      max = 5,
      step = 0.01
    ),
    dateInput(
      "fecha_medicion",
      "Date of sample collection:",
      value = Sys.Date(),
      format = "dd/mm/yyyy",
      language = "en"
    ),
    textInput(
      "hora_medicion",
      HTML(
        "Time of sample colection: <span class='input-format'>(HH:MM)</span>"
      ),
      value = format(Sys.time() - hours(1), "%H:%M")
    ),

    h6("Event:"),
    dateInput(
      "fecha_evento",
      "Date of incident:",
      value = Sys.Date(),
      format = "dd/mm/yyyy",
      language = "en"
    ),
    textInput(
      "hora_evento",
      HTML("Time of incident: <span class='input-format'>(HH:MM)</span>"),
      value = format(Sys.time() - hours(3), "%H:%M")
    ),
    actionButton(
      "calcular",
      "Calculate extrapolation",
      class = "btn-primary btn-lg w-100",
      icon = icon("calculator")
    ),

    downloadButton("descargar_reporte", "Download report") |> disabled(),

    hr(),
    helpText(
      paste0(
        "Note: Alcohol elimination rate (β) varies between ",
        BETA_MIN,
        " and ",
        BETA_MAX,
        " g/L/h."
      )
    ),
    helpText(
      "Ensure that the date/time of the event is prior to the date/time of the measurement."
    )

    # helpText(
    #   paste("v", version)
    # )
  ),

  div(
    style = "max-width: 800px;",
    # navset_tab(
    # id = "main_tabs",
    # nav_panel(
    # title = "Extrapolation", icon = icon("chart-line"),
    layout_column_wrap(
      width = "100%",
      heights_equal = "row",

      # results ----
      card(
        # class = "shadow-sm mb-3",
        card_header(h4("Results")),
        card_body(
          div(
            markdown(
              "No results to show. Press _Calculate extrapolation_ to get results."
            ),
            id = "no_results",
            class = "no-results-msg",
            role = "alert"
          ) |>
            hidden(),
          uiOutput("resultados_ui")
        )
      ),
      card(
        # class = "shadow-sm mb-3",
        full_screen = TRUE,
        card_header(h4("Retrograde extrapolation plot")),
        card_body(
          div(
            markdown(
              "No results to show. Press _Calculate extrapolation_ to get results."
            ),
            id = "no_results_plot",
            class = "no-results-msg",
            role = "alert"
          ) |>
            hidden(),
          plotOutput("bac_plot")
        )
      ),

      ## detalles ----
      # El id "calculos_detallados_card_body" se usa para que el CSS pueda apuntar a los h5 dentro.
      # O simplemente se puede poner el uiOutput directo y apuntar con #calculos_detallados_ui h5
      card(
        # class = "shadow-sm mb-3",
        card_header(h4("Calculation details")),
        card_body(
          id = "calculos_detallados_card_body",
          div(
            markdown(
              "No results to show. Press _Calculate extrapolation_ to get results."
            ),
            id = "no_results_calculos",
            class = "no-results-msg",
            role = "alert"
          ) |>
            hidden(),
          uiOutput("calculos_detallados_ui")
        )
      ),

      ## notas ----
      card(
        # class = "shadow-sm",
        card_header(h4("Important Notes and Interpretation")),
        card_body(
          tags$ul(
            tags$li(
              "Retrograde extrapolation is a mathematical estimation based on Widmark's formula:",
              # helpText(
              "$$AC_{inc} = AC_{test} + (\\beta \\times t)$$",
              # ),
              "where \\(AC_{inc}\\) is the estimated alcohol concentration at the time of the incident, \\(AC_{test}\\) is the measured alcohol concentration, \\(\\beta\\) is the elimination rate, and \\(t\\) is the elapsed time between the incident and the sample."
            ),
            tags$li(
              "The results show a ",
              tags$strong("range of possible concentrations"),
              ", due to individual variability in the alcohol elimination rate (\\(\\beta\\))."
            ),
            tags$li(
              "Factors such as sex, weight, food intake, drinking pattern, and state of health can influence the actual elimination rate and are not accounted for in this simplified calculation."
            ),
            tags$li(
              "This tool is intended to support expert forensic analysis; however, it does not carry legal validity by itself."
            )
          ),
          h5("Reference:"),

          tags$ul(
            tags$a(
              href = "https://www.aafs.org/asb-standard/best-practice-recommendation-performing-alcohol-calculations-forensic-toxicology",
              target = "_blank",
              "Best Practice Recommendation for Performing Alcohol Calculations in Forensic Toxicology"
            )
          )
        )
      )
    )
    # ),
    # )
    ## (x) signos y síntomas ----
    # nav_panel(
    #   title = "Signos y Síntomas", icon = icon("notes-medical"),
    #   h3("Signos y Síntomas Clínicos Asociados a la Alcoholemia"),
    #   p("Esta sección muestra los signos y síntomas generalmente asociados con diferentes niveles de concentración de alcohol en sangre (CAS / BAC)."),
    #   sliderInput("bac_sintomas_selector", "Nivel de BAC (g/L) para consultar síntomas:", min = 0, max = 4, value = 0.8, step = 0.05, width = '100%'),
    #   uiOutput("sintomas_output")
    # ),

    ## (x) estimación de bebidas ----
    # nav_panel(
    #   title = "Estimación de Bebidas", icon = icon("beer-mug-empty"),
    #   h3("Estimación de Bebidas Consumidas"),
    #   p("Esta herramienta estima la cantidad de bebidas alcohólicas que una persona necesitaría consumir para alcanzar un determinado nivel de alcoholemia (BAC), según la fórmula de Widmark. Es una estimación teórica y la absorción real puede variar."),
    #   card(class="shadow-sm mb-3", card_header("Datos para la estimación de bebidas"),
    #        card_body(
    #          fluidRow(
    #            column(6, numericInput("bac_para_bebidas", "Nivel de BAC objetivo (g/L):", value = 0.8, min = 0.01, max = 4, step = 0.01)),
    #            column(6, numericInput("peso_estimacion", "Peso Corporal (kg):", value = 70, min = 30, max = 200, step = 1))
    #          ),
    #          fluidRow(
    #            column(6, radioButtons("sexo_estimacion", "Sexo Biológico:", choices = c("Hombre", "Mujer"), selected = "Hombre", inline = TRUE)),
    #            column(6, selectInput("tipo_bebida_estimacion", "Tipo de Bebida Estándar:", choices = names(beverages_data)))
    #          ),
    #          actionButton("calcular_bebidas", "Estimar Cantidad de Bebidas", class = "btn-primary w-100", icon = icon("calculator"))
    #        )),
    #   uiOutput("bebidas_output")
    # )
    # )
  )
)


# server ----
server <- function(input, output, session) {
  # ancho de la ventana (debounce para evitar actualizaciones excesivas)
  ancho <- reactive(input$window_width)
  ancho <- debounce(ancho, 400)

  # estado móvil/desktop: solo se actualiza al cruzar el umbral (600px),
  # así el gráfico no se redibuja con cada cambio de ancho
  es_movil <- reactiveVal(FALSE)
  observeEvent(ancho(), {
    es_movil(!is.null(ancho()) && ancho() < 600)
  })

  observe(
    if (input$calcular == 0) {
      show("no_results")
      show("no_results_plot")
      show("no_results_calculos")
      disable("descargar_reporte")
    } else {
      hide("no_results")
      hide("no_results_plot")
      hide("no_results_calculos")
      enable("descargar_reporte")
    }
  )

  observeEvent(
    input$bac_medido,
    {
      current_bac <- input$bac_medido
      if (!is.na(current_bac) && is.numeric(current_bac)) {
        updateSliderInput(session, "bac_sintomas_selector", value = current_bac)
        updateNumericInput(session, "bac_para_bebidas", value = current_bac)
      }
    },
    ignoreNULL = TRUE,
    ignoreInit = TRUE
  )

  ## validación ----
  iv <- InputValidator$new()

  iv$add_rule(
    "bac_medido",
    sv_required("A tested BAC value is required.")
  )
  iv$add_rule("bac_medido", sv_gte(0, "The tested BAC cannot be negative."))
  iv$add_rule(
    "hora_medicion",
    sv_required("The time of sample collection is required.")
  )
  iv$add_rule(
    "hora_medicion",
    sv_regex(
      "^([01]?[0-9]|2[0-3]):[0-5][0-9]$",
      "Time of sample collection: HH:MM format."
    )
  )
  iv$add_rule("hora_evento", sv_required("The time of incident is required."))
  iv$add_rule(
    "hora_evento",
    sv_regex(
      "^([01]?[0-9]|2[0-3]):[0-5][0-9]$",
      "Time of incident: HH:MM format."
    )
  )

  iv$add_rule("fecha_medicion", function(value) {
    if (is.null(value) || is.null(input$fecha_evento)) {
      return(NULL)
    }
    if (value < input$fecha_evento) {
      return(
        "The date of sample collection cannot be earlier than the date of incident."
      )
    }
    return(NULL)
  })

  iv$add_rule("fecha_evento", function(value) {
    if (
      !nzchar(input$hora_medicion) ||
        !nzchar(input$hora_evento) ||
        !grepl("^([01]?[0-9]|2[0-3]):[0-5][0-9]$", input$hora_medicion) ||
        !grepl("^([01]?[0-9]|2[0-3]):[0-5][0-9]$", input$hora_evento)
    ) {
      return(NULL)
    }
    tiempo_medicion <- ymd_hm(
      paste(input$fecha_medicion, input$hora_medicion),
      tz = Sys.timezone()
    )
    tiempo_evento <- ymd_hm(
      paste(input$fecha_evento, input$hora_evento),
      tz = Sys.timezone()
    )
    if (is.na(tiempo_medicion) || is.na(tiempo_evento)) {
      return(
        "Error combining dates and times. Please check that the dates are valid."
      )
    } else if (tiempo_evento >= tiempo_medicion) {
      return("The incident must occur before the sample collection.")
    }
    return(NULL)
  })
  iv$enable()

  resultado <- eventReactive(input$calcular, {
    req(iv$is_valid(), cancelOutput = TRUE)

    tiempo_medicion_val <- ymd_hm(
      paste(input$fecha_medicion, input$hora_medicion),
      tz = Sys.timezone()
    )
    tiempo_evento_val <- ymd_hm(
      paste(input$fecha_evento, input$hora_evento),
      tz = Sys.timezone()
    )
    horas_transcurridas <- calcular_horas(
      tiempo_evento_val,
      tiempo_medicion_val
    )
    extrap <- extrapolar_bac(
      bac_medido = input$bac_medido,
      horas_transcurridas = horas_transcurridas,
      beta_min = BETA_MIN,
      beta_max = BETA_MAX
    )

    list(
      horas = extrap$horas,
      bac_min = extrap$bac_min,
      bac_max = extrap$bac_max,
      bac_medido_val = extrap$bac_medido,
      tiempo_medicion_val = tiempo_medicion_val,
      tiempo_evento_val = tiempo_evento_val,
      beta_min_val = extrap$beta_min,
      beta_max_val = extrap$beta_max
    )
  })

  output$resultados_ui <- renderUI({
    res <- resultado()
    req(res)
    tagList(
      p(
        strong("Time between incident and time of blood draw: "),
        paste(res$horas, "hours")
      ),
      tags$div(
        class = "alert alert-success fs-5",
        role = "alert",
        HTML(paste0(
          "Estimated BAC at time of the incident: ",
          tags$strong(res$bac_min |> formatC(digits = 2, format = "f")),
          " – ",
          tags$strong(res$bac_max |> formatC(digits = 2, format = "f")),
          " g/L"
        ))
      )
    )
  })

  ## gráfico ----
  # construye el gráfico; es_movil controla la adaptación responsiva

  output$bac_plot <- renderPlot(
    {
      construir_grafico(resultado(), es_movil = es_movil())
    },
    res = 96
  )

  output$calculos_detallados_ui <- renderUI({
    res <- resultado()
    req(res) # Solo proceder si hay un resultado válido

    fmt <- function(x) formatC(x, digits = 2, format = "f")

    bac <- res$bac_medido_val
    prod_min <- round(res$beta_min_val * res$horas, 3)
    prod_max <- round(res$beta_max_val * res$horas, 3)

    withMathJax(tagList(
      p(
        # "The estimated alcohol concentration at the time of the incident is obtained from Widmark's retrograde extrapolation formula:",
        # helpText("$$AC_{inc} = AC_{test} + (\\beta \\times t)$$"),
        HTML(paste0(
          "For the calculation of estimated alcohol concentration at the time of the incident, \\(AC_{test} = ",
          fmt(bac),
          "\\,\\text{g/L}\\) is the measured concentration, \\(\\beta\\) is the elimination rate, ",
          "and \\(t = ",
          res$horas,
          "\\,\\text{h}\\) is the elapsed time between the incident and the sample. ",
          "The range is spanned by applying the minimum and maximum elimination rates."
        ))
      ),
      layout_columns(
        div(
          h5("Lower bound of the estimated range (\\(AC_{inc}^{\\,min}\\))"),
          p(HTML(paste0(
            "Using the minimum elimination rate \\(\\beta_{min} = ",
            fmt(res$beta_min_val),
            "\\,\\text{g/L/h}\\):"
          ))),
          # helpText(
          paste0(
            "$$\\begin{aligned}",
            "AC_{inc}^{\\,min} &= AC_{test} + (\\beta_{min} \\times t) \\\\",
            "&= ",
            fmt(bac),
            "\\,\\text{g/L} + (",
            fmt(res$beta_min_val),
            "\\,\\text{g/L/h} \\times ",
            res$horas,
            "\\,\\text{h}) \\\\",
            "&= ",
            fmt(bac),
            "\\,\\text{g/L} + ",
            fmt(prod_min),
            "\\,\\text{g/L} \\\\",
            "&= ",
            fmt(res$bac_min),
            "\\,\\text{g/L}",
            "\\end{aligned}$$"
          )
        ),

        div(
          h5("Upper bound of the estimated range (\\(AC_{inc}^{\\,max}\\))"),
          p(HTML(paste0(
            "Using the maximum elimination rate \\(\\beta_{max} = ",
            fmt(res$beta_max_val),
            "\\,\\text{g/L/h}\\):"
          ))),
          # helpText(
          paste0(
            "$$\\begin{aligned}",
            "AC_{inc}^{\\,max} &= AC_{test} + (\\beta_{max} \\times t) \\\\",
            "&= ",
            fmt(bac),
            "\\,\\text{g/L} + (",
            fmt(res$beta_max_val),
            "\\,\\text{g/L/h} \\times ",
            res$horas,
            "\\,\\text{h}) \\\\",
            "&= ",
            fmt(bac),
            "\\,\\text{g/L} + ",
            fmt(prod_max),
            "\\,\\text{g/L} \\\\",
            "&= ",
            fmt(res$bac_max),
            "\\,\\text{g/L}",
            "\\end{aligned}$$"
          )
        )
      )
    ))
  })

  # # --- Lógica para Pestaña de Signos y Síntomas ---
  # output$sintomas_output <- renderUI({
  #   bac <- input$bac_sintomas_selector
  #   sintomas_info <- list(
  #     list(
  #       rango = c(-Inf, 0.29),
  #       titulo = "BAC < 0.3 g/L (Muy Bajo - Leve)",
  #       efectos = c(
  #         "La mayoría de las personas no muestran efectos obvios o estos son muy leves.",
  #         "Ligera intensificación del humor."
  #       ),
  #       class = "alert-light"
  #     ),
  #     list(
  #       rango = c(0.3, 0.59),
  #       titulo = "BAC 0.3 - 0.59 g/L (Bajo - Euforia Leve)",
  #       efectos = c(
  #         "Sensación de bienestar, relajación, euforia leve.",
  #         "Reducción de la inhibición.",
  #         "Disminución de la atención y control."
  #       ),
  #       class = "alert-info"
  #     ),
  #     list(
  #       rango = c(0.6, 0.99),
  #       titulo = "BAC 0.6 - 0.99 g/L (Moderado - Excitación)",
  #       efectos = c(
  #         "Deterioro del juicio.",
  #         "Tiempo de reacción aumentado.",
  #         "Pérdida de coordinación muscular."
  #       ),
  #       class = "alert-primary"
  #     ),
  #     list(
  #       rango = c(1.0, 1.49),
  #       titulo = "BAC 1.0 - 1.49 g/L (Alto - Confusión)",
  #       efectos = c(
  #         "Confusión mental, desorientación.",
  #         "Alteraciones sensoriales.",
  #         "Ataxia severa."
  #       ),
  #       class = "alert-warning"
  #     ),
  #     list(
  #       rango = c(1.5, 2.49),
  #       titulo = "BAC 1.5 - 2.49 g/L (Muy Alto - Estupor)",
  #       efectos = c(
  #         "Estupor.",
  #         "Incapacidad para mantenerse de pie.",
  #         "Vómitos, riesgo de aspiración."
  #       ),
  #       class = "alert-danger"
  #     ),
  #     list(
  #       rango = c(2.5, 3.49),
  #       titulo = "BAC 2.5 - 3.49 g/L (Severo - Coma)",
  #       efectos = c("Coma.", "Reflejos deprimidos.", "Depresión respiratoria."),
  #       class = "alert-danger fw-bold"
  #     ),
  #     list(
  #       rango = c(3.5, Inf),
  #       titulo = "BAC ≥ 3.5 g/L (Potencialmente Letal)",
  #       efectos = c(
  #         "Depresión respiratoria severa/paro.",
  #         "Paro cardíaco.",
  #         "Muerte."
  #       ),
  #       class = "alert-danger fw-bolder"
  #     )
  #   )
  #   info_seleccionada <- NULL
  #   for (item in sintomas_info) {
  #     if (bac >= item$rango[1] && bac <= item$rango[2]) {
  #       info_seleccionada <- item
  #       break
  #     }
  #   }
  #   if (!is.null(info_seleccionada)) {
  #     tags$div(
  #       class = paste("card shadow-sm mt-3"),
  #       tags$div(
  #         class = paste("card-header fs-5", info_seleccionada$class),
  #         info_seleccionada$titulo
  #       ),
  #       tags$div(
  #         class = "card-body",
  #         tags$ul(
  #           class = "list-group list-group-flush",
  #           lapply(info_seleccionada$efectos, function(efecto) {
  #             tags$li(class = "list-group-item", efecto)
  #           })
  #         ),
  #         tags$p(
  #           class = "mt-3 small text-muted",
  #           "Fuente: Información general adaptada de fuentes toxicológicas y de salud pública. La respuesta individual al alcohol puede variar."
  #         )
  #       )
  #     )
  #   } else {
  #     tags$p(
  #       class = "alert alert-secondary mt-3",
  #       "No se encontró información para el nivel de BAC seleccionado o el nivel es 0."
  #     )
  #   }
  # })

  # --- Lógica para Pestaña de Estimación de Bebidas ---
  # calculo_bebidas_res <- eventReactive(input$calcular_bebidas, {
  #   shiny::validate(
  #     need(isTruthy(input$bac_para_bebidas) && input$bac_para_bebidas > 0, "El BAC objetivo debe ser un número positivo."),
  #     need(isTruthy(input$peso_estimacion) && input$peso_estimacion > 0, "El peso debe ser un número positivo."),
  #     need(isTruthy(input$sexo_estimacion), "Debe seleccionar un sexo biológico."),
  #     need(isTruthy(input$tipo_bebida_estimacion), "Debe seleccionar un tipo de bebida.")
  #   )
  #
  #   peso <- input$peso_estimacion
  #   sexo <- input$sexo_estimacion
  #   bac_objetivo <- input$bac_para_bebidas
  #   bebida_seleccionada_nombre <- input$tipo_bebida_estimacion
  #
  #   r_widmark <- ifelse(sexo == "Hombre", 0.68, 0.55)
  #   gramos_alcohol_totales <- bac_objetivo * peso * r_widmark
  #
  #   info_bebida <- beverages_data[[bebida_seleccionada_nombre]]
  #   gramos_etanol_por_bebida <- info_bebida$gramos_etanol
  #
  #   if (is.null(gramos_etanol_por_bebida) || gramos_etanol_por_bebida <= 0) {
  #     shiny::validate("Error: La bebida seleccionada no tiene un contenido alcohólico definido correctamente.")
  #   }
  #
  #   numero_bebidas <- round(gramos_alcohol_totales / gramos_etanol_por_bebida, 1)
  #
  #   list(
  #     numero_bebidas = numero_bebidas, bebida_nombre = bebida_seleccionada_nombre, etiqueta_ube = info_bebida$etiqueta_ube,
  #     gramos_alcohol_totales = round(gramos_alcohol_totales,1), bac_objetivo = bac_objetivo,
  #     peso = peso, sexo = sexo, r_widmark = r_widmark
  #   )
  # })

  # output$bebidas_output <- renderUI({
  #   req(input$calcular_bebidas > 0)
  #   res_bebidas_data <- calculo_bebidas_res()
  #   req(res_bebidas_data)
  #
  #   card(class = "shadow-sm mt-3", card_header("Resultado de la Estimación de Bebidas"),
  #        card_body(
  #          p(HTML(paste0("Para alcanzar un BAC de aproximadamente <strong>", res_bebidas_data$bac_objetivo, " g/L</strong>, una persona de <strong>",
  #                        res_bebidas_data$sexo, "</strong> con un peso de <strong>", res_bebidas_data$peso, " kg</strong> (usando factor de Widmark r = ", res_bebidas_data$r_widmark,"), necesitaría consumir aproximadamente:" ))),
  #          h4(class = "text-center text-primary", style="font-size: 2em; margin-top: 1rem; margin-bottom: 0.5rem;",
  #             paste(res_bebidas_data$numero_bebidas, "dosis de", res_bebidas_data$bebida_nombre)),
  #          p(class = "text-center", paste0("(",res_bebidas_data$etiqueta_ube, ", aprox. ", beverages_data[[res_bebidas_data$bebida_nombre]]$gramos_etanol, "g de etanol por dosis)")),
  #          p(class = "text-center small", paste0("Esto equivale a un total estimado de ", res_bebidas_data$gramos_alcohol_totales, " gramos de etanol puro.")),
  #          hr(),
  #          p(strong("Nota Importante:"), class = "text-danger"),
  #          tags$ul(
  #            tags$li("Esta es una estimación teórica basada en la fórmula de Widmark (A = C * W * r)."), # Fórmula en texto plano
  #            tags$li("No considera la velocidad de ingesta, alimentos consumidos, fase de absorción o eliminación del alcohol durante el consumo."),
  #            tags$li("La respuesta individual al alcohol y el BAC real alcanzado pueden variar significativamente."),
  #            tags$li("Este cálculo no debe usarse para tomar decisiones sobre la capacidad para conducir o realizar actividades de riesgo.")
  #          )))
  # })

  # reporte ----

  reporte <- reactive({
    doc <- read_docx()

    # Título
    doc <- body_add_par(
      doc,
      "Retrograde extrapolation alcohol calculation",
      style = "heading 1"
    )

    doc <- body_add_par(
      doc,
      "Report generated automatically by Retro-BAC web app."
    )

    doc <- body_add_par(
      doc,
      "Results:",
      style = "heading 2"
    )

    # Datos de entrada
    doc <- body_add_par(
      doc,
      paste("Blood alcohol concentration:", resultado()$bac_medido_val, "g/L"),
      style = "Normal"
    )

    doc <- body_add_par(
      doc,
      paste(
        "Elapsed time between incident and sample:",
        resultado()$horas,
        "horas"
      ),
      style = "Normal"
    )

    # # Insertar tabla
    # tabla <- datos_proyeccion()
    # doc <- body_add_par(doc, "Resultados:", style = "heading 2")
    # doc <- body_add_table(doc, value = tabla, style = "table_template")
    # browser()
    doc <- body_add_par(
      doc,
      "Estimated blood alcohol concentration at time of event:",
      style = "heading 2"
    )

    doc <- body_add_par(
      doc,
      paste0(
        "Minimum (elimination rate ",
        BETA_MIN,
        "): ",
        resultado()$bac_min |> formatC(digits = 2, format = "f"),
        " g/L"
      ),
      style = "Normal"
    )
    doc <- body_add_par(
      doc,
      paste0(
        "Maximum (elimination rate ",
        BETA_MAX,
        "): ",
        resultado()$bac_max |> formatC(digits = 2, format = "f"),
        " g/L"
      ),
      style = "Normal"
    )

    doc <- body_add_par(
      doc,
      "Retrograde extrapolation plot:",
      style = "heading 2"
    )

    doc <- body_add_gg(
      doc,
      value = construir_grafico(resultado(), es_movil = FALSE),
      style = "centered"
    )
  })

  # download ----
  output$descargar_reporte <- downloadHandler(
    filename = function() {
      paste0("reporte_retroproyeccion_", Sys.Date(), ".docx")
    },
    content = function(file) {
      id <- showNotification(
        "Generating report...",
        duration = NULL,
        closeButton = FALSE,
        type = "message"
      )
      on.exit(removeNotification(id), add = TRUE)

      print(reporte(), target = file)
    }
  )
}

# --- Run ---
shinyApp(ui, server)
