#!/bin/bash

#
#  Script for generating a single set of emission files from the TROPMET
#  dataset. The seasonal cycle will be applied later.
#
#  Directory must contain:
#      anthro_emis
#      wrfinput_d01 to wrfinput_d04
#      input_data   ---- link to the TROPMET dataset, containing the files:
#						SAFAR_BC_2015.nc  
#						SAFAR_NMVOC_2015.nc  
#						SAFAR_OC_2015.nc    
#						SAFAR_PM2_5_2015.nc
#						SAFAR_CO_2015.nc  
#						SAFAR_NOX_2015.nc    
#						SAFAR_PM10_2015.nc  
#						SAFAR_SO2_2015.nc
#						(if the file names differ then alter the config file)
#      tropmet_data_and_dust.inp --- anthro_emiss config file

year='2010'


./anthro_emis < tropmet_data_and_dust.inp &> anthro.log

for jj in {1..4};do
	mv wrfchemi_00z_d0${jj} wrfchemi_00z_d0${jj}_${year}
	mv wrfchemi_12z_d0${jj} wrfchemi_12z_d0${jj}_${year}
done




