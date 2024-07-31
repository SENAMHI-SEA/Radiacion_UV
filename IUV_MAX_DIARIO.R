##### CARGADO DE LIBRERIAS

library(readxl)
library(magrittr)
library(tidyverse)
library(ggplot2)
library(openair)

##### IMPORTACION DE DATOS AL MINUTO DEL IUV

setwd("C:\\boletin_ruv")

datos<-read_excel('data_radiacion.xlsx')

datos = datos %>% mutate(.,date=as.POSIXct(date))

############  GRAFICA DE LA EVOLUCION DEL IUV MÁXIMO DIARIO DURANTE EL MES ##########

datos_iuv = openair::rollingMean(datos,"Indice_UV_Avg",width = 30,new.name = "IUV_MM",data.thresh = 75)

datos_iuv = openair::timeAverage(datos_iuv,avg.time = "day",statistic = "max")

tabla = as.data.frame(datos_iuv) %>% select(.,date,IUV_MM) %>% 
  mutate(IUV = round(IUV_MM,0)) 

tabla = tabla %>% mutate(num=c(1:nrow(tabla)))

s <- as.Date("2024-01-01",tz = "Etc/GMT")
e <- as.Date("2024-01-31",tz = "Etc/GMT")
etiquetas = format(seq(from=s, to=e, by=5),"%b %d")


iuv_catg <- data.frame(xstart = c(0,2,5,7,10), xend = c(2,5,7,10,20), 
                       Categoria = c("Baja","Moderada","Alta","Muy Alta","Extremadamente Alta"))

iuv_catg$Categoria = factor(iuv_catg$Categoria,levels = c("Baja","Moderada","Alta","Muy Alta","Extremadamente Alta"),
                            labels = c("Baja","Moderada","Alta","Muy Alta","Extremadamente Alta"))

IUV_MAX_DIARIO<- ggplot() + 
  geom_rect(data=iuv_catg, aes(ymin = xstart,
                               ymax = xend,
                               xmin = - Inf,
                               xmax = Inf,
                               fill= Categoria), alpha = 0.8) +
  geom_line(data= tabla, aes(x= num, y = IUV), color = "black", size = 0.9) +
  geom_point(data= tabla, aes(x= num, y = IUV),color = "black", size = 2.5) +
  scale_y_continuous(breaks = seq(2, 20, 2),
                     limits = c(0,20),
                     expand = c(0,0)) +
  scale_x_continuous(breaks = seq(1, nrow(tabla), 5),
                     expand = c(0.01, 0.01),
                     name = "Fecha",
                     labels = etiquetas) +
  xlab("Fecha")+ylab("IUV")+ labs(fill="Categoría de \nexposición") +
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
        plot.margin=unit(c(0.5,0.5,0.1,0.5), 'cm')) +
  scale_fill_manual(values = c("#4eb400", "#f7e400", "#f88700", "#d8001d", "#998cff"))


IUV_MAX_DIARIO

# Dispositivo PNG
png("IUV_diario.png",width = 40, height = 20, res = 1200, units = "cm")

IUV_MAX_DIARIO

# Cerramos el dispositivo
dev.off()

