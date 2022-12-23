#!/bin/bash
#PBS -l nodes=1:ppn=4
#PBS -l walltime=48:00:00
#PBS -l pmem=64
#PBS -l feature=rhel7
#PBS -j oe
#PBS -M bur157@psu.edu
#PBS -m bea

#####Catch Error Blocks#############
# exit when any command fails
set -e
# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT
#####################################

conda activate bio bakery

DIR=$(pwd)
SRC=${DIR}/src
RAW=${DIR}/raw
WORK=${DIR}/work
FILE=$FILE

#### SOFTWARES ########
TRIM=$SRC/trimmomatic

#### DATABASES ##########
MTPHLN_DIR=$SRC/databases/humann3/chocophlan
DB_MOUSE=$SRC/databases/mouse
DB_HUMAN=$SRC/databases/human
KRAKEN_DB=$SRC/databases/kraken2_db

######## INPUT #########
#FILE=$1
FILE=$FILE


#####Kneaddata########
TRIM_OUTDIR=${WORK}/filtered

FQ1=$(basename $FILE); SAMPLE=${FQ1%_R1*}; FQ2=${SAMPLE}_R2_001.fastq.gz

echo "Running kneading on data ${FQ1} and ${FQ2}"

kneaddata -i ${RAW}/${FQ1} -i ${RAW}/${FQ2} -db $DB_MOUSE -o $TRIM_OUTDIR \
--trimmomatic ${TRIM} \
-t 4 --trimmomatic-options "SLIDINGWINDOW:4:20 MINLEN:50" \
--bowtie2-options "--very-sensitive --dovetail" --remove-intermediate-output


######Concatenate#########
CT_IN=$TRIM_OUTDIR
FQ1=${SAMPLE}_R1_001_kneaddata_paired_1.fastq
FQ2=${SAMPLE}_R1_001_kneaddata_paired_2.fastq

CT_OUTDIR=$WORK/ct_data; mkdir -p $CT_OUTDIR

CT_OUT=${SAMPLE}_ct.fastq

echo "Concatenating ${FQ1} and ${FQ2}"

cat $CT_IN/$FQ1 $CT_IN/$FQ2 > $CT_OUTDIR/$CT_OUT


###### Kraken #############
echo -e "**Running Kraken and Bracken \n**"
KRAKEN_IN=$TRIM_OUTDIR
FQ1=$KRAKEN_IN/${SAMPLE}_R1_001_kneaddata_paired_1.fastq; 
FQ2=$KRAKEN_IN/${SAMPLE}_R1_001_kneaddata_paired_2.fastq

echo -e "Input: $FQ1"
KRAKEN_DIR=$WORK/krakenOUT; mkdir -p $KRAKEN_DIR

#kraken2 --db ${KRAKEN_DB} --paired ${FQ1} ${FQ2}  --output ${KRAKEN_DIR}/${SAMPLE}_kraken.out --report-zero-counts --use-mpa-style  --report ${KRAKEN_DIR}/${SAMPLE}_kraken.report


# Bracken #

BRACKEN_IN=$KRAKEN_DIR
BRACKEN_OUT=$WORK/backenOUT

for CHR in {'D','P','C','O','F','G','S'}
do
mkdir -p $BRACKEN_OUT/$CHR
bracken -d ${KRAKEN_DB} -r 150 -i ${KRAKEN_DIR}/${SAMPLE}_kraken.report -l ${CHR} -o $OUT/${SAMPLE}_bracken.out
done



######Humann3#############
HUMANN_IN=$CT_OUTDIR
HUMANN_OUT=$WORK/humann3; mkdir -p $HUMANN_OUT

FQ=$HUMANN_IN/$CT_OUT

echo "\n**Running humann3 analysis with metaphlan on file $FQ **\n"

humann3 --threads 12 --input $FQ --metaphlan-options '--bowtie2db /gpfs/group/adp117/default/bipin/src/databases/metap
hlan --unknown_estimation'  --output $HUMANN_OUT

#######Diamond##################
REF=${SRC}/bile_metabolism.dmnd
DIAMOND_IN=$CT_OUTDIR
DIAMOND_OUT=$WORK/diamond; mkdir -p $DIAMOND_OUT
FQ=$DIAMOND_IN/$CT_OUT
file=$(basename $FQ)
base=${file%ct*}
OUT=${base}.m8
TMP=$DIAMOND_OUT/tmp
mkdir -p $TMP

diamond blastx -d $REF -q $IN/$file -o $OUTDIR/$OUT --sensitive -t $TMP --outfmt 6

