# Contexto del directorio `05_EXAMENES`

Este directorio contiene los materiales de evaluación del curso **TC2001B — Ciencia de datos para política pública** (Tec de Monterrey).

## Propósito

Generar exámenes de opción múltiple para los estudiantes del curso a partir de un banco de preguntas curado por el profesor, cubriendo las 14 sesiones del semestre + una sección de práctica/ejercicios.

## Archivos principales

### Banco de preguntas
- **`preguntas_opcion_multiple.xlsx`** — banco con 140 preguntas (14 temas × 10 preguntas).
  - Hoja única `Sheet1`.
  - Columnas: `tema`, `pregunta`, `opcion_a`, `opcion_b`, `opcion_c`, `opcion_d`, `opcion_correcta` (valores A/B/C/D), `explicacion`.
  - Temas: Sesión 1 a Sesión 13 + "Práctica y ejercicios".

### Documentos de apoyo
- **`base_conocimientos.md`** — base de conocimiento del curso usada para generar preguntas.
- **`ejercicios_codigo.md`** — ejercicios prácticos de código.
- **`contexto_generacion_preguntas.md`** — contexto usado al generar las preguntas con IA.

### Aplicación Shiny de examen
- **`app.R`** — aplicación Shiny que renderiza un examen aleatorio.
  - Variable de configuración `ruta_preguntas` al inicio del archivo para apuntar al Excel.
  - Selecciona `preguntas_por_tema = 2` preguntas aleatorias por cada tema (28 preguntas por examen).
  - Tres etapas controladas por `estado$etapa`: `"examen"` → `"calificacion"` → `"revision"`.
  - Flujo: el estudiante responde → botón "Calificar examen" (valida completitud) → muestra calificación (%) → botón "Aceptar y revisar errores" → muestra tarjetas con respuesta del estudiante, respuesta correcta y explicación.
  - Botón "Generar otro examen" disponible en calificación y revisión.
  - Umbral de aprobación visual: 70%.
  - Usa `tidyverse` (`dplyr`, `purrr::pmap`), `shiny`, `readxl`.
  - Estilo CSS embebido siguiendo la identidad visual del curso: fuente **Ubuntu**, azul institucional **#1e4c7d**, gradientes, tarjetas con sombra, banner de revisión amarillo, tarjetas de error con borde rojo.

- **`TC2001B_Examen.Rproj`** — archivo de proyecto RStudio. Al abrirlo, fija este directorio como working directory, lo que permite que `ruta_preguntas = "preguntas_opcion_multiple.xlsx"` funcione con ruta relativa.

## Cómo ejecutar la aplicación

1. Abrir `TC2001B_Examen.Rproj` en RStudio (fija el working directory).
2. Abrir `app.R` y hacer clic en **Run App** (o ejecutar `shiny::runApp()`).
3. Paquetes requeridos: `shiny`, `readxl`, `dplyr`, `purrr`.

## Convenciones seguidas (del CLAUDE.md global del usuario)

- Código R en **tidyverse** con pipe `%>%`.
- `snake_case` para variables, indentación de 2 espacios, asignación `<-`.
- Comentarios informativos en lugar de `cat()`/`print()` salvo para interpolar variables.
- `stopifnot()` para validación de precondiciones.
- `set.seed()` al generar aleatorios (en `generar_examen()` se usa `Sys.time()` para que cada examen sea distinto).

## Estilo visual del curso (memoria global del usuario)

Las presentaciones y aplicaciones del curso siguen un estilo consistente:
- Fuente **Ubuntu** (Google Fonts).
- Color primario **#1e4c7d** (azul institucional), con gradiente hacia **#2d6fa8**.
- Banners con borde lateral de color, highlight boxes, tarjetas con sombra suave.
- Tipografía jerárquica con pesos 300/400/500/700.

## Estado actual

- Banco de 140 preguntas completo y validado.
- Aplicación Shiny funcional generada el 2026-04-07.
- El working directory al ejecutar la app debe ser `05_EXAMENES/` (garantizado por el `.Rproj`).
