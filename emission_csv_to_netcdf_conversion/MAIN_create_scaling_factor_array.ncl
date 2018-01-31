;
;  Program for converting creating a scaling factor netcdf file for TROPMET
;
;  Run this after you have run the MAIN_SAFAR_2015_convert_csv_to_netcdf.ncl script
;
;  Output file format (netcdf):
;      file name = SAFAR_SCALE_2015.nc
;      2 dimensions:
;           lat - number of latitude values
;           lon - number of longitude values
;      3 variables (and their dimensions):
;           lat(lat) - latitude values (in degrees_north) for center_of_cell
;           lon(lon) - longitude values (in degrees_east) for center_of_cell
;           scale(lat,lon) - 1's where there is SAFAR data, 0's otherwise
;
load "./acsii_netcdf_convert_routines.ncl"
load "./emission_conversion_routines.ncl"

begin
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Configuration Information ;;;;;;;;;;;;;;;;;;;;;;;
input_path = "/nerc/n02/n02/lowe/emissions_files/input_data/TROPMET/generate_emission_netcdfs/2015_processed_data/"
input_file = "SAFAR_PM10_2015.nc"

input_sectors = (/"ind","pow","res","tra","wbd"/)  ; has to be same order as input_sectors!!!!!

output_path = "/nerc/n02/n02/lowe/emissions_files/input_data/TROPMET/generate_emission_netcdfs/2015_processed_data/"
output_file = "SAFAR_SCALE_2015.nc"
output_sectors = (/"scale"/)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; End of Configuration Information ;;;;;;;;;;;;;;;;

print("== Reading input files ==")

;;; open input file
INFILE = addfile(input_path+input_file,"r")

;;; load lat and lon data
lat_output = INFILE->lat
lon_output = INFILE->lon

;;; determine the number of longitude and latitude data points
nlon = dimsizes(lon_output)
nlat = dimsizes(lat_output)


;;; create the netcdf file, and dimensions, global attributes, and latitude & longitude data
OUTFILE = netcdf_file_create(output_path,output_file,nlat,nlon,lat_output,lon_output,output_sectors)


;;; add up all the emissions input (so we don't miss any locations)
emiss = (/INFILE->$input_sectors(0)$/)
do vari = 1, dimsizes(input_sectors)-1
	emiss = emiss + (/INFILE->$input_sectors(vari)$/)
end do

;;; create our array of 1's where there are emission data
data_table = where(emiss.gt.0,1,0)

;;; save data in netcdf file
OUTFILE->$output_sectors(0)$ = data_table





end ; end program