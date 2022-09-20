#!/usr/bin/bash

# Author  : Domitille JARRIGE
# Date    : 2022-09-12
#
# Script for biogeographical analysis: search for nucleotids homologs a user chosen sequence
# using megablast. The user can also chose the indentity and query coverage thresholds for a sequence to be
# considered homologous to the query. The script was intented for a cluster with SLURM workload manager, but
# can be modified as needed.
#___________________________________________________________________________________________________________
# USAGE   : Run thru launching script:
#        bash sra_meta-analyses_wgs_v2.sh -q [path/to/your/query.fa] -i [percentage identity threshold] 
#        {-c [percentage query cover] optional: default value 0}
#___________________________________________________________________________________________________________

#SBATCH --array=0-689%5
#SBATCH --cpus-per-task=4
#SBATCH --mem=1G
#SBATCH --partition=fast

module load sra-tools

path=$(pwd)
list_accessions=( $(tail -n -690 "${path}/data/WGS_metaSRA_v2.tsv" | cut -f 1) )
data_type=wgs_v2

while getopts q:i:c: flag
do
    case "${flag}" in
        q) query_file=${OPTARG};;
        i) perc_identity=${OPTARG};;
        c) perc_query_coverage=${OPTARG};;
    esac
done

echo "Prefetching run ${list_accessions[$SLURM_ARRAY_TASK_ID]}" >> "${path}/log/${data_type}_${perc_identity}_sra_meta_analyses.log"

srun -J "${list_accessions[$SLURM_ARRAY_TASK_ID]} prefetch" prefetch -p ${list_accessions[$SLURM_ARRAY_TASK_ID]} -O "${path}/data/meta_SRA"

echo "File at: ${path}/data/meta_SRA/${list_accessions[$SLURM_ARRAY_TASK_ID]}.sra" >> "${path}/log/${data_type}_${perc_identity}_sra_meta_analyses.log"

srun -J "${list_accessions[$SLURM_ARRAY_TASK_ID]} validation" vdb-validate "${path}/data/meta_SRA/${list_accessions[$SLURM_ARRAY_TASK_ID]}.sra" >> "${path}/log/${data_type}_${perc_identity}_sra_meta_analyses.log"

srun -J "${list_accessions[$SLURM_ARRAY_TASK_ID]} blastn" blastn_vdb -num_threads 4 -query "${path}/${query_file}" -db "${list_accessions[$SLURM_ARRAY_TASK_ID]}" -task megablast -out "${path}/results/${list_accessions[$SLURM_ARRAY_TASK_ID]}blast_meta_${data_type}_${perc_identity}.tmp" -outfmt 7 -perc_identity ${perc_identity} -max_target_seqs 5 -qcov_hsp_perc ${perc_query_coverage} 2>> "${path}/log/${data_type}_${perc_identity}_sra_meta_analyses.log"

echo "Command: blastn_vdb -num_threads 4 -query ${query_file} -db ${list_accessions[$SLURM_ARRAY_TASK_ID]} -task megablast -out ${path}/results/${list_accessions[$SLURM_ARRAY_TASK_ID]}blast_meta_${data_type}.tmp -outfmt 7 -perc_identity ${perc_identity} -max_target_seqs 5" >> "${path}/log/${data_type}_${perc_identity}_sra_meta_analyses.log"

wait >>  "${path}/log/${data_type}_sra_meta_analyses.log"
srun -J "${list_accessions[$SLURM_ARRAY_TASK_ID]} Cleanup" rm -f "${path}/data/meta_SRA/${list_accessions[$SLURM_ARRAY_TASK_ID]}.sra" 2>> "${path}/log/${data_type}_${perc_identity}_sra_meta_analyses.log"

wait >>  "${path}/log/${data_type}_sra_meta_analyses.log"
srun -J "${list_accessions[$SLURM_ARRAY_TASK_ID]} Cache cleanup" rm -f "${path}/data/meta_SRA/sra/${list_accessions[$SLURM_ARRAY_TASK_ID]}*" 2>> "${path}/log/${data_type}_${perc_identity}_sra_meta_analyses.log"