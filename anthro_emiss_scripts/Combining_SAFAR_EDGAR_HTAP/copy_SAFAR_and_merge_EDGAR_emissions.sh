#!/bin/bash 

SRCDIR='../SAFAR/' 
fileroot='wrfchemi_'
times=( '00z' '12z' )
domains=( 'd01' 'd02' 'd03' 'd04' )
year='2015'
months=( '01' '02' '03' '04' '05' '06' '07' '08' '09' '10' '11' '12' )

EDGARDIR='../EDGAR_HTAP/'

for MONTH in ${months[@]}; do
	for TIME in ${times[@]}; do
		for DOM in ${domains[@]}; do
	
			filename=${fileroot}${TIME}_${DOM}_${year}_${MONTH}

			# copy the SAFAR emission file
			cp ${SRCDIR}${filename} ${filename}


			echo running merge script on $DOM
			# merge the emissions data from EDGAR into these files
			#     we use | instead of / as delimiter, in order to avoid problems with '/' in filepaths
			sed "s|%%file%%|${filename}|g" merge_emissions_template.ncl > merge_emiss.temp1.ncl # set the filename
			sed "s|%%edgar%%|"${EDGARDIR}"${filename}|g" merge_emiss.temp1.ncl > merge_emiss.temp2.ncl  # set the month

			ncl merge_emiss.temp2.ncl &> log_merge_${TIME}_${DOM}_${MONTH}.txt


		done
	done
done
