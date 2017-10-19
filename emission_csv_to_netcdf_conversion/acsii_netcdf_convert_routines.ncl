;
;  function for loading csv input data files, and gather them into a single data array
;
;
undef("read_all_input_data")
function read_all_input_data(ncols:numeric,nsecs:numeric,input_path:string,input_head:string,\
								input_tail:string,input_sectors:string)
local start, datatype, head_length, ii, filename, \
		data_table, ndims, nrows, nrows_start, entire_data_table
begin

	start = True
	datatype = "float" ; define what type of data we're loading
	head_length = 1    ; define how many header lines in each file

	; loop through the input sectors
	do ii = 0,nsecs-1

		filename = input_path + input_head + input_sectors(ii) + input_tail

		; read raw data file
		data_table := readAsciiTable(filename,ncols,datatype,head_length)
	
		; obtain the number of rows
		ndims = dimsizes(data_table)
		nrows = ndims(0)	


		; with the first data file, create the data array, otherwise check dimensions are consistent
		if(start)
			entire_data_table = new((/nsecs,nrows,ncols/),float,-9999.0)
			nrows_start = nrows
			start = False
		else
			if(nrows.ne.nrows_start)
				print("mismatch in input file lengths, stopping script")
				print("length of "+input_sectors(0)+" data is "+nrows_start)
				print("length of "+input_sectors(ii)+" data is "+nrows)
				exit()
			end if
		end if
	
		; copy model data into data array
		entire_data_table(ii,:,:) = data_table	
	
	end do ; ii=0,dimsizes(input_sectors)-1


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



