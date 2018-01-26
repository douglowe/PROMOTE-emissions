#
#  script for looping through months of year, generating emissions.
#
#  Directory must contain:
#      anthro_emis
#      wrfinput_d01 to wrfinput_d04
#      input_data   ---- link to the EDGAR_NMVOC dataset, containing 12 monthly directories (numbered 01 to 12) 
#      edgar_template_${SECT}.inp --- template config files (for the list of sectors below)
#

year='2015'


sectors=( 'AWB' 'ENE' 'FFF' 'IND' 'PPA' 'PRO' \
			'RCO' 'REF' 'SWD' 'TNR_Other' 'TNR_Ship' \
			'TRF' 'TRO' 'TNR_AV_CDS' 'TNR_AV_CRS' 'TNR_AV_LTO' )



for ii in {1..12};do

	if [ $ii -lt 10 ]
	then
		rep="0$ii"
	else
		rep="$ii"
	fi
	echo "processing month ${rep}"

	for SECT in ${sectors[@]};do

		echo "  processing sector ${SECT}"
		
		# modify the template config file
		sed "s/%%AA%%/$ii/g" edgar_template_${SECT}.inp > edgar_template.temp1.inp # set the month in filename
		sed "s/%%BB%%/$rep/g" edgar_template.temp1.inp > edgar_template.temp2.inp  # set the month in folder name


		./anthro_emis < edgar_template.temp2.inp &> anthro_${rep}_${SECT}.log

		# append the variables we need to the final output files
		#    (this will create the final output files if they do not exist already)
		for jj in {1..4};do
			ncks -A wrfchemi_00z_d0${jj} wrfchemi_00z_d0${jj}_${year}_${rep}
			ncks -A wrfchemi_12z_d0${jj} wrfchemi_12z_d0${jj}_${year}_${rep}
			rm wrfchemi_00z_d0${jj} wrfchemi_12z_d0${jj}
		done		
		
	done

done


