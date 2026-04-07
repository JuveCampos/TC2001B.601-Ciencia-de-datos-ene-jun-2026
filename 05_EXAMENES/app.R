# ============================================================================
# Aplicación Shiny - Examen de Opción Múltiple
# Curso: TC2001B - Ciencia de datos para política pública
# Tec de Monterrey
# ============================================================================
#
# Descripción:
# Genera un examen aleatorio tomando 2 preguntas por tema desde un archivo
# Excel. El estudiante responde, recibe su calificación y, si la acepta,
# visualiza las preguntas incorrectas con la explicación correspondiente.
#
# ============================================================================

library(shiny)
library(readxl)
library(dplyr)
library(purrr)

# ----------------------------------------------------------------------------
# CONFIGURACIÓN: ubicación del archivo de preguntas
# Modifique esta ruta si el archivo se encuentra en otra ubicación
# ----------------------------------------------------------------------------
ruta_preguntas <- "preguntas_opcion_multiple.xlsx"

# Número de preguntas a seleccionar por tema
preguntas_por_tema <- 2

# ----------------------------------------------------------------------------
# Carga y validación del banco de preguntas
# ----------------------------------------------------------------------------
cargar_banco <- function(ruta) {
  stopifnot("El archivo de preguntas no existe" = file.exists(ruta))

  banco <- read_excel(ruta) %>%
    as_tibble() %>%
    mutate(
      tema = as.character(tema),
      pregunta = as.character(pregunta),
      opcion_correcta = toupper(trimws(as.character(opcion_correcta)))
    ) %>%
    filter(!is.na(pregunta), !is.na(tema))

  columnas_req <- c("tema", "pregunta", "opcion_a", "opcion_b",
                    "opcion_c", "opcion_d", "opcion_correcta", "explicacion")
  stopifnot("Faltan columnas en el archivo" = all(columnas_req %in% colnames(banco)))

  banco
}

# ----------------------------------------------------------------------------
# Selección aleatoria: n preguntas por cada tema
# ----------------------------------------------------------------------------
generar_examen <- function(banco, n = 2) {
  set.seed(as.integer(Sys.time()))

  examen <- banco %>%
    group_by(tema) %>%
    slice_sample(n = n) %>%
    ungroup() %>%
    arrange(tema) %>%
    mutate(id_pregunta = paste0("q_", row_number()))

  examen
}

# ----------------------------------------------------------------------------
# CSS personalizado siguiendo el estilo del curso
# Fuente Ubuntu, azul institucional #1e4c7d
# ----------------------------------------------------------------------------
estilo_css <- HTML("
@import url('https://fonts.googleapis.com/css2?family=Ubuntu:wght@300;400;500;700&display=swap');

body {
  font-family: 'Ubuntu', sans-serif;
  background: linear-gradient(135deg, #f5f7fa 0%, #e8eef4 100%);
  color: #2c3e50;
  margin: 0;
  padding: 0;
}

.contenedor-principal {
  max-width: 900px;
  margin: 30px auto;
  padding: 0 20px;
}

.encabezado {
  background: linear-gradient(135deg, #1e4c7d 0%, #2d6fa8 100%);
  color: white;
  padding: 30px 40px;
  border-radius: 12px 12px 0 0;
  box-shadow: 0 4px 20px rgba(30, 76, 125, 0.15);
}

.encabezado h1 {
  margin: 0;
  font-weight: 700;
  font-size: 28px;
}

.encabezado p {
  margin: 8px 0 0 0;
  font-weight: 300;
  opacity: 0.95;
}

.panel-instrucciones {
  background: white;
  padding: 25px 40px;
  border-left: 5px solid #1e4c7d;
  margin-bottom: 25px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.05);
}

.panel-instrucciones h3 {
  color: #1e4c7d;
  margin-top: 0;
}

.tarjeta-pregunta {
  background: white;
  padding: 25px 35px;
  margin-bottom: 20px;
  border-radius: 10px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.06);
  border-top: 4px solid #1e4c7d;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.tarjeta-pregunta:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 18px rgba(30, 76, 125, 0.12);
}

.etiqueta-tema {
  display: inline-block;
  background: #1e4c7d;
  color: white;
  padding: 5px 14px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 500;
  margin-bottom: 12px;
  letter-spacing: 0.3px;
}

.numero-pregunta {
  color: #7f8c8d;
  font-size: 13px;
  font-weight: 500;
  margin-left: 10px;
}

.texto-pregunta {
  font-size: 17px;
  font-weight: 500;
  color: #2c3e50;
  margin-bottom: 18px;
  line-height: 1.5;
}

.tarjeta-pregunta .radio label {
  display: block;
  padding: 10px 14px;
  margin: 6px 0;
  background: #f8f9fb;
  border-radius: 6px;
  border: 1px solid #e4e8ef;
  cursor: pointer;
  transition: all 0.2s ease;
  font-weight: 400;
}

.tarjeta-pregunta .radio label:hover {
  background: #eef2f8;
  border-color: #1e4c7d;
}

.tarjeta-pregunta .radio input[type='radio'] {
  margin-right: 10px;
}

.boton-principal {
  background: linear-gradient(135deg, #1e4c7d 0%, #2d6fa8 100%) !important;
  color: white !important;
  border: none !important;
  padding: 14px 40px !important;
  border-radius: 8px !important;
  font-size: 16px !important;
  font-weight: 500 !important;
  font-family: 'Ubuntu', sans-serif !important;
  cursor: pointer !important;
  box-shadow: 0 4px 12px rgba(30, 76, 125, 0.25) !important;
  transition: all 0.3s ease !important;
}

.boton-principal:hover {
  transform: translateY(-2px) !important;
  box-shadow: 0 6px 18px rgba(30, 76, 125, 0.35) !important;
}

.panel-calificacion {
  background: white;
  padding: 40px;
  border-radius: 12px;
  text-align: center;
  box-shadow: 0 4px 20px rgba(30, 76, 125, 0.1);
  margin-bottom: 20px;
}

.calificacion-numero {
  font-size: 72px;
  font-weight: 700;
  margin: 20px 0;
  background: linear-gradient(135deg, #1e4c7d 0%, #2d6fa8 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

.calificacion-aprobado { color: #27ae60 !important; -webkit-text-fill-color: #27ae60 !important; }
.calificacion-reprobado { color: #c0392b !important; -webkit-text-fill-color: #c0392b !important; }

.detalle-resultados {
  font-size: 16px;
  color: #5a6c7d;
  margin: 15px 0;
}

.banner-revision {
  background: linear-gradient(135deg, #fff8e1 0%, #ffecb3 100%);
  border-left: 5px solid #f39c12;
  padding: 20px 30px;
  border-radius: 8px;
  margin-bottom: 20px;
}

.banner-revision h3 {
  color: #b8771a;
  margin: 0 0 8px 0;
}

.tarjeta-incorrecta {
  background: white;
  padding: 25px 35px;
  margin-bottom: 18px;
  border-radius: 10px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.06);
  border-left: 5px solid #c0392b;
}

.respuesta-estudiante {
  background: #fdeeee;
  padding: 10px 15px;
  border-radius: 6px;
  margin: 10px 0;
  color: #922b21;
  font-weight: 500;
}

.respuesta-correcta {
  background: #e8f6ef;
  padding: 10px 15px;
  border-radius: 6px;
  margin: 10px 0;
  color: #1e7e47;
  font-weight: 500;
}

.caja-explicacion {
  background: #f0f4f9;
  border-left: 4px solid #1e4c7d;
  padding: 15px 20px;
  margin-top: 12px;
  border-radius: 6px;
  font-size: 14px;
  line-height: 1.6;
  color: #34495e;
}

.caja-explicacion strong {
  color: #1e4c7d;
}

.pie-pagina {
  text-align: center;
  color: #95a5a6;
  font-size: 12px;
  padding: 25px;
  margin-top: 20px;
}
")

# ----------------------------------------------------------------------------
# UI
# ----------------------------------------------------------------------------
ui <- fluidPage(
  tags$head(
    tags$title("Examen - TC2001B Ciencia de Datos"),
    tags$style(estilo_css)
  ),

  div(class = "contenedor-principal",
      div(class = "encabezado",
          h1("Examen de Ciencia de Datos"),
          p("TC2001B - Ciencia de datos para política pública | Tec de Monterrey")
      ),

      uiOutput("contenido_dinamico"),

      div(class = "pie-pagina",
          HTML("&copy; 2026 Tec de Monterrey - TC2001B")
      )
  )
)

# ----------------------------------------------------------------------------
# SERVER
# ----------------------------------------------------------------------------
server <- function(input, output, session) {

  # Estado de la aplicación
  estado <- reactiveValues(
    etapa = "examen",        # etapa: "examen", "calificacion", "revision"
    examen = NULL,
    respuestas = NULL,
    calificacion = NULL,
    incorrectas = NULL
  )

  # Carga inicial del banco y generación del examen
  observe({
    if (is.null(estado$examen)) {
      banco <- cargar_banco(ruta_preguntas)
      estado$examen <- generar_examen(banco, n = preguntas_por_tema)
    }
  })

  # --------------------------------------------------------------------------
  # Renderizado dinámico según etapa
  # --------------------------------------------------------------------------
  output$contenido_dinamico <- renderUI({
    req(estado$examen)

    if (estado$etapa == "examen") {
      renderizar_examen(estado$examen)
    } else if (estado$etapa == "calificacion") {
      renderizar_calificacion(estado$calificacion, nrow(estado$examen))
    } else if (estado$etapa == "revision") {
      renderizar_revision(estado$incorrectas)
    }
  })

  # Vista del examen
  renderizar_examen <- function(examen) {
    tagList(
      div(class = "panel-instrucciones",
          h3("Instrucciones"),
          p(sprintf("El examen consta de %d preguntas agrupadas por tema. Selecciona la respuesta que consideres correcta para cada pregunta. Al terminar, presiona el botón \"Calificar examen\" al final de la página.",
                    nrow(examen))),
          p(tags$em("Asegúrate de responder todas las preguntas antes de enviar."))
      ),

      # Construcción de cada tarjeta de pregunta
      pmap(list(examen$id_pregunta, examen$tema, examen$pregunta,
                examen$opcion_a, examen$opcion_b, examen$opcion_c,
                examen$opcion_d, seq_len(nrow(examen))),
           function(id, tema, pregunta, a, b, c, d, num) {
             div(class = "tarjeta-pregunta",
                 span(class = "etiqueta-tema", tema),
                 span(class = "numero-pregunta", sprintf("Pregunta %d", num)),
                 div(class = "texto-pregunta", pregunta),
                 radioButtons(
                   inputId = id,
                   label = NULL,
                   choices = c(
                     setNames("A", paste("A)", a)),
                     setNames("B", paste("B)", b)),
                     setNames("C", paste("C)", c)),
                     setNames("D", paste("D)", d))
                   ),
                   selected = character(0)
                 )
             )
           }),

      div(style = "text-align: center; padding: 30px 0;",
          actionButton("btn_calificar", "Calificar examen",
                       class = "boton-principal")
      )
    )
  }

  # Vista de calificación
  renderizar_calificacion <- function(cal, total) {
    clase_color <- if (cal$porcentaje >= 70) "calificacion-aprobado" else "calificacion-reprobado"
    mensaje <- if (cal$porcentaje >= 70) {
      "¡Felicidades! Has aprobado el examen."
    } else {
      "No has alcanzado la calificación mínima. Te recomendamos revisar los temas."
    }

    tagList(
      div(class = "panel-calificacion",
          h2("Resultado del examen", style = "color: #1e4c7d; margin-top: 0;"),
          div(class = paste("calificacion-numero", clase_color),
              sprintf("%.1f", cal$porcentaje), tags$small("/ 100")),
          p(class = "detalle-resultados",
            sprintf("Respuestas correctas: %d de %d", cal$correctas, total)),
          p(class = "detalle-resultados", tags$strong(mensaje)),
          tags$hr(style = "margin: 25px 0;"),
          p("¿Aceptas tu calificación y deseas revisar las preguntas que contestaste incorrectamente?",
            style = "font-size: 15px; color: #5a6c7d;"),
          div(style = "margin-top: 20px;",
              actionButton("btn_aceptar", "Aceptar y revisar errores",
                           class = "boton-principal"),
              tags$span(style = "display: inline-block; width: 15px;"),
              actionButton("btn_reiniciar", "Generar otro examen",
                           class = "boton-principal")
          )
      )
    )
  }

  # Vista de revisión de errores
  renderizar_revision <- function(incorrectas) {
    if (nrow(incorrectas) == 0) {
      return(
        div(class = "panel-calificacion",
            h2("Excelente desempeño", style = "color: #27ae60;"),
            p("No tuviste errores en este examen. ¡Felicitaciones!"),
            actionButton("btn_reiniciar", "Generar otro examen",
                         class = "boton-principal")
        )
      )
    }

    tagList(
      div(class = "banner-revision",
          h3("Revisión de respuestas incorrectas"),
          p(sprintf("A continuación se muestran las %d preguntas que contestaste de forma incorrecta, junto con la explicación de la respuesta correcta.",
                    nrow(incorrectas)))
      ),

      pmap(list(incorrectas$tema, incorrectas$pregunta,
                incorrectas$respuesta_estudiante_texto,
                incorrectas$respuesta_correcta_texto,
                incorrectas$explicacion, seq_len(nrow(incorrectas))),
           function(tema, preg, r_est, r_cor, exp, num) {
             div(class = "tarjeta-incorrecta",
                 span(class = "etiqueta-tema", tema),
                 span(class = "numero-pregunta", sprintf("Error %d", num)),
                 div(class = "texto-pregunta", preg),
                 div(class = "respuesta-estudiante",
                     tags$strong("Tu respuesta: "), r_est),
                 div(class = "respuesta-correcta",
                     tags$strong("Respuesta correcta: "), r_cor),
                 div(class = "caja-explicacion",
                     tags$strong("Explicación: "), exp)
             )
           }),

      div(style = "text-align: center; padding: 30px 0;",
          actionButton("btn_reiniciar", "Generar otro examen",
                       class = "boton-principal")
      )
    )
  }

  # --------------------------------------------------------------------------
  # Evento: calificar examen
  # --------------------------------------------------------------------------
  observeEvent(input$btn_calificar, {
    examen <- estado$examen

    # Recopilar respuestas del estudiante
    respuestas <- map_chr(examen$id_pregunta, function(id) {
      val <- input[[id]]
      if (is.null(val) || length(val) == 0) NA_character_ else as.character(val)
    })

    # Validar que haya respondido todo
    if (any(is.na(respuestas))) {
      no_respondidas <- sum(is.na(respuestas))
      showModal(modalDialog(
        title = "Examen incompleto",
        sprintf("Faltan %d preguntas por responder. Por favor contesta todas antes de calificar.",
                no_respondidas),
        easyClose = TRUE,
        footer = modalButton("Entendido")
      ))
      return()
    }

    # Calcular calificación
    correctas <- sum(respuestas == examen$opcion_correcta)
    total <- nrow(examen)
    porcentaje <- (correctas / total) * 100

    estado$respuestas <- respuestas
    estado$calificacion <- list(
      correctas = correctas,
      total = total,
      porcentaje = porcentaje
    )

    # Preparar tabla de incorrectas con textos completos para la revisión
    obtener_texto <- function(fila, letra) {
      col <- paste0("opcion_", tolower(letra))
      fila[[col]]
    }

    idx_mal <- which(respuestas != examen$opcion_correcta)
    if (length(idx_mal) > 0) {
      incorrectas <- examen[idx_mal, ] %>%
        mutate(
          respuesta_estudiante = respuestas[idx_mal],
          respuesta_estudiante_texto = map2_chr(
            respuesta_estudiante, row_number(),
            ~ sprintf("%s) %s", .x, obtener_texto(examen[idx_mal[.y], ], .x))
          ),
          respuesta_correcta_texto = map2_chr(
            opcion_correcta, row_number(),
            ~ sprintf("%s) %s", .x, obtener_texto(examen[idx_mal[.y], ], .x))
          )
        )
    } else {
      incorrectas <- examen[0, ] %>%
        mutate(respuesta_estudiante_texto = character(0),
               respuesta_correcta_texto = character(0))
    }

    estado$incorrectas <- incorrectas
    estado$etapa <- "calificacion"
  })

  # Evento: aceptar calificación y mostrar revisión
  observeEvent(input$btn_aceptar, {
    estado$etapa <- "revision"
  })

  # Evento: reiniciar con nuevo examen
  observeEvent(input$btn_reiniciar, {
    banco <- cargar_banco(ruta_preguntas)
    estado$examen <- generar_examen(banco, n = preguntas_por_tema)
    estado$respuestas <- NULL
    estado$calificacion <- NULL
    estado$incorrectas <- NULL
    estado$etapa <- "examen"
  })
}

# ----------------------------------------------------------------------------
# Lanzamiento de la aplicación
# ----------------------------------------------------------------------------
shinyApp(ui = ui, server = server)
