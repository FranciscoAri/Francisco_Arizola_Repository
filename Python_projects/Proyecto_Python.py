"""

Inclusión Financiera y Pobreza

Integrantes: 
    Arizola, Francisco
    Condori, Fernando
    Lau, Victor
    Regal, José Ignacio
    Valdivia, Mack

"""

#Importar librerías
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

#Importar archivos CSV con la data de inclusión financiera de la SBS
datos_acceso = pd.read_csv("Datos_Acceso.csv",encoding='utf-8')
datos_uso = pd.read_csv("Datos_Uso.csv",encoding='utf-8')

#Eliminar columna N° Distritos del Data Frame Acceso
datos_acceso = datos_acceso[['Departamento', '2005', '2006', '2007', '2008', '2009',
       '2010', '2011', '2012', '2013', '2014', '2015', '2016', '2017', '2018',
       '2019', '2020', '2021', '2022', '2023']]

#Crear un tercer Data Frame que guarde el Indicador General de Inclusión Financiera de cada Departamento por Año
datos_ciif = pd.DataFrame(columns=['Departamento', '2005', '2006', '2007', '2008', '2009',
       '2010', '2011', '2012', '2013', '2014', '2015', '2016', '2017', '2018',
       '2019', '2020', '2021', '2022', '2023'])

#Colocar los Departamentos en el Data Frame
datos_ciif['Departamento'] = datos_acceso['Departamento']

#Llenar el Data Frame con el indicador general de Inclusion para cada Año y Departamento
for i in range(len(datos_ciif)):
    for j in range(1,20):
        #El indicador resulta como el promedio de los indicadores acceso y uso para el respectivo año y región
        datos_ciif.iloc[i,j] = (datos_acceso.iloc[i,j] + datos_uso.iloc[i,j]) / 2

#Crear una lista con los 10 Departamentos más pobres en 2005 
print(list(datos_ciif['Departamento']))
departamentos_pobres = ['Amazonas', 'Apurímac', 'Ayacucho', 'Cajamarca', 'Huancavelica', 'Huánuco', 'Loreto', 'Pasco', 'Piura', 'Puno']

#Crear un Data Frame de inclusión financiera con solo los 10 dptos. más pobres
datos_ciif_pobres = datos_ciif[datos_ciif['Departamento'].isin(departamentos_pobres)]

#Importar archivo CSV con la evolución de la tasa de pobreza de cada región
file_pobreza = pd.read_csv('INDICE_POBREZA.csv',sep=";",encoding='utf-8')

#Cambiar el nombre a la primera columna
file_pobreza.rename(columns= {file_pobreza.columns[0] : 'Departamento'},inplace = True)

#El archivo importado tenía las columnas de los años en el sentido contrario y el símbolo "%" en cada dato
#Se trabajó para que quede en una presentación similar a los datos de Inclusión Financiera
#Crear un Data Frame auxiliar sin la columna de Departamentos
datos_pobreza_1 = file_pobreza[['2022', '2021', '2020', '2019', '2018', '2017', '2016', '2015',
       '2014', '2013', '2012', '2011', '2010', '2009', '2008', '2007', '2006','2005']]

#Invertir el orden de las columnas (2005-2022)
datos_pobreza_1 = datos_pobreza_1.iloc[:,::-1]

#Convertir los datos de str a númerico
for i in range(len(datos_pobreza_1)):
    for j in range(18):
        #Quitarle el "%" a todos los datos
        datos_pobreza_1.iloc[i,j] = datos_pobreza_1.iloc[i,j][:-1]
        #Convertir a númerico todos los datos
        datos_pobreza_1.iloc[i,j] = float(datos_pobreza_1.iloc[i,j])

#Armar el Data Frame de pobreza
datos_pobreza = pd.DataFrame(columns=['Departamento', '2005', '2006', '2007', '2008', '2009',
       '2010', '2011', '2012', '2013', '2014', '2015', '2016', '2017', '2018',
       '2019', '2020', '2021', '2022'])

#Colocar los departamentos en el Data Frame
datos_pobreza['Departamento'] = file_pobreza['Departamento']

#Llenar los datos a partir de los trabajado en el Data Frame auxiliar 1
for i in range(len(datos_pobreza)):
    for j in range(1,19):
        datos_pobreza.iloc[i,j] = datos_pobreza_1.iloc[i,j-1]

#Conservar las filas con los 10 distritos más pobres
datos_pobreza_pobres = datos_pobreza[datos_pobreza['Departamento'].isin(departamentos_pobres)]

#Crear el Data Frame final con el ratio Inclusión Financiera - Pobreza para los 10 dptos. más pobres
datos_finales = pd.DataFrame(columns=['Departamento', '2005', '2006', '2007', '2008', '2009',
       '2010', '2011', '2012', '2013', '2014', '2015', '2016', '2017', '2018',
       '2019', '2020', '2021', '2022'])

#Colocar los departamentos
datos_finales['Departamento'] = datos_ciif_pobres['Departamento'] 
datos_finales = datos_finales.reset_index(drop=True)

#Llenar el Data Frame con el ratio final para cada Año y Departamento
for i in range(len(datos_finales)):
    for j in range(1,19):
        datos_finales.iloc[i,j] = datos_ciif_pobres.iloc[i,j]  / datos_pobreza_pobres.iloc[i,j]

#Crear Data Frames auxiliares para los gráficos con solo los datos
#Data Frame auxiliar de Indicadores de Inclusión Financiera
datos_ciif_aux = datos_ciif.drop(columns='Departamento')
datos_ciif_aux = datos_ciif_aux.apply(pd.to_numeric, errors='coerce')

#Data Frame auxiliar de Pobreza
datos_pobreza_aux = datos_pobreza.drop(columns='Departamento')
datos_pobreza_aux = datos_pobreza_aux.apply(pd.to_numeric, errors='coerce')

#Data Frame auxiliar de los datos con el ratio final
datos_finales_aux = datos_finales.drop(columns='Departamento')
datos_finales_aux = datos_finales_aux.apply(pd.to_numeric, errors='coerce')

## -------Gráficos Scatter Inclusion Financiera - Pobreza, años 2005 y 2023---------##

#La data de ciif contiene solo Lima, pero la data de pobreza separa Lima Metropolitana y Provincias, por esta limitación se elimina Lima del gráfico
#Creación de lista de departamentos sin Lima
departamentos_sin_Lima = ['Amazonas', 'Ancash', 'Apurímac', 'Arequipa', 'Ayacucho', 'Cajamarca', 'Callao', 'Cusco', 'Huancavelica', 'Huánuco', 'Ica', 'Junín', 'La Libertad', 'Lambayeque', 'Loreto', 'Madre de Dios', 'Moquegua', 'Pasco', 'Piura', 'Puno', 'San Martín', 'Tacna', 'Tumbes', 'Ucayali']

#Creación de Data Frames auxiliares sin Lima
datos_ciif_scatter = datos_ciif[datos_ciif['Departamento'].isin(departamentos_sin_Lima)]
datos_ciif_scatter = datos_ciif_scatter.reset_index(drop=True)
datos_pobreza_scatter = datos_pobreza[datos_pobreza['Departamento'].isin(departamentos_sin_Lima)]
datos_pobreza_scatter = datos_pobreza_scatter.reset_index(drop=True)

#Creación de Data Frame para 2005
data_2005 = pd.DataFrame(columns=['Departamento','InclusionFinanciera','Pobreza'])
data_2005['Departamento'] = datos_ciif_scatter['Departamento']
data_2005['InclusionFinanciera'] = datos_ciif_scatter['2005']
data_2005['Pobreza'] = datos_pobreza_scatter['2005']

#Creación de Data Frame para 2022
data_2022 = pd.DataFrame(columns=['Departamento','InclusionFinanciera','Pobreza'])
data_2022['Departamento'] = datos_ciif_scatter['Departamento']
data_2022['InclusionFinanciera'] = datos_ciif_scatter['2022']
data_2022['Pobreza'] = datos_pobreza_scatter['2022']

#Gráfico Scatter 2005
plt.figure(figsize=(12,8))
plt.scatter(data_2005['Pobreza'],data_2005['InclusionFinanciera'],s=70,color='c',edgecolors='black')
plt.title("Figura 4: Dispersión de Inclusión Financiera y Pobreza por Departamento, 2005")
plt.xlabel("Porcentaje de pobreza")
plt.ylabel("Nivel de inclusión financiera")

# Calcular la pendiente (m) y el intercepto (b) de la línea de regresión
m_2005, b_2005 = np.polyfit(data_2005['Pobreza'].astype(float),data_2005['InclusionFinanciera'].astype(float), 1)

# Agregar la línea de regresión al gráfico
plt.plot(data_2005['Pobreza'].astype(float), m_2005*data_2005['Pobreza'].astype(float) + b_2005, color='red', label='Línea de Regresión')

#Agregar etiquetas con el nombre del dpto a cada punto
for i, departamento in enumerate(data_2005['Departamento']):
    plt.annotate(departamento,(data_2005['Pobreza'][i],data_2005['InclusionFinanciera'][i]))

#Guardar el gráfico
plt.grid(True)
plt.savefig('Dispersion_2005.png')

#Gráfico Scatter 2022
plt.figure(figsize=(12,8))
plt.scatter(data_2022['Pobreza'],data_2022['InclusionFinanciera'],s=70,color='c',edgecolors='black')
plt.title("Figura 5: Dispersión de Inclusión Financiera y Pobreza por Departamento, 2022")
plt.xlabel("Porcentaje de pobreza")
plt.ylabel("Nivel de inclusión financiera")

# Calcular la pendiente (m) y el intercepto (b) de la línea de regresión
m_2022, b_2022 = np.polyfit(data_2022['Pobreza'].astype(float),data_2022['InclusionFinanciera'].astype(float), 1)

# Agregar la línea de regresión al gráfico
plt.plot(data_2022['Pobreza'].astype(float), m_2022*data_2022['Pobreza'].astype(float) + b_2022, color='red', label='Línea de Regresión')

#Agregar etiquetas con el nombre del dpto a cada punto
for i, departamento in enumerate(data_2022['Departamento']):
    plt.annotate(departamento,(data_2022['Pobreza'][i],data_2022['InclusionFinanciera'][i]))

#Guardar el gráfico
plt.grid(True)
plt.savefig('Dispersion_2022.png')

## ----Mapa de Calor de la evolución de la inclusión financiera------- ##
# Establecer la columna 'Departamento' como índice (si no lo está)
datos_ciif.set_index('Departamento', inplace=True)

# Crear el grfico de mapa de calor con matplotlib
plt.figure(figsize=(10, 6))
heatmap_ciif = plt.imshow(datos_ciif_aux.values, cmap='YlGnBu', interpolation='nearest')

# Añadir barra de color
plt.colorbar(heatmap_ciif, shrink = 0.9)

# Establecer los nombres de las etiquetas de los ejes
plt.xticks(range(len(datos_ciif_aux.columns)), datos_ciif.columns)
plt.yticks(range(len(datos_ciif_aux.index)), datos_ciif.index)

# Rotar los nombres de las etiquetas de los ejes x para mejor visualizacin
plt.xticks(rotation=60)

# Añadir título y etiquetas de los ejes
plt.title('Figura 1: Evolución de la Inclusión Financiera por Departamento y Año')
plt.xlabel('Año')
plt.ylabel('Departamento')

# Mostrar el grfico
plt.savefig('ciif.png')

## ------- Mapa de Calor de la evolucin de la pobreza ----------- ##
# Establecer la columna 'Departamento' como índice
datos_pobreza.set_index('Departamento', inplace=True)

# Crear el grfico de mapa de calor con matplotlib
plt.figure(figsize=(10, 6))
heatmap_pobreza = plt.imshow(datos_pobreza_aux.values, cmap='YlGnBu', interpolation='nearest')

# Aadir barra de color
plt.colorbar(heatmap_pobreza, shrink = 0.9)

# Establecer los nombres de las etiquetas de los ejes
plt.xticks(range(len(datos_pobreza_aux.columns)), datos_pobreza.columns)
plt.yticks(range(len(datos_pobreza_aux.index)), datos_pobreza.index)

# Rotar los nombres de las etiquetas de los ejes x para mejor visualizacin
plt.xticks(rotation=60)

# Aadir ttulo y etiquetas de los ejes
plt.title('Figura 2: Evolución de la Pobreza por Departamento y Año')
plt.xlabel('Año')
plt.ylabel('Departamento')

# Mostrar el grfico
plt.savefig('pobreza.png')

## ------- Mapa de Calor del ratio Inclusión Financiera - Pobreza ----------- ##
# Establecer la columna 'Departamento' como índice (si no lo está)
datos_finales.set_index('Departamento', inplace=True)

# Crear el gráfico de mapa de calor con matplotlib
plt.figure(figsize=(10, 6))
heatmap_final = plt.imshow(datos_finales_aux.values, cmap='YlGnBu', interpolation='nearest')

# Aadir barra de color
plt.colorbar(heatmap_final, shrink = 0.7)

# Establecer los nombres de las etiquetas de los ejes
plt.xticks(range(len(datos_finales_aux.columns)), datos_finales.columns)
plt.yticks(range(len(datos_finales_aux.index)), datos_finales.index)

# Rotar los nombres de las etiquetas de los ejes x para mejor visualizacin
plt.xticks(rotation=60)

# Aadir ttulo y etiquetas de los ejes
plt.title('Figura 3: Evolución del ratio Inclusión Financiera - Pobreza por Departamento y Año')
plt.xlabel('Año')
plt.ylabel('Departamento')

# Mostrar el grfico
plt.savefig('final.png')


