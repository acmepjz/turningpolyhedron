VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsTheFile"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)
Private Declare Sub ZeroMemory Lib "kernel32.dll" Alias "RtlZeroMemory" (ByRef Destination As Any, ByVal Length As Long)

Private Type typeFileNode
 Size As Long
 d() As Byte
End Type

Private Type typeFileNodeArray
 Name As Long
 Count As Long
 nd() As typeFileNode
End Type

Private nds() As typeFileNodeArray, ndc As Long
Private sig As String

Private cmp As New clsLZSS

Private m_sFileName As String

Public Property Get FileName() As String
FileName = m_sFileName
End Property

Public Property Get NodeCount(ByVal Index As Long) As Long
NodeCount = nds(Index).Count
End Property

Public Sub AddNode(ByVal Index As Long)
With nds(Index)
 .Count = .Count + 1
 ReDim Preserve .nd(1 To .Count)
End With
End Sub

Public Sub RemoveNode(ByVal Index As Long, ByVal Index2 As Long)
Dim i As Long
With nds(Index)
 If .Count <= 1 Then
  .Count = 0
  Erase .nd
 Else
  .Count = .Count - 1
  For i = Index2 To .Count
   .nd(i) = .nd(i + 1)
  Next i
  ReDim Preserve .nd(1 To .Count)
 End If
End With
End Sub

Public Sub ClearNode(ByVal Index As Long)
With nds(Index)
 .Count = 0
 Erase .nd
End With
End Sub

Public Property Get NodeSize(ByVal Index As Long, ByVal Index2 As Long) As Long
NodeSize = nds(Index).nd(Index2).Size
End Property

Public Property Let NodeSize(ByVal Index As Long, ByVal Index2 As Long, ByVal m As Long)
With nds(Index).nd(Index2)
 .Size = m
 If m > 0 Then
  ReDim .d(1 To m)
 Else
  Erase .d
 End If
End With
End Property

Public Sub GetNodeData(ByVal Index As Long, ByVal Index2 As Long, b() As Byte)
Dim m As Long
With nds(Index).nd(Index2)
 m = .Size
 If m > 0 Then
  ReDim b(1 To m)
  CopyMemory b(1), .d(1), m
 Else
  Erase b
 End If
End With
End Sub

Public Sub SaveNodeDataToFile(ByVal Index As Long, ByVal Index2 As Long, ByVal FileName As String)
With nds(Index).nd(Index2)
 Open FileName For Output As #1
 Close
 If .Size > 0 Then
  Open FileName For Binary As #1
  Put #1, 1, .d
  Close
 End If
End With
End Sub

Public Sub SetNodeData(ByVal Index As Long, ByVal Index2 As Long, b() As Byte)
On Error Resume Next
Dim m As Long, l As Long
Err.Clear
l = LBound(b)
m = UBound(b) - l + 1
If Err <> 0 Then m = 0
With nds(Index).nd(Index2)
 .Size = m
 If m > 0 Then
  ReDim .d(1 To m)
  CopyMemory .d(1), b(l), m
 Else
  Erase .d
 End If
End With
End Sub

Public Sub LoadNodeDataFromFile(ByVal Index As Long, ByVal Index2 As Long, ByVal FileName As String)
With nds(Index).nd(Index2)
 Open FileName For Binary As #1
 .Size = LOF(1)
 If .Size > 0 Then
  ReDim .d(1 To .Size)
  Get #1, 1, .d
 Else
  Erase .d
 End If
 Close
End With
End Sub

Public Sub GetNodeDataEx(ByVal Index As Long, ByVal Index2 As Long, ByVal lp As Long)
Dim m As Long
With nds(Index).nd(Index2)
 m = .Size
 If m > 0 Then
  CopyMemory ByVal lp, .d(1), m
 End If
End With
End Sub

Public Sub SetNodeDataEx(ByVal Index As Long, ByVal Index2 As Long, ByVal m As Long, ByVal lp As Long)
With nds(Index).nd(Index2)
 .Size = m
 If m > 0 Then
  ReDim .d(1 To m)
  CopyMemory .d(1), ByVal lp, m
 Else
  Erase .d
 End If
End With
End Sub

Public Sub ClearNodeData(ByVal Index As Long, ByVal Index2 As Long)
With nds(Index).nd(Index2)
 .Size = 0
 Erase .d
End With
End Sub

Public Sub EraseNodeData(ByVal Index As Long, ByVal Index2 As Long)
With nds(Index).nd(Index2)
 If .Size > 0 Then ZeroMemory .d(1), .Size
End With
End Sub

Public Property Get NodeArrayCount() As Long
NodeArrayCount = ndc
End Property

Public Sub AddNodeArray(Optional ByVal Name As Variant)
ndc = ndc + 1
ReDim Preserve nds(1 To ndc)
nds(ndc).Name = pVariant(Name)
End Sub

Public Property Get NodeArrayName(ByVal Index As Long) As String
Dim s As String, b() As Byte, i As Long
ReDim b(1 To 4)
CopyMemory b(1), nds(Index).Name, 4&
s = StrConv(b, vbUnicode)
i = InStr(1, s, vbNullChar)
If i > 0 Then s = Left(s, i - 1)
NodeArrayName = s
End Property

Public Property Let NodeArrayName(ByVal Index As Long, ByVal s As String)
nds(Index).Name = pVariant(s)
End Property

Public Property Get NodeArrayNameValue(ByVal Index As Long) As Long
NodeArrayNameValue = nds(Index).Name
End Property

Public Property Let NodeArrayNameValue(ByVal Index As Long, ByVal n As Long)
nds(Index).Name = n
End Property

Public Sub SetNodeArrayName(ByVal Index As Long, ByVal Name As Variant)
nds(Index).Name = pVariant(Name)
End Sub

Public Function FindNodeArray(ByVal Name As Variant, Optional ByVal Start As Long) As Long
Dim i As Long, n As Long
If Start = 0 Then Start = 1
n = pVariant(Name)
For i = Start To ndc
 If nds(i).Name = n Then
  FindNodeArray = i
  Exit Function
 End If
Next i
End Function

Public Sub RemoveNodeArray(ByVal Index As Long)
Dim i As Long
If ndc <= 1 Then
 ndc = 0
 Erase nds
Else
 ndc = ndc - 1
 For i = Index To ndc
  nds(i) = nds(i + 1)
 Next i
 ReDim Preserve nds(1 To ndc)
End If
End Sub

Private Function pVariant(ByVal v As Variant) As Long
Dim ret As Long, s As String
If IsMissing(v) Then
 ret = 0
ElseIf VarType(v) = vbString Then
 s = StrConv(v, vbFromUnicode) + vbNullChar + vbNullChar
 CopyMemory ret, ByVal StrPtr(s), 4&
ElseIf VarType(v) And vbArray Then
 CopyMemory ret, v(LBound(v)), 4&
Else
 ret = v
End If
pVariant = ret
End Function

Public Property Get Signature() As String
Signature = sig
End Property

Public Property Let Signature(ByVal s As String)
sig = s
End Property

Public Function LoadFile(ByVal fn As String, Optional ByVal Signature As String) As Boolean
On Error GoTo a
Dim i As Long, j As Long, m As Long, lp As Long
Dim b() As Byte, b2() As Byte
Clear
Open fn For Binary As #1
ReDim b(7)
Get #1, 1, b
sig = StrConv(b, vbUnicode)
i = InStr(1, sig, vbNullChar)
If i > 0 Then sig = Left(sig, i - 1)
If Signature <> "" Then
 If StrComp(Signature, sig) Then 'err!
  sig = ""
  Close
  Exit Function
 End If
End If
Get #1, 9, m
If m < 0 Then
 j = -m
 m = LOF(1) - 12
 ReDim b(1 To m)
 Get #1, 13, b
 cmp.DecompressData b, b2, j
 pLoadData b2
Else
 m = LOF(1) - 8
 ReDim b(1 To m)
 Get #1, 9, b
 pLoadData b
End If
m_sFileName = fn
LoadFile = True
a:
Close
End Function

Public Function LoadData(d() As Byte, Optional ByVal Signature As String) As Boolean
Dim i As Long, j As Long, m As Long, lp As Long
Dim b() As Byte, b2() As Byte
Clear
lp = LBound(d)
ReDim b(7)
CopyMemory b(0), d(lp), 8&
sig = StrConv(b, vbUnicode)
i = InStr(1, sig, vbNullChar)
If i > 0 Then sig = Left(sig, i - 1)
If Signature <> "" Then
 If StrComp(Signature, sig) Then 'err!
  sig = ""
  Exit Function
 End If
End If
CopyMemory m, d(lp + 8), 4&
If m < 0 Then
 j = -m
 m = UBound(d) - lp + 1
 m = m - 12
 ReDim b(1 To m)
 CopyMemory b(1), d(lp + 12), m
 cmp.DecompressData b, b2, j
 pLoadData b2
Else
 m = UBound(d) - lp + 1
 m = m - 8
 ReDim b(1 To m)
 CopyMemory b(1), d(lp + 8), m
 pLoadData b
End If
LoadData = True
End Function

Private Sub pLoadData(b() As Byte)
Dim i As Long, j As Long, m As Long, lp As Long
CopyMemory ndc, b(1), 4&
If ndc > 0 Then
 ReDim nds(1 To ndc)
 lp = 5
 For i = 1 To ndc
  With nds(i)
   CopyMemory .Name, b(lp), 4& ' 8&
   CopyMemory .Count, b(lp + 4), 4&
   lp = lp + 8
   If .Count > 0 Then
    ReDim .nd(1 To .Count)
    For j = 1 To .Count
     With .nd(j)
      CopyMemory .Size, b(lp), 4&
      If .Size > 0 Then
       ReDim .d(1 To .Size)
       CopyMemory .d(1), b(lp + 4), .Size
      End If
      lp = lp + 4 + .Size
     End With
    Next j
   End If
  End With
 Next i
End If
End Sub

Public Function SaveFile(Optional ByVal fn As String, Optional ByVal IsCompress As Boolean = True) As Boolean
On Error GoTo a
Dim i As Long, j As Long, m As Long
Dim b() As Byte, b2() As Byte, s As String
If fn = "" Then fn = m_sFileName
If fn = "" Then Exit Function
Open fn For Output As #1
Close
Open fn For Binary As #1
s = StrConv(sig, vbFromUnicode)
ReDim b(1 To 8)
m = LenB(s)
If m > 8 Then m = 8
If m > 0 Then CopyMemory b(1), ByVal StrPtr(s), m
Put #1, 1, b
m = pSaveData(b)
If IsCompress Then
 m = -m
 Put #1, 9, m
 m = cmp.CompressData(b, b2)
 Put #1, 13, b2
Else
 Put #1, 9, b
End If
m_sFileName = fn
SaveFile = True
a:
Close
End Function

Public Function SaveData(d() As Byte, Optional ByVal IsCompress As Boolean = True) As Long
Dim i As Long, j As Long, m As Long
Dim b() As Byte, b2() As Byte, s As String
m = pSaveData(b)
If IsCompress Then
 m = -m
 Put #1, 9, m
 m = cmp.CompressData(b, b2)
 SaveData = m + 12
 ReDim d(1 To m + 12)
 CopyMemory d(13), b2(1), m
Else
 SaveData = m + 8
 ReDim d(1 To m + 8)
 CopyMemory d(9), b(1), m
End If
s = StrConv(sig, vbFromUnicode)
ReDim b(1 To 8)
m = LenB(s)
If m > 8 Then m = 8
If m > 0 Then CopyMemory b(1), ByVal StrPtr(s), m
CopyMemory d(1), b(1), 8&
End Function

Private Function pSaveData(b() As Byte) As Long
Dim i As Long, j As Long, m As Long, lp As Long
'calc max
m = 4 + ndc * 8&
For i = 1 To ndc
 With nds(i)
  m = m + .Count * 4&
  For j = 1 To .Count
   m = m + .nd(j).Size
  Next j
 End With
Next i
pSaveData = m
ReDim b(1 To m)
'save
CopyMemory b(1), ndc, 4&
lp = 5
For i = 1 To ndc
 With nds(i)
  CopyMemory b(lp), .Name, 4& '8&
  CopyMemory b(lp + 4), .Count, 4&
  lp = lp + 8
  For j = 1 To .Count
   With .nd(j)
    CopyMemory b(lp), .Size, 4&
    If .Size > 0 Then
     CopyMemory b(lp + 4), .d(1), .Size
    End If
    lp = lp + 4 + .Size
   End With
  Next j
 End With
Next i
End Function

Public Sub Clear()
Erase nds
ndc = 0
sig = ""
m_sFileName = ""
End Sub

Private Sub Class_Terminate()
Clear
End Sub
