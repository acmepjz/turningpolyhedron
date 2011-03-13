dir /b *.bas > list.txt
fbc.exe -O 3 -fpu sse -vec 2 -m main -x TurningSquare1.exe @list.txt
del list.txt
pause
