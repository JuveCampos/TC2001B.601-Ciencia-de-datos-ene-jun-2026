# ============================================================================
# Aplicación Shiny - Guía de estudio de opción múltiple
# Curso: TC2001B - Ciencia de datos para política pública
# Tec de Monterrey
# ============================================================================
#
# Descripción:
# Guía de estudio interactiva con 120 preguntas de opción múltiple repartidas
# en 8 temas de Machine Learning. El estudiante elige un tema (o todos),
# responde, recibe su calificación y, si la acepta, revisa las preguntas
# incorrectas con su explicación.
#
# El banco se carga desde un archivo .rds (no legible en Excel).
# ============================================================================

library(shiny)
library(dplyr)
library(purrr)

# ----------------------------------------------------------------------------
# CONFIGURACIÓN
# ----------------------------------------------------------------------------
ruta_preguntas <- "preguntas_guia_ml.rds"

# ----------------------------------------------------------------------------
# Carga y validación del banco de preguntas
# ----------------------------------------------------------------------------
cargar_banco <- function(ruta) {
  stopifnot("El archivo de preguntas no existe" = file.exists(ruta))

  banco <- readRDS(ruta) %>%
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

# Banco completo en memoria (para poblar el selector de temas)
banco_completo <- cargar_banco(ruta_preguntas)
temas_disponibles <- sort(unique(banco_completo$tema))

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

.tarjeta-pregunta .form-group {
  width: 100%;
}

.tarjeta-pregunta .shiny-options-group {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 6px 12px;
  width: 100%;
}

.tarjeta-pregunta .shiny-options-group .radio {
  margin: 0;
  width: 100%;
}

.tarjeta-pregunta .shiny-options-group .radio label {
  min-height: 48px;
  display: flex;
  align-items: center;
  width: 100%;
  box-sizing: border-box;
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

.panel-inicio {
  background: white;
  padding: 40px;
  border-radius: 12px;
  text-align: center;
  box-shadow: 0 4px 20px rgba(30, 76, 125, 0.1);
  margin-top: 25px;
}

.panel-inicio h2 {
  color: #1e4c7d;
  margin-top: 0;
}

.panel-inicio p {
  color: #5a6c7d;
  font-size: 15px;
  max-width: 600px;
  margin: 0 auto 25px auto;
  line-height: 1.6;
}

.controles-inicio {
  max-width: 480px;
  margin: 0 auto 25px auto;
  text-align: left;
}

.controles-inicio .form-group { margin-bottom: 16px; }

.controles-inicio label {
  color: #1e4c7d;
  font-weight: 500;
}

.controles-inicio .selectize-input,
.controles-inicio select {
  font-family: 'Ubuntu', sans-serif;
  border-radius: 6px;
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
    tags$title("Guía de estudio - TC2001B Ciencia de Datos"),
    tags$style(estilo_css)
  ),

  div(class = "contenedor-principal",
      div(class = "encabezado",
          h1("Guía de estudio de Machine Learning"),
          p("TC2001B - Ciencia de datos para política pública | Tec de Monterrey")
      ),

      uiOutput("contenido_dinamico"),

      div(class = "pie-pagina",
          HTML("&copy; 2026 Tec de Monterrey - TC2001B<br>Elaborado por Juvenal Campos :3")
      )
  )
)

# ----------------------------------------------------------------------------
# SERVER
# ----------------------------------------------------------------------------
server <- function(input, output, session) {

  # Estado de la aplicación
  estado <- reactiveValues(
    etapa = "inicio",         # etapa: "inicio", "examen", "calificacion", "revision"
    examen = NULL,
    respuestas = NULL,
    calificacion = NULL,
    incorrectas = NULL
  )

  # --------------------------------------------------------------------------
  # Renderizado dinámico según etapa
  # --------------------------------------------------------------------------
  output$contenido_dinamico <- renderUI({
    if (estado$etapa == "inicio") {
      renderizar_inicio()
    } else if (estado$etapa == "examen") {
      renderizar_examen(estado$examen)
    } else if (estado$etapa == "calificacion") {
      renderizar_calificacion(estado$calificacion, nrow(estado$examen))
    } else if (estado$etapa == "revision") {
      renderizar_revision(estado$incorrectas)
    }
  })

  # Vista de inicio
  renderizar_inicio <- function() {
    div(class = "panel-inicio",
        h2("Bienvenido a la guía de estudio"),
        p("Esta guía contiene 120 preguntas de opción múltiple sobre ocho temas de Machine Learning. Elige el tema que quieras practicar (o todos), responde cada pregunta y, al finalizar, presiona \"Calificar\" para obtener tu resultado y revisar tus errores con la explicación."),
        div(class = "controles-inicio",
            selectInput(
              "sel_tema", "Tema a practicar:",
              choices = c("Todos los temas", temas_disponibles),
              selected = "Todos los temas", width = "100%"
            ),
            selectInput(
              "sel_cantidad", "Número de preguntas:",
              choices = c("Todas", "10", "20", "30"),
              selected = "Todas", width = "100%"
            ),
            checkboxInput(
              "sel_aleatorio", "Ordenar las preguntas al azar", value = TRUE
            )
        ),
        div(style = "margin-top: 20px;",
            actionButton("btn_comenzar", "Comenzar",
                         class = "boton-principal"))
    )
  }

  # Vista del examen
  renderizar_examen <- function(examen) {
    tagList(
      div(class = "panel-instrucciones",
          h3("Instrucciones"),
          p(sprintf("Esta sesión consta de %d preguntas. Selecciona la respuesta que consideres correcta para cada pregunta. Al terminar, presiona el botón \"Calificar\" al final de la página.",
                    nrow(examen))),
          p(tags$em("Asegúrate de responder todas las preguntas antes de enviar."))
      ),

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
          actionButton("btn_calificar", "Calificar",
                       class = "boton-principal"),
          tags$span(style = "display: inline-block; width: 15px;"),
          actionButton("btn_reiniciar", "Volver al inicio",
                       class = "boton-principal")
      )
    )
  }

  # Vista de calificación
  renderizar_calificacion <- function(cal, total) {
    # Guía de estudio: sin umbral de aprobado/reprobado, solo retroalimentación.
    mensaje <- if (cal$porcentaje == 100) {
      "¡Excelente! Acertaste todas las preguntas."
    } else if (cal$porcentaje >= 70) {
      "Vas bien. Revisa tus errores para afianzar los detalles."
    } else {
      "Buen punto de partida. Revisa tus errores y vuelve a practicar el tema."
    }

    tagList(
      div(class = "panel-calificacion",
          h2("Resultado", style = "color: #1e4c7d; margin-top: 0;"),
          div(class = "calificacion-numero",
              sprintf("%.1f", cal$porcentaje), tags$small("/ 100")),
          p(class = "detalle-resultados",
            sprintf("Respuestas correctas: %d de %d", cal$correctas, total)),
          p(class = "detalle-resultados", tags$strong(mensaje)),
          tags$hr(style = "margin: 25px 0;"),
          p("¿Deseas revisar las preguntas que contestaste incorrectamente?",
            style = "font-size: 15px; color: #5a6c7d;"),
          div(style = "margin-top: 20px;",
              actionButton("btn_aceptar", "Revisar errores",
                           class = "boton-principal"),
              tags$span(style = "display: inline-block; width: 15px;"),
              actionButton("btn_reiniciar", "Volver al inicio",
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
            p("No tuviste errores. ¡Felicitaciones!"),
            div(style = "margin-top: 20px;",
                actionButton("btn_reiniciar", "Volver al inicio",
                             class = "boton-principal"))
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
          actionButton("btn_reiniciar", "Volver al inicio",
                       class = "boton-principal")
      )
    )
  }

  # --------------------------------------------------------------------------
  # Evento: comenzar — filtra por tema, ordena y limita la cantidad
  # --------------------------------------------------------------------------
  observeEvent(input$btn_comenzar, {
    seleccion <- banco_completo

    # Filtro por tema
    if (!is.null(input$sel_tema) && input$sel_tema != "Todos los temas") {
      seleccion <- seleccion %>% filter(tema == input$sel_tema)
    }

    # Orden aleatorio opcional
    if (isTRUE(input$sel_aleatorio)) {
      seleccion <- seleccion %>% slice_sample(prop = 1)
    }

    # Límite de cantidad
    if (!is.null(input$sel_cantidad) && input$sel_cantidad != "Todas") {
      n_pedidas <- as.integer(input$sel_cantidad)
      seleccion <- seleccion %>% slice_head(n = min(n_pedidas, nrow(seleccion)))
    }

    # id_pregunta estable para esta sesión (tras filtrar y ordenar)
    seleccion <- seleccion %>% mutate(id_pregunta = paste0("q_", row_number()))

    estado$examen <- seleccion
    estado$etapa <- "examen"
  })

  # --------------------------------------------------------------------------
  # Evento: calificar examen
  # --------------------------------------------------------------------------
  observeEvent(input$btn_calificar, {
    examen <- estado$examen

    respuestas <- map_chr(examen$id_pregunta, function(id) {
      val <- input[[id]]
      if (is.null(val) || length(val) == 0) NA_character_ else as.character(val)
    })

    if (any(is.na(respuestas))) {
      no_respondidas <- sum(is.na(respuestas))
      showModal(modalDialog(
        title = "Sesión incompleta",
        sprintf("Faltan %d preguntas por responder. Por favor contesta todas antes de calificar.",
                no_respondidas),
        easyClose = TRUE,
        footer = modalButton("Entendido")
      ))
      return()
    }

    correctas <- sum(respuestas == examen$opcion_correcta)
    total <- nrow(examen)
    porcentaje <- (correctas / total) * 100

    estado$respuestas <- respuestas
    estado$calificacion <- list(
      correctas = correctas,
      total = total,
      porcentaje = porcentaje
    )

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

  # Evento: reiniciar — vuelve al inicio
  observeEvent(input$btn_reiniciar, {
    estado$respuestas <- NULL
    estado$calificacion <- NULL
    estado$incorrectas <- NULL
    estado$examen <- NULL
    estado$etapa <- "inicio"
  })
}

# ----------------------------------------------------------------------------
# Lanzamiento de la aplicación
# ----------------------------------------------------------------------------
shinyApp(ui = ui, server = server)
