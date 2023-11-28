#########################################
#   CODIGO DE EJEMPLO Y UTILIDAD PARA   #
#     PREPARAR DATOS DE GPS BLANCOS     #
#########################################

## Configuración y librerías
library(tidyverse)
library(lubridate)
library(geosphere)
library(sf)

setwd("/home/danielc/TEPESCO/git/formato/")

## Cargamos el fichero de cajas verdes
data <- read_csv("datos_de_muestra/GPS/gps_blanco.csv")

# Leer el archivo CSV. Hay que comprobar que separadores de campos y de decimales tiene. 
# Usaremos por convención el ; como separador de campos y el . como separador de decimales
# El archivo de muestra ya tiene el separador de campos como ; pero el de decimales es
# incorrecto, ya que usa , en lugar de .

# Ruta al archivo CSV ya fromateado correctamente
csv_formateado <- "datos_de_muestra/GPS/gps_blanco_formatted.csv"

# Ruta al archivo RDS ya formateado correctamente
rds_formateado <- "datos_de_muestra/GPS/gps_blanco_formatted.rds"

write.table(data, file = csv_formateado, sep = ";", dec = ".", row.names = FALSE, col.names = TRUE, quote = FALSE)

# Trabajamos con el fichero formateado correctamente para evitar posteriores problemas

vessel_track_df <- read_delim(csv_formateado, delim =";")

# Nos quedaremos solo con las variables que nos interesan del dataframe
# y las renombraremos

vessel_track_df <- vessel_track_df %>%
  select(-`Altitude(m)`, -`Visible Satellites`, -`Satellites(CN>22)`, -HDOP) %>%
  rename(SI_TIMESTAMP = Time, 
         SI_LATI = Latitude, 
         SI_LONG = Longitude, 
         SI_SP = `Speed(km/h)`, 
         SI_HE = Course, 
         SI_DISTANCE = `Distance(m)`)

# Cambiamos la fecha para que sea del tipo correcto
# y
# Cambiamos la velocidad instantánea de km/h a nudos
vessel_track_df <- vessel_track_df %>%
  mutate(SI_TIMESTAMP = ymd_hms(SI_TIMESTAMP, tz = "UTC")) %>%
  mutate(SI_SP = vessel_track_df$SI_SP*0.539957)



# Calculamos diferencias de tiempo y velocidades (en nudos)
# Al venir de GPS, los VE_REF de cada GPS han de ser los mismos, así
# que asumiremos una agrupacón por días

vessel_track_df <- vessel_track_df %>%
  group_by(floor_date(SI_TIMESTAMP, unit = 'day')) %>%
  mutate(
    SI_DISTANCECA = distHaversine(cbind(lag(SI_LONG), lag(SI_LATI)),cbind(SI_LONG, SI_LATI))) %>%
  mutate(
    SI_TDIFF = as.numeric(SI_TIMESTAMP - lag(SI_TIMESTAMP), units = "secs"),
    SI_SPCA = (SI_DISTANCECA / as.numeric(SI_TDIFF))*1.94384
  ) %>%
  ungroup() %>%
  select(-`floor_date(SI_TIMESTAMP, unit = "day")`)

# Convertimos las columnas de latitud y longitud a objetos "SpatialPoints"
## Código usando sp
#coords <- vessel_track_df %>%
#  select(SI_LONG, SI_LATI)
#points <- SpatialPoints(coords)

## Nuevo código para sf
coords <- vessel_track_df %>%
  select(SI_LONG, SI_LATI) %>%
  st_as_sf(coords = c("SI_LONG", "SI_LATI"), crs = 4326)

points <- st_as_sf(coords, coords = c("SI_LONG", "SI_LATI"), agr = "constant")

# Extract coordinates as a matrix
coords_matrix <- st_coordinates(points)

# Calculamos el rumbo medio entre puntos consecutivos. Se puede hacer de dos formas
# 1.
# USANDO bearing
# --------------
# Calcula el rumbo inicial (dirección; azimut) para ir del punto p1 al punto p2 (en longitud/latitud) 
# siguiendo el camino más corto en un elipsoide (geodésico). 
# Hay que tener en cuenta que el rumbo del viaje cambia continuamente a medida que avanza por el camino. 
# Una ruta con rumbo constante es una línea de rumbo.

#(sp) bearings <- bearing(points[-length(points)], points[-1])

bearings <- bearing(coords_matrix[-nrow(coords_matrix), ], coords_matrix[-1, ])

# 2.
# USANDO bearingsRhumb
#---------------------
# Calculo el rumbo (dirección de desplazamiento; rumbo verdadero) a lo largo de una línea de rumbo (loxódromica) entre dos puntos.
# A diferencia de la mayoría de los grandes círculos, una línea de rumbo es una línea de rumbo (dirección) constante, 
# es decir, trayectorias de rumbo verdadero constante. Los meridianos y el ecuador son a la vez líneas de rumbo y 
# círculos máximos. Las líneas de rumbo que se acercan a un polo se convierten en una espiral muy cerrada.

#(sp) bearingsRhumb <- bearingRhumb(points[-length(points)], points[-1])

bearingsRhumb <- bearingRhumb(coords_matrix[-nrow(coords_matrix), ], coords_matrix[-1, ])
# Añadimos la columna de bearings al dataframe original
vessel_track_df$SI_COG <- c(NA, if_else(bearings < 0, bearings + 360, bearings))
#vessel_track_df$SI_COG2 <- c(NA, bearingsRhumb)

# Eliminamos la primera fila ya que tendrá un NA creado al calcular la velocidad
vessel_track_df <- na.omit(vessel_track_df)

#### Añadimos columna para indicar si hay obervador o no (SU_ISOB) que por defecto es FALSE,
#### Si llevase observador se cambiaría por un TRUE.
#### En el caso del GPS añadimos también un código para el GPS. Se creará
#### de forma similar al FT_REF, añadiendo un _G_ en medio para diferenciarlos
#### EJEMPLOS:
####
#### SAN_G_0001
#### MAL_G_0044
#### etc...   

vessel_track_df <- vessel_track_df %>%
  mutate(SU_ISOB = 0, FT_REF = NA)

## Añadimos la columna para indicar si está equipado con OGT

vessel_track_df <- vessel_track_df %>%
  mutate(SI_OGT = 0)

# Añadimos las columnas que es necesario completar y estimar. Estas por defecto estarán vacías
#
# CFR
vessel_track_df$VE_REF <- NA
vessel_track_df$VE_REF <- as.factor(vessel_track_df$VE_REF)

# Marea
vessel_track_df$FT_REF <- NA
vessel_track_df$FT_REF <- as.factor(vessel_track_df$FT_REF)

# Arte
vessel_track_df$LE_MET4 <- NA
vessel_track_df$LE_MET4 <- as.factor(vessel_track_df$LE_MET4)

# Metier
vessel_track_df$LE_MET6 <- NA
vessel_track_df$LE_MET6 <- as.factor(vessel_track_df$LE_MET6)

# Estado
#
# PESCA: 1
# NO PESCA: 0 
vessel_track_df$SI_FSTATUS <- NA
vessel_track_df$SI_FSTATUS <- as.factor(vessel_track_df$SI_FSTATUS)

# Observador
# 
# Observador embarcado : 1
# Observador no embarcado: 0
vessel_track_df$SU_ISOB <- as.factor(vessel_track_df$SU_ISOB)

# OGT
#
# No equipado: 0
# Equipado: 1

vessel_track_df$SI_OGT <- as.factor(vessel_track_df$SI_OGT)

# En los GPS podríamos identificar también las operaciones de pesca
#
# LARGADA: SE
# VIRADA: HA
# ESPERA: WT (tiempo entre fin de largada e inicio de virada)
# NAVEGACION: ST
#
# Añadimos la culumna apropiada, que estará inicialmente vacía


vessel_track_df <- vessel_track_df %>%
  mutate(SI_FOPER = NA)

vessel_track_df$SI_FOPER <- as.factor(vessel_track_df$SI_FOPER)

# Nos quedamos con el dataframe ordenado como nos interesa

vessel_track_df <- vessel_track_df %>%
  select(VE_REF, FT_REF, SI_TIMESTAMP, SI_LATI, SI_LONG, SI_SP, SI_SPCA, SI_HE, 
         SI_COG, SI_DISTANCE, SI_DISTANCECA, SI_TDIFF, LE_MET4, LE_MET6, 
         SI_FSTATUS, SI_FOPER, SU_ISOB, SI_OGT)


# Podemos guardar ya el fichero en formato csv
write.table(vessel_track_df, file = csv_formateado, sep = ";", dec = ".", row.names = FALSE, col.names = TRUE, quote = FALSE)

# O en formato RDS (menos tamaño y 100% R)
saveRDS(vessel_track_df, file=rds_formateado)



### Podemos aplicar en enfoque espacial en el que añadiremos geometrías que 
### nos van a permitir realizar operaciones espaciales.
### Por ejemplo para saber que puntos del trayecto del barco están fuera del puerto

## Para evitar usar extract que a algunos les causa problemas vamos a hacerlo de otra manera
vessel_track_df$SI_LATI2 <- vessel_track_df$SI_LATI
vessel_track_df$SI_LONG2 <- vessel_track_df$SI_LONG

## Creamos un objeto espacial a partir de dataframe
vessel_track_sf <- st_as_sf(vessel_track_df, coords =  c("SI_LONG2", "SI_LATI2"), crs = 4326)

## Cargamos el fichero de Puertos, este es uno de este año, el que empezamos a
## crear nosotros
puertos_df <- read_csv("Puertos.csv")


## Creamos un objeto espacial con los datos del puerto, que será
## un círculo con centro el las coordenadas del puerto y radio el RANGO
## De esta forma puertos_sf contiene polígonos circulares en la columna de geometría
puertos_sf <- st_as_sf(puertos_df, coords = c("LON", "LAT"), crs = 4326)

puertos_sf <- st_buffer(puertos_sf, dist = puertos_sf$RANGO*1000)


## Buscamos los puntos de las trayectorias del barco que intersectan con
## los púntos del círculo del puerto. En nuestro caso, como queremos los que está fuera
## necesitamos los de longitud cero (no intersecta)

vessel_tracks_outside_ports <- vessel_track_sf[lengths(st_intersects(vessel_track_sf, puertos_sf)) == 0,]

## Podemos comprobar los que estan dentro del puerto. Si está todo correcto, la suma de las filas
## de los que están dentro y los que están fuera ha de ser igual a las filas de las
## trayectorias de los barcos
## En este caso, nuestro ejemplo tiene 57 filas. Puntos fuera del puerto 54, puntos
## dentro del puerto 3. Suma 57, correcto
vessel_tracks_inside_ports <- vessel_track_sf[lengths(st_intersects(vessel_track_sf, puertos_sf)) != 0,]

# Y podemos añadir la columna indicando si están dentro o fuera del puerto
# SI_HARB (0 = en puerto, 1 = en mar)

vessel_tracks_outside_ports$SI_HARB = 1
vessel_tracks_inside_ports$SI_HARB = 0

vessel_track_sf_in_out <- rbind(vessel_tracks_outside_ports, vessel_tracks_inside_ports)

vessel_track_sf_in_out <- vessel_track_sf_in_out %>%
  arrange(SI_TIMESTAMP)

# Podemos extrar de la geometría la latitud y la longitud para volverlo a incorporar
# a nuestro dataframe
## Si usamos la aproximación de las líneas 198 a 202 no es necesario
## 
#vessel_track_sf_in_out <- extract(vessel_track_sf_in_out, geometry, into = c('SI_LATI', 'SI_LONG'), '\\((.*),(.*)\\)', conv = TRUE)

#vessel_track_sf_in_out <- vessel_track_sf_in_out[, 1:(length(vessel_track_sf_in_out)-1)]
# 
# vessel_track_sf_in_out$geometry_sf <- vessel_track_sf_in_out$geometry %>% 
#   st_sf %>% 
#   st_cast(.,"POINT") 


# Reordenamos el dataframe y lo guardamos, finalizando aquí

col_order <- c("VE_REF", "FT_REF", "SI_TIMESTAMP", "SI_LATI", "SI_LONG", "SI_SP", "SI_SPCA", "SI_HE", "SI_COG", "SI_DISTANCECA", 
               "SI_TDIFF", "LE_MET4", "LE_MET6", "SI_HARB", "SI_FSTATUS", "geometry", "SI_FOPER", "SU_ISOB", "SI_OGT", "SI_DISTANCE")

vessel_track_sf_final <- vessel_track_sf_in_out[, col_order]

write.table(vessel_track_sf_final, file = "datos_de_muestra/GPS/gps_blanco_formatted_final.csv", 
            sep = ";", dec = ".", row.names = FALSE, col.names = TRUE, quote = FALSE, na ="")
saveRDS(vessel_track_sf_final, file = "datos_de_muestra/GPS/gps_blanco_formatted_final.rds")

