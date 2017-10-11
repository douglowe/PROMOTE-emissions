;
;  Program for converting SAFAR csv format emission data to a netcdf format
;
;  Input file format (csv):
;    file name = dehli_[sector].csv
;    1 header line (this script will break if it's more or less than 1 line!!!!)
;    all data lines, organised in columns:
;         0) Longitude
;         1) Latitude
;         2) REGID?
;         3) SO2
;         4) NOx
;         5) CO
;         6) PM10
;         7) PM2_5
;         8) BC
;         9) OC
;        10) NMVOC
;
;  Input Latitude and Longitude are for lower left corner of the grid cell
;  Emissions are in (metric?) tonnes per year per grid cell
;  
;  Input files are for 4 sectors: industrial, power, residential, transport
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
input_path = "../SAFAR_data/"
input_head = "dehli_"
input_tail = ".csv"

input_sectors = (/"industrial","power","residential","transport"/)
output_sectors = (/"ind","pow","res","tra"/)  ; has to be same order as input_sectors!!!!!

output_path = "./"
output_head = "SAFAR_"
output_tail = "_2015.nc"

var_names = (/"SO2","NOX","CO","PM10","PM2_5","BC","OC","NMVOC"/) ; has to be in the order of data in the input files!

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; End of Configuration Information ;;;;;;;;;;;;;;;;

print("== Reading input files ==")

;;; define the number of columns
ncols = 3 + dimsizes(var_names)
;;; define the number of sectors
nsecs = dimsizes(input_sectors)

;;; load data from input files - this will be 3 dimensional (nsectors, nrows, ncols)
;;;      				- it will only work if all input files are the same size!
entire_data_table = read_all_input_data(ncols,nsecs,input_path,input_head,input_tail,input_sectors)

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

;;; create grid of conversion factors, from T/Yr/grid to kg/m2/s
convert_grid = conversion_tyrgrid_to_kgm2s_calc(lon_output,lat_output)




;;; process each of the data sets we're loading
do vari = 0, dimsizes(var_names)-1
	print("=== Processing variable '"+var_names(vari)+"' ===")

	;;; set the pointer for the variable in the original data file
	var_point = vari + 3

	;;; create the output data tables - these will be 3 dimensional (nsectors, nlat, lon)
	data_table := create_table(lon_output,lat_output,nsecs,ncols,nrows,nlon,nlat,entire_data_table,var_point)

	;;; convert the emission variable from T/yr/grid to kg/m2/s
	do seci = 0,nsecs-1
		data_table(seci,:,:) = data_table(seci,:,:)*convert_grid
	end do

	print("== Creating the output file ==")
	filename = output_head+var_names(vari)+output_tail
	;;; create the netcdf file, and dimensions, global attributes, and latitude & longitude data
	OUTFILE = netcdf_file_create(output_path,filename,nlat,nlon,lat_output,lon_output,output_sectors)


	;;; save data in netcdf file
	save_variable_data(OUTFILE,data_table,output_sectors)


end do


end ; end program