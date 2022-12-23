DIR=$(pwd)

mkdir -p $DIR/src/BA_genes
cd $DIR/src

### Download genes from kegg
python getBA_genes.py
cat BA_genes/K*.fa >all_genes.fa

diamond makedb --in all_genes.fa -d bile_metabolism
 
