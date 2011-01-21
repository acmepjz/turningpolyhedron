VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsXMLSerializer"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'////////////////////////////////
'This file is public domain.
'////////////////////////////////

'a buggy XML reader/writer, only supports most basic features,
'and will produce ill-formed XML files :D

Private Type SAFEARRAYBOUND
    cElements As Long
    lLbound As Long
End Type
Private Type SAFEARRAY2D
    cDims As Integer
    fFeatures As Integer
    cbElements As Long
    cLocks As Long
    pvData As Long
    Bounds(0 To 1) As SAFEARRAYBOUND
End Type
Private Declare Function VarPtrArray Lib "msvbvm60.dll" Alias "VarPtr" (Ptr() As Any) As Long
Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)
Private Declare Sub ZeroMemory Lib "kernel32.dll" Alias "RtlZeroMemory" (ByRef Destination As Any, ByVal Length As Long)

Public Enum enumVBChar
 ["\0"] = 0
 ["\t"] = 9
 ["\n"] = 10
 ["\r"] = 13
 [" "] = 32
 ["!"] = 33
 ["""] = 34
 ["#"] = 35
 ["$"] = 36
 ["%"] = 37
 ["&"] = 38
 ["'"] = 39
 ["("] = 40
 [")"] = 41
 ["*"] = 42
 ["+"] = 43
 [","] = 44
 ["-"] = 45
 ["."] = 46
 ["/"] = 47
 ["0"] = 48
 ["1"] = 49
 ["2"] = 50
 ["3"] = 51
 ["4"] = 52
 ["5"] = 53
 ["6"] = 54
 ["7"] = 55
 ["8"] = 56
 ["9"] = 57
 [":"] = 58
 [";"] = 59
 ["<"] = 60
 ["="] = 61
 [">"] = 62
 ["?"] = 63
 ["@"] = 64
 ["a"] = 65
 ["b"] = 66
 ["c"] = 67
 ["d"] = 68
 ["e"] = 69
 ["f"] = 70
 ["g"] = 71
 ["h"] = 72
 ["i"] = 73
 ["j"] = 74
 ["k"] = 75
 ["l"] = 76
 ["m"] = 77
 ["n"] = 78
 ["o"] = 79
 ["p"] = 80
 ["q"] = 81
 ["r"] = 82
 ["s"] = 83
 ["t"] = 84
 ["u"] = 85
 ["v"] = 86
 ["w"] = 87
 ["x"] = 88
 ["y"] = 89
 ["z"] = 90
 ["lll"] = 91
 ["\"] = 92
 ["rrr"] = 93
 ["^"] = 94
 ["_"] = 95
 ["`"] = 96
 ["aa"] = 97
 ["bb"] = 98
 ["cc"] = 99
 ["dd"] = 100
 ["ee"] = 101
 ["ff"] = 102
 ["gg"] = 103
 ["hh"] = 104
 ["ii"] = 105
 ["jj"] = 106
 ["kk"] = 107
 ["ll"] = 108
 ["mm"] = 109
 ["nn"] = 110
 ["oo"] = 111
 ["pp"] = 112
 ["qq"] = 113
 ["rr"] = 114
 ["ss"] = 115
 ["tt"] = 116
 ["uu"] = 117
 ["vv"] = 118
 ["ww"] = 119
 ["xx"] = 120
 ["yy"] = 121
 ["zz"] = 122
 ["{"] = 123
 ["|"] = 124
 ["}"] = 125
 ["~"] = 126
End Enum

'Implements ITreeStorageReader
'Implements ITreeStorageWriter

Private m_nEncoding As Long
'0=UTF8 (default)
'1=UCS2LE
'2=UCS2BE

Private Type typeXMLReadStack
 obj As ITreeStorageBuilder
 lps As Long
 nLength As Long
End Type

Friend Sub SetEncoding(ByVal sEncoding As String)
sEncoding = Replace(sEncoding, " ", "", , , vbTextCompare)
sEncoding = Replace(sEncoding, "-", "", , , vbTextCompare)
sEncoding = Replace(sEncoding, "_", "", , , vbTextCompare)
sEncoding = Replace(sEncoding, "(", "", , , vbTextCompare)
sEncoding = Replace(sEncoding, ")", "", , , vbTextCompare)
If InStr(1, sEncoding, "utf8", vbTextCompare) > 0 Then
 m_nEncoding = 0
ElseIf InStr(1, sEncoding, "ucs2be", vbTextCompare) > 0 Then
 m_nEncoding = 2
Else
 m_nEncoding = 1
End If
End Sub

Friend Function pEscapeAndWriteString(ByVal lp As Long, ByVal nLength As Long, ByVal nType As Long, ByVal objOut As clsTreeStorageNode) As Long
'///
'type:
'0-normal
'1-name,etc.
'///
On Error Resume Next
Dim tSA As SAFEARRAY2D
Dim d() As Byte
Dim d2(8399&) As Byte
Dim i As Long, j As Long, m As Long
Dim c1 As Long, c2 As Long
'///
If nLength > 0 Then
 '///
 tSA.cbElements = 1
 tSA.cDims = 1
 tSA.Bounds(0).cElements = nLength
 tSA.pvData = lp
 CopyMemory ByVal VarPtrArray(d), VarPtr(tSA), 4&
 '///
 For i = 0 To nLength - 1 Step 2
  If i < nLength - 1 Then
   c1 = d(i)
   c2 = d(i + 1)
  Else
   c1 = d(i)
   c2 = 0
  End If
  '///
  If c2 = 0 Then
   If c1 = ["&"] Then '&amp;
    d2(j) = ["&"]: d2(j + 1) = 0
    d2(j + 2) = ["aa"]: d2(j + 3) = 0
    d2(j + 4) = ["mm"]: d2(j + 5) = 0
    d2(j + 6) = ["pp"]: d2(j + 7) = 0
    d2(j + 8) = [";"]: d2(j + 9) = 0
    j = j + 10
   ElseIf c1 = ["<"] Then '&lt;
    d2(j) = ["&"]: d2(j + 1) = 0
    d2(j + 2) = ["ll"]: d2(j + 3) = 0
    d2(j + 4) = ["tt"]: d2(j + 5) = 0
    d2(j + 6) = [";"]: d2(j + 7) = 0
    j = j + 8
   ElseIf c1 = [">"] Then '&gt;
    d2(j) = ["&"]: d2(j + 1) = 0
    d2(j + 2) = ["gg"]: d2(j + 3) = 0
    d2(j + 4) = ["tt"]: d2(j + 5) = 0
    d2(j + 6) = [";"]: d2(j + 7) = 0
    j = j + 8
   ElseIf c1 = ["""] Then '&quot;
    d2(j) = ["&"]: d2(j + 1) = 0
    d2(j + 2) = ["qq"]: d2(j + 3) = 0
    d2(j + 4) = ["uu"]: d2(j + 5) = 0
    d2(j + 6) = ["oo"]: d2(j + 7) = 0
    d2(j + 8) = ["tt"]: d2(j + 9) = 0
    d2(j + 10) = [";"]: d2(j + 11) = 0
    j = j + 12
   ElseIf c1 = ["'"] Then '&apos;
    d2(j) = ["&"]: d2(j + 1) = 0
    d2(j + 2) = ["aa"]: d2(j + 3) = 0
    d2(j + 4) = ["pp"]: d2(j + 5) = 0
    d2(j + 6) = ["oo"]: d2(j + 7) = 0
    d2(j + 8) = ["ss"]: d2(j + 9) = 0
    d2(j + 10) = [";"]: d2(j + 11) = 0
    j = j + 12
   ElseIf (c1 >= 0 And c1 < 32) Or _
   (nType > 0 And (c1 = [" "] Or c1 = ["/"] Or c1 = ["="] Or c1 = ["?"] Or c1 = ["!"] Or c1 = ["lll"] Or c1 = ["rrr"])) Then
    'must <100
    d2(j) = ["&"]: d2(j + 1) = 0
    d2(j + 2) = ["#"]: d2(j + 3) = 0
    j = j + 4
    If c1 >= 10 Then
     d2(j) = ["0"] + (c1 \ 10): d2(j + 1) = 0
     j = j + 2
    End If
    d2(j) = ["0"] + (c1 Mod 10): d2(j + 1) = 0
    d2(j + 2) = [";"]: d2(j + 3) = 0
    j = j + 4
   Else
    d2(j) = c1
    d2(j + 1) = 0
    j = j + 2
   End If
  Else
   d2(j) = c1
   d2(j + 1) = c2
   j = j + 2
  End If
  '///
  If j >= 8192& Then
   m = m + WriteString(VarPtr(d2(0)), j, objOut)
   j = 0
  End If
 Next i
 If j > 0 Then m = m + WriteString(VarPtr(d2(0)), j, objOut)
 '///
 ZeroMemory ByVal VarPtrArray(d), 4&
 '///
 pEscapeAndWriteString = m
End If
End Function

Friend Function WriteString(ByVal lp As Long, ByVal nLength As Long, ByVal objOut As clsTreeStorageNode) As Long
On Error Resume Next
Dim tSA As SAFEARRAY2D
Dim d() As Byte
Dim tSA2 As SAFEARRAY2D
Dim d2() As Byte
Dim i As Long, j As Long, m As Long
Dim c As Long
'///
If nLength > 0 Then
 Select Case m_nEncoding
 Case 1 '////////UCS2LE
  objOut.AppendValueEx lp, nLength
  If nLength And 1& Then _
  objOut.AppendValueEx VarPtr(0&), 1
  WriteString = (nLength + 1) And &HFFFFFFFE
 Case 2 '////////UCS2BE
  j = (nLength + 1) And &HFFFFFFFE
  m = objOut.ExpandValueSizeEx(j, 0, &H40000)
  '///
  tSA.cbElements = 1
  tSA.cDims = 1
  tSA.Bounds(0).cElements = nLength
  tSA.pvData = lp
  CopyMemory ByVal VarPtrArray(d), VarPtr(tSA), 4&
  '///
  tSA2.cbElements = 1
  tSA2.cDims = 1
  tSA2.Bounds(0).cElements = nLength + 1
  tSA2.pvData = objOut.ValuePointer + m
  CopyMemory ByVal VarPtrArray(d2), VarPtr(tSA2), 4&
  '///
  For i = 0 To nLength - 2 Step 2
   d2(i) = d(i + 1)
   d2(i + 1) = d(i)
  Next i
  If nLength And 1& Then
   d2(nLength - 1) = 0
   d2(nLength) = d(nLength - 1)
  End If
  '///
  ZeroMemory ByVal VarPtrArray(d), 4&
  ZeroMemory ByVal VarPtrArray(d2), 4&
  '///
  WriteString = j
 Case Else '////////UTF8
  m = objOut.ExpandValueSizeEx(0, nLength * 2&, &H40000)
  '///
  tSA.cbElements = 1
  tSA.cDims = 1
  tSA.Bounds(0).cElements = nLength
  tSA.pvData = lp
  CopyMemory ByVal VarPtrArray(d), VarPtr(tSA), 4&
  '///
  tSA2.cbElements = 1
  tSA2.cDims = 1
  tSA2.Bounds(0).cElements = nLength * 2&
  tSA2.pvData = objOut.ValuePointer + m
  CopyMemory ByVal VarPtrArray(d2), VarPtr(tSA2), 4&
  '///
  For i = 0 To nLength - 2 Step 2
   c = d(i) Or (d(i + 1) * 256&)
   If c < &H80& Then
    d2(j) = c
    j = j + 1
   ElseIf c < &H800& Then
    d2(j) = &HC0& Or ((c And &H7C0&) \ &H40&)
    d2(j + 1) = &H80& Or (c And &H3F&)
    j = j + 2
   Else
    d2(j) = &HE0& Or ((c And &HF000&) \ &H1000&)
    d2(j + 1) = &H80& Or ((c And &HFC0&) \ &H40&)
    d2(j + 2) = &H80& Or (c And &H3F&)
    j = j + 3
   End If
  Next i
  If nLength And 1& Then
   c = d(nLength - 1)
   If c < &H80& Then
    d2(j) = c
    j = j + 1
   Else
    d2(j) = &HC0& Or (c \ &H40&)
    d2(j + 1) = &H80& Or (c And &H3F&)
    j = j + 2
   End If
  End If
  '///
  ZeroMemory ByVal VarPtrArray(d), 4&
  ZeroMemory ByVal VarPtrArray(d2), 4&
  '///
  objOut.ValueSize = m + j
  WriteString = j
 End Select
End If
End Function

Friend Sub WriteHeader(ByVal objOut As clsTreeStorageNode, Optional ByVal bPretty As Boolean = True)
Dim s As String, m As Long
Select Case m_nEncoding
Case 1
 s = ChrW(&HFEFF&) + "<?xml version=""1.0""?>"
 If bPretty Then s = s + vbCrLf
 m = LenB(s)
Case 2
 s = ChrW(&HFFFE&) + ChrB(0) + "<?xml version=""1.0""?>"
 If bPretty Then s = s + vbCrLf
 m = LenB(s) - 1
Case Else
 s = "<?xml version=""1.0"" encoding=""UTF-8""?>"
 If bPretty Then s = s + vbCrLf
 s = StrConv(s, vbFromUnicode)
 m = LenB(s)
End Select
objOut.AppendValueEx StrPtr(s), m
End Sub

Friend Function SaveNodeToFile(ByVal FileName As String, ByVal obj As ITreeStorageReader, Optional ByVal bWriteHeader As Boolean = True, Optional ByVal nIndent As Long, Optional ByVal bSaveSubNodeOnly As Boolean) As Boolean
Dim objOut As New clsTreeStorageNode
WriteNode obj, objOut, bWriteHeader, nIndent, bSaveSubNodeOnly
SaveNodeToFile = objOut.SaveValueToFile(FileName)
End Function

Friend Sub WriteNode(ByVal obj As ITreeStorageReader, ByVal objOut As clsTreeStorageNode, Optional ByVal bWriteHeader As Boolean = True, Optional ByVal nIndent As Long, Optional ByVal bSaveSubNodeOnly As Boolean)
On Error Resume Next
Dim obj1 As ITreeStorageReader
Dim lp As Long, lp1 As Long, lp2 As Long
Dim m As Long, m1 As Long, m2 As Long
Dim i As Long
Dim bHaveContents As Boolean
Dim bHaveSubNode As Boolean
Dim bNoPretty As Boolean
'///
If bWriteHeader Then WriteHeader objOut, nIndent >= 0
'///
If Not bSaveSubNodeOnly Then
 '///name
 m = obj.GetName(lp)
 WriteString StrPtr("<"), 2, objOut
 pEscapeAndWriteString lp, m, 1, objOut
 '///
 bHaveContents = m > 0
 bHaveSubNode = False
 '///attributes
 i = 0
 Do
  i = obj.GetNextAttribute(i, lp1, m1, lp2, m2)
  If i = 0 Then Exit Do
  bHaveContents = True
  WriteString StrPtr(" "), 2, objOut
  pEscapeAndWriteString lp1, m1, 1, objOut
  WriteString StrPtr("="""), 4, objOut
  pEscapeAndWriteString lp2, m2, 0, objOut
  WriteString StrPtr(""""), 2, objOut
 Loop
 '///value
 m1 = obj.GetValue(lp1)
 If m1 > 0 Then
  bHaveContents = True
  bHaveSubNode = True
  bNoPretty = True
  WriteString StrPtr(">"), 2, objOut
  pEscapeAndWriteString lp1, m1, 0, objOut
 End If
End If
'///child nodes
'TODO:non-recursive
i = 0
Do
 i = obj.GetNextNode(i, obj1)
 If i = 0 Then Exit Do
 If Not obj1 Is Nothing Then
  If Not bHaveSubNode Then
   WriteString StrPtr(">"), 2, objOut
   bHaveSubNode = True
  End If
  If nIndent >= 0 Then
   If Not bNoPretty Then
    WriteString StrPtr(vbCrLf + String(nIndent + 1, vbTab)), (nIndent + 3&) * 2&, objOut
   End If
   bNoPretty = False
   WriteNode obj1, objOut, False, nIndent + 1, False
  Else
   WriteNode obj1, objOut, False, -1, False
  End If
 End If
 Set obj1 = Nothing
Loop
'///
If Not bSaveSubNodeOnly Then
 If bHaveSubNode Then
  If nIndent >= 0 And Not bNoPretty Then
   WriteString StrPtr(vbCrLf + String(nIndent, vbTab)), (nIndent + 2&) * 2&, objOut
  End If
  If m > 0 Then
   WriteString StrPtr("</"), 4, objOut
   pEscapeAndWriteString lp, m, 1, objOut
   WriteString StrPtr(">"), 2, objOut
  Else
   WriteString StrPtr("</ >"), 8, objOut
  End If
 ElseIf bHaveContents Then
  WriteString StrPtr("/>"), 4, objOut
 Else
  WriteString StrPtr(" />"), 6, objOut
 End If
End If
End Sub

'internal use only
Friend Function pDecodeStringToBuffer(ByVal nEncoding As Long, d() As Byte, ByRef i As Long, ByVal nLength As Long, ByVal lpd2 As Long, ByVal nSizeToRead As Long) As Long
On Error Resume Next
Dim tSA2 As SAFEARRAY2D
Dim d2() As Byte
Dim j As Long
Dim c As Long, c1 As Long
'///
Select Case nEncoding
Case 1 'UCS2LE
 If nSizeToRead > nLength - i Then nSizeToRead = nLength - i
 CopyMemory ByVal lpd2, d(i), nSizeToRead
 i = i + nSizeToRead
 If nSizeToRead And 1& Then
  ZeroMemory ByVal lpd2 + nSizeToRead, 1
  nSizeToRead = nSizeToRead + 1
 End If
 pDecodeStringToBuffer = nSizeToRead
Case 2 'UCS2BE
 '///
 tSA2.cbElements = 1
 tSA2.cDims = 1
 tSA2.Bounds(0).cElements = nSizeToRead + 16&
 tSA2.pvData = lpd2
 CopyMemory ByVal VarPtrArray(d2), VarPtr(tSA2), 4&
 '///
 If nSizeToRead > nLength - i Then nSizeToRead = nLength - i
 For j = 0 To nSizeToRead - 2 Step 2
  d2(j) = d(i + j + 1)
  d2(j + 1) = d(i + j)
 Next j
 i = i + nSizeToRead
 If nSizeToRead And 1& Then
  d2(nSizeToRead - 1) = 0
  d2(nSizeToRead) = d(i - 1)
  nSizeToRead = nSizeToRead + 1
 End If
 '///
 ZeroMemory ByVal VarPtrArray(d2), 4&
 '///
 pDecodeStringToBuffer = nSizeToRead
Case Else 'UTF8
 '///
 tSA2.cbElements = 1
 tSA2.cDims = 1
 tSA2.Bounds(0).cElements = nSizeToRead + 16&
 tSA2.pvData = lpd2
 CopyMemory ByVal VarPtrArray(d2), VarPtr(tSA2), 4&
 '///
 For j = 0 To nSizeToRead - 2 Step 2
  If i >= nLength Then Exit For
  c = d(i)
  i = i + 1
  If c < &H80& Then
   d2(j) = c
   d2(j + 1) = 0
  ElseIf c < &HC0& Or c >= &HF0& Then 'invalid or unsupported
   d2(j) = ["?"]
   d2(j + 1) = 0
  ElseIf c < &HE0& Then
   If i >= nLength Then Exit For
   d2(j) = (d(i) And &H3F&) Or ((c And &H3&) * &H40&)
   d2(j + 1) = (c And &H1C&) \ &H4&
   i = i + 1
  Else
   i = i + 2
   If i > nLength Then Exit For
   c1 = d(i - 2)
   d2(j) = (d(i - 1) And &H3F&) Or ((c1 And &H3&) * &H40&)
   d2(j + 1) = ((c1 And &H3C&) \ &H4&) Or ((c And &HF&) * &H10&)
  End If
 Next j
 '///
 ZeroMemory ByVal VarPtrArray(d2), 4&
 '///
 pDecodeStringToBuffer = j
End Select
End Function

'internal use only
Friend Sub pSkipSpaces(ByRef d2() As Integer, ByRef i As Long, ByVal m As Long)
On Error Resume Next
Dim c As Long
Do While i < m
 c = d2(i)
 If c = [" "] Or c = ["\r"] Or c = ["\n"] Or c = ["\t"] Then i = i + 1 _
 Else Exit Do
Loop
End Sub

'internal use only
Friend Function pUnescapeStringInPlace(ByRef d2() As Integer, ByRef i As Long, ByVal m As Long, Optional ByVal nEndCharacter As Long, Optional ByRef nLTrim As Long, Optional ByRef nRTrim As Long) As Long
On Error Resume Next
Dim iOld As Long
Dim nCount As Long
Dim c As Long, c1 As Long
Dim bStart As Boolean
'///
iOld = i
nLTrim = 0
nRTrim = 0
Do While i < m
 c = d2(i)
 If nEndCharacter Then
  If c = nEndCharacter Then Exit Do
  If c = [" "] Or c = ["\r"] Or c = ["\n"] Or c = ["\t"] Then
   If bStart Then nRTrim = nRTrim + 1 Else nLTrim = nLTrim + 1
  Else
   bStart = True
   nRTrim = 0
  End If
 Else
  If c = [" "] Or c = ["\r"] Or c = ["\n"] Or c = ["\t"] _
  Or c = ["<"] Or c = ["/"] Or c = [">"] Or c = ["="] Or c = ["""] Or c = ["'"] Then Exit Do
 End If
 i = i + 1
 '///unescape?
 If c = ["&"] Then
  If i >= m Then Exit Do
  Select Case d2(i)
  Case ["#"]
   i = i + 1
   If i >= m Then Exit Do
   c = d2(i)
   i = i + 1
   Select Case c
   Case ["x"], ["xx"] 'hex
    c = 0
    Do While i < m
     c1 = d2(i)
     Select Case c1
     Case ["0"] To ["9"]
      c = (c * 16& + (c1 - ["0"])) And &HFFFF&
     Case ["a"] To ["f"]
      c = (c * 16& + (c1 - 55)) And &HFFFF&
     Case ["aa"] To ["ff"]
      c = (c * 16& + (c1 - 87)) And &HFFFF&
     Case Else
      Exit Do
     End Select
    Loop
   Case ["0"] To ["9"] 'dec
    c = c - ["0"]
    Do While i < m
     c1 = d2(i)
     i = i + 1
     Select Case c1
     Case ["0"] To ["9"]
      c = (c * 10& + (c1 - ["0"])) And &HFFFF&
     Case Else
      Exit Do
     End Select
    Loop
   End Select
  Case ["aa"]
   If i + 3 >= m Then Exit Do
   Select Case d2(i + 1)
   Case ["mm"]
    If d2(i + 2) = ["pp"] And d2(i + 3) = [";"] Then
     i = i + 4
     c = ["&"]
    End If
   Case ["pp"]
    If i + 4 >= m Then Exit Do
    If d2(i + 2) = ["oo"] And d2(i + 3) = ["ss"] And d2(i + 4) = [";"] Then
     i = i + 5
     c = ["'"]
    End If
   End Select
  Case ["gg"]
   If i + 2 >= m Then Exit Do
   If d2(i + 1) = ["tt"] And d2(i + 2) = [";"] Then
    i = i + 3
    c = [">"]
   End If
  Case ["ll"]
   If i + 2 >= m Then Exit Do
   If d2(i + 1) = ["tt"] And d2(i + 2) = [";"] Then
    i = i + 3
    c = ["<"]
   End If
  Case ["qq"]
   If i + 4 >= m Then Exit Do
   If d2(i + 1) = ["uu"] And d2(i + 2) = ["oo"] And d2(i + 3) = ["tt"] And d2(i + 4) = [";"] Then
    i = i + 5
    c = ["""]
   End If
  End Select
 End If
 '///
 If c And &H8000& Then c = c Or &HFFFF0000
 d2(iOld + nCount) = c
 nCount = nCount + 1
Loop
'///over
pUnescapeStringInPlace = nCount
End Function

Friend Function LoadNodeFromFile(ByVal FileName As String, ByVal objOut As ITreeStorageBuilder, Optional ByVal bLoadSubNodeOnly As Boolean) As Boolean
On Error GoTo a
Dim b() As Byte, m As Long
Open FileName For Binary As #1
m = LOF(1)
If m > 0 Then
 ReDim b(m - 1)
 Get #1, 1, b
End If
Close
If m > 0 Then LoadNodeFromFile = ReadNode(VarPtr(b(0)), m, objOut, bLoadSubNodeOnly) _
Else LoadNodeFromFile = True
Exit Function
a:
Close
End Function

Friend Function ReadNode(ByVal lp As Long, ByVal nLength As Long, ByVal objOut As ITreeStorageBuilder, Optional ByVal bLoadSubNodeOnly As Boolean) As Boolean
On Error Resume Next
Dim nEncoding As Long
Dim tSA As SAFEARRAY2D
Dim d() As Byte
'///
Dim d2() As Integer
Dim i As Long, j As Long, m As Long
Dim c As Long, c1 As Long, c2 As Long, c3 As Long
'///stack
Dim nStackPointer As Long
Dim nStackSize As Long
Dim tStack() As typeXMLReadStack
'///
If nLength > 0 Then
 tSA.cbElements = 1
 tSA.cDims = 1
 tSA.Bounds(0).cElements = nLength
 tSA.pvData = lp
 CopyMemory ByVal VarPtrArray(d), VarPtr(tSA), 4&
 '///guess encoding
 If nLength >= 2 Then
  c1 = d(0)
  c2 = d(1)
  c = c1 Or (c2 * 256&)
  If c = &HFEFF& Then
   nEncoding = 1
   i = 2
  ElseIf c = &HFFFE& Then
   nEncoding = 2
   i = 2
  ElseIf c1 <> 0 And c2 = 0 Then
   nEncoding = 1
  ElseIf c1 = 0 And c2 <> 0 Then
   nEncoding = 2
  End If
 End If
 If nLength >= 3 And nEncoding = 0 Then
  c = c Or (d(2) * 65536)
  If c = &HBFBBEF Then i = 3
 End If
 '///decode to buffer
 'TODO:don't allocate full memory at one time
 m = nLength + 2
 ReDim d2(m - 1)
 m = pDecodeStringToBuffer(nEncoding, d, i, nLength, VarPtr(d2(0)), m * 2&) \ 2&
 '///
 ZeroMemory ByVal VarPtrArray(d), 4&
 '///init
 nStackSize = 32
 ReDim tStack(nStackSize - 1)
 If bLoadSubNodeOnly Then
  With tStack(0)
   Set .obj = objOut
   .nLength = &H80000000
  End With
 Else
  nStackPointer = -1
 End If
 '///main loop
 i = 0
 Do While i < m
  c = d2(i)
  Select Case c
  Case ["<"]
   i = i + 1
   If i >= m Then Exit Function
   c = d2(i)
   '///
   Select Case c
   Case ["!"]
    '<!DOCTYPE and <![CDATA[ are not supported, only comments
    If i + 2 >= m Then Exit Function
    If d2(i + 1) <> ["-"] Or d2(i + 2) <> ["-"] Then Exit Function
    '///skip comment
    i = i + 3
    Do While i < m
     If d2(i - 2) = ["-"] Then
      If d2(i - 1) = ["-"] Then
       If d2(i) = [">"] Then Exit Do
      End If
     End If
     i = i + 1
    Loop
    i = i + 1
   Case ["?"]
    '///skip headers
    i = i + 1
    Do While i < m
'     If d2(i - 1) = ["?"] Then '??? ill-formed?
      If d2(i) = [">"] Then Exit Do
'     End If
     i = i + 1
    Loop
    i = i + 1
   Case ["/"]
    '///end of node
    If nStackPointer < 0 Then Exit Function
    i = i + 1
    '///read name and check the same
    c1 = i
    c = pUnescapeStringInPlace(d2, i, m)
    If c <> tStack(nStackPointer).nLength Then Exit Function
    c2 = tStack(nStackPointer).lps
    For j = 0 To c - 1
     If d2(c1 + j) <> d2(c2 + j) Then Exit Function
    Next j
    '///
    pSkipSpaces d2, i, m
    If i >= m Then Exit Function
    If d2(i) <> [">"] Then Exit Function
    i = i + 1
    '///raise event and pop stack
    objOut.EndNode
    nStackPointer = nStackPointer - 1
    If nStackPointer < 0 Then Exit Do
    Set objOut = tStack(nStackPointer).obj
   Case Else
    '///begin of node
    '///push stack
    If nStackPointer < 0 Then
     nStackPointer = 0
    Else
     nStackPointer = nStackPointer + 1
     If nStackPointer >= nStackSize Then
      nStackSize = nStackSize + 32&
      ReDim Preserve tStack(nStackSize - 1)
     End If
     Set objOut = objOut.NewNode
    End If
    Set tStack(nStackPointer).obj = objOut
    '///read and save name
    c1 = i
    c = pUnescapeStringInPlace(d2, i, m)
    With tStack(nStackPointer)
     .lps = c1
     .nLength = c
    End With
    If c > 0 Then objOut.SetName VarPtr(d2(0)) + c1 * 2&, c * 2&
    '///read attributes (if any)
    Do
     pSkipSpaces d2, i, m
     If i >= m Then Exit Function
     c = d2(i)
     Select Case c
     Case ["/"]
      '///node without any sub nodes
      i = i + 1
      If i >= m Then Exit Function
      If d2(i) <> [">"] Then Exit Function
      i = i + 1
      '///raise event and pop stack
      objOut.EndNode
      nStackPointer = nStackPointer - 1
      If nStackPointer < 0 Then Exit Do
      Set objOut = tStack(nStackPointer).obj
      '///
      Exit Do
     Case [">"]
      '///node with some data (if any)
      i = i + 1
      '///read value (if any)
      j = i
      c = pUnescapeStringInPlace(d2, i, m, ["<"], c1, c2)
      c = c - c1 - c2
      If c > 0 Then objOut.SetValue VarPtr(d2(0)) + (j + c1) * 2&, c * 2&
      '///
      Exit Do
     Case Else
      '///attributes
      '///read name
      c1 = i
      c = pUnescapeStringInPlace(d2, i, m)
      pSkipSpaces d2, i, m
      If i >= m Then Exit Function
      If d2(i) <> ["="] Then Exit Function
      'read value
      i = i + 1
      pSkipSpaces d2, i, m
      If i >= m Then Exit Function
      c3 = d2(i)
      Select Case c3
      Case ["""], ["'"]
       i = i + 1
       c2 = i
       j = pUnescapeStringInPlace(d2, i, m, c3)
       If i >= m Then Exit Function
       If d2(i) <> c3 Then Exit Function
       i = i + 1
      Case Else 'ill-formed
       c2 = i
       j = pUnescapeStringInPlace(d2, i, m)
      End Select
      '///raise event
      c3 = VarPtr(d2(0))
      objOut.NewAttribute c3 + c1 * 2&, c * 2&, c3 + c2 * 2&, j * 2&
     End Select
    Loop
   End Select
  Case Else
   'invalid character (?)
   i = i + 1
  End Select
 Loop
 '///over
End If
'///
ReadNode = True
End Function

