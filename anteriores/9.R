# Retroproyección de etanol - Shiny App Mejorada con Tabla y Reporte

library(shiny)
library(ggplot2)
library(DT)        # Para la tabla interactiva
library(officer)   # Para reporte Word
library(rvg)       # Para insertar gráficos

ui <- fluidPage(
  titlePanel("Retro-BAC: Retroproyección de Etanol (g/L) - Basado en Guía ANSI/ASB 122"),
  
  sidebarLayout(
    sidebarPanel(
      numericInput("bac_actual", 
                   "Concentración de etanol medida (g/L):", 
                   value = 0.8, 
                   min = 0.1, 
                   max = 6.0, 
                   step = 0.01),
      
      sliderInput("tiempo", 
                  "Tiempo transcurrido desde el evento (horas):", 
                  min = 0.5, 
                  max = 8.0, 
                  value = 2.0, 
                  step = 0.1),
      
      selectInput("formato_reporte", "Formato del reporte:", 
                  choices = c("Word (.docx)" = "word")),
      br(),
      p(strong("Tasas de eliminación consideradas:"), "0.10 a 0.25 g/L/hora"),
      br(),
      downloadButton("descargar_reporte", "Descargar Reporte")
    ),
    
    mainPanel(
      h3("Resultados"),
      DTOutput("tabla_resultados"),
      br(),
      h3("Gráfico de Retroproyección"),
      plotOutput("grafica"),
      br(),
      h4("Notas importantes para su interpretación"),
      tags$ul(
        tags$li("La retroproyección es una ", strong("estimación matemática"), " basada en la fórmula de Widmark: ", 
                code("BAC_evento = BAC_medido + (tasa_eliminación * tiempo_transcurrido)")),
        tags$li("Los resultados muestran un ", strong("rango posible"), " debido a la variabilidad individual en la tasa de eliminación."),
        tags$li("Factores individuales como sexo, masa corporal, alimentación y salud no están contemplados."),
        tags$li("Este modelo es de uso educativo y pericial preliminar, no sustituye un análisis forense integral.")
      )
    )
  )
)

server <- function(input, output) {
  
  # Cálculo de BAC en retroproyección
  datos_proyeccion <- reactive({
    tasas <- c(0.10, 0.25) # Más tasas para mostrar rango más detallado
    bac_evento <- input$bac_actual + tasas * input$tiempo
    data.frame(
      `Tasa de eliminación (g/L/h)` = tasas,
      `Concentración estimada al evento (g/L)` = round(bac_evento, 2)
    )
  })
  
  output$tabla_resultados <- renderDT({
    datatable(datos_proyeccion(), 
              options = list(pageLength = 7, dom = 't'),  # Solo tabla sin buscador ni paginador
              rownames = FALSE)
  })
  
  output$grafica <- renderPlot({
    datos <- data.frame(
      Tiempo = seq(0, input$tiempo, by = 0.1)
    )
    datos$BAC_Lenta <- input$bac_actual + 0.10 * datos$Tiempo
    datos$BAC_Rapida <- input$bac_actual + 0.25 * datos$Tiempo
    
    ggplot(datos, aes(x = Tiempo)) +
      geom_line(aes(y = BAC_Lenta), color = "blue", size = 1.2) +
      geom_line(aes(y = BAC_Rapida), color = "red", size = 1.2) +
      labs(x = "Tiempo (horas)", 
           y = "Concentración de etanol (g/L)", 
           title = "Retroproyección de Concentración de Etanol") +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5)) +
      scale_y_continuous(limits = c(0, max(datos$BAC_Rapida) * 1.1))
  })
  
  output$descargar_reporte <- downloadHandler(
    filename = function() {
      paste0("reporte_retroproyeccion_", Sys.Date(), ".docx")
    },
    content = function(file) {
      doc <- read_docx()
      
      # Título
      doc <- body_add_par(doc, "Reporte de Retroproyección de Etanol", style = "heading 1")
      
      # Datos de entrada
      doc <- body_add_par(doc, paste("Concentración medida:", input$bac_actual, "g/L"), style = "Normal")
      doc <- body_add_par(doc, paste("Tiempo transcurrido:", input$tiempo, "horas"), style = "Normal")
      
      # Insertar tabla
      tabla <- datos_proyeccion()
      doc <- body_add_par(doc, "Resultados:", style = "heading 2")
      doc <- body_add_table(doc, value = tabla, style = "table_template")
      
      # Insertar gráfico
      datos <- data.frame(
        Tiempo = seq(0, input$tiempo, by = 0.1)
      )
      datos$BAC_Lenta <- input$bac_actual + 0.10 * datos$Tiempo
      datos$BAC_Rapida <- input$bac_actual + 0.25 * datos$Tiempo
      
      grafica <- ggplot(datos, aes(x = Tiempo)) +
        geom_line(aes(y = BAC_Lenta), color = "blue", size = 1.2) +
        geom_line(aes(y = BAC_Rapida), color = "red", size = 1.2) +
        labs(x = "Tiempo (horas)", 
             y = "Concentración de etanol (g/L)", 
             title = "Retroproyección de Concentración de Etanol") +
        theme_minimal() +
        theme(plot.title = element_text(hjust = 0.5)) +
        scale_y_continuous(limits = c(0, max(datos$BAC_Rapida) * 1.1))
      
      doc <- body_add_gg(doc, value = grafica, style = "centered")
      
      # Guardar
      print(doc, target = file)
    }
  )
}

# Ejecutar aplicación
shinyApp(ui = ui, server = server)
