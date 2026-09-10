library(shiny)
library(bslib)
library(lubridate)
library(shinyvalidate)
library(ggplot2)
library(shinyjs)
library(shinydisconnect)
library(officer)
# library(rvg)

version <- "1.2"

# --- Constantes ---
BETA_MIN <- 0.10 # g/L/hora
BETA_MAX <- 0.25 # g/L/hora
DENSIDAD_ETANOL <- 0.789 # g/mL

# Definición de bebidas estándar (aproximadamente 1 UBE = 10g de etanol)
beverages_data <- list(
  "Cerveza (Caña/Tercio, 300ml, 5%)" = list(
    vol_ml = 300,
    abv = 5,
    etiqueta_ube = "~1 UBE"
  ),
  "Vino (Copa, 125ml, 13%)" = list(
    vol_ml = 125,
    abv = 13,
    etiqueta_ube = "~1.3 UBE"
  ),
  "Destilado (Combinado/Chupito, 50ml, 40%)" = list(
    vol_ml = 50,
    abv = 40,
    etiqueta_ube = "~1.6 UBE"
  ),
  "Vermut/Jerez (Copa, 70ml, 15%)" = list(
    vol_ml = 70,
    abv = 15,
    etiqueta_ube = "~0.8 UBE"
  )
)

# Calcular gramos de etanol para cada bebida
for (bev_name in names(beverages_data)) {
  bev <- beverages_data[[bev_name]]
  beverages_data[[bev_name]]$gramos_etanol <- round(
    bev$vol_ml * (bev$abv / 100) * DENSIDAD_ETANOL,
    1
  )
}


# --- UI ---
ui <- page_sidebar(
  title = div(
    h1("Retro-BAC", class = "app-title"),
    h5("Retrograde extrapolation alcohol calculation")
  ),

  theme = bs_theme(
    version = 5,
    bootswatch = "flatly",
    base_font = font_google("Inter"),
    heading_font = font_google("Inter"),
    "primary" = "#2C3E50",
    "secondary" = "#3498DB"
  ),
  # Eliminamos withMathJax() de aquí

  useShinyjs(),

  disconnectMessage(
    text = p(
      "The app has been disconnected. Please reconnect to continue your session."
    ),
    refresh = "Reconnect app",
    background = "#2C3E50",
    colour = "white",
    overlayColour = "white"
  ),

  # css ----
  tags$head(
    includeCSS("estilos.css")
  ),

  sidebar = sidebar(
    width = 350,
    # h4("Input data"),
    numericInput(
      "bac_medido",
      "Blood Alcohol Concentration tested (g/L):",
      value = 0.8,
      min = 0,
      max = 5,
      step = 0.01
    ),
    dateInput(
      "fecha_medicion",
      "Date of sample colection:",
      value = Sys.Date(),
      format = "dd/mm/yyyy",
      language = "es"
    ),
    textInput(
      "hora_medicion",
      "Time of sample colection (HH:MM):",
      value = format(Sys.time() - hours(1), "%H:%M")
    ),
    dateInput(
      "fecha_evento",
      "Date of incident:",
      value = Sys.Date(),
      format = "dd/mm/yyyy",
      language = "es"
    ),
    textInput(
      "hora_evento",
      "Time incident (HH:MM):",
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
    ),

    helpText(
      paste("v", version)
    )
  ),

  page_fluid(
    # navset_tab(
    # id = "main_tabs",
    # nav_panel(
    # title = "Extrapolation", icon = icon("chart-line"),
    layout_column_wrap(
      width = "100%",
      heights_equal = "row",

      # Results ----
      card(
        class = "shadow-sm mb-3",
        card_header(h4("Results estimated")),
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
        class = "shadow-sm mb-3",
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
      # El id "calculos_detallados_card_body" se usa para que el CSS pueda apuntar a los h5 dentro.
      # O simplemente se puede poner el uiOutput directo y apuntar con #calculos_detallados_ui h5
      card(
        full_screen = TRUE,
        class = "shadow-sm mb-3",
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
      card(
        class = "shadow-sm",
        card_header(h4("Notas Importantes e Interpretación")),
        card_body(
          tags$ul(
            tags$li(
              "La retroproyección (o extrapolación retrógrada) es una estimación matemática."
            ),
            tags$li(
              "Se basa en la fórmula de Widmark: ",
              tags$code(
                "BAC_evento = BAC_medido + (tasa_eliminación * tiempo_transcurrido)"
              )
            ),
            tags$li(
              "Los resultados muestran un ",
              tags$strong("rango posible"),
              ", debido a la variabilidad individual en la tasa de eliminación de alcohol (β)."
            ),
            tags$li(
              "Factores como el sexo, peso, ingesta de alimentos, patrón de consumo y estado de salud pueden influir en la tasa de eliminación real y no se consideran en este cálculo simplificado."
            ),
            tags$li(
              "Esta herramienta pretende ser un apoyo en el análisis pericial experto, sin embargo, no tiene validez legal por sí misma."
            )
          ),
          h5("Reference:"),
          tags$ul(tags$a(
            href = "https://www.aafs.org/asb-standard/best-practice-recommendation-performing-alcohol-calculations-forensic-toxicology",
            target = "_blank",
            "Best Practice Recommendation for Performing Alcohol Calculations in Forensic Toxicology"
          ))
        )
      )
    )
    # ),
    # )
    # Signos y Síntomas ----
    # nav_panel(
    #   title = "Signos y Síntomas", icon = icon("notes-medical"),
    #   h3("Signos y Síntomas Clínicos Asociados a la Alcoholemia"),
    #   p("Esta sección muestra los signos y síntomas generalmente asociados con diferentes niveles de concentración de alcohol en sangre (CAS / BAC)."),
    #   sliderInput("bac_sintomas_selector", "Nivel de BAC (g/L) para consultar síntomas:", min = 0, max = 4, value = 0.8, step = 0.05, width = '100%'),
    #   uiOutput("sintomas_output")
    # ),

    # Estimación de Bebidas ----
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


# --- Server ---
server <- function(input, output, session) {
  observe(
    if (input$calcular == 0) {
      show("no_results")
      show("no_results_plot")
      show("no_results_calculos")
      hide("descargar_reporte")
    } else {
      hide("no_results")
      hide("no_results_plot")
      hide("no_results_calculos")
      show("descargar_reporte")
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

  iv <- InputValidator$new()

  iv$add_rule(
    "bac_medido",
    sv_required("Debe ingresar un valor para BAC medido.")
  )
  iv$add_rule("bac_medido", sv_gte(0, "El BAC medido no puede ser negativo."))
  iv$add_rule(
    "hora_medicion",
    sv_required("La hora de medición es obligatoria.")
  )
  iv$add_rule(
    "hora_medicion",
    sv_regex(
      "^([01]?[0-9]|2[0-3]):[0-5][0-9]$",
      "Hora de medición: formato HH:MM."
    )
  )
  iv$add_rule("hora_evento", sv_required("La hora del evento es obligatoria."))
  iv$add_rule(
    "hora_evento",
    sv_regex(
      "^([01]?[0-9]|2[0-3]):[0-5][0-9]$",
      "Hora del evento: formato HH:MM."
    )
  )

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
        "Error al combinar fechas y horas. Verifique que las fechas sean válidas."
      )
    } else if (tiempo_evento >= tiempo_medicion) {
      return("El evento debe ser anterior a la medición.")
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
    horas_transcurridas <- as.numeric(difftime(
      tiempo_medicion_val,
      tiempo_evento_val,
      units = "hours"
    ))
    bac_medido_val <- input$bac_medido
    bac_evento_min <- round(bac_medido_val + BETA_MIN * horas_transcurridas, 2)
    bac_evento_max <- round(bac_medido_val + BETA_MAX * horas_transcurridas, 2)

    list(
      horas = round(horas_transcurridas, 2),
      bac_min = bac_evento_min,
      bac_max = bac_evento_max,
      bac_medido_val = bac_medido_val,
      tiempo_medicion_val = tiempo_medicion_val,
      tiempo_evento_val = tiempo_evento_val,
      beta_min_val = BETA_MIN,
      beta_max_val = BETA_MAX
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
          "Estimated BAC at time of the incident: <br>",
          tags$strong(res$bac_min |> formatC(digits = 2, format = "f")),
          " – ",
          tags$strong(res$bac_max |> formatC(digits = 2, format = "f")),
          " g/L"
        ))
      )
    )
  })

  ## gráfico ----
  grafico <- reactive({
    res <- resultado()
    req(res)
    points_df <- data.frame(
      time = c(
        res$tiempo_evento_val,
        res$tiempo_evento_val,
        res$tiempo_medicion_val
      ),
      bac = c(res$bac_min, res$bac_max, res$bac_medido_val),
      type = factor(
        c("Extrapolado (Mín)", "Extrapolado (Máx)", "Analítico"),
        levels = c("Analítico", "Extrapolado (Mín)", "Extrapolado (Máx)")
      ),
      label_text = c(
        sprintf("%.2f g/L", res$bac_min),
        sprintf("%.2f g/L", res$bac_max),
        sprintf("%.2f g/L", res$bac_medido_val)
      )
    )
    # p <-
    # dev.new()
    ggplot(points_df, aes(x = time, y = bac)) +
      geom_segment(
        data = data.frame(
          x = res$tiempo_medicion_val,
          y = res$bac_medido_val,
          xend = res$tiempo_evento_val,
          yend = res$bac_min
        ),
        aes(x = x, y = y, xend = xend, yend = yend),
        linetype = "dashed",
        color = "steelblue",
        linewidth = 0.8
      ) +
      geom_segment(
        data = data.frame(
          x = res$tiempo_medicion_val,
          y = res$bac_medido_val,
          xend = res$tiempo_evento_val,
          yend = res$bac_max
        ),
        aes(x = x, y = y, xend = xend, yend = yend),
        linetype = "dashed",
        color = "steelblue",
        linewidth = 0.8
      ) +
      geom_point(aes(shape = type, color = type), size = 4) +
      geom_text(
        aes(label = label_text),
        vjust = -1.2,
        size = 3.8,
        check_overlap = FALSE,
        fontface = "bold"
      ) +
      scale_x_datetime(
        name = "Tiempo",
        breaks = sort(unique(points_df$time)),
        labels = function(brks) {
          sapply(brks, function(t) {
            base_format <- format(t, "%H:%M\n%d/%m/%Y")
            if (t == res$tiempo_evento_val) {
              paste0(base_format, "\n(T Evento)")
            } else if (t == res$tiempo_medicion_val) {
              paste0(base_format, "\n(T Muestra)")
            } else {
              base_format
            }
          })
        },
        expand = expansion(c(0.1, 0.1))
      ) +
      scale_y_continuous(
        name = "Blood alcohol concentration (g/L)",
        limits = c(0, max(points_df$bac, na.rm = TRUE) * 1.25),
        expand = expansion(mult = c(0.01, 0.1))
      ) +
      # scale_shape_manual(values = c("Analite" = 16, "Extrapolate (Mín)" = 17, "Extrapolate (Máx)" = 17)) +
      scale_color_manual(
        values = c(
          "Analítico" = "#0072B2",
          "Extrapolado (Mín)" = "#E69F00",
          "Extrapolado (Máx)" = "#D55E00"
        )
      ) +
      labs(color = "Resultado:", shape = "Resultado:") +
      theme_bw(base_size = 14) +
      theme(
        legend.position = "bottom",
        axis.title = element_text(face = "bold", size = 12),
        axis.text.x = element_text(angle = 0, hjust = 0.5, size = 10),
        axis.text.y = element_text(size = 10),
        legend.title = element_text(size = 11),
        legend.text = element_text(size = 10),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_line(
          linetype = "dotted",
          color = "grey80"
        ),
        panel.grid.major.y = element_line(linetype = "dotted", color = "grey80")
      )
    # browser()
    # print(p)
  })

  output$bac_plot <- renderPlot(
    {
      grafico()
    },
    res = 96
  )

  output$calculos_detallados_ui <- renderUI({
    res <- resultado()
    req(res) # Solo proceder si hay un resultado válido

    fmt_tiempo_medicion <- format(res$tiempo_medicion_val, "%d/%m/%Y %H:%M")
    fmt_tiempo_evento <- format(res$tiempo_evento_val, "%d/%m/%Y %H:%M")

    # Estructura usando tagList y etiquetas HTML individuales para claridad
    tagList(
      # tags$h5("1. Tiempo Transcurrido (Delta_t)"),
      # tags$p(paste0("Hora de Medición: ", fmt_tiempo_medicion)),
      # tags$p(paste0("Hora del Evento: ", fmt_tiempo_evento)),
      # tags$p(tags$code("Delta_t = Hora de Medición - Hora de Evento")),
      # tags$p(tags$strong(paste0("Delta_t = ", res$horas, " horas"))),
      # tags$hr(),

      # tags$h5("2. Concentración de Alcohol Estimada en el Momento del Evento (BAC_evento)"),
      # tags$p(tags$code("BAC_evento = BAC_medido + (beta * Delta_t)")),
      # tags$p(paste0("Donde BAC_medido = ", res$bac_medido_val, " g/L")),
      # tags$p(paste0("y beta es la tasa de eliminación horaria (g/L/hora).")),
      # tags$hr(),
      layout_columns(
        div(
          h5(
            "Cálculo del Límite Inferior del Rango Estimado (BAC_evento_min)"
          ),
          p(paste0(
            "Usando Tasa de Eliminación Mínima (beta_min) = ",
            res$beta_min_val,
            " g/L/hora:"
          )),
          p(tags$code(
            paste0(
              "BAC_evento_min = ",
              res$bac_medido_val |> formatC(digits = 2, format = "f"),
              " g/L + (",
              res$beta_min_val |> formatC(digits = 2, format = "f"),
              " g/L/hora * ",
              res$horas,
              " horas)"
            )
          )),
          p(HTML(paste0(
            "&nbsp;&nbsp;&nbsp;&nbsp; = ",
            res$bac_medido_val |> formatC(digits = 2, format = "f"),
            " g/L + ",
            round(res$beta_min_val * res$horas, 3) |>
              formatC(digits = 2, format = "f"),
            " g/L"
          ))),
          p(tags$strong(
            paste0(
              "BAC_evento_min = ",
              res$bac_min |> formatC(digits = 2, format = "f"),
              " g/L"
            )
          ))
        ),

        # segunda columna
        div(
          h5(
            "Cálculo del Límite Superior del Rango Estimado (BAC_evento_max)"
          ),
          p(paste0(
            "Usando Tasa de Eliminación Máxima (beta_max) = ",
            res$beta_max_val,
            " g/L/hora:"
          )),
          p(tags$code(
            paste0(
              "BAC_evento_max = ",
              res$bac_medido_val |> formatC(digits = 2, format = "f"),
              " g/L + (",
              res$beta_max_val |> formatC(digits = 2, format = "f"),
              " g/L/hora * ",
              res$horas,
              " horas)"
            )
          )),
          p(
            HTML(paste0(
              "&nbsp;&nbsp;&nbsp;&nbsp; = ",
              res$bac_medido_val |> formatC(digits = 2, format = "f"),
              " g/L + ",
              round(res$beta_max_val * res$horas, 3) |>
                formatC(digits = 2, format = "f"),
              " g/L"
            ))
          ),
          p(
            strong(
              paste0(
                "BAC_evento_max = ",
                res$bac_max |> formatC(digits = 2, format = "f"),
                " g/L"
              )
            )
          )
        )
      )
    )
  })

  # --- Lógica para Pestaña de Signos y Síntomas ---
  output$sintomas_output <- renderUI({
    bac <- input$bac_sintomas_selector
    sintomas_info <- list(
      list(
        rango = c(-Inf, 0.29),
        titulo = "BAC < 0.3 g/L (Muy Bajo - Leve)",
        efectos = c(
          "La mayoría de las personas no muestran efectos obvios o estos son muy leves.",
          "Ligera intensificación del humor."
        ),
        class = "alert-light"
      ),
      list(
        rango = c(0.3, 0.59),
        titulo = "BAC 0.3 - 0.59 g/L (Bajo - Euforia Leve)",
        efectos = c(
          "Sensación de bienestar, relajación, euforia leve.",
          "Reducción de la inhibición.",
          "Disminución de la atención y control."
        ),
        class = "alert-info"
      ),
      list(
        rango = c(0.6, 0.99),
        titulo = "BAC 0.6 - 0.99 g/L (Moderado - Excitación)",
        efectos = c(
          "Deterioro del juicio.",
          "Tiempo de reacción aumentado.",
          "Pérdida de coordinación muscular."
        ),
        class = "alert-primary"
      ),
      list(
        rango = c(1.0, 1.49),
        titulo = "BAC 1.0 - 1.49 g/L (Alto - Confusión)",
        efectos = c(
          "Confusión mental, desorientación.",
          "Alteraciones sensoriales.",
          "Ataxia severa."
        ),
        class = "alert-warning"
      ),
      list(
        rango = c(1.5, 2.49),
        titulo = "BAC 1.5 - 2.49 g/L (Muy Alto - Estupor)",
        efectos = c(
          "Estupor.",
          "Incapacidad para mantenerse de pie.",
          "Vómitos, riesgo de aspiración."
        ),
        class = "alert-danger"
      ),
      list(
        rango = c(2.5, 3.49),
        titulo = "BAC 2.5 - 3.49 g/L (Severo - Coma)",
        efectos = c("Coma.", "Reflejos deprimidos.", "Depresión respiratoria."),
        class = "alert-danger fw-bold"
      ),
      list(
        rango = c(3.5, Inf),
        titulo = "BAC ≥ 3.5 g/L (Potencialmente Letal)",
        efectos = c(
          "Depresión respiratoria severa/paro.",
          "Paro cardíaco.",
          "Muerte."
        ),
        class = "alert-danger fw-bolder"
      )
    )
    info_seleccionada <- NULL
    for (item in sintomas_info) {
      if (bac >= item$rango[1] && bac <= item$rango[2]) {
        info_seleccionada <- item
        break
      }
    }
    if (!is.null(info_seleccionada)) {
      tags$div(
        class = paste("card shadow-sm mt-3"),
        tags$div(
          class = paste("card-header fs-5", info_seleccionada$class),
          info_seleccionada$titulo
        ),
        tags$div(
          class = "card-body",
          tags$ul(
            class = "list-group list-group-flush",
            lapply(info_seleccionada$efectos, function(efecto) {
              tags$li(class = "list-group-item", efecto)
            })
          ),
          tags$p(
            class = "mt-3 small text-muted",
            "Fuente: Información general adaptada de fuentes toxicológicas y de salud pública. La respuesta individual al alcohol puede variar."
          )
        )
      )
    } else {
      tags$p(
        class = "alert alert-secondary mt-3",
        "No se encontró información para el nivel de BAC seleccionado o el nivel es 0."
      )
    }
  })

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
      "Reporte de Retroproyección de Etanol",
      style = "heading 1"
    )

    # Datos de entrada
    doc <- body_add_par(
      doc,
      paste("Concentración medida:", resultado()$bac_medido_val, "g/L"),
      style = "Normal"
    )
    doc <- body_add_par(
      doc,
      paste("Tiempo transcurrido:", resultado()$horas, "horas"),
      style = "Normal"
    )

    # # Insertar tabla
    # tabla <- datos_proyeccion()
    # doc <- body_add_par(doc, "Resultados:", style = "heading 2")
    # doc <- body_add_table(doc, value = tabla, style = "table_template")
    # browser()
    doc <- body_add_par(
      doc,
      "Concentración estimada al evento (g/L):",
      style = "heading 2"
    )

    doc <- body_add_par(
      doc,
      paste0(
        "Mínimo (tasa de eliminación ",
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
        "Máximo (tasa de eliminación ",
        BETA_MAX,
        "): ",
        resultado()$bac_max |> formatC(digits = 2, format = "f"),
        " g/L"
      ),
      style = "Normal"
    )

    # # Insertar gráfico
    # datos <- data.frame(
    #   Tiempo = seq(0, input$tiempo, by = 0.1)
    # )
    # datos$BAC_Lenta <- res$bac_medido_val + 0.10 * datos$Tiempo
    # datos$BAC_Rapida <- res$bac_medido_val + 0.25 * datos$Tiempo
    #
    # grafica <- ggplot(datos, aes(x = Tiempo)) +
    #   geom_line(aes(y = BAC_Lenta), color = "blue", size = 1.2) +
    #   geom_line(aes(y = BAC_Rapida), color = "red", size = 1.2) +
    #   labs(x = "Tiempo (horas)",
    #        y = "Concentración de etanol (g/L)",
    #        title = "Retroproyección de Concentración de Etanol") +
    #   theme_minimal() +
    #   theme(plot.title = element_text(hjust = 0.5)) +
    #   scale_y_continuous(limits = c(0, max(datos$BAC_Rapida) * 1.1))

    doc <- body_add_par(doc, "Gráfico de extrapolación:", style = "heading 2")

    doc <- body_add_gg(doc, value = grafico(), style = "centered")
  })

  # download ----
  output$descargar_reporte <- downloadHandler(
    filename = function() {
      paste0("reporte_retroproyeccion_", Sys.Date(), ".docx")
    },
    content = function(file) {
      print(reporte(), target = file)
    }
  )
}

# --- Run ---
shinyApp(ui, server)
