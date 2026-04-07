# Propensity Score Matching (PSM)

## Emparejamiento por puntaje de propension

---

## 1. Que es el Propensity Score Matching

El **Propensity Score Matching (PSM)** es una tecnica estadistica que busca estimar el efecto causal de un tratamiento cuando no se dispone de un experimento aleatorizado. La idea central es sencilla: si no podemos asignar el tratamiento al azar, al menos podemos **construir grupos comparables** a partir de los datos observados.

### La intuicion

Imaginemos que queremos evaluar si un programa de capacitacion laboral mejora los ingresos de los participantes. El problema es que las personas que deciden participar en el programa probablemente son diferentes de quienes no participan: quiza tienen mas motivacion, menos ingresos previos o un perfil demografico distinto. Si simplemente comparamos los ingresos promedio de ambos grupos, la diferencia reflejara tanto el efecto del programa como las diferencias preexistentes.

El PSM resuelve esto creando **parejas** (o grupos) de individuos que son similares en sus caracteristicas observables, pero que difieren en si recibieron o no el tratamiento. De esta forma, la comparacion se realiza entre individuos "gemelos estadisticos".

---

## 2. El puntaje de propension (Propensity Score)

El **puntaje de propension** es la probabilidad de que un individuo reciba el tratamiento, dadas sus caracteristicas observables:

$$e(X) = P(T = 1 \mid X)$$

Donde:
- $T$ es la variable de tratamiento (1 = tratado, 0 = no tratado)
- $X$ es el vector de covariables observadas (edad, educacion, ingresos previos, etc.)

### Como se estima

Tipicamente se utiliza un modelo de **regresion logistica** donde la variable dependiente es el tratamiento y las independientes son las covariables:

```
logit(T) = beta_0 + beta_1 * edad + beta_2 * educacion + ... + beta_k * X_k
```

El resultado es un numero entre 0 y 1 para cada individuo, que resume toda la informacion de las covariables en una sola dimension.

### Por que es util

El teorema de Rosenbaum y Rubin (1983) demuestra que, si la asignacion al tratamiento es ignorable dado $X$, entonces tambien es ignorable dado $e(X)$. Esto reduce un problema multidimensional (emparejar en muchas covariables) a uno unidimensional (emparejar en un solo numero).

---

## 3. Algoritmos de emparejamiento

Una vez estimado el puntaje de propension, existen diferentes formas de emparejar a los individuos tratados con los no tratados:

### 3.1 Vecino mas cercano (Nearest Neighbor)

Para cada individuo tratado, se busca el individuo no tratado con el puntaje de propension mas similar. Es el metodo mas intuitivo y utilizado.

- **Con reemplazo**: un individuo del grupo de control puede ser emparejado con varios tratados.
- **Sin reemplazo**: cada individuo del control se usa solo una vez.

### 3.2 Caliper (radio de tolerancia)

Similar al vecino mas cercano, pero se impone un **limite maximo** a la distancia entre los puntajes. Si no hay un par dentro del radio de tolerancia (caliper), el individuo tratado se descarta. Esto evita emparejamientos de mala calidad.

Un caliper comun es 0.2 desviaciones estandar del logit del puntaje de propension (Rosenbaum y Rubin, 1985).

### 3.3 Kernel (nucleo)

En lugar de emparejar con un solo individuo, se calcula un **promedio ponderado** de todos los individuos del grupo de control, donde los pesos dependen de la cercania del puntaje de propension. Los individuos mas cercanos reciben mayor peso.

- **Ventaja**: utiliza toda la informacion del grupo de control.
- **Desventaja**: puede incluir individuos poco comparables si la funcion kernel tiene soporte amplio.

### Comparacion rapida

| Metodo | Sesgo | Varianza | Facilidad |
|--------|-------|----------|-----------|
| Vecino mas cercano | Medio | Alta | Alta |
| Caliper | Bajo | Media | Media |
| Kernel | Bajo | Baja | Baja |

---

## 4. Supuestos fundamentales

El PSM descansa sobre dos supuestos criticos:

### 4.1 Independencia condicional (CIA - Conditional Independence Assumption)

Tambien llamado **supuesto de seleccion en observables** o **ignorabilidad**:

> Condicional a las covariables observadas $X$, la asignacion al tratamiento es independiente de los resultados potenciales.

$$Y(0), Y(1) \perp T \mid X$$

En palabras simples: **no hay variables omitidas** que afecten simultaneamente la participacion en el programa y el resultado. Este supuesto no es comprobable empiricamente; debe argumentarse con base en el conocimiento del contexto.

### 4.2 Soporte comun (Common Support / Overlap)

Para cada valor del puntaje de propension, debe haber individuos tanto en el grupo de tratamiento como en el grupo de control:

$$0 < P(T = 1 \mid X) < 1$$

Esto significa que, para cualquier combinacion de caracteristicas, debe existir una probabilidad positiva de ser tratado y de no ser tratado. En la practica, se verifica graficamente que las distribuciones de los puntajes de propension se **traslapen** (overlap) entre ambos grupos.

Si hay regiones sin traslape, los individuos en esas regiones deben excluirse del analisis.

---

## 5. Verificacion del balance

Despues del emparejamiento, es fundamental verificar que las covariables estan **balanceadas** entre el grupo tratado y el grupo de control emparejado. Si el emparejamiento funciono bien, las diferencias en las covariables deben haber disminuido sustancialmente.

### Metricas comunes

- **Diferencia estandarizada de medias (Standardized Mean Difference, SMD)**: mide la diferencia en medias como proporcion de la desviacion estandar. Se considera buen balance si SMD < 0.1 (regla general).
- **Razon de varianzas**: la varianza de cada covariable deberia ser similar entre grupos tras el emparejamiento.
- **Pruebas t**: aunque se pueden usar, las diferencias estandarizadas son preferibles porque no dependen del tamano de muestra.

### Herramientas visuales

- **Love plot**: grafico que muestra las diferencias estandarizadas antes y despues del emparejamiento para cada covariable.
- **Graficos de densidad**: superponer las distribuciones de cada covariable por grupo, antes y despues.

---

## 6. Cuando usar PSM

### Situaciones apropiadas

- Estudios observacionales donde no fue posible aleatorizar el tratamiento.
- Cuando se dispone de un conjunto amplio de covariables que predicen la seleccion al tratamiento.
- Evaluaciones de politicas publicas, programas sociales y programas de salud.

### Ventajas

- **Intuitivo**: la idea de emparejar individuos similares es facil de comunicar.
- **No parametrico** en la etapa de estimacion del efecto (no requiere supuestos sobre la forma funcional de la relacion entre covariables y resultado).
- **Transparente**: el balance puede verificarse directamente.
- **Reduce dimension**: sintetiza muchas covariables en un solo puntaje.

### Limitaciones

- **Solo corrige por observables**: no puede eliminar el sesgo causado por variables no observadas (motivacion, habilidad innata, etc.).
- **Requiere buen soporte comun**: si los grupos son muy diferentes, habra pocas parejas validas.
- **Sensible a la especificacion del modelo**: un modelo logistico mal especificado produce puntajes incorrectos.
- **Pierde observaciones**: los individuos fuera del soporte comun se descartan.
- **No es un sustituto de la aleatorizacion**: sigue siendo un metodo observacional con supuestos fuertes.

---

## 7. Referencia clasica: Dehejia y Wahba (1999)

### Contexto

Uno de los estudios mas influyentes en la literatura del PSM es el de **Dehejia y Wahba (1999)**, quienes replicaron y extendieron el trabajo seminal de **LaLonde (1986)**.

### El estudio original de LaLonde (1986)

LaLonde evaluo el **National Supported Work (NSW) Demonstration**, un programa de capacitacion laboral en Estados Unidos dirigido a personas con dificultades para encontrar empleo (exconvictos, personas en asistencia social, etc.). LaLonde comparo los resultados del experimento aleatorizado con estimaciones obtenidas usando metodos observacionales (grupos de comparacion no experimentales). Su conclusion fue pesimista: los metodos observacionales no lograban replicar los resultados experimentales.

### La contribucion de Dehejia y Wahba

Dehejia y Wahba mostraron que, usando **Propensity Score Matching** con los mismos datos no experimentales, era posible obtener estimaciones **cercanas al resultado experimental**. Esto fue una reivindicacion importante para los metodos de emparejamiento.

- **Tratamiento**: participacion en el programa NSW de capacitacion laboral.
- **Resultado**: ingresos en 1978 (post-programa).
- **Covariables**: edad, educacion, raza, estado civil, ingresos en 1974 y 1975.
- **Efecto encontrado**: el programa incremento los ingresos en aproximadamente $1,800 dolares, consistente con la estimacion experimental.

### Leccion clave

El PSM, cuando se aplica cuidadosamente y con covariables relevantes, puede producir estimaciones causales creibles en contextos observacionales. Sin embargo, la calidad del resultado depende criticamente de la **calidad y completitud de las covariables** disponibles.

---

## 8. Referencias

- Dehejia, R. H., & Wahba, S. (1999). Causal effects in nonexperimental studies: Reevaluating the evaluation of training programs. *Journal of the American Statistical Association*, 94(448), 1053-1062.
- LaLonde, R. J. (1986). Evaluating the econometric evaluations of training programs with experimental data. *The American Economic Review*, 76(4), 604-620.
- Rosenbaum, P. R., & Rubin, D. B. (1983). The central role of the propensity score in observational studies for causal effects. *Biometrika*, 70(1), 41-55.
- Rosenbaum, P. R., & Rubin, D. B. (1985). Constructing a control group using multivariate matched sampling methods that incorporate the propensity score. *The American Statistician*, 39(1), 33-38.

---

## 9. Flujo de trabajo resumido

```
1. Definir tratamiento, resultado y covariables
           |
2. Estimar propensity score (regresion logistica)
           |
3. Verificar soporte comun (overlap)
           |
4. Realizar emparejamiento (nearest neighbor, caliper, etc.)
           |
5. Verificar balance de covariables
           |
6. Estimar efecto del tratamiento en muestra emparejada
           |
7. Analisis de sensibilidad
```
