


#############  TOTAL SKY
import pandas as pd # Jose: movido por cuestiones de orden
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import geopandas as gpd
from shapely.geometry import box
import matplotlib.patheffects as pe


import xarray as xr # Jose: indicar en el codigo como instalar esta libreria asi como dependencias para evitar errores ()

usuario='jinoue'  # --- Jose: como obtengo el nombre de usuario

ds = xr.open_dataset('C:\\Users\\'+usuario+'\\Downloads\\ncs\\prono\\data_sfc.nc') 
# jose: la ruta del archivo es muy especifica o direccionada, capaz podria ser mas general 

#falta colocar lineas de verificacion del contenido de netcdf o resultados que se requiera revisar

ds=ds.uvbed
ds=ds*40


#print(f"Año: {year}, Mes: {month}, Día: {day}")

year_analisis = f"{ds[0].forecast_reference_time.dt.year.item():04}"
month_analisis = f"{ds[0].forecast_reference_time.dt.month.item():02}"
day_analisis = f"{ds[0].forecast_reference_time.dt.day.item():02}"

# Jose: en esta seccion falta comentar lo que se esta haciendo en las lineas siguientes
ds= ds.assign_coords(time=ds['forecast_reference_time'] + ds['forecast_period'])
ds= ds.squeeze('forecast_reference_time')
ds= ds.drop_vars('forecast_reference_time')
ds= ds.drop_vars('forecast_period')

ds= ds.assign_coords(time=ds.time - pd.Timedelta(hours=5))
ds= ds.rename({'forecast_period': 'time'})
ds= ds.set_index(time='time')

ds= ds.resample(time="D").max()
ds[2] # Jose: quizas podrias colocar una opcion para ver el listado de dias de pronostico que tienes para elegir y que se entienda cual es el 2

#ds.forecast_reference_time




# Jose: Quizas colocarle un titulo de apartado que haga referencia el documento  instructivo

lat_max= -5.5
lat_min= -9.5
lon_max= -76.5
lon_min= -80.5
ds=ds.sel(latitude=slice(lat_max, lat_min),longitude=slice(lon_min, lon_max))
specific_day = ds.isel(time=2)


# Jose: colocar titulo de seccion de graficar o algo asi
plt.figure(figsize=(8, 8))
ax = plt.axes(projection=ccrs.PlateCarree())
ax.coastlines()
ax.add_feature(cfeature.LAKES, edgecolor='blue')
ax.add_feature(cfeature.RIVERS, edgecolor='blue',alpha=0.5)
ax.add_feature(cfeature.BORDERS, linestyle=':', linewidth=2)
ax.gridlines(draw_labels=True, linewidth=1, color='black', alpha=0.4, linestyle='--')

colors = ['#97D700','#FFCD00','#FF8200',    '#DA291C',       '#62359F']  # 20 colores, el 0 tiene su color hasta 0.5, 0.5 ya es otro color porque sería 1 aproximándolo
levels = [0,2.5,5.5,7.5,10.5,20.5]
levels = [0,3,6,8,11,21]

#Jose: indicar aqui o en el documento el metodo de generacion de la superficie de contornos, brevemente dado que 
# las salidas del modelo son de 44 km de resolucion espacial y tambien deberia decirse esto ultimo en el documento
# asi como la interpretacion de esta visualizacion 
contour = ax.contourf(specific_day.longitude, specific_day.latitude, specific_day,
                      levels=levels, colors=colors,
                      transform=ccrs.PlateCarree())
cbar = plt.colorbar(contour, pad=0.04, fraction=0.03, label='IUV', orientation='horizontal', location='bottom', ticks=[0,3,6,8,11])


plt.title('SENAMHI-DMA-SEA\nCAMS - IUV máximo diario - Nivel: Superficie\n Análisis: ' +year_analisis+month_analisis+day_analisis+' 00UTC'+'       Válido: '+ str(specific_day.time)[38:46], fontsize=10)
# Jose: no se si en lugar de "Analisis" podria ir "fecha de analisis" o "fecha de refencia de pronostico", pero lo deja a tu consideracion como se entiende mejor

plt.savefig('C:\\Users\\'+usuario+'\\Downloads\\ncs\\prono\\IUV_max_diario_DZ3.png', dpi=600, bbox_inches='tight')

##   Importación de shapefiles

Departamentos = gpd.read_file('C:\\Users\\'+usuario+'\\Downloads\\shp\\LIMITES POLITICOS\\PERU\\Departamental INEI 2023 geogpsperu SuyoPomalia.shp')
DZs = gpd.read_file('C:\\Users\\'+usuario+'\\Downloads\\shp\\LIMITES POLITICOS\\PERU\\Direcciones_Zonales_SENAMHI\\DIRECCIONES_ZONALES.shp')
cap_dep = gpd.read_file('C:\\Users\\'+usuario+'\\Downloads\\shp\\CIUDADES, CENT POB, ZONAS\\Peru\\Cap_Departa.shp')
cap_prov = gpd.read_file('C:\\Users\\'+usuario+'\\Downloads\\shp\\CIUDADES, CENT POB, ZONAS\\Peru\\Cap_Provincia.shp')


##   Adaptación espacial de shapefiles

# Create a bounding box using the extent of specific_day data
bbox = box(specific_day.longitude.min(), specific_day.latitude.min(), specific_day.longitude.max(), specific_day.latitude.max())

# Clip the shapefile to the square bounding box
Departamentos_clip = gpd.clip(Departamentos, bbox)
DZs_clip = gpd.clip(DZs, bbox)
cap_dep_clip = gpd.clip(cap_dep, bbox)
cap_prov_clip = gpd.clip(cap_prov, bbox)


##   ploteo de shapefiles
Departamentos_clip.plot(ax=ax, color='none', edgecolor='black', linestyle='dashed',linewidth=0.5,alpha=0.25,legend=True)
DZs_clip.plot(ax=ax, color='none', edgecolor='black', linewidth=0.75,legend=True)
cap_dep_clip.plot(ax=ax, color='black', edgecolor='black', legend=True, markersize=1,linewidth=0)
cap_prov_clip.plot(ax=ax, color='black', edgecolor='black', legend=True, markersize=1,linewidth=0)


# Add labels for each point

for idx, row in cap_prov_clip.iterrows():
    nombre_capitalizado = row['Nombre'].capitalize()
    ax.annotate(nombre_capitalizado, xy=(row.geometry.x, row.geometry.y), xytext=(3, 3),
                textcoords="offset points", color='black', fontsize=4.5,
                path_effects=[pe.withStroke(linewidth=0.9, foreground="white")])


for idx, row in cap_dep_clip.iterrows():
    ax.annotate(text=row['Nombre'], xy=(row.geometry.x, row.geometry.y), xytext=(-3, -11),
                textcoords="offset points", color='black', fontsize=8,
                path_effects=[pe.withStroke(linewidth=1, foreground="white")])


#plt.tight_layout()
plt.savefig('C:\\Users\\'+usuario+'\\OneDrive\\plots\\prono\\IUV_max_diario_DZ3.png', dpi=600, bbox_inches='tight')
# Jose: Esta ruta no coincide o no hace referencia donde se ubica el archivo netcdf



plt.savefig('C:\\Users\\'+usuario+'\\Downloads\\ncs\\prono\\IUV_max_diario_DZ3.png', dpi=600, bbox_inches='tight')

# Jose: algo asi deberia ser













































