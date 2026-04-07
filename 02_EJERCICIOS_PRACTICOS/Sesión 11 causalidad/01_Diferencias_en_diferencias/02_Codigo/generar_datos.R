# ============================================================
# Generacion de datos sinteticos para Diferencias en Diferencias
# Inspirado en Card & Krueger (1994)
# ============================================================
# Este script genera datos ficticios que simulan el estudio
# clasico sobre el efecto del aumento del salario minimo en
# el empleo de restaurantes de comida rapida.
#
# - Grupo tratado: Nueva Jersey (aumento de salario minimo)
# - Grupo control: Pensilvania (sin cambio)
# - Periodos: antes y despues del aumento
# ============================================================

# Cargar librerias
library(tidyverse)

# Fijar semilla para reproducibilidad
set.seed(2)

# --- Parametros de la simulacion ---

n_restaurantes <- 200  # por estado (400 en total)

# Empleo promedio base (empleados equivalentes a tiempo completo)
empleo_base_nj <- 21.0  # NJ empieza ligeramente abajo
empleo_base_pa <- 23.0  # PA empieza ligeramente arriba

# Tendencia temporal comun (cambio que afecta a ambos estados)
tendencia_comun <- -1.5  # leve caida en empleo (recesion)

# Efecto causal del tratamiento (aumento salario minimo en NJ)
efecto_tratamiento <- 2.75  # efecto positivo en empleo

# Desviacion estandar del error
sd_error <- 5.0

# --- Generar datos ---

# Crear identificadores de restaurantes
datos_did <- tibble(
  restaurante_id = rep(1:(2 * n_restaurantes), each = 2),
  estado = rep(
    c(rep("Nueva Jersey", n_restaurantes),
      rep("Pensilvania", n_restaurantes)),
    each = 2
  ),
  periodo = rep(c("Antes", "Despues"), times = 2 * n_restaurantes)
)

# Agregar variables binarias y generar empleo
datos_did <- datos_did %>%
  mutate(
    # Variable de tratamiento (1 = Nueva Jersey)
    tratamiento = if_else(estado == "Nueva Jersey", 1, 0),
    # Variable de periodo (1 = despues del aumento)
    post = if_else(periodo == "Despues", 1, 0),
    # Interaccion tratamiento x post
    tratamiento_post = tratamiento * post,
    # Generar empleo usando el modelo DiD + ruido
    empleo = empleo_base_pa +
      (empleo_base_nj - empleo_base_pa) * tratamiento +
      tendencia_comun * post +
      efecto_tratamiento * tratamiento_post +
      rnorm(n(), mean = 0, sd = sd_error)
  ) %>%
  # Redondear empleo (no puede haber empleados fraccionarios)
  mutate(
    empleo = round(pmax(empleo, 1), 1)
  )

# Agregar variables adicionales para enriquecer el dataset
cadenas <- c(
  "Burger King", "KFC", "Wendys", "Roy Rogers"
)

datos_did <- datos_did %>%
  mutate(
    # Asignar cadena de restaurante aleatoriamente
    cadena = rep(
      sample(cadenas, 2 * n_restaurantes, replace = TRUE),
      each = 2
    ),
    # Salario minimo vigente
    salario_minimo = case_when(
      estado == "Pensilvania" ~ 4.25,
      estado == "Nueva Jersey" & post == 0 ~ 4.25,
      estado == "Nueva Jersey" & post == 1 ~ 5.05
    )
  ) %>%
  # Reordenar columnas
  select(
    restaurante_id, estado, cadena, periodo, tratamiento,
    post, tratamiento_post, salario_minimo, empleo
  )

# --- Verificacion rapida ---
# Mostrar medias por grupo y periodo
resumen <- datos_did %>%
  group_by(estado, periodo) %>%
  summarise(
    empleo_promedio = mean(empleo),
    n = n(),
    .groups = "drop"
  )

print("Resumen de medias por grupo y periodo:")
print(resumen)

# Calcular DiD manualmente
did_manual <- resumen %>%
  pivot_wider(
    names_from = periodo,
    values_from = empleo_promedio
  ) %>%
  mutate(diferencia = Despues - Antes)

print("Diferencia en diferencias manual:")
print(did_manual)

did_valor <- did_manual$diferencia[
  did_manual$estado == "Nueva Jersey"
] - did_manual$diferencia[
  did_manual$estado == "Pensilvania"
]
print(paste("Estimador DiD:", round(did_valor, 3)))

# --- Guardar datos ---
write_csv(
  datos_did,
  "01_Datos/datos_did.csv"
)

print("Datos guardados en '01_Datos/datos_did.csv'")
print(paste("Total de observaciones:", nrow(datos_did)))
print(paste(
  "Restaurantes unicos:",
  n_distinct(datos_did$restaurante_id)
))
