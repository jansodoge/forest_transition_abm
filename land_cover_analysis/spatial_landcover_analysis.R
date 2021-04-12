library(sf)
library(raster)
library(spData)
library(stringr)
library(tidyverse)





#get state level data
states <- sf::read_sf("states/dest2019gw.shp")

#1997
geo_data_1997 <- sf::read_sf("1997/usv250kcs1agw.shp")
shape_areas <- st_area(geo_data_1997)
geo_data_1997$area <- shape_areas
geo_data_1997$year <- 1997

#2001 geodata
geo_data_2001 <- sf::read_sf("2001/usv250ks2gw.shp")
shape_areas <- st_area(geo_data_2001)
geo_data_2001$area <- shape_areas
geo_data_2001$year <- 2001

#2005 geodata
geo_data_2005 <- sf::read_sf("2005/usv250ks3gw.shp")
shape_areas <- st_area(geo_data_2005)
geo_data_2005$area <- shape_areas
geo_data_2005$year <- 2005

#2009 geodata
geo_data_2009 <- sf::read_sf("2009/usv250ks4gw.shp")
shape_areas <- st_area(geo_data_2009)
geo_data_2009$area <- shape_areas
geo_data_2009$year <- 2009


#2013 geodata
geo_data_2013 <- sf::read_sf("2013/usv250s5ugw.shp")
shape_areas <- st_area(geo_data_2013)
geo_data_2013$area <- shape_areas
geo_data_2013$year <- 2013


#2016 geodata
geo_data_2016 <- sf::read_sf("2016/usv250s6gw.shp")
shape_areas <- st_area(geo_data_2016)
geo_data_2016$area <- shape_areas
geo_data_2016$year <- 2016





land_cover_types <- read_csv("land_cover_types.csv") %>% 
  filter(type != "null")



#merging with prior data



geo_data_1997 <- geo_data_1997 %>% 
  left_join(land_cover_types, by = c("descripcio"="descripcio"))



geo_data_2001 <- geo_data_2001 %>% 
  left_join(land_cover_types, by = c("descripcio"="descripcio"))


geo_data_2005 <- geo_data_2005 %>% 
  left_join(land_cover_types, by = c("descripcio"="descripcio"))



geo_data_2009 <- geo_data_2009 %>% 
  left_join(land_cover_types, by = c("descripcio"="descripcio"))



geo_data_2013 <- geo_data_2013 %>% 
  left_join(land_cover_types, by = c("descripcio"="descripcio"))



geo_data_2016 <- geo_data_2016 %>% 
  left_join(land_cover_types, by = c("DESCRIPCIO"="descripcio")) %>% 
  mutate(descripcio = DESCRIPCIO)



long_geodata_list <- list(geo_data_2001, geo_data_2005, geo_data_2009, geo_data_2013, geo_data_2016)





generate_plot_data_for_state <- function(state_name, long_geodata_list){
  
  
  oaxaca = states[states$NOM_ENT == state_name, ]
  
  intersected_geodata_list <- list()
  
  for(geodata in long_geodata_list){
    
    intersect <- sf::st_intersection(oaxaca, geodata)
    intersected_geodata_list <- list.append(intersected_geodata_list, intersect)
    print("Edit per Year:: DONE")
    
  }
  
  
  
  spatial_attributes_dataset <- data.frame()
  for(data in intersected_geodata_list){
    
    tmp_data <- data
    st_geometry(tmp_data) <- NULL
    tmp_data <- as.data.frame(tmp_data)
    print(colnames(tmp_data))
    tmp <- tmp_data %>% 
      select(year, type, area)
    spatial_attributes_dataset <- dplyr::bind_rows(spatial_attributes_dataset, tmp_data)
    
  }
  
return(spatial_attributes_dataset)  
  
}




#For each state calculate area covered by particular land-cover type
results <- data.frame()
for(elem in states$NOM_ENT){
  
  
  tmp <- generate_plot_data_for_state(elem, long_geodata_list)
  tmp$state_measured <- elem
  results <- dplyr::bind_rows(results, tmp)
  print(paste(elem, "measured"))
  
}




#Produces a file that will be analysed within further scripts
#gis_analysis_data.csv






