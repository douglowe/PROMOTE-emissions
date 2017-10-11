;
;  Function for creating a 2D array of conversion factors from 
;    two 1D arrays of longitude and latitude points
;
;  Long / Lat arrays must define the lower left corner of the grid cell
;
;  Conversion is from Tonnes per yer per grid cell to kg per m^2 per second
;
undef("conversion_tyrgrid_to_kgm2s_calc")
function conversion_tyrgrid_to_kgm2s_calc(longitude:numeric,latitude:numeric)
local lon_steps, lat_steps, lon_step, lat_step, factor_grid, ilat, ilon, ll_len
begin

	;; determine the grid spacing (if the grid is not regular then this routine will fail!)
	;lon_steps = todouble(longitude(1:dimsizes(longitude)-1)) - todouble(longitude(0:dimsizes(longitude)-2))
	;lat_steps = todouble(latitude(1:dimsizes(latitude)-1)) - todouble(latitude(0:dimsizes(latitude)-2))
	lon_steps = longitude(1:dimsizes(longitude)-1) - longitude(0:dimsizes(longitude)-2)
	lat_steps = latitude(1:dimsizes(latitude)-1) - latitude(0:dimsizes(latitude)-2)

	;;; round to 4 decimal places
	;;     this is a massive fudge to get round machine accuracy issues in the maths above
	;;     and makes the check below less useful (though it will still catch large changes)
	lon_steps = decimalPlaces(lon_steps,4,True)
	lat_steps = decimalPlaces(lat_steps,4,True)

	;; find all unique values
	lon_step = get_unique_values(lon_steps)
	lat_step = get_unique_values(lat_steps)
	
	
	
	;;; check to make sure grid is regular, fail if not
	if(dimsizes(lon_step).ne.1 .or. dimsizes(lat_step).ne.1)
		print("grid is not regular, correct your grid spacing")
		print(lon_step)
		print(lat_step)
		exit()
	end if
	

	;; create the output array
	factor_grid = new((/dimsizes(latitude),dimsizes(longitude)/),float,-9999.)

	;; loop through grid cells
	do ilat = 0, dimsizes(latitude)-1
	do ilon = 0, dimsizes(longitude)-1
		
		;;; lat1 / lon1 are starting positions, and lat2 / lon2 are ending positions, in the order below
		;;; latlon_lengths(0) = length of West edge
		;;; latlon_lengths(1) = length of South edge
		;;; latlon_lengths(2) = length of East edge
		;;; latlon_lengths(3) = length of North edge
		lat1 = (/latitude(ilat),          latitude(ilat),           latitude(ilat),           latitude(ilat)+lat_step/)
		lon1 = (/longitude(ilon),         longitude(ilon),          longitude(ilon)+lon_step, longitude(ilon)/)
		lat2 = (/latitude(ilat)+lat_step, latitude(ilat),           latitude(ilat)+lat_step,  latitude(ilat)+lat_step/)
		lon2 = (/longitude(ilon),         longitude(ilon)+lon_step, longitude(ilon)+lon_step, longitude(ilon)+lon_step/)
		ll_len = gc_latlon(lat1,lon1,lat2,lon2,4,4)
	
		;; calculate area of grid cell in m2
		factor_grid(ilat,ilon) = ( (ll_len(0)+ll_len(2))/2.0 )*1000.0 * ( (ll_len(1)+ll_len(3))/2.0 )*1000.0
	
	end do
	end do

	;;; change factor from units of m2 to 1/m2
	factor_grid = 1.0/factor_grid

	;;; apply tonnes to kg conversion
	factor_grid = factor_grid * 1000.0
	
	;;; apply year^-1 to s^-1 conversion
	factor_grid = factor_grid / (60.0*60.0*24.0*365.0)


	return(factor_grid)

end