# Metadatos — Perfil químico de vinos

## Nombre

Perfil fisicoquímico de vinos (`datos.csv`).

## Contexto / problema

Un laboratorio enológico recibió 600 muestras de vino con sus mediciones
fisicoquímicas de rutina (acidez, azúcar, alcohol, compuestos de azufre,
etc.). Nadie etiquetó las muestras: no sabemos de antemano cuántos "tipos"
de vino hay ni a qué tipo pertenece cada muestra. La pregunta es
exploratoria: **¿existen perfiles químicos naturales que agrupen a las
muestras?** Queremos descubrir esa estructura latente sin imponer
categorías previas.

## Tipo de problema

Clustering — aprendizaje **no supervisado**. No hay etiquetas que predecir;
buscamos estructura (grupos) dentro de los datos. En consecuencia **no** se
hace partición entrenamiento/prueba: no hay un objetivo contra el cual medir
acierto.

## Variable objetivo

Ninguna — aprendizaje no supervisado. Todas las columnas son atributos
fisicoquímicos; ninguna es una respuesta a predecir.

## Tabla de variables

| Nombre | Tipo | Unidad | Rango aprox. | Descripción |
|---|---|---|---|---|
| acidez_fija | numérica | g/L (ác. tartárico) | 4 – 16 | Ácidos no volátiles; aportan estructura y frescura. |
| acidez_volatil | numérica | g/L (ác. acético) | 0.1 – 1.6 | Ácido acético; en exceso da aroma a vinagre. |
| acido_citrico | numérica | g/L | 0 – 1 | Aporta frescura; suele ser bajo. |
| azucar_residual | numérica | g/L | 0.5 – 16 | Azúcar que queda tras la fermentación. |
| cloruros | numérica | g/L | 0.01 – 0.2 | Contenido de sal. |
| dioxido_azufre_libre | numérica | mg/L | 1 – 70 | SO₂ libre; conservante antimicrobiano. |
| dioxido_azufre_total | numérica | mg/L | 6 – 290 | SO₂ total (libre + combinado). **Colineal** con el libre. |
| densidad | numérica | g/cm³ | 0.990 – 1.004 | Depende de azúcar y alcohol. |
| ph | numérica | (escala pH) | 2.7 – 4.0 | Acidez en escala logarítmica. |
| sulfatos | numérica | g/L | 0.3 – 2.0 | Aditivo que contribuye al SO₂. |
| alcohol | numérica | % vol | 8 – 15 | Grado alcohólico. |

## Número de observaciones

600 muestras (filas) × 11 variables (columnas). Todas numéricas.

## Notas

- **Valores faltantes (NAs):** no hay. Aun así, en el script se incluye
  `step_impute_median()` como buena práctica defensiva (no altera nada si
  no hay NAs).
- **Colinealidad:** `dioxido_azufre_total` y `dioxido_azufre_libre` están
  fuertemente correlacionados (total ≈ 3.1 × libre, porque el total
  contiene al libre). Esta redundancia infla el peso del "eje de azufre"
  en distancias y varianza; el PCA la absorbe de forma natural al
  proyectar sobre componentes ortogonales, por lo que aquí la dejamos y la
  comentamos en lugar de eliminarla.
- **Escalas heterogéneas:** las variables van desde valores menores a 1
  (cloruros, ácido cítrico) hasta cientos (dióxido de azufre total). Por
  eso es **indispensable normalizar (z-score) antes de PCA y clustering**:
  sin normalizar, las variables con números grandes dominarían tanto la
  varianza del PCA como las distancias del k-means/jerárquico, y el
  resultado reflejaría solo las unidades de medida, no la química real.
- **Estructura latente:** el dataset fue construido con varios perfiles
  químicos subyacentes; el número exacto de grupos lo debe descubrir el
  alumno con el método del codo y la silueta, no se da de antemano.
