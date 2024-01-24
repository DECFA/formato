# Load libraries
library(lubridate)
library(hms)
# Load ogt1 and ogt2 data into separate dataframes
ogt1 <- read.csv2("/home/danielc/TEPESCO/Test OGT/ogt1.csv")
ogt2 <- read.csv2("/home/danielc/TEPESCO/Test OGT/ogt2.csv")


# Set the threshold for SI_TDIFF
threshold <- 600

# Function to extract required information
extract_info <- function(df1, df2, threshold) {
  
  # Find rows where SI_TDIFF is larger than the threshold
  interesting_rows1 <- which(df1$SI_TDIFF > threshold)
  interesting_rows2 <- which(df2$SI_TDIFF > threshold)
  
  # Initialize the variables
  fec_cal <- as.Date(df1$SI_TIMESTAMP[interesting_rows1 -1], format = "%Y-%m-%d")
  ini_largada <- as.POSIXct(df1$SI_TIMESTAMP[interesting_rows1 - 1])
  fin_largada <- as.POSIXct(df2$SI_TIMESTAMP[interesting_rows2 -1])
  fec_vir <- as.Date(df2$SI_TIMESTAMP[interesting_rows2 -1], format = "%Y-%m-%d")
  ini_virada <- as.POSIXct(df2$SI_TIMESTAMP[interesting_rows2])
  fin_virada <- as.POSIXct(df1$SI_TIMESTAMP[interesting_rows1])
  
  # Create a data frame
  diario <- data.frame(
    Fecha = as.Date(fec_cal, format = "%Y-%m-%d %H:%M:%S"),
    fec_cal = as.Date(fec_cal, format = "%Y-%m-%d"),
    ini_largada = as_hms(ymd_hms(ini_largada)),
    fin_largada = as_hms(ymd_hms(fin_largada)),
    fec_vir = as.Date(fec_vir, format = "%Y-%m-%d %H:%M:%S"),
    ini_virada = as_hms(ymd_hms(ini_virada)),
    fin_virada = as_hms(ymd_hms(fin_virada))
  )
  
  return(diario)
}

diario <- extract_info(ogt1, ogt2, threshold)

write.table(diario,
            file = "/home/danielc/TEPESCO/Test OGT/diario.csv",
            sep = ";", dec = ".", row.names = FALSE, col.names = TRUE,
            quote = FALSE, na = ""
)
saveRDS(diario,
        file = "/home/danielc/TEPESCO/Test OGT/diario.rds")
