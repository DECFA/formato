## Validar los dataframes que hemos creado
## Usamos el paquete validate

library("validate")
library("dplyr")
library("readr")
library("sf")

setwd("/home/danielc/TEPESCO/git/formato/")

# Cargamos el fichero que queramos validar (rds o csv)
#val_df <- readRDS("datos_de_muestra/GB/gb_testsample_processed_validation.rds")

val_df <- readRDS("datos_de_muestra/GPS/gps_blanco_formatted_final.rds")

# Hay que crear un dataframe nuevo sin geometría que habrá que comprobar aparte
# ya que esta libreríano sabe que hacer con objetos sf
val_df_drop <- val_df |> st_drop_geometry()

# Leemos el fichero de Metiers
met4 <- read_csv("Metiers_level_4.csv")

# Nos quedamos con la abreviatura

met4_abb <- met4 |> 
  select(Abbreviation) 

met4_abb[met4_abb == "NKX"] <- "NK"

# Definir los nombres de columna requeridos
required_columns <- c(
  "VE_REF", "FT_REF", "SI_TIMESTAMP", "SI_LATI", "SI_LONG",
  "SI_SP", "SI_SPCA", "SI_HE", "SI_COG", "SI_DISTANCECA", "SI_TDIFF",
  "LE_MET4", "LE_MET6", "SI_HARB", "SI_FSTATUS", "geometry", "SI_FOPER",
  "SU_ISOB", "SI_OGT"
)

# Verificar si todas las columnas requeridas están presentes
if (length(colnames(val_df_drop)[!(colnames(val_df_drop) %in% required_columns)]) > 0) {
  extra_columns <- colnames(val_df)[!(colnames(val_df) %in% required_columns)]
  print(paste("Columnas adicionales encontradas:", extra_columns))
  # Detener la ejecución del script
  return()
} else if (all(required_columns %in% colnames(val_df)))  {
  print("Todas las columnas requeridas están presentes.")
  # Continuar con el resto del script aquí
  rules <- validator(.file = "validador/gb_rules.yaml")
  summary(confront(val_df, rules, raise = "all"))
  warnings(confront(val_df, rules, raise = "all"))
  errors(confront(val_df, rules, raise = "all"))
} else {
  print("Algunas columnas requeridas están ausentes.")
  # Obtener las columnas faltantes
  missing_columns <- required_columns[!(required_columns %in% colnames(val_df))]
  print(paste("Columnas faltantes:", missing_columns))

  # Detener la ejecución del script
  return()
}

aggregate((confront(val_df, rules, raise = "all")))

sort((confront(val_df, rules, raise = "all")))

####
rules <- validator(.file = "validador/gb_rules.yaml")
summary(confront(onecol, rules, raise = "all")) |> 
  select(name, items, passes, fails)


