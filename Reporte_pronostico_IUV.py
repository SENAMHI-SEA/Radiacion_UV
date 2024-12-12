###    INSTALANDO LAS LIBRERÍAS NECESARIAS PARA LA EJECUCIÓN DEL CÓDIGO

import subprocess
import sys

# Lista de librerias a verificar e instala:
libraries = [
    "pandas", "numpy", "matplotlib", "pillow",  "os"
    "cartopy", "shapely", "pyproj", "geopandas", 
    "fiona", "xarray", "netCDF4", "h5netcdf"
]

def install_library(lib_name):
    try:
        # Try to import the library
        __import__(lib_name)
        print(f"{lib_name} is already installed.")
    except ImportError:
        # If import fails, install the library
        print(f"{lib_name} not found. Installing...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", lib_name])




##    Importación de librerías 
import pandas as pd 
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import geopandas as gpd
from shapely.geometry import box
import matplotlib.patheffects as pe
import xarray as xr 
import os

##______________________________________________________________________________


####    IMPORTANDO EL ARCHIVO NETCDF DEL CAMS DESDE LA CARPETA DE DESCARGAS

ds = xr.open_dataset(r'C:\Users\pozot\Downloads\data_sfc.nc') 
print(ds)

##______________________________________________________________________________


####    EXTRAYENDO LA VARIABLE DE INTERÉS Y APLICANDO CONVERSIONES DE RUV a IUV
ds=ds.uvbed
ds=ds*40
print(ds)

##______________________________________________________________________________


####    AJUSTE DE LAS COORDENADAS DE TIEMPO
## Se definen, a partir de la matriz "ds", el año, mes, y día de la salida del modelo
year_analisis = f"{ds[0].forecast_reference_time.dt.year.item():04}"
month_analisis = f"{ds[0].forecast_reference_time.dt.month.item():02}"
day_analisis = f"{ds[0].forecast_reference_time.dt.day.item():02}"


## El CAMS exporta la información grillada con un estructura propia: por cada día hay múltiples horas de pronósticos
## los cuales no poseen una identidad temporal. A partir de las siguientes líneas de código se asigna a cada
## pronóstico horario su día y hora correspondiente, formando finalmente una matriz de 120 horas de datos espaciales.

ds= ds.assign_coords(time=ds['forecast_reference_time'] + ds['forecast_period'])
ds= ds.squeeze('forecast_reference_time')
ds= ds.drop_vars('forecast_reference_time')
ds= ds.drop_vars('forecast_period')

## cambio de UTC a huso horario del Perú
ds= ds.assign_coords(time=ds.time - pd.Timedelta(hours=5))
ds= ds.rename({'forecast_period': 'time'})
ds= ds.set_index(time='time')

##______________________________________________________________________________


####    Selección de valores máximos diarios a partir de los datos horarios de IUV
ds= ds.resample(time="D").max()
print(ds)

##______________________________________________________________________________


####    SELECCIÓN DEL DÍA DE PRONÓSTICO A GRAFICAR

print(ds.time)

### Selección del día pronosticado
specific_day = ds.isel(time=2)
print(specific_day)

##______________________________________________________________________________


####    VISUALIZACIÓN DEL DÍA SELECCIONADO


plt.figure(figsize=(8, 8))
ax = plt.axes(projection=ccrs.PlateCarree())
ax.coastlines()
ax.add_feature(cfeature.LAKES, edgecolor='blue')
ax.add_feature(cfeature.RIVERS, edgecolor='blue',alpha=0.5)
ax.add_feature(cfeature.BORDERS, linestyle=':', linewidth=2)
ax.gridlines(draw_labels=True, linewidth=1, color='black', alpha=0.4, linestyle='--')

###  Se define la paleta de colores correspondiente al IUV (OMM, OMS)

colors = ['#97D700','#FFCD00','#FF8200',    '#DA291C',       '#62359F']  # 20 colores, el 0 tiene su color hasta 0.5, 0.5 ya es otro color porque sería 1 aproximándolo
levels = [0,2.5,5.5,7.5,10.5,20.5]
levels = [0,3,6,8,11,21]



##        VISUALIZACIÓN POR CONTORNOS
####  En estudios climáticos y meteorológicos, contourf es ampliamente usado porque refleja patrones espaciales
#### que son consistentes con la física del sistema, en este caso, la orografía y la dispersión de radiación UV
#### a través de la atmósfera.

contour = ax.contourf(specific_day.longitude, specific_day.latitude, specific_day,
                      levels=levels, colors=colors,
                      transform=ccrs.PlateCarree())

###  Definiendo la barra de colores
cbar = plt.colorbar(contour, pad=0.04, fraction=0.03, label='IUV', orientation='horizontal', location='bottom', ticks=[0,3,6,8,11])


###  Se define el título de la imagen
plt.title('SENAMHI-DMA-SEA\nCAMS - IUV máximo diario - Nivel: Superficie\n Análisis: ' +year_analisis+month_analisis+day_analisis+' 00UTC'+'       Válido: '+ str(specific_day.time)[38:46], fontsize=10)


##   Importación de shapefiles

Departamentos = gpd.read_file(r'C:\Users\pozot\Downloads\shp\LIMITES POLITICOS\PERU\Departamental INEI 2023 geogpsperu SuyoPomalia.shp')
DZs = gpd.read_file(r'C:\Users\pozot\Downloads\shp\LIMITES POLITICOS\PERU\Direcciones_Zonales_SENAMHI\DIRECCIONES_ZONALES.shp')
cap_dep = gpd.read_file(r'C:\Users\pozot\Downloads\shp\CIUDADES, CENT POB, ZONAS\Peru\Cap_Departa.shp')
cap_prov = gpd.read_file(r'C:\Users\pozot\Downloads\shp\CIUDADES, CENT POB, ZONAS\Peru\Cap_Provincia.shp')


##   Adaptación espacial de shapefiles

# Create a bounding box using the extent of specific_day data
bbox = box(specific_day.longitude.min(), specific_day.latitude.min(), specific_day.longitude.max(), specific_day.latitude.max())

# Clip the shapefile to the square bounding box
Departamentos_clip = gpd.clip(Departamentos, bbox)
DZs_clip = gpd.clip(DZs, bbox)
cap_dep_clip = gpd.clip(cap_dep, bbox)
cap_prov_clip = gpd.clip(cap_prov, bbox)


##  Visualización de shapefiles
Departamentos_clip.plot(ax=ax, color='none', edgecolor='black', linestyle='dashed',linewidth=0.5,alpha=0.25,legend=True)
DZs_clip.plot(ax=ax, color='none', edgecolor='black', linewidth=0.75,legend=True)
cap_dep_clip.plot(ax=ax, color='black', edgecolor='black', legend=True, markersize=1,linewidth=0)
cap_prov_clip.plot(ax=ax, color='black', edgecolor='black', legend=True, markersize=1,linewidth=0)


# Añadimos etiquetas para las capitales.

for idx, row in cap_prov_clip.iterrows():
    nombre_capitalizado = row['Nombre'].capitalize()
    ax.annotate(nombre_capitalizado, xy=(row.geometry.x, row.geometry.y), xytext=(3, 3),
                textcoords="offset points", color='black', fontsize=4.5,
                path_effects=[pe.withStroke(linewidth=0.9, foreground="white")])


for idx, row in cap_dep_clip.iterrows():
    ax.annotate(text=row['Nombre'], xy=(row.geometry.x, row.geometry.y), xytext=(-3, -11),
                textcoords="offset points", color='black', fontsize=8,
                path_effects=[pe.withStroke(linewidth=1, foreground="white")])



####     EXPORTANDO EL MAPA DE IUV MÁXIMO
plt.savefig(r'C:\Users\pozot\Downloads\IUV_max_diario.png', dpi=600, bbox_inches='tight')










































