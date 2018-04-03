;
;  function for loading csv input data files, and gather them into a single data array
;
;
undef("read_all_input_data")
function read_all_input_data(ncols:numeric,nsecs:numeric,input_path:string,input_file:string,\
								input_sectors:string,input_var_names:string)
local start, datatype, head_length, front, filename, data_head, ncol_data, \
		data_table, ndims, nrows, entire_data_table, vname, vind, ii, jj
begin

	start = True
	datatype = "float" ; define what type of data we're loading
	head_length = 1    ; define how many header lines in each file
	front = "UNIQUE_"

	; set file name to read
	filename = input_path + input_file
	
	; read the header, and split by ","
	data_head = readAsciiHead(filename,head_length)
	data_head := str_split(data_head, ",")
	; add front end to strings, for uniqueness checking later
	data_head := front + data_head
	
	; get the number of data columns using heading data
	ncol_data = dimsizes(data_head)
	
	; read raw data file
	data_table = readAsciiTable(filename,ncol_data,datatype,head_length)

	; obtain the number of rows in the dataset
	ndims = dimsizes(data_table)
	nrows = ndims(0)	

	; create our data array (# sectors, # rows, #(Lat Lon Var1 Var2 etc) )
	entire_data_table = new((/nsecs,nrows,ncols/),float,-9999.0)

	; determine latitude & longitude pointers
	lat_ind = str_match_ind_ic(data_head,"lat")
	lon_ind = str_match_ind_ic(data_head,"long")


	; loop through the input sectors
	do ii = 0,nsecs-1
	
		; copy longitude data
		entire_data_table(ii,:,0) = data_table(:,lon_ind)		
		; copy latitude data
		entire_data_table(ii,:,1) = data_table(:,lat_ind)		

	
		; loop through the emission variables
		do jj = 0,ncols-3

			; construct variable / sector name, using the front end info, and get index
			vname = front + input_var_names(jj)+"_"+input_sectors(ii)
			vind  := str_match_ind_ic(data_head,vname)
	
			; check that the variable/sector exists (i.e. vind is real), if not then
			;   set the data for this sector to zero
			if(.not. any(ismissing(vind)))	
				; copy model data into data array
				entire_data_table(ii,:,jj+2) = data_table(:,vind)
			else
				print("no data for "+vname+" exists - setting this to zero")
				entire_data_table(ii,:,jj+2) = 0.0
			end if
	
		end do ; jj=0,ncols-1

	end do ; ii=0,nsecs-1


	return(entire_data_table)


end 

;
;  Function for creating a 1-D ascending list of values from the input data array
;
;  Assumes a 3D array, of shape (nsectors, nrows, ncols)
;
;  This function will only work with NCL versions 6.3.0 or later
;
undef("create_latlon_array")
function create_latlon_array(entire_data_table:numeric,col_num:numeric)
local oneD_data, unique_data
begin

	; pull out all longitude or latitude data, and store as 1D list
	oneD_data = ndtooned(entire_data_table(:,:,col_num))

	; get all unique values
	unique_data = get_unique_values(oneD_data)

	; sort unique values into ascending order
	qsort(unique_data)

	return(unique_data)

end

;
;  Function for increasing a 1D data array by 1 at each end, and then
;    adding an extra data point (with the same step size as adjacent data)
;
undef("increase_latlon_array_byone")
function increase_latlon_array_byone(array_temp:numeric)
local array_output, narray
begin

	;;; increase array size by 2
	array_output = new(dimsizes(array_temp)+2,typeof(array_temp),-9999.)

	;;; determine the number of data points
	narray = dimsizes(array_output)

	;;; save the data in the new data array
	array_output(1:narray-2) = array_temp
	;;; create the extra datapoints, assuming we've got a regular grid
	array_output(0) = array_output(1) + (array_output(1) - array_output(2))
	array_output(narray-1) = array_output(narray-2) + (array_output(narray-2) - array_output(narray-3))

	return(array_output)

end


;
;  Function for calculating the centre position of a grid cell, from the lower edge value provided
;     assuming that the array spacing is monotic
;
undef("derive_centre_values_from_lower_values")
function derive_centre_values_from_lower_values(array_temp:numeric)
local array_output, narray
begin

	;;; create output array
	array_output = new(dimsizes(array_temp),typeof(array_temp),-9999.)

	;;; determine the number of data points
	narray = dimsizes(array_output)

	;;; for most of the array we simply take the geometric average of the lower/upper boundaries
	array_output(0:narray-2) = (array_temp(0:narray-2)+array_temp(1:narray-1))/2.0
	;;; for the final grid cell we will assume monoticity, and take add half the width of the previous gridcell
	array_output(narray-1) = array_temp(narray-1) + (array_temp(narray-1)-array_temp(narray-2))/2.0

	return(array_output)

end


;
;  Function for creating a 3-D array of sector on the lat / lon grid
;
;  input: entire_data_table (nsecs,nrows,ncols)
;
;  output: data_table (nsecs,nlon,nlat)
;
undef("create_table")
function create_table(lon_output:numeric,lat_output:numeric,nsecs:numeric,ncols:numeric,\
									nrows:numeric,nlon:numeric,nlat:numeric,\
									entire_data_table:numeric,var_point:numeric)
local data_table, ii, longitude, latitude, ilat, ilon 
begin

	; create output data array
	data_table = new((/nsecs,nlat,nlon/),float,-9999.)
	
	; set the background emissions to zero
	data_table = 0.0
	
	; loop through the rows in the input array
	do ii = 0,nrows-1
	
		; grab longitude and latitude data for this row
		longitude := get_unique_values(entire_data_table(:,ii,0))
		latitude  := get_unique_values(entire_data_table(:,ii,1))
		
		; ensure each is only one value, if not crash out of program
		if(dimsizes(longitude).ne.1 .or. dimsizes(latitude).ne.1)
			print("on row "+ii+" there are multiple longitudes / latitudes")
			print(longitude)
			print(latitude)
			exit()
		end if
		
		
		; loop through lat_output list looking for value
		do ilat = 0,nlat-1
			if(latitude .eq. lat_output(ilat))
				
				; then loop through lon_output list looking for value
				do ilon = 0,nlon-1
					if(longitude .eq. lon_output(ilon))
						data_table(:,ilat,ilon) = entire_data_table(:,ii,var_point)
						break ; exit ilon do loop
					end if
				end do ; ilon
				
				; exit ilat do loop
				break
			end if
		end do ; ilat
	
	
	end do ; ii=0,nrows-1


	return(data_table)

end


;
;  Creates the output netcdf file
;
;  This is based on the EDGAR HTAP data files - which have no time information
;
;
undef("netcdf_file_create")
function netcdf_file_create(filepath:string,filename:string,nlat:numeric,nlon:numeric,
											lat_data:numeric,lon_data:numeric,\
											var_names:string)
local OUTFILE, dimNames, dimSizes, dimUnlim, globalatt, Data_Var, vari
begin

	; check if the file exists already, if so then back the old file up
	if(fileexists(filepath+filename))
		system("mv "+filepath+filename+" "+filepath+filename+".backup")
	end if

	; create output file
	OUTFILE = addfile(filepath+filename,"c")
	
	
	;;;; define the dimensions
	;; lat  -> use number of rows
	;; lon  -> use number of columns
	dimNames = (/"lat","lon"/)
	dimSizes = (/nlat,nlon/)
	dimUnlim = (/False,False/) 
	
	;;;; define the global attributes
	globalAtt = True
	globalAtt@info = "Test file"
	
	;;;; name the dimensions for lat and lon data
	lat_data!0 = "lat"
	lon_data!0 = "lon"
	lat_data@units = "degrees_north"
	lon_data@units = "degrees_east"
	lat_data@long_name = "latitude"
	lon_data@long_name = "longitude"

	
	;;;; create a dummy data variable
	Data_Var = new((/nlat,nlon/),float,-9999)
	Data_Var!0 = "lat"
	Data_Var!1 = "lon"
	Data_Var@units = "kg m-2 s-1"
	
	;;;; define the file settings
	setfileoption(OUTFILE,"DefineMode",True)
	
		; set file attributes
		filedimdef(OUTFILE,dimNames,dimSizes,dimUnlim)
		fileattdef(OUTFILE,globalAtt)
	
		; create the lat and lon data arrays
		filevardef(OUTFILE, "lat", typeof(lat_data), getvardims(lat_data))                          
		filevardef(OUTFILE, "lon", typeof(lon_data), getvardims(lon_data))                          
		filevarattdef(OUTFILE, "lat", lat_data)
		filevarattdef(OUTFILE, "lon", lon_data)
			
		; create the data arrays
		do vari = 0, dimsizes(var_names)-1
			filevardef(OUTFILE, var_names(vari), typeof(Data_Var), getvardims(Data_Var))                          
			filevarattdef(OUTFILE, var_names(vari), Data_Var)
		end do
		
	setfileoption(OUTFILE,"DefineMode",False)

	;;;; copy time and position data over to the file
	OUTFILE->lat = (/lat_data/)
	OUTFILE->lon = (/lon_data/)


	; return output file handle
	return(OUTFILE)


end




undef("save_variable_data")
procedure save_variable_data(OUTFILE:file,data_table:numeric,var_names:string)
local ii
begin

	do ii = 0,dimsizes(var_names)-1
		;;; copy data to the new variable
		OUTFILE->$var_names(ii)$ = (/data_table(ii,:,:)/)
	end do

end



