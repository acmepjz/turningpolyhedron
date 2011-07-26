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
Private m_tOldPos As typePolyhedronPosition

Private m_tState As typePolyhedronState
Private m_tOldState As typePolyhedronState

Friend Property Get Position() As typePolyhedronPosition
Position = m_tPos
End Property

Friend Property Get OldPosition() As typePolyhedronPosition
OldPosition = m_tOldPos
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

'Friend Sub Destroy()
'Dim t1 As typePolyhedronLogic
'Dim t2 As typePolyhedronPosition
''///
'm_nIndex = 0
'm_tLogic = t1
'm_tPos = t2
''///
'End Sub

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
tPos.p.nMapDataIndex = idx
tPos.p.x = 0
tPos.p.y = 0
tPos.p.z = 0
If i > 0 Then
 tPos.p.x = Val(s1) 'FIXME: no sanity check :-3
 i = InStr(1, s1, ",")
 If i > 0 Then
  tPos.p.y = Val(Mid(s1, i + 1))
  i = InStr(i + 1, s1, ",")
  If i > 0 Then
   tPos.p.z = Val(Mid(s1, i + 1))
  End If
 End If
ElseIf i < 0 Then
 Do
  For k = 0 To tLevel.tMapData(idx).nSize(2) - 1
   For j = 0 To tLevel.tMapData(idx).nSize(1) - 1
    For i = 0 To tLevel.tMapData(idx).nSize(0) - 1
     If tLevel.tMapData(idx).sTagArray(i, j, k) = s1 Then
      tPos.p.x = i
      tPos.p.y = j
      tPos.p.z = k
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
 SetPolyhedronFaceNormal4 tLogic.tFace(0), Vec3(, , -1), Vec3, Vec3(, j), Vec3(i, j), Vec3(i)
 '///top
 CreatePolyhedronFaceLogic tLogic.tFace(1), 4, i, j, , &H5234&, &H1030&
 SetPolyhedronFaceNormal4 tLogic.tFace(1), Vec3(, , 1), Vec3(i, , k), Vec3(i, j, k), Vec3(, j, k), Vec3(, , k)
 '///front
 CreatePolyhedronFaceLogic tLogic.tFace(2), 4, i, k, , &H5031&, &H2222&
 SetPolyhedronFaceNormal4 tLogic.tFace(2), Vec3(, 1), Vec3(i, j, k), Vec3(i, j), Vec3(, j), Vec3(, j, k)
 '///right
 CreatePolyhedronFaceLogic tLogic.tFace(3), 4, k, j, , &H1204&, &H1133&
 SetPolyhedronFaceNormal4 tLogic.tFace(3), Vec3(1), Vec3(i), Vec3(i, j), Vec3(i, j, k), Vec3(i, , k)
 '///back
 CreatePolyhedronFaceLogic tLogic.tFace(4), 4, i, k, , &H3051&, 0
 SetPolyhedronFaceNormal4 tLogic.tFace(4), Vec3(, -1), Vec3(, , k), Vec3, Vec3(i), Vec3(i, , k)
 '///left
 CreatePolyhedronFaceLogic tLogic.tFace(5), 4, k, j, , &H214&, &H1331&
 SetPolyhedronFaceNormal4 tLogic.tFace(5), Vec3(-1), Vec3(, , k), Vec3(, j, k), Vec3(, j), Vec3
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

'vNormal should be normalized
Friend Sub SetPolyhedronFaceNormal4(ByRef tFace As typePolyhedronFaceLogic, ByRef vNormal As D3DVECTOR, ByRef p0 As D3DVECTOR, ByRef p1 As D3DVECTOR, ByRef p2 As D3DVECTOR, ByRef p3 As D3DVECTOR)
tFace.vNormal = vNormal
tFace.vBase(0) = p0
tFace.vBase(1) = p1
tFace.vBase(2) = p2
tFace.vBase(3) = p3
End Sub

Friend Sub GetPolyhedronCoordinates(ByRef vBase As D3DVECTOR, ByRef vNormal As D3DVECTOR, ByRef vRotationAxis As D3DVECTOR)
GetPolyhedronCoordinatesEx m_tPos, vBase, vNormal, vRotationAxis
End Sub

Friend Sub GetOldPolyhedronCoordinates(ByRef vBase As D3DVECTOR, ByRef vNormal As D3DVECTOR, ByRef vRotationAxis As D3DVECTOR)
GetPolyhedronCoordinatesEx m_tOldPos, vBase, vNormal, vRotationAxis
End Sub

'returns which point and edge is on ground
'vBase=which point is on ground
'vNormal=the normal of face which is on ground
'vRotationAxis=which edge is on ground
Friend Sub GetPolyhedronCoordinatesEx(ByRef tPos As typePolyhedronPosition, ByRef vBase As D3DVECTOR, ByRef vNormal As D3DVECTOR, ByRef vRotationAxis As D3DVECTOR)
Dim idx As Long, i As Long, j As Long
idx = tPos.nGroundFaceIndex
i = tPos.nGroundEdgeIndex
j = i - 1
If j < 0 Then j = j + m_tLogic.tFace(idx).nEdgeCount
vBase = m_tLogic.tFace(idx).vBase(i)
vNormal = m_tLogic.tFace(idx).vNormal
D3DXVec3Normalize vRotationAxis, D3DXVec3Subtract(m_tLogic.tFace(idx).vBase(j), vBase)
End Sub

Friend Function CanChangeGroundEdgeIndex(ByVal nNewIndex As Long) As Boolean
If nNewIndex = m_tPos.nGroundEdgeIndex Then
 CanChangeGroundEdgeIndex = True
 Exit Function
End If
'... unimplemented. TODO:actually check it
CanChangeGroundEdgeIndex = True
End Function

Friend Sub InitPolyhedronState()
CheckPolyhedronStateEx m_tPos, m_tState
End Sub

Friend Sub CheckPolyhedronState(ByRef ret As typePolyhedronState)
CheckPolyhedronStateEx m_tPos, ret
End Sub

'TODO:more arguments in typePolyhedronState
'e.g. all on ground tiles
Friend Sub CheckPolyhedronStateEx(ByRef tPos As typePolyhedronPosition, ByRef ret As typePolyhedronState)
Dim i As Long, j As Long, k As Long
Dim x As Long, y As Long, z As Long
Dim p As typeMapPosition
Dim p1 As typeMapPosition
Dim nDirX As Long, nDirYDelta As Long
'///
ret.nState = 0
'///
Select Case m_tLogic.nShape
Case &H111 To &HFFF
 GetCurrentSizeEx tPos, x, y, z
 p = tPos.p
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
    Exit Sub
   End If
  Next i
  nDirX = (nDirX + 1) And 3&
  nDirYDelta = 1
 Case 3
  nDirX = 3
  For i = 1 To x - 1
   If Not objGameMgr.GetAdjacentPositionInPlace(p, nDirX, nDirX) Then
    Debug.Assert False
    Exit Sub
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
    Exit Sub
   End If
  End If
  p1 = p
  k = (nDirX + nDirYDelta) And 3&
  For j = 1 To y
   If j > 1 Then
    If Not objGameMgr.GetAdjacentPositionInPlace(p1, k, k) Then
     Debug.Assert False
     Exit Sub
    End If
   End If
   '///
   z = objGameMgr.HitTest(p1, m_nIndex)
   Select Case z
   Case Is >= 0
    'TODO:check object interaction
   Case -1 'no supporter
    If (m_tLogic.nFlags And &H8&) = 0 Then
     ret.nState = -1 '???
     Exit Sub
    ElseIf x + y <= 3 Then '1x1 or 1x2 or 2x1
     ret.nState = -1
     Exit Sub
    Else
     'TODO:
     Debug.Assert False
     Exit Sub
    End If
   Case &H80000000 To &H8000FFFF 'block tiltable
    'TODO:check tilt angle
    If j = 1 Then
     ret.nState = 0 '???
     Exit Sub
    ElseIf (m_tLogic.nFlags And &H20&) = 0 Then
     ret.nState = 0 '???
     Exit Sub
    Else
     'TODO:
     Debug.Assert False
     Exit Sub
    End If
   Case &H80010000 To &H8001FFFF 'block not tiltable
    'TODO:
    ret.nState = 0 '???
    Exit Sub
   Case Else
    'error???
    Debug.Assert False
    Exit Sub
   End Select
   '///
  Next j
 Next i
 '///over
 ret.nState = 1
Case Else
 'TODO:
 Debug.Assert False
End Select
End Sub

'note: tPos.nGroundEdgeIndex should be calculated before
Friend Function MovePosition(ByRef tPos As typePolyhedronPosition, ByVal nDirection As Long) As Boolean
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
  If Not objGameMgr.GetAdjacentPositionInPlace(tPos.p, nDirection, nDirection) Then
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
'other --> same as CheckPolyhedronStateEx
'TODO:etc.
Friend Function Move(ByVal nDirection As Long) As Long
Dim tPos As typePolyhedronPosition
Dim tState As typePolyhedronState
Dim m As Long
'///check if other polyhedron is on
If objGameMgr.IsOtherPolyhedronOn(m_nIndex) Then Exit Function
'///get new nGroundEdgeIndex
tPos = m_tPos
tPos.nGroundEdgeIndex = tPos.nFirstEdgeIndex + nDirection
m = m_tLogic.tFace(m_tPos.nGroundFaceIndex).nEdgeCount
If tPos.nGroundEdgeIndex >= m Then tPos.nGroundEdgeIndex = tPos.nGroundEdgeIndex - m
'///check if can turn
If Not CanChangeGroundEdgeIndex(tPos.nGroundEdgeIndex) Then Exit Function
'///get new position
If Not MovePosition(tPos, nDirection) Then Exit Function
'///check new state and do something
CheckPolyhedronStateEx tPos, tState
Select Case tState.nState
Case 1 ', -1 'TODO:etc.
 'TODO:onLeave and onMoveLeave events
 '///update animation (TEST ONLY)
 'TODO:tilt angle,etc.
 m_tOldPos = m_tPos
 m_tOldState = m_tState
 objGameMgr.StartPolyhedronAnimation m_nIndex, ret, 0
 '///over
 m_tPos = tPos
 m_tState = tState
End Select
Move = ret
End Function
