VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsPolyhedron"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private m_nIndex As Long

Private m_tLogic As typePolyhedronLogic
Private m_tPos As typePolyhedronPosition

Friend Property Get Position() As typePolyhedronPosition
Position = m_tPos
End Property

Friend Sub GetSize(Optional ByRef nSize0 As Long, Optional ByRef nSize1 As Long, Optional ByRef nSize2 As Long)
nSize0 = m_tLogic.nSize(0)
nSize1 = m_tLogic.nSize(1)
nSize2 = m_tLogic.nSize(2)
End Sub

Friend Sub GetCurrentSize(Optional ByRef nSize0 As Long, Optional ByRef nSize1 As Long, Optional ByRef nSize2 As Long)
GetCurrentSizeEx m_tPos, nSize0, nSize1, nSize2
End Sub

Friend Sub GetCurrentSizeEx(ByRef tPos As typePolyhedronPosition, Optional ByRef nSize0 As Long, Optional ByRef nSize1 As Long, Optional ByRef nSize2 As Long)
Dim i As Long, j As Long
'///
Select Case m_tLogic.nShape
Case &H111 To &HFFF
 Select Case tPos.nGroundFaceIndex
 Case 0, 1
  i = m_tLogic.nSize(0)
  j = m_tLogic.nSize(1)
  nSize2 = m_tLogic.nSize(2)
 Case 2, 4
  i = m_tLogic.nSize(0)
  j = m_tLogic.nSize(2)
  nSize2 = m_tLogic.nSize(1)
 Case 3, 5
  i = m_tLogic.nSize(2)
  j = m_tLogic.nSize(1)
  nSize2 = m_tLogic.nSize(0)
 End Select
 If tPos.nFirstEdgeIndex And 1& Then
  nSize0 = j
  nSize1 = i
 Else
  nSize0 = i
  nSize1 = j
 End If
Case Else
 'TODO:
 Debug.Assert False
End Select
End Sub

Friend Sub Destroy()
Dim t1 As typePolyhedronLogic
Dim t2 As typePolyhedronPosition
'///
m_nIndex = 0
m_tLogic = t1
m_tPos = t2
'///
End Sub

Friend Function CreateIndirect(ByRef tLevel As typeLevelData, ByVal nPolyhedronIndex As Long) As Boolean
'///get index
m_nIndex = nPolyhedronIndex
'///get logic
If Not CreatePolyhedronLogic(m_tLogic, tLevel.tPolyhedron(nPolyhedronIndex).nShape) Then Exit Function
m_tLogic.nObjType = tLevel.tPolyhedron(nPolyhedronIndex).nObjType
m_tLogic.nFlags = tLevel.tPolyhedron(nPolyhedronIndex).nFlags
'///get position
If Not ParsePolyhedronPosition(tLevel.tPolyhedron(nPolyhedronIndex).sPos, m_tPos, tLevel) Then Exit Function
'///
CreateIndirect = True
End Function

Friend Function ParsePolyhedronPosition(ByVal s As String, ByRef tPos As typePolyhedronPosition, ByRef tLevel As typeLevelData) As Boolean
Dim v As Variant
Dim s1 As String
Dim i As Long, j As Long, k As Long, m As Long
Dim idx As Long
'///
v = Split(s, ":")
m = UBound(v)
If m < 0 Then
 Debug.Assert False
 Exit Function
End If
'///get position
s = v(0)
i = InStr(1, s, "(")
If i > 0 Then
 s1 = Mid(s, i + 1)
 s = Left(s, i - 1)
Else
 i = InStr(1, s, ".")
 If i > 0 Then
  s1 = Mid(s, i + 1)
  s = Left(s, i - 1)
  i = -1
 End If
End If
idx = Val(s)
If idx <= 0 Or idx > tLevel.nMapDataCount Then
 For idx = 1 To tLevel.nMapDataCount
  If s = tLevel.tMapData(idx).sID Then Exit For
 Next idx
 If idx > tLevel.nMapDataCount Then
  Debug.Assert False
  Exit Function
 End If
End If
tPos.nMapDataIndex = idx
tPos.x = 0
tPos.y = 0
tPos.z = 0
If i > 0 Then
 tPos.x = Val(s1) 'FIXME: no sanity check :-3
 i = InStr(1, s1, ",")
 If i > 0 Then
  tPos.y = Val(Mid(s1, i + 1))
  i = InStr(i + 1, s1, ",")
  If i > 0 Then
   tPos.z = Val(Mid(s1, i + 1))
  End If
 End If
ElseIf i < 0 Then
 Do
  For k = 0 To tLevel.tMapData(idx).nSize(2) - 1
   For j = 0 To tLevel.tMapData(idx).nSize(1) - 1
    For i = 0 To tLevel.tMapData(idx).nSize(0) - 1
     If tLevel.tMapData(idx).sTagArray(i, j, k) = s1 Then
      tPos.x = i
      tPos.y = j
      tPos.z = k
      Exit Do
     End If
    Next i
   Next j
  Next k
  'err: not found
  Debug.Assert False
  Exit Function
 Loop While False
End If
'///get direction,etc.
i = 0
If m >= 1 Then
 s = v(1)
 Select Case s
 Case "up", "top", "back"
  i = 0
 Case "left"
  i = 1
 Case "down", "bottom", "front"
  i = 2
 Case "right"
  i = 3
 Case Else
  i = Val(s)
 End Select
End If
tPos.nFirstEdgeIndex = i
'///
i = 0
If m >= 2 Then
 s = v(2)
 Select Case s
 Case "bottom"
  i = 0
 Case "top"
  i = 1
 Case "front"
  i = 2
 Case "right"
  i = 3
 Case "back"
  i = 4
 Case "left"
  i = 5
 Case Else
  i = Val(s)
 End Select
End If
tPos.nGroundFaceIndex = i
'///
i = 0
If m >= 3 Then i = Val(v(3))
tPos.nGroundEdgeIndex = i
'///debug
'Debug.Print tPos.nMapDataIndex; tPos.x; tPos.y; tPos.z; tPos.nFirstEdgeIndex; tPos.nGroundFaceIndex; tPos.nGroundEdgeIndex
'///over
ParsePolyhedronPosition = True
End Function

Friend Function CreatePolyhedronLogic(ByRef tLogic As typePolyhedronLogic, ByVal nShape As Long) As Boolean
Dim i As Long, j As Long, k As Long
Dim m As Long, n As Long
tLogic.nShape = nShape
Select Case nShape
Case &H111 To &HFFF
 i = (nShape And &HF00&) \ &H100&
 j = (nShape And &HF0&) \ &H10&
 k = nShape And &HF&
 tLogic.nSize(0) = i
 tLogic.nSize(1) = j
 tLogic.nSize(2) = k
 '///debug
 'Debug.Print i; j; k
 '///
 tLogic.nFaceCount = 6
 ReDim tLogic.tFace(0 To 5)
 '///bottom
 CreatePolyhedronFaceLogic tLogic.tFace(0), 4, i, j, , &H3254&, &H1232&
 '///top
 CreatePolyhedronFaceLogic tLogic.tFace(1), 4, i, j, , &H5234&, &H1030&
 '///front
 CreatePolyhedronFaceLogic tLogic.tFace(2), 4, i, k, , &H5031&, &H2222&
 '///right
 CreatePolyhedronFaceLogic tLogic.tFace(3), 4, k, j, , &H1204&, &H1133&
 '///back
 CreatePolyhedronFaceLogic tLogic.tFace(4), 4, i, k, , &H3051&, 0
 '///left
 CreatePolyhedronFaceLogic tLogic.tFace(5), 4, k, j, , &H214&, &H1331&
Case Else
 'TODO:
 Debug.Assert False
 Exit Function
End Select
CreatePolyhedronLogic = True
End Function

'internal
Friend Sub CreatePolyhedronFaceLogic(ByRef tFace As typePolyhedronFaceLogic, ByVal nEdgeCount As Long, Optional ByVal nSize0 As Long, Optional ByVal nSize1 As Long, Optional ByVal nSize2 As Long, Optional ByVal nAdjacentFace As Long, Optional ByVal nAdjacentFaceEdge As Long)
Dim i As Long
tFace.nEdgeCount = nEdgeCount
tFace.nSize(0) = nSize0
tFace.nSize(1) = nSize1
tFace.nSize(2) = nSize2
For i = 0 To nEdgeCount - 1
 tFace.nAdjacentFace(i) = nAdjacentFace And &HF&
 tFace.nAdjacentFaceEdge(i) = nAdjacentFaceEdge And &HF&
 nAdjacentFace = nAdjacentFace \ &H10&
 nAdjacentFaceEdge = nAdjacentFaceEdge \ &H10&
Next i
End Sub

Friend Function CanChangeGroundEdgeIndex(ByVal nNewIndex As Long, ByVal objGameMgr As clsGameManager) As Boolean
If nNewIndex = m_tPos.nGroundEdgeIndex Then
 CanChangeGroundEdgeIndex = True
 Exit Function
End If
'... unimplemented. TODO:actually check it
CanChangeGroundEdgeIndex = True
End Function

Friend Function CheckPolyhedronState(ByVal objGameMgr As clsGameManager) As Long
CheckPolyhedronState = CheckPolyhedronStateEx(m_tPos, objGameMgr)
End Function

'-1=fall (TODO:if it isn't fragile then it's OK)
'0 =can't move
'1 =OK
'TODO:etc.
Friend Function CheckPolyhedronStateEx(ByRef tPos As typePolyhedronPosition, ByVal objGameMgr As clsGameManager) As Long
Dim i As Long, j As Long, k As Long
Dim x As Long, y As Long, z As Long
Dim p As typePolyhedronPosition
Dim p1 As typePolyhedronPosition
Dim nDirX As Long, nDirYDelta As Long
'///
Select Case m_tLogic.nShape
Case &H111 To &HFFF
 GetCurrentSizeEx tPos, x, y, z
 p = tPos
 '///
 'on-ground edge --> index on ground
 i = (tPos.nGroundEdgeIndex - tPos.nFirstEdgeIndex) And 3&
 Select Case i
 Case 0
  nDirX = 3
  nDirYDelta = -1
 Case 1
  nDirX = 2
  nDirYDelta = 1
  z = x
  x = y
  y = z
 Case 2
  nDirX = 2
  For i = 1 To y - 1
   If Not objGameMgr.GetAdjacentPositionInPlace(p, nDirX, nDirX) Then
    Debug.Assert False
    Exit Function
   End If
  Next i
  nDirX = (nDirX + 1) And 3&
  nDirYDelta = 1
 Case 3
  nDirX = 3
  For i = 1 To x - 1
   If Not objGameMgr.GetAdjacentPositionInPlace(p, nDirX, nDirX) Then
    Debug.Assert False
    Exit Function
   End If
  Next i
  nDirX = (nDirX - 1) And 3&
  nDirYDelta = -1
  z = x
  x = y
  y = z
 End Select
 '///check
 For i = 1 To x
  If i > 1 Then
   If Not objGameMgr.GetAdjacentPositionInPlace(p, nDirX, nDirX) Then
    Debug.Assert False
    Exit Function
   End If
  End If
  p1 = p
  k = (nDirX + nDirYDelta) And 3&
  For j = 1 To y
   If j > 1 Then
    If Not objGameMgr.GetAdjacentPositionInPlace(p1, k, k) Then
     Debug.Assert False
     Exit Function
    End If
   End If
   '///
   z = objGameMgr.HitTest(p1, m_nIndex)
   Select Case z
   Case Is >= 0
    'TODO:check object interaction
   Case -1 'no supporter
    If (m_tLogic.nFlags And &H8&) = 0 Then
     CheckPolyhedronStateEx = -1 '???
     Exit Function
    ElseIf x + y <= 3 Then '1x1 or 1x2 or 2x1
     CheckPolyhedronStateEx = -1
     Exit Function
    Else
     'TODO:
     Debug.Assert False
     Exit Function
    End If
   Case &H80000000 To &H8000FFFF 'block tiltable
    If j = 1 Then
     CheckPolyhedronStateEx = 0 '???
     Exit Function
    ElseIf (m_tLogic.nFlags And &H20&) = 0 Then
     CheckPolyhedronStateEx = 0 '???
     Exit Function
    Else
     'TODO:
     Debug.Assert False
     Exit Function
    End If
   Case &H80010000 To &H8001FFFF 'block not tiltable
    'TODO:
    CheckPolyhedronStateEx = 0 '???
    Exit Function
   Case Else
    'error???
    Debug.Assert False
    Exit Function
   End Select
   '///
  Next j
 Next i
 '///over
 CheckPolyhedronStateEx = 1
Case Else
 'TODO:
 Debug.Assert False
End Select
End Function

'note: tPos.nGroundEdgeIndex should be calculated before
Friend Function MovePosition(ByRef tPos As typePolyhedronPosition, ByVal nDirection As Long, ByVal objGameMgr As clsGameManager) As Boolean
Dim x As Long, y As Long, z As Long
Dim nOldFace As Long
Dim nOldEdge As Long
'///
Select Case m_tLogic.nShape
Case &H111 To &HFFF
 GetCurrentSizeEx tPos, x, y, z
 '///
 Select Case nDirection
 Case 0, 1 'up,left
  x = z
 Case 2 'down
  x = y
 Case 3 'right
 Case Else
  Debug.Assert False
  Exit Function
 End Select
 Do While x > 0
  If Not objGameMgr.GetAdjacentPositionInPlace(tPos, nDirection, nDirection) Then
   Debug.Assert False
   Exit Function
  End If
  x = x - 1
 Loop
 '///
 nOldFace = tPos.nGroundFaceIndex
 nOldEdge = tPos.nGroundEdgeIndex
 tPos.nGroundFaceIndex = m_tLogic.tFace(nOldFace).nAdjacentFace(nOldEdge)
 tPos.nGroundEdgeIndex = m_tLogic.tFace(nOldFace).nAdjacentFaceEdge(nOldEdge)
 tPos.nFirstEdgeIndex = (tPos.nGroundEdgeIndex - nDirection + 2) And 3&
Case Else
 'TODO:
 Debug.Assert False
 Exit Function
End Select
MovePosition = True
End Function

'0=can't move
'1=OK
'TODO:etc.
Friend Function Move(ByVal nDirection As Long, ByVal objGameMgr As clsGameManager) As Long
Dim tPos As typePolyhedronPosition
Dim m As Long
'///check if other polyhedron is on
If objGameMgr.IsOtherPolyhedronOn(m_nIndex) Then Exit Function
'///get new nGroundEdgeIndex
tPos = m_tPos
tPos.nGroundEdgeIndex = tPos.nFirstEdgeIndex + nDirection
m = m_tLogic.tFace(m_tPos.nGroundFaceIndex).nEdgeCount
If tPos.nGroundEdgeIndex >= m Then tPos.nGroundEdgeIndex = tPos.nGroundEdgeIndex - m
'///check if can turn
If Not CanChangeGroundEdgeIndex(tPos.nGroundEdgeIndex, objGameMgr) Then Exit Function
'///get new position
If Not MovePosition(tPos, nDirection, objGameMgr) Then Exit Function
'///check new position
'TODO:check state and do something
If CheckPolyhedronStateEx(tPos, objGameMgr) <> 1 Then Exit Function
'///over
m_tPos = tPos
Move = 1
End Function
