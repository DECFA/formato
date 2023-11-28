## Validar los dataframes que hemos creado
## Usamos el paquete validate

library("validate")
setwd("/home/danielc/TEPESCO/git/formato/")

val_df <- readRDS("datos_de_muestra/GB/gb_testsample_processed_validation.rds")

## Creamos un fichero con reglas para la validación: p.ej gb_rules.yaml

onecol <- val_df %>% select(VE_REF,FT_REF, SI_TIMESTAMP, SI_LATI, SI_LONG, SI_SP, SI_SPCA, SI_HE)

# Definir los nombres de columna requeridos
required_columns <- c(
  "VE_REF", "FT_REF", "SI_TIMESTAMP", "SI_LATI", "SI_LONG",
  "SI_SP", "SI_SPCA", "SI_HE", "SI_DISTANCE", "SI_TDIFF",
  "LE_MET4", "LE_MET6", "SI_FSTATUS"
)

# Verificar si todas las columnas requeridas están presentes
if (length(colnames(val_df)[!(colnames(val_df) %in% required_columns)]) > 0){
  extra_columns <- colnames(val_df)[!(colnames(val_df) %in% required_columns)]
  print(paste("Columnas adicionales encontradas:", extra_columns))
  # Detener la ejecución del script
  return()
} else if (all(required_columns %in% colnames(val_df)))  {
  print("Todas las columnas requeridas están presentes.")
  # Continuar con el resto del script aquí
  rules <- validator(.file ="validador/gb_rules.yaml")
  summary(confront(val_df,rules, raise ='all'))
  warnings(confront(val_df,rules, raise ='all'))
  errors(confront(val_df,rules, raise ='all'))
} else {
  print("Algunas columnas requeridas están ausentes.")
  # Obtener las columnas faltantes
  missing_columns <- required_columns[!(required_columns %in% colnames(val_df))]
  print(paste("Columnas faltantes:", missing_columns))
  
  # Detener la ejecución del script
  return()
}

aggregate((confront(val_df,rules, raise ='all')))

sort((confront(val_df,rules, raise ='all')))











rules <- validator(.file ="/home/danielc/TEPESCO/formato/datos_de_muestra/gb_rules.yaml")
summary(confront(onecol,rules, raise ='all'))




