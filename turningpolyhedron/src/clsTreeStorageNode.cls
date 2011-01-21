VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsTreeStorageNode"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)
Private Declare Sub ZeroMemory Lib "kernel32.dll" Alias "RtlZeroMemory" (ByRef Destination As Any, ByVal Length As Long)

'////////////////////////////////
'This file is public domain.
'////////////////////////////////

Private m_bName() As Byte 'UCS-2,0-based
Private m_nNameSize As Long
Private m_nNameSizeMax As Long
Private m_bValue() As Byte 'UCS-2,0-based
Private m_nValueSize As Long
Private m_nValueSizeMax As Long

Private Type typeTreeStorageSubNode
 '///
 nType As Long
 '(-1=unused) ?? not implemented
 '0=attribute
 '1=subnode
 '2=subnode(array mode) (???) not implemented
 objSubNode As clsTreeStorageNode
 '///
 bName() As Byte 'UCS-2,0-based
 nNameSize As Long
 nNameSizeMax As Long
 bValue() As Byte 'UCS-2,0-based
 nValueSize As Long
 nValueSizeMax As Long
End Type

Private m_tNodes() As typeTreeStorageSubNode '1-based
Private m_nNodeCount As Long

Implements ITreeStorageBuilder
Implements ITreeStorageReader

Friend Sub Destroy()
Erase m_bName, m_bValue, m_tNodes
m_nNameSize = 0
m_nNameSizeMax = 0
m_nValueSize = 0
m_nValueSizeMax = 0
m_nNodeCount = 0
End Sub

'////////////////

Friend Property Get NameSize() As Long
NameSize = m_nNameSize
End Property

Friend Property Let NameSize(ByVal n As Long)
If n <= 0 Then
 Erase m_bName
 m_nNameSize = 0
 m_nNameSizeMax = 0
Else
 m_nNameSize = n
 If n > m_nNameSizeMax Then
  m_nNameSizeMax = n
  ReDim Preserve m_bName(n - 1)
 End If
End If
End Property

'return value=old size
Friend Function ExpandNameSizeEx(ByVal nExpandCount As Long, ByVal nMinReservedCount As Long, ByVal nMaxReservedCount As Long) As Long
ExpandNameSizeEx = m_nNameSize
m_nNameSize = m_nNameSize + nExpandCount
If m_nNameSize + nMinReservedCount > m_nNameSizeMax Then
 m_nNameSizeMax = m_nNameSize + nMinReservedCount + nMaxReservedCount 'nMinReservedCount?
 ReDim Preserve m_bName(m_nNameSizeMax - 1)
End If
End Function

Friend Property Get NamePointer() As Long
If m_nNameSizeMax > 0 Then NamePointer = VarPtr(m_bName(0))
End Property

Friend Sub GetName(b() As Byte)
b = m_bName
End Sub

Friend Function GetNameEx(ByVal lp As Long, ByVal nLength As Long, Optional ByVal nStart As Long) As Long
If nStart >= 0 And nStart < m_nNameSize Then
 If nStart + nLength > m_nNameSize Then nLength = m_nNameSize - nStart
 If nLength > 0 Then
  CopyMemory ByVal lp, m_bName(nStart), nLength
  GetNameEx = nLength
 End If
End If
End Function

Friend Function GetNameAsString() As String
GetNameAsString = LeftB(m_bName, m_nNameSize)
End Function

Friend Sub SetName(b() As Byte)
On Error Resume Next
Dim lps As Long, lpe As Long
Err.Clear
lps = LBound(b)
lpe = UBound(b)
If lps > lpe Or Err.Number <> 0 Then
 Erase m_bName
 m_nNameSize = 0
 m_nNameSizeMax = 0
Else
 lpe = lpe - lps + 1
 m_nNameSize = lpe
 If lpe > m_nNameSizeMax Then
  m_nNameSizeMax = lpe
  ReDim Preserve m_bName(lpe - 1)
 End If
 CopyMemory m_bName(0), b(lps), lpe
End If
End Sub

Friend Function SetNameEx(ByVal lp As Long, ByVal nLength As Long, Optional ByVal nStart As Long, Optional ByVal bTruncate As Boolean = True, Optional ByVal bExpand As Boolean = True) As Long
Dim m As Long
If nStart >= 0 Then
 m = nStart + nLength
 If m > m_nNameSize Then
  If bExpand Then
   m_nNameSize = m
   If m > m_nNameSizeMax Then
    m_nNameSizeMax = m
    ReDim Preserve m_bName(m - 1)
   End If
  Else
   nLength = m_nNameSize - nStart
  End If
 ElseIf m < m_nNameSize And bTruncate Then
  m_nNameSize = m
 End If
 If nLength > 0 Then
  CopyMemory m_bName(nStart), ByVal lp, nLength
  SetNameEx = nLength
 End If
End If
End Function

Friend Sub AppendNameEx(ByVal lp As Long, ByVal nLength As Long, Optional ByVal nStart As Long = -1)
Dim m As Long
If nStart < 0 Then nStart = m_nNameSize
m = nStart + nLength
If m > m_nNameSize Then
 m_nNameSize = m
 If m > m_nNameSizeMax Then
  m = m + &H40000
  m_nNameSizeMax = m
  ReDim Preserve m_bName(m - 1)
 End If
End If
If nLength > 0 Then CopyMemory m_bName(nStart), ByVal lp, nLength
End Sub

Friend Sub SetNameFromString(ByVal s As String)
On Error Resume Next
m_bName = s
Err.Clear
m_nNameSize = UBound(m_bName) + 1
If m_nNameSize < 0 Or Err.Number <> 0 Then m_nNameSize = 0
m_nNameSizeMax = m_nNameSize
End Sub

'////////////////

Friend Property Get ValueSize() As Long
ValueSize = m_nValueSize
End Property

Friend Property Let ValueSize(ByVal n As Long)
If n <= 0 Then
 Erase m_bValue
 m_nValueSize = 0
 m_nValueSizeMax = 0
Else
 m_nValueSize = n
 If n > m_nValueSizeMax Then
  m_nValueSizeMax = n
  ReDim Preserve m_bValue(n - 1)
 End If
End If
End Property

'return value=old size
Friend Function ExpandValueSizeEx(ByVal nExpandCount As Long, ByVal nMinReservedCount As Long, ByVal nMaxReservedCount As Long) As Long
ExpandValueSizeEx = m_nValueSize
m_nValueSize = m_nValueSize + nExpandCount
If m_nValueSize + nMinReservedCount > m_nValueSizeMax Then
 m_nValueSizeMax = m_nValueSize + nMinReservedCount + nMaxReservedCount 'nMinReservedCount?
 ReDim Preserve m_bValue(m_nValueSizeMax - 1)
End If
End Function

Friend Property Get ValuePointer() As Long
If m_nValueSizeMax > 0 Then ValuePointer = VarPtr(m_bValue(0))
End Property

Friend Sub GetValue(b() As Byte)
b = m_bValue
End Sub

Friend Function GetValueEx(ByVal lp As Long, ByVal nLength As Long, Optional ByVal nStart As Long) As Long
If nStart >= 0 And nStart < m_nValueSize Then
 If nStart + nLength > m_nValueSize Then nLength = m_nValueSize - nStart
 If nLength > 0 Then
  CopyMemory ByVal lp, m_bValue(nStart), nLength
  GetValueEx = nLength
 End If
End If
End Function

Friend Function GetValueAsString() As String
GetValueAsString = LeftB(m_bValue, m_nValueSize)
End Function

Friend Sub SetValue(b() As Byte)
On Error Resume Next
Dim lps As Long, lpe As Long
Err.Clear
lps = LBound(b)
lpe = UBound(b)
If lps > lpe Or Err.Number <> 0 Then
 Erase m_bValue
 m_nValueSize = 0
 m_nValueSizeMax = 0
Else
 lpe = lpe - lps + 1
 m_nValueSize = lpe
 If lpe > m_nValueSizeMax Then
  m_nValueSizeMax = lpe
  ReDim Preserve m_bValue(lpe - 1)
 End If
 CopyMemory m_bValue(0), b(lps), lpe
End If
End Sub

Friend Function SetValueEx(ByVal lp As Long, ByVal nLength As Long, Optional ByVal nStart As Long, Optional ByVal bTruncate As Boolean = True, Optional ByVal bExpand As Boolean = True) As Long
Dim m As Long
If nStart >= 0 Then
 m = nStart + nLength
 If m > m_nValueSize Then
  If bExpand Then
   m_nValueSize = m
   If m > m_nValueSizeMax Then
    m_nValueSizeMax = m
    ReDim Preserve m_bValue(m - 1)
   End If
  Else
   nLength = m_nValueSize - nStart
  End If
 ElseIf m < m_nValueSize And bTruncate Then
  m_nValueSize = m
 End If
 If nLength > 0 Then
  CopyMemory m_bValue(nStart), ByVal lp, nLength
  SetValueEx = nLength
 End If
End If
End Function

Friend Sub AppendValueEx(ByVal lp As Long, ByVal nLength As Long, Optional ByVal nStart As Long = -1)
Dim m As Long
If nStart < 0 Then nStart = m_nValueSize
m = nStart + nLength
If m > m_nValueSize Then
 m_nValueSize = m
 If m > m_nValueSizeMax Then
  m = m + &H40000
  m_nValueSizeMax = m
  ReDim Preserve m_bValue(m - 1)
 End If
End If
If nLength > 0 Then CopyMemory m_bValue(nStart), ByVal lp, nLength
End Sub

Friend Sub SetValueFromString(ByVal s As String)
On Error Resume Next
m_bValue = s
Err.Clear
m_nValueSize = UBound(m_bValue) + 1
If m_nValueSize < 0 Or Err.Number <> 0 Then m_nValueSize = 0
m_nValueSizeMax = m_nValueSize
End Sub

'////////////////

Friend Property Get SubNodeNameSize(ByVal nIndex As Long) As Long
SubNodeNameSize = m_tNodes(nIndex).nNameSize
End Property

Friend Property Let SubNodeNameSize(ByVal nIndex As Long, ByVal n As Long)
If n <= 0 Then
 Erase m_tNodes(nIndex).bName
 m_tNodes(nIndex).nNameSize = 0
 m_tNodes(nIndex).nNameSizeMax = 0
Else
 m_tNodes(nIndex).nNameSize = n
 If n > m_tNodes(nIndex).nNameSizeMax Then
  m_tNodes(nIndex).nNameSizeMax = n
  ReDim Preserve m_tNodes(nIndex).bName(n - 1)
 End If
End If
End Property

Friend Property Get SubNodeNamePointer(ByVal nIndex As Long) As Long
If m_tNodes(nIndex).nNameSizeMax > 0 Then SubNodeNamePointer = VarPtr(m_tNodes(nIndex).bName(0))
End Property

Friend Sub GetSubNodeName(ByVal nIndex As Long, b() As Byte)
b = m_tNodes(nIndex).bName
End Sub

Friend Function GetSubNodeNameEx(ByVal nIndex As Long, ByVal lp As Long, ByVal nLength As Long, Optional ByVal nStart As Long) As Long
If nStart >= 0 And nStart < m_tNodes(nIndex).nNameSize Then
 If nStart + nLength > m_tNodes(nIndex).nNameSize Then nLength = m_tNodes(nIndex).nNameSize - nStart
 If nLength > 0 Then
  CopyMemory ByVal lp, m_tNodes(nIndex).bName(nStart), nLength
  GetSubNodeNameEx = nLength
 End If
End If
End Function

Friend Function GetSubNodeNameAsString(ByVal nIndex As Long) As String
GetSubNodeNameAsString = LeftB(m_tNodes(nIndex).bName, m_tNodes(nIndex).nNameSize)
End Function

Friend Sub SetSubNodeName(ByVal nIndex As Long, b() As Byte)
On Error Resume Next
Dim lps As Long, lpe As Long
Err.Clear
lps = LBound(b)
lpe = UBound(b)
If lps > lpe Or Err.Number <> 0 Then
 Erase m_tNodes(nIndex).bName
 m_tNodes(nIndex).nNameSize = 0
 m_tNodes(nIndex).nNameSizeMax = 0
Else
 lpe = lpe - lps + 1
 m_tNodes(nIndex).nNameSize = lpe
 If lpe > m_tNodes(nIndex).nNameSizeMax Then
  m_tNodes(nIndex).nNameSizeMax = lpe
  ReDim Preserve m_tNodes(nIndex).bName(lpe - 1)
 End If
 CopyMemory m_tNodes(nIndex).bName(0), b(lps), lpe
End If
End Sub

Friend Function SetSubNodeNameEx(ByVal nIndex As Long, ByVal lp As Long, ByVal nLength As Long, Optional ByVal nStart As Long, Optional ByVal bTruncate As Boolean = True, Optional ByVal bExpand As Boolean = True) As Long
Dim m As Long
If nStart >= 0 Then
 m = nStart + nLength
 If m > m_tNodes(nIndex).nNameSize Then
  If bExpand Then
   m_tNodes(nIndex).nNameSize = m
   If m > m_tNodes(nIndex).nNameSizeMax Then
    m_tNodes(nIndex).nNameSizeMax = m
    ReDim Preserve m_tNodes(nIndex).bName(m - 1)
   End If
  Else
   nLength = m_tNodes(nIndex).nNameSize - nStart
  End If
 ElseIf m < m_tNodes(nIndex).nNameSize And bTruncate Then
  m_tNodes(nIndex).nNameSize = m
 End If
 If nLength > 0 Then
  CopyMemory m_tNodes(nIndex).bName(nStart), ByVal lp, nLength
  SetSubNodeNameEx = nLength
 End If
End If
End Function

Friend Sub AppendSubNodeNameEx(ByVal nIndex As Long, ByVal lp As Long, ByVal nLength As Long, Optional ByVal nStart As Long = -1)
Dim m As Long
If nStart < 0 Then nStart = m_tNodes(nIndex).nNameSize
m = nStart + nLength
If m > m_tNodes(nIndex).nNameSize Then
 m_tNodes(nIndex).nNameSize = m
 If m > m_tNodes(nIndex).nNameSizeMax Then
  m = m + &H40000
  m_tNodes(nIndex).nNameSizeMax = m
  ReDim Preserve m_tNodes(nIndex).bName(m - 1)
 End If
End If
If nLength > 0 Then CopyMemory m_tNodes(nIndex).bName(nStart), ByVal lp, nLength
End Sub

Friend Sub SetSubNodeNameFromString(ByVal nIndex As Long, ByVal s As String)
On Error Resume Next
m_tNodes(nIndex).bName = s
Err.Clear
m_tNodes(nIndex).nNameSize = UBound(m_tNodes(nIndex).bName) + 1
If m_tNodes(nIndex).nNameSize < 0 Or Err.Number <> 0 Then m_tNodes(nIndex).nNameSize = 0
m_tNodes(nIndex).nNameSizeMax = m_tNodes(nIndex).nNameSize
End Sub

'////////////////

Friend Property Get SubNodeValueSize(ByVal nIndex As Long) As Long
SubNodeValueSize = m_tNodes(nIndex).nValueSize
End Property

Friend Property Let SubNodeValueSize(ByVal nIndex As Long, ByVal n As Long)
If n <= 0 Then
 Erase m_tNodes(nIndex).bValue
 m_tNodes(nIndex).nValueSize = 0
 m_tNodes(nIndex).nValueSizeMax = 0
Else
 m_tNodes(nIndex).nValueSize = n
 If n > m_tNodes(nIndex).nValueSizeMax Then
  m_tNodes(nIndex).nValueSizeMax = n
  ReDim Preserve m_tNodes(nIndex).bValue(n - 1)
 End If
End If
End Property

Friend Property Get SubNodeValuePointer(ByVal nIndex As Long) As Long
If m_tNodes(nIndex).nValueSizeMax > 0 Then SubNodeValuePointer = VarPtr(m_tNodes(nIndex).bValue(0))
End Property

Friend Sub GetSubNodeValue(ByVal nIndex As Long, b() As Byte)
b = m_tNodes(nIndex).bValue
End Sub

Friend Function GetSubNodeValueEx(ByVal nIndex As Long, ByVal lp As Long, ByVal nLength As Long, Optional ByVal nStart As Long) As Long
If nStart >= 0 And nStart < m_tNodes(nIndex).nValueSize Then
 If nStart + nLength > m_tNodes(nIndex).nValueSize Then nLength = m_tNodes(nIndex).nValueSize - nStart
 If nLength > 0 Then
  CopyMemory ByVal lp, m_tNodes(nIndex).bValue(nStart), nLength
  GetSubNodeValueEx = nLength
 End If
End If
End Function

Friend Function GetSubNodeValueAsString(ByVal nIndex As Long) As String
GetSubNodeValueAsString = LeftB(m_tNodes(nIndex).bValue, m_tNodes(nIndex).nValueSize)
End Function

Friend Sub SetSubNodeValue(ByVal nIndex As Long, b() As Byte)
On Error Resume Next
Dim lps As Long, lpe As Long
Err.Clear
lps = LBound(b)
lpe = UBound(b)
If lps > lpe Or Err.Number <> 0 Then
 Erase m_tNodes(nIndex).bValue
 m_tNodes(nIndex).nValueSize = 0
 m_tNodes(nIndex).nValueSizeMax = 0
Else
 lpe = lpe - lps + 1
 m_tNodes(nIndex).nValueSize = lpe
 If lpe > m_tNodes(nIndex).nValueSizeMax Then
  m_tNodes(nIndex).nValueSizeMax = lpe
  ReDim Preserve m_tNodes(nIndex).bValue(lpe - 1)
 End If
 CopyMemory m_tNodes(nIndex).bValue(0), b(lps), lpe
End If
End Sub

Friend Function SetSubNodeValueEx(ByVal nIndex As Long, ByVal lp As Long, ByVal nLength As Long, Optional ByVal nStart As Long, Optional ByVal bTruncate As Boolean = True, Optional ByVal bExpand As Boolean = True) As Long
Dim m As Long
If nStart >= 0 Then
 m = nStart + nLength
 If m > m_tNodes(nIndex).nValueSize Then
  If bExpand Then
   m_tNodes(nIndex).nValueSize = m
   If m > m_tNodes(nIndex).nValueSizeMax Then
    m_tNodes(nIndex).nValueSizeMax = m
    ReDim Preserve m_tNodes(nIndex).bValue(m - 1)
   End If
  Else
   nLength = m_tNodes(nIndex).nValueSize - nStart
  End If
 ElseIf m < m_tNodes(nIndex).nValueSize And bTruncate Then
  m_tNodes(nIndex).nValueSize = m
 End If
 If nLength > 0 Then
  CopyMemory m_tNodes(nIndex).bValue(nStart), ByVal lp, nLength
  SetSubNodeValueEx = nLength
 End If
End If
End Function

Friend Sub AppendSubNodeValueEx(ByVal nIndex As Long, ByVal lp As Long, ByVal nLength As Long, Optional ByVal nStart As Long = -1)
Dim m As Long
If nStart < 0 Then nStart = m_tNodes(nIndex).nValueSize
m = nStart + nLength
If m > m_tNodes(nIndex).nValueSize Then
 m_tNodes(nIndex).nValueSize = m
 If m > m_tNodes(nIndex).nValueSizeMax Then
  m = m + &H40000
  m_tNodes(nIndex).nValueSizeMax = m
  ReDim Preserve m_tNodes(nIndex).bValue(m - 1)
 End If
End If
If nLength > 0 Then CopyMemory m_tNodes(nIndex).bValue(nStart), ByVal lp, nLength
End Sub

Friend Sub SetSubNodeValueFromString(ByVal nIndex As Long, ByVal s As String)
On Error Resume Next
m_tNodes(nIndex).bValue = s
Err.Clear
m_tNodes(nIndex).nValueSize = UBound(m_tNodes(nIndex).bValue) + 1
If m_tNodes(nIndex).nValueSize < 0 Or Err.Number <> 0 Then m_tNodes(nIndex).nValueSize = 0
m_tNodes(nIndex).nValueSizeMax = m_tNodes(nIndex).nValueSize
End Sub

'////////////////

Friend Sub DestroySubNodes()
Erase m_tNodes
m_nNodeCount = 0
End Sub

Friend Property Get SubNodeCount() As Long
SubNodeCount = m_nNodeCount
End Property

Friend Property Get SubNodeType(ByVal nIndex As Long) As Long
SubNodeType = m_tNodes(nIndex).nType
End Property

Friend Property Let SubNodeType(ByVal nIndex As Long, ByVal n As Long)
m_tNodes(nIndex).nType = n
End Property

Friend Property Get SubNodeObject(ByVal nIndex As Long) As clsTreeStorageNode
Set SubNodeObject = m_tNodes(nIndex).objSubNode
End Property

Friend Property Set SubNodeObject(ByVal nIndex As Long, ByVal obj As clsTreeStorageNode)
Set m_tNodes(nIndex).objSubNode = obj
End Property

Friend Function AddSubNode(Optional ByVal nType As Long, Optional ByVal obj As clsTreeStorageNode, Optional ByVal sName As String, Optional ByVal sValue As String) As Long
On Error Resume Next
m_nNodeCount = m_nNodeCount + 1
ReDim Preserve m_tNodes(1 To m_nNodeCount)
With m_tNodes(m_nNodeCount)
 .nType = nType
 Set .objSubNode = obj
 '///
 Err.Clear
 .bName = sName
 .nNameSize = UBound(.bName) + 1
 If .nNameSize < 0 Or Err.Number <> 0 Then .nNameSize = 0
 .nNameSizeMax = .nNameSize
 '///
 Err.Clear
 .bValue = sValue
 .nValueSize = UBound(.bValue) + 1
 If .nValueSize < 0 Or Err.Number <> 0 Then .nValueSize = 0
 .nValueSizeMax = .nValueSize
 '///
End With
AddSubNode = m_nNodeCount
End Function

'ERR?
Friend Sub RemoveSubNode(ByVal nIndex As Long)
Dim lp As Long, m As Long
If nIndex > 0 And nIndex < m_nNodeCount Then
 lp = VarPtr(m_tNodes(1))
 m = VarPtr(m_tNodes(2)) - lp
 '///
 With m_tNodes(nIndex)
  Erase .bName, .bValue
  Set .objSubNode = Nothing
 End With
 '///dirty code
 CopyMemory ByVal lp + (nIndex - 1) * m, ByVal lp + nIndex * m, (m_nNodeCount - nIndex) * m
 ZeroMemory ByVal lp + (m_nNodeCount - 1) * m, m
 '///
 m_nNodeCount = m_nNodeCount - 1
 ReDim Preserve m_tNodes(1 To m_nNodeCount)
ElseIf nIndex = m_nNodeCount Then
 If nIndex > 0 Then
  m_nNodeCount = m_nNodeCount - 1
  ReDim Preserve m_tNodes(1 To m_nNodeCount)
 Else
  Erase m_tNodes
  m_nNodeCount = 0
 End If
End If
End Sub

Friend Function FindSubNodeByName(ByVal sName As String) As Long
Dim i As Long
For i = 1 To m_nNodeCount
 If CStr(m_tNodes(i).bName) = sName Then
  FindSubNodeByName = i
  Exit Function
 End If
Next i
End Function

Friend Function GetSubNodeValueAsStringByName(ByVal sName As String) As String
Dim i As Long
For i = 1 To m_nNodeCount
 If CStr(m_tNodes(i).bName) = sName Then
  GetSubNodeValueAsStringByName = LeftB(m_tNodes(i).bValue, m_tNodes(i).nValueSize)
  Exit Function
 End If
Next i
End Function

Friend Sub SetSubNodeValueFromStringByName(ByVal sName As String, ByVal sValue As String)
On Error Resume Next
Dim i As Long
For i = 1 To m_nNodeCount
 If CStr(m_tNodes(i).bName) = sName Then
  m_tNodes(i).bValue = sValue
  Err.Clear
  m_tNodes(i).nValueSize = UBound(m_tNodes(i).bValue) + 1
  If m_tNodes(i).nValueSize < 0 Or Err.Number <> 0 Then m_tNodes(i).nValueSize = 0
  m_tNodes(i).nValueSizeMax = m_tNodes(i).nValueSize
  Exit Sub
 End If
Next i
End Sub

Friend Function GetSubNodeObjectByName(ByVal sName As String) As clsTreeStorageNode
Dim i As Long
For i = 1 To m_nNodeCount
 If Not m_tNodes(i).objSubNode Is Nothing Then
  If m_tNodes(i).objSubNode.GetNameAsString = sName Then
   Set GetSubNodeObjectByName = m_tNodes(i).objSubNode
   Exit Function
  End If
 End If
Next i
End Function

Friend Function SaveNameToFile(ByVal FileName As String) As Boolean
On Error GoTo a
Open FileName For Output As #1
Close
If m_nNameSize > 0 Then
 If m_nNameSizeMax > m_nNameSize Then
  m_nNameSizeMax = m_nNameSize
  ReDim Preserve m_bName(m_nNameSize - 1)
 End If
 Open FileName For Binary As #1
 Put #1, 1, m_bName
 Close
 SaveNameToFile = True
End If
a:
Close
End Function

Friend Function SaveValueToFile(ByVal FileName As String) As Boolean
On Error GoTo a
Open FileName For Output As #1
Close
If m_nValueSize > 0 Then
 If m_nValueSizeMax > m_nValueSize Then
  m_nValueSizeMax = m_nValueSize
  ReDim Preserve m_bValue(m_nValueSize - 1)
 End If
 Open FileName For Binary As #1
 Put #1, 1, m_bValue
 Close
 SaveValueToFile = True
End If
a:
Close
End Function

Private Sub ITreeStorageBuilder_EndNode()
'do nothing
End Sub

Private Sub ITreeStorageBuilder_NewAttribute(ByVal lpName As Long, ByVal nNameLength As Long, ByVal lpValue As Long, ByVal nValueLength As Long)
m_nNodeCount = m_nNodeCount + 1
ReDim Preserve m_tNodes(1 To m_nNodeCount)
With m_tNodes(m_nNodeCount)
 .nType = 0
 If nNameLength > 0 Then
  ReDim .bName(nNameLength - 1)
  CopyMemory .bName(0), ByVal lpName, nNameLength
  .nNameSize = nNameLength
  .nNameSizeMax = nNameLength
 End If
 If nValueLength > 0 Then
  ReDim .bValue(nValueLength - 1)
  CopyMemory .bValue(0), ByVal lpValue, nValueLength
  .nValueSize = nValueLength
  .nValueSizeMax = nValueLength
 End If
End With
End Sub

Private Function ITreeStorageBuilder_NewNode() As ITreeStorageBuilder
Dim obj As clsTreeStorageNode
Set obj = New clsTreeStorageNode
m_nNodeCount = m_nNodeCount + 1
ReDim Preserve m_tNodes(1 To m_nNodeCount)
With m_tNodes(m_nNodeCount)
 .nType = 1
 Set .objSubNode = obj
End With
Set ITreeStorageBuilder_NewNode = obj
End Function

Private Sub ITreeStorageBuilder_SetName(ByVal lp As Long, ByVal nLength As Long)
SetNameEx lp, nLength
End Sub

Private Sub ITreeStorageBuilder_SetValue(ByVal lp As Long, ByVal nLength As Long)
SetValueEx lp, nLength
End Sub

Private Function ITreeStorageReader_GetName(lpName As Long) As Long
If m_nNameSize > 0 Then
 lpName = VarPtr(m_bName(0))
 ITreeStorageReader_GetName = m_nNameSize
End If
End Function

Private Function ITreeStorageReader_GetNextAttribute(ByVal nUserData As Long, lpName As Long, nNameSize As Long, lpValue As Long, nValueSize As Long) As Long
Dim i As Long
For i = nUserData + 1 To m_nNodeCount
 If m_tNodes(i).nType = 0 Then
  '///
  nNameSize = m_tNodes(i).nNameSize
  If nNameSize > 0 Then lpName = VarPtr(m_tNodes(i).bName(0))
  '///
  nValueSize = m_tNodes(i).nValueSize
  If nValueSize > 0 Then lpValue = VarPtr(m_tNodes(i).bValue(0))
  '///
  ITreeStorageReader_GetNextAttribute = i
  Exit Function
 End If
Next i
End Function

Private Function ITreeStorageReader_GetNextNode(ByVal nUserData As Long, obj As ITreeStorageReader) As Long
Dim i As Long
For i = nUserData + 1 To m_nNodeCount
 If m_tNodes(i).nType = 1 Then
  '///
  Set obj = m_tNodes(i).objSubNode
  '///
  ITreeStorageReader_GetNextNode = i
  Exit Function
 End If
Next i
End Function

Private Function ITreeStorageReader_GetValue(lpValue As Long) As Long
If m_nValueSize > 0 Then
 lpValue = VarPtr(m_bValue(0))
 ITreeStorageReader_GetValue = m_nValueSize
End If
End Function
