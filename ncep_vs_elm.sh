#!/usr/bin/env bash

# Purpose: Evaluate CRUNCEP forcing against E3SM ELM output fields

drc_ncep=/global/cfs/cdirs/e3sm/inputdata/atm/datm7/atm_forcing.datm7.cruncep_qianFill.0.5d.v7.c160715 # [sng] Root of NCEP reanalysis
drc_elm=/pscratch/sd/c/cwhicker/e3sm_scratch/pm-cpu/20230509.IGELM_MLI.ne30pg2_r05_oECv3_gis1to10.pm-cpu.cruncep_datm_1yrtst/run # [sng] Root of ELM output
caseid_elm=20230509.IGELM_MLI.ne30pg2_r05_oECv3_gis1to10.pm-cpu.cruncep_datm_1yrtst # [sng] ELM caseid
elm_ncep_vars=RAIN,SNOW,FSDSNI,FSDSVI,FSDSND,FSDSVD,TSA,FLDS,PBOT # [sng] ELM variables directly forced by NCEP
elm_xtra_vars=FSDS,TBOT,landfrac,landmask # [sng] Extra variables to carry
yyyy=1980 # [yr] Analysis year for NCEP
yyyy_elm=0001 # [yr] Analysis year for ELM simulation

# Derived variables
fl_h0_elm=${caseid_elm}.elm.h0.${yyyy_elm}-02-01-00000.nc

function var2drc {
    # Purpose: Return subdirectory where CRUNCEP DATM stores files containining given CRUNCEP variable name
    local drc_nm_crr
    if [ ${1} = 'PRECTmms' ]; then
        drc_nm_crr='Precip6Hrly'
    elif [ ${1} = 'TBOT' ] || [ ${1} = 'QBOT' ] || [ ${1} = 'PSRF' ] || [ ${1} = 'WIND' ] || [ ${1} = 'FLDS' ]; then
        drc_nm_crr='TPHWL6Hrly'
    elif [ ${1} = 'FSDS']; then
        drc_nm_crr='Solar6Hrly'
    else
	echo "${spt_nm}: ERROR Unknown CRUNCEP variable name = \"${1}\" in function var2drc()"
	exit 1
    fi # !1
    echo ${drc_nm_crr}
} # !var2drc

function var2elm {
    # Purpose: Return ELM variable name to compare with given CRUNCEP variable name
    local var_nm_elm
    if [ ${1} = 'PRECTmms' ]; then
        var_nm_elm='SNOW' # ELM outputs RAIN and SNOW separately, has no total precip field
    elif [ ${1} = 'TBOT' ]; then
        var_nm_elm='TBOT'
    elif [ ${1} = 'QBOT' ]; then
        var_nm_elm='QBOT'
    elif [ ${1} = 'PSRF' ]; then
        var_nm_elm='PBOT'
    elif [ ${1} = 'FLDS' ]; then
        var_nm_elm='FLDS'
    elif [ ${1} = 'FSDS' ]; then
        var_nm_elm='FSDS'
    elif [ ${1} = 'WIND' ]; then
        var_nm_elm='WIND'
    else
	echo "${spt_nm}: ERROR Unknown CRUNCEP variable name = \"${1}\" in function var2elm()"
	exit 1
    fi # !1
    echo ${var_nm_elm}
} # !var2elm

function var2sng {
    # Purpose: Return file sub-string used by DATM file that includes given CRUNCEP variable
    local var_sng
    if [ ${1} = 'PRECTmms' ]; then
        var_sng='Prec'
    elif [ ${1} = 'TBOT' ] || [ ${1} = 'QBOT' ] || [ ${1} = 'PSRF' ] || [ ${1} = 'WIND' ] || [ ${1} = 'FLDS' ]; then
        var_sng='TPQWL'
    elif [ ${1} = 'FSDS' ]; then
        var_sng='Solr'
    else
	echo "${spt_nm}: ERROR Unknown CRUNCEP variable name = \"${1}\" in function var2sng()"
	exit 1
    fi # !1
    echo ${var_sng}
} # !var2sng

#for var_ncep in TBOT PSRF QBOT FLDS FSDS WIND; do
for var_ncep in TBOT; do
    sbd_ncep=`var2drc ${var_ncep}`
    var_elm=`var2elm ${var_ncep}`
    var_sng=`var2sng ${var_ncep}`
    cd ${drc_ncep}/${sbd_ncep}
#    if false; then
    for fl in `ls clmforc.cruncep.V7.c2016.0.5d.${var_sng}.${yyyy}-??.nc`; do
    	echo "CRUNCEP fl=${fl}"
	fl_var=${fl/${var_sng}/${var_ncep}}
	fl_out=${fl_var/0.5d/r05}
	# NB: CRUNCEP forcing datasets have time as fixed, not record, coordinate
	ncks -O -v ${var_ncep} --mk_rec_dmn time ${fl} ${DATA}/era5/clm/${fl_var}
	ncra -O ${DATA}/era5/clm/${fl_var} ${DATA}/era5/clm/${fl_var}
	ncremap -v ${var_ncep} --map=${DATA}/maps/map_cruncep_to_r05_nco.20230701.nc ${DATA}/era5/clm/${fl_var} ${DATA}/era5/rgr/${fl_out}
	if [ ${var_ncep} != ${var_elm} ]; then
	    ncrename -v ${var_ncep},${var_elm} ${DATA}/era5/rgr/${fl_out}
	fi # !var_ncep
	ncks --append -C -v landfrac ${DATA}/grids/elm_landfrac_r05.nc ${DATA}/era5/rgr/${fl_out}
    done # !fl
#    fi # !false
    cd ${DATA}/era5/rgr
    ncrcat -O clmforc.cruncep.V7.c2016.r05.${var_ncep}.${yyyy}-??.nc ${DATA}/era5/rgr/cruncep_r05_${yyyy}_0112_${var_elm}.nc
    ncbo -O -v ${var_elm} ${drc_elm}/${fl_h0_elm} ${DATA}/era5/rgr/cruncep_r05_${yyyy}_0112_${var_elm}.nc ~/elm-cruncep_r05_${yyyy}_0112_${var_elm}.nc
    ncra -O ~/elm-cruncep_r05_${yyyy}_0112_${var_elm}.nc ~/elm-cruncep_r05_${yyyy}_${var_elm}.nc
    scp ~/elm-cruncep_r05_${yyyy}*_${var_elm}.nc e3sm.ess.uci.edu:
    # scp "e3sm.ess.uci.edu:elm-cruncep_r05_${yyyy}*_${var_elm}.nc" ~
done # !var_ncep
