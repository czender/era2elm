#!/usr/bin/env bash

# Purpose: Analyze statistics of ERA5 aphysical inferred diffuse fluxes

# Usage:
# screen
# time era_swrf_anl.sh > ~/era_swrf_anl.out 2>&1 &
# Ctl-A D # Detach screen
# screen -ls # list screens
# screen -r <ID> # re-attach screen

drc_in=/global/cfs/cdirs/e3sm/inputdata/atm/datm7/atm_forcing.datm7.ERA.0.25d.v5.c180614/swdn
cd ${drc_in}
for yyyy in 1980; do
    for mth in {1..12}; do
#    for mth in 12; do
        mm=`printf "%02d" $mth`
	fl_in="elmforc.ERA5.c2018.0.25d.msdfswrf.${yyyy}-${mm}.nc"
	fl_out="${DATA}/era5/clm/era5_msdfswrf_err_stt_${yyyy}${mm}.nc"
	fl_out2="${DATA}/era5/clm/era5_msdfswrf_err_ttl_${yyyy}${mm}_t.nc"
	fl_out3="${DATA}/era5/clm/era5_msdfswrf_err_avg_${yyyy}${mm}_t.nc"
	echo "Processing ${fl_in}..."
	ncap2 -O -4 -v -s 'msdfswrf_err=float(msdfswrf);msdfswrf_err=msdfswrf_err << 0.0f;err_flg=0*msdfswrf_err;where(msdfswrf < 0.0f) err_flg=1; elsewhere err_flg=0;err_ttl=err_flg.total();nbr_ttl=msdfswrf.size();err_frc=1.0*err_ttl/nbr_ttl' ${fl_in} ${fl_out}
	ncks -O --mk_rec_dmn=time ${fl_out} ${fl_out}
#	ncks -A -v area ${fl_area} ${fl_out}
	ncra -O -y ttl -v err_flg ${fl_out} ${fl_out2}
	ncra -O ${fl_out} ${fl_out3}
    done # !mth
done # !yyyy
