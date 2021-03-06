#!/bin/bash
#PBS -l walltime=48:00:00
#PBS -l select=1:ncpus=120:mem=1440gb

# load required environment
module load anaconda3/personal
source activate Renv

# checks and prep
cutadapt --version
echo ${arg_path}

echo "R is about to run DADA2 pipeline"
Rscript --vanilla $HOME/MRes/MycobiomeProject/Analysis/Generalised_Scripts/Processing/DADA2_pipeline.R "$HOME/MRes/MycobiomeProject/Analysis/Runs_Countries/${arg_path}/DADA2_args.R"
echo "R has finished running DADA2 pipeline"

#echo "R is about to run filtering script on DADA2 results"
#Rscript --vanilla $HOME/MRes/MycobiomeProject/Analysis/Generalised_Scripts/Processing/DADA2_data_filtering.R "$HOME/MRes/MycobiomeProject/Analysis/Runs_Countries/${arg_path}/filtering_args.R"
#echo "R has finished running filtering script on DADA2 results"

echo "All scripts have finished running. End."

# end of script
