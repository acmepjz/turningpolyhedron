VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsSimpleTarFile"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'////////////////////////////////
'This file is public domain.
'////////////////////////////////

'////////
'a simple and buggy tar reader/writer, supports the most basic features only
'documents about tar file can be found at:
'http://en.wikipedia.org/wiki/Tar_(file_format)
'http://www.gnu.org/software/automake/manual/tar/Standard.html
'////////

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)
Private Declare Sub ZeroMemory Lib "kernel32.dll" Alias "RtlZeroMemory" (ByRef Destination As Any, ByVal Length As Long)

Private Declare Function GetTimeZoneInformation Lib "kernel32.dll" (ByRef lpTimeZoneInformation As TIME_ZONE_INFORMATION) As Long
Private Type SYSTEMTIME
    wYear As Integer
    wMonth As Integer
    wDayOfWeek As Integer
    wDay As Integer
    wHour As Integer
    wMinute As Integer
    wSecond As Integer
    wMilliseconds As Integer
End Type
Private Type TIME_ZONE_INFORMATION
    Bias As Long
    StandardName(31) As Integer
    StandardDate As SYSTEMTIME
    StandardBias As Long
    DaylightName(31) As Integer
    DaylightDate As SYSTEMTIME
    DaylightBias As Long
End Type

'/* tar Header Block, from POSIX 1003.1-1990.  */
'
'/* POSIX header.  */
'
'struct posix_header
'{                              /* byte offset */
'  char name[100];               /*   0 */
'  char mode[8];                 /* 100 */
'  char uid[8];                  /* 108 */
'  char gid[8];                  /* 116 */
'  char size[12];                /* 124 */
'  char mtime[12];               /* 136 */
'  char chksum[8];               /* 148 */
'  char typeflag;                /* 156 */
'  char linkname[100];           /* 157 */
'  char magic[6];                /* 257 */
'  char version[2];              /* 263 */
'  char uname[32];               /* 265 */
'  char gname[32];               /* 297 */
'  char devmajor[8];             /* 329 */
'  char devminor[8];             /* 337 */
'  char prefix[155];             /* 345 */
'                                /* 500 */
'};
'/* Values used in typeflag field.  */
'#define REGTYPE  '0'            /* regular file */
'#define AREGTYPE '\0'           /* regular file */
'#define LNKTYPE  '1'            /* link */
'#define SYMTYPE  '2'            /* reserved */
'#define CHRTYPE  '3'            /* character special */
'#define BLKTYPE  '4'            /* block special */
'#define DIRTYPE  '5'            /* directory */
'#define FIFOTYPE '6'            /* FIFO special */
'#define CONTTYPE '7'            /* reserved */
'#define XHDTYPE  'x'            /* Extended header referring to the
'                                   next file in the archive */
'#define XGLTYPE  'g'            /* Global extended header */

Private Type typeTarHeader
 sName(99) As Byte 'UTF-8? GB18030?
 sMode(7) As Byte
 sUID(7) As Byte
 sGID(7) As Byte
 sSize(11) As Byte
 sModifyTime(11) As Byte
 sCheckSum(7) As Byte
 sTypeFlag As Byte
 sLinkName(99) As Byte
 sMagicAndVersion(7) As Byte
 sUName(31) As Byte
 sGName(31) As Byte
 sDevMajor(7) As Byte
 sDevMinor(7) As Byte
 sPrefix(154) As Byte
 '///
 nReserved(11) As Byte
End Type

Private Type typeTarFileData
 sName As String
 nSize As Long '<0=unused (unused file linked-list :D)
 nMaxSize As Long
 bData() As Byte
End Type

Private m_tFiles() As typeTarFileData '1-based
Private m_nFileCount As Long
Private m_nFirstUnusedFile As Long

Friend Property Get FileCount() As Long
FileCount = m_nFileCount
End Property

Friend Function AddFile(ByRef sName As String, b() As Byte) As Long
Dim m As Long
Dim lps As Long
'///
On Error Resume Next
Err.Clear
lps = LBound(b)
m = UBound(b) - lps + 1
On Error GoTo 0
If Err.Number <> 0 Or m <= 0 Then m = 0
If m > 0 Then lps = VarPtr(b(lps))
'///
AddFile = AddFileEx(sName, lps, m)
End Function

Friend Function AddFileFromFile(ByRef sName As String, ByRef sFileName As String) As Long
On Error Resume Next
Dim nIndex As Long, m As Long
'///
If m_nFirstUnusedFile > 0 Then
 nIndex = m_nFirstUnusedFile
 m_nFirstUnusedFile = m_tFiles(nIndex).nSize Xor &H80000000
Else
 m_nFileCount = m_nFileCount + 1
 ReDim Preserve m_tFiles(1 To m_nFileCount)
 nIndex = m_nFileCount
End If
'///
Err.Clear
Open sFileName For Binary Access Read As #1
If Err.Number Then 'err! just remove it
 m_tFiles(nIndex).nSize = m_nFirstUnusedFile Xor &H80000000
 m_nFirstUnusedFile = nIndex
 nIndex = 0
Else
 m = LOF(1)
 m_tFiles(nIndex).sName = sName
 m_tFiles(nIndex).nSize = m
 If m > 0 Then
  m_tFiles(nIndex).nMaxSize = m
  ReDim m_tFiles(nIndex).bData(m - 1)
  Get #1, 1, m_tFiles(nIndex).bData
 End If
End If
Close
'///
AddFileFromFile = nIndex
End Function

Friend Function AddFileEx(ByRef sName As String, ByVal lpBuffer As Long, ByVal nSize As Long) As Long
Dim nIndex As Long
If m_nFirstUnusedFile > 0 Then
 nIndex = m_nFirstUnusedFile
 m_nFirstUnusedFile = m_tFiles(nIndex).nSize Xor &H80000000
Else
 m_nFileCount = m_nFileCount + 1
 ReDim Preserve m_tFiles(1 To m_nFileCount)
 nIndex = m_nFileCount
End If
'///
m_tFiles(nIndex).sName = sName
m_tFiles(nIndex).nSize = nSize
If m_tFiles(nIndex).nMaxSize < nSize Then
 m_tFiles(nIndex).nMaxSize = nSize
 ReDim m_tFiles(nIndex).bData(nSize - 1)
End If
If nSize > 0 Then CopyMemory m_tFiles(nIndex).bData(0), ByVal lpBuffer, nSize
'///
AddFileEx = nIndex
End Function

Friend Sub RemoveFile(ByVal nIndex As Long)
If m_tFiles(nIndex).nSize >= 0 Then
 m_tFiles(nIndex).nSize = m_nFirstUnusedFile Xor &H80000000
 m_nFirstUnusedFile = nIndex
End If
End Sub

Friend Sub Destroy()
Erase m_tFiles
m_nFileCount = 0
m_nFirstUnusedFile = 0
End Sub

Friend Property Get FileName(ByVal nIndex As Long) As String
If m_tFiles(nIndex).nSize >= 0 Then FileName = m_tFiles(nIndex).sName
End Property

Friend Property Let FileName(ByVal nIndex As Long, ByVal s As String)
If m_tFiles(nIndex).nSize >= 0 Then m_tFiles(nIndex).sName = Replace(s, "\", "/")
End Property

Friend Property Get FileSize(ByVal nIndex As Long, Optional ByVal bPreserve As Boolean) As Long
FileSize = m_tFiles(nIndex).nSize
End Property

Friend Property Let FileSize(ByVal nIndex As Long, Optional ByVal bPreserve As Boolean, ByVal n As Long)
Dim i As Long
i = m_tFiles(nIndex).nSize
If i >= 0 And n >= 0 Then
 If i <> n Then
  m_tFiles(nIndex).nSize = n
  If n > m_tFiles(nIndex).nMaxSize Then
   m_tFiles(nIndex).nMaxSize = n
   If bPreserve Then
    ReDim Preserve m_tFiles(nIndex).bData(n - 1)
   Else
    ReDim m_tFiles(nIndex).bData(n - 1)
   End If
  End If
 End If
 If Not bPreserve Then
  If n > 0 Then ZeroMemory m_tFiles(nIndex).bData(0), n
 End If
End If
End Property

Friend Function GetFileData(ByVal nIndex As Long, b() As Byte, Optional ByRef nSize As Long) As Boolean
nSize = m_tFiles(nIndex).nSize
If nSize < 0 Then
 nSize = 0
Else
 b = m_tFiles(nIndex).bData
 GetFileData = True
End If
End Function

Friend Function GetFileDataEx(ByVal nIndex As Long, ByVal lpBuffer As Long, ByVal nBufferSize As Long, Optional ByVal nOffset As Long, Optional ByRef nSizeReturn As Long) As Boolean
nSizeReturn = m_tFiles(nIndex).nSize
If nSizeReturn < 0 Then
 nSizeReturn = 0
Else
 nSizeReturn = nSizeReturn - nOffset
 If nSizeReturn > nBufferSize Then nSizeReturn = nBufferSize
 If nSizeReturn < 0 Then
  nSizeReturn = 0
 Else
  nOffset = nOffset + VarPtr(m_tFiles(nIndex).bData(0))
  CopyMemory ByVal lpBuffer, ByVal nOffset, nSizeReturn
 End If
 GetFileDataEx = True
End If
End Function

Friend Function SetFileData(ByVal nIndex As Long, b() As Byte) As Boolean
Dim m As Long
Dim lps As Long
'///
If m_tFiles(nIndex).nSize < 0 Then Exit Function
'///
On Error Resume Next
Err.Clear
lps = LBound(b)
m = UBound(b) - lps + 1
On Error GoTo 0
If Err.Number <> 0 Or m <= 0 Then m = 0
If m > 0 Then lps = VarPtr(b(lps))
'///
SetFileData = SetFileDataEx(nIndex, lps, m, , , True, True)
End Function

Friend Function SetFileDataEx(ByVal nIndex As Long, ByVal lpBuffer As Long, ByVal nSize As Long, Optional ByVal nOffset As Long, Optional ByRef nSizeReturn As Long, Optional ByVal bExpand As Boolean, Optional ByVal bTruncate As Boolean) As Boolean
Dim m As Long, m2 As Long
m = m_tFiles(nIndex).nSize
If m < 0 Then
 nSizeReturn = 0
Else
 nSizeReturn = m - nOffset
 If nSizeReturn > nSize Then
  If bTruncate Then m_tFiles(nIndex).nSize = nOffset + nSize
  nSizeReturn = nSize
 ElseIf nSizeReturn < nSize Then
  If bExpand Then
   '///
   m2 = nOffset + nSize
   m_tFiles(nIndex).nSize = m2
   If m2 > m_tFiles(nIndex).nMaxSize Then
    m_tFiles(nIndex).nMaxSize = m2 + &H20000
    ReDim Preserve m_tFiles(nIndex).bData(m2 + &H1FFFF)
   End If
   ZeroMemory m_tFiles(nIndex).bData(m), m2 - m
   '///
   nSizeReturn = nSize
  End If
 End If
 '///
 If nSizeReturn > 0 Then CopyMemory m_tFiles(nIndex).bData(nOffset), ByVal lpBuffer, nSizeReturn
 '///
 SetFileDataEx = True
End If
End Function

Friend Function FindOneFile(ByVal sFileName As String, Optional ByVal nLastIndex As Long) As Long
Dim i As Long
If nLastIndex >= m_nFileCount Then Exit Function _
Else If nLastIndex < 0 Then nLastIndex = 0
sFileName = Replace(sFileName, "\", "/")
For i = nLastIndex + 1 To m_nFileCount
 If m_tFiles(i).nSize >= 0 Then
  If LCase(m_tFiles(i).sName) Like sFileName Then
   FindOneFile = i
   Exit Function
  End If
 End If
Next i
End Function

Friend Function FindAllFiles(ByVal sFileName As String, ByRef nIndex() As Long) As Long
Dim i As Long, m As Long, m2 As Long
Erase nIndex
m = 0
m2 = 0
sFileName = Replace(sFileName, "\", "/")
For i = 1 To m_nFileCount
 If m_tFiles(i).nSize >= 0 Then
  If LCase(m_tFiles(i).sName) Like sFileName Then
   m = m + 1
   If m > m2 Then
    m2 = m2 + 16&
    ReDim Preserve nIndex(1 To m2)
    nIndex(m) = i
   End If
  End If
 End If
Next i
FindAllFiles = m
End Function

Friend Sub SetHeaderTime(t As typeTarHeader)
On Error Resume Next
Dim tInfo As TIME_ZONE_INFORMATION
Dim i As Long, nTime As Long
Dim s As String
i = GetTimeZoneInformation(tInfo)
nTime = (CDbl(Now) - CDbl(#1/1/1970#)) * 86400
Select Case i
Case 1
 nTime = nTime + tInfo.StandardBias * 60&
Case 2
 nTime = nTime + tInfo.DaylightBias * 60&
Case Else
 nTime = nTime + tInfo.Bias * 60&
End Select
s = StrConv(Right("00000000000" + Oct(nTime), 11), vbFromUnicode)
CopyMemory t.sModifyTime(0), ByVal StrPtr(s), 11&
End Sub

Friend Sub CalcHeaderCheckSum(t As typeTarHeader)
Dim b(511) As Byte
Dim i As Long, m As Long
Dim s As String
Erase t.sCheckSum
CopyMemory b(0), t, 512&
For i = 0 To 511
 m = m + b(i)
Next i
m = m + &H100& '???
s = StrConv(Right("000000" + Oct(m), 6), vbFromUnicode) + vbNullChar
CopyMemory t.sCheckSum(0), ByVal StrPtr(s), 6&
End Sub

Friend Function IsHeaderEmpty(ByRef t As typeTarHeader) As Boolean
Dim d(127) As Long
Dim i As Long
CopyMemory d(0), t, 512&
For i = 0 To 127
 If d(i) Then Exit Function
Next i
IsHeaderEmpty = True
End Function

'no sanity check :-3
Friend Function LoadTarLzmaFile(ByRef sFileName As String) As Boolean
On Error GoTo a
Dim b() As Byte, b2() As Byte
Dim m As Long
'///
Destroy
'///
Open sFileName For Binary Access Read As #1
m = LOF(1)
If m > 0 Then
 ReDim b2(m - 1)
 Get #1, 1, b2
End If
Close
If m > 0 Then
 If LZMADecompress_Correct_Simple(b2, b) Then
  LoadFromByteArray b
  LoadTarLzmaFile = True
 End If
End If
a:
Close
End Function

Friend Function SaveTarLzmaFile(ByRef sFileName As String) As Boolean
On Error GoTo a
Dim b() As Byte, b2() As Byte
SaveToByteArray b
If Not LZMACompress_Correct_Simple(b, b2, 0) Then Exit Function
Open sFileName For Output As #1
Close
Open sFileName For Binary As #1
Put #1, 1, b2
Close
SaveTarLzmaFile = True
a:
Close
End Function

'no sanity check :-3
Friend Function LoadFile(ByRef sFileName As String) As Boolean
On Error GoTo a
Dim t As typeTarHeader
Dim lp As Long, i As Long, m As Long
Dim bEmpty As Boolean
Dim nSize As Long
Dim s As String
'///
Destroy
'///
Open sFileName For Binary Access Read As #1
lp = 0
m = LOF(1)
Do Until lp + 512& > m
 Get #1, lp + 1, t
 lp = lp + 512&
 nSize = 0
 If IsHeaderEmpty(t) Then
  If bEmpty Then Exit Do Else bEmpty = True
 Else
  bEmpty = False
  s = StrConv(t.sSize, vbUnicode)
  i = InStr(1, s, vbNullChar)
  If i > 0 Then s = Left(s, i - 1)
  nSize = Val("&O" + Trim(s) + "&")
  If nSize < 0 Then nSize = 0
  '///
  If t.sTypeFlag = 0 Or t.sTypeFlag = &H30& Then 'only support file :-3
   s = StrConv(t.sName, vbUnicode)
   i = InStr(1, s, vbNullChar)
   If i > 0 Then s = Left(s, i - 1)
   s = Replace(s, "\", "/")
   If Right(s, 1) <> "/" Or nSize > 0 Then
    '///
    m_nFileCount = m_nFileCount + 1
    ReDim Preserve m_tFiles(1 To m_nFileCount)
    With m_tFiles(m_nFileCount)
     .sName = s
     .nSize = nSize
     .nMaxSize = nSize
     If nSize > 0 Then
      ReDim .bData(nSize - 1)
      Get #1, lp + 1, .bData
     End If
    End With
   End If
  End If
  '///
  lp = lp + ((nSize + &H1FF&) And &HFFFFFE00)
 End If
Loop
LoadFile = True
a:
Close
End Function

'no sanity check :-3
Friend Sub LoadFromMemory(ByVal lpData As Long, ByVal m As Long)
Dim t As typeTarHeader
Dim lp As Long, i As Long
Dim bEmpty As Boolean
Dim nSize As Long
Dim s As String
'///
Destroy
'///
Do Until lp + 512& > m
 CopyMemory t, ByVal (lpData + lp), 512&
 lp = lp + 512&
 nSize = 0
 If IsHeaderEmpty(t) Then
  If bEmpty Then Exit Do Else bEmpty = True
 Else
  bEmpty = False
  s = StrConv(t.sSize, vbUnicode)
  i = InStr(1, s, vbNullChar)
  If i > 0 Then s = Left(s, i - 1)
  nSize = Val("&O" + Trim(s) + "&")
  If nSize < 0 Then nSize = 0
  '///
  If t.sTypeFlag = 0 Or t.sTypeFlag = &H30& Then 'only support file :-3
   s = StrConv(t.sName, vbUnicode)
   i = InStr(1, s, vbNullChar)
   If i > 0 Then s = Left(s, i - 1)
   s = Replace(s, "\", "/")
   If Right(s, 1) <> "/" Or nSize > 0 Then
    '///
    m_nFileCount = m_nFileCount + 1
    ReDim Preserve m_tFiles(1 To m_nFileCount)
    With m_tFiles(m_nFileCount)
     .sName = s
     .nSize = nSize
     .nMaxSize = nSize
     If nSize > 0 Then
      ReDim .bData(nSize - 1)
      CopyMemory .bData(0), ByVal (lpData + lp), nSize
     End If
    End With
   End If
  End If
  '///
  lp = lp + ((nSize + &H1FF&) And &HFFFFFE00)
 End If
Loop
End Sub

Friend Sub LoadFromByteArray(b() As Byte)
Dim m As Long
Dim lps As Long
'///
On Error Resume Next
Err.Clear
lps = LBound(b)
m = UBound(b) - lps + 1
On Error GoTo 0
If Err.Number <> 0 Or m <= 0 Then m = 0
If m > 0 Then lps = VarPtr(b(lps))
'///
LoadFromMemory lps, m
End Sub


Friend Function SaveFile(ByRef sFileName As String) As Boolean
On Error GoTo a
Dim i As Long, nTime As Long
Dim t As typeTarHeader
Dim b() As Byte
Dim s As String, m As Long, n As Long
Dim lp As Long
'///
SetHeaderTime t
'///
s = StrConv("0000666", vbFromUnicode)
CopyMemory t.sMode(0), ByVal StrPtr(s), LenB(s)
s = StrConv("0000000", vbFromUnicode)
CopyMemory t.sUID(0), ByVal StrPtr(s), LenB(s)
CopyMemory t.sGID(0), ByVal StrPtr(s), LenB(s)
t.sTypeFlag = &H30&
'///
Open sFileName For Output As #1
Close
Open sFileName For Binary As #1
lp = 1
For i = 1 To m_nFileCount
 m = m_tFiles(i).nSize
 If m >= 0 Then
  CopyMemory t.sSize(0), ByVal StrPtr(StrConv(Right("00000000000" + Oct(m), 11), vbFromUnicode)), 11&
  Erase t.sName
  s = StrConv(m_tFiles(i).sName, vbFromUnicode)
  n = LenB(s)
  If n > 99 Then n = 99
  If n > 0 Then CopyMemory t.sName(0), ByVal StrPtr(s), n
  CalcHeaderCheckSum t
  Put #1, lp, t
  lp = lp + 512&
  '///
  If m > 0 Then
   m = (m + &H1FF&) And &HFFFFFE00
   If m_tFiles(i).nMaxSize <> m Then
    m_tFiles(i).nMaxSize = m
    ReDim Preserve m_tFiles(i).bData(m - 1)
   End If
   Put #1, lp, m_tFiles(i).bData
   lp = lp + m
  End If
  '///
 End If
Next i
'///
ReDim b(1023&)
Put #1, lp, b
'///
SaveFile = True
a:
Close
End Function

Friend Function SaveToByteArray(b() As Byte) As Long
Dim i As Long, nTime As Long
Dim t As typeTarHeader
Dim s As String, m As Long, n As Long
Dim lp As Long, nMaxSize As Long
'///
SetHeaderTime t
'///
s = StrConv("0000666", vbFromUnicode)
CopyMemory t.sMode(0), ByVal StrPtr(s), LenB(s)
s = StrConv("0000000", vbFromUnicode)
CopyMemory t.sUID(0), ByVal StrPtr(s), LenB(s)
CopyMemory t.sGID(0), ByVal StrPtr(s), LenB(s)
t.sTypeFlag = &H30&
'///
nMaxSize = &H20000
ReDim b(nMaxSize - 1)
'///
lp = 0
For i = 1 To m_nFileCount
 m = m_tFiles(i).nSize
 If m >= 0 Then
  CopyMemory t.sSize(0), ByVal StrPtr(StrConv(Right("00000000000" + Oct(m), 11), vbFromUnicode)), 11&
  Erase t.sName
  s = StrConv(m_tFiles(i).sName, vbFromUnicode)
  n = LenB(s)
  If n > 99 Then n = 99
  If n > 0 Then CopyMemory t.sName(0), ByVal StrPtr(s), n
  CalcHeaderCheckSum t
  '///
  If lp + 512& >= nMaxSize Then
   nMaxSize = nMaxSize + &H20000
   ReDim Preserve b(nMaxSize - 1)
  End If
  CopyMemory b(lp), t, 512&
  lp = lp + 512&
  '///
  If m > 0 Then
   n = (m + &H1FF&) And &HFFFFFE00
   If lp + n >= nMaxSize Then
    nMaxSize = nMaxSize + n + &H20000
    ReDim Preserve b(nMaxSize - 1)
   End If
   CopyMemory b(lp), m_tFiles(i).bData(0), m
   lp = lp + n
  End If
  '///
 End If
Next i
'///
lp = lp + 1024&
ReDim Preserve b(lp - 1)
SaveToByteArray = lp
End Function
