#!/usr/bin/env bash

# Purpose: Convert ERA5 hourly forcing datasets for E3SM ELM to 6-hourly forcing datasets

if false; then
    # Spectral (Charlie's laptop)
    tm_rsn_hr=6 # Number of hours per output record
    drc_top=${DATA}/era5
    drc_tm_rsn=data_${tm_rsn_hr}hr
    drc_in=${drc_top}/data_1hr
else
    # Perlmutter (NERSC)
    tm_rsn_hr=6 # Number of hours per output record
    drc_top=/global/cfs/cdirs/e3sm/inputdata/atm/datm7
    drc_tm_rsn=atm_forcing.datm7.ERA.6HRLY.0.25d.v5.c180614
    drc_in=/global/cfs/cdirs/e3sm/inputdata/atm/datm7/atm_forcing.datm7.ERA.0.25d.v5.c180614
fi # !false

for yr in {1981..1981}; do
#for yr in {1982..1990}; do
    yyyy=`printf "%04d" $yr`

    # Process instantaneous variables
    for var_drc in tbot tdew pbot wind; do
	#for var_drc in wind; do
	cd ${drc_in}/${var_drc}
	drc_out=${drc_top}/${drc_tm_rsn}/${var_drc}
	mkdir -p ${drc_out}
	for fl_in in `ls *${yyyy}*.nc`; do
            # Select every sixth instantaneous timestep
	    cmd_ncrcat="ncrcat -O -d time,0,,${tm_rsn_hr} ${fl_in} ${drc_out}/${fl_in}"
	    echo "cmd_ncrcat = ${cmd_ncrcat}"
	    eval ${cmd_ncrcat}
	done # !fl_in
    done # !var_drc

    # Process time-mean variables
    for var_drc in prec lwdn swdn; do
	#for var_drc in prec; do
	cd ${drc_in}/${var_drc}
	drc_out=${drc_top}/${drc_tm_rsn}/${var_drc}
	mkdir -p ${drc_out}
	for fl_in in `ls *${yyyy}*.nc`; do
            # Average every six timesteps into a single group. Start with timestep 1 (0Z) not 0 (23Z the night before).
	    # Last timestep of month will contain mean of 5 timesteps from 18Z-23Z
	    cmd_ncra="ncra -O --mro -d time,1,,${tm_rsn_hr},${tm_rsn_hr} ${fl_in} ${drc_out}/${fl_in}"
	    echo "cmd_ncra = ${cmd_ncra}"
	    eval ${cmd_ncra}
	    # Shift timestamps from numeric means (3.5Z, 9.5Z, 15.5Z, 21.5Z) of 6-timestep hourly interval endpoint values (1Z, 2Z, ... 6Z), to 6-hour interval endpoints (6Z, 12Z, 18Z, 24Z)
	    # Last timestep in each month is average of 5 not 6 timesteps and so has endpoint value = 23.5Z 
	    # Fudge this from 23.5Z to 24Z to keep six hour intervals
	    cmd_ncap2="ncap2 -O -C -s 'time+=2.5/24;where(time == time.max()) time=time+0.5/24' ${drc_out}/${fl_in} ${drc_out}/${fl_in}"
	    echo "cmd_ncap2 = ${cmd_ncap2}"
	    eval ${cmd_ncap2}
	done # !fl_in
    done # !var_drc
done # !yr
