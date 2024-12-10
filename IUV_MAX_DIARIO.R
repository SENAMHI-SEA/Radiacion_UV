
###############################################################################
#### ELABORACIÓN DE VARIACION DIARIA DEL IUV MÁXIMO PARA UNA ESTACIÓN #########
###############################################################################

##### INSTALACION DE LIBRERIAS #####
# En caso de no contar con las siguientes librerias instaladas, primero deben ser instaladas.
install.packages("readxl",dependencies = TRUE)
install.packages("magrittr",dependencies = TRUE)
install.packages("tidyverse",dependencies = TRUE)
install.packages("openair",dependencies = TRUE)

#### ACTIVACION DE LIBRERIA ####
# Una vez instaldas las librerias, se procede a activarlas como sigue a continuación
library(readxl)
library(magrittr)
library(tidyverse)
library(ggplot2)
library(openair)

##### IMPORTACION DE DATOS AL MINUTO DEL IUV #####
# Definir en la maquina local la ruta o dirección la carpeta de trabajo, en donde se encontrará el archivo excel 
# de los datos de radiación UV y colocarlo en la línea siguiente entre parentesis

setwd(r"(C:\boletin_ruv)")

# Importar el archivo de datos de radiación con el mismo nombre con el que se encuentra creado
# De aqui en adelante se recomienda que el archivo a importar tenga el contenido estructurado como el archivo
# denominado data_radiacion.xlsx

datos<-read_excel('data_radiacion.xlsx')

#Cambiar la columna "date" de un formato caracter a formato fecha
datos = datos %>% mutate(.,date=as.POSIXct(date))

############  ESTIMACIÓN DEL IUV MÁXIMO DIARIO ##########
# Realizar el promedio de cada 30 minutos del IUV
# indicar el nombre de la columna que tiene los datos del IUV , en este caso corresponde a "Indice_UV_Avg"
# podemos indicar una nueva columna a crear con los promedios, por ejemplo "IUV_MM"

datos_iuv = openair::rollingMean(datos,"Indice_UV_Avg",width = 30,new.name = "IUV_MM",
                                 align = "right",data.thresh = 100)

# Estimar el máximo promedio de cada 30 minutos del IUV por  día
datos_iuv = openair::timeAverage(datos_iuv,avg.time = "day",statistic = "max")

# Seleccionar las variables requeridas y redondear a valor entero el máximo promedio de cada 30 minutos del IUV por  día
datos_iuv = as.data.frame(datos_iuv) %>% select(.,date,IUV_MM) %>% 
  mutate(IUV = round(IUV_MM,0)) 

########### PREPARACION DE DATOS PARA GRAFICAR #######
# Preparación de etiquetas del eje x (fechas)
datos_iuv = datos_iuv %>% mutate(num=c(1:nrow(datos_iuv)))

s <- as.Date("2024-01-01",tz = "Etc/GMT") # fecha de inicio
e <- as.Date("2024-01-31",tz = "Etc/GMT") # fecha de termino
etiquetas = format(seq(from=s, to=e, by=5),"%b %d") #intervalo de días de las etiquetas y formato respectivo

# En cuanto al formato de fecha podemos considerar los siguientes tipos 

# Símbolo	  Significado
# %d	      día (numérico, de 0 a 31)
# %a	      día de la semana abreviado a tres letras
# %A	      día de la semana (nombre completo)
# 
# %m	      mes (numérico de 0 a 12)
# %b	      mes (nombre abreviado a tres letras)
# %B	      mes (nombre completo)
# 
# %y	      año (con dos dígitos)
# %Y	      año (con cuatro dígitos)


# Crear undataframe de los limites de las categorias de exposición del IUV
iuv_catg <- data.frame(xstart = c(0,2,5,7,10), xend = c(2,5,7,10,20), 
                       Categoria = c("Baja","Moderada","Alta","Muy Alta","Extremadamente Alta"))

# Establecer un orden predeterminado distinto al alfabetico de las categorias
# en este caso el orden es "Baja","Moderada","Alta","Muy Alta","Extremadamente Alta"

iuv_catg$Categoria = factor(iuv_catg$Categoria,levels = c("Baja","Moderada","Alta","Muy Alta","Extremadamente Alta"),
                            labels = c("Baja","Moderada","Alta","Muy Alta","Extremadamente Alta"))

######### REALIZAR LA GRAFICA DE VARIACION DIARIA DEL IUV MAXIMO #####

IUV_MAX_DIARIO<- ggplot() + 
  geom_rect(data=iuv_catg, aes(ymin = xstart,
                               ymax = xend,
                               xmin = - Inf,
                               xmax = Inf,
                               fill= Categoria), alpha = 0.8) + #establecer las categorias de exposicion como fondo de colores
  geom_line(data= datos_iuv, aes(x= num, y = IUV), color = "black", size = 0.9) + #dibujar los datos como lineas
  geom_point(data= datos_iuv, aes(x= num, y = IUV),color = "black", size = 2.5) + #dibujar los datos como puntos
  scale_y_continuous(breaks = seq(2, 20, 2),
                     limits = c(0,20),
                     expand = c(0,0)) + # Definir caracteristicas del eje y como limites e intervalo de marcadores
  scale_x_continuous(breaks = seq(1, nrow(datos_iuv), 5),
                     expand = c(0.01, 0.01),
                     name = "Fecha",
                     labels = etiquetas) + # Definir caracteristicas del eje x como etiquetas e intervalo de marcadores
  xlab("Fecha")+ylab("IUV")+ labs(fill="Categoría de \nexposición") + #Indicar nombres de ejes X, Y y leyenda
  theme(axis.text.x = element_text(size = 16, color = "black", face = "bold",hjust = 0.7,angle = 0,
                                   margin = unit(c(0.1, 0.1, 0.1, 0.1), "cm")),
        axis.text.y = element_text(size = 16, color = "black", face = "bold", 
                                   margin = unit(c(0.1, 0.1, 0.1, 0.1), "cm")),
        panel.grid.major = element_line(colour = "black"),
        panel.grid.minor = element_blank(),
        axis.title.x = element_text(vjust = 0.1), 
        axis.title = element_text(size = 18, face = "bold", color = "black",
                                  margin = unit(c(0.1, 0.1, 0.1, 0.1), "cm")),
        legend.position = "bottom",
        legend.title = element_text(size = 18, color = "black",face = "bold"),
        legend.text = element_text(size = 18, color = "black"),
        plot.margin=unit(c(0.5,0.5,0.1,0.5), 'cm')) + #Definir caracteristicas adicionales del grafico tales como
  # tamaño de letra, color, espaciado de margenes, orientacion vertical u horizontal, estilo negrita, posición de leyenda entre otros
  scale_fill_manual(values = c("#4eb400", "#f7e400", "#f88700", "#d8001d", "#998cff")) # definir los colores de categorias de exposicion en el orden predeterminado


IUV_MAX_DIARIO ## LLamado a la gráfica para visualizar

######### GUARDAR LA GRAFICA DE VARIACION DIARIA DEL IUV MAXIMO #####

# Indicar el nombre del archivo PNG de guardado y caracteristicas como ancho, alto y resolución
png("IUV_diario.png",width = 40, height = 20, res = 1200, units = "cm")

IUV_MAX_DIARIO ## LLamado a la gráfica que se guardará

# Terminamos la operación de guardado
dev.off()

### LISTO!! Ahora a verificar en la carpeta de trabajo definida en la linea 25
