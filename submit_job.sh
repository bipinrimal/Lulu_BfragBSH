DIR=$(pwd)
RAW=$DIR/raw

for file in $RAW/*R1_001.fastq.gz
do
base=$(basename $file)
name=${base%_S*}
echo -e "Running analysis in ${base} \n"

qsub -v FILE=$file -N run_${name} -A open -o logs $DIR/workflow.sh

done
