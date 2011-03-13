ls *.bas > list.txt
fbc -g -m main -x TurningSquare1_d @list.txt
rm -f list.txt
