#!/bin/bash
#PBS -l walltime=1000:00:00
#PBS -l select=1:ncpus=8:mem=96gb
module load anaconda3/personal
source activate R_tree_env
echo "R is about to run cooccurence script"
Rscript --vanilla $HOME/MRes/MycobiomeProject/Analysis/Generalised_Scripts/Analysis/cooccur.R "$HOME/MRes/MycobiomeProject/Analysis/Results/${arg_path}/analysis_args.R"
echo "R has finished running cooccurence script"
# end of file
