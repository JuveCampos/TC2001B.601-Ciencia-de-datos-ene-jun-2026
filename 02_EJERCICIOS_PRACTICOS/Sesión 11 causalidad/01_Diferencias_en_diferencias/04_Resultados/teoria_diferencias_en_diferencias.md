# Diferencias en Diferencias (DiD)

## Introduccion

El metodo de **Diferencias en Diferencias** (DiD, por sus siglas en ingles
*Difference-in-Differences*) es una de las tecnicas mas utilizadas en
econometria y ciencias sociales para estimar **efectos causales** de
politicas publicas, intervenciones o tratamientos.

La idea central es sencilla: si queremos saber el efecto de un programa o
politica, comparamos el **cambio** en el grupo que recibio el tratamiento
con el **cambio** en un grupo similar que no lo recibio. Al tomar la
diferencia de las diferencias, eliminamos factores que afectan a ambos
grupos por igual.

---

## Intuicion

Imaginemos que el estado de Nueva Jersey incrementa el salario minimo y
queremos saber si esto afecto el empleo en restaurantes de comida rapida.
Pensilvania, un estado vecino que no cambio su salario minimo, sirve como
grupo de comparacion.

- **Primera diferencia**: el cambio en empleo en Nueva Jersey
  (despues - antes del aumento).
- **Segunda diferencia**: el cambio en empleo en Pensilvania
  (despues - antes, sin aumento).
- **DiD**: restamos la segunda diferencia de la primera. Esto elimina
  cualquier tendencia comun (como una recesion economica) que haya
  afectado a ambos estados por igual.

```
DiD = (Y_NJ_post - Y_NJ_pre) - (Y_PA_post - Y_PA_pre)
```

Si ambos estados hubieran seguido la misma tendencia sin la intervencion,
la diferencia resultante es el **efecto causal** del aumento de salario
minimo.

---

## El supuesto de tendencias paralelas

El supuesto fundamental de DiD es el de **tendencias paralelas**
(*parallel trends assumption*):

> En ausencia del tratamiento, el grupo tratado y el grupo de control
> habrian seguido la misma tendencia a lo largo del tiempo.

Esto **no** significa que los dos grupos tengan el mismo nivel de la
variable de resultado (pueden empezar en niveles distintos). Lo que
importa es que el **cambio** en el tiempo habria sido el mismo para
ambos grupos si no hubiera ocurrido la intervencion.

### Como evaluar este supuesto

- Graficar las tendencias de ambos grupos en periodos **previos** al
  tratamiento. Si las lineas son aproximadamente paralelas antes de la
  intervencion, es razonable asumir que habrian seguido siendo
  paralelas despues.
- Realizar pruebas formales de pre-tendencias (*pre-trends tests*).

**Importante**: este supuesto no se puede probar directamente porque
se refiere a un contrafactual (lo que habria pasado). Solo podemos
buscar evidencia que lo respalde o lo contradiga.

---

## Formulacion matematica

El modelo de regresion de DiD se expresa como:

```
Y_it = beta_0 + beta_1 * Tratamiento_i + beta_2 * Post_t
       + beta_3 * (Tratamiento_i x Post_t) + epsilon_it
```

Donde:

| Termino | Significado |
|---------|-------------|
| `Y_it` | Variable de resultado para la unidad *i* en el periodo *t* |
| `Tratamiento_i` | Variable binaria: 1 si pertenece al grupo tratado, 0 si es control |
| `Post_t` | Variable binaria: 1 si es el periodo posterior al tratamiento, 0 si es anterior |
| `Tratamiento_i x Post_t` | Interaccion entre tratamiento y periodo |
| `beta_0` | Media del grupo control en el periodo pre-tratamiento |
| `beta_1` | Diferencia entre grupos **antes** del tratamiento |
| `beta_2` | Cambio en el tiempo para el grupo **control** |
| **`beta_3`** | **El efecto causal del tratamiento (el estimador DiD)** |
| `epsilon_it` | Termino de error |

### Interpretacion de los coeficientes

Para entender los coeficientes, veamos las medias predichas:

| | Pre (Post=0) | Post (Post=1) | Diferencia |
|---|---|---|---|
| **Control** (Trat=0) | beta_0 | beta_0 + beta_2 | beta_2 |
| **Tratado** (Trat=1) | beta_0 + beta_1 | beta_0 + beta_1 + beta_2 + beta_3 | beta_2 + beta_3 |
| **Diferencia** | beta_1 | beta_1 + beta_3 | **beta_3** |

El coeficiente **beta_3** captura exactamente la "diferencia de las
diferencias": el cambio adicional que experimento el grupo tratado mas
alla de lo que cambio el grupo de control.

---

## Cuando usar Diferencias en Diferencias

### Situaciones apropiadas

- Hay un **tratamiento o politica** que se aplica a un grupo pero no
  a otro.
- Se tienen datos de **antes y despues** del tratamiento para ambos
  grupos.
- Es razonable asumir **tendencias paralelas** entre los grupos.
- La asignacion al tratamiento no depende de la tendencia futura de
  la variable de resultado.

### Ventajas

1. **Controla por diferencias fijas entre grupos**: no importa si el
   grupo tratado y el control difieren en nivel, mientras las
   tendencias sean paralelas.
2. **Controla por tendencias temporales comunes**: factores que
   afectan a todos por igual (como la inflacion o una recesion) se
   cancelan.
3. **Intuitivo y facil de comunicar**: la logica de "doble diferencia"
   es accesible para audiencias no tecnicas.
4. **Implementacion sencilla**: se estima con una regresion lineal
   estandar.

### Limitaciones

1. **Dependencia del supuesto de tendencias paralelas**: si este
   supuesto no se cumple, el estimador esta sesgado.
2. **No controla por shocks diferenciales**: eventos que afectan
   de manera distinta a tratados y controles en el mismo periodo
   pueden sesgar los resultados.
3. **Posibles problemas de inferencia**: errores estandar pueden estar
   subestimados si no se ajusta por correlacion serial o por
   agrupamiento (*clustering*).
4. **Efectos de composicion**: si la composicion de los grupos cambia
   con el tiempo, los resultados pueden ser enganiosos.

---

## El estudio clasico: Card y Krueger (1994)

El ejemplo mas iconico de DiD en economia es el estudio de **David Card
y Alan Krueger (1994)**: *"Minimum Wages and Employment: A Case Study
of the Fast-Food Industry in New Jersey and Pennsylvania"*.

### Contexto

- En abril de 1992, Nueva Jersey aumento su salario minimo de $4.25
  a $5.05 por hora.
- Pensilvania mantuvo el salario minimo federal de $4.25.
- Los autores encuestaron a 410 restaurantes de comida rapida
  (Burger King, KFC, Wendy's, Roy Rogers) en ambos estados, antes
  y despues del aumento.

### Resultado principal

Contrario a la prediccion de la teoria economica clasica (que un
aumento en el salario minimo reduciria el empleo), Card y Krueger
encontraron que el empleo en restaurantes de comida rapida en Nueva
Jersey **no disminuyo** e incluso **aumento ligeramente** respecto
a Pensilvania.

### Importancia

Este estudio revoluciono la forma de pensar sobre los efectos del
salario minimo y demostro el poder del metodo DiD como herramienta
para la inferencia causal en politica publica. Hasta la fecha, es
uno de los articulos mas citados en economia laboral.

### Referencia completa

> Card, D., & Krueger, A. B. (1994). Minimum Wages and Employment:
> A Case Study of the Fast-Food Industry in New Jersey and Pennsylvania.
> *The American Economic Review*, 84(4), 772-793.

---

## Resumen

| Concepto | Descripcion |
|----------|-------------|
| **Que es DiD** | Metodo que compara cambios entre un grupo tratado y uno de control |
| **Supuesto clave** | Tendencias paralelas en ausencia del tratamiento |
| **Estimador** | beta_3 en la regresion con interaccion Tratamiento x Post |
| **Fortaleza** | Controla por diferencias fijas y tendencias comunes |
| **Debilidad** | Depende fuertemente del supuesto de tendencias paralelas |
| **Ejemplo clasico** | Card y Krueger (1994) - salario minimo en NJ vs PA |
