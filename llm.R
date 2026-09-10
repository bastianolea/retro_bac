# https://bastianolea.rbind.io/blog/rag_ragnar/
library(ragnar)

store <- ragnar_store_create(
  location = "documentos/documentos.ragnar.duckdb",
  embed = NULL,
  overwrite = TRUE
)

# leer
paper_a <- read_as_markdown(
  "documentos/best_practices_2024/best_practices_2024.md"
)
paper_b <- read_as_markdown("documentos/wayne_2024/wayne_2024.md")
poster_a <- read_as_markdown("documentos/poster/poster.md")
marco_teorico <- read_as_markdown("documentos/marco_teorico.html")

# trozar
paper_a_secciones <- markdown_chunk(paper_a)
paper_b_secciones <- markdown_chunk(paper_b)
poster_a_secciones <- markdown_chunk(poster_a)
marco_teorico_secciones <- markdown_chunk(marco_teorico)

# insertar
ragnar_store_insert(store, paper_a_secciones)
ragnar_store_insert(store, paper_b_secciones)
ragnar_store_insert(store, poster_a_secciones)
ragnar_store_insert(store, marco_teorico_secciones)

# guardar
ragnar_store_build_index(store)

# probar ----
library(ellmer)

chat <- chat_anthropic(
  system_prompt = readLines("documentos/system_prompt.md"),
  model = "claude-haiku-4-5",
)

store <- ragnar_store_connect(
  "documentos/documentos.ragnar.duckdb",
  read_only = TRUE
)

# registrar herramienta con el modelo de IA
ragnar_register_tool_retrieve(
  chat,
  store,
  top_k = 4,
  store_description = "Consulta de documentos sobre cálculos de alcohol en sangre para cálculo de extrapolación retrógrada de alcohol"
)


chat$chat(
  "a cuántas unidades de alcohol corresponden aproximadamente 0.8 g/l, y qué síntomas pueden estar asociados?"
)

chat$chat("qué significa el concepto de Eliminación?")
