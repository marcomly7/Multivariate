##-------------------------------META-AN�LISIS-----------------------------##

##-------------------------------------------TABACO CD--------------------------------------------------------##

#Importamos el dataset (con la hoja del Excel pertinente)
setwd("C:/Users/Usuario/Desktop/M�ster Big Data/2. Meta-an�lisis/Trabajo")
library(readxl)
library(meta)
excel_sheets("MA_corregido.xlsx") # Nombres de las hojas del Excel
CDtab <- read_excel("MA_corregido.xlsx", sheet = "CD TABACO")
View(CDtab)

as.factor(CDtab$Zona)
as.factor(CDtab$`hab_tabaco\n`)

#---Vectores l�gicos para segmentar y escribir menos---- 
fumaCD <- CDtab$`hab_tabaco\n`=="Fumador" 
dejaCD <- CDtab$`hab_tabaco\n`=="Ex-fumador"
#-------------------------------------------------------

# Realizamos modelo de efectos fijos para CD en tabaco, tanto en fumadores como ex-fumadores (2 modelos distintos)
# El argumento sm="OR" hace que tome los valores de log(OR) y lo que devuelva sean directamente los OR
# No empleamos Mantel-Haenszel mediante la funci�n metabin (espec�fico para binarios) pq requiere los datos de tama�o de efecto sin transformar

fitCDtab_fuma <- metagen(CDtab$`TE\n`[fumaCD], CDtab$ES_TE[fumaCD],
                        studlab = paste("(", CDtab$A�o[fumaCD], ")", CDtab$Autor[fumaCD]), 
                        comb.fixed = TRUE, comb.random = FALSE, prediction=FALSE, sm="OR")

fitCDtab_deja <- metagen(CDtab$`TE\n`[dejaCD], CDtab$ES_TE[dejaCD], 
                         studlab = paste("(", CDtab$A�o[dejaCD], ")",CDtab$Autor[dejaCD]), 
                         comb.fixed = TRUE, comb.random = FALSE, prediction=FALSE, sm="OR")

# Hacemos forest plot de ambos; en ninguno se observa heterogeneidad (m�todo de varianza inversa)
forest(fitCDtab_fuma, sortvar = CDtab$A�o[fumaCD], leftlabs=c("Art�culo", NA, NA))
forest(fitCDtab_deja, sortvar = CDtab$A�o[dejaCD], leftlabs=c("Art�culo", NA, NA))



#----------------------------------------------TABACO UC-----------------------------------------------##

UCtab <- read_excel("MA_corregido.xlsx", sheet = "UC TABACO")
View(UCtab)

as.factor(UCtab$Zona)
as.factor(UCtab$`hab_tabaco\n`)

fumaUC <- UCtab$`hab_tabaco\n`=="Fumador" # Vectores l�gicos
dejaUC <- UCtab$`hab_tabaco\n`=="Ex-fumador"

fitUCtab_fuma <- metagen(UCtab$`TE\n`[fumaUC], UCtab$ES_TE[fumaUC],
                         studlab = paste("(", UCtab$A�o[fumaUC], ")", UCtab$Autor[fumaUC]), 
                         comb.fixed = TRUE, comb.random = FALSE, prediction=FALSE, sm="OR")

fitUCtab_deja <- metagen(UCtab$`TE\n`[dejaUC], UCtab$ES_TE[dejaUC], 
                        studlab = paste("(", UCtab$A�o[dejaUC], ")",UCtab$Autor[dejaUC]), 
                         comb.fixed = TRUE, comb.random = FALSE, prediction=FALSE, sm="OR")

forest(fitUCtab_fuma, sortvar = UCtab$A�o[fumaUC], leftlabs=c("Art�culo", NA, NA)) # Obtenemos heterogeneidad elevada en ambos casos
forest(fitUCtab_deja, sortvar = UCtab$A�o[dejaUC], leftlabs=c("Art�culo", NA, NA))




# Estudiaremos la heterogeneidad con Baujat plot
baujat(fitUCtab_fuma, studlab = UCtab$ID[fumaUC]) # Claramente hay un outlier (alta contrib. a heterogeneidad y alto peso en los c�lculos)
baujat(fitUCtab_deja, studlab = UCtab$ID[dejaUC]) # En este caso hay heterogeneidad general, habr�a que ver por subgrupos

#----------------------Realizamos estudio por subgrupos de ZONA GEOGR�FICA---------------------------
# Para ello tenemos que cargar un repositorio de GitHub del autor de la gu�a. Tiene demasiadas funciones, ponemos la que nos interesa.
# Cargamos el archivo R adjunto con la funci�n:
source("subgrupos_MA.R")

subgroup.analysis.mixed.effects(fitUCtab_fuma, subgroups = UCtab$Zona[fumaUC])
subgroup.analysis.mixed.effects(fitUCtab_deja, subgroups = UCtab$Zona[dejaUC])
# Permite hacer forest plot de los subgrupos y del conjunto, ver si hay homogeneidad por subgrupos (test chi^2)
#-----------------------No lo usamos pq tenemos subgrupos con un solo art�culo-----------------------

# Lo mostramos en una meta-regresi�n para fumadores:
metareg(fitUCtab_fuma, UCtab$Zona[fumaUC])
# Siguiendo los pasos de la referencia, tenemos varias cosas:
# 1: son valores calculados tomando de referencia el factor "Asia"
# 2: test de moderadores significativo; implica que las zonas est�n relacionadas con la diferencia en tam. efecto (heterogeneidad)
# 3: R^2=96.57%, indica que realmente este factor captura ese porcentaje de la heterogeneidad del modelo
# CONCLUSI�N: es un buen factor de confusi�n para fumadores

# Como hay diferencias, quitamos el art�culo de Asia y probamos:
noAsia <- UCtab$Zona!="Asia"

fitUCtab_fuma2 <- metagen(UCtab$`TE\n`[fumaUC & noAsia], UCtab$ES_TE[fumaUC & noAsia],
                         studlab = paste("(", UCtab$A�o[fumaUC & noAsia], ")", UCtab$Autor[fumaUC & noAsia]), 
                         comb.fixed = TRUE, comb.random = FALSE, prediction=FALSE, sm="OR")

forest(fitUCtab_fuma2, sortvar = UCtab$A�o[fumaUC & noAsia], leftlabs=c("Art�culo", NA, NA))




# Repetimos para ex-fumadores:
metareg(fitUCtab_deja, UCtab$Zona[dejaUC]) # No explica

# Tambi�n podemos ver si el a�o del art�culo influye
metareg(fitUCtab_fuma, UCtab$A�o[fumaUC]) # No explica
metareg(fitUCtab_deja, UCtab$A�o[dejaUC]) # Tampoco explica

# Comprobamos la calidad de los art�culos
metareg(fitUCtab_fuma, UCtab$Calidad[fumaUC]) # Nada
metareg(fitUCtab_deja, UCtab$Calidad[dejaUC]) # Tampoco



# Estudiamos ahora el sesgo de publicaci�n
# Contour-enhanced funnel plot del sesgo de publicaci�n
funnel(fitCDtab_fuma, studlab=CDtab$ID[fumaCD], contour = c(.95, 0.99), col.contour = c("blue", "gray"))
legend(1.15, 0, c("p<0.05", "p<0.01"), fill=c("blue", "gray"))
title("Sesgo en CD para fumadores")

funnel(fitCDtab_deja, studlab=CDtab$ID[dejaCD],  contour = c(.95, 0.99), col.contour = c("blue", "gray"))
legend(1.15, 0, c("p<0.05", "p<0.01"), fill=c("blue", "gray"))
title("Sesgo en CD para ex-fumadores")

funnel(fitUCtab_fuma, studlab=UCtab$ID[fumaUC], contour = c(.95, 0.99), col.contour = c("blue", "gray"))
legend(1.15, 0, c("p<0.05", "p<0.01"), fill=c("blue", "gray"))
title("Sesgo en UC para fumadores")

funnel(fitUCtab_deja, studlab=UCtab$ID[dejaUC],  contour = c(.95, 0.99), col.contour = c("blue", "gray"))
legend(1.15, 0, c("p<0.05", "p<0.01"), fill=c("blue", "gray"))
title("Sesgo en UC para ex-fumadores")

# Contraste de asimetr�a del funnel plot mediante recta de Egger, usar funci�n metabias()
# En nuestro caso no se puede hacer porque requiere al menos 10 art�culos
# Dicho de otra forma, no podemos estudiar el sesgo con un test pq tenemos muy pocos art�culos

# Lo que podemos hacer es un "trim-and-fill"

trimCD_fuma <- trimfill(fitCDtab_fuma) # Concluye que se a�ade 1 estudio para eliminar asimetr�a
funnel(trimCD_fuma, contour = c(.95, 0.99), col.contour = c("blue", "gray"))
legend(1.15, 0, c("p<0.05", "p<0.01"), fill=c("blue", "gray"))
title("Trim-and-fill en CD para fumadores")
# Tama�o del efecto 2.0029; anterior 2.0558, no apreciable

trimCD_deja <- trimfill(fitCDtab_deja) # Concluye que se a�aden 2 estudios para eliminar asimetr�a
funnel(trimCD_deja, contour = c(.95, 0.99), col.contour = c("blue", "gray"))
legend(1.15, 0, c("p<0.05", "p<0.01"), fill=c("blue", "gray"))
title("Trim-and-fill en CD para ex-fumadores")
# Tama�o del efecto 0.9472, antes 1.01; en el l�mite pero no significativo

trimUC_fuma <- trimfill(fitUCtab_fuma) # Concluye que se a�aden 3 estudios para eliminar asimetr�a
funnel(trimUC_fuma, contour = c(.95, 0.99), col.contour = c("blue", "gray"))
legend(1.15, 0, c("p<0.05", "p<0.01"), fill=c("blue", "gray"))
title("Trim-and-fill en UC para fumadores")
# Obtiene un tam. efecto 1.0054, que comparamos con el inicial de 0.9779; no es un cambio significativo ya que en 
# ambos el IC encierra al valor 1

trimUC_deja <- trimfill(fitUCtab_deja) # Concluye que se a�aden 3 estudios para eliminar asimetr�a
funnel(trimUC_deja, contour = c(.95, 0.99), col.contour = c("blue", "gray"))
legend(1.15, 0, c("p<0.05", "p<0.01"), fill=c("blue", "gray"))
title("Trim-and-fill en UC para ex-fumadores")
# Tenemos tam. efecto de 1.0058 comparado con el 0.9866 de antes; otra vez no significativo el cambio

# Concluimos que se intuye que no hay sesgo, pero no se puede contrastar de forma eficaz pq tenemos 
# muy pocos estudios