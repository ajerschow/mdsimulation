#!/bin/bash
#
#SBATCH --job-name=epm_o2_analysis
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --time=20:30:00
#SBATCH --mem=4GB
#SBATCH --mail-user=aj39@nyu.edu
#SBATCH --output=arr_%A_%a.out
#SBATCH --error=arr_%A_%a.err


# for working without X-window connection in batch mode
# then do not need agg code in script (convenient)
export MPLBACKEND="agg"

# python -m simtk.testInstallation

# Boris temp data available for 233   253   273   283   298

# array=($(seq 0 1 100 ))
# k=${array[$SLURM_ARRAY_TASK_ID]}
# sampledir="sample_npt_${k}"
# cd ${sampledir}


temparray=($(seq 280 10 320 ))

temparray=(300)

echo ${!array[@]}

for i in "${temparray[@]}"
do

# trajpath="/scratch/work/aj39/myambertest/EPM_O2/${sampledir}/"
trajpath=""
trajprefix="31_o2_Prod_cont"
trajextension="nc"

# for Amber NC trajectories, need to transfer to mem because of error -> -m flag
# also dx0 and dx02 end up having an extra point which I have to shave off 

# python ~/Python-analysis/calcdrelax_openmm3.py -o outplot${i} ./chcl3_files/chcl3.prmtop ./traj${i}.dcd 

singularity exec --nv \
            --overlay /scratch/work/aj39/singularity/mdanalysis-overlay-2GB-1.3M.ext3:ro \
            /scratch/work/public/singularity/ubuntu-20.04.1.sif \
            bash -c "source /ext3/env.sh; \
 python ~/Python-analysis/new_drelax_cutoff_RS6.py -a cf_${i}_OO.txt -x 1000 -u 20 -m 99000 -c R1 -n drelax_OO.log -l 8000 -i 1H 1H -s 'name O and resname OXL' 'name O1' 'name O1 and resname OXL' -o ${trajprefix}${i}_cf_OO.pdf o2.prmtop ${trajpath}${trajprefix}${i}.${trajextension}"

done
