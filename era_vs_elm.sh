#!/usr/bin/env bash

# Purpose: Evaluate ERA5 forcing against E3SM ELM output fields

drc_era=/global/cfs/cdirs/e3sm/inputdata/atm/datm7/atm_forcing.datm7.ERA.0.25d.v5.c180614/data_out # [sng] Root of ERA5 reanalysis
drc_elm=/pscratch/sd/c/cwhicker/e3sm_scratch/pm-cpu/20230224.IGELM_MLI.ne30pg2_r05_oECv3_gis1to10.pm-cpu.cwhicker_snicar_adv4-amschne_era5_merge_ig_f10e_era5tests/run # [sng] Root of ELM output
caseid_elm=20230224.IGELM_MLI.ne30pg2_r05_oECv3_gis1to10.pm-cpu.cwhicker_snicar_adv4-amschne_era5_merge_ig_f10e_era5tests # [sng] ELM caseid
elm_era5_vars=RAIN,SNOW,FSDSNI,FSDSVI,FSDSND,FSDSVD,TSA,FLDS,PBOT # [sng] ELM variables directly forced by ERA5
elm_xtra_vars=FSDS,TBOT,landfrac,landmask # [sng] Extra variables to carry
yyyy=1980 # [yr] Analysis year

# Derived variables
fl_h0_elm=${caseid_elm}.elm.h0.${yyyy}-02-01-00000.nc

function var2drc {
    # Purpose: Return subdirectory where CRUNCEP DATM stores files containining given CRUNCEP variable name
    local drc_nm_crr
    if [ ${1} = 'mcpr' ] || [ ${1} = 'mlspr' ]; then
        drc_nm_crr='prec'
    elif [ ${1} = 't2m' ]; then
        drc_nm_crr='tbot'
    elif [ ${1} = 'd2m' ]; then
        drc_nm_crr='tdew'
    elif [ ${1} = 'sp' ]; then
        drc_nm_crr='pbot'
    elif [ ${1} = 'msdwlwrf' ]; then
        drc_nm_crr='lwdn'
    elif [ ${1} = 'msdfswrf' ] || [ ${1} = 'msdrswrf' ] || [ ${1} = 'msdwswrf' ]; then
        drc_nm_crr='swdn'
    elif [ ${1} = 'u10' ] || [ ${1} = 'v10' ] || [ ${1} = 'w10' ]; then
        drc_nm_crr='wind'
    else
	echo "${spt_nm}: ERROR Unknown ERA5 variable name = \"${1}\" in function var2drc()"
	exit 1
    fi # !1
    echo ${drc_nm_crr}
} # !var2drc

function var2elm {
    # Purpose: Return ELM variable name to compare with given ERA5 variable name
    local var_nm_elm
    if [ ${1} = 'mcpr' ] || [ ${1} = 'mlspr' ]; then
        var_nm_elm='prec'
    elif [ ${1} = 't2m' ]; then
	# 20230412 Chloe showed that t2m should be compared to TBOT, not TSA, since t2m is assigned to TBOT in input in namelist_definition_datm.xml
        var_nm_elm='TSA'
    elif [ ${1} = 'd2m' ]; then
        var_nm_elm='tdew'
    elif [ ${1} = 'sp' ]; then
        var_nm_elm='PBOT'
    elif [ ${1} = 'msdwlwrf' ]; then
        var_nm_elm='FLDS'
    elif [ ${1} = 'msdfswrf' ] || [ ${1} = 'msdrswrf' ] || [ ${1} = 'msdwswrf' ]; then
        var_nm_elm='swdn'
    elif [ ${1} = 'u10' ] || [ ${1} = 'v10' ] || [ ${1} = 'w10' ]; then
        var_nm_elm='WIND'
    else
	echo "${spt_nm}: ERROR Unknown ERA5 variable name = \"${1}\" in function var2elm()"
	exit 1
    fi # !1
    echo ${var_nm_elm}
} # !var2elm

for var_era in t2m sp w10 msdwlwrf; do
#for var_era in t2m; do
    sbd_era=`var2drc ${var_era}`
    var_elm=`var2elm ${var_era}`
    cd ${drc_era}/${sbd_era}
#    if false; then
    for fl in `ls elmforc.ERA5.c2018.0.25d.${var_era}.${yyyy}-??.nc`; do
    	echo "ERA5 fl=${fl}"
	ncra -O ${fl} ${DATA}/era5/clm/${fl}
	ncremap -v ${var_era} --map=${DATA}/maps/map_era5_s2n_to_r05_aave.20230301.nc ${DATA}/era5/clm/${fl} ${DATA}/era5/rgr/${fl/0.25d/r05}
	ncrename -v ${var_era},${var_elm} ${DATA}/era5/rgr/${fl/0.25d/r05}
	ncks --append -C -v landfrac ${DATA}/grids/elm_landfrac_r05.nc ${DATA}/era5/rgr/${fl/0.25d/r05}
    done # !fl
#    fi # !false
    cd ${DATA}/era5/rgr
    ncrcat -O elmforc.ERA5.c2018.r05.${var_era}.${yyyy}-??.nc ${DATA}/era5/rgr/era5_r05_${yyyy}_0112_${var_elm}.nc
    ncbo -O ${drc_elm}/${fl_h0_elm} ${DATA}/era5/rgr/era5_r05_${yyyy}_0112_${var_elm}.nc ~/elm-era_r05_${yyyy}_0112_${var_elm}.nc
    ncra -O ~/elm-era_r05_${yyyy}_0112_${var_elm}.nc ~/elm-era_r05_${yyyy}_${var_elm}.nc
    scp ~/elm-era_r05_${yyyy}*_${var_elm}.nc imua.ess.uci.edu:
    # scp "e3sm.ess.uci.edu:elm-era_r05_${yyyy}*_${var_elm}.nc" ~
done # !var_era
