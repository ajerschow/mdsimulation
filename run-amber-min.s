#!/bin/bash
#
#SBATCH --job-name=myAmberJob
#SBATCH --nodes=1
#SBATCH --tasks-per-node=8
#SBATCH --time=20:00:00
#SBATCH --mem=16GB

module purge
module load amber/openmpi/intel/20.06 
# module load python/intel/2.7.12


prefix="o2"

set -x

inpcrd="${prefix}.inpcrd"
prmtop="${prefix}.prmtop"
jobprefix="01_${prefix}"
min_name="${jobprefix}.in"

cat > $min_name << END_TEXT
Minimize
 &cntrl
  imin=1,
  ntx=1,
  irest=0,
  maxcyc=5000,
  ncyc=3000,
  ntc=1,
  ntpr=100,
  ntwx=100,
  cut=8.0,
 /
END_TEXT


$AMBERHOME/bin/sander -O -i $min_name -o ${jobprefix}.out -p $prmtop -c $inpcrd -r ${jobprefix}.rst \
-inf ${jobprefix}.mdinfo -x ${jobprefix}.nc

singularity exec --nv \
            --overlay /scratch/work/aj39/singularity/mdanalysis-overlay-2GB-1.3M.ext3:ro \
            /scratch/work/public/singularity/ubuntu-20.04.1.sif \
            bash -c "source /ext3/env.sh; \
python ~/Python-analysis/analyze_amber_out7.py -m -b ${jobprefix}.out"

