# Variables Instrumentales (IV)

## 1. Intuicion y motivacion

En muchos problemas de ciencias sociales y politica publica, queremos estimar el
efecto causal de una variable $X$ sobre un resultado $Y$. Por ejemplo: "cual es
el efecto de un anio adicional de educacion sobre los ingresos?".

El problema es que una regresion por Minimos Cuadrados Ordinarios (MCO/OLS) puede
darnos una respuesta **sesgada** si existe una variable omitida (como la habilidad
innata) que afecta tanto a $X$ como a $Y$. Esto se conoce como **sesgo por
variable omitida** o **endogeneidad**.

Las **variables instrumentales** son una estrategia para resolver este problema.
La idea central es encontrar una variable externa $Z$ (el "instrumento") que:

1. Afecte a $X$ (la variable endogena).
2. No afecte directamente a $Y$, excepto a traves de $X$.

De esta forma, podemos aislar la variacion "exogena" en $X$ y usarla para
estimar el efecto causal verdadero.

---

## 2. El problema: correlacion entre X y el termino de error

Consideremos el modelo estructural:

$$Y_i = \beta_0 + \beta_1 X_i + u_i$$

donde $u_i$ contiene factores no observados (como la habilidad). Si la habilidad
afecta tanto a la educacion ($X$) como a los ingresos ($Y$), entonces:

$$Cov(X_i, u_i) \neq 0$$

Esto viola el supuesto clave de MCO y produce un estimador sesgado e
inconsistente. El coeficiente $\hat{\beta}_1^{OLS}$ captura tanto el efecto
causal de $X$ como la correlacion espuria a traves de la variable omitida.

---

## 3. Que hace a un buen instrumento

Un instrumento $Z$ debe satisfacer dos condiciones:

### 3.1 Relevancia (primera condicion)

El instrumento debe estar correlacionado con la variable endogena:

$$Cov(Z_i, X_i) \neq 0$$

Esto es **verificable empiricamente**: se puede estimar la regresion de $X$
sobre $Z$ y comprobar que el coeficiente es significativo.

**Regla practica**: el estadistico F de la primera etapa debe ser mayor a 10
(Stock & Yogo, 2005). Si es menor, tenemos un problema de **instrumentos
debiles**.

### 3.2 Restriccion de exclusion (segunda condicion)

El instrumento no debe estar correlacionado con el termino de error:

$$Cov(Z_i, u_i) = 0$$

Es decir, $Z$ solo afecta a $Y$ **a traves de** $X$, no directamente. Esta
condicion **no es verificable empiricamente** de forma directa; debe
justificarse con argumentos teoricos y conocimiento del contexto.

---

## 4. Minimos Cuadrados en Dos Etapas (MC2E / 2SLS)

El procedimiento de estimacion mas comun con variables instrumentales es
**Minimos Cuadrados en Dos Etapas** (Two-Stage Least Squares, 2SLS):

### Primera etapa

Se regresa la variable endogena $X$ sobre el instrumento $Z$:

$$X_i = \pi_0 + \pi_1 Z_i + v_i$$

Se obtienen los valores ajustados $\hat{X}_i = \hat{\pi}_0 + \hat{\pi}_1 Z_i$.

### Segunda etapa

Se regresa el resultado $Y$ sobre los valores ajustados $\hat{X}_i$:

$$Y_i = \beta_0 + \beta_1 \hat{X}_i + \epsilon_i$$

El estimador $\hat{\beta}_1^{IV}$ es consistente para el efecto causal, siempre
que los supuestos del instrumento se cumplan.

**Nota importante**: los errores estandar de la segunda etapa manual no son
correctos porque no toman en cuenta que $\hat{X}$ es un valor estimado. Es
necesario usar software especializado (como `ivreg()`) que calcule los errores
estandar correctos.

---

## 5. Ecuaciones del modelo

### Ecuacion estructural (lo que queremos estimar)

$$Y_i = \beta_0 + \beta_1 X_i + u_i$$

### Primera etapa (relacion instrumento-variable endogena)

$$X_i = \pi_0 + \pi_1 Z_i + v_i$$

### Forma reducida (efecto total del instrumento sobre Y)

$$Y_i = \gamma_0 + \gamma_1 Z_i + \eta_i$$

La relacion entre estos parametros es:

$$\gamma_1 = \beta_1 \times \pi_1$$

Por lo tanto:

$$\beta_1^{IV} = \frac{\gamma_1}{\pi_1} = \frac{Cov(Z, Y)}{Cov(Z, X)}$$

Este es el estimador de Wald, que muestra la logica fundamental de IV: dividir
el efecto del instrumento sobre el resultado entre el efecto del instrumento
sobre la variable endogena.

---

## 6. Problema de instrumentos debiles

Cuando el instrumento esta solo debilmente correlacionado con $X$ (primera
etapa debil), surgen problemas graves:

- El estimador IV tiene **sesgo en muestras finitas** que puede ser peor que OLS.
- Los **intervalos de confianza** se distorsionan.
- Las **pruebas de hipotesis** pierden validez.

**Diagnostico**: calcular el estadistico F de la primera etapa. La regla de
Stock, Wright y Yogo (2002) sugiere F > 10 como umbral minimo.

---

## 7. Cuando usar variables instrumentales

### Situaciones apropiadas

- Existe **endogeneidad** por variables omitidas, simultaneidad o error de
  medicion.
- Se dispone de un instrumento con justificacion teorica solida.
- El instrumento es suficientemente fuerte (F > 10).

### Ventajas

- Permite obtener estimaciones **causales consistentes** cuando OLS esta sesgado.
- Framework teorico bien desarrollado con diagnosticos claros.
- Ampliamente utilizado y aceptado en economia y ciencias sociales.

### Limitaciones

- Encontrar un buen instrumento es **muy dificil** en la practica.
- La restriccion de exclusion no se puede verificar directamente.
- Con instrumentos debiles, el remedio puede ser peor que la enfermedad.
- Estima un **efecto local** (LATE), no necesariamente el efecto promedio.
- Requiere muestras relativamente grandes para ser confiable.

---

## 8. Ejemplo clasico: Angrist y Krueger (1991)

### Contexto

Joshua Angrist y Alan Krueger publicaron "Does Compulsory School Attendance
Affect Schooling and Earnings?" en el *Quarterly Journal of Economics* (1991).

### Pregunta de investigacion

Cual es el efecto causal de la educacion sobre los ingresos?

### El problema

Las personas con mas habilidad tienden a estudiar mas **y** a ganar mas.
Entonces, la correlacion observada entre educacion e ingresos sobreestima el
efecto causal de la educacion.

### El instrumento: trimestre de nacimiento

En Estados Unidos, las leyes de asistencia escolar obligatoria requieren que
los estudiantes permanezcan en la escuela hasta cumplir cierta edad (16 o 17
anios). Debido a las reglas de ingreso por fecha de corte:

- Los nacidos a **inicio de anio** (Q1) pueden abandonar la escuela antes
  porque alcanzan la edad legal de abandono con menos anios de educacion
  completados.
- Los nacidos a **finales de anio** (Q4) deben permanecer mas tiempo para
  alcanzar la edad legal.

### Por que funciona como instrumento

1. **Relevancia**: el trimestre de nacimiento afecta los anios de educacion a
   traves de las leyes de escolaridad obligatoria.
2. **Restriccion de exclusion**: el trimestre de nacimiento es esencialmente
   aleatorio y no deberia afectar los ingresos directamente (mas alla de su
   efecto a traves de la educacion).

### Resultado

El estimador IV mostro un efecto positivo y significativo de la educacion sobre
los ingresos, con una magnitud similar pero ligeramente mayor que OLS en algunos
casos.

---

## 9. Referencias

- Angrist, J. D., & Krueger, A. B. (1991). Does Compulsory School Attendance
  Affect Schooling and Earnings? *Quarterly Journal of Economics*, 106(4),
  979-1014.
- Stock, J. H., & Yogo, M. (2005). Testing for Weak Instruments in Linear IV
  Regression. En D. W. K. Andrews & J. H. Stock (Eds.), *Identification and
  Inference for Econometric Models*.
- Angrist, J. D., & Pischke, J. S. (2009). *Mostly Harmless Econometrics*.
  Princeton University Press.
