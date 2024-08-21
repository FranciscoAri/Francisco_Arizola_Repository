################################################################################
######################### ANÁLISIS TEXTUAL EN R ################################
################################################################################

# Elaborado por: Francisco Arizola

# Este script trabaja con el archivo 'canciones', el cual contiene información de
# canciones en Spotify de diversos géneros musicales y artistas entre 2017-2022.

# Cargar los paquetes necesarios
library(tidytext)
library(dplyr)
library(readxl)
library(ggplot2)
library(textdata)
library(rtweet)
library(tidyverse)
library(wordcloud)
library(reshape2)
library(RColorBrewer)
library(tm)
library(writexl)
library(quanteda)
library(quanteda.textmodels)
library(quanteda.textstats)
library(quanteda.textplots)
library(topicmodels)

########### 1. Limpieza, procesamiento y transformación de datos ###############

# Configurar el directorio de trabajo
setwd("C:/Users/Franc/OneDrive/Escritorio/Análisis_textual_R")

# Cargar y preparar los datos
data <- read_excel("canciones.xlsx", skip=1, col_names = FALSE)
data

# Renombramos las variables
names(data) <- c('canciones', 'artistas', "Sexo", "Género", 'Nacionalidad', 'years', 'link',
                 'letra')
head(data)

# Convirtiendo las variables en factores 
levels(as.factor(data$Nacionalidad))
levels(as.factor(data$Género))

# Ver la frecuencia de cada género
table(data$Género)

# Correjimos el error en los géneros Reggeaton y Dance pop
data$Género <- data$Género |>  str_replace_all("Reggaeton","Reggeaton")
data$Género <- data$Género |>  str_replace_all("Dancepop","Dance pop")
table(data$Género)

# Eliminamos observaciones duplicadas
data <- distinct(data, canciones, .keep_all = TRUE)

# Creamos el corpus
data_corpus <- corpus(data, text_field = "letra")
class(data_corpus)
print(data_corpus) 

# Ver un resumen
head(summary(data_corpus))
head(docvars(data_corpus))

# Remover puntuación y stopwords, y separar palabras unidas por guiones
toks <- tokens(data_corpus, remove_punct = TRUE) |>
  tokens_remove(pattern = stopwords("es")) |>
  tokens_remove(pattern = stopwords("en")) |>
  tokens(data_corpus, split_hyphens = TRUE) |>
  # Filtrar los tokens que tienen 4 caracteres o más
  tokens_select(pattern = "^[A-Za-záéíóúñ]{4,}$", valuetype = "regex")
print(toks)

# Convertir todos los tokens a minúsculas
toks <- tokens_tolower(toks)
print(toks)

# ----------------------------  Stemming ------------------------------------- #
# Instala el paquete 'SnowballC' para aplicar stemming en diferentes idiomas.
install.packages("SnowballC")
library(SnowballC)

# Aplicar stemming (quedarse con las raíces de las palabras)
toks_stem <- tokens_wordstem(toks, language = "spanish")
print(toks_stem)

################## 2. Document frecuency matrix (DFM) ##########################

# Crear el dfm
dfm <- dfm(toks)
print(dfm)

# Mostrar las 10 palabras más frecuentes
print(topfeatures(dfm,10))

# Buscar el contexto de la palabra "quiero" dentro del corpus (key word context)
kwc_quiero <- kwic(toks, pattern = "quiero*")
print(head(kwc_quiero,10))

# Mostrar las palabras más frecuentes por género y artista
print(head(topfeatures(dfm, 5, groups = Género)))
print(head(topfeatures(dfm, 5, groups = Sexo)))

# Se puede ver la frecuencia en general o por en cuántos documentos aparece
print(head(topfeatures(dfm, 5, scheme = "count")))
print(head(topfeatures(dfm, 5, scheme = "docfreq")))

# --------------------- Otras funciones adicionales ---------------------------#
# Recorta la DFM eliminando los términos que no aparecen al menos 20 veces.
dfm_trim(dfm, min_termfreq = 20)

# Selecciona los términos en la DFM que tienen al menos 10 caracteres.
dfm_select(dfm, min_nchar = 10)

# Recorta la DFM eliminando los términos que no aparecen en al menos el 30% de los documentos.
dfm_trim(dfm, min_docfreq = 0.30, docfreq_type = "prop")

######################## 3. Estadística Descriptiva ############################

# --------------------------- Nubes de palabras -------------------------------#
# Abre un dispositivo gráfico PNG
png("wordcloud.png", width = 800, height = 600)

# Crea una nube de palabras básica con un máximo de 150 palabras y color azul
cloud_basic <- textplot_wordcloud(dfm,
                                  max_words = 150, color = c("blue"),
                                  labelcolor = "black")

# Cierra el dispositivo gráfico para guardar el archivo
dev.off()

# Ahora existe una librería más reciente para armar una nube de palabras: "wordcloud2"
install.packages("wordcloud2")
library(wordcloud2)

# Convertir dfm a un formato compatible para wordcloud2
word_freqs <- textstat_frequency(dfm)

# Crear la nube de palabras
wordcloud2(word_freqs, color = "random-light", backgroundColor = "white")

# Mostrar los géneros musicales más frecuentes
table(dfm$Género)

# Agrupa la DFM por género y filtra los 4 más frecuentes
dfm_genero <- dfm |> 
  dfm_group(groups = Género) |>
  dfm_subset(Género == "Reggeaton" | Género == "Latin Pop" | Género == "Pop" | Género == "Trap")
dfm_genero

# Crea una nube de palabras comparativa para los géneros
cloud_genero <- textplot_wordcloud(dfm_genero, comparison = TRUE,
                                   max_words = 160, 
                                   color = c("blue", "red", "yellow", "green"), 
                                   labelcolor = "black")

# --------------------------- Diversidad léxica -------------------------------#
# Agrupa el dfm por género (nuevamente)
dfm_genero <- dfm |> 
  dfm_group(groups = Género)

# Calcula el TTR para cada género
diversity_by_genre <- textstat_lexdiv(dfm_genero, measure = "TTR") |>
  # Ordena los géneros de mayor a menor TTR
  arrange(desc(TTR)) |>
  # Renombrar la columna de "document" a "Género"
  rename(Género = document)

# Crea un gráfico de barras ordenado
ggplot(diversity_by_genre, aes(x = reorder(Género, -TTR), y = TTR, fill = Género)) +
  geom_bar(stat = "identity") +
  labs(x = "Género Musical", y = "Diversidad léxica") +
  ggtitle("Diversidad Léxica por Género Musical (TTR)") +
  theme_minimal() +
  theme(legend.position = "none") +
  theme(axis.text.x = element_text(angle = 90, hjust = 0.5))

# Ahora evaluamos diversidad léxica por sexo
# Calcula el TTR para cada documento en el dfm
div_lexica <- textstat_lexdiv(dfm, measure = "TTR")

# Añade la variable "Sexo" al data frame de diversidad léxica
div_lexica$Sexo <- docvars(dfm, "Sexo")

# Crea un gráfico de cajas para mostrar la diversidad léxica por Sexo
ggplot(div_lexica, aes(x = Sexo, y = TTR, fill = Sexo)) +
  geom_boxplot() +
  labs(x = "Sexo", y = "TTR (Type-Token Ratio)") +
  ggtitle("Diversidad Léxica por Sexo (TTR)") +
  theme_minimal()

# ------------------- Palabras más utilizadas por año -------------------------#
# Agrupa el dfm por años
dfm_years <- dfm_group(dfm, groups = years)

# Convierte el dfm agrupado en un data frame de frecuencias
word_frequencies <- textstat_frequency(dfm_years, n = 3, groups = years)

# Filtra solo las 3 palabras más frecuentes por cada año
top_words_per_year <- word_frequencies %>%
  group_by(group) %>%
  top_n(3, wt = frequency)

# Crea un gráfico de barras con etiquetas de datos más pequeñas
ggplot(top_words_per_year, aes(x = reorder(feature, -frequency), y = frequency, fill = feature)) +
  geom_bar(stat = "identity") +
  facet_wrap(~ group, scales = "free_x") +  # Crea un panel para cada grupo
  geom_text(aes(label = frequency), vjust = -0.3, color = "black", size = 2) +  # Agrega etiquetas de datos con tamaño de fuente más pequeño
  labs(x = "Palabras", y = "Frecuencia", title = "Top 3 Palabras Más Utilizadas por Año") +
  theme_minimal() +
  theme(legend.position = "none")

########################### 4. Topic Modeling ##################################

# Convierte la matriz de documentos y términos al formato para topic modeling
dfm_tm <- convert(dfm, to = "topicmodels")
class(dfm_tm)

# Configura la semilla para reproducibilidad y ajusta un modelo LDA con 20 tópicos
set.seed(2)
tmod_20 <- LDA(dfm_tm,
               k = 10,
               method = "Gibbs",
               control = list(alpha = 0.02, delta = 0.02))
terms(tmod_20, 15)

# Extrae y visualiza los términos más relevantes para el modelo con 20 tópicos
topics <- tidytext::tidy(tmod_20, matrix = "beta")
head(topics)

# Indicamos las 4 palabras más frecuentes por tópico
topterms <-
  topics %>%
  group_by(topic) %>%
  top_n(4, beta) %>%
  ungroup() %>%
  arrange(topic, -beta)
head(topterms)

# Nota: Debe agrandar el gráfico o hacer zoom para verlo apropiadamente
topterms %>%
  mutate(term = reorder(term, beta)) %>%
  ggplot(aes(term, beta, fill = factor(topic))) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ topic, scales = "free") +
  coord_flip()

######################### 5. Análisis adicional ################################

# ------- ¿Qué tanto repiten su nombre los artistas en sus canciones? ---------#
# Convertir la columna 'artista' a minúsculas
data$artistas <- tolower(data$artistas)
table(data$artistas)

# Crear un dataframe con el conteo de menciones del nombre del artista
count_artist_mentions <- function(tokens, artist_name) {
  sum(tokens %>% tokens_select(pattern = artist_name) %>% lengths())
}

# Inicializamos un dataframe para almacenar los conteos
artist_mentions <- data.frame(artista = character(), menciones = numeric(), stringsAsFactors = FALSE)

# Convertir la columna 'artistas' en minúsculas y limpiar los nombres
data$artistas <- tolower(data$artistas)
data$artistas <- gsub(" feat | feat. | & | / ", ";", data$artistas)  # Reemplaza delimitadores por ";"

# Contar las menciones del nombre del artista en sus propias canciones
for (row in 1:nrow(data)) {
  # Obtener los nombres de los artistas
  artists <- unlist(strsplit(data$artistas[row], ";"))
  
  # Crear el corpus y tokens para las letras del artista
  artist_corpus <- corpus(data[row, ], text_field = "letra")
  artist_tokens <- tokens(artist_corpus, remove_punct = TRUE) |>
    tokens_remove(pattern = stopwords("es")) |>
    tokens_remove(pattern = stopwords("en")) |>
    tokens_select(pattern = "^[A-Za-záéíóúñ]{4,}$", valuetype = "regex") |>
    tokens_tolower()
  
  # Contar menciones para cada artista individualmente
  for (artist in artists) {
    mentions <- count_artist_mentions(artist_tokens, artist)
    
    # Añadir el resultado al dataframe
    artist_mentions <- rbind(artist_mentions, data.frame(artista = artist, menciones = mentions, stringsAsFactors = FALSE))
  }
}

# Calcular el promedio de menciones por canción para cada artista
artist_mentions_avg <- artist_mentions %>%
  group_by(artista) %>%
  summarise(menciones_promedio = mean(menciones, na.rm = TRUE)) %>%
  arrange(desc(menciones_promedio))

# Mostrar los resultados
print(artist_mentions_avg, n = 20)

# Limitar los resultados a los 12 artistas con más menciones promedio
top_12_artists <- artist_mentions_avg %>%
  slice_max(order_by = menciones_promedio, n = 12)

# Crear el gráfico
ggplot(top_12_artists, aes(x = reorder(artista, menciones_promedio), y = menciones_promedio)) +
  geom_bar(stat = "identity", fill = "skyblue") +
  coord_flip() +
  labs(x = "Artista", y = "Promedio de menciones por canción", title = "Promedio de veces que los artistas mencionan su propio nombre en sus canciones (Top 12)") +
  theme_minimal()
