# Regresion Discontinua (Regression Discontinuity Design - RDD)

## 1. Que es la regresion discontinua

La **regresion discontinua** es un metodo de inferencia causal cuasi-experimental
que explota el hecho de que un tratamiento se asigna a partir de un **umbral
(cutoff)** en una variable continua llamada **variable de asignacion** (running
variable o forcing variable).

### Intuicion basica

Imaginemos que un programa de becas se otorga a todos los estudiantes con un
promedio **menor a 6.0**. Un estudiante con promedio de 5.99 recibe la beca,
mientras que uno con promedio de 6.01 no la recibe. Sin embargo, ambos
estudiantes son practicamente identicos en todas sus caracteristicas observables
y no observables. La unica diferencia relevante es que uno recibio el
tratamiento y el otro no.

Esta es la clave de la regresion discontinua: **justo alrededor del umbral, la
asignacion al tratamiento es casi aleatoria**, lo que nos permite estimar un
efecto causal local.

---

## 2. Sharp RDD vs. Fuzzy RDD

### Sharp RDD (nitida)

En el diseno **sharp**, el tratamiento se asigna de forma **determinista** segun
el umbral:

- Si `X >= c`: no recibe tratamiento
- Si `X < c`: recibe tratamiento

La probabilidad de tratamiento salta de 0 a 1 (o viceversa) exactamente en el
punto de corte. Esto es lo que veremos en el ejercicio practico.

### Fuzzy RDD (difusa)

En el diseno **fuzzy**, el umbral **no determina perfectamente** el tratamiento,
sino que cambia significativamente la **probabilidad** de recibirlo. Por ejemplo,
un programa de becas donde cruzar el umbral aumenta la probabilidad de recibir
beca del 20% al 80%, pero no de 0% a 100%.

En este caso, se estima el efecto usando **variables instrumentales**, donde
cruzar el umbral es el instrumento para el tratamiento efectivo.

---

## 3. Supuesto clave: continuidad en el umbral

El supuesto fundamental de la RDD es el de **continuidad**:

> En ausencia del tratamiento, la relacion entre la variable de asignacion y el
> resultado seria **continua** (suave) al pasar por el punto de corte.

Esto implica que:

1. **No hay manipulacion**: los individuos no pueden manipular su posicion
   respecto al umbral con precision suficiente para autoseleccionarse.
2. **Las caracteristicas observables son continuas en el umbral**: no hay saltos
   en covariables pre-tratamiento al cruzar el punto de corte.
3. **La densidad de la variable de asignacion es continua**: no hay
   acumulacion sospechosa de observaciones justo antes o despues del umbral.

### Como verificar el supuesto

- **Test de McCrary**: verifica que la densidad de la variable de asignacion
  no presenta un salto en el umbral.
- **Balance de covariables**: estimar RDD usando variables pre-tratamiento
  como resultado; no deberian mostrar saltos.

---

## 4. Formulacion matematica

### Efecto causal en el punto de corte

El parametro de interes es el **efecto local promedio del tratamiento (LATE)**
en el punto de corte `c`:

$$
\tau_{RDD} = \lim_{x \downarrow c} E[Y_i | X_i = x] - \lim_{x \uparrow c} E[Y_i | X_i = x]
$$

Es decir, la diferencia entre el limite por la derecha y el limite por la
izquierda de la esperanza condicional del resultado en el punto de corte.

### Estimacion parametrica

La forma mas sencilla de estimar el efecto es con una regresion lineal:

$$
Y_i = \alpha + \tau \cdot D_i + \beta_1 (X_i - c) + \beta_2 \cdot D_i \cdot (X_i - c) + \epsilon_i
$$

Donde:

- `Y_i` es el resultado de interes
- `X_i` es la variable de asignacion
- `c` es el punto de corte
- `D_i = 1` si `X_i >= c` (indicador de tratamiento)
- `tau` es el **efecto del tratamiento** (el coeficiente de interes)
- Los terminos de interaccion permiten que la pendiente sea diferente a cada
  lado del umbral

### Estimacion no parametrica

Se utilizan **regresiones locales (local polynomial regression)** que solo usan
observaciones dentro de una ventana (bandwidth) alrededor del punto de corte,
con funciones kernel que dan mas peso a las observaciones mas cercanas al umbral.

---

## 5. Seleccion del ancho de banda (bandwidth)

El **ancho de banda (bandwidth)** es un parametro crucial:

- **Muy estrecho**: pocas observaciones, alta varianza, pero menor sesgo.
- **Muy amplio**: muchas observaciones, baja varianza, pero mayor sesgo
  (la relacion lineal puede no ser buena aproximacion lejos del umbral).

### Criterios de seleccion

1. **Metodo de Imbens-Kalyanaraman (IK)**: seleccion optima que minimiza
   el error cuadratico medio.
2. **Metodo de Calonico-Cattaneo-Titiunik (CCT)**: extension del anterior
   con correcciones de sesgo robustas.
3. **Analisis de sensibilidad**: probar multiples anchos de banda y verificar
   que el resultado es robusto.

En la practica, **siempre se debe mostrar que el resultado es robusto a
diferentes anchos de banda**.

---

## 6. Cuando usar la regresion discontinua

### Escenarios ideales

- Programas sociales con elegibilidad basada en un puntaje (Progresa/Oportunidades)
- Regulaciones que aplican a partir de un umbral (tamano de empresa, edad)
- Elecciones: efecto de ganar por un margen estrecho
- Educacion: reglas de tamano de clase (Maimonides)

### Ventajas

1. **Alta validez interna**: cerca del umbral, es casi un experimento aleatorio.
2. **Transparencia**: el efecto es visible graficamente.
3. **Supuestos verificables**: la continuidad se puede testear empiricamente.
4. **No requiere datos panel**: se puede estimar con datos de corte transversal.

### Limitaciones

1. **Validez externa limitada**: el efecto estimado es **local**, solo valido
   para observaciones cercanas al punto de corte.
2. **Requiere una variable de asignacion continua**: no funciona si el
   tratamiento se asigna de forma discreta.
3. **Poder estadistico reducido**: al usar solo observaciones cerca del umbral,
   el tamano efectivo de la muestra se reduce.
4. **Sensible a la forma funcional**: si se elige mal el polinomio o el
   ancho de banda, el estimador puede ser sesgado.

---

## 7. Ejemplo clasico: Angrist y Lavy (1999)

### La Regla de Maimonides

El estudio de **Joshua Angrist y Victor Lavy (1999)**, publicado en el
*Quarterly Journal of Economics*, es uno de los ejemplos mas celebres de
regresion discontinua en economia de la educacion.

### Contexto

En Israel, la **Regla de Maimonides** establece que el tamano maximo de una
clase es de **40 alumnos**. Cuando la matricula de un grado en una escuela
supera los 40 estudiantes, el grado se divide en dos clases. Esto genera una
discontinuidad:

| Matricula | Numero de clases | Tamano promedio de clase |
|-----------|-----------------|------------------------|
| 39        | 1               | 39                     |
| 40        | 1               | 40                     |
| **41**    | **2**            | **~20.5**              |
| 42        | 2               | 21                     |

### Resultado principal

Angrist y Lavy encontraron que **reducir el tamano de clase mejora
significativamente el rendimiento academico de los estudiantes**, medido a
traves de puntajes en examenes estandarizados.

### Por que es un buen diseno RDD

- La variable de asignacion (matricula) es continua.
- El umbral (40 alumnos) es una regla institucional, no manipulable
  facilmente por las escuelas.
- Justo alrededor del umbral, las escuelas son comparables.

### Referencia completa

> Angrist, J. D., & Lavy, V. (1999). Using Maimonides' Rule to Estimate the
> Effect of Class Size on Scholastic Achievement. *The Quarterly Journal of
> Economics*, 114(2), 533-575.

---

## 8. Resumen visual del metodo

```
Resultado (Y)
    |
    |         o o o
    |       o o          <- Relacion Y vs X (arriba del corte)
    |     o o
    |   o o
    |  o        ^
    | o    SALTO |  tau  <- Efecto del tratamiento
    |  o        v
    |    o o
    |      o o           <- Relacion Y vs X (abajo del corte)
    |        o o o
    |________________
              c          <- Punto de corte (cutoff)
         Variable de asignacion (X)
```

El **salto (tau)** en el punto de corte `c` es el efecto causal estimado.

---

## 9. Lecturas recomendadas

- Angrist, J. D., & Pischke, J. S. (2009). *Mostly Harmless Econometrics*.
  Princeton University Press. Capitulo 6.
- Cattaneo, M. D., Idrobo, N., & Titiunik, R. (2020). *A Practical
  Introduction to Regression Discontinuity Designs*. Cambridge University Press.
- Lee, D. S., & Lemieux, T. (2010). Regression Discontinuity Designs in
  Economics. *Journal of Economic Literature*, 48(2), 281-355.
