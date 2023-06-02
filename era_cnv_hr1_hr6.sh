#!/usr/bin/env bash

# Purpose: Convert ERA5 hourly forcing datasets for E3SM ELM to 6-hourly forcing datasets

# Interactive Usage:
# cd ~/era5;era_cnv_hr1_hr6.sh > ~/era5.txt 2>&1 &
# tail ~/era5.txt

# Perlmutter Batch Queue:
# ln -s ~/era5/era_cnv_hr1_hr6.sh ~/sh/era_cnv_hr1_hr6.sh
# echo '#!/bin/bash' > ~/era5.slurm
# echo "era_cnv_hr1_hr6.sh" >> ~/era5.slurm;chmod a+x ~/era5.slurm
# sbatch -A e3sm --constraint=cpu --nodes=1 --time=06:00:00 --qos=regular --job-name=era5 --mail-type=fail,end --mail-user=zender@uci.edu --output=${HOME}/era5.txt ~/era5.slurm # Perlmutter: ~20 minutes/year

# Instructions:
# Set yr_srt, yr_end to desired start and end years, respectively
# Cull unwanted directories from the default (full) lists in var_drc_nst, var_drc_avg
# Command-line options are not (yet) supported

dbg_lvl=1 # [nbr] Debugging level

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

# Directories containing instantaneous variables
var_drc_nst='tbot tdew pbot wind'
#var_drc_nst='tbot'

# Directories containing time-mean/accumulated variables
var_drc_avg='prec lwdn swdn'
#var_drc_avg='lwdn'

# Start and end years
yr_srt='2022'
yr_end='2022'

# Human-readable summary
date_srt=$(date +"%s")
if [ ${dbg_lvl} -ge 0 ]; then
    printf "era_cnv_hr1_hr6, an ERA5 hourly forcing dataset conversion tool\n"
    printf "Started creating ERA5 ${tm_rsn_hr}-hourly datasets from hourly datasets at `date`\n"
fi # !dbg

for yr in `seq ${yr_srt} ${yr_end}`; do
    [[ ${dbg_lvl} -ge 0 ]] && date_yr=$(date +"%s")
    yyyy=`printf "%04d" $yr`

    # Process instantaneous variables
    for var_drc in ${var_drc_nst}; do
	cd ${drc_in}/${var_drc}
	drc_out=${drc_top}/${drc_tm_rsn}/${var_drc}
	mkdir -p ${drc_out}
	for fl_in in `ls *.${yyyy}-??.nc`; do
            # Select every sixth instantaneous timestep
	    cmd_ncrcat="ncrcat -O -d time,0,,${tm_rsn_hr} ${fl_in} ${drc_out}/${fl_in}"
	    echo "cmd_ncrcat = ${cmd_ncrcat}"
	    eval ${cmd_ncrcat}
	done # !fl_in
    done # !var_drc

    # Process time-mean variables
    for var_drc in ${var_drc_avg}; do
	cd ${drc_in}/${var_drc}
	drc_out=${drc_top}/${drc_tm_rsn}/${var_drc}
	mkdir -p ${drc_out}
	for fl_in in `ls *.${yyyy}-??.nc`; do
            # Average every six timesteps into a single group. Start with timestep 1 (0Z) not 0 (23Z the night before).
	    # Last timestep of month will contain mean of 5 timesteps from 18Z-23Z
	    cmd_ncra="ncra -O --mro -d time,1,,${tm_rsn_hr},${tm_rsn_hr} ${fl_in} ${drc_out}/${fl_in}"
	    echo "cmd_ncra = ${cmd_ncra}"
	    eval ${cmd_ncra}
	    # Shift timestamps from numeric means (3.5Z, 9.5Z, 15.5Z, 21.5Z) of 6-timestep hourly interval endpoint values (1Z, 2Z, ... 6Z), to 6-hour interval endpoints (6Z, 12Z, 18Z, 24Z)
	    # Last timestep of each month is average of 5 not 6 timesteps and so has endpoint value = 23.5Z 
	    # Fudge this from 23.5Z to 24Z to keep regular six hour intervals for entire month
	    cmd_ncap2="ncap2 -O -C -s 'time+=2.5/24;where(time == time.max()) time=time+0.5/24' ${drc_out}/${fl_in} ${drc_out}/${fl_in}"
	    echo "cmd_ncap2 = ${cmd_ncap2}"
	    eval ${cmd_ncap2}
	done # !fl_in
    done # !var_drc

    if [ ${dbg_lvl} -ge 1 ]; then
	date_crr=$(date +"%s")
	date_dff=$((date_crr-date_yr))
	echo "Elapsed time to process year ${yyyy} = $((date_dff/60))m$((date_dff % 60))s"
    fi # !dbg

done # !yr

date_end=$(date +"%s")
if [ ${dbg_lvl} -ge 0 ]; then
    printf "Completed ERA5 ${tm_rsn_hr}-hourly dataset creation at `date`\n"
    date_dff=$((date_end-date_srt))
    echo "Elapsed time $((date_dff/60))m$((date_dff % 60))s"
fi # !dbg

exit 0
