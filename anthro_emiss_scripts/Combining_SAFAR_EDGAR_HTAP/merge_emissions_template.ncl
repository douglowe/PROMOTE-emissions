;
;    Script for merging the SAFAR data into 
;    the global EDGAR/HTAP data set for domain 4
;
;    This script uses the "SCALE" variable for SAFAR
;    to identify where this data would be, and what
;    fraction of the grid cell should be SAFAR data
;
;


;*********************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"


begin 
;;; define the running parameters ;;;;;;;;;;;;;;;;;
file_name = (/"%%file%%"/)
edgar_file = (/"%%edgar%%"/)


;;; start the actual processing code ;;;;;;;;;;;;;;

print("merging emissions for file "+file_name)

;; open file for writing
FILE = addfile(file_name+".nc","w")
EDGAR = addfile(edgar_file+".nc","r")

;; get the list of variable names in this file
var_list = getfilevarnames(FILE)
;; get the list of variable names in the edgar file too
edgar_list = getfilevarnames(EDGAR)

;; pull out the SCALE variable from file
scale = (/FILE->E_SCALE/)
;; convert back to a 0-1 scale
scale = scale / 1e9


;; loop through the list of variables, only modifying the emissions that exist in both files
do mm = 0, dimsizes(var_list)-1
	if(isStrSubset(var_list(mm),"E_") .and. any(.not.ismissing(str_match(edgar_list,var_list(mm)))))
		print("processing variable "+var_list(mm))
		var_proc := (/FILE->$var_list(mm)$/)
		var_edgar := (/EDGAR->$var_list(mm)$/)
		
		if(sum(var_proc).gt.0.0)
			print("  merging SAFAR and EDGAR emissions")
			var_new := var_proc + (var_edgar * (1-scale))
						
			
		else ; if there is no data for this variable in the new dataset, then just use EDGAR
			print("  copying EDGAR emissions")
			var_new := var_edgar
			
		end if
		
		FILE->$var_list(mm)$ = (/var_new/)

	else if(isStrSubset(var_list(mm),"E_"))
		print("no change to variable "+var_list(mm))

	end if
	end if
end do


; close the files
delete(FILE)
delete(EDGAR)


end
