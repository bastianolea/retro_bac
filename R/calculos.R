# Cálculos de extrapolación retrógrada de alcohol (fórmula de Widmark).
# Funciones puras, sin dependencias de Shiny, para poder probarlas de forma aislada.

# --- Constantes ---
# Tasas de eliminación de alcohol (g/L/hora). Fuente única de verdad,
# usada tanto por la app como por las funciones de cálculo.
BETA_MIN <- 0.10
BETA_MAX <- 0.25

#' Calcular las horas transcurridas entre el evento y la medición
#'
#' @param tiempo_evento    Fecha-hora del incidente (POSIXct).
#' @param tiempo_medicion  Fecha-hora de la toma de muestra (POSIXct).
#'
#' @return Número de horas transcurridas (numeric). Es positivo cuando la
#'   medición ocurre después del evento.
calcular_horas <- function(tiempo_evento, tiempo_medicion) {
  if (is.na(tiempo_evento) || is.na(tiempo_medicion)) {
    stop("Las fechas/horas del evento y de la medición deben ser válidas.")
  }
  as.numeric(difftime(tiempo_medicion, tiempo_evento, units = "hours"))
}

#' Extrapolar la concentración de alcohol al momento del incidente
#'
#' Aplica la fórmula de Widmark de extrapolación retrógrada
#' \eqn{AC_{inc} = AC_{test} + (\beta \times t)} usando las tasas de
#' eliminación mínima y máxima para obtener un rango de valores.
#'
#' @param bac_medido          Concentración de alcohol medida (g/L).
#' @param horas_transcurridas Tiempo transcurrido entre el incidente y la
#'   medición, en horas. Debe ser >= 0.
#' @param beta_min,beta_max   Tasas de eliminación mínima y máxima (g/L/hora).
#'
#' @return Una lista con:
#'   \item{bac_min}{BAC estimado usando la tasa mínima, redondeado a 2 cifras.}
#'   \item{bac_max}{BAC estimado usando la tasa máxima, redondeado a 2 cifras.}
#'   \item{horas}{Horas transcurridas, redondeadas a 2 cifras.}
#'   \item{bac_medido}{BAC medido de entrada.}
#'   \item{beta_min, beta_max}{Tasas de eliminación utilizadas.}
extrapolar_bac <- function(
  bac_medido,
  horas_transcurridas,
  beta_min = BETA_MIN,
  beta_max = BETA_MAX
) {
  if (!is.numeric(bac_medido) || is.na(bac_medido)) {
    stop("`bac_medido` debe ser un número.")
  }
  if (!is.numeric(horas_transcurridas) || is.na(horas_transcurridas)) {
    stop("`horas_transcurridas` debe ser un número.")
  }
  if (bac_medido < 0) {
    stop("`bac_medido` no puede ser negativo.")
  }
  # Un valor negativo implica que el evento ocurrió después de la medición,
  # lo cual no tiene sentido para una extrapolación retrógrada.
  if (horas_transcurridas < 0) {
    stop(
      "`horas_transcurridas` es negativo: el incidente debe ocurrir antes de la medición."
    )
  }

  list(
    bac_min = round(bac_medido + beta_min * horas_transcurridas, 2),
    bac_max = round(bac_medido + beta_max * horas_transcurridas, 2),
    horas = round(horas_transcurridas, 2),
    bac_medido = bac_medido,
    beta_min = beta_min,
    beta_max = beta_max
  )
}
