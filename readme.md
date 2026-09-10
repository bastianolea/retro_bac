# Retro-BAC
_Aplicación de acceso abierto para el cálculo de extrapolación retrógrada de alcohol_

2026-09-09

## Objetivos del proyecto

Retro-BAC es una aplicación en R Shiny desarrollada para asistir a los
laboratorios de toxicología forense en el **cálculo de extrapolación
retrógrada de alcohol**, una solicitud frecuente en el ámbito pericial.
Su objetivo es estimar la concentración de alcohol en sangre (BAC) que
un individuo tenía en el momento de un incidente a partir de una
medición analítica posterior.

Los cálculos siguen la guía de consenso **ANSI/ASB Best Practice
Recommendation 122, 1.ª ed. (2024)**, que establece un fundamento
científico común para estas estimaciones y su uso en escenarios
judiciales. La aplicación busca ofrecer:

- Un entorno amigable para obtener resultados en tiempo real (concepto
  de *caja blanca*).
- Estimaciones basadas en una guía de consenso actualizada.
- Generación automática de reportes que sirven como documentación de
  registro.

## Definiciones principales

El cálculo básico de extrapolación retrógrada se expresa como:

$$
AC_{inc} = AC_{test} + (\beta \times T)
$$

| Símbolo | Definición | Unidad |
|----|----|----|
| $AC_{inc}$ | Concentración de alcohol estimada en el momento del incidente | g/L |
| $AC_{test}$ | Concentración de alcohol medida (analítica) | g/L |
| $\beta$ | Tasa de eliminación de alcohol | g/L/hora |
| $T$ | Tiempo entre el incidente y la toma de muestra | horas |

Dado que la tasa de eliminación $\beta$ varía entre individuos, la
aplicación no reporta un valor único sino un **rango**, calculado con
una tasa mínima ($\beta_{min}$ = 0.10 g/L/h) y una máxima ($\beta_{max}$
= 0.25 g/L/h). La herramienta está pensada para casos post-absortivos y
**no tiene validez legal por sí misma**: es un apoyo al análisis
pericial experto.

## Entregables

| Entregable | Descripción |
|----|----|
| Aplicación Shiny | [`RetroBAC_V6.R`](RetroBAC_V6.R): app de un solo archivo con cálculo, validación y visualización |
| Rango de BAC estimado | Límites inferior y superior de la concentración en el momento del incidente |
| Gráfico de línea temporal | Visualización del punto analítico y las extrapolaciones a lo largo del tiempo |
| Reporte descargable | Documento Word (`.docx`) con datos de entrada, resultados y gráfico |
| Documentación técnica | [`documentacion.qmd`](documentacion.qmd): estructura interna, diagramas y notas de mantenimiento |

## Próximos pasos

- Versión en español de la interfaz para ampliar su alcance.
- Extensión a otros cálculos incorporados en la guía ANSI/ASB de
  referencia.

## Autores

Espinoza Cruz, Carlos (1,4); Moreno Paz, José (1); Gómez Olmos, Yolanda
(2); Caselles Gil, José (3).

1.  Servicio Médico Legal de Copiapó, Chile.
2.  Departamento de Estadística, Facultad de Ciencias, Universidad del
    Bío-Bío, Chile.
3.  Servicio de Farmacia, Hospital Universitario de Fuenlabrada, Madrid,
    España.
4.  Universidad de Santiago de Compostela, España.

## Referencias

1.  Labay L. y Logan B. (2018). *Call for a Scientific Consensus
    Regarding the Application of Retrograde Extrapolation to Determine
    Blood Alcohol Content in DUI Cases*. J Forensic Sci, 63(5).
2.  LeBeau MA. y Limoges JF. (2024). *Answering the call for a
    scientific consensus…* J Forensic Sci, 69:1935.
3.  Academy Standards Board (2024). *ANSI/ASB BPR 122 – Best Practice
    Recommendation for Performing Alcohol Calculations in Forensic
    Toxicology*, 1.ª edición.
