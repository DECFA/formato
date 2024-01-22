setwd("/home/danielc/TEPESCO/git/formato/operaciones/")
library(dplyr)
library(lubridate)
uno <- readRDS("ESP000004365_06082023_16082023_B_formatted.rds")
dos <- readRDS("ESP000015362_25092023_06102023_B_formatted.rds")
tres <- readRDS("ESP000015608_11082023_22082023_B_formatted.rds")
cuatro <- readRDS("ESP000022251_30072023_03082023_B_formatted.rds")

gps <- rbind(uno, dos, tres, cuatro)
gps$SI_DATE <- date(gps$SI_TIMESTAMP)
diario <- read.table(file = "rutas_gps.csv", sep = ";", dec=".", header = T)
diario$Fecha <- date(diario$Fecha)
gps <- gps %>% 
  group_by(VE_REF, SI_DATE) %>%
  mutate(FT_REF = sprintf("MUR_%04d", first(cur_group_id()))) %>%
  ungroup()

assign_operation <- function(gps, diario, timezone ="UTC") {
  # Convert timestamps to POSIXct format
  #gps$DateTime <- as.POSIXct(paste(gps$SI_DATE, gps$SI_TIME), format="%Y-%m-%d %H:%M:%S", tz=timezone)
  
  # Aggregate diario data
  diario_aggregated <- diario %>%
    group_by(CFR, Fecha, GEAR) %>%
    reframe(
      se_1_dt = min(as.POSIXct(paste(fec_cal, ini_largada), format="%Y-%m-%d %H:%M", tz=timezone)),
      se_2_dt = max(as.POSIXct(paste(fec_cal, fin_largada), format="%Y-%m-%d %H:%M", tz=timezone)),
      ha_1_dt = min(as.POSIXct(paste(fec_vir, ini_virada), format="%Y-%m-%d %H:%M", tz=timezone)),
      ha_2_dt = max(as.POSIXct(paste(fec_vir, fin_virada), format="%Y-%m-%d %H:%M", tz=timezone))
    )
  
  # Perform the operation
  result <- gps %>%
    left_join(diario_aggregated, by = c("VE_REF"="CFR", "SI_DATE"="Fecha"), relationship = "many-to-many") %>%
    group_by(VE_REF, SI_DATE, GEAR) %>%
    mutate(
      SI_FOPER = case_when(
        SI_TIMESTAMP < se_1_dt | SI_TIMESTAMP > ha_2_dt ~ "ST",
        SI_TIMESTAMP >= se_1_dt & SI_TIMESTAMP <= se_2_dt ~ "SE",
        SI_TIMESTAMP >= ha_1_dt & SI_TIMESTAMP <= ha_2_dt ~ "HA",
        SI_TIMESTAMP > se_2_dt & SI_TIMESTAMP < ha_1_dt ~ "WT",
        TRUE ~ "UN"
      ),
      SI_FOPER = as.factor(SI_FOPER),
      SI_FSTATUS = if_else(SI_FOPER %in% c("SE", "HA", "WT"), "Y", "N")
    ) %>%
    ungroup()  # Remove grouping
  
  return(result)
}

op_assigned_df <- assign_operation(gps, diario, timezone="Europe/Madrid")
op_assigned_df$LE_MET4 <- op_assigned_df$GEAR
# replace all NA values in the LE_MET4 column with NK
op_assigned_df$LE_MET4 <- replace(op_assigned_df$LE_MET4, is.na(op_assigned_df$LE_MET4), "NK")
op_assigned_df$GEAR <- as.factor(op_assigned_df$GEAR)

op_assigned_df <- op_assigned_df |>
  select(-c(GEAR, SI_DATE, se_1_dt, se_2_dt, ha_1_dt, ha_2_dt))

op_assigned_df$SI_OGT <- if_else(op_assigned_df$SI_OGT == 0, FALSE, TRUE)
op_assigned_df$SI_HARB <- if_else(op_assigned_df$SI_HARB == 0, FALSE, TRUE)
op_assigned_df$SU_ISOB <- if_else(op_assigned_df$VE_REF == "ESP000022251", FALSE, TRUE)
op_assigned_df$SI_FSTATUS <- if_else(op_assigned_df$SI_FSTATUS == "Y", TRUE, FALSE)

col_order <- c(
  "VE_REF", "FT_REF", "SI_TIMESTAMP", "SI_LATI", "SI_LONG", "SI_SP", "SI_SPCA",
  "SI_HE", "SI_COG", "SI_DISTANCECA", "SI_TDIFF", "LE_MET4", "LE_MET6",
  "SI_HARB", "SI_FSTATUS", "geometry", "SI_FOPER", "SU_ISOB", "SI_OGT"
)

op_assigned_df <- op_assigned_df[, col_order]

write.table(op_assigned_df,
            file = "test_gps_bbdd.csv",
            sep = ";", dec = ".", row.names = FALSE, col.names = TRUE,
            quote = FALSE, na = ""
)
saveRDS(op_assigned_df,
        file = "test_gps_bbdd.rds")

