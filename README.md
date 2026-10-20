# Propuesta Bookdown — Pronóstico de la dinámica del sueño con EEG (Sleep-EDF)

Propuesta de una página para el curso **Series Temporales** (Maestría en Ciencia de Datos, UNIFRANZ).

- HTML: `docs/index.html` · PDF: `docs/propuesta-eeg-sueno.pdf`
- Datos: Sleep-EDF Database Expanded v1.0.0 (PhysioNet, doi:10.13026/C2X676), licencia **ODC-By 1.0**.
- `data/preparar_datos.R` lee el EDF del sujeto SC4001 y genera `data/sc4001_epocas.csv`
  (potencia relativa por banda en épocas de 30 s + etapa de sueño). Los EDF originales
  no se suben al repositorio (ver `.gitignore`); se descargan con:
  ```bash
  B=https://physionet-open.s3.amazonaws.com/sleep-edfx/1.0.0/sleep-cassette
  mkdir -p data/raw_s3 && cd data/raw_s3 && curl -O $B/SC4001E0-PSG.edf -O $B/SC4001EC-Hypnogram.edf
  ```

## Compilar

```r
bookdown::render_book("index.Rmd", "bookdown::pdf_document2")
bookdown::render_book("index.Rmd", "bookdown::gitbook")
file.copy("docs/propuesta-eeg-sueno.html", "docs/index.html", overwrite = TRUE)
```

## Publicar en GitHub Pages

```bash
git add . && git add -f docs/.nojekyll
git commit -m "Propuesta bookdown EEG"
git branch -M main
git remote add origin https://github.com/<usuario>/propuesta-eeg-sleepedf.git
git push -u origin main
```
En GitHub: **Settings → Pages → Deploy from a branch → `main` / `/docs`**.
