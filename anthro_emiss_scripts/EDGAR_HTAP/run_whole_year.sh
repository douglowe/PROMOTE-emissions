#!/bin/bash

#
#  script for looping through months of year, generating emissions.
#
#  Directory must contain:
#      anthro_emis
#      wrfinput_d01 to wrfinput_d04
#      input_data   ---- link to the EDGAR_HTAP dataset, containing 12 monthly directories (numbered 01 to 12) 
#      edgar_monthly_data_template.inp --- template config file

year='2010'

for ii in {1..12};do
	# modify the template config file
	sed "s/%%AA%%/$ii/g" edgar_monthly_data_template.inp > edgar_monthly_data_template.temp1.inp
	if [ $ii -lt 10 ]
	then
		rep="0$ii"
	else
		rep="$ii"
	fi
	sed "s/%%BB%%/$rep/g" edgar_monthly_data_template.temp1.inp > edgar_monthly_data_template.temp2.inp	

	echo "processing month ${rep}"

	./anthro_emis < edgar_monthly_data_template.temp2.inp &> anthro_${rep}.log

	for jj in {1..4};do
		mv wrfchemi_00z_d0${jj} wrfchemi_00z_d0${jj}_${year}_${rep}
		mv wrfchemi_12z_d0${jj} wrfchemi_12z_d0${jj}_${year}_${rep}
	done

done



