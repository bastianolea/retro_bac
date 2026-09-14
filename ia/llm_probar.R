library(ellmer)
library(ragnar)

source("R/calculos.R")
source("ia/llm_setup.R")


# probar rag ----
chat$chat(
  "a cuántas unidades de alcohol corresponden aproximadamente 0.8 g/l, y qué síntomas pueden estar asociados?"
)

chat$chat(
  "qué significa el concepto de eliminación?"
)


# probar herramienta ----
chat$chat(
  "calcula el alcohol en sangre de una persona que fue medida con 0.8 g/l de alcohol en sangre, 2 horas después del incidente"
)
# 1.0 a 1.3 g/L

chat$chat(
  "calcula el alcohol en sangre de una persona que fue medida con 0.9 g/l de alcohol en sangre, 3 horas después del incidente."
)
# 1.2 a 1.65 g/L
