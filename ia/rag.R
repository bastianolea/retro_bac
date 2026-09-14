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
