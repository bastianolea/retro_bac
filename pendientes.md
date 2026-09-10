- [x] eliminar las secciones “Signos y Síntomas” y “Estimación de Bebidas”, es decir solo quedarnos con “Extrapolación” que es el objetivo principal de la App; ese es el cambio más importante, y para probarla usa los datos del ejemplo para que la vayas viendo, 
- [x] te pido si puedes redondear a dos cifras el output de los resultados.
- [x] Y luego eliminar en la parte de los resultados debajo de la gráfica, las items: “tiempo transcurrido” y “concentración de alcohol…”, debido a que esa información esta en el Input data; entregue el cálculo y los resultados para cada rango de eliminación.

- [ ] google font local
- [ ] "Calculation details" debería estar en dos columnas
- [ ] mostrar texto "No results to show. Press Calculate extrapolation to get results." en "Retrograde extrapolation plot"
- [ ] mejorar responsividad en dispositivos móviles, controles deberían estar arriba
- [ ] armonizar idioma de la app (inglés como idioma de la aplicación, español como idioma del código)
  - [ ] traducir sección "Notas Importantes e Interpretación"
- [ ] implementar chatbot



- [ ] si la ventana es angosta, leyenda hacia abajo
- [ ] fórmulas formateadas con texto de mathjax

- [ ] refactorizar el cálculo de extrapolación a una función de R independiente

  Actualmente el cálculo principal vive en línea dentro del reactivo `resultado <- eventReactive(input$calcular, {...})` en `RetroBAC_V6.R` (aprox. línea 214). Planificación punto por punto:

  1. **Definir la función pura.** Crear `extrapolar_bac(bac_medido, horas_transcurridas, beta_min = BETA_MIN, beta_max = BETA_MAX)` que reciba solo valores numéricos (sin `input$` ni objetos reactivos) y devuelva una lista con `bac_min`, `bac_max` y los `beta` usados. Toda la lógica de negocio queda aislada de Shiny.
  2. **Separar cálculo de tiempo.** Mantener fuera de la función el parseo de fechas/horas (`ymd_hm`, `difftime`), o bien crear una segunda función auxiliar `calcular_horas(tiempo_evento, tiempo_medicion)` para poder probarla de forma independiente.
  3. **Ubicación en el proyecto.** Mover la(s) función(es) a un archivo separado (p. ej. `R/calculos.R`) y cargarlo con `source()` al inicio de `RetroBAC_V6.R`, dejando la app enfocada en la UI/servidor.
  4. **Adaptar el reactivo.** Reemplazar el cálculo en línea del `eventReactive` por una llamada a `extrapolar_bac(...)`, conservando el `req(iv$is_valid())` y el redondeo a dos cifras.
  5. **Manejo de casos límite.** Documentar y validar dentro de la función qué hacer si `horas_transcurridas` es negativa o cero (evento posterior a la medición), en lugar de dejarlo pasar silenciosamente.
  6. **Pruebas.** Agregar tests con `testthat` que verifiquen la fórmula de Widmark con valores conocidos (p. ej. los datos del ejemplo) y los casos límite.
  7. **Documentación.** Documentar la función (roxygen o comentario de cabecera) y actualizar `documentacion.qmd` / `documentos/marco_teorico.qmd` para reflejar la nueva estructura.