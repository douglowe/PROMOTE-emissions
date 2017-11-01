;
;  Program for converting SAFAR csv format emission data to a netcdf format
;
;  Input file format (csv):
;    file name = Gridded_Emission_SAFAR_CWG_2010.csv
;    1 header line (this script will break if it's more or less than 1 line!!!!)
;    all data lines, organised in columns:
;         0) REGID?
;         1) Latitude
;         2) Longitude
;         3) CO   Power
;         4) CO   Industrial
;         5) CO   Transport
;         6) CO   Residential
;         7) NOx   Power
;         8) NOx   Industrial
;         9) NOx   Transport
;        10) NOx  Residential
;        11) BC   Power
;        12) BC   Industrial
;        13) BC   Transport
;        14) BC   Residential
;        15) OC   Power
;        16) OC   Industrial
;        17) OC   Transport
;        18) OC   Residential
;        19) PM2.5   Power
;        20) PM2.5   Industrial
;        21) PM2.5   Transport
;        22) PM2.5   Residential
;        23) PM10   Power
;        24) PM10   Industrial
;        25) PM10   Transport
;        26) PM10   Residential
;        27) SO2  Power
;        28) SO2  Industrial
;        29) SO2  Transport
;        30) SO2  Residential
;        31) VOC  Power
;        32) VOC  Industrial
;        33) VOC  Transport
;        34) VOC  Residential
;
;;;;;;;;;;;;;;;; Is this still true?
;;;;;;  Input Latitude and Longitude are for lower left corner of the grid cell
;;;;;;  Emissions are in (metric?) tonnes per year per grid cell
;  
;  The positions for these compounds will be determined by filtering the header information.
;
;
;
;
;  Output file format (netcdf):
;      file name = SAFAR_[SPC]_2015.nc
;      2 dimensions:
;           lat - number of latitude values
;           lon - number of longitude values
;      6 variables (and their dimensions):
;           lat(lat) - latitude values (in degrees_north) for center_of_cell
;           lon(lon) - longitude values (in degrees_east) for center_of_cell
;           ind(lat,lon) - industrial sector emissions for SPC
;           pow(lat,lon) - power sector emissions for SPC
;           res(lat,lon) - residential sector emissions for SPC
;           tra(lat,lon) - transport sector emissions for SPC
;
;      Output files for the 8 emission SPC's will be generated.
;
;
load "./acsii_netcdf_convert_routines.ncl"
load "./emission_conversion_routines.ncl"

begin
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Configuration Information ;;;;;;;;;;;;;;;;;;;;;;;
input_path = "../SAFAR_raw_data/"
input_file = "Gridded_Emission_SAFAR_CWG_2010_With_WindBlown_Dust.csv"


input_sectors = (/"industrial","power","residential","transport"/)
output_sectors = (/"ind","pow","res","tra"/)  ; has to be same order as input_sectors!!!!!

output_path = "./"
output_head = "SAFAR_"
output_tail = "_2015.nc"

input_var_names  = (/"SO2","NOX","CO","PM10","PM2.5","BC","OC","VOC"/) 
output_var_names = (/"SO2","NOX","CO","PM10","PM2_5","BC","OC","NMVOC"/)  ; keep order same as var_names_in!!!!

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; End of Configuration Information ;;;;;;;;;;;;;;;;

print("== Reading input files ==")

;;; define the number of columns (this will be Lat, Lon, Var1, Var2, etc)
ncols = 2 + dimsizes(input_var_names)
;;; define the number of sectors
nsecs = dimsizes(input_sectors)

;;; load data from input files - this will be 3 dimensional (nsectors, nrows, ncols)
;;;      				- it will only work if all input files are the same size!
entire_data_table = read_all_input_data(ncols,nsecs,input_path,input_file,input_sectors,input_var_names)
;;; 1st column is longitude, 2nd column is latitude, 3rd+ are variables


;;; determine number of rows
ndims = dimsizes(entire_data_table)
nrows = ndims(1)
delete(ndims)


print("== Creating the Lat/Lon grids from input information ==")
;;; create the "lat" and "lon" variables, which will define the data grid
;;;    this process simply sorts all unique values into ascending order
lon_output = create_latlon_array(entire_data_table,0)
lat_output = create_latlon_array(entire_data_table,1)

;;; determine the number of longitude and latitude data points
nlon = dimsizes(lon_output)
nlat = dimsizes(lat_output)

;;; create grid of conversion factors, from Gg/Yr/grid to kg/m2/s
;convert_grid = conversion_tyrgrid_to_kgm2s_calc(lon_output,lat_output)
convert_grid = conversion_Ggyrgrid_to_kgm2s_calc(lon_output,lat_output)




;;; process each of the data sets we're loading
do vari = 0, dimsizes(output_var_names)-1
	print("=== Processing variable '"+output_var_names(vari)+"' ===")

	;;; set the pointer for the variable in the original data file (need to account for extra columns for long and lat)
	var_point = vari + 2

	;;; create the output data tables - these will be 3 dimensional (nsectors, nlat, lon)
	data_table := create_table(lon_output,lat_output,nsecs,ncols,nrows,nlon,nlat,entire_data_table,var_point)

	;;; convert the emission variable from T/yr/grid to kg/m2/s
	do seci = 0,nsecs-1
		data_table(seci,:,:) = data_table(seci,:,:)*convert_grid
	end do

	print("== Creating the output file ==")
	filename = output_head+output_var_names(vari)+output_tail
	;;; create the netcdf file, and dimensions, global attributes, and latitude & longitude data
	OUTFILE = netcdf_file_create(output_path,filename,nlat,nlon,lat_output,lon_output,output_sectors)


	;;; save data in netcdf file
	save_variable_data(OUTFILE,data_table,output_sectors)


end do


end ; end program