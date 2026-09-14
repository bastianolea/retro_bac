# crear chat con modelo
chat <- chat_anthropic(
  system_prompt = paste(
    "ALWAYS ANSWER IN ENGLISH, even if the user 
    asks in spanish, you must answer in english.",
    readLines("ia/system_prompt.md")
  ),
  model = "claude-haiku-4-5",
  echo = "all"
)

# cargar biblioteca rag
store <- ragnar_store_connect(
  "documentos/documentos.ragnar.duckdb",
  read_only = TRUE
)

# registrar herramienta rag con el modelo
ragnar_register_tool_retrieve(
  chat,
  store,
  top_k = 4,
  store_description = "Consulta de documentos sobre cálculos de alcohol en sangre para cálculo de extrapolación retrógrada de alcohol"
)

# registrar función
herramienta_retrobac <- tool(
  extrapolar_bac,
  description = "Función para cálculo de extrapolación retrógrada de alcohol. Calcular las horas transcurridas entre el evento y la medición. A partir del BAC o alcohol en el cuerpo medido y las horas transcurridas desde el evento, retorna: BAC estimado usando la tasa mínima y máxima, horas transcurridas, BAC medido de entrada, y las tasas de eliminación utilizadas. Usa esta función cuando te pidan calcular o estimar la concentración de alcohol en sangre (BAC) que un individuo en el momento de un incidente a partir de una medición analítica posterior.",
  arguments = list(
    bac_medido = type_number(
      required = TRUE,
      "Concentración de alcohol medida (g/L)."
    ),
    horas_transcurridas = type_number(
      required = TRUE,
      "Tiempo transcurrido entre el incidente y la medición, en horas. Debe ser >= 0."
    ),
    beta_min = type_number(
      required = FALSE,
      "Tasas de eliminación mínima (g/L/hora), por defecto 0.10."
    ),
    beta_max = type_number(
      required = FALSE,
      "Tasas de eliminación máxima (g/L/hora), por defecto 0.25."
    )
  )
)

# entregar herramienta
chat$register_tool(herramienta_retrobac)
