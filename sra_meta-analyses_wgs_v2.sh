#!/usr/bin/bash

# Author  : Domitille JARRIGE
# Date    : 2022-09-12
#
# Launching Script for biogeographical analysis: search for nucleotids homologs of a user chosen sequence
# using megaBLAST. The user can also chose the indentity and query coverage thresholds for a sequence to be
# considered homologous to the query. The script was intented for a cluster with SLURM workload manager, but
# can be modified as needed.
#___________________________________________________________________________________________________________
# USAGE   : bash sra_meta-analyses_wgs_v2.sh -q [path/to/your/query.fa] -i [percentage identity threshold]
#        {-c [percentage query cover] optional: default value 0}
#
# Exemple : bash sra_meta-analyses_wgs_v2.sh -q ITS.fa -i 97 -c 30
#___________________________________________________________________________________________________________

path=$(pwd)
list_accessions=( $(cut -f 1 "${path}/data/WGS_metaSRA_v2.tsv" | tail -n +2) )
data_type=wgs_v2
perc_query_coverage=0

while getopts hq:i:c: flag
do
    case "${flag}" in
        q) query_file=${OPTARG};;
        i) perc_identity=${OPTARG};;
        c) perc_query_coverage=${OPTARG};;
        h) echo "USAGE: bash sra_meta-analyses_wgs_v2.sh -q [path/to/your/query.fa] -i [percentage identity threshold] {-c [percentage query cover] optional: default value 0}"
        exit 0;;
        *) echo "USAGE: bash sra_meta-analyses_wgs_v2.sh -q [path/to/your/query.fa] -i [percentage identity threshold] {-c [percentage query cover] optional: default value 0}"
        exit 1;;
    esac
done

[ $# -lt 3 ] && { echo "USAGE: bash sra_meta-analyses_wgs_v2.sh -q [path/to/your/query.fa] -i [percentage identity threshold] {-c [percentage query cover] optional: default value 0}"; exit 1; }

echo "Launching three SLURM batches for query ${query_file} with ${perc_identity}% identity threshold and ${perc_query_coverage} minimum query coverage."
sbatch "${path}/scripts/sra_meta-analyses_wgs_v2_part1.sh" -q "${query_file}" -i "${perc_identity}" -c "${perc_query_coverage}"
sbatch "${path}/scripts/sra_meta-analyses_wgs_v2_part2.sh" -q "${query_file}" -i "${perc_identity}" -c "${perc_query_coverage}"
sbatch "${path}/scripts/sra_meta-analyses_wgs_v2_part3.sh" -q "${query_file}" -i "${perc_identity}" -c "${perc_query_coverage}"
