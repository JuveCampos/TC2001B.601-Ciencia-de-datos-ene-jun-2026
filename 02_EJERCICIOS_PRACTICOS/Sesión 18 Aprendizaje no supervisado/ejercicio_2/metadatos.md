# Metadatos — Municipios por indicadores socioeconómicos (México)

## Nombre

Indicadores socioeconómicos municipales (`datos.csv`).

## Contexto / problema

Una secretaría de desarrollo social cuenta con 500 municipios descritos por
indicadores de pobreza, carencias sociales, ingreso, ruralidad, conectividad
y marginación. No existe una clasificación oficial previa que diga qué tipo
de municipio es cada uno. La pregunta es de política pública:
**¿podemos agrupar los municipios en perfiles socioeconómicos comparables**
para diseñar intervenciones diferenciadas (no la misma política para un
municipio urbano conectado que para uno rural marginado)? Queremos que los
grupos emerjan de los datos, sin imponer categorías de antemano.

## Tipo de problema

Clustering — aprendizaje **no supervisado**. No hay etiqueta de "tipo de
municipio" que predecir; buscamos segmentar a partir de la estructura de
los indicadores. Por lo tanto **no** hay partición entrenamiento/prueba.

## Variable objetivo

Ninguna — aprendizaje no supervisado. Todas las columnas (salvo el
identificador) son indicadores descriptivos; ninguna es una respuesta a
predecir.

## Tabla de variables

| Nombre | Tipo | Unidad | Rango aprox. | Descripción |
|---|---|---|---|---|
| clave_municipio | carácter | — (id) | MUN001 … MUN500 | **Identificador**; se elimina, no es indicador. |
| pct_pobreza | numérica | % | 1 – 99 | Porcentaje de población en pobreza. |
| pct_carencia_educativa | numérica | % | 0 – 100 | Rezago educativo. |
| pct_carencia_salud | numérica | % | 0 – 100 | Carencia de acceso a servicios de salud. |
| ingreso_promedio_mxn | numérica | MXN | ~5,000 – 40,000 | Ingreso mensual promedio. **Tiene NAs (~4%).** |
| pct_poblacion_rural | numérica | % | 0 – 100 | Porcentaje de población rural. |
| pct_acceso_internet | numérica | % | 0 – 100 | Hogares con acceso a internet. |
| densidad_pob_km2 | numérica | hab/km² | baja – muy alta | Densidad poblacional. |
| tasa_alfabetizacion | numérica | % | ~70 – 100 | Porcentaje de población alfabetizada. |
| grado_marginacion_idx | numérica | índice | continuo | Índice de marginación. **Colineal** (derivado de pobreza + carencia educativa). |

## Número de observaciones

500 municipios (filas) × 10 variables (9 indicadores numéricos + 1 id).

## Notas

- **Valores faltantes (NAs):** `ingreso_promedio_mxn` tiene 20 NAs (≈ 4%
  de los 500 municipios). Los algoritmos de distancia (k-means, jerárquico)
  y el PCA **no toleran NAs**, así que se imputan con la **mediana** vía
  `step_impute_median()`. Se prefiere la mediana a la media porque el
  ingreso es asimétrico (pocos municipios con ingresos muy altos arrastran
  la media).
- **Colinealidad:** `grado_marginacion_idx` es prácticamente una
  combinación de `pct_pobreza` y `pct_carencia_educativa`, por lo que está
  muy correlacionado con ellas. Esa redundancia refuerza el eje de
  marginación; el PCA la absorbe al construir componentes ortogonales. La
  dejamos y la comentamos en el script.
- **Escalas heterogéneas:** los porcentajes van de 0 a 100, el ingreso a
  decenas de miles de pesos y la densidad puede alcanzar valores muy
  grandes. Por eso es **indispensable normalizar (z-score) antes de PCA y
  clustering**: sin normalizar, `ingreso_promedio_mxn` y `densidad_pob_km2`
  (números grandes) dominarían las distancias y los grupos reflejarían solo
  las unidades, no el perfil socioeconómico. La normalización pone todos
  los indicadores en pie de igualdad.
- **Estructura latente:** el dataset fue construido con varios perfiles
  socioeconómicos subyacentes; el número de grupos y su interpretación los
  debe descubrir el alumno con el codo y la silueta.
