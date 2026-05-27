#------------------------------------------------------------------------------#
# Proyecto:             Informalidad Laboral MCV-OMX
# Objetivo:             Entender las características de las personas en informalidad
#                       laboral
# 
# Encargadas:           Axel Eduardo González Gómez
#.                      Jorge Juvenal Campos Ferreira
# Correos:              axel@mexicocomovamos.mx, juvenal@mexicocomovamos.mx        
# 
# Fecha de creación:   13/mayo/2024       
# Última actualización:       
#------------------------------------------------------------------------------#

# Fuente: ENOE
# Microdatos de la ENOE: https://www.inegi.org.mx/programas/enoe/15ymas/#Microdatos
# Documentación ENOE:    https://www.inegi.org.mx/contenidos/programas/enoe/15ymas/doc/enoe_123_fd_c_bas_amp.pdf

# 0. Configuración inicial -----------------------------------------------------
Sys.setlocale("LC_TIME", "es_ES")

# Cargar paquetería 
library(pacman) 
p_load(tidyverse, hot.deck, zoo, stringi, scales, srvyr, openxlsx, VIM, foreign, presupuestoR, ggh4x)

# Funciones propias: 
# ----- Colores MCV 
mcv_discrete <- c("#6950D8", "#3CEAFA", "#00B783", "#FF6260", "#FFAF84", "#FFBD41")
mcv_semaforo <- c("#00b783", "#E8D92E", "#ffbd41", "#ff6260")
mcv_blacks   <- c("black"  , "#D2D0CD", "#777777")
mcv_morados  <- c("#6950D8", "#A99BE9")
mcv_infobite    <- c("#6950D8","#0095C5", "#00BA88","#007E71", "#5898D6", "#598F2F","#245D81","#DF6852")

deflactar_inpc <- function (monto, 
                            #año del monto proporcionado
                            year_monto,
                            #año al que se quiere llevar el monto
                            year_out,
                            #trimestre al que quieres deflactar
                            trimestre = c(1, 1)){
  # Descarga del INPC de la página de BANXICO: 
  if (!exists("inpc_bd") || !(c("fecha") %in% colnames(inpc_bd)) || 
      !(c("mes") %in% colnames(inpc_bd)) || !(c("year") %in% 
                                              colnames(inpc_bd)) || !(c("inpc") %in% colnames(inpc_bd))) {
    temp <- tempfile(fileext = ".xls")
    # Descargamos datos de Banxico de precios: 
    inpc_ur <- "http://www.banxico.org.mx/SieInternet/consultasieiqy?series=SP1&locale=en"
    utils::download.file(inpc_ur, destfile = temp, mode = "wb")
    rlang::env_unlock(as.environment("package:presupuestoR"))
    assign("inpc_bd", XML::htmlParse(temp) %>% XML::getNodeSet("//table") %>% 
             .[[6]] %>% XML::readHTMLTable() %>% dplyr::tibble() %>% 
             janitor::clean_names() %>% tidyr::separate(date, 
                                                        c("mes", "year")) %>% dplyr::transmute(fecha = paste0(mes, 
                                                                                                              "/", year), mes = as.numeric(mes), year = as.numeric(year), 
                                                                                               inpc = as.numeric(sp1)), envir = as.environment("package:presupuestoR"))
    rlang::env_lock(as.environment("package:presupuestoR"))
  }
  
  trimestre_dato1 <- as.numeric(trimestre[1])
  trimestre_dato2 <- as.numeric(trimestre[2])
  
  #indice_1 periodo con datos nominales 
  #indice_2 - periodo base -- con precios del año que quieres 
  
  indice_1 = inpc_bd %>%
    filter(year %in% c(year_monto)) %>% 
    {
      if(trimestre_dato1 == 1){
        filter(., mes %in% 1:3)
      } else if(trimestre_dato1 == 2){
        filter(., mes %in% 4:6)
      } else if(trimestre_dato1 == 3){
        filter(., mes %in% 7:9)
      } else if(trimestre_dato1 == 4){
        filter(., mes %in% 10:12)
      }
    } %>% 
    pull(inpc) %>% 
    mean()
  
  indice_2 = inpc_bd %>%
    filter(year %in% c(year_out)) %>% 
    {
      if(trimestre_dato2 == 1){
        filter(., mes %in% 1:3)
      } else if(trimestre_dato2 == 2){
        filter(., mes %in% 4:6)
      } else if(trimestre_dato2 == 3){
        filter(., mes %in% 7:9)
      } else if(trimestre_dato2 == 4){
        filter(., mes %in% 10:12)
      }
    } %>% 
    pull(inpc) %>% 
    mean()
  
  monto_deflactado <- (monto * indice_2)/indice_1
  return(monto_deflactado)
}

# 1. Cargar datos --------------------------------------------------------------

# CAMBIAR A LA CARPETA LOCAL DONDE SE TENGAN GUARDADOS LOS MICRODATOS EN FORMATO DBF: 
directorio <- "/Volumes/Extreme\ SSD/DATASETS/INEGI\ -\ ENOE/dbf"
# directorio <- "/Users/jorgejuvenalcamposferreira/Downloads/enoe_2024_trim1_dbf"
# directorio <- "/Users/axel/Documents/MCV/ENOE/enoe_2025_trim3_dbf"
# Carpeta donde se guardan los datos procesados: (Carpeta en blanco si se va a procesar info): 
datos_limpios <- "02_datos_limpios/rds"
# Carpeta para guardar los bites de las bases de datos para hacer las gráficas (carpeta en blanco si es primera vez): 
datos_graficas <- "02_datos_limpios/rds"
# Carpeta para guardar los infobites
graficas <- "04_infobites"

# Años entre los cuales se va a correr el código de procesamiento 
anio_inicio = 2005
anio_final = 2025

archivos <- tibble(
  file = list.files(directorio, full.names = T, recursive = T, pattern = "dbf|DBF"),
  year = str_extract(file, pattern = "\\d\\d\\d\\d"), 
  trim = str_extract(file, pattern = "trim\\d") %>% 
    str_extract(pattern = "\\d"), 
  tipo = case_when(str_detect(str_to_lower(file), pattern = "coe1") ~ "Cuestionario 1", 
                   str_detect(str_to_lower(file), pattern = "coe2") ~ "Cuestionario 2", 
                   str_detect(str_to_lower(file), pattern = "sdem") ~ "Sociodemográfico", 
                   str_detect(str_to_lower(file), pattern = "viv") ~ "Viviendas",
                   str_detect(str_to_lower(file), pattern = "hog") ~ "Hogares")) %>% 
  filter(between(as.numeric(year), anio_inicio, anio_final))
archivos

# 2. Procesar datos ------------------------------------------------------------

# #* Pruebas: ****************************************
# Estos argumentos no afectan el código subsecuente, solo son para probar la función
year_sel <- 2025
trim_sel <- 2
# #*****************************************

# En el tercer trimestre de 2025 el INEGI cambió el nombre de la variable
# ent por cve_ent, el código funcina a partir de dicho periodo (por el cambio),
# para generar enoes previas se tendría que cambiar nuevamente de cve_ent a ent

gen_datos <- function(year_sel, trim_sel){

  # Helper compartido por los tres bloques: normaliza el nombre de la
  # columna de entidad federativa. INEGI ha alternado entre `CVE_ENT`
  # y `ENT` según la edición. Después de `rename_all(tolower)` esta
  # función deja siempre `cve_ent`, que es el nombre que el resto del
  # script (paste0 de la llave, joins, vars_a_escoger, hotdeck) espera.
  normalizar_cve_ent <- function(df) {
    if ("ent" %in% names(df) & !"cve_ent" %in% names(df)) {
      df <- df %>% rename(cve_ent = ent)
    }
    df
  }

  # ==========================================================================
  # BLOQUE 1: Procesamiento para 3T2025 en adelante ----
  # ==========================================================================
  # Nota: A partir del 3T2025, INEGI cambió nombres de columnas. 
  # Cambios conocidos: cve_ent -> ent
  
  if(year_sel > 2025 | (year_sel == 2025 & trim_sel >= 3)){
    
    # *** inicio de la función *** #
    dir <- archivos %>% 
      filter(year == year_sel & trim == trim_sel & tipo == "Cuestionario 1") %>% 
      pull(file)
    
    df_coe1 <- read.dbf(dir, as.is = T)
    
    # --- Corrección de nombres de columnas nuevas ---
    # TODO: Agregar aquí cualquier rename adicional que se descubra en pruebas
    if("CVE_ENT" %in% names(df_coe1)){
      df_coe1 <- df_coe1 %>% rename(ENT = CVE_ENT)
    }
    # Renombrar ent -> cve_ent para mantener compatibilidad interna
    if("ENT" %in% names(df_coe1) & !"CVE_ENT" %in% names(df_coe1)){
      df_coe1 <- df_coe1 %>% rename(CVE_ENT = ENT)
    }
    
    df_coe1 <- df_coe1 %>% 
      rename_all(tolower) %>% 
      mutate(llave = paste0(cd_a, cve_ent, con, v_sel, tipo, mes_cal, n_hog, h_mud, n_ren)) %>% 
      mutate_at(vars(-starts_with("llave")), as.numeric)
    
    # Tabla de cuestionario de ocupación y empleo II
    dir <- archivos %>% 
      filter(year == year_sel & trim == trim_sel & tipo == "Cuestionario 2") %>% 
      pull(file)
    
    df_coe2 <- read.dbf(dir, as.is = T)  
    if("CVE_ENT" %in% names(df_coe2)){
      df_coe2 <- df_coe2 %>% rename(ENT = CVE_ENT)
    }
    
    if("ENT" %in% names(df_coe2) & !"CVE_ENT" %in% names(df_coe2)){
      df_coe2 <- df_coe2 %>% rename(CVE_ENT = ENT)
    }
    
    df_coe2 <- df_coe2 %>% 
      rename_all(tolower) %>% 
      mutate(
        llave = paste0(
          cd_a, cve_ent, con, v_sel, tipo, mes_cal, n_hog, h_mud, n_ren
        )
      ) %>% 
      mutate_at(vars(-starts_with("llave")), as.numeric)
    
    # Tabla de sociodemográfico 
    dir <- archivos %>% 
      filter(year == year_sel & trim == trim_sel & tipo == "Sociodemográfico") %>% 
      pull(file)
    
    df_sdem <- read.dbf(dir, as.is = T) 
    if("CVE_ENT" %in% names(df_sdem)){
      df_sdem <- df_sdem %>% rename(ENT = CVE_ENT)
    }
    if("ENT" %in% names(df_sdem) & !"CVE_ENT" %in% names(df_sdem)){
      df_sdem <- df_sdem %>% rename(CVE_ENT = ENT)
    }
    
    # --- Manejo flexible de columnas que pueden no existir ---
    # En 3T2025 se quitaron CS_P21_DES y CS_P23_DES; verificar si siguen ausentes
    cols_a_quitar_sdem <- intersect(names(df_sdem), c("CS_P21_DES", "CS_P23_DES"))
    if(length(cols_a_quitar_sdem) > 0){
      df_sdem <- df_sdem %>% select(-all_of(cols_a_quitar_sdem))
    }
    
    df_sdem <- df_sdem %>% 
      rename_all(tolower) %>% 
      mutate(
        llaveh = paste0(
          cd_a, cve_ent, con, v_sel, tipo, mes_cal, n_hog, h_mud
        ),
        llave = paste0(
          cd_a, cve_ent, con, v_sel, tipo, mes_cal, n_hog, h_mud, n_ren
        )
      ) %>% 
      mutate_at(
        # TODO: Verificar si cs_p21_des sigue existiendo en los datos nuevos después del rename
        vars(-c(starts_with("llave"), r_def, c_res, 
                any_of("cs_p21_des"))),
        as.numeric
      ) %>% 
      filter(as.character(r_def) == "00" & (as.character(c_res) == "1" | as.character(c_res) == "3")) 
    
    # sort(unique(df_sdem$cve_ent))
    
    # --- Unión de bases ---
    # Nota: se conservan upm, est_d_tri, fac_tri como variables de diseño
    # muestral. fac_tri se duplica en `fac` (alias) por compatibilidad con
    # el flujo histórico que termina renombrando `fac` -> `factor`.
    # r_def y c_res NO se conservan: el filtro de residencia ya se aplicó
    # arriba sobre df_sdem, así que en este punto serían constantes.
    # Mantenerlas además causa problemas si COE1/COE2 traen una columna
    # con el mismo nombre (queda r_def.x/.y que el select por sufijos elimina).
    df_tempo <- df_sdem %>%
      rename(t_loc = t_loc_tri) %>%
      mutate(fac = fac_tri) %>%
      select(-c(
        con, d_sem, n_pro_viv, v_sel, fac_men, h_mud, n_ent, per, n_ren, ur
      )) %>%
      left_join(df_coe1 %>% select(-c(fac_tri, fac_men, cve_ent)), by = c("llave")) %>%
      left_join(df_coe2 %>%
                  select(-c(fac_tri, fac_men, cve_ent)), by = c("llave")) %>%
      select(-c(ends_with(".y"), ends_with(".x"))) %>%
      mutate(trimestre = trim_sel)
    
    # --- Procesamiento de variables derivadas ---
    df_tempo = df_tempo |> 
      mutate(
        # 01. Sexo: 
        sexo = ifelse(sex == 1, "Hombre", "Mujer"),
        # 02. Años de escolaridad: 
        anios_esc = ifelse(anios_esc == 99, NA, anios_esc),
        # 03. Tipo de localidad
        tamanio_localidad = case_when(t_loc == 1 ~ "Mayores a 100,000 habitantes", 
                                      t_loc == 2 ~ "Entre 15,000 a 99,999 habitantes", 
                                      t_loc == 3 ~ "Entre 2,500 a 14,999 habitantes", 
                                      t_loc == 4 ~ "Menores de 2,500 habitantes") %>% 
          factor(levels = c("Mayores a 100,000 habitantes",
                            "Entre 15,000 a 99,999 habitantes",
                            "Entre 2,500 a 14,999 habitantes",
                            "Menores de 2,500 habitantes")),
        tamanio_localidad_2 = ifelse(t_loc == 4, yes = "Rural", no = "Urbana"),
        # 04. Edad
        edad = eda,
        grupo_edad = case_when(
          eda12c == 1 ~ "De 15 a 19 años",
          eda12c == 2 ~ "De 20 a 24 años",
          eda12c == 3 ~ "De 25 a 29 años",
          eda12c == 4 ~ "De 30 a 34 años",
          eda12c == 5 ~ "De 35 a 39 años",
          eda12c == 6 ~ "De 40 a 44 años",
          eda12c == 7 ~ "De 45 a 49 años",
          eda12c == 8 ~ "De 50 a 54 años",
          eda12c == 9 ~ "De 55 a 59 años",
          eda12c == 10 ~ "De 60 a 64 años",
          eda12c == 11 ~ "De 65 años y más",
          eda12c == 12 ~ "No especificado"
        ) %>% 
          factor(levels = c("De 15 a 19 años", "De 20 a 24 años", "De 25 a 29 años",
                            "De 30 a 34 años", "De 35 a 39 años", "De 40 a 44 años",
                            "De 45 a 49 años", "De 50 a 54 años", "De 55 a 59 años",
                            "De 60 a 64 años", "De 65 años y más", "No especificado")),
        # 05. Analfabetismo:
        analfabetismo = case_when(cs_p12 == 1 ~ "Sabe leer y escribir un recado", 
                                  cs_p12 == 2 ~ "No sabe leer y escribir un recado", 
                                  cs_p12 == 9 ~ NA) %>% 
          factor(levels = c("Sabe leer y escribir un recado", "No sabe leer y escribir un recado")),
        # 06. Numero de hijos:
        no_hijos = n_hij, 
        no_hijos_cat = case_when(n_hij == 0 ~ "Ningún hijo", 
                                 n_hij == 1 ~ "1 hijo",
                                 n_hij == 2 ~ "2 hijos",
                                 n_hij == 3 ~ "3 hijos",
                                 between(n_hij, 4, 5) ~ "Entre 4 y 5 hijos", 
                                 between(n_hij, 6, 10) ~ "Entre 6 y 10 hijos", 
                                 between(n_hij, 11, 25) ~ "Más de 10 hijos", 
                                 n_hij == 99 ~ "No especificado") %>% 
          factor(levels = c("Ningún hijo", "1 hijo", "2 hijos", "3 hijos", 
                            "Entre 4 y 5 hijos", "Entre 6 y 10 hijos", 
                            "Más de 10 hijos", "No especificado")),
        # 07. Estado marital: 
        estado_conyugal = case_when(e_con == 1 ~ "Vive con su pareja en unión libre",
                                    e_con == 2 ~ "Está separado(a)",
                                    e_con == 3 ~ "Está divorciado(a)",
                                    e_con == 4 ~ "Está viudo(a)",
                                    e_con == 5 ~ "Está casado(a)",
                                    e_con == 6 ~ "Está soltero(a)",
                                    e_con == 9 ~ NA) %>% 
          factor(levels = c("Vive con su pareja en unión libre", "Está separado(a)",
                            "Está divorciado(a)", "Está viudo(a)",
                            "Está casado(a)", "Está soltero(a)")),
        # 10. Duración jornada:
        duracion_jornada = case_when(dur9c == 1 ~ "Ausentes temporales con vínculo laboral", 
                                     dur9c == 2 ~ "Menos de 15 horas", 
                                     dur9c == 3 ~ "De 15 a 24 horas", 
                                     dur9c == 4 ~ "De 25 a 34 horas", 
                                     dur9c == 5 ~ "De 35 a 39 horas", 
                                     dur9c == 6 ~ "De 40 a 48 horas", 
                                     dur9c == 7 ~ "De 49 a 56 horas", 
                                     dur9c == 8 ~ "Más de 56 horas", 
                                     dur9c == 9 ~ "No especificado") %>% 
          factor(levels = c("Ausentes temporales con vínculo laboral", "Menos de 15 horas",
                            "De 15 a 24 horas", "De 25 a 34 horas", "De 35 a 39 horas",
                            "De 40 a 48 horas", "De 49 a 56 horas", "Más de 56 horas",
                            "No especificado")),
        horas_ocupadas = hrsocup,
        # 11. Tamaño unidad económica:
        tamanio_empresa = case_when(ambito2 %in% c(2, 3) ~ "Micronegocios", 
                                    ambito2 == 4 ~ "Pequeños establecimientos", 
                                    ambito2 == 5 ~ "Medianos establecimientos", 
                                    ambito2 == 6 ~ "Grandes establecimientos", 
                                    ambito2 == 7 ~ "Gobierno", 
                                    ambito2 == 8 ~ "Otros") %>% 
          factor(levels = c("Micronegocios", "Pequeños establecimientos",
                            "Medianos establecimientos", "Grandes establecimientos",
                            "Gobierno", "Otros")),
        tamanio_empresa_2 = case_when(ambito2 %in% c(2, 3, 4, 5) ~ "MIPyMES", 
                                      ambito2 == 6 ~ "Grandes establecimientos", 
                                      TRUE ~ NA) %>% 
          factor(levels = c("MIPyMES", "Grandes establecimientos")),
        # 12.0 Sector de la economía: 
        sector_economico = case_when(rama_est1 == 1 ~ "Sector primario",
                                     rama_est1 == 2 ~ "Sector secundario",
                                     rama_est1 == 3 ~ "Sector terciario",
                                     rama_est1 == 4 ~ NA) %>% 
          factor(levels = c("Sector primario", "Sector secundario", "Sector terciario")),
        # 12. Sector SCIAN:
        scian = case_when(scian == 1 ~ "Agricultura, ganadería, aprovechamiento forestal, pesca y caza", 
                          scian == 2 ~ "Minería", 
                          scian == 3 ~ "Generación y distribución de electricidad, suministro de agua y gas", 
                          scian == 4 ~ "Construcción", 
                          scian == 5 ~ "Industrias manufactureras", 
                          scian == 6 ~ "Comercio al por mayor", 
                          scian == 7 ~ "Comercio al por menor", 
                          scian == 8 ~ "Transportes, correos y almacenamiento", 
                          scian == 9 ~ "Información en medios masivos", 
                          scian == 10 ~ "Servicios financieros y de seguros", 
                          scian == 11 ~ "Servicios inmobiliarios de alquiler de bienes", 
                          scian == 12 ~ "Servicios profesionales, científicos y técnicos", 
                          scian == 13 ~ "Corporativos", 
                          scian == 14 ~ "Servicios de apoyo a los negocios y manejo de desechos", 
                          scian == 15 ~ "Servicios educativos", 
                          scian == 16 ~ "Servicios de salud y de asistencia social", 
                          scian == 17 ~ "Servicios de esparcimiento culturales y deportivos", 
                          scian == 18 ~ "Servicios de hospedaje y preparación de alimentos y bebidas", 
                          scian == 19 ~ "Otros servicios, excepto actividades gubernamentales", 
                          scian == 20 ~ "Actividades gubernamentales y de organismos internacionales", 
                          scian == 21 ~ "No especificado") %>%
          factor(levels = c("Agricultura, ganadería, aprovechamiento forestal, pesca y caza",
                            "Minería", 
                            "Generación y distribución de electricidad, suministro de agua y gas", 
                            "Construcción", "Industrias manufactureras",
                            "Comercio al por mayor", "Comercio al por menor",
                            "Transportes, correos y almacenamiento",
                            "Información en medios masivos", 
                            "Servicios financieros y de seguros",
                            "Servicios inmobiliarios de alquiler de bienes",
                            "Servicios profesionales, científicos y técnicos", 
                            "Corporativos",
                            "Servicios de apoyo a los negocios y manejo de desechos",
                            "Servicios educativos",
                            "Servicios de salud y de asistencia social",
                            "Servicios de esparcimiento culturales y deportivos",
                            "Servicios de hospedaje y preparación de alimentos y bebidas", 
                            "Otros servicios, excepto actividades gubernamentales",
                            "Actividades gubernamentales y de organismos internacionales",
                            "No especificado")),
        # 13. Trabajo en gobierno:
        empresas_gubernamentales = case_when(tue3 == 0 ~ NA,
                                             tue3 == 1 ~ "Administradas por los gobiernos",
                                             tue3 == 2 ~ "No administradas por los Gobiernos"),
        # 14. Subocupados:
        subocu = ifelse(sub_o == 1, "Subocupado", "No subocupado") %>% 
          factor(levels = c("Subocupado", "No subocupado")),
        # 15. Contrato:
        tipo_contratacion = case_when(tip_con == 1 ~ "Con contrato escrito", 
                                      tip_con == 2 ~ "Temporal", 
                                      tip_con == 3 ~ "De base, planta o por tiempo definido", 
                                      tip_con == 4 ~ "Contrato de tipo no especificado", 
                                      tip_con == 5 ~ "Sin contrato escrito", 
                                      tip_con == 6 ~ "No especificado") %>% 
          factor(levels = c("Con contrato escrito", "Temporal",
                            "De base, planta o por tiempo definido",
                            "Contrato de tipo no especificado",
                            "Sin contrato escrito", "No especificado")),
        # 16. Apoyos económicos:
        recibe_apoyos = case_when(p14apoyos == 1 ~ "Sí recibe apoyos económicos",
                                  p14apoyos == 2 ~ "No recibe apoyos económicos",
                                  p14apoyos == 3 ~ NA),
        # 17. Tipo de unidad económica empleadora:
        sector_informalidad = case_when(mh_fil2 == 1 ~ "Sector informal",
                                        mh_fil2 == 2 ~ "Trabajo doméstico remunerado",
                                        mh_fil2 == 3 ~ "Empresas, gobierno e instituciones",
                                        mh_fil2 == 4 ~ "Ámbito agropecuario") %>% 
          factor(levels = c("Sector informal", "Trabajo doméstico remunerado",
                            "Empresas, gobierno e instituciones", "Ámbito agropecuario")),
        # 18. Seguridad Social: 
        seguridad_social = case_when(seg_soc == 1 ~ "Con acceso a Seguridad Social", 
                                     seg_soc == 2 ~ "Sin acceso a Seguridad Social", 
                                     TRUE ~ NA),
        # Ingreso salario mínimo:
        ingreso_sm = case_when(
          (is.na(p6b2) & (p6_9 == 9 | p6a3 == 3)) ~ 0,
          is.na(p6b2) & p6c == 1 ~ salario * 0.5,
          is.na(p6b2) & p6c == 2 ~ salario * 1,
          is.na(p6b2) & p6c == 3 ~ salario * 1.5,
          is.na(p6b2) & p6c == 4 ~ salario * 2.5,
          is.na(p6b2) & p6c == 5 ~ salario * 4,
          is.na(p6b2) & p6c == 6 ~ salario * 7.5,
          is.na(p6b2) & p6c == 7 ~ (salario * 10) + 1,
          T ~ p6b2
        ),
        ingreso = ifelse(ingocup == 0, NA, ingocup),
        edu = case_when(
          anios_esc < 6 ~ "Primaria incompleta",
          anios_esc >= 6 & anios_esc < 9 ~ "Primaria completa",
          anios_esc >= 9 & anios_esc < 12 ~ "Secundaria completa",
          anios_esc >= 12 & anios_esc < 15 ~ "Preparatoria completa",
          anios_esc >= 15 ~ "Universidad o más",
          T ~ NA_character_
        ),
        sector = case_when(
          rama_est2 == 1 ~ "Agricultura, ganadería, silvicultura, caza y pesca",
          rama_est2 == 2 ~ "Industria extractiva y de la electricidad",
          rama_est2 == 3 ~ "Industria manufacturera",
          rama_est2 == 4 ~ "Construcción",
          rama_est2 == 5 ~ "Comercio",
          rama_est2 == 6 ~ "Restaurantes y serviciosde alojamiento",
          rama_est2 == 7 ~ "Transportes, comunicaciones, correo y almacenamiento",
          rama_est2 == 8 ~ "Servicios profesionales, financieros y corporativos",
          rama_est2 == 9 ~ "Servicios sociales",
          rama_est2 == 10 ~ "Servicios diversos",
          rama_est2 == 11 ~ "Gobierno y organismos internacionales",
          T ~ NA_character_
        ),
        tipo_formalidad = case_when(
          emp_ppal == 1 ~ "Empleo informal",
          emp_ppal == 2 ~ "Empleo formal",
          T ~ NA_character_
        ),
        jornada_completa = case_when(
          dur_est == 4 | dur_est == 5 ~ "Jornada de tiempo completo",
          dur_est <= 3 ~ "Jornada de medio tiempo",
          T ~ NA_character_
        ), 
        tipo_educacion = case_when(
          cs_p13_1 == "00" | cs_p13_1 == 0 ~ "Ninguna",
          cs_p13_1 == "01" | cs_p13_1 == 1 ~ "Preescolar",
          cs_p13_1 == "02" | cs_p13_1 == 2 ~ "Primaria",
          cs_p13_1 == "03" | cs_p13_1 == 3 ~ "Secundaria",
          cs_p13_1 == "04" | cs_p13_1 == 4 ~ "Preparatoria o bachillerato",
          cs_p13_1 == "05" | cs_p13_1 == 5 ~ "Normal",
          cs_p13_1 == "06" | cs_p13_1 == 6 ~ "Carrera técnica",
          cs_p13_1 == "07" | cs_p13_1 == 7 ~ "Profesional",
          cs_p13_1 == "08" | cs_p13_1 == 8 ~ "Maestría",
          cs_p13_1 == "09" | cs_p13_1 == 9 ~ "Doctorado",
          cs_p13_1 == "99" | cs_p13_1 == 10 ~ "No sabe")) %>% 
      rename(sinco = p3, factor = fac)
    
    # --- 08. Migración ---
    df_tempo = df_tempo %>% 
      mutate(
        donde_vivia_hace_un_año = case_when(cs_p20a_1 == 1 ~ "Aquí en este estado",
                                            cs_p20a_1 == 2 ~ "En otro estado",
                                            cs_p20a_1 == 3 ~ "En los Estados Unidos de América",
                                            cs_p20a_1 == 4 ~ "En otro país", 
                                            TRUE ~ NA) %>%
          factor(levels = c("Aquí en este estado", "En otro estado",
                            "En los Estados Unidos de América", "En otro país")))
    
    # --- Variables de selección ---
    set.seed(20230216)
    vars_a_escoger <- c("llaveh", "llave", "ingreso", "ingreso_sm", "sex", "par_c",
                        "eda12c", "eda", "e_con", "edu", "pos_ocu", "tipo_formalidad", "sector",
                        "jornada_completa", "t_loc", "cve_ent", "anios_esc",
                        "tipo_educacion", "grupo_edad",
                        "clase1", "clase2", "cve_ent",
                        "sinco", "hrsocup", "p4a", "factor",
                        "pos_ocu", "c_inac5c",
                        "p3a", "p3d", "t_tra", "hrsocup",
                        "sexo", "anios_esc", "tamanio_localidad", "grupo_edad", "horas_ocupadas",
                        "analfabetismo", "no_hijos", "no_hijos_cat", "estado_conyugal",
                        "duracion_jornada",
                        "tamanio_empresa", "sector_economico", "scian",
                        "salario",
                        "empresas_gubernamentales", "subocu", "tipo_contratacion",
                        "recibe_apoyos", "sector_informalidad", "seguridad_social", "sector", "cd_a",
                        # Variables de diseño muestral y crudas para análisis
                        # a nivel ciudad autorrepresentada (script 102 y posteriores).
                        "upm", "est_d_tri", "fac_tri",
                        "ingocup", "sub_o",
                        "donde_vivia_hace_un_año")
    
    # --- Horas de trabajo no remunerado ---
    if(trim_sel == 1){
      df_tempo = df_tempo %>%
        mutate(p11_h2 = ifelse(p11_h2 > 97, NA, p11_h2),
               horas_semana_cuidados = p11_h2 + (p11_m2 / 60),
               p11_h7 = ifelse(p11_h7 > 97, NA, p11_h7),
               horas_semana_quehaceres = p11_h7 + (p11_m7 / 60),
               horas_semana_quehaceres_cuidados = horas_semana_cuidados + horas_semana_quehaceres)
      vars_a_escoger <- append(vars_a_escoger, c("horas_semana_quehaceres", "horas_semana_quehaceres_cuidados"))
    } else {
      df_tempo = df_tempo %>%
        mutate(p11_h2 = ifelse(p9_h2 > 97, NA, p9_h2),
               horas_semana_cuidados = p9_h2 + (p9_m2 / 60),
               p9_h7 = ifelse(p9_h7 > 97, NA, p9_h7),
               horas_semana_quehaceres = p9_h7 + (p9_m7 / 60),
               horas_semana_quehaceres_cuidados = horas_semana_cuidados + horas_semana_quehaceres)
      vars_a_escoger <- append(vars_a_escoger, c("horas_semana_quehaceres", "horas_semana_quehaceres_cuidados"))
    }
    
    # --- Hot Deck Imputation ---
    df_tempo_hotdeck <- df_tempo %>% 
      filter(eda >= 15) %>% 
      filter(pos_ocu < 4 & clase1 == 1 & clase2 == 1) %>% 
      select_at(vars_a_escoger) |> 
      VIM::hotdeck(
        variable = c("ingreso_sm"),
        domain_var = c("sex", "eda12c", "e_con",
                       "edu", "pos_ocu", "tipo_formalidad",
                       "sector", "jornada_completa", "t_loc", "cve_ent")
      ) |>
      mutate(
        periodo = paste0(year_sel, "T", trim_sel),
        año = paste0(year_sel),
        trimestre = trim_sel
      )
    
    df_tempo_no_hotdeck <- df_tempo %>% 
      mutate(bandera = ifelse((eda >= 15 & pos_ocu < 4 & clase1 == 1 & clase2 == 1), 
                              yes = T, no = F)) %>% 
      filter(bandera == F) %>% 
      select(-bandera) %>% 
      select_at(vars_a_escoger) %>% 
      mutate(
        periodo = paste0(year_sel, "T", trim_sel),
        año = paste0(year_sel),
        trimestre = trim_sel, 
        ingreso_sm_imp = NA
      ) %>% 
      select(names(df_tempo_hotdeck))
    
    df_tempo_final <- rbind(df_tempo_hotdeck, df_tempo_no_hotdeck)
    
    df_tempo_final$ent <- df_tempo_final$cve_ent
    df_tempo_final$cve_ent <- NULL
    
    
  } # Fin del Bloque 1 (3T2025+)
  
  # ==========================================================================
  # BLOQUE 2: Procesamiento de 3T2020 a 2T2025 ----
  # ==========================================================================
  # (Antes era el bloque para >= 3T2020, ahora acotado hasta 2T2025)
  
  if((year_sel >= 2021 | (year_sel >= 2020 & trim_sel >= 3)) & 
     (year_sel < 2025 | (year_sel == 2025 & trim_sel <= 2))){
    
    # *** inicio de la función *** #
    dir <- archivos %>% 
      filter(year == year_sel & trim == trim_sel & tipo == "Cuestionario 1") %>% 
      pull(file)
    
    # Nota: BLOQUE 2 conserva `cve_ent` como nombre canónico (no swap a
    # `ent` al final). El helper `normalizar_cve_ent` viene definido al
    # inicio de gen_datos y se aplica tras tolower a coe1, coe2 y sdem.

    df_coe1 <- read.dbf(dir, as.is = T) %>%
      as_tibble() %>%
      rename_all(tolower) %>%
      normalizar_cve_ent() %>%
      mutate(llave = paste0(cd_a, cve_ent, con, v_sel, tipo, mes_cal, n_hog, h_mud, n_ren)) %>%
      mutate_at(vars(-starts_with("llave")), as.numeric)

    # Tabla de cuestionario de ocupación y empleo II
    dir <- archivos %>%
      filter(year == year_sel & trim == trim_sel & tipo == "Cuestionario 2") %>%
      pull(file)

    df_coe2 <- read.dbf(dir, as.is = T) %>%
      rename_all(tolower) %>%
      normalizar_cve_ent() %>%
      mutate(
        llave = paste0(
          cd_a, cve_ent, con, v_sel, tipo, mes_cal, n_hog, h_mud, n_ren
        )
      ) %>%
      mutate_at(vars(-starts_with("llave")), as.numeric)

    # Tabla de sociodemográfico
    dir <- archivos %>%
      filter(year == year_sel & trim == trim_sel & tipo == "Sociodemográfico") %>%
      pull(file)
    df_sdem <- read.dbf(dir, as.is = T) %>%
      rename_all(tolower) %>%
      normalizar_cve_ent() %>%
      mutate(
        llaveh = paste0(
          cd_a, cve_ent, con, v_sel, tipo, mes_cal, n_hog, h_mud
        ),
        llave = paste0(
          cd_a, cve_ent, con, v_sel, tipo, mes_cal, n_hog, h_mud, n_ren
        )
      ) %>%
      mutate_at(
        vars(-c(starts_with("llave"), r_def, c_res, any_of(c("cs_p21_des", "cs_p23_des")))),
        as.numeric
      ) %>%
      filter(as.character(r_def) == "00" & (as.character(c_res) == "1" | as.character(c_res) == "3"))
    
    # Nota: se conservan upm, est_d_tri, fac_tri como variables de diseño
    # muestral. fac_tri se duplica en `fac` (alias) por compatibilidad con
    # el flujo histórico que termina renombrando `fac` -> `factor`.
    # r_def y c_res NO se conservan: el filtro de residencia ya se aplicó
    # arriba sobre df_sdem, así que en este punto serían constantes.
    # Mantenerlas además causa problemas si COE1/COE2 traen una columna
    # con el mismo nombre (queda r_def.x/.y que el select por sufijos elimina).
    df_tempo <- df_sdem                                                         %>%
      rename(t_loc = t_loc_tri)                                               %>%
      mutate(fac = fac_tri)                                                   %>%
      select(-c(
        con,
        d_sem,
        n_pro_viv,
        v_sel,
        fac_men,
        h_mud,
        n_ent, per, n_ren, ur))                                 %>%
      left_join(df_coe1 %>% select(-c(fac_tri, fac_men, cve_ent)), by = c("llave")) %>%
      left_join(df_coe2 %>% select(-c(fac_tri, fac_men, cve_ent)), by = c("llave")) %>%
      select(-c(ends_with(".y"),ends_with(".x"))) %>%
      mutate(trimestre = trim_sel)
    
    df_tempo
    
    df_tempo = df_tempo |> 
      mutate(
        sexo = ifelse(sex == 1, "Hombre", "Mujer"),
        anios_esc = ifelse(anios_esc==99,NA,anios_esc),
        tamanio_localidad = case_when(t_loc == 1 ~ "Mayores a 100,000 habitantes", 
                                      t_loc == 2 ~ "Entre 15,000 a 99,999 habitantes", 
                                      t_loc == 3 ~ "Entre 2,500 a 14,999 habitantes", 
                                      t_loc == 4 ~ "Menores de 2,500 habitantes") %>% 
          factor(levels = c("Mayores a 100,000 habitantes",
                            "Entre 15,000 a 99,999 habitantes",
                            "Entre 2,500 a 14,999 habitantes",
                            "Menores de 2,500 habitantes")),
        tamanio_localidad_2 = ifelse(t_loc == 4, yes = "Rural", no = "Urbana"),
        edad = eda,
        grupo_edad = case_when(
          eda12c == 1 ~ "De 15 a 19 años",
          eda12c == 2 ~  "De 20 a 24 años",
          eda12c == 3 ~  "De 25 a 29 años",
          eda12c == 4 ~  "De 30 a 34 años",
          eda12c == 5 ~  "De 35 a 39 años",
          eda12c == 6 ~  "De 40 a 44 años",
          eda12c == 7 ~  "De 45 a 49 años",
          eda12c == 8 ~  "De 50 a 54 años",
          eda12c == 9 ~  "De 55 a 59 años",
          eda12c == 10 ~  "De 60 a 64 años",
          eda12c == 11 ~  "De 65 años y más",
          eda12c == 12 ~  "No especificado"
        ) %>% 
          factor(levels = c("De 15 a 19 años",
                            "De 20 a 24 años",
                            "De 25 a 29 años",
                            "De 30 a 34 años",
                            "De 35 a 39 años",
                            "De 40 a 44 años",
                            "De 45 a 49 años", 
                            "De 50 a 54 años",
                            "De 55 a 59 años",
                            "De 60 a 64 años",
                            "De 65 años y más",
                            "No especificado")),
        analfabetismo = case_when(cs_p12 == 1 ~ "Sabe leer y escribir un recado", 
                                  cs_p12 == 2 ~ "No sabe leer y escribir un recado", 
                                  cs_p12 == 9 ~ NA) %>% 
          factor(levels = c("Sabe leer y escribir un recado",
                            "No sabe leer y escribir un recado")),
        no_hijos = n_hij, 
        no_hijos_cat = case_when(n_hij == 0 ~ "Ningún hijo", 
                                 n_hij == 1 ~ "1 hijo",
                                 n_hij == 2 ~ "2 hijos",
                                 n_hij == 3 ~ "3 hijos",
                                 between(n_hij, 4,5) ~   "Entre 4 y 5 hijos", 
                                 between(n_hij, 6,10) ~  "Entre 6 y 10 hijos", 
                                 between(n_hij, 11,25) ~ "Más de 10 hijos", 
                                 n_hij == 99 ~           "No especificado") %>% 
          factor(levels = c("Ningún hijo",
                            "1 hijo",
                            "2 hijos",
                            "3 hijos", 
                            "Entre 4 y 5 hijos",
                            "Entre 6 y 10 hijos", 
                            "Más de 10 hijos", 
                            "No especificado"
          )),
        estado_conyugal = case_when(e_con == 1 ~ "Vive con su pareja en unión libre",
                                    e_con == 2 ~ "Está separado(a)",
                                    e_con == 3 ~ "Está divorciado(a)",
                                    e_con == 4 ~ "Está viudo(a)",
                                    e_con == 5 ~ "Está casado(a)",
                                    e_con == 6 ~ "Está soltero(a)",
                                    e_con == 9 ~ NA                             ) %>% 
          factor(levels = c("Vive con su pareja en unión libre",
                            "Está separado(a)",
                            "Está divorciado(a)",
                            "Está viudo(a)",
                            "Está casado(a)",
                            "Está soltero(a)")),
        duracion_jornada = case_when(dur9c == 1 ~ "Ausentes temporales con vínculo laboral", 
                                     dur9c == 2 ~ "Menos de 15 horas", 
                                     dur9c == 3 ~ "De 15 a 24 horas", 
                                     dur9c == 4 ~ "De 25 a 34 horas", 
                                     dur9c == 5 ~ "De 35 a 39 horas", 
                                     dur9c == 6 ~ "De 40 a 48 horas", 
                                     dur9c == 7 ~ "De 49 a 56 horas", 
                                     dur9c == 8 ~ "Más de 56 horas", 
                                     dur9c == 9 ~ "No especificado") %>% 
          factor(levels = c("Ausentes temporales con vínculo laboral",
                            "Menos de 15 horas",
                            "De 15 a 24 horas",
                            "De 25 a 34 horas",
                            "De 35 a 39 horas",
                            "De 40 a 48 horas",
                            "De 49 a 56 horas",
                            "Más de 56 horas",
                            "No especificado")),
        horas_ocupadas = hrsocup,
        tamanio_empresa = case_when(ambito2 %in% c(2,3) ~ "Micronegocios", 
                                    ambito2 == 4 ~        "Pequeños establecimientos", 
                                    ambito2 == 5 ~        "Medianos establecimientos", 
                                    ambito2 == 6 ~        "Grandes establecimientos", 
                                    ambito2 == 7 ~        "Gobierno", 
                                    ambito2 == 8 ~        "Otros") %>% 
          factor(levels = c("Micronegocios",
                            "Pequeños establecimientos",
                            "Medianos establecimientos",
                            "Grandes establecimientos",
                            "Gobierno",
                            "Otros")),
        tamanio_empresa_2 = case_when(ambito2 %in% c(2,3,4,5) ~ "MIPyMES", 
                                      ambito2 == 6 ~        "Grandes establecimientos", 
                                      TRUE ~ NA) %>% factor(levels = c("MIPyMES", "Grandes establecimientos")),
        sector_economico = case_when(rama_est1 == 1 ~ "Sector primario"  ,
                                     rama_est1 == 2 ~ "Sector secundario",
                                     rama_est1 == 3 ~ "Sector terciario",
                                     rama_est1 == 4 ~ NA) %>% factor(levels = c("Sector primario","Sector secundario","Sector terciario")),
        scian = case_when(scian == 1 ~  "Agricultura, ganadería, aprovechamiento forestal, pesca y caza", 
                          scian == 2 ~  "Minería", 
                          scian == 3 ~  "Generación y distribución de electricidad, suministro de agua y gas", 
                          scian == 4 ~  "Construcción", 
                          scian == 5 ~  "Industrias manufactureras", 
                          scian == 6 ~  "Comercio al por mayor", 
                          scian == 7 ~  "Comercio al por menor", 
                          scian == 8 ~  "Transportes, correos y almacenamiento", 
                          scian == 9 ~  "Información en medios masivos", 
                          scian == 10 ~ "Servicios financieros y de seguros", 
                          scian == 11 ~ "Servicios inmobiliarios de alquiler de bienes", 
                          scian == 12 ~ "Servicios profesionales, científicos y técnicos", 
                          scian == 13 ~ "Corporativos", 
                          scian == 14 ~ "Servicios de apoyo a los negocios y manejo de desechos", 
                          scian == 15 ~ "Servicios educativos", 
                          scian == 16 ~ "Servicios de salud y de asistencia social", 
                          scian == 17 ~ "Servicios de esparcimiento culturales y deportivos", 
                          scian == 18 ~ "Servicios de hospedaje y preparación de alimentos y bebidas", 
                          scian == 19 ~ "Otros servicios, excepto actividades gubernamentales", 
                          scian == 20 ~ "Actividades gubernamentales y de organismos internacionales", 
                          scian == 21 ~ "No especificado") %>%
          factor(levels = c("Agricultura, ganadería, aprovechamiento forestal, pesca y caza",
                            "Minería", 
                            "Generación y distribución de electricidad, suministro de agua y gas", 
                            "Construcción", 
                            "Industrias manufactureras",
                            "Comercio al por mayor",
                            "Comercio al por menor",
                            "Transportes, correos y almacenamiento",
                            "Información en medios masivos", 
                            "Servicios financieros y de seguros",
                            "Servicios inmobiliarios de alquiler de bienes",
                            "Servicios profesionales, científicos y técnicos", 
                            "Corporativos",
                            "Servicios de apoyo a los negocios y manejo de desechos",
                            "Servicios educativos",
                            "Servicios de salud y de asistencia social",
                            "Servicios de esparcimiento culturales y deportivos",
                            "Servicios de hospedaje y preparación de alimentos y bebidas", 
                            "Otros servicios, excepto actividades gubernamentales",
                            "Actividades gubernamentales y de organismos internacionales",
                            "No especificado"
          )
          ),
        empresas_gubernamentales = case_when(tue3 == 0 ~ NA,
                                             tue3 == 1 ~ "Administradas por los gobiernos",
                                             tue3 == 2 ~ "No administradas por los Gobiernos"),
        subocu = ifelse(sub_o == 1,
                        "Subocupado", 
                        "No subocupado") %>% 
          factor(levels = c("Subocupado", "No subocupado")),
        tipo_contratacion = case_when(tip_con == 1 ~ "Con contrato escrito", 
                                      tip_con == 2 ~ "Temporal", 
                                      tip_con == 3 ~ "De base, planta o por tiempo definido", 
                                      tip_con == 4 ~ "Contrato de tipo no especificado", 
                                      tip_con == 5 ~ "Sin contrato escrito", 
                                      tip_con == 6 ~ "No especificado") %>% 
          factor(levels = c("Con contrato escrito",
                            "Temporal",
                            "De base, planta o por tiempo definido",
                            "Contrato de tipo no especificado",
                            "Sin contrato escrito",
                            "No especificado")),
        recibe_apoyos = case_when(p14apoyos == 1 ~ "Sí recibe apoyos económicos",
                                  p14apoyos == 2 ~ "No recibe apoyos económicos",
                                  p14apoyos == 3 ~ NA),
        sector_informalidad = case_when(mh_fil2 == 1 ~ "Sector informal",
                                        mh_fil2 == 2 ~ "Trabajo doméstico remunerado",
                                        mh_fil2 == 3 ~ "Empresas, gobierno e instituciones",
                                        mh_fil2 == 4 ~ "Ámbito agropecuario") %>% 
          factor(levels = c("Sector informal",
                            "Trabajo doméstico remunerado",
                            "Empresas, gobierno e instituciones",
                            "Ámbito agropecuario")),
        seguridad_social = case_when(seg_soc == 1 ~ "Con acceso a Seguridad Social", 
                                     seg_soc == 2 ~ "Sin acceso a Seguridad Social", 
                                     TRUE ~ NA
        ),
        ingreso_sm = case_when(
          (is.na(p6b2) & (p6_9==9 | p6a3==3)) ~ 0,
          is.na(p6b2) & p6c == 1 ~ salario*0.5,
          is.na(p6b2) & p6c == 2 ~ salario*1,
          is.na(p6b2) & p6c == 3 ~ salario*1.5,
          is.na(p6b2) & p6c == 4 ~ salario*2.5,
          is.na(p6b2) & p6c == 5 ~ salario*4,
          is.na(p6b2) & p6c == 6 ~ salario*7.5,
          is.na(p6b2) & p6c == 7 ~ (salario*10)+1,
          T ~ p6b2
        ),
        ingreso = ifelse(ingocup==0,NA,ingocup),
        edu = case_when(
          anios_esc < 6 ~                     "Primaria incompleta",
          anios_esc >= 6 & anios_esc < 9  ~   "Primaria completa",
          anios_esc >= 9 & anios_esc < 12  ~  "Secundaria completa",
          anios_esc >= 12 & anios_esc < 15  ~ "Preparatoria completa",
          anios_esc >= 15 ~                   "Universidad o más",
          T ~ NA_character_
        ),
        sector = case_when(
          rama_est2 == 1 ~ "Agricultura, ganadería, silvicultura, caza y pesca",
          rama_est2 == 2 ~ "Industria extractiva y de la electricidad",
          rama_est2 == 3 ~ "Industria manufacturera",
          rama_est2 == 4 ~ "Construcción",
          rama_est2 == 5 ~ "Comercio",
          rama_est2 == 6 ~ "Restaurantes y serviciosde alojamiento",
          rama_est2 == 7 ~ "Transportes, comunicaciones, correo y almacenamiento",
          rama_est2 == 8 ~ "Servicios profesionales, financieros y corporativos",
          rama_est2 == 9 ~ "Servicios sociales",
          rama_est2 == 10 ~ "Servicios diversos",
          rama_est2 == 11 ~ "Gobierno y organismos internacionales",
          T ~ NA_character_
        ),
        tipo_formalidad = case_when(
          emp_ppal == 1 ~ "Empleo informal",
          emp_ppal == 2 ~ "Empleo formal",
          T ~ NA_character_
        ),
        jornada_completa = case_when(
          dur_est == 4 | dur_est == 5 ~ "Jornada de tiempo completo",
          dur_est <=3 ~ "Jornada de medio tiempo",
          T ~ NA_character_
        ), 
        tipo_educacion = case_when(
          cs_p13_1 == "00" | cs_p13_1 == 0  ~ "Ninguna",
          cs_p13_1 == "01" | cs_p13_1 == 1 ~ "Preescolar",
          cs_p13_1 == "02" | cs_p13_1 == 2 ~ "Primaria",
          cs_p13_1 == "03" | cs_p13_1 == 3 ~ "Secundaria",
          cs_p13_1 == "04" | cs_p13_1 == 4 ~ "Preparatoria o bachillerato",
          cs_p13_1 == "05" | cs_p13_1 == 5 ~ "Normal",
          cs_p13_1 == "06" | cs_p13_1 == 6 ~ "Carrera técnica",
          cs_p13_1 == "07" | cs_p13_1 == 7 ~ "Profesional",
          cs_p13_1 == "08" | cs_p13_1 == 8 ~ "Maestría",
          cs_p13_1 == "09" | cs_p13_1 == 9 ~ "Doctorado",
          cs_p13_1 == "99" | cs_p13_1 == 10 ~ "No sabe")) %>% 
      rename(sinco = p3, factor = fac)
    
    set.seed(20230216)
    vars_a_escoger <- c("llaveh", "llave", "ingreso", "ingreso_sm", "sex", "par_c",
                        "eda12c", "eda", "e_con", "edu", "pos_ocu", "tipo_formalidad", "sector",
                        "jornada_completa", "t_loc", "cve_ent", "anios_esc",
                        "tipo_educacion", "grupo_edad",
                        "clase1", "clase2", "cve_ent",
                        "sinco","hrsocup","p4a","factor",
                        "pos_ocu",  "c_inac5c",
                        "p3a", "p3d", "t_tra","hrsocup",
                        # Nuevas variables
                        "sexo", "anios_esc", "tamanio_localidad", "grupo_edad", "horas_ocupadas",
                        "analfabetismo", "no_hijos", "no_hijos_cat", "estado_conyugal",
                        "duracion_jornada",
                        "tamanio_empresa", "sector_economico", "scian",
                        "salario",
                        "empresas_gubernamentales", "subocu", "tipo_contratacion",
                        "recibe_apoyos", "sector_informalidad", "seguridad_social", "sector", "cd_a",
                        # Variables de diseño muestral y crudas para análisis
                        # a nivel ciudad autorrepresentada (script 102 y posteriores).
                        "upm", "est_d_tri", "fac_tri",
                        "ingocup", "sub_o")
    
    
    if(trim_sel == 1 & year_sel > 2008){
      df_tempo = df_tempo %>%
        mutate(p11_h2 = ifelse(p11_h2>97,NA,p11_h2),
               horas_semana_cuidados = p11_h2 + (p11_m2/60),
               p11_h7 = ifelse(p11_h7>97,NA,p11_h7),
               horas_semana_quehaceres = p11_h7 + (p11_m7/60),
               horas_semana_quehaceres_cuidados = horas_semana_cuidados+horas_semana_quehaceres)
      vars_a_escoger <- append(vars_a_escoger, c("horas_semana_quehaceres", "horas_semana_quehaceres_cuidados"))
      
    } else {
      df_tempo = df_tempo %>%
        mutate(p11_h2 = ifelse(p9_h2>97,NA,p9_h2),
               horas_semana_cuidados = p9_h2 + (p9_m2/60),
               p9_h7 = ifelse(p9_h7>97,NA,p9_h7),
               horas_semana_quehaceres = p9_h7 + (p9_m7/60),
               horas_semana_quehaceres_cuidados = horas_semana_cuidados+horas_semana_quehaceres)
      vars_a_escoger <- append(vars_a_escoger, c("horas_semana_quehaceres", "horas_semana_quehaceres_cuidados"))
      
    }
    
    if(year_sel > 2021 | year_sel == 2021 & trim_sel >= 3){
      # Corrección migración 
      df_tempo = df_tempo %>% 
        mutate(
          donde_vivia_hace_un_año = case_when(cs_p20a_1 == 1 ~  "Aquí en este estado",
                                              cs_p20a_1 == 2 ~  "En otro estado",
                                              cs_p20a_1 == 3 ~  "En los Estados Unidos de América",
                                              cs_p20a_1 == 4 ~  "En otro país", 
                                              TRUE ~ NA) %>%
            factor(levels = c("Aquí en este estado",
                              "En otro estado",
                              "En los Estados Unidos de América",
                              "En otro país")))  
      vars_a_escoger <- append(vars_a_escoger, c("donde_vivia_hace_un_año"))
    }
    
    df_tempo_hotdeck <- df_tempo %>% 
      filter(eda >= 15) %>% 
      filter(pos_ocu < 4 & clase1 == 1 & clase2 == 1) %>% 
      select_at(vars_a_escoger) |> 
      VIM::hotdeck(
        variable = c("ingreso_sm"),
        domain_var = c("sex", "eda12c", "e_con",
                       "edu", "pos_ocu", "tipo_formalidad",
                       "sector", "jornada_completa", "t_loc", "cve_ent")
      ) |>
      mutate(
        periodo = paste0(year_sel,"T",trim_sel),
        año = paste0(year_sel),
        trimestre = trim_sel
      )
    
    df_tempo_no_hotdeck <- df_tempo %>% 
      mutate(bandera = ifelse((eda >= 15 & pos_ocu < 4 & clase1 ==1 & clase2==1), 
                              yes = T, no = F)) %>% 
      filter(bandera == F) %>% 
      select(-bandera) %>% 
      select_at(vars_a_escoger) %>% 
      mutate(
        periodo = paste0(year_sel,"T",trim_sel),
        año = paste0(year_sel),
        trimestre = trim_sel, 
        ingreso_sm_imp = NA
      ) %>% 
      select(names(df_tempo_hotdeck))
    
    df_tempo_final <- rbind(df_tempo_hotdeck, df_tempo_no_hotdeck)
    
  } # Fin del Bloque 2 (3T2020 a 2T2025)
  
  # ==========================================================================
  # BLOQUE 3: Procesamiento antes del 1T2020 ----
  # ==========================================================================
  
  if(year_sel < 2020 | (year_sel == 2020 & trim_sel == 1)){
    # *** inicio de la función *** #
    dir <- archivos %>% 
      filter(year == year_sel & trim == trim_sel & tipo == "Cuestionario 1") %>% 
      pull(file)
    
    df_coe1 <- read.dbf(dir, as.is = T) %>%
      rename_all(tolower) %>%
      normalizar_cve_ent() %>%
      mutate(llave = paste0(
        cd_a, cve_ent, con, v_sel, n_hog, h_mud, n_ren
      )) %>%
      mutate_at(vars(-starts_with("llave")), as.numeric)

    # Tabla de cuestionario de ocupación y empleo II
    dir <- archivos %>%
      filter(year == year_sel & trim == trim_sel & tipo == "Cuestionario 2") %>%
      pull(file)

    df_coe2 <- read.dbf(dir, as.is = T) %>%
      rename_all(tolower) %>%
      normalizar_cve_ent() %>%
      mutate(
        llave = paste0(
          cd_a, cve_ent, con, v_sel, n_hog, h_mud, n_ren
        )
      ) %>%
      mutate_at(vars(-starts_with("llave")), as.numeric)


    # Tabla de sociodemográfico
    dir <- archivos %>%
      filter(year == year_sel & trim == trim_sel & tipo == "Sociodemográfico") %>%
      pull(file)

    df_sdem <- read.dbf(dir, as.is = T) %>%
      rename_all(tolower) %>%
      normalizar_cve_ent() %>%
      mutate(
        llaveh = paste0(
          cd_a, cve_ent, con, v_sel, n_hog, h_mud
        ),
        llave = paste0(
          cd_a, cve_ent, con, v_sel, n_hog, h_mud, n_ren
        )
      ) %>%
      mutate_at(
        vars(-c(starts_with("llave"), r_def, c_res,
                any_of(c("cs_p21_des", "cs_p23_des")))),
        as.numeric
      ) %>%
      filter(
        as.character(r_def) == "00" & (as.character(c_res) == "1" | as.character(c_res) == "3")
      )
    
    ## Juntar bases 
    
    df_tempo <- df_sdem                                                         %>%
      left_join(df_coe1 %>% select(-c(fac, cve_ent)), by = c("llave")) %>%
      left_join(df_coe2 %>% select(-c(fac, cve_ent)), by = c("llave")) %>%
      select(-c(ends_with(".y"),ends_with(".x"))) %>% 
      mutate(trimestre = trim_sel)
    
    # Procesamiento del microstio de mercado laboral y brechas de género: 
    df_tempo = df_tempo |> 
      mutate(
        sexo = ifelse(sex == 1, "Hombre", "Mujer"),
        anios_esc = ifelse(anios_esc==99,NA,anios_esc),
        tamanio_localidad = case_when(t_loc == 1 ~ "Mayores a 100,000 habitantes", 
                                      t_loc == 2 ~ "Entre 15,000 a 99,999 habitantes", 
                                      t_loc == 3 ~ "Entre 2,500 a 14,999 habitantes", 
                                      t_loc == 4 ~ "Menores de 2,500 habitantes") %>% 
          factor(levels = c("Mayores a 100,000 habitantes",
                            "Entre 15,000 a 99,999 habitantes",
                            "Entre 2,500 a 14,999 habitantes",
                            "Menores de 2,500 habitantes")),
        tamanio_localidad_2 = ifelse(t_loc == 4, yes = "Rural", no = "Urbana"),
        edad = eda,
        grupo_edad = case_when(
          eda12c == 1 ~ "De 15 a 19 años",
          eda12c == 2 ~  "De 20 a 24 años",
          eda12c == 3 ~  "De 25 a 29 años",
          eda12c == 4 ~  "De 30 a 34 años",
          eda12c == 5 ~  "De 35 a 39 años",
          eda12c == 6 ~  "De 40 a 44 años",
          eda12c == 7 ~  "De 45 a 49 años",
          eda12c == 8 ~  "De 50 a 54 años",
          eda12c == 9 ~  "De 55 a 59 años",
          eda12c == 10 ~  "De 60 a 64 años",
          eda12c == 11 ~  "De 65 años y más",
          eda12c == 12 ~  "No especificado"
        ) %>% 
          factor(levels = c("De 15 a 19 años",
                            "De 20 a 24 años",
                            "De 25 a 29 años",
                            "De 30 a 34 años",
                            "De 35 a 39 años",
                            "De 40 a 44 años",
                            "De 45 a 49 años", 
                            "De 50 a 54 años",
                            "De 55 a 59 años",
                            "De 60 a 64 años",
                            "De 65 años y más",
                            "No especificado")),
        analfabetismo = case_when(cs_p12 == 1 ~ "Sabe leer y escribir un recado", 
                                  cs_p12 == 2 ~ "No sabe leer y escribir un recado", 
                                  cs_p12 == 9 ~ NA) %>% 
          factor(levels = c("Sabe leer y escribir un recado",
                            "No sabe leer y escribir un recado")),
        no_hijos = n_hij, 
        no_hijos_cat = case_when(n_hij == 0 ~ "Ningún hijo", 
                                 n_hij == 1 ~ "1 hijo",
                                 n_hij == 2 ~ "2 hijos",
                                 n_hij == 3 ~ "3 hijos",
                                 between(n_hij, 4,5) ~   "Entre 4 y 5 hijos", 
                                 between(n_hij, 6,10) ~  "Entre 6 y 10 hijos", 
                                 between(n_hij, 11,25) ~ "Más de 10 hijos", 
                                 n_hij == 99 ~           "No especificado") %>% 
          factor(levels = c("Ningún hijo",
                            "1 hijo",
                            "2 hijos",
                            "3 hijos", 
                            "Entre 4 y 5 hijos",
                            "Entre 6 y 10 hijos", 
                            "Más de 10 hijos", 
                            "No especificado"
          )),
        estado_conyugal = case_when(e_con == 1 ~ "Vive con su pareja en unión libre",
                                    e_con == 2 ~ "Está separado(a)",
                                    e_con == 3 ~ "Está divorciado(a)",
                                    e_con == 4 ~ "Está viudo(a)",
                                    e_con == 5 ~ "Está casado(a)",
                                    e_con == 6 ~ "Está soltero(a)",
                                    e_con == 9 ~ NA                             ) %>% 
          factor(levels = c("Vive con su pareja en unión libre",
                            "Está separado(a)",
                            "Está divorciado(a)",
                            "Está viudo(a)",
                            "Está casado(a)",
                            "Está soltero(a)")),
        duracion_jornada = case_when(dur9c == 1 ~ "Ausentes temporales con vínculo laboral", 
                                     dur9c == 2 ~ "Menos de 15 horas", 
                                     dur9c == 3 ~ "De 15 a 24 horas", 
                                     dur9c == 4 ~ "De 25 a 34 horas", 
                                     dur9c == 5 ~ "De 35 a 39 horas", 
                                     dur9c == 6 ~ "De 40 a 48 horas", 
                                     dur9c == 7 ~ "De 49 a 56 horas", 
                                     dur9c == 8 ~ "Más de 56 horas", 
                                     dur9c == 9 ~ "No especificado") %>% 
          factor(levels = c("Ausentes temporales con vínculo laboral",
                            "Menos de 15 horas",
                            "De 15 a 24 horas",
                            "De 25 a 34 horas",
                            "De 35 a 39 horas",
                            "De 40 a 48 horas",
                            "De 49 a 56 horas",
                            "Más de 56 horas",
                            "No especificado")),
        horas_ocupadas = hrsocup,
        tamanio_empresa = case_when(ambito2 %in% c(2,3) ~ "Micronegocios", 
                                    ambito2 == 4 ~        "Pequeños establecimientos", 
                                    ambito2 == 5 ~        "Medianos establecimientos", 
                                    ambito2 == 6 ~        "Grandes establecimientos", 
                                    ambito2 == 7 ~        "Gobierno", 
                                    ambito2 == 8 ~        "Otros"                        ) %>% 
          factor(levels = c("Micronegocios",
                            "Pequeños establecimientos",
                            "Medianos establecimientos",
                            "Grandes establecimientos",
                            "Gobierno",
                            "Otros")),
        tamanio_empresa_2 = case_when(ambito2 %in% c(2,3,4,5) ~ "MIPyMES", 
                                      ambito2 == 6 ~        "Grandes establecimientos", 
                                      TRUE ~ NA) %>% factor(levels = c("MIPyMES", "Grandes establecimientos")),
        sector_economico = case_when(rama_est1 == 1 ~ "Sector primario"  ,
                                     rama_est1 == 2 ~ "Sector secundario",
                                     rama_est1 == 3 ~ "Sector terciario",
                                     rama_est1 == 4 ~ NA) %>% factor(levels = c("Sector primario","Sector secundario","Sector terciario")),
        scian = case_when(scian == 1 ~  "Agricultura, ganadería, aprovechamiento forestal, pesca y caza", 
                          scian == 2 ~  "Minería", 
                          scian == 3 ~  "Generación y distribución de electricidad, suministro de agua y gas", 
                          scian == 4 ~  "Construcción", 
                          scian == 5 ~  "Industrias manufactureras", 
                          scian == 6 ~  "Comercio al por mayor", 
                          scian == 7 ~  "Comercio al por menor", 
                          scian == 8 ~  "Transportes, correos y almacenamiento", 
                          scian == 9 ~  "Información en medios masivos", 
                          scian == 10 ~ "Servicios financieros y de seguros", 
                          scian == 11 ~ "Servicios inmobiliarios de alquiler de bienes", 
                          scian == 12 ~ "Servicios profesionales, científicos y técnicos", 
                          scian == 13 ~ "Corporativos", 
                          scian == 14 ~ "Servicios de apoyo a los negocios y manejo de desechos", 
                          scian == 15 ~ "Servicios educativos", 
                          scian == 16 ~ "Servicios de salud y de asistencia social", 
                          scian == 17 ~ "Servicios de esparcimiento culturales y deportivos", 
                          scian == 18 ~ "Servicios de hospedaje y preparación de alimentos y bebidas", 
                          scian == 19 ~ "Otros servicios, excepto actividades gubernamentales", 
                          scian == 20 ~ "Actividades gubernamentales y de organismos internacionales", 
                          scian == 21 ~ "No especificado") %>%
          factor(levels = c("Agricultura, ganadería, aprovechamiento forestal, pesca y caza",
                            "Minería", 
                            "Generación y distribución de electricidad, suministro de agua y gas", 
                            "Construcción", 
                            "Industrias manufactureras",
                            "Comercio al por mayor",
                            "Comercio al por menor",
                            "Transportes, correos y almacenamiento",
                            "Información en medios masivos", 
                            "Servicios financieros y de seguros",
                            "Servicios inmobiliarios de alquiler de bienes",
                            "Servicios profesionales, científicos y técnicos", 
                            "Corporativos",
                            "Servicios de apoyo a los negocios y manejo de desechos",
                            "Servicios educativos",
                            "Servicios de salud y de asistencia social",
                            "Servicios de esparcimiento culturales y deportivos",
                            "Servicios de hospedaje y preparación de alimentos y bebidas", 
                            "Otros servicios, excepto actividades gubernamentales",
                            "Actividades gubernamentales y de organismos internacionales",
                            "No especificado"
          )
          ),
        empresas_gubernamentales = case_when(tue3 == 0 ~ NA,
                                             tue3 == 1 ~ "Administradas por los gobiernos",
                                             tue3 == 2 ~ "No administradas por los Gobiernos"),
        subocu = ifelse(sub_o == 1,
                        "Subocupado", 
                        "No subocupado") %>% 
          factor(levels = c("Subocupado", "No subocupado")),
        tipo_contratacion = case_when(tip_con == 1 ~ "Con contrato escrito", 
                                      tip_con == 2 ~ "Temporal", 
                                      tip_con == 3 ~ "De base, planta o por tiempo definido", 
                                      tip_con == 4 ~ "Contrato de tipo no especificado", 
                                      tip_con == 5 ~ "Sin contrato escrito", 
                                      tip_con == 6 ~ "No especificado") %>% 
          factor(levels = c("Con contrato escrito",
                            "Temporal",
                            "De base, planta o por tiempo definido",
                            "Contrato de tipo no especificado",
                            "Sin contrato escrito",
                            "No especificado")),
        recibe_apoyos = case_when(p14apoyos == 1 ~ "Sí recibe apoyos económicos",
                                  p14apoyos == 2 ~ "No recibe apoyos económicos",
                                  p14apoyos == 3 ~ NA),
        sector_informalidad = case_when(mh_fil2 == 1 ~ "Sector informal",
                                        mh_fil2 == 2 ~ "Trabajo doméstico remunerado",
                                        mh_fil2 == 3 ~ "Empresas, gobierno e instituciones",
                                        mh_fil2 == 4 ~ "Ámbito agropecuario") %>% 
          factor(levels = c("Sector informal",
                            "Trabajo doméstico remunerado",
                            "Empresas, gobierno e instituciones",
                            "Ámbito agropecuario")),
        seguridad_social = case_when(seg_soc == 1 ~ "Con acceso a Seguridad Social", 
                                     seg_soc == 2 ~ "Sin acceso a Seguridad Social", 
                                     TRUE ~ NA
        ),
        ingreso_sm = case_when(
          (is.na(p6b2) & (p6_9==9 | p6a3==3)) ~ 0,
          is.na(p6b2) & p6c == 1 ~ salario*0.5,
          is.na(p6b2) & p6c == 2 ~ salario*1,
          is.na(p6b2) & p6c == 3 ~ salario*1.5,
          is.na(p6b2) & p6c == 4 ~ salario*2.5,
          is.na(p6b2) & p6c == 5 ~ salario*4,
          is.na(p6b2) & p6c == 6 ~ salario*7.5,
          is.na(p6b2) & p6c == 7 ~ (salario*10)+1,
          T ~ p6b2
        ),
        ingreso = ifelse(ingocup==0,NA,ingocup),
        edu = case_when(
          anios_esc < 6 ~ "Primaria incompleta",
          anios_esc >= 6 & anios_esc < 9  ~ "Primaria completa",
          anios_esc >= 9 & anios_esc < 12  ~ "Secundaria completa",
          anios_esc >= 12 & anios_esc < 15  ~ "Preparatoria completa",
          anios_esc >= 15 ~ "Universidad o más",
          T ~ NA_character_
        ),
        sector = case_when(
          rama_est2 == 1 ~ "Agricultura, ganadería, silvicultura, caza y pesca",
          rama_est2 == 2 ~ "Industria extractiva y de la electricidad",
          rama_est2 == 3 ~ "Industria manufacturera",
          rama_est2 == 4 ~ "Construcción",
          rama_est2 == 5 ~ "Comercio",
          rama_est2 == 6 ~ "Restaurantes y serviciosde alojamiento",
          rama_est2 == 7 ~ "Transportes, comunicaciones, correo y almacenamiento",
          rama_est2 == 8 ~ "Servicios profesionales, financieros y corporativos",
          rama_est2 == 9 ~ "Servicios sociales",
          rama_est2 == 10 ~ "Servicios diversos",
          rama_est2 == 11 ~ "Gobierno y organismos internacionales",
          T ~ NA_character_
        ),
        tipo_formalidad = case_when(
          emp_ppal == 1 ~ "Empleo informal",
          emp_ppal == 2 ~ "Empleo formal",
          T ~ NA_character_
        ),
        jornada_completa = case_when(
          dur_est == 4 | dur_est == 5 ~ "Jornada de tiempo completo",
          dur_est <=3 ~                 "Jornada de medio tiempo",
          T ~ NA_character_
        ), 
        tipo_educacion = case_when(
          cs_p13_1 == "00" | cs_p13_1 == 0  ~ "Ninguna",
          cs_p13_1 == "01" | cs_p13_1 == 1 ~ "Preescolar",
          cs_p13_1 == "02" | cs_p13_1 == 2 ~ "Primaria",
          cs_p13_1 == "03" | cs_p13_1 == 3 ~ "Secundaria",
          cs_p13_1 == "04" | cs_p13_1 == 4 ~ "Preparatoria o bachillerato",
          cs_p13_1 == "05" | cs_p13_1 == 5 ~ "Normal",
          cs_p13_1 == "06" | cs_p13_1 == 6 ~ "Carrera técnica",
          cs_p13_1 == "07" | cs_p13_1 == 7 ~ "Profesional",
          cs_p13_1 == "08" | cs_p13_1 == 8 ~ "Maestría",
          cs_p13_1 == "09" | cs_p13_1 == 9 ~ "Doctorado",
          cs_p13_1 == "99" | cs_p13_1 == 10 ~ "No sabe"
        )) %>%
      mutate(fac_tri = fac) %>%
      rename(sinco = p3, factor = fac)

    # Alias del estrato trimestral. Pre-2020 ENOE sólo trae `est_d`
    # (no había distinción _tri/_men). Se duplica como `est_d_tri` para
    # mantener un nombre uniforme con bloques 1 y 2.
    if(!"est_d_tri" %in% names(df_tempo) & "est_d" %in% names(df_tempo)){
      df_tempo <- df_tempo %>% mutate(est_d_tri = est_d)
    }

    set.seed(20230216)

    vars_a_escoger <- c("llaveh", "llave", "ingreso", "ingreso_sm", "sex", "par_c",
                        "eda12c", "eda", "e_con", "edu", "pos_ocu", "tipo_formalidad", "sector",
                        "jornada_completa", "t_loc", "cve_ent", "anios_esc",
                        "tipo_educacion", "grupo_edad",
                        "clase1", "clase2", "cve_ent",
                        "sinco","hrsocup","p4a","factor",
                        "pos_ocu", "c_inac5c",
                        "p3a", "p3d", "t_tra","hrsocup",
                        "sexo", "anios_esc", "tamanio_localidad", "grupo_edad", "horas_ocupadas",
                        "analfabetismo", "no_hijos", "no_hijos_cat",
                        "estado_conyugal", "duracion_jornada",
                        "tamanio_empresa", "sector_economico", "scian",
                        "salario",
                        "empresas_gubernamentales", "subocu", "tipo_contratacion",
                        "recibe_apoyos", "sector_informalidad", "seguridad_social", "sector", "cd_a",
                        # Variables de diseño muestral y crudas para análisis
                        # a nivel ciudad autorrepresentada (script 102 y posteriores).
                        # Pre-2020: fac_tri y est_d_tri son alias de fac y est_d.
                        "upm", "est_d_tri", "fac_tri",
                        "ingocup", "sub_o")
    
    if(trim_sel == 1 & year_sel > 2008){
      
      df_tempo = df_tempo %>%
        mutate(p11_h2 = ifelse(p11_h2>97,NA,p11_h2),
               horas_semana_cuidados = p11_h2 + (p11_m2/60),
               p11_h7 = ifelse(p11_h7>97,NA,p11_h7),
               horas_semana_quehaceres = p11_h7 + (p11_m7/60),
               horas_semana_quehaceres_cuidados = horas_semana_cuidados+horas_semana_quehaceres)
      vars_a_escoger <- append(vars_a_escoger, c("horas_semana_quehaceres", "horas_semana_quehaceres_cuidados"))
      
    }
    
    
    df_tempo_hotdeck <- df_tempo %>% 
      filter(eda >= 15) %>% 
      filter(pos_ocu < 4 & clase1 == 1 & clase2 == 1) %>% 
      select_at(vars_a_escoger) |> 
      VIM::hotdeck(
        variable = c("ingreso_sm"),
        domain_var = c("sex", "eda12c", "e_con",
                       "edu", "pos_ocu", "tipo_formalidad",
                       "sector", "jornada_completa", "t_loc", "cve_ent")
      ) |>
      mutate(
        periodo = paste0(year_sel,"T",trim_sel),
        año = paste0(year_sel),
        trimestre = trim_sel
      )
    
    df_tempo_no_hotdeck <- df_tempo %>% 
      mutate(bandera = ifelse((eda >= 15 & pos_ocu < 4 & clase1 ==1 & clase2==1), 
                              yes = T, no = F)) %>% 
      filter(bandera == F) %>% 
      select(-bandera) %>% 
      select_at(vars_a_escoger) %>% 
      mutate(
        periodo = paste0(year_sel,"T",trim_sel),
        año = paste0(year_sel),
        trimestre = trim_sel, 
        ingreso_sm_imp = NA
      ) %>% 
      select(names(df_tempo_hotdeck))
    
    df_tempo_final <- rbind(df_tempo_hotdeck, df_tempo_no_hotdeck)
  } # Fin del Bloque 3 (antes de 1T2020)
  
  # ==========================================================================
  # Renombrar y guardar ----
  # ==========================================================================
  
  df_enoe_reciente <- df_tempo_final %>% 
    mutate(trimestre = as.character(trimestre))
  
  saveRDS(df_enoe_reciente,
          file = str_c(datos_limpios, "/", "enoe_proc_",
                       year_sel, "_", trim_sel, ".rds"))
}

# Generamos las bases para las ENOES que nos interesan: 
# Tabla de Años y Trimestres disponibles
indice = archivos %>% 
  select(year, trim) %>% 
  group_by(year, trim) %>% 
  unique() %>% 
  arrange(year, trim) 
# %>% 
#   tail(14)

# Generamos los datos en el formato solicitado: 
for(i in nrow(indice):1){
  esta_ya_la_base_en_la_carpeta <- str_c(datos_limpios, "/", "enoe_proc_",
                                         indice$year[i], "_", indice$trim[i], ".rds") %in% list.files(datos_limpios, full.names = T)
  
  
  
  if(esta_ya_la_base_en_la_carpeta){
    print(str_c("Año: ", indice$year[i] , " - Trimestre: ", indice$trim[i], " (Ya en carpeta)"))
  } else {
    print(str_c("Año: ", indice$year[i] , " - Trimestre: ", indice$trim[i], " (Generando)"))
    gen_datos(year_sel = indice$year[i], trim_sel = indice$trim[i])        
    print(str_c("Año: ", indice$year[i] , " - Trimestre: ", indice$trim[i], " (Generada)"))
  }
}

# 3. Guardar datos -------------------------------------------------------------
# bdx <- readRDS("02_datos_limpios/rds/enoe_proc_2024_1.rds") %>%
#   as_tibble()

# class(bdx$horas_semana_quehaceres)
# 
# names(bdx) %>% sort()

# 4. FIN. ----------------------------------------------------------------------
