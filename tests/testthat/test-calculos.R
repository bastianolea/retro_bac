library(testthat)
library(lubridate)
library(here)

source(here("R/calculos.R"))

test_that("extrapolar_bac reproduce la fórmula de Widmark con los datos del ejemplo", {
  # Ejemplo de la app: BAC medido 0.8 g/L, 2 horas transcurridas
  res <- extrapolar_bac(bac_medido = 0.8, horas_transcurridas = 2)

  # 0.8 + 0.10 * 2 = 1.00 ; 0.8 + 0.25 * 2 = 1.30
  expect_equal(res$bac_min, 1.00)
  expect_equal(res$bac_max, 1.30)
  expect_equal(res$horas, 2)
  expect_equal(res$bac_medido, 0.8)
  expect_equal(res$beta_min, 0.10)
  expect_equal(res$beta_max, 0.25)
})

test_that("extrapolar_bac respeta betas personalizados", {
  res <- extrapolar_bac(
    bac_medido = 1.0,
    horas_transcurridas = 4,
    beta_min = 0.15,
    beta_max = 0.20
  )
  expect_equal(res$bac_min, 1.6)
  expect_equal(res$bac_max, 1.8)
})

test_that("extrapolar_bac redondea a dos cifras", {
  res <- extrapolar_bac(bac_medido = 0.831, horas_transcurridas = 1.5)
  # 0.831 + 0.10 * 1.5 = 0.981 -> 0.98
  expect_equal(res$bac_min, 0.98)
})

test_that("horas cero devuelve el BAC medido", {
  res <- extrapolar_bac(bac_medido = 0.75, horas_transcurridas = 0)
  expect_equal(res$bac_min, 0.75)
  expect_equal(res$bac_max, 0.75)
})

test_that("extrapolar_bac valida casos límite", {
  expect_error(extrapolar_bac(bac_medido = 0.8, horas_transcurridas = -1))
  expect_error(extrapolar_bac(bac_medido = -0.1, horas_transcurridas = 2))
  expect_error(extrapolar_bac(bac_medido = NA, horas_transcurridas = 2))
  expect_error(extrapolar_bac(bac_medido = 0.8, horas_transcurridas = NA))
})

test_that("calcular_horas mide la diferencia en horas", {
  evento <- ymd_hm("2026-01-01 10:00", tz = "UTC")
  medicion <- ymd_hm("2026-01-01 13:30", tz = "UTC")
  expect_equal(calcular_horas(evento, medicion), 3.5)
})

test_that("calcular_horas es negativo si el evento es posterior a la medición", {
  evento <- ymd_hm("2026-01-01 14:00", tz = "UTC")
  medicion <- ymd_hm("2026-01-01 13:00", tz = "UTC")
  expect_equal(calcular_horas(evento, medicion), -1)
})

test_that("calcular_horas falla ante fechas inválidas", {
  medicion <- ymd_hm("2026-01-01 13:00", tz = "UTC")
  expect_error(calcular_horas(NA, medicion))
})

# --- Robustez frente a entradas incorrectas (p. ej. desde el LLM) ---
# El LLM puede pasar fechas/horas malformadas o inconsistentes. Estas pruebas
# fijan el comportamiento esperado de calcular_horas() en esos escenarios.

test_that("calcular_horas falla si la medición es NA", {
  evento <- ymd_hm("2026-01-01 10:00", tz = "UTC")
  expect_error(calcular_horas(evento, NA))
})

test_that("calcular_horas falla si ambas fechas son NA", {
  expect_error(calcular_horas(NA, NA))
})

test_that("calcular_horas falla cuando un string malformado se parsea a NA", {
  # ymd_hm() devuelve NA (con warning) ante texto no interpretable como fecha;
  # ese NA debe provocar un error claro en lugar de propagarse silenciosamente.
  evento <- suppressWarnings(ymd_hm("no es una fecha", tz = "UTC"))
  medicion <- ymd_hm("2026-01-01 13:00", tz = "UTC")
  expect_true(is.na(evento))
  expect_error(calcular_horas(evento, medicion))
})

test_that("calcular_horas devuelve 0 cuando evento y medición coinciden", {
  instante <- ymd_hm("2026-01-01 12:00", tz = "UTC")
  expect_equal(calcular_horas(instante, instante), 0)
})

test_that("calcular_horas maneja spans de varios días", {
  evento <- ymd_hm("2026-01-01 08:00", tz = "UTC")
  medicion <- ymd_hm("2026-01-03 08:00", tz = "UTC")
  expect_equal(calcular_horas(evento, medicion), 48)
})

test_that("calcular_horas conserva la precisión de minutos y segundos", {
  evento <- ymd_hms("2026-01-01 10:00:00", tz = "UTC")
  medicion_min <- ymd_hms("2026-01-01 10:15:00", tz = "UTC")
  expect_equal(calcular_horas(evento, medicion_min), 0.25)

  medicion_seg <- ymd_hms("2026-01-01 11:30:30", tz = "UTC")
  expect_equal(calcular_horas(evento, medicion_seg), 1.5 + 30 / 3600)
})

test_that("calcular_horas mide horas físicas a través de un cambio de horario (DST)", {
  # America/Santiago adelanta el reloj en la madrugada del 2026-09-06 (00:00 -> 01:00).
  # Entre 23:00 y 02:00 hora local transcurren 2 horas físicas, no 3.
  evento <- ymd_hm("2026-09-05 23:00", tz = "America/Santiago")
  medicion <- ymd_hm("2026-09-06 02:00", tz = "America/Santiago")
  expect_equal(calcular_horas(evento, medicion), 2)
})

# --- validar_fecha_hora(): validación de strings del LLM ---
# El LLM entrega fechas como texto; este parseo exige ISO 8601 no ambiguo y
# falla con mensajes claros ante entradas parciales o mal formadas.

test_that("validar_fecha_hora acepta ISO fecha-hora (con y sin segundos, con 'T')", {
  esperado <- ymd_hms("2026-01-01 14:30:00", tz = "UTC")
  expect_equal(validar_fecha_hora("2026-01-01 14:30", tz = "UTC"), esperado)
  expect_equal(validar_fecha_hora("2026-01-01 14:30:00", tz = "UTC"), esperado)
  expect_equal(validar_fecha_hora("2026-01-01T14:30", tz = "UTC"), esperado)
})

test_that("validar_fecha_hora conserva los segundos cuando se proveen", {
  expect_equal(
    validar_fecha_hora("2026-01-01 14:30:45", tz = "UTC"),
    ymd_hms("2026-01-01 14:30:45", tz = "UTC")
  )
})

test_that("validar_fecha_hora asume la fecha de hoy cuando solo hay hora", {
  hoy <- as.Date("2026-09-14")
  expect_equal(
    validar_fecha_hora("14:30", tz = "UTC", hoy = hoy),
    ymd_hm("2026-09-14 14:30", tz = "UTC")
  )
})

test_that("validar_fecha_hora rechaza fecha sin hora y pide la hora", {
  expect_error(
    validar_fecha_hora("2026-01-01", nombre = "tiempo_evento"),
    "tiempo_evento"
  )
  expect_error(validar_fecha_hora("2026-01-01"), "hora")
})

test_that("validar_fecha_hora rechaza un objeto Date (sin hora)", {
  expect_error(validar_fecha_hora(as.Date("2026-01-01")), "hora")
})

test_that("validar_fecha_hora rechaza formatos ambiguos o no ISO", {
  # DD/MM vs MM/DD: ambiguo -> rechazado
  expect_error(validar_fecha_hora("01/12/2026 14:30"), "ISO|formato")
  expect_error(validar_fecha_hora("01/12/2026"), "ISO|formato")
  # separador con barras aunque el orden sea año primero
  expect_error(validar_fecha_hora("2026/12/01 14:30"), "ISO|formato")
  # mes textual
  expect_error(validar_fecha_hora("Jan 1 2026 14:30"), "ISO|formato")
})

test_that("validar_fecha_hora rechaza fechas imposibles del calendario", {
  expect_error(validar_fecha_hora("2026-13-40 10:00"), "calendario")
  expect_error(validar_fecha_hora("2026-02-30 10:00"), "calendario")
})

test_that("validar_fecha_hora rechaza entradas vacías, NA, NULL o múltiples", {
  expect_error(validar_fecha_hora(""), "válid")
  expect_error(validar_fecha_hora(NA_character_))
  expect_error(validar_fecha_hora(NULL))
  expect_error(validar_fecha_hora(c("2026-01-01 10:00", "2026-01-02 10:00")))
})

test_that("validar_fecha_hora se integra con calcular_horas", {
  evento <- validar_fecha_hora("2026-01-01 10:00", tz = "UTC")
  medicion <- validar_fecha_hora("2026-01-01 13:30", tz = "UTC")
  expect_equal(calcular_horas(evento, medicion), 3.5)
})
