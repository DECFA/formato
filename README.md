# Formateado de GPS y cajas verdes
Scripts para el crear el formato adecuado a los GPS y las cajas verdes

Para homogeineizar la salida de los scripts y que todos los formatos producidos sean iguales, las columnas creadas para todos los tipos de entrada son las mismas.
La siguiente tabla muestra las variables generadas, así como el significado de cada variable, el tipo de valor que se espera para cada una y si dicha variable puede contener NA's o no.

| Variable |Descripción| Tipo | NA |
|:--------:|:----:|:--:|:--:|
|VE_REF|CFR del Barco<br>ESP000XXXXX o ESP0000XXXX|factor (*fct*)|NO|
|FT_REF|Código de marea|factor (*fct*)|SI|
|SI_TIMESTAMP|Fecha y hora <br> YYYY-MM-DD HH:MM:SS|datetime (*dttm*)|NO|
|SI_LATI|Latitud decimal|numeric (*dbl*)|NO|
|SI_LONG|Longitud decimal|numeric (*dbl*)|NO|
|SI_SP|velocidad (instantánea)|numeric (*dbl*)|NO|
|SI_SPCA|velocidad media (calculada)|numeric (*dbl*)|NO|
|SI_HE|Rumbo (instantáneo)|numeric (*dbl*)|NO|
|SI_COG|Course Over Ground (calculado)|numeric (*dbl*)|NO|
|SI_DISTANCECA|Distancia entre dos puntos <br> consecutivos (calculada)|numeric (*dbl*)|NO|
|SI_TDIFF|Tiempo en segundos entre dos<br>puntos consecutivos (calculado)|numeric (*dbl*)|NO|
|LE_MET4|Metier nivel 4<br>OTB, LLS ...|factor (*fct*)|NO|
|LE_MET6|Metier nivel 6<br>LLS_DEF_0_0_0, GNS_DEF_50-59_0_0 ...|factor (*fct*)|SI|
|SI_HARB|En puerto (FALSE) o en mar (TRUE)| factor (*fct*)|NO|
|SI_FSTATUS|Pescando (TRUE) o no pescando (FALSE)|factor (*fct*)|SI|
|geometry||geometria (POINT)|NO|
|SI_FOPER|Maniobra del barco<br>ST: Navegando (Steaming)<br>WT: Espera (Waiting)<br>SE: Largando (Setting)<br>HA: Virando (Hauling)|factor (*fct*)|SI|
|SU_ISOB|Observador a bordo (TRUE) o no (FALSE)|factor (*fct*)|SI|
|SI_OGT|Equipado con un O.G.T. (TRUE) o no (FALSE)|factor (*fct*)|SI|
