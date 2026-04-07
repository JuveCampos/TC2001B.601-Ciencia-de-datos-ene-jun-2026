# Sesion 11 - Causalidad: Ejercicios Practicos

## Estructura del proyecto

Cinco carpetas con ejercicios independientes de metodos de inferencia causal, ordenadas de menor a mayor complejidad:

| Carpeta | Metodo | Paper iconico | Datos sinteticos |
|---------|--------|---------------|------------------|
| `01_Diferencias_en_diferencias` | DiD | Card & Krueger (1994) - Salario minimo NJ vs PA | 400 restaurantes, efecto +1.92 empleados |
| `02_Regresion_discontinua` | RDD | Angrist & Lavy (1999) - Regla de Maimonides | 500 escuelas, cutoff en 40, efecto +4.78 puntos |
| `03_Propensity_score_matching` | PSM | Dehejia & Wahba (1999) / LaLonde (1986) | 1000 individuos (~157 tratados), efecto +$1,800 |
| `04_Variables_instrumentales` | IV/2SLS | Angrist & Krueger (1991) - Trimestre nacimiento | 2000 individuos, efecto verdadero 0.08 |
| `05_Control_sintetico` | SCM | Abadie, Diamond & Hainmueller (2010) - Prop. 99 | 31 estados, 20 anios, efecto -32.6 paquetes |

## Contenido de cada carpeta

- `*.Rproj` - Proyecto RStudio
- `generar_datos.R` - Genera datos sinteticos (ejecutar primero, crea el CSV)
- `analisis_*.R` - Analisis completo con visualizaciones
- `teoria_*.md` - Documento teorico del metodo

## Flujo de ejecucion

1. Abrir el `.Rproj` en RStudio
2. Ejecutar `generar_datos.R` (genera el `.csv`)
3. Ejecutar el script de analisis (genera graficas `.png`)

## Dependencias de R

Paquetes requeridos (todos disponibles en el sistema):
- `tidyverse` (usado en todos)
- `lmtest` + `sandwich` (errores robustos en DiD e IV)
- `quadprog` (optimizacion cuadratica en Control Sintetico)

**No se usan** `MatchIt`, `ivreg`, ni `AER` - los metodos estan implementados manualmente con fines pedagogicos.

## Decisiones de diseno

- Matching en PSM implementado manualmente (nearest neighbor sin reemplazo) para no depender de `MatchIt`
- IV usa 2SLS manual con correccion de errores estandar, sin `ivreg`/`AER`
- Control sintetico usa `quadprog::solve.QP()` en vez del paquete `Synth`
- Todos los efectos son estadisticamente significativos por diseno
- Datos generados con `set.seed()` para reproducibilidad
- Comentarios y texto en espanol, estilo tidyverse
