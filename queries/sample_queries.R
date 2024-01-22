library(RPostgreSQL)
library(sf)

# Datos de la conexión
db_connection <- dbConnect(
  dbDriver("PostgreSQL"),
  user = "postgres",
  password = "postgres",
  dbname = "tepesco_test",
  host = "172.24.0.121",
  port = 5432
)

# Ejecutar la consulta SQL usando los datos de la conexión:
# get_filtered_vessels es una funcion de SQL y cuyos parámetros son:
# Tamaño mínimo del barco
# Si está pescando
# Si tiene VMS
# Si lleva observador

query <- "SELECT * FROM get_filtered_vessels(10, NULL, false, true)"

# Sin usar la función la consulta sería:
query <- "SELECT g.ve_ref, g.ft_ref::bpchar(8), g.si_timestamp, g.si_lati, 
          g.si_long, g.si_spca, g.si_he, g.si_cog, g.si_distanceca, g.si_tdiff, 
          g.le_met4, g.le_met6, g.si_harb, g.si_fstatus, g.geometry, g.si_foper, 
          g.su_isob, g.si_ogt, vm.ve_name
    FROM gps g
    JOIN vessel_master vm ON g.ve_ref = vm.ve_ref
    WHERE vm.ve_len > 10
        AND vm.ve_vms_indicator = FALSE
        AND g.su_isob = TRUE"

result <- dbGetQuery(db_connection, query)

# Convertir la geometría de PostgreSQL a una que entienda R

result_sf <- st_as_sf(result, coords = c("si_long", "si_lati"))

#Cerrar la conexión a la BBDD
  
dbDisconnect(db_connection)

library(dplyr)
library(dbplyr)
library(DBI)

# Usando dbplyr para hacer queries "sin" SQL

# Crear una conexión dbplyr
con_dbplyr <- tbl(db_connection, in_schema("public", "gps")) %>%
  left_join(tbl(db_connection, in_schema("public", "vessel_master")), by = c("ve_ref"))

# Definir la consulta
query_dbplyr <- con_dbplyr %>%
  select(
    ve_ref, 
    ft_ref, 
    si_timestamp, 
    si_lati, 
    si_long, 
    si_spca, 
    si_he, 
    si_cog, 
    si_distanceca, 
    si_tdiff, 
    le_met4, 
    le_met6, 
    si_harb, 
    si_fstatus, 
    geometry, 
    si_foper, 
    su_isob, 
    si_ogt, 
    ve_name,
    ve_len,
    ve_vms_indicator
  ) %>%
  filter(
    ve_len > 10,
    ve_vms_indicator == FALSE,
    su_isob == TRUE,
    si_fstatus == TRUE
  )

# Ejecutar la consulta en la base de datos y traer los resultados a R
result_sf_dbplyr <- query_dbplyr %>% 
  collect() %>%
  st_as_sf(coords = c("si_long", "si_lati"))

# Cerrar la conexión a la base de datos
dbDisconnect(db_connection)



