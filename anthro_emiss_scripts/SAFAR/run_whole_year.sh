#!/bin/bash

#
#  script for looping through months of year, generating emissions.
#
#  Directory must contain:
#      anthro_emis
#      wrfinput_d01 to wrfinput_d04
#      input_data   ---- link to the SAFAR dataset, containing the 2015_data folder 
#      edgar_monthly_data_template.inp --- template config file

year='2015'

for ii in {1..12};do
	
	if [ $ii -lt 10 ]
	then
		rep="0$ii"
	else
		rep="$ii"
	fi
	sed "s/%%AA%%/$rep/g" safar_data_and_dust_template.inp > safar_data_and_dust.temp.inp	

	echo "processing month ${rep}"

	./anthro_emis < safar_data_and_dust.temp.inp &> anthro_${rep}.log

	for jj in {1..4};do
		mv wrfchemi_00z_d0${jj} wrfchemi_00z_d0${jj}_${year}_${rep}
		mv wrfchemi_12z_d0${jj} wrfchemi_12z_d0${jj}_${year}_${rep}
	done

done



