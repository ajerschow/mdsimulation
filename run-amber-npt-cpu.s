#!/bin/bash
#
#SBATCH --job-name=myAmberJob
#SBATCH --nodes=1
#SBATCH --time=20:00:00
#SBATCH --mem=8GB
#SBATCH --mail-type=END
#SBATCH --mail-user=aj39@nyu.edu


array=($(seq 280 10 320 ))
array=(300)
echo ${!array[@]}
i=${array[$SLURM_ARRAY_TASK_ID]}

module purge
module load amber/openmpi/intel/20.06
# module load python/intel/2.7.12
pycmd1="/home/aj39/wrapper/run-python.bash python ~/Python-analysis/analyze_amber_out7.py -b"

# ambercmd="pmemd.cuda -O"
ambercmd="sander -O"
prefix="o2"

# for working without X-window connection in batch mode
# then do not need agg code in script (convenient)
export MPLBACKEND="agg"

restart="01_${prefix}"
tempinitial=0
tempfinal=${i}
heatname_input="21_${prefix}_Heat$tempfinal"
stabil_prefix="31_${prefix}_Stabil$tempfinal"
prod_prefix="31_${prefix}_Prod$tempfinal"
prmtop="${prefix}.prmtop"


cat > $heatname_input.in << END_TEXT
Heat
 &cntrl
  imin=0,
  ntx=1,
  irest=0,
  nstlim=20000,
  dt=0.001,
  ntf=1,
  ntc=1,
  tempi=$tempinitial,
  temp0=$tempfinal,
  ntpr=100,
  ntwx=100,
  cut=8.0,
  ntp=0,
  ntt=3,
  gamma_ln=5.0,
  nmropt=1,
  ig=-1,
 /
&wt type='TEMP0', istep1=0, istep2=18000, value1=$tempinitial, value2=$tempfinal /
&wt type='TEMP0', istep1=18001, istep2=20000, value1=$tempfinal, value2=$tempfinal /
&wt type='END' /
END_TEXT


$ambercmd -i ${heatname_input}.in -o ${heatname_input}.out -p ${prmtop} -c ${restart}.rst \
 -r ${heatname_input}.rst -x ${heatname_input}.nc -inf ${heatname_input}.info 

${pycmd1} ${heatname_input}.out
# python  ~/Python-analysis/analyze_amber_out4.py -b ${heatname_input}.out

cat > $stabil_prefix.in << END_TEXT
Stabilization NTP NTT
 &cntrl
  imin=0,
  ntx=5,
  irest=1,
  nstlim=100000,
  dt=0.001,
  ntf=1,
  ntc=1,
  temp0=$tempfinal,
  ntpr=1000,
  ntwx=1000,
  cut=8.0,
  ntp=1,
  taup=1,   ! pressure regulation time constant (ps)
  ntt=3,
  gamma_ln=5.0,
  ig=-1,
 /
END_TEXT

$ambercmd -i ${stabil_prefix}.in -o ${stabil_prefix}.out -p ${prmtop} -c ${heatname_input}.rst \
 -r ${stabil_prefix}.rst -x ${stabil_prefix}.nc -inf ${stabil_prefix}.info

# python ~/Python-analysis/mdanalysis_test3.py -b ${prmtop} ${stabil_prefix}.nc
${pycmd1} ${stabil_prefix}.out
# python  ~/Python-analysis/analyze_amber_out4.py -b ${stabil_prefix}.out

cat > $prod_prefix.in << END_TEXT
Production, no constraints
 &cntrl
  imin=0,
  ntx=5,
  irest=1,
  nstlim=20000,
  dt=0.001,
  ntf=2,
  ntc=2,
  temp0=$tempfinal,
  ntpr=1000,
  ntwx=100,
  cut=8.0,
  ntp=1,
  taup=1,   ! pressure regulation time constant (ps)
  ntt=3,
  gamma_ln=5.0,
  ig=-1,
 /
END_TEXT


$ambercmd -i ${prod_prefix}.in -o ${prod_prefix}.out -p ${prmtop} -c ${stabil_prefix}.rst \
 -r ${prod_prefix}.rst -x ${prod_prefix}.nc -inf ${prod_prefix}.info

# python ~/Python-analysis/mdanalysis_test3.py -b ${prmtop} ${prod_prefix}.nc
${pycmd1} ${prod_prefix}.out

# python  ~/Python-analysis/analyze_amber_out4.py -b ${prod_prefix}.out

