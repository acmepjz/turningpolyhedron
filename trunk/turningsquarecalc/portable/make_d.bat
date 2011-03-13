dir /b *.bas > list.txt
fbc.exe -g -m main -x TurningSquare1_d.exe @list.txt
del list.txt
pause
