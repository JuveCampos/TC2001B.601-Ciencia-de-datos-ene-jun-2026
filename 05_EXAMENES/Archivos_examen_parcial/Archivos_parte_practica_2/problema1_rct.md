# Problema 1 (versión RCT).

Un equipo de investigación del área de salud pública diseñó un **ensayo
controlado aleatorizado** (*Randomized Controlled Trial*, RCT) para evaluar
si una nueva vitamina, llamada **"VitaEstudio"**, mejora el rendimiento
académico de estudiantes universitarios. La hipótesis de los
investigadores es que la vitamina incrementa la concentración y, con ello,
la calificación promedio del semestre.

El diseño fue el siguiente:

- Se reclutaron **400 estudiantes** del mismo plan de estudios.
- Cada estudiante fue **asignado aleatoriamente** a uno de dos grupos:
  - `tratamiento` (200 estudiantes): recibió una dosis diaria de
    VitaEstudio durante todo el semestre.
  - `control` (200 estudiantes): recibió un placebo indistinguible de la
    vitamina.
- Ni el estudiante ni el profesor conocían la asignación (doble ciego).

Al terminar el semestre se construyó el archivo **`datos_rct_vitamina.xlsx`**,
que contiene las siguientes variables:

- `id_alumno`: identificador único del estudiante.
- `grupo`: `"tratamiento"` o `"control"`.
- `edad`: edad del estudiante al inicio del experimento (años).
- `horas_sueno`: horas promedio de sueño por noche durante el semestre.
- `calificacion_previa`: promedio del estudiante antes del experimento
  (escala 0 a 10).
- `calificacion_final`: promedio obtenido al final del semestre
  (escala 0 a 10). **Esta es la variable de resultado.**

---

### 1. Resumen numérico por grupo.

Para cada grupo (`tratamiento` y `control`) calcula:

- El **tamaño** del grupo (n),
- La **media** de `calificacion_final`,
- La **media** de `calificacion_previa`,
- La **desviación estándar** de `calificacion_final`,
- La **media** de `edad`,
- La **media** de `horas_sueno`.

> *Pista:* usa `group_by(grupo)` y `summarise()` del tidyverse.

### 2. Diferencia de medias y efecto del tratamiento.

a) Calcula la **diferencia de medias** de `calificacion_final` entre el
   grupo de tratamiento y el grupo de control. A este número se le conoce
   como **efecto promedio del tratamiento** (*Average Treatment Effect*,
   ATE).

b) Realiza una prueba **t de Student** (`t.test()`) para evaluar si la
   diferencia entre los grupos es estadísticamente significativa. Reporta
   el valor-p y el intervalo de confianza al 95%.

c) Responde con tus propias palabras:

   - ¿La vitamina VitaEstudio parece **mejorar** el rendimiento académico?
   - ¿Por qué es importante que los grupos sean **similares en edad,
     horas de sueño y calificación previa**? ¿Qué propiedad de los RCT
     garantiza esto?
   - Si en lugar de asignar los grupos aleatoriamente hubiéramos dejado
     que los estudiantes **eligieran** si tomar la vitamina o no, ¿qué
     problema de los vistos en clase podríamos tener?

### 3. Visualización.

Genera un **boxplot** (`geom_boxplot`) de `calificacion_final` separado por
`grupo`. Asigna un color distinto a cada grupo (sugerencia: azul para
control, naranja/rojo para tratamiento). Agrega título, subtítulo y
etiquetas en los ejes. Guarda la gráfica con `ggsave()` en la carpeta del
examen.

Opcionalmente, agrega con `geom_point()` o `geom_jitter()` los puntos
individuales sobre el boxplot para visualizar la dispersión.
