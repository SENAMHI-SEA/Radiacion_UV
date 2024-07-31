##### CARGADO DE LIBRERIAS

library(readxl)
library(magrittr)
library(tidyverse)
library(ggplot2)
library(openair)


library(openair)
library(ggplot2)
library(dplyr)
library(lubridate)
library(magrittr)
library(png)
library(grid)
library(scales)
library(readr)
library(readxl)
library(reshape2)

##### IMPORTACION DE DATOS AL MINUTO DEL IUV

setwd("C:\\boletin_ruv")

datos<-read_excel('data_radiacion.xlsx')

datos = datos %>% mutate(.,date=as.POSIXct(date))

############  GRAFICA DE FRECUENCIA DE LAS CATEGORIAS DE EXPOSICION POR DECADIARIA ##########

datos_iuv = openair::rollingMean(datos,"Indice_UV_Avg",width = 30,new.name = "IUV_MM",data.thresh = 75)

datos_iuv = openair::timeAverage(datos_iuv,avg.time = "day",statistic = "max")

df=reshape2::melt(datos_iuv,id.vars="date")

df$dia <- as.numeric(format(df$date, "%d"))
df = df %>% mutate(decadiario = ifelse(dia<11,'Decadaria I', 
                                               ifelse(dia<21,'Decadaria II','Decadaria III')))

df = df %>% filter(.,variable=="IUV_MM")

df = df %>% rename(.,"IUV"="value")

df$IUV = round(df$IUV,0)

df$categoria <- ifelse(df$IUV<=2,"Baja",
                          ifelse(df$IUV>2.0001 & df$IUV<=5,"Moderada",
                                 ifelse(df$IUV>5.0001 & df$IUV<=7,"Alta",
                                        ifelse(df$IUV>7.0001 & df$IUV<=10,"Muy Alta","Extremadamente Alta")))) 


resumen = aggregate(. ~ categoria + decadiario, data = df, FUN = length)
resumen = resumen %>% select(.,"categoria","dia","decadiario")

resumen$porcentaje = rep(NA,nrow(resumen))

resumen = resumen %>% 
  mutate(porcentaje = if_else(decadiario == "Decadaria I", round((dia/10)*100,2), porcentaje))

resumen = resumen %>% 
  mutate(porcentaje = if_else(decadiario == "Decadaria II", round((dia/10)*100,2), porcentaje)) 

resumen = resumen %>% 
  mutate(porcentaje = if_else(decadiario == "Decadaria III", round((dia/11)*100,2), porcentaje)) #dependiendo de los dias del mes

resumen

#write.csv(resumen,"porcentaje_iuv.csv",row.names = F)

resumen$categoria<- factor(resumen$categoria, levels = c("Extremadamente Alta", "Muy Alta", 
                                                         "Alta"))

IUV_FREC<- resumen %>% ggplot(aes(x=decadiario, y=porcentaje, fill=categoria)) +
  geom_bar(stat="identity", 
           width = 0.5) +
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
        legend.spacing = unit(0, "cm")) +
  scale_y_continuous(breaks = seq(0,100, 10),
                     name = "Frecuencia %",
                     expand = c(0,0)) +
  scale_fill_manual(labels = c("Extremadamente Alta", "Muy Alta", "Alta","Moderada","Baja"),
                    values = c("#998cff", "#d8001d", "#f88700","#f7e400", "#4eb400"),
                    name = "Categoría de exposición")
IUV_FREC

ggsave(filename = "IUV_frec.png", plot =IUV_FREC, 
       width = 24, height = 14, dpi = 1200, units = "cm")

