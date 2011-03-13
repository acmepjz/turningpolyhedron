ls *.bas > list.txt
fbc -O 3 -fpu sse -vec 2 -m main -x TurningSquare1 @list.txt
rm -f list.txt
