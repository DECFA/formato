# Scripts relacionados con la identificación de las operaciones de pesca
## gps_match_oper.R
A partir de ficheros de GPS correctamente formateados y contando con un diario o rutas de gps (`rutas_gps.csv`) en las que están marcadas las operaciones de largada y virada, asigna a cada punto uno de los posibles valores:
- Navegación (ST)
- Largada (SE)
- Virada (HA)
- Espera (WT)
- Desconocido (UN)

Además asigna NK como metier nivel 4 (le_met4) en caso de que el campo esté vacío.

**NOTA** En la línea 34:
```r
left_join(diario_aggregated, by = c("VE_REF"="CFR", "SI_DATE"="Fecha"), relationship = "many-to-many")
```
según versiones el parámetro *relationship = "many-to-many"* que está puesto para evitar warnings puede causar un error. Si es así, basta con eliminarlo.

## crear_diario_desde_ogt.R
A patir de los datos de los GPS de los OGT crea un fichero con rutas de gps igual que el anteriormente mencionado `rutas_gps.csv` llamado para diferenciarlos `diario.csv`. Con este diario se puede usar el script anterior para procesar los datos de la misma forma.
