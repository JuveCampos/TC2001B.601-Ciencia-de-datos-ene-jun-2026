# Control Sintetico

## Introduccion

El metodo de control sintetico es una tecnica de inferencia causal disenada
para evaluar el efecto de una intervencion o politica cuando solo existe
**una unidad tratada** (o muy pocas). Fue popularizado por Alberto Abadie,
Alexis Diamond y Jens Hainmueller en su influyente estudio de 2010 sobre
el efecto de la Proposicion 99 en California (una legislacion de control
del tabaco).

La pregunta fundamental es: *"Que habria pasado con la unidad tratada si
no hubiera recibido el tratamiento?"* Como no podemos observar ese
contrafactual directamente, el metodo de control sintetico lo **construye**
a partir de una combinacion ponderada de unidades no tratadas.

---

## Intuicion del metodo

Imaginemos que California implemento una ley anti-tabaco en 1989 y queremos
saber cuanto redujo el consumo de cigarrillos. No podemos simplemente
comparar California con un solo estado de control, porque ningun estado
individual es suficientemente parecido a California en todas las
dimensiones relevantes.

La idea clave es: **combinar varios estados de control con pesos
especificos para crear un "California sintetico"** que se parezca lo mas
posible al California real *antes* del tratamiento.

Por ejemplo, el California sintetico podria ser:
- 30% Utah
- 25% Nevada  
- 20% Colorado
- 15% Montana
- 10% Connecticut

Esta combinacion ponderada replica las tendencias y caracteristicas
de California en el periodo pre-tratamiento.

---

## Formalizacion

### Notacion

- Tenemos $J + 1$ unidades: la unidad 1 es la tratada, las unidades
  $2, ..., J+1$ forman el **pool de donantes** (controles potenciales).
- Observamos $T$ periodos: $T_0$ pre-tratamiento y $T - T_0$
  post-tratamiento.
- $Y_{it}$ es el resultado observado para la unidad $i$ en el periodo $t$.

### Objetivo

Encontrar un vector de pesos $W = (w_2, w_3, ..., w_{J+1})$ tal que:

1. $w_j \geq 0$ para todo $j$ (pesos no negativos)
2. $\sum_{j=2}^{J+1} w_j = 1$ (los pesos suman 1)
3. El **control sintetico** $\hat{Y}_{1t} = \sum_{j=2}^{J+1} w_j Y_{jt}$
   sea lo mas parecido posible a $Y_{1t}$ en el periodo pre-tratamiento.

### Optimizacion

Los pesos se eligen minimizando el **error cuadratico medio de prediccion
pre-tratamiento** (MSPE, por sus siglas en ingles):

$$
\min_W \sum_{t=1}^{T_0} \left( Y_{1t} - \sum_{j=2}^{J+1} w_j Y_{jt} \right)^2
$$

sujeto a las restricciones de no-negatividad y suma unitaria.

En la version original de Abadie et al., tambien se pueden incorporar
**covariables predictoras** (como PIB per capita, composicion demografica,
etc.) en la optimizacion, pero la version basica con solo la variable de
resultado ya es muy ilustrativa.

---

## Estimacion del efecto

Una vez obtenidos los pesos optimos, el efecto del tratamiento en cada
periodo post-tratamiento se estima como la **brecha** (gap) entre la
unidad tratada y su control sintetico:

$$
\hat{\alpha}_{1t} = Y_{1t} - \hat{Y}_{1t} \quad \text{para } t > T_0
$$

Si el tratamiento tuvo un efecto negativo (por ejemplo, reducir el
consumo), esperamos que $\hat{\alpha}_{1t} < 0$ en el periodo
post-tratamiento.

---

## Inferencia: pruebas de placebo

A diferencia de otros metodos, el control sintetico **no produce errores
estandar tradicionales**. En su lugar, la inferencia se basa en **pruebas
de placebo por permutacion**.

### Procedimiento

1. Aplicar el metodo de control sintetico a **cada unidad del pool de
   donantes**, como si cada una de ellas hubiera sido la unidad tratada.
2. Para cada placebo, calcular la brecha (gap) entre la unidad y su
   control sintetico.
3. Comparar la brecha de la unidad realmente tratada con la distribucion
   de brechas placebo.

### Valor p

El valor p se calcula como la fraccion de unidades placebo cuyo efecto
estimado es tan grande o mas grande (en valor absoluto) que el de la
unidad tratada:

$$
p = \frac{\text{Numero de placebos con } |\hat{\alpha}| \geq |\hat{\alpha}_{\text{tratada}}|}{J + 1}
$$

Si la brecha de la unidad tratada es mucho mas grande que las brechas
placebo, tenemos evidencia de que el efecto es genuino y no simplemente
un artefacto del metodo.

### Refinamiento: razon MSPE

Una practica comun es descartar placebos con mal ajuste pre-tratamiento
(alto MSPE pre-tratamiento) y calcular la razon:

$$
\text{Razon MSPE} = \frac{\text{MSPE post-tratamiento}}{\text{MSPE pre-tratamiento}}
$$

Una razon alta indica un gran cambio post-tratamiento relativo al ajuste
pre-tratamiento.

---

## Validacion: ajuste pre-tratamiento

La calidad del control sintetico se evalua examinando que tan bien replica
la trayectoria de la unidad tratada **antes** del tratamiento.

- Un **buen ajuste pre-tratamiento** (las lineas se superponen casi
  perfectamente antes de la intervencion) da credibilidad al
  contrafactual post-tratamiento.
- Un **mal ajuste pre-tratamiento** indica que la combinacion de controles
  no logra replicar la unidad tratada, y los resultados deben
  interpretarse con precaucion.

Regla practica: si el MSPE pre-tratamiento es grande, el control
sintetico no es confiable.

---

## Cuando usar control sintetico

### Situaciones ideales

- Hay **una sola unidad tratada** (un pais, un estado, una region).
- Existe un **pool de donantes** con unidades similares no tratadas.
- Hay suficientes **periodos pre-tratamiento** para evaluar el ajuste.
- El tratamiento ocurre en un **momento conocido y bien definido**.
- Los datos son de **panel** (mismas unidades observadas en multiples
  periodos).

### Ventajas

1. **Transparencia**: los pesos son observables y se pueden inspeccionar.
2. **No requiere un grupo de control perfecto**: construye uno optimo.
3. **Evita la extrapolacion**: los pesos son convexos (no negativos y
   suman 1), asi que el sintetico queda dentro del "casco convexo" de
   los donantes.
4. **Visualizacion intuitiva**: la grafica tratado vs. sintetico es
   facil de interpretar.
5. **Inferencia basada en datos**: las pruebas de placebo no dependen de
   supuestos distribucionales.

### Limitaciones

1. **No funciona bien con pocas unidades de control**: se necesita un
   pool de donantes suficientemente grande.
2. **Sensible a la eleccion del pool de donantes**: incluir unidades
   muy diferentes puede sesgar los resultados.
3. **Requiere buen ajuste pre-tratamiento**: si no se logra, el metodo
   pierde credibilidad.
4. **No maneja bien efectos de derrame (spillovers)**: asume que el
   tratamiento no afecta a las unidades de control.
5. **Peso 0 para muchos donantes**: tipicamente, pocos donantes reciben
   peso positivo, lo cual puede ser fragil.
6. **Inferencia limitada**: el valor p de las pruebas de placebo depende
   del numero de unidades, asi que con pocas unidades la resolucion del
   valor p es baja.

---

## Ejemplo clasico: Proposicion 99 de California

Abadie, Diamond y Hainmueller (2010) estudian el efecto de la
**Proposicion 99**, aprobada en California en 1988, que:

- Aumento el impuesto al cigarrillo en 25 centavos por paquete.
- Destino los fondos a programas de salud y anti-tabaco.

Usando datos de 1970 a 2000 para los 50 estados de EE.UU.:

- **Unidad tratada**: California
- **Pool de donantes**: los 38 estados que no implementaron legislacion
  anti-tabaco similar en el periodo de estudio.
- **Variable de resultado**: ventas per capita de paquetes de cigarrillos.
- **Periodo pre-tratamiento**: 1970-1988
- **Periodo post-tratamiento**: 1989-2000

El estudio encontro que las ventas de cigarrillos en California cayeron
significativamente por debajo de lo que predecia el control sintetico,
con un efecto que se ampliaba con el tiempo. Las pruebas de placebo
confirmaron que este efecto era estadisticamente significativo.

---

## Referencia principal

Abadie, A., Diamond, A., & Hainmueller, J. (2010). "Synthetic Control
Methods for Comparative Case Studies: Estimating the Effect of
California's Tobacco Control Program." *Journal of the American
Statistical Association*, 105(490), 493-505.

Otras referencias relevantes:

- Abadie, A., & Gardeazabal, J. (2003). "The Economic Costs of Conflict:
  A Case Study of the Basque Country." *American Economic Review*, 93(1),
  113-132. (Primera aplicacion del metodo.)
- Abadie, A. (2021). "Using Synthetic Controls: Feasibility, Data
  Requirements, and Methodological Aspects." *Journal of Economic
  Literature*, 59(2), 391-425. (Revision metodologica completa.)
