library(testthat)
library(ggplot2)
library(lubridate)

source(file.path("..", "..", "R", "grafico.R"))

# Resultado de ejemplo equivalente al que produce el reactivo resultado()
res_ejemplo <- list(
  tiempo_evento_val = ymd_hm("2026-01-01 10:00", tz = "UTC"),
  tiempo_medicion_val = ymd_hm("2026-01-01 12:00", tz = "UTC"),
  bac_min = 1.00,
  bac_max = 1.30,
  bac_medido_val = 0.80
)

test_that("construir_grafico devuelve un objeto ggplot", {
  p <- construir_grafico(res_ejemplo)
  expect_s3_class(p, "ggplot")
})

test_that("construir_grafico funciona en modo móvil", {
  p <- construir_grafico(res_ejemplo, es_movil = TRUE)
  expect_s3_class(p, "ggplot")
})

test_that("construir_grafico falla si res es NULL", {
  expect_error(construir_grafico(NULL))
})
