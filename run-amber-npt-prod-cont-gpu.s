#!/bin/bash
#
#SBATCH --job-name=myAmberJob
#SBATCH --nodes=1
#SBATCH --time=20:00:00
#SBATCH --mem=8GB
#SBATCH --mail-type=END
#SBATCH --mail-user=aj39@nyu.edu
#SBATCH --gres=gpu:1

# to use after cpu prod run to continue for many steps with GPU


array=($(seq 220 10 310 ))
array=(300)
echo ${!array[@]}
i=${array[$SLURM_ARRAY_TASK_ID]}

module purge
module load amber/openmpi/intel/20.06
# module load python/intel/2.7.12
pycmd1="/home/aj39/wrapper/run-python.bash python ~/Python-analysis/analyze_amber_out7.py -b"

ambercmd="pmemd.cuda -O"
# ambercmd="sander -O"
prefix="o2"

restart=${prefix}
tempinitial=0
tempfinal=${i}
heatname_input="21_${prefix}_Heat$tempfinal"
stabil_prefix="31_${prefix}_Stabil$tempfinal"
prod_prefix="31_${prefix}_Prod$tempfinal"
prod_cont_prefix="31_${prefix}_Prod_cont$tempfinal"
prmtop="${prefix}.prmtop"

# for working without X-window connection in batch mode
# then do not need agg code in script (convenient)
export MPLBACKEND="agg"

cat > $prod_cont_prefix.in << END_TEXT
Production, no constraints
 &cntrl
  imin=0,
  ntx=5,
  irest=1,
  nstlim=1000000,
  dt=0.001,
  ntf=2,
  ntc=2,
  temp0=$tempfinal,
  ntpr=1000,
  ntwx=1,
  cut=5.0,
  ntp=1,
  taup=1,   ! pressure regulation time constant (ps)
  ntt=3,
  gamma_ln=5.0,
  ig=-1,
 /
END_TEXT


$ambercmd -i ${prod_cont_prefix}.in -o ${prod_cont_prefix}.out -p ${prmtop} -c ${prod_prefix}.rst \
 -r ${prod_cont_prefix}.rst -x ${prod_cont_prefix}.nc -inf ${prod_cont_prefix}.info

# python ~/Python-analysis/mdanalysis_test3.py -b ${prmtop} ${prod_prefix}.nc
${pycmd1} ${prod_cont_prefix}.out

# python  ~/Python-analysis/analyze_amber_out4.py -b ${prod_prefix}.out

