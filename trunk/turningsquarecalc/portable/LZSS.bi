#pragma once

#include once "main.bi"

type typeLZSSMemFile
    lp as UByte ptr
    lpEnd as UByte ptr
end type

declare Sub CompressTest(ByRef infile As typeLZSSMemFile, ByRef outfile As typeLZSSMemFile)
declare Sub DecompressTest(ByRef infile As typeLZSSMemFile, ByRef outfile As typeLZSSMemFile)

declare Function CompressData(DataIn() As Byte, DataOut() As Byte) As Long
declare Function DecompressData(DataIn() As Byte, DataOut() As Byte, ByVal OriginalSize As Long) As Long

