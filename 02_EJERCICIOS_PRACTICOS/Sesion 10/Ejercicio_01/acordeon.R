
library(tidyverse)
library(plotly)

# Cargue los datos que se encuentran en la carpeta del ejercicio 01 de la sesión 10. 
empleados <- read_csv("datos_empleados.csv")
summary(empleados)


# 1. Explore los datos. ¿Cuantas filas tienen? ¿Cuantos renglones? ¿Cuales son los nombres de las variables? ¿Cuales son numéricas? ¿Cuales son categóricas?
nrow(empleados)
names(empleados)

i = 1
for(i in 1:ncol(empleados)){
  print(class(pull(empleados, i)))
}

vector_tipos <- sapply(empleados, class)
sum(vector_tipos == "numeric")
sum(vector_tipos == "character")


# 2. Aplique a la tabla la función summary(). ¿Qué resultado le arroja? 
summary(empleados)

# 3. Obtenga la media sólo del ingreso mensual. 
mean(empleados$ingreso_mensual, na.rm = T)

# 4. Detecte las variables numéricas. Genere una tabla nueva con esas variables. Grafique su distribución usando geom_density y un arreglo de facetas. 
bd_plot <- tabla_solo_numeros <- empleados %>% 
  select(which(vector_tipos == "numeric"))


bd_plot %>% 
  pivot_longer(cols = 2:ncol(.)) %>% 
  ggplot(aes(x = value)) + 
  geom_density() + 
  facet_wrap(~name, scales = "free")


plt_2 <- bd_plot %>% 
  pivot_longer(cols = 2:ncol(.)) %>% 
  ggplot(aes(x = value)) + 
  geom_boxplot() + 
  facet_wrap(~name, scales = "free")

plt_2

ggplotly(plt_2)

# 
# cor(bd_plot$ingreso_mensual, bd_plot$gastos_mensual)
bd_plot %>% 
  na.omit() %>% 
  summarise(cor = cor(ingreso_mensual, gastos_mensual))

bd_plot %>% 
  filter(ingreso_mensual < 5e4) %>% 
  ggplot(aes(x = ingreso_mensual, y = gastos_mensual)) + 
  geom_point() + 
  geom_smooth(method = "lm")


# 7. Diagnostique el tipo de NAs que tiene cada una de las variables. ¿Qué hacer en cada caso? Si detecta algún caso de NAs tipo MCAR y MAR impute los valores faltantes. 

tabla_solo_numeros %>% 
  summary()

# NAS en: edad, ingreso_mensual y score_desempeño
bd_plot %>% 
  mutate(is.na.ingreso_mensual = ifelse(is.na(ingreso_mensual), 
                                        yes = "Tiene NA", 
                                        no = "Con dato")) %>% 
  group_by(is.na.ingreso_mensual) %>% 
  summarise(prom_edad = mean(edad, na.rm = T), 
            gastos_mensual = mean(gastos_mensual, na.rm = T), 
            score_desempeño = mean(score_desempeño, na.rm = T))

bd_plot %>% 
  mutate(is.na.score = ifelse(is.na(score_desempeño), 
                                        yes = "Tiene NA", 
                                        no = "Con dato")) %>% 
  group_by(is.na.score) %>% 
  summarise(prom_edad = mean(edad, na.rm = T), 
            gastos_mensual = mean(gastos_mensual, na.rm = T), 
            ingreso_mensual = mean(ingreso_mensual, na.rm = T)) 



library(tidyverse)
library(plotly)
library(mice)
library(naniar)

# =========================
# 7. Diagnóstico de NAs
# =========================

# Convierte variables de texto a factor para que mice las use como predictores
empleados2 <- empleados %>% 
  mutate(across(where(is.character), as.factor))

# Cuántos NA hay por variable
colSums(is.na(empleados2))

# Proporción de NA por variable
colMeans(is.na(empleados2))

# Visual general de faltantes
vis_miss(empleados2)

# Patrón de faltantes
md.pattern(empleados2)

# -------------------------
# Diagnóstico más formal:
# si la probabilidad de NA depende de variables observadas,
# NO parece MCAR y puede tratarse como MAR
# -------------------------

# NA en ingreso_mensual
mod_na_ingreso <- glm(
  is.na(ingreso_mensual) ~ edad + gastos_mensual + `score_desempeño` +
    `años_experiencia` + horas_extras_semana + num_dependientes +
    genero + region + nivel_educacion + departamento,
  data = empleados2,
  family = binomial()
)

summary(mod_na_ingreso)

# NA en score_desempeño
mod_na_score <- glm(
  is.na(`score_desempeño`) ~ edad + ingreso_mensual + gastos_mensual +
    `años_experiencia` + horas_extras_semana + num_dependientes +
    genero + region + nivel_educacion + departamento,
  data = empleados2,
  family = binomial()
)

summary(mod_na_score)

# NA en edad
mod_na_edad <- glm(
  is.na(edad) ~ ingreso_mensual + gastos_mensual + `score_desempeño` +
    `años_experiencia` + horas_extras_semana + num_dependientes +
    genero + region + nivel_educacion + departamento,
  data = empleados2,
  family = binomial()
)

summary(mod_na_edad)

# =========================
# Imputación múltiple con mice
# =========================

# Inicialización para editar métodos y matriz de predictores
ini <- mice(empleados2, maxit = 0, printFlag = FALSE)

metodos <- ini$method
pred <- ini$predictorMatrix

# No imputar id ni usarlo como predictor
metodos["id"] <- ""
pred["id", ] <- 0
pred[, "id"] <- 0

# Método de imputación:
# - edad: pmm
# - ingreso_mensual: pmm
# - score_desempeño: pmm
# Las demás variables sin NA pueden quedarse como están
metodos["edad"] <- "pmm"
metodos["ingreso_mensual"] <- "pmm"
metodos["score_desempeño"] <- "pmm"

# Ejecutar imputación múltiple
imp <- mice(
  empleados2,
  m = 5,               # 5 bases imputadas
  maxit = 20,          # iteraciones
  method = metodos,
  predictorMatrix = pred,
  seed = 123,
  printFlag = FALSE
)

# Resumen del proceso
imp

# Revisar valores imputados
imp$imp$edad
imp$imp$ingreso_mensual
imp$imp$score_desempeño

# Diagnósticos visuales
stripplot(imp, pch = 20, cex = 1.1)
densityplot(imp)

# Obtener una base completada (solo para explorar o guardar)
empleados_imputados <- complete(imp, 1)

summary(empleados_imputados)
colSums(is.na(empleados_imputados))

# =========================
# Comparación antes vs después
# =========================

summary(empleados[, c("edad", "ingreso_mensual", "gastos_mensual", "score_desempeño")])
summary(empleados_imputados[, c("edad", "ingreso_mensual", "gastos_mensual", "score_desempeño")])

# Comparar correlación antes y después
bd_plot_original <- empleados %>% 
  select(id, edad, ingreso_mensual, gastos_mensual, score_desempeño,
         `años_experiencia`, horas_extras_semana, num_dependientes)

bd_plot_imputado <- empleados_imputados %>% 
  select(id, edad, ingreso_mensual, gastos_mensual, score_desempeño,
         `años_experiencia`, horas_extras_semana, num_dependientes)

bd_plot_original %>% 
  na.omit() %>% 
  summarise(cor = cor(ingreso_mensual, gastos_mensual))

bd_plot_imputado %>% 
  summarise(cor = cor(ingreso_mensual, gastos_mensual))
