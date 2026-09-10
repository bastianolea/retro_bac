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
