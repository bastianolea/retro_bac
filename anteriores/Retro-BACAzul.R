# Cargar paquetes
library(shiny)
library(bslib)
library(lubridate)
library(ggplot2)
library(shinyvalidate)
library(rmarkdown)
library(officer)
library(webshot2)

# Constantes
BETA_MIN <- 0.10
BETA_MAX <- 0.25

# UI
ui <- fluidPage(
  
  # Estilos CSS para mejorar el diseño
  tags$head(
    tags$style(HTML("
      body {
        background-color: #f0f8ff; /* Color de fondo */
        color: #003366; /* Color de texto general */
      }
      .panel {
        background-color: #ffffff; /* Color del panel blanco */
        border-radius: 10px;
        padding: 20px;
        box-shadow: 2px 2px 12px #aaaaaa;
      }
      h1, h3, h4 {
        color: #00509e; /* Color de títulos */
      }
      .btn {
        background-color: #00509e;
        color: white;
      }
      .btn:hover {
        background-color: #003f7f;
      }
    "))
  ),
  tags$h1("Retro-BAC v.1.0.0"),
  titlePanel("Herramienta para Retroproyección de Alcohol  - Estimación del rango según Guía ANSI/ASB 122."),
  tags$hr(),
  tags$p(strong("QF. Carlos Espinoza Cruz"), em("(Servicio Médico Legal de Chile)")),
  sidebarLayout(
    sidebarPanel(
      numericInput("bac_medido", "Concentración de etanol en sangre (g/L):", value = 0.80, min = 0.20, max = 6.0, step = 0.01),
      dateInput("fecha_medicion", "Fecha de la toma de muestra:", value = Sys.Date()),
      textInput("hora_medicion", "Hora de la toma de muestra (HH:MM):", value = "03:44"),
      dateInput("fecha_evento", "Fecha del Evento:", value = Sys.Date()),
      textInput("hora_evento", "Hora del Evento (HH:MM):", value = "01:44"),
      actionButton("calcular", "Calcular Retroproyección", icon = icon("calculator"), class = "btn btn-primary"),
      br(), br(),
      downloadButton("descargar_pdf", "Descargar Informe (PDF)", class = "btn btn-info"),
      downloadButton("descargar_word", "Descargar Informe (Word)", class = "btn btn-info")
    ),
    
    mainPanel(
      h3("Resultados:"),
      uiOutput("resultados_ui"),
      plotOutput("grafico"),
      hr(),
      h4("Notas Importantes e Interpretación"),
      tags$ul(
        tags$li("La retroproyección (o extrapolación retrógrada) es una estimación matemática."),
        tags$li("Se basa en la ecuación de Widmark: ", tags$code("BAC_evento = BAC_medido + (tasa_eliminación * tiempo_transcurrido)")),
        tags$li("Los resultados muestran un ", tags$strong("rango posible"),", debido a la variabilidad individual en la tasa de eliminación de alcohol (β)."),
        tags$li("Factores como el sexo, peso, ingesta de alimentos, patrón de consumo y estado de salud pueden influir en la tasa de eliminación real y no se consideran en este cálculo simplificado."),
        tags$li("Esta herramienta pretende ser un apoyo en el análisis pericial experto, sin embargo, no tiene validez legal por sí misma."),
        h4("Referencia:"),
      ),
      tags$ul(
        tags$a(href="https://www.aafs.org/asb-standard/best-practice-recommendation-performing-alcohol-calculations-forensic-toxicology", "Best Practice Recommendation for Performing Alcohol
Calculations in Forensic Toxicology, First Edition 2024")),
    )
  )
)

# SERVER
server <- function(input, output, session) {
  
  iv <- InputValidator$new()
  iv$add_rule("hora_medicion", sv_regex("^([01]?[0-9]|2[0-3]):[0-5][0-9]$", "Hora inválida. Use HH:MM."))
  iv$add_rule("hora_evento", sv_regex("^([01]?[0-9]|2[0-3]):[0-5][0-9]$", "Hora inválida. Use HH:MM."))
  iv$add_rule("fecha_evento", function(value) {
    if (nzchar(input$hora_medicion) && nzchar(input$hora_evento)) {
      tiempo_medicion <- ymd_hm(paste(input$fecha_medicion, input$hora_medicion))
      tiempo_evento <- ymd_hm(paste(input$fecha_evento, input$hora_evento))
      if (tiempo_evento >= tiempo_medicion) {
        return("El evento debe ser anterior a la medición.")
      }
    }
    NULL
  })
  iv$enable()
  
  resultado <- eventReactive(input$calcular, {
    req(iv$is_valid())
    
    tiempo_medicion <- ymd_hm(paste(input$fecha_medicion, input$hora_medicion))
    tiempo_evento <- ymd_hm(paste(input$fecha_evento, input$hora_evento))
    horas_transcurridas <- as.numeric(difftime(tiempo_medicion, tiempo_evento, units = "hours"))
     
    # ACinc = ACtest + (𝛽 x 𝑇) Widmark’s Formula
    bac_min <- round(input$bac_medido + BETA_MIN * horas_transcurridas, 3)
    bac_max <- round(input$bac_medido + BETA_MAX * horas_transcurridas, 3)
    
    list(
      horas = round(horas_transcurridas, 2),
      bac_medido = input$bac_medido,
      bac_min = bac_min,
      bac_max = bac_max,
      tiempo_evento = tiempo_evento,
      tiempo_medicion = tiempo_medicion
    )
  })
  
  output$resultados_ui <- renderUI({
    req(resultado())
    res <- resultado()
    tagList(
      tags$p(strong("Tiempo transcurrido:"), res$horas, " horas"),
      tags$p(strong("La concentración estimada de etanol en el momento de los hechos, estaría entre:"), res$bac_min, "-", res$bac_max, "g de etanol/L de sangre")
    )
  })
  
  output$grafico <- renderPlot({
    req(resultado())
    res <- resultado()
    
    datos <- data.frame(
      Tiempo = c(res$tiempo_evento, res$tiempo_evento, res$tiempo_medicion),
      BAC = c(res$bac_min, res$bac_max, res$bac_medido),
      Tipo = c("Extrapolado Inferior", "Extrapolado Superior", "Valor de la Alcoholemia")
    )
    
    ggplot(datos, aes(x = Tiempo, y = BAC, color = Tipo)) +
      geom_point(size = 4) +
      geom_line(linetype = "dashed") +
      labs(y = "Concentración de etanol (g/L)", x = "Hora", title = "Gráfico de la Retroproyección de etanol") +
      scale_color_manual(values = c("blue", "red", "green")) +
      theme_minimal(base_size = 14)
  })
  
  output$descargar_pdf <- downloadHandler(
    filename = function() {
      paste0("informe_retroproyeccion_", Sys.Date(), ".pdf")
    },
    content = function(file) {
      tempReport <- tempfile(fileext = ".Rmd")
      file.copy("informe.Rmd", tempReport, overwrite = TRUE)
      
      params <- resultado()
      ggsave("grafico_temp.png", plot = output$grafico(), width = 8, height = 5, dpi = 300)
      
      rmarkdown::render(tempReport, output_file = file,
                        params = params,
                        envir = new.env(parent = globalenv()))
    }
  )
  
  output$descargar_word <- downloadHandler(
    filename = function() {
      paste0("informe_retroproyeccion_", Sys.Date(), ".docx")
    },
    content = function(file) {
      doc <- read_docx()
      res <- resultado()
      
      doc <- body_add_par(doc, "Informe de Retroproyección de Alcoholemia", style = "heading 1")
      doc <- body_add_par(doc, paste("Fecha del evento:", res$tiempo_evento))
      doc <- body_add_par(doc, paste("Fecha de medición:", res$tiempo_medicion))
      doc <- body_add_par(doc, paste("Tiempo transcurrido:", res$horas, "horas"))
      doc <- body_add_par(doc, paste("BAC medido:", res$bac_medido, "g/L"))
      doc <- body_add_par(doc, paste("BAC estimado:", res$bac_min, "-", res$bac_max, "g/L"))
      
      ggsave("grafico_temp.png", plot = output$grafico(), width = 6, height = 4, dpi = 300)
      doc <- body_add_img(doc, src = "grafico_temp.png", width = 6, height = 4)
      
      print(doc, target = file)
    }
  )
}

# App
shinyApp(ui, server)
