# Metadatos — Apostadores en casas de apuestas en línea

## Nombre

Comportamiento de usuarios de apuestas en línea (`datos.csv`).

## Contexto / problema

Una casa de apuestas en línea cuenta con 700 usuarios descritos por su
comportamiento de juego: depósitos, montos apostados, frecuencia, horarios,
retiros, uso de bonos y señales de juego de riesgo. No existe una
clasificación previa que diga qué "tipo" de jugador es cada uno. La pregunta
es exploratoria y de negocio (y de juego responsable): **¿podemos agrupar a
los usuarios en perfiles de jugador comparables** para tratarlos de forma
diferenciada (no la misma estrategia para un jugador recreativo que para uno
de alto valor o para uno con señales de riesgo)? Queremos que los grupos
emerjan de los datos, sin imponer categorías de antemano.

## Tipo de problema

Clustering + PCA — aprendizaje **no supervisado**. No hay variable objetivo
("y") que predecir; buscamos descubrir estructura (grupos) y reducir
dimensionalidad para visualizarla. En consecuencia **no** se hace partición
entrenamiento/prueba: no hay un acierto contra el cual medir.

## Variable objetivo

Ninguna — aprendizaje no supervisado. Todas las columnas (salvo el
identificador) son atributos de comportamiento; ninguna es una respuesta a
predecir.

## Tabla de variables

| Nombre | Tipo | Unidad | Rango aprox. | Descripción |
|---|---|---|---|---|
| id_usuario | carácter | — (id) | US00001 … US00700 | **Identificador**; se elimina, no es atributo. |
| edad | numérica | años | 18 – 65 | Edad del usuario. |
| antiguedad_dias | numérica | días | 5 – 1,600 | Días desde el registro en la plataforma. |
| num_depositos_mes | numérica | conteo | 0 – 45 | Número de depósitos al mes. |
| monto_total_depositado_mxn | numérica | MXN | ~300 – 50,000 | Total depositado al mes. |
| monto_promedio_apuesta_mxn | numérica | MXN | ~15 – 1,600 | Apuesta promedio. **Tiene NAs (~4%).** |
| num_apuestas_mes | numérica | conteo | 2 – 540 | Número de apuestas al mes. |
| num_sesiones_mes | numérica | conteo | 2 – 70 | Sesiones de juego al mes. |
| duracion_sesion_min | numérica | minutos | 4 – 170 | Duración promedio de la sesión. |
| pct_apuestas_nocturnas | numérica | % | 0 – 100 | Porcentaje de apuestas hechas de noche (señal de riesgo). |
| num_juegos_distintos | numérica | conteo | 1 – 14 | Variedad de juegos usados. |
| pct_uso_bonos | numérica | % | 0 – 100 | Porcentaje de jugadas con bono/promoción. |
| indice_persecucion_perdidas | numérica | índice 0–1 | 0 – 1 | Tendencia a depositar tras perder ("chasing losses"); señal de riesgo. |
| monto_total_retirado_mxn | numérica | MXN | 0 – 33,000 | Total retirado al mes. |
| perdida_neta_mxn | numérica | MXN | negativo – ~24,000 | Pérdida neta = depositado − retirado. **Colineal** (derivada de las dos anteriores). |

## Número de observaciones

700 usuarios (filas) × 15 columnas (14 atributos numéricos + 1 id).

## Notas

- **Valores faltantes (NAs):** `monto_promedio_apuesta_mxn` tiene 28 NAs
  (≈ 4% de los 700 usuarios). Los algoritmos de distancia (k-means,
  jerárquico) y el PCA **no toleran NAs**, así que se imputan con la
  **mediana** vía `step_impute_median()`. Se prefiere la mediana a la media
  porque los montos son asimétricos (pocos usuarios VIP con apuestas muy
  altas arrastran la media).
- **Colinealidad:** `perdida_neta_mxn` se construye como
  `monto_total_depositado_mxn − monto_total_retirado_mxn`, por lo que está
  fuertemente correlacionada con ambas (≈ 0.89 con el depósito). Esa
  redundancia refuerza el eje de "dinero/intensidad"; el PCA la absorbe al
  construir componentes ortogonales. La dejamos y la comentamos en el script
  en lugar de eliminarla.
- **Escalas heterogéneas:** los conteos y porcentajes van de decenas a unos
  cuantos cientos, mientras que los montos en pesos llegan a decenas de
  miles. Por eso es **indispensable normalizar (z-score) antes de PCA y
  clustering**: sin normalizar, `monto_total_depositado_mxn` y
  `perdida_neta_mxn` (números grandes) dominarían la varianza y las
  distancias, y los grupos reflejarían solo las unidades (pesos), no el
  comportamiento de juego. La normalización pone todos los atributos en pie
  de igualdad.
- **Estructura latente:** el dataset fue construido con cuatro perfiles de
  jugador subyacentes (recreativo, VIP de alto valor, en riesgo / juego
  problemático, y cazador de bonos). El número de grupos lo debe descubrir
  el alumno con el **método del codo** (confirmado con la silueta), no se da
  de antemano.
