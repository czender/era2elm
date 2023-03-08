#!/usr/bin/env bash

# Purpose: Analyze statistics of ERA5 aphysical inferred diffuse fluxes

# Usage:
# screen
# time era_swrf_anl.sh > ~/era_swrf_anl.out 2>&1 &
# Ctl-A D # Detach screen
# screen -ls # list screens
# screen -r <ID> # re-attach screen

drc_in=/global/cfs/cdirs/e3sm/inputdata/atm/datm7/atm_forcing.datm7.ERA.0.25d.v5.c180614/data_out/swdn
cd ${drc_in}
for yyyy in 1980; do
#    if false; then
    for mth in {1..12}; do
        mm=`printf "%02d" $mth`
	fl_msdwswrf="elmforc.ERA5.c2018.0.25d.msdwswrf.${yyyy}-${mm}.nc"
	fl_msdrswrf="elmforc.ERA5.c2018.0.25d.msdrswrf.${yyyy}-${mm}.nc"
	fl_err="${DATA}/era5/clm/era5_msdfswrf_err_${yyyy}${mm}.nc"
	fl_err_stt="${DATA}/era5/clm/era5_msdfswrf_err_stt_${yyyy}${mm}.nc"
	fl_err_ttl="${DATA}/era5/clm/era5_msdfswrf_err_ttl_${yyyy}${mm}_t.nc"
	fl_err_avg="${DATA}/era5/clm/era5_msdfswrf_err_avg_${yyyy}${mm}_t.nc"
	echo "Processing ${fl_in}..."
	ncbo -O ${fl_msdwswrf} ${fl_msdrswrf} ${fl_err}
	ncap2 -O -4 -v -s 'msdfswrf_err=float(msdfswrf);msdfswrf_err=msdfswrf_err << 0.0f;err_flg=0*msdfswrf_err;where(msdfswrf < 0.0f) err_flg=1; elsewhere err_flg=0;err_ttl=err_flg.total();nbr_ttl=msdfswrf.size();err_frc=1.0*err_ttl/nbr_ttl' ${fl_err} ${fl_err_stt}
	ncra -O -y ttl -v err_flg ${fl_err_stt} ${fl_err_ttl}
	ncra -O ${fl_err_stt} ${fl_err_avg}
    done # !mth
#    fi # !false

    # Annual cycle of errors
    ncrcat -O ${DATA}/era5/clm/era5_msdfswrf_err_ttl_${yyyy}??_t.nc ${DATA}/era5/clm/era5_msdfswrf_err_ttl_${yyyy}0112_t.nc
    ncrcat -O ${DATA}/era5/clm/era5_msdfswrf_err_avg_${yyyy}??_t.nc ${DATA}/era5/clm/era5_msdfswrf_err_avg_${yyyy}0112_t.nc

    # Annual mean of errors
    ncra -O -y ttl ${DATA}/era5/clm/era5_msdfswrf_err_ttl_${yyyy}0112_t.nc ${DATA}/era5/clm/era5_msdfswrf_err_ttl_${yyyy}_t.nc
    ncra -O ${DATA}/era5/clm/era5_msdfswrf_err_avg_${yyyy}0112_t.nc ${DATA}/era5/clm/era5_msdfswrf_err_avg_${yyyy}_t.nc

    # Copy to e3sm
    # rsync ${DATA}/era5/clm/era5_msdfswrf_err_ttl_${yyyy}_t.nc e3sm.ess.uci.edu:
    # rsync ${DATA}/era5/clm/era5_msdfswrf_err_avg_${yyyy}_t.nc e3sm.ess.uci.edu:

    # Copy to laptop
    # rsync 'e3sm.ess.uci.edu:era5_msdfswrf_err_*.nc' ${DATA}/era5/clm
    
    # Add grid for plotting ${HOME}/era5_rdr_skl.nc
    # ncks -A -C -v area ${HOME}/era5_rdr_skl.nc ${DATA}/era5/clm/era5_msdfswrf_err_ttl_${yyyy}_t.nc
    # ncks -A -C -v area ${HOME}/era5_rdr_skl.nc ${DATA}/era5/clm/era5_msdfswrf_err_avg_${yyyy}_t.nc
    
done # !yyyy
