# Convierte un registro Sleep-EDF (EEG Fpz-Cz, 100 Hz) en una serie de tiempo
# de potencia relativa por banda en épocas de 30 s, junto con la etapa de sueño.
# Datos: Sleep-EDF Database Expanded (PhysioNet, ODC-By 1.0), sujeto SC4001.
library(edfReader)

psg_file <- "data/raw_s3/SC4001E0-PSG.edf"
hyp_file <- "data/raw_s3/SC4001EC-Hypnogram.edf"

# --- EEG ---------------------------------------------------------------------
psg_hdr <- readEdfHeader(psg_file)
eeg <- readEdfSignals(psg_hdr, signals = "EEG Fpz-Cz")
fs <- eeg$sRate                       # 100 Hz
epoca <- 30 * fs                      # 3000 muestras por época
n_ep <- floor(length(eeg$signal) / epoca)

bandas <- list(delta = c(0.5, 4), theta = c(4, 8), alfa = c(8, 12),
               sigma = c(12, 15), beta = c(15, 30))

potencia <- t(sapply(seq_len(n_ep), function(i) {
  x <- eeg$signal[((i - 1) * epoca + 1):(i * epoca)]
  sp <- spec.pgram(x, taper = 0.1, detrend = TRUE, plot = FALSE,
                   spans = c(5, 5))
  f <- sp$freq * fs
  total <- sum(sp$spec[f >= 0.5 & f < 30])
  sapply(bandas, function(b) sum(sp$spec[f >= b[1] & f < b[2]]) / total)
}))

# --- Hipnograma (anotaciones EDF+) -------------------------------------------
hyp_hdr <- readEdfHeader(hyp_file)
anot <- readEdfSignals(hyp_hdr)$annotations
anot <- anot[grepl("^Sleep stage", anot$annotation), ]
etapa <- rep(NA_character_, n_ep)
for (k in seq_len(nrow(anot))) {
  ini <- floor(anot$onset[k] / 30) + 1
  fin <- min(n_ep, ini + round(anot$duration[k] / 30) - 1)
  if (ini <= n_ep) etapa[ini:fin] <- sub("Sleep stage ", "", anot$annotation[k])
}
etapa <- c(W = "Vigilia", `1` = "N1", `2` = "N2", `3` = "N3", `4` = "N3",
           R = "REM", `?` = NA)[etapa]

datos <- data.frame(epoca = seq_len(n_ep), round(potencia, 4),
                    etapa = unname(etapa))

# Se conserva el periodo de sueño ±30 min (práctica habitual con Sleep-EDF,
# que incluye muchas horas de vigilia antes y después de dormir)
dormido <- which(!is.na(datos$etapa) & datos$etapa != "Vigilia")
rango <- max(1, min(dormido) - 60):min(n_ep, max(dormido) + 60)
datos <- datos[rango, ]
datos$hora <- round((datos$epoca - datos$epoca[1]) * 30 / 3600, 4)

write.csv(datos, "data/sc4001_epocas.csv", row.names = FALSE)
cat("Épocas:", nrow(datos), "| horas:", round(nrow(datos) / 120, 1), "\n")
print(table(datos$etapa, useNA = "ifany"))
