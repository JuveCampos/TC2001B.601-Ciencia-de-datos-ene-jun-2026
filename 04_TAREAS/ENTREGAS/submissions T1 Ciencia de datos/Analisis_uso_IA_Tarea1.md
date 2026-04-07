# Analisis de probable uso de IA - Tarea 1 Ciencia de Datos

**Fecha de analisis:** 2026-04-06  
**Metodo:** Comparacion cruzada de estilos de codigo, comentarios, errores, typos y patrones entre las 15 entregas.

> **Disclaimer:** Este analisis es orientativo. Ninguna de estas observaciones es concluyente por si sola. Se recomienda usar como guia para una revision manual mas profunda o para conversaciones con los alumnos.

---

## Indicadores utilizados

| Indicador | Señal de IA | Señal humana |
|-----------|-------------|--------------|
| Estilo de comentarios | Tercera persona impersonal ("Se filtra...", "Se obtienen...") | Informal, primera persona, inconsistente |
| Errores ortograficos en comentarios | Cero typos en cientos de lineas | Typos naturales ("libreroas", "columbas") |
| Ratio comentarios/codigo | >25% de lineas son comentarios explicativos | <15%, comentarios esporadicos |
| Funciones inexistentes | Funciones "alucinadas" por IA (theme_sub_axis_bottom, theme_replace) | Uso de funciones vistas en clase o documentacion |
| Consistencia de principio a fin | Mismo nivel de detalle y pulcritud en todo el script | Mas cuidado al inicio, descuido hacia el final |
| Errores logicos basicos | Muy raros | Presentes (filter con \|, aes con constantes, variable inexistente) |
| Adherencia perfecta a la rubrica | Todos los nombres de variables exactos, todas las preguntas respondidas | Nombres aproximados, preguntas omitidas |

---

## Clasificacion por alumno

### ALTA PROBABILIDAD

#### Verdugo Carranza Oscar (Calificacion: 100/100)

- **Comentarios en tercera persona impersonal** de principio a fin: "Se filtra...", "Se cargan...", "Se obtienen...", "Se calcula...", "Se crea..."
- **Cero errores de ortografia** en 568 lineas y 103 comentarios. Estadisticamente muy improbable para un estudiante.
- Perfeccion absoluta: todos los nombres de variables exactos, todas las preguntas respondidas, estructura impecable.
- Tiene un archivo `tarea codigo.R` (Ej1-8, version anterior) y `tarea codigo avance 2.R` (completo). Sugiere iteracion con IA.
- Cada bloque de codigo tiene un comentario descriptivo *antes*, como documentacion autogenerada.
- **Patron mas claro de la clase.** El estilo de comentarios es el patron clasico de ChatGPT/Claude.

#### Gomez Salazar Gerardo Alberto (Calificacion: 98/100)

- **Ratio de comentarios mas alto de la clase:** 149 comentarios en 458 lineas (32%).
- Cada linea de pipe tiene su propio comentario explicativo, patron tipico de IA que "ensena".
- Cero errores ortograficos en comentarios.
- Estilo perfectamente consistente de principio a fin. Los humanos tienden a ser mas descuidados hacia el final.
- **Atenuante:** Tiene personalidad propia (nombre del autor, titulo del proyecto) y el Ej16 con datos de Tesla muestra esfuerzo de busqueda genuino.

---

### PROBABILIDAD MEDIA-ALTA

#### Garces Camacho Jose Francisco (Calificacion: 83/100)

- 139 comentarios en 424 lineas (33%), ratio muy alto.
- Comentarios detallados y explicativos en cada operacion.
- **Atenuante importante:** Comete errores que la IA no cometeria: usa indicador no=156 (vehiculos) en vez de no=36 (diabetes) en Ej5. La numeracion de ejercicios esta desfasada a partir del Ej10. Estos son errores de atencion humana, no de generacion automatica.
- **Lectura probable:** Uso IA para generar la estructura y comentarios, pero ejecuto y modifico el mismo sin verificar completamente.

#### Jimenez Ramirez Danae (Calificacion: 91/100)

- Comentarios bien estructurados con estilo explicativo por linea, similar al patron de IA.
- **Atenuante fuerte:** Errores como `options(scipen=999)` dentro de `theme()` (linea 145) y `theme_sub_axis()` en Ej15, que no es una funcion existente.
- Estos errores son tipicos de **edicion humana de codigo generado por IA**: la IA genera la estructura, la alumna copia y modifica sin entender completamente cada parte.
- **Lectura probable:** Uso parcial de IA, con edicion manual posterior.

---

### PROBABILIDAD MEDIA (uso parcial probable)

#### Valerio Garcia Ruben Arturo (Calificacion: 95/100)

- Usa funciones que **no existen en ggplot2/ggthemes**: `theme_sub_axis_bottom()`, `theme_replace()`, `theme_update()`.
- Estas funciones son un indicador fuerte de **alucinacion de IA** (la IA "inventa" funciones que suenan plausibles pero no existen).
- **Atenuante fuerte:** Tiene MUCHOS typos humanos genuinos en comentarios: "columbas", "vaiable", "feculdiad", "desarollo", "tendendia", "dodne", "corrije", "Ejericicio" (repetido en 10 encabezados).
- **Lectura probable:** Escribio los comentarios el mismo (de ahi los typos) pero genero partes del codigo con IA (de ahi las funciones alucinadas).

#### Sepulveda Soto Mauricio (Calificacion: 92/100)

- **El mismo declara uso de IA** en linea 40: `#la funcion head la comprobe con IA, no recuerdo si fue utilizada en clase`
- Honestidad valorable. Indica que al menos consulto IA para verificar funciones.
- Codigo bien organizado pero con errores propios (comillas en filter del Ej12 en vez de backticks).
- **Lectura:** Uso IA como referencia/consulta, no como generador completo. Nivel de uso probablemente moderado.

---

### BAJA PROBABILIDAD (trabajo propio)

#### Ramirez Arroyo Ilse Irais (Calificacion: 96/100)

- Solo 24 comentarios en 339 lineas (7%). Codigo funcional pero minimalista.
- Patron tipico de estudiante que sabe lo que hace pero no documenta en exceso.
- Usa `read.csv()` de base R en vez de `read_csv()`, lo cual es mas tipico de aprendizaje propio.

#### Gomez Gonzalez Maria Jose (Calificacion: 92/100)

- Typos en comentarios: "libreroas", "clumnas".
- Errores de referencia a variable inexistente (`ev_2022`).
- Ej16 creativo con datos de World Athletics (Kaggle), limpieza con janitor. Muestra busqueda y esfuerzo genuino.
- Join tecnico incorrecto en Ej10 (year fuera de by=c()), error que IA no cometeria.

#### Reina Haponte Paula (Calificacion: 98/100)

- Estilo informal: usa `=` en vez de `<-` para asignacion.
- **Error logico imposible de IA:** `filter(year == 2002 | 2024)` — en R, `2024` siempre evalua como TRUE, asi que el filtro no hace lo esperado. Ningun LLM generaria este error.
- Comentarios en estilo personal e informal.
- Alto nivel de competencia genuina.

#### Daniel Moedano Victoria (Calificacion: 71/100)

- Solo 21 comentarios en 333 lineas (6%).
- No incluye Ej16.
- Error de sintaxis en Ej8 (ggplot cortado prematuramente).
- Entrega incompleta con patron claramente humano.

#### Gutierrez Solorio Salvador (Calificacion: 38/100)

- Solo 24 comentarios en 216 lineas (11%).
- Solo completo 9 de 16 ejercicios.
- Error fundamental: `aes(x = 1266, y = 40)` mapea constantes en vez de columnas.
- Claramente trabajo propio e incompleto.

#### Lopez Juarez Emilio (Calificacion: 86/100)

- Error de sintaxis (una `r` suelta en linea 131).
- Sin carpeta datos_problemario.
- Error logico en Ej2 (bottom 5 calculado sobre top 5).
- Patron de trabajo humano con descuidos.

#### Mercado Toledo Luis Ramon (Calificacion: 90/100)

- Nombre de archivo "Tarea lol.R" — improbable que IA sugiera esto.
- Error critico en Ej16: variable `afiliacion_estados` nunca definida.
- Codigo bien hecho pero con descuidos puntuales tipicos de estudiante.

#### Perez Reyes Santiago (Calificacion: 91/100, TARDIA)

- Usa `read.csv()` de base R.
- Varias graficas sin personalizacion minima (sin titulos ni ejes).
- Imprime `grafica_diabetes` en vez de `grafica_diabetes_final` en Ej8.
- Patron de trabajo propio con prisas (entrega tardia).

#### Flores Hernandez Alejandro (Calificacion: 63/100)

- No entrego archivo .R, solo PDF con resultados.
- Imposible analizar codigo fuente.
- No evaluable para uso de IA.

---

## Resumen ejecutivo

| Alumno | Probabilidad IA | Calificacion | Evidencia clave |
|--------|:---------------:|:------------:|-----------------|
| Verdugo Carranza Oscar | **ALTA** | 100 | Comentarios 3ra persona, 0 typos, perfeccion total |
| Gomez Salazar Gerardo Alberto | **ALTA** | 98 | 32% comentarios, 0 typos, cada linea comentada |
| Garces Camacho Jose Francisco | **Media-alta** | 83 | 33% comentarios, pero errores humanos de atencion |
| Jimenez Ramirez Danae | **Media-alta** | 91 | Estilo IA, pero errores de edicion humana |
| Valerio Garcia Ruben Arturo | **Media** | 95 | Funciones alucinadas + typos humanos = uso mixto |
| Sepulveda Soto Mauricio | **Media** | 92 | Declara uso parcial de IA (linea 40 del script) |
| Ramirez Arroyo Ilse Irais | Baja | 96 | Codigo minimalista, pocos comentarios |
| Gomez Gonzalez Maria Jose | Baja | 92 | Typos, errores propios, creatividad en Ej16 |
| Reina Haponte Paula | Baja | 98 | Error logico imposible de IA, estilo informal |
| Perez Reyes Santiago | Baja | 91 | Graficas sin pulir, entrega tardia |
| Mercado Toledo Luis Ramon | Baja | 90 | Nombre "lol.R", errores de variable |
| Lopez Juarez Emilio | Baja | 86 | Errores de sintaxis, sin carpeta datos |
| Daniel Moedano Victoria | Baja | 71 | Incompleto, error sintaxis, pocos comentarios |
| Flores Hernandez Alejandro | No evaluable | 63 | Sin archivo .R |
| Gutierrez Solorio Salvador | Baja | 38 | Muy incompleto, errores fundamentales |
