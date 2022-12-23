KOs="K01442_cbh
K00076_hdhA
K22604_E1.1.1.52
K22605_baiA
K22606_E1.1.1.391
K22607_E1.1.1.393
K15868_baiB
K15871_baiF
K15869_baiA
K15870_baiCD
K15872_baiE
K15873_baiH
K15874_baiI
K07007_baiN"

for val in $KOs
do
  gene=$val
  KO=${gene%_*}
  echo "Now counting for $KO in"
for file in *m8
do
  base=${file%.m8} 
  echo "$base"
  out=${base}_${gene}.counts
  awk  -v KO="$KO" '$3>90 && $2~KO ' $file | sort -k2 | cut -f2| sort|uniq -c >$out
done
echo ""
done


