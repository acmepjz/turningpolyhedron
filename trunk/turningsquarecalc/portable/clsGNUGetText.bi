#pragma once

#include once "main.bi"

type LPtypeGNUGetTextNode as typeGNUGetTextNode ptr

type clsGNUGetText
public:
    Declare Destructor()
    Declare Sub Clear()
    Declare Function GetText(ByRef s As String) As String
    Declare Function GetLangName() As String
    Declare Function LoadFile(ByRef sFileName As String, ByVal bCaseSensitive As Boolean=0) As Boolean
    Declare Function LoadFileWithLocale(ByRef sFileName As String, ByVal Locale As Long=0, ByVal bCaseSensitive As Boolean=0) As Boolean
    Declare Function StringCount() As Long
    CaseSensitive as Boolean
private:
    _HashTable(255) as LPtypeGNUGetTextNode
    nStringCount As Long
    sLocale As String
end type
