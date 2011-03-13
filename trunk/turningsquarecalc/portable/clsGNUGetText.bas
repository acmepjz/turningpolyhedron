#include once "main.bi"
#include once "clsGNUGetText.bi"
#include once "crt/string.bi"
#include once "crt/stdio.bi"

#ifdef __FB_WIN32__

Declare Function GetLocaleInfo Lib "kernel32" Alias "GetLocaleInfoA" (ByVal Locale As Long, ByVal LCType As Long, ByVal lpLCData As String, ByVal cchData As Long) As Long

#endif

Const LOCALE_SYSTEM_DEFAULT As Long = &H800&
Const LOCALE_USER_DEFAULT As Long = &H400&

Const LOCALE_SISO639LANGNAME As Long = &H59
Const LOCALE_SISO3166CTRYNAME As Long = &H5A

type typeGNUGetTextNode
 lpsKey as UByte ptr
 nKeyLength as long
 lpsValue as UByte ptr
 nValueLength as long
 lpNext as LPtypeGNUGetTextNode
end type

Type typeMOFileHeader
 nMagic As Long
 nFileFormatRevision As Long
 nStringCount As Long
 lpOriginalString As Long
 lpTranslatedString As Long
 nHashTableSize As Long
 lpHashTable As Long
End Type

Type typeMOString
 nLength As Long
 nOffset As Long
End Type


Destructor clsGNUGetText()
Clear
End Destructor

Sub clsGNUGetText.Clear()
dim i as long
dim as LPtypeGNUGetTextNode lp,lp1
for i=0 to 255
 lp=_HashTable(i)
 do until lp=NULL
  lp1=lp->lpNext
  deallocate lp->lpsKey
  deallocate lp->lpsValue
  deallocate lp
  lp=lp1
 loop
next i
memset @_HashTable(0),0,1024
nStringCount=0
sLocale=""
End Sub

'a stupid hash
Function CalcHash(ByVal lp as UByte ptr,ByVal nSize as long, ByVal bCaseSensitive As Boolean) as long
dim ret as long=0
dim i as long, c as Long
for i=0 to nSize-1
 c=lp[i]
 if bCaseSensitive=0 then
  if c>=97 and c<=122 then c=c-32
 end if
 ret=(((ret shl 3)-ret) xor (ret shr 2) xor c)+37
next i
return ret and &HFF&
end function

'input and output are both UTF-8
Function clsGNUGetText.GetText(ByRef s As String) As String
dim lp as UByte ptr=strptr(s)
dim nSize as long=len(s)
dim h as long=CalcHash(lp,nSize,CaseSensitive)
dim lp1 as LPtypeGNUGetTextNode=_HashTable(h)
dim i as long,c1 as long,c2 as long
dim s1 as string
do until lp1=NULL
 if nSize=lp1->nKeyLength then
  if CaseSensitive then
   if memcmp(lp,lp1->lpsKey,nSize)=0 then
    s1=space(lp1->nValueLength)
    memcpy(strptr(s1),lp1->lpsValue,lp1->nValueLength)
    return s1
   end if
  else
   for i=0 to nSize-1
    c1=lp[i]
    c2=lp1->lpsKey[i]
    if c1>=97 and c1<=122 then c1=c1-32
    if c2>=97 and c2<=122 then c2=c2-32
    if c1<>c2 then exit for
   next i
   if i>=nSize then
    s1=space(lp1->nValueLength)
    memcpy(strptr(s1),lp1->lpsValue,lp1->nValueLength)
    return s1
   end if
  end if
 end if
 lp1=lp1->lpNext
loop
return s
End Function

Function clsGNUGetText.LoadFile(ByRef sFileName As String, ByVal bCaseSensitive As Boolean=0) As Boolean
Dim i As Long
Dim b() As Byte, s1 As String, s2 As String
Dim t As typeMOFileHeader
Dim t1() As typeMOString, t2() As typeMOString
'///
dim f as FILE ptr
dim as Long h
dim as UByte ptr lp1,lp2
dim as LPtypeGNUGetTextNode lp0
'///
f=fopen(sFileName,"rb")
if f=NULL then exit function
'///
 fread(@t,sizeof(typeMOFileHeader),1,f)
 If t.nMagic = &H950412DE And t.nFileFormatRevision = 0 Then
  Clear
  If t.nStringCount > 0 Then
   ReDim t1(t.nStringCount - 1), t2(t.nStringCount - 1)
   fseek(f,t.lpOriginalString,SEEK_SET)
   fread(@t1(0),sizeof(typeMOString),t.nStringCount,f)
   fseek(f,t.lpTranslatedString,SEEK_SET)
   fread(@t2(0),sizeof(typeMOString),t.nStringCount,f)
   For i = 0 To t.nStringCount - 1
    '///original
    If t1(i).nLength > 0 Then
     lp1=allocate(t1(i).nLength)
     fseek(f,t1(i).nOffset,SEEK_SET)
     fread(lp1,1,t1(i).nLength,f)
     h=CalcHash(lp1,t1(i).nLength,bCaseSensitive)
    Else
     h=0
     lp1=NULL
    End If
    '///translated
    If t2(i).nLength > 0 Then
     lp2=allocate(t2(i).nLength)
     fseek(f,t2(i).nOffset,SEEK_SET)
     fread(lp2,1,t2(i).nLength,f)
    Else
     lp2=NULL
    End If
    '///add
    lp0=_HashTable(h)
    _HashTable(h)=callocate(sizeof(typeGNUGetTextNode))
    with *_HashTable(h)
     .lpsKey=lp1
     .nKeyLength=t1(i).nLength
     .lpsValue=lp2
     .nValueLength=t2(i).nLength
     .lpNext=lp0
    end with
   Next i
  End If
  CaseSensitive = bCaseSensitive
  LoadFile = True
 End If

fclose(f)
End Function

Function clsGNUGetText.LoadFileWithLocale(ByRef sFileName As String, ByVal Locale As Long=0, ByVal bCaseSensitive As Boolean=0) As Boolean
Dim v() As String, m As Long
Dim s1 As String, s2 As String, s3 As String
Dim i As Long, lps As Long
dim f as FILE ptr
'///
If Locale = 0 Then Locale = LOCALE_USER_DEFAULT
If Locale = LOCALE_USER_DEFAULT Or Locale = LOCALE_SYSTEM_DEFAULT Then
 '///new:check enviroment vairable
 s1 = Trim(Environ("LANG"))
 If s1 = "" Then s1 = Trim(Environ("LANGUAGE"))
End If
If s1 = "" Then
 #ifdef __FB_WIN32__
 s1 = String(1024, !"\0")
 GetLocaleInfo Locale, LOCALE_SISO639LANGNAME, s1, 1024&
 s1 = Left(s1, InStr(1, s1, !"\0") - 1)
 s2 = String(1024, !"\0")
 GetLocaleInfo Locale, LOCALE_SISO3166CTRYNAME, s2, 1024&
 s2 = Left(s2, InStr(1, s2, !"\0") - 1)
 If s2 <> "" Then s1 = s1 + "_" + s2
 #else
 '??? TODO:
 exit function
 #endif
End If
Split(Replace(Replace(s1, ";", ":"), ",", ":"), ":", v())
m = UBound(v)
For i = 0 To m
 s1 = Trim(v(i))
 If s1 <> "" Then
  '///
  s2 = Replace(sFileName, "*", s1)
  f=fopen(s2,"rb")
  If f<>NULL Then
    fclose(f)
    If LoadFile(s2, bCaseSensitive) Then
     sLocale = s1
     LoadFileWithLocale = True
     Exit Function
    End If
  End If
  '///
  lps = InStr(1, s1, ".")
  If lps > 0 Then
   s3 = Left(s1, lps - 1)
   s2 = Replace(sFileName, "*", s3)
   f=fopen(s2,"rb")
   If f<>NULL Then
     fclose(f)
     If LoadFile(s2, bCaseSensitive) Then
      sLocale = s3
      LoadFileWithLocale = True
      Exit Function
     End If
   End If
  End If
  '///
  lps = InStr(1, s1, "@")
  If lps > 0 Then
   s3 = Left(s1, lps - 1)
   s2 = Replace(sFileName, "*", s3)
   f=fopen(s2,"rb")
   If f<>NULL Then
     fclose(f)
     If LoadFile(s2, bCaseSensitive) Then
      sLocale = s3
      LoadFileWithLocale = True
      Exit Function
     End If
   End If
  End If
  '///
  lps = InStr(1, s1, "_")
  If lps > 0 Then
   s3 = Left(s1, lps - 1)
   s2 = Replace(sFileName, "*", s3)
   f=fopen(s2,"rb")
   If f<>NULL Then
     fclose(f)
     If LoadFile(s2, bCaseSensitive) Then
      sLocale = s3
      LoadFileWithLocale = True
      Exit Function
     End If
   End If
  End If
 End If
Next i
End Function

Function clsGNUGetText.StringCount() As Long
return nStringCount
End Function

Function clsGNUGetText.GetLangName() As String
Return sLocale
End Function


