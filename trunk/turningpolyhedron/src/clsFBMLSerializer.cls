VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsFBMLSerializer"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'////////////////////////////////
'This file is public domain.
'////////////////////////////////

'a stupid format - FBML - Fake Binary Markup Language - reader/writer

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)
Private Declare Sub ZeroMemory Lib "kernel32.dll" Alias "RtlZeroMemory" (ByRef Destination As Any, ByVal Length As Long)

Friend Function WriteInteger(ByVal n As Long, ByVal objOut As clsTreeStorageNode, Optional ByVal nStart As Long = -1) As Boolean
If n < 0 Or n >= &H40004080 Then Exit Function
If n < &H80& Then
 objOut.AppendValueEx VarPtr(n), 1&, nStart
ElseIf n < &H4080& Then
 n = n - &H80&
 n = (n And &H3F&) Or ((n And &H3FC0&) * 4&) Or &H80&
 objOut.AppendValueEx VarPtr(n), 2&, nStart
ElseIf n < &H40004080 Then
 n = n - &H4080&
 n = (n And &H3F&) Or ((n And &H1FFFFFC0) * 4&) Or &HC0& Or ((n >= &H20000000) And &H80000000)
 objOut.AppendValueEx VarPtr(n), 4&, nStart
End If
WriteInteger = True
End Function

'internal use only
Friend Function pReadInteger(ByVal lp As Long, ByRef i As Long, ByVal nLength As Long) As Long
Dim n As Long
If i < nLength Then
 CopyMemory n, ByVal lp + i, 1&
 If n And &H80& Then
  If n And &H40& Then
   If i + 3 < nLength Then
    CopyMemory n, ByVal lp + i, 4&
    pReadInteger = ((n And &H3F&) Or ((n And &H7FFFFF00) \ 4&) Or ((n < 0&) And &H20000000)) + &H4080&
   End If
   i = i + 4
  Else
   If i + 1 < nLength Then
    CopyMemory n, ByVal lp + i, 2&
    pReadInteger = ((n And &H3F&) Or ((n And &HFF00&) \ 4&)) + &H80&
   End If
   i = i + 2
  End If
 Else
  pReadInteger = n
  i = i + 1
 End If
End If
End Function

Friend Function WriteString(ByVal lp As Long, ByVal nLength As Long, ByVal objOut As clsTreeStorageNode) As Boolean
If WriteInteger(nLength, objOut) Then
 If nLength > 0 Then objOut.AppendValueEx lp, nLength
 WriteString = True
End If
End Function

Friend Sub WriteHeader(ByVal objOut As clsTreeStorageNode)
Dim i As Long
i = &H4C4DFB '&HFB 'M' 'L' + version (0)
objOut.AppendValueEx VarPtr(i), 4&
End Sub

Friend Function SaveNodeToFile(ByVal FileName As String, ByVal obj As ITreeStorageReader, Optional ByVal bWriteHeader As Boolean = True, Optional ByVal bSaveSubNodeOnly As Boolean) As Boolean
Dim objOut As New clsTreeStorageNode
If WriteNode(obj, objOut, bWriteHeader, bSaveSubNodeOnly) = 0 Then Exit Function
SaveNodeToFile = objOut.SaveValueToFile(FileName)
End Function

Friend Function WriteNode(ByVal obj As ITreeStorageReader, ByVal objOut As clsTreeStorageNode, Optional ByVal bWriteHeader As Boolean = True, Optional ByVal bSaveSubNodeOnly As Boolean) As Long
On Error Resume Next
Dim obj1 As ITreeStorageReader
Dim lp1 As Long, lp2 As Long
Dim m1 As Long, m2 As Long
Dim idx As Long
Dim i As Long
Dim ret As Long
Static idx1 As Long
'///
If bWriteHeader Then WriteHeader objOut
'///
If Not bSaveSubNodeOnly Then
 '///name and value
 m1 = obj.GetName(lp1)
 m2 = obj.GetValue(lp2)
 idx = objOut.ValueSize
 objOut.AppendValueEx VarPtr(&H10&), 1, idx
 If Not WriteString(lp1, m1, objOut) Then Exit Function
 If Not WriteString(lp2, m2, objOut) Then Exit Function
 '///attributes
 i = 0
 Do
  i = obj.GetNextAttribute(i, lp1, m1, lp2, m2)
  If i = 0 Then Exit Do
  ret = 1
  idx = objOut.ValueSize
  objOut.AppendValueEx VarPtr(&H20&), 1, idx
  If Not WriteString(lp1, m1, objOut) Then Exit Function
  If Not WriteString(lp2, m2, objOut) Then Exit Function
 Loop
End If
'///child nodes
'TODO:non-recursive
i = 0
Do
 i = obj.GetNextNode(i, obj1)
 If i = 0 Then Exit Do
 If Not obj1 Is Nothing Then
  ret = WriteNode(obj1, objOut, False, False)
  If ret = 0 Then Exit Function
 End If
 Set obj1 = Nothing
Loop
'///
WriteNode = 2
If Not bSaveSubNodeOnly Then
 If ret >= 2 Then
  ret = ret + 1
  If ret >= &HCF& Then
   i = &HCF&
   objOut.AppendValueEx VarPtr(i), 1, idx1
   If Not WriteInteger(ret - &HCB&, objOut, idx1 + 1) Then Exit Function
   WriteNode = ret
  ElseIf ret >= &HCC& Then
   objOut.AppendValueEx VarPtr(ret), 1, idx1
   WriteNode = ret
  Else
   idx1 = objOut.ValueSize
   objOut.AppendValueEx VarPtr(&HCC&), 1
   WriteNode = &HCC&
  End If
 Else
  If ret >= 1 Then
   objOut.AppendValueEx VarPtr(&H21&), 1, idx
  Else
   objOut.AppendValueEx VarPtr(&H11&), 1, idx
  End If
 End If
End If
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
'///
Dim i As Long, j As Long
Dim c As Long, c1 As Long, c2 As Long
'///stack
Dim nStackPointer As Long
Dim nStackSize As Long
Dim tStack() As ITreeStorageBuilder
'///
If nLength > 0 Then
 If nLength < 4 Then Exit Function
 '///check header
 CopyMemory i, ByVal lp, 4&
 If i <> &H4C4DFB Then Exit Function
 '///init
 nStackSize = 32
 ReDim tStack(nStackSize - 1)
 If bLoadSubNodeOnly Then Set tStack(0) = objOut _
 Else nStackPointer = -1
 '///main loop
 i = 4
 Do While i < nLength
  c = 0
  CopyMemory c, ByVal lp + i, 1&
  i = i + 1
  Select Case c
  Case &H10, &H11 'new node
   c = c - &H10&
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
   Set tStack(nStackPointer) = objOut
   '///read name
   c1 = pReadInteger(lp, i, nLength)
   If i + c1 > nLength Then Exit Function
   If c1 > 0 Then objOut.SetName lp + i, c1
   i = i + c1
   '///read value
   c1 = pReadInteger(lp, i, nLength)
   If i + c1 > nLength Then Exit Function
   If c1 > 0 Then objOut.SetValue lp + i, c1
   i = i + c1
  Case &H20, &H21 'new attribute
   c = c - &H20&
   If nStackPointer < 0 Then Exit Function
   '///read name
   c1 = pReadInteger(lp, i, nLength)
   If i + c1 > nLength Then Exit Function
   j = i
   i = i + c1
   '///read value
   c2 = pReadInteger(lp, i, nLength)
   If i + c2 > nLength Then Exit Function
   objOut.NewAttribute lp + j, c1, lp + i, c2
   i = i + c2
  Case &HCC, &HCD, &HCE
   c = c - &HCB&
  Case &HCF
   c = pReadInteger(lp, i, nLength)
  Case Else
   Exit Do
  End Select
  '///exit node?
  If c > 0 Then '??? slow
   If nStackPointer < 0 Then Exit Function '??? slow
   For c = 1 To c
    objOut.EndNode
    nStackPointer = nStackPointer - 1
    If nStackPointer < 0 Then Exit Do
    Set objOut = tStack(nStackPointer)
   Next c
  End If
 Loop
 '///over
End If
'///
ReadNode = True
End Function
