##########################################################################################
#### ELABORACIÓN DE GRAFICA DE DE FRECUENCIA DE CATEGORIAS DE EXPOSICION DEL IUV MAXIMO #########
##########################################################################################

# Si has instalado R por primera vez se recomienda instalar la herramienta RTools, que sera importante para evitar
# errores en la instalacion de algunas librerias, mayor información puedes ver la siguiente página: https://cran.r-project.org/bin/windows/Rtools/ 

##### INSTALACION DE LIBRERIAS #####
# En caso de no contar con las siguientes librerias instaladas, primero deben ser instaladas.
# Lista de librerías necesarias

librerias <- c("readxl", "magrittr", "tidyverse", "openair","stringi","reshape2")

# Verifica e instala aquellas librerias que faltan
for (lib in librerias) {
  if (!require(lib, character.only = TRUE)) {
    install.packages(lib, dependencies = TRUE)
  }
}

#### ACTIVACION DE LIBRERIA ####
# Una vez instaldas las librerias, se procede a activarlas como sigue a continuaci?n

library(readxl)    # Permite abrir archivos de hoja de calculo excel
library(magrittr)  # permite utilizar pipetas ( |> ) para unir funciones 
library(tidyverse) # Tiene multiples paquetes para la manipulacion de tablas, entre otros
library(openair)   # Permite realizar promedios moviles de una variable y obtener estadisticos
library(reshape2)

##### IMPORTACION DE DATOS AL MINUTO DEL IUV #####
# Definir en la maquina local la ruta o dirección la carpeta de trabajo, en donde se encontrará el archivo excel 
# de los datos de radiación UV y colocarlo en la l?nea siguiente entre parentesis

setwd(r"(C:\boletin_ruv)")

# Importar el archivo de datos de radiación con el mismo nombre con el que se encuentra creado
# De aqui en adelante se recomienda que el archivo a importar tenga el contenido estructurado como el archivo
# denominado data_radiacion.xlsx

datos<-read_excel('data_radiacion.xlsx')

#Cambiar la columna "date" de un formato caracter a formato fecha
datos <-  datos |>  mutate(date=as.POSIXct(date))

############  ESTIMACIÓN DEL IUV MÁXIMO DIARIO ##########
# Realizar el promedio de cada 30 minutos del IUV
# indicar el nombre de la columna que tiene los datos del IUV , en este caso corresponde a "Indice_UV_Avg"
# podemos indicar una nueva columna a crear con los promedios, por ejemplo "IUV_MM"

datos_iuv <- openair::rollingMean(datos,"Indice_UV_Avg",width = 30,new.name = "IUV_MM",
                                  align = "right",data.thresh = 100)

# Estimar el máximo promedio de cada 30 minutos del IUV por  día
datos_iuv <- openair::timeAverage(datos_iuv,avg.time = "day",statistic = "max")

# Transformar el dataframe de datos de radiacion UV de un formato corto a un formato largo
df <- reshape2::melt(datos_iuv,id.vars="date")

########### PREPARACION DE DATOS PARA GRAFICAR #######

#Clasificar los datos de acuerdo a la decadiaria que pertenecen segun el día

df$dia <- as.numeric(format(df$date, "%d")) #Crear una columnna del número de día

df <- df |>  mutate(decadiario = ifelse(dia<11,'Decadaria I', 
                                               ifelse(dia<21,'Decadaria II','Decadaria III')))

df <- df |>  filter(variable=="IUV_MM") # Filtrar la variable de interes

df <- df |>  rename("IUV"="value") |> # renombrar la variable de interes
  mutate(IUV = round(IUV,0)) # redondear los valores a numero entero en otra variable

#df$IUV <- round(df$IUV,0) 
# Clasificar los datos de IUV según la categoria de exposicion a la que pertenecen
df$categoria <- ifelse(df$IUV<=2,"Baja",
                          ifelse(df$IUV>2.0001 & df$IUV<=5,"Moderada",
                                 ifelse(df$IUV>5.0001 & df$IUV<=7,"Alta",
                                        ifelse(df$IUV>7.0001 & df$IUV<=10,"Muy Alta","Extremadamente Alta")))) 

# Crear un dataframe de resumen de la cantidad de dias por categoria en cada decadiaria
resumen = aggregate(. ~ categoria + decadiario, data = df, FUN = length)
resumen = resumen %>% select(.,"categoria","dia","decadiario")

# Calcular el porcentaje que le corresponde a esa cantidad de días respecto al total de días por decadiaria
resumen$porcentaje = rep(NA,nrow(resumen))

resumen = resumen %>% 
  mutate(porcentaje = if_else(decadiario == "Decadaria I", round((dia/10)*100,2), porcentaje))

resumen = resumen %>% 
  mutate(porcentaje = if_else(decadiario == "Decadaria II", round((dia/10)*100,2), porcentaje)) 

resumen = resumen %>% 
  mutate(porcentaje = if_else(decadiario == "Decadaria III", round((dia/11)*100,2), porcentaje)) #dependiendo de los dias del mes puede ser 10,11 u 8

resumen

write.csv(resumen,"porcentaje_iuv.csv",row.names = F) #Puedes guardar el resultado de manera opcional como un archivo .csv


######### REALIZAR LA GRAFICA DE FRECUENCIA DE CATEGORIAS DE EXPOSICION DEL IUV MAXIMO #####

resumen$categoria<- factor(resumen$categoria, levels = c("Extremadamente Alta", "Muy Alta", 
                                                         "Alta")) #definir el orden de categorias, si hubiese mas categorias incluir

IUV_FREC<- resumen %>% ggplot(aes(x=decadiario, y=porcentaje, fill=categoria)) +
  geom_bar(stat="identity", 
           width = 0.5) + #graficar las barras que representan la frecuencia de cada categoria
  theme_bw() +
  theme(axis.title = element_text(colour = "black", size = 16, face = "bold"),
        panel.grid = element_line(color = "#636363", linewidth = 0.2),
        panel.grid.minor = element_blank(),
        axis.title.x = element_blank(),
        axis.title.y = element_text(margin = unit(c(0.5, 0.5, 0.5, 0.5), "cm")),
        axis.text.x = element_text(size = 13, color = "#262626", face = "bold", 
                                   margin = unit(c(0.1, 0.1, 0.1, 0.1), "cm")),
        axis.text.y = element_text(size = 12, color = "#262626", face = "bold", 
                                   margin = unit(c(0.1, 0.1, 0.1, 0.1), "cm")),
        legend.title = element_text(size = 12, face = "bold"),
        legend.text = element_text(size = 12),
        legend.spacing = unit(0, "cm")) + #realiza personalizacion del tamaño de letra, color, distancia de margeneres, etc
  scale_y_continuous(breaks = seq(0,100, 10),
                     name = "Frecuencia %",
                     expand = c(0,0)) + # personaliza los marcadores y su intervalo de separacion
  scale_fill_manual(labels = c("Extremadamente Alta", "Muy Alta", "Alta","Moderada","Baja"),
                    values = c("#998cff", "#d8001d", "#f88700","#f7e400", "#4eb400"),
                    name = "Categoría de exposición") #Establecer los colores correspondientes a cada categoria y colocar el nombre de la leyenda

IUV_FREC #realiza el llamado a la gráfica elaborada para visualizar

######### GUARDAR LA GRAFICA DE FRECUENCIA DE CATEGORIAS DE EXPOSICION DEL IUV MAXIMO #####

ggsave(filename = "IUV_frec.png", plot =IUV_FREC, 
       width = 24, height = 14, dpi = 1200, units = "cm")

### LISTO!! Ahora puedes verificar la grafica guardada en la carpeta de trabajo definida lineas arriba
