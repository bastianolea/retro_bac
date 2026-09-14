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

#' Validar y parsear una fecha-hora provista como texto (p. ej. por el LLM)
#'
#' Convierte un string a POSIXct exigiendo formato ISO 8601 no ambiguo, para
#' evitar interpretaciones erróneas en un contexto forense. Reglas:
#'   * `"YYYY-MM-DD HH:MM"` (con segundos o separador `"T"` opcionales): se acepta.
#'   * Solo hora `"HH:MM"`: se asume la fecha `hoy`.
#'   * Solo fecha `"YYYY-MM-DD"`: se rechaza (falta la hora).
#'   * Cualquier otro formato (p. ej. `"01/12/2026"`): se rechaza por ambiguo/no ISO.
#'
#' Cada rechazo produce un error informativo para que el LLM pueda reintentar.
#'
#' @param x       String con la fecha-hora.
#' @param nombre  Nombre del campo, usado en los mensajes de error.
#' @param tz      Zona horaria del resultado. Por defecto la del sistema.
#' @param hoy     Fecha a asumir cuando solo se entrega la hora (Date).
#'
#' @return Un POSIXct de longitud 1.
validar_fecha_hora <- function(
  x,
  nombre = "fecha-hora",
  tz = Sys.timezone(),
  hoy = Sys.Date()
) {
  if (missing(x) || is.null(x) || length(x) != 1 || is.na(x) || !nzchar(trimws(x))) {
    stop(
      sprintf(
        "`%s` no es una fecha-hora válida. Usa el formato ISO 'YYYY-MM-DD HH:MM' (por ejemplo, '2026-01-01 14:30').",
        nombre
      ),
      call. = FALSE
    )
  }
  x <- trimws(x)

  re_hora <- "([01]?[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?"
  re_iso <- paste0("^\\d{4}-\\d{2}-\\d{2}[ T]", re_hora, "$")
  re_solo_hora <- paste0("^", re_hora, "$")
  re_solo_fecha <- "^\\d{4}-\\d{2}-\\d{2}$"

  if (grepl(re_iso, x)) {
    texto <- x
  } else if (grepl(re_solo_hora, x)) {
    # Solo hora: se asume la fecha de hoy.
    texto <- paste(format(hoy), x)
  } else if (grepl(re_solo_fecha, x)) {
    stop(
      sprintf(
        "`%s` ('%s') incluye solo la fecha, sin la hora. Añade la hora: 'YYYY-MM-DD HH:MM'.",
        nombre,
        x
      ),
      call. = FALSE
    )
  } else {
    stop(
      sprintf(
        "`%s` ('%s') tiene un formato inválido o ambiguo. Usa ISO 8601 'YYYY-MM-DD HH:MM'; no se aceptan formatos como 'DD/MM/YYYY'.",
        nombre,
        x
      ),
      call. = FALSE
    )
  }

  instante <- suppressWarnings(
    lubridate::ymd_hms(texto, tz = tz, truncated = 1, quiet = TRUE)
  )
  if (is.na(instante)) {
    stop(
      sprintf(
        "`%s` ('%s') no corresponde a una fecha del calendario.",
        nombre,
        x
      ),
      call. = FALSE
    )
  }
  instante
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

# extrapolar_bac(bac_medido = 0.9, horas_transcurridas = 3L)
