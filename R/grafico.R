#' Construir el gráfico de extrapolación retrógrada
#'
#' @param res       Lista de resultados devuelta por el reactivo `resultado()`,
#'   con los campos `tiempo_evento_val`, `tiempo_medicion_val`, `bac_min`,
#'   `bac_max` y `bac_medido_val`.
#' @param es_movil  Lógico; adapta la disposición para pantallas angostas.
#'
#' @return Un objeto ggplot.
construir_grafico <- function(res, es_movil = FALSE) {
  stopifnot(!is.null(res))

  etiquetas <- c("Extrapolation (min)", "Extrapolation (max)", "Measured")

  # datos
  points_df <- data.frame(
    time = c(
      res$tiempo_evento_val,
      res$tiempo_evento_val,
      res$tiempo_medicion_val
    ),
    bac = c(res$bac_min, res$bac_max, res$bac_medido_val),
    type = factor(
      etiquetas,
      levels = etiquetas
    ),
    label_text = c(
      sprintf("%.2f g/L", res$bac_min),
      sprintf("%.2f g/L", res$bac_max),
      sprintf("%.2f g/L", res$bac_medido_val)
    )
  )

  # browser()

  # adaptación según ancho de la ventana (móvil < 600px)
  exp_x <- if (es_movil) 0.2 else 0.1
  # en móvil, repartir la leyenda en 2 filas para que quepan los 3 elementos
  filas_leyenda <- if (es_movil) 2 else 1

  # con lapsos largos entre evento y medición, ampliar los minor_breaks
  horas_lapso <- as.numeric(
    difftime(res$tiempo_medicion_val, res$tiempo_evento_val, units = "hours")
  )
  intervalo_minor <- if (abs(horas_lapso) > 12) "3 hours" else "1 hour"

  # gráfico
  ggplot(points_df, aes(x = time, y = bac)) +
    # líneas punteadas
    geom_segment(
      data = data.frame(
        x = res$tiempo_medicion_val,
        y = res$bac_medido_val,
        xend = res$tiempo_evento_val,
        yend = res$bac_min
      ),
      aes(x = x, y = y, xend = xend, yend = yend),
      linetype = "dashed",
      color = "#67839A",
      linewidth = 0.6
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
      color = "#67839A",
      linewidth = 0.6
    ) +
    # figuras/puntos
    geom_point(
      aes(shape = type, color = type),
      size = 5
    ) +
    # textos sobre figuras
    geom_label(
      aes(label = label_text),
      vjust = -1,
      size = 3,
      fontface = "bold",
      color = "#19222A",
      linewidth = 0
    ) +
    # escalas
    scale_x_datetime(
      breaks = unique(points_df$time),
      minor_breaks = seq(
        min(points_df$time),
        max(points_df$time),
        by = intervalo_minor
      ),
      labels = function(brks) {
        sapply(brks, function(t) {
          base_format <- format(t, "%H:%M\n%d/%m/%Y")
          if (t == res$tiempo_evento_val) {
            paste0(base_format, "\n(event)")
          } else if (t == res$tiempo_medicion_val) {
            paste0(base_format, "\n(sample)")
          } else {
            base_format
          }
        })
      },
      expand = expansion(c(exp_x, exp_x))
    ) +
    scale_y_continuous(
      limits = c(0, max(points_df$bac, na.rm = TRUE) * 1.25),
      expand = expansion(mult = c(0, 0.1))
    ) +
    scale_color_manual(
      values = setNames(
        c("#D55E00", "#E69F00", "#0072B2"),
        etiquetas
      )
    ) +
    scale_shape_manual(
      values = setNames(
        c(15, 17, 16),
        etiquetas
      )
    ) +
    labs(
      color = NULL,
      shape = NULL,
      y = "Blood alcohol concentration (g/L)",
      x = "Time"
    ) +
    theme_bw(
      base_size = 14,
      base_family = "Arial",
      ink = "#19222A"
    ) +
    guides(
      shape = guide_legend(
        nrow = filas_leyenda,
        override.aes = list(size = 3.6, alpha = 0.8)
      ),
      color = guide_legend(nrow = filas_leyenda)
    ) +
    theme(
      legend.position = "top",
      axis.title.y = element_text(size = 12),
      axis.title.x = element_text(
        size = 12,
        margin = margin(t = 2, b = 0)
      ),
      axis.text.x = element_text(
        # angle = 0,
        hjust = 0.5,
        size = 10,
        margin = margin(t = 4)
      ),
      axis.text.y = element_text(size = 10),
      legend.title = element_text(
        size = 11
      ),
      legend.text = element_text(
        size = 10,
        margin = margin(l = 1, r = 3)
      ),
      legend.margin = margin(b = -6),
      panel.grid.major.x = element_line(
        linewidth = .4,
        color = "grey80"
      ),
      panel.grid.major.y = element_line(
        linewidth = .4,
        color = "grey80"
      )
    )
  # browser()
  # dev.new()
  # print(p)
}
