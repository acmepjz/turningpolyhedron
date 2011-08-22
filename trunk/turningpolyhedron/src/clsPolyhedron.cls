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

Private m_nSlipDirection As Long '0=disabled 1=direction 0,etc...

Friend Property Get PolyhedronFlags() As Long
PolyhedronFlags = m_tLogic.nFlags
End Property

Friend Property Let PolyhedronFlags(ByVal n As Long)
m_tLogic.nFlags = n
End Property

Friend Property Get Position(Optional ByVal IsOld As Boolean) As typePolyhedronPosition
If IsOld Then
 Position = m_tOldPos
Else
 Position = m_tPos
End If
End Property

Friend Property Let Position(Optional ByVal IsOld As Boolean, ByRef tPos As typePolyhedronPosition)
If IsOld Then
 m_tOldPos = tPos
Else
 m_tPos = tPos
End If
End Property

Friend Function SetPositionFromString(ByVal s As String, ByRef tLevel As typeLevelData) As Boolean
Dim t As typePolyhedronPosition
If ParsePolyhedronPosition(s, t, tLevel) Then
 m_tPos = t
 SetPositionFromString = True
End If
End Function

Friend Property Get PolyhedronState(Optional ByVal IsOld As Boolean) As typePolyhedronState
If IsOld Then
 PolyhedronState = m_tOldState
Else
 PolyhedronState = m_tState
End If
End Property

Friend Property Get PolyhedronTiltTangent(Optional ByVal IsOld As Boolean) As Single
If IsOld Then
 PolyhedronTiltTangent = m_tOldState.fTiltTangent
Else
 PolyhedronTiltTangent = m_tState.fTiltTangent
End If
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
If m_tLogic.nFlags And &H100& Then
 If Not ParsePolyhedronPosition(tLevel.tPolyhedron(nPolyhedronIndex).sPos, m_tPos, tLevel) Then Exit Function
End If
'///
CreateIndirect = True
End Function

Friend Function ParsePolyhedronPosition(ByVal s As String, ByRef tPos As typePolyhedronPosition, ByRef tLevel As typeLevelData) As Boolean
Dim v As Variant
Dim i As Long, m As Long
'///
v = Split(s, ":")
m = UBound(v)
If m < 0 Then
 Debug.Assert False
 Exit Function
End If
'///get position
If Not objGameMgr.FindPositionEx(tLevel, v(0), tPos.p) Then
 Debug.Assert False
 Exit Function
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

Friend Sub GetPolyhedronCoordinates(ByRef vBase As D3DVECTOR, ByRef vNormal As D3DVECTOR, ByRef vRotationAxis As D3DVECTOR, Optional ByVal IsOld As Boolean)
If IsOld Then
 GetPolyhedronCoordinatesEx m_tOldPos, vBase, vNormal, vRotationAxis
Else
 GetPolyhedronCoordinatesEx m_tPos, vBase, vNormal, vRotationAxis
End If
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
'///check tilt (TEST ONLY)
If m_tState.nTiltY > 0 Then
 If ((m_tPos.nGroundEdgeIndex + 2) And 3&) = nNewIndex Then
  Exit Function
 End If
End If
'///TODO:other
CanChangeGroundEdgeIndex = True
End Function

Friend Sub CheckPolyhedronStateAndResponse()
Dim i As Long
Dim tPos As typePolyhedronPosition
Dim tState As typePolyhedronState
'///
CheckPolyhedronStateEx m_tPos, m_tState, False
'///response
'TODO:if state changed then play some animation (e.g. tilt angle changed)
Select Case m_tState.nState
Case -1 'falling
 objGameMgr.StartPolyhedronAnimation m_nIndex, -1, 0
Case 2 'slippery
 If m_nSlipDirection > 0 Then
  tPos = m_tPos
  If objGameMgr.GetAdjacentPositionInPlace(tPos.p, m_nSlipDirection - 1, i) Then
   'TODO:non-retangular shape
   tPos.nFirstEdgeIndex = (tPos.nFirstEdgeIndex - i + m_nSlipDirection - 1) And 3& '???
   '///check
   CheckPolyhedronStateEx tPos, tState, False
   If tState.nState Then
    m_tOldPos = m_tPos
    m_tOldState = m_tState
    m_tPos = tPos
    m_tState = tState
    'TODO:events
    'wrong code because some tile receives event more than one
    SendEventEx EventTypeOnLeave, m_tOldState
    SendEventEx EventTypeOnMoveLeave, m_tOldState
    'animation
    objGameMgr.StartPolyhedronAnimation m_nIndex, 2, 0
    'over
    m_nSlipDirection = i + 1
   Else
    m_nSlipDirection = 0
   End If
  Else 'err???
   m_nSlipDirection = 0
  End If
 End If
Case &H100 To &H1FF 'game over
 objGameMgr.ProcessGameOver m_nIndex, m_tState.nState, m_tPos.p
End Select
End Sub

'TODO:more arguments in typePolyhedronState
'e.g. all on ground tiles
Friend Sub CheckPolyhedronStateEx(ByRef tPos As typePolyhedronPosition, ByRef ret As typePolyhedronState, ByVal bMoving As Boolean)
Dim i As Long, j As Long, k As Long
Dim x As Long, y As Long, z As Long
Dim nHeight As Long, nHeight2 As Long
Dim tmp As Long, tHitTest As typeMapDataHitTest
Dim p As typeMapPosition
Dim p1 As typeMapPosition
Dim nDirXDelta As Long, nDirY As Long
Dim nMax As Long, nState As Long
Dim f As Single
Dim bFirstEmpty As Boolean
'///
ret.nState = 0
nState = 1
ret.nTiltX = 1
ret.nTiltY = 0
ret.fTiltTangent = 0
ret.fPressure = 0
ret.nOnGroundCount = 0
Erase ret.tOnGroundPos
ret.nHitTestCount = 0
Erase ret.tHitTestPos
ret.nTileTypeCount = 0
Erase ret.nTileTypes
ret.nObjTypeCount = 0
Erase ret.nObjTypes
'///
Select Case m_tLogic.nShape
Case &H111 To &HFFF
 GetCurrentSizeEx tPos, x, y, z
 ret.fPressure = z 'TODO:irregular polyhedron
 p = tPos.p
 '///
 'on-ground edge --> index on ground
 i = (tPos.nGroundEdgeIndex - tPos.nFirstEdgeIndex) And 3&
 Select Case i
 Case 0
  nDirY = 2
  nDirXDelta = 1
 Case 1
  nDirY = 3
  nDirXDelta = -1
  tmp = x
  x = y
  y = tmp
 Case 2
  nDirY = 2
  For i = 1 To y - 1
   If Not objGameMgr.GetAdjacentPositionInPlace(p, nDirY, nDirY) Then 'err
    Debug.Assert False
    Exit Sub
   End If
  Next i
  nDirY = (nDirY + 2) And 3&
  nDirXDelta = -1
 Case 3
  nDirY = 3
  For i = 1 To x - 1
   If Not objGameMgr.GetAdjacentPositionInPlace(p, nDirY, nDirY) Then 'err
    Debug.Assert False
    Exit Sub
   End If
  Next i
  nDirY = (nDirY + 2) And 3&
  nDirXDelta = 1
  tmp = x
  x = y
  y = tmp
 End Select
 '///check
 For j = 1 To y
  If j > 1 Then
   If Not objGameMgr.GetAdjacentPositionInPlace(p, nDirY, nDirY) Then 'err
    Debug.Assert False
    Exit Sub
   End If
  End If
  p1 = p
  k = (nDirY + nDirXDelta) And 3&
  '///get polyhedron height (???)
  If bMoving Then
   nHeight = j - 1
   nHeight = y * y - nHeight * nHeight
   'TODO: WRONG CODE --> if wall height is infinity and nHeight>nHeight2 then it produces wrong result
   nHeight2 = -Int(-Sqr(nHeight))
   nHeight = -Int(-Sqr(nHeight + z * z))
  Else
   nHeight = z
   nHeight2 = z
  End If
  '///debug
  'Debug.Print y, z, j, bMoving, nHeight, nHeight2
  '///
  For i = 1 To x
   If i > 1 Then
    If Not objGameMgr.GetAdjacentPositionInPlace(p1, k, k) Then 'err
     Debug.Assert False
     Exit Sub
    End If
   End If
   '///
   objGameMgr.HitTest p1, tHitTest, ret, m_nIndex, nHeight, nHeight2, z, ret.nTiltY = 0
   Select Case tHitTest.nType
   Case 0
    If ret.nTiltY = 0 Then
     '///record
     ret.nOnGroundCount = ret.nOnGroundCount + 1
     If ret.nOnGroundCount > nMax Then
      nMax = nMax + 16
      ReDim Preserve ret.tOnGroundPos(1 To nMax)
     End If
     ret.tOnGroundPos(ret.nOnGroundCount) = p1
     '///add type
     If tHitTest.nTileType Then
      For tmp = 1 To ret.nTileTypeCount
       If ret.nTileTypes(tmp) = tHitTest.nTileType Then Exit For
      Next tmp
      If tmp > ret.nTileTypeCount Then
       ret.nTileTypeCount = ret.nTileTypeCount + 1
       ReDim Preserve ret.nTileTypes(1 To ret.nTileTypeCount)
       ret.nTileTypes(ret.nTileTypeCount) = tHitTest.nTileType
      End If
     End If
     '///
     For tmp = 1 To ret.nObjTypeCount
      If ret.nObjTypes(tmp) = tHitTest.nObjType Then Exit For
     Next tmp
     If tmp > ret.nObjTypeCount Then
      ret.nObjTypeCount = ret.nObjTypeCount + 1
      ReDim Preserve ret.nObjTypes(1 To ret.nObjTypeCount)
      ret.nObjTypes(ret.nObjTypeCount) = tHitTest.nObjType
     End If
     '///
    End If
   Case -1 'no supporter
    If j = 1 Then bFirstEmpty = True
    If ret.nTiltY = 0 Then '????????
     If (m_tLogic.nFlags And &H8&) = 0 Then
      If nState > 0 Then nState = -1 '???
     ElseIf x + y <= 3 Then '1x1 or 1x2 or 2x1
      If nState > 0 Then nState = -1
     Else
      'TODO:
      Debug.Assert False
     End If
    End If
   Case &H80000000 To &H8001FFFF 'block tiltable AND block not tiltable
    If j = 1 Then
     nState = 0
    ElseIf (m_tLogic.nFlags And &H20&) = 0 Then
     nState = 0
    Else
     '///check tilt angle
     tmp = (tHitTest.nType And &HFFFF&) * ret.nTiltX - ret.nTiltY * (j - 1)
     If tHitTest.nType < &H80010000 Then 'tiltable
      '///check height - if it's blocked (???)
      If (tHitTest.nType And &HFFFF&) > nHeight2 And tmp > 0 Then
       nState = 0
      End If
      '///tile --> doesn't need supporter (???)
      If nState = -1 Then
       If Not bFirstEmpty Then nState = 1
      End If
      '///
      If tmp >= 0 Then
       If tmp > 0 Then
        ret.nTiltX = j - 1
        ret.nTiltY = tHitTest.nType And &HFFFF&
        ret.nOnGroundCount = 0
        nMax = 16
        ReDim ret.tOnGroundPos(1 To nMax)
        '///???
        ret.nTileTypeCount = 0
        Erase ret.nTileTypes
        ret.nObjTypeCount = 0
        Erase ret.nObjTypes
       End If
       '///record
       ret.nOnGroundCount = ret.nOnGroundCount + 1
       If ret.nOnGroundCount > nMax Then
        nMax = nMax + 16
        ReDim Preserve ret.tOnGroundPos(1 To nMax)
       End If
       ret.tOnGroundPos(ret.nOnGroundCount) = p1
       '///add type
       If tHitTest.nTileType Then
        For tmp = 1 To ret.nTileTypeCount
         If ret.nTileTypes(tmp) = tHitTest.nTileType Then Exit For
        Next tmp
        If tmp > ret.nTileTypeCount Then
         ret.nTileTypeCount = ret.nTileTypeCount + 1
         ReDim Preserve ret.nTileTypes(1 To ret.nTileTypeCount)
         ret.nTileTypes(ret.nTileTypeCount) = tHitTest.nTileType
        End If
       End If
       '///
       For tmp = 1 To ret.nObjTypeCount
        If ret.nObjTypes(tmp) = tHitTest.nObjType Then Exit For
       Next tmp
       If tmp > ret.nObjTypeCount Then
        ret.nObjTypeCount = ret.nObjTypeCount + 1
        ReDim Preserve ret.nObjTypes(1 To ret.nObjTypeCount)
        ret.nObjTypes(ret.nObjTypeCount) = tHitTest.nObjType
       End If
       '///
      End If
     Else 'not tiltable
      If tmp > 0 Then
       nState = 0
      End If
     End If
    End If
   Case Else
    'error???
    Debug.Assert False
    Exit Sub
   End Select
   '///
  Next i
 Next j
 '///check object interaction
 If nState = 1 Then
  j = 0
  For i = 1 To ret.nObjTypeCount
   k = objGameMgr.GetObjectInteractionType(m_tLogic.nObjType, ret.nObjTypes(i))
   Select Case k
   Case 0 'moveable
   Case 1 'not-moveable (???)
    Debug.Print "TODO:not-moveable"
   Case 2 'slippery
    If ret.nTiltY = 0 Then j = j + 1 '??
   Case 3 'superSlippery
    j = ret.nObjTypeCount + 1
   Case 4 'blocked (???)
    nState = 0
   Case &H100& 'game-over (falling)
    If nState = 1 Then nState = -1
   Case &H101& To &H1FF& 'game-over (other)
    If nState = 1 Then nState = k
   End Select
  Next i
  If j > 0 And j >= ret.nObjTypeCount And nState = 1 Then nState = 2
 End If
 '///over, calc tangent
 ret.nState = nState
 If ret.nTiltY > 0 Then
  i = ret.nTiltX
  ret.fTiltTangent = ret.nTiltY / i
  f = Sqr(y * y - i * i) / i
  If ret.fTiltTangent > f Then ret.fTiltTangent = f
  '///
  ret.nHitTestCount = 0
  Erase ret.tHitTestPos
 End If
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
'(obsolete) other --> same as CheckPolyhedronStateEx
'TODO:etc.
Friend Function Move(ByVal nDirection As Long, Optional ByVal bAllowFalling As Boolean) As Long
Dim tPos As typePolyhedronPosition
Dim tState As typePolyhedronState
Dim nTiltGroundEdgeDelta As Long '????????
Dim m As Long
Dim bMove As Boolean
'///
m_nSlipDirection = 0
'///check if other polyhedron is on
If objGameMgr.IsOtherPolyhedronOn(m_nIndex) Then Exit Function
'///get new nGroundEdgeIndex
tPos = m_tPos
tPos.nGroundEdgeIndex = tPos.nFirstEdgeIndex + nDirection
m = m_tLogic.tFace(m_tPos.nGroundFaceIndex).nEdgeCount
If tPos.nGroundEdgeIndex >= m Then tPos.nGroundEdgeIndex = tPos.nGroundEdgeIndex - m
If m = 4 And m_tState.nTiltY > 0 Then
 nTiltGroundEdgeDelta = (tPos.nGroundEdgeIndex - m_tPos.nGroundEdgeIndex) And 3&
End If
'///check if can turn
If Not CanChangeGroundEdgeIndex(tPos.nGroundEdgeIndex) Then Exit Function
'///get new position
If Not MovePosition(tPos, nDirection) Then Exit Function
'///check new state and do something
'check tilt move first
If nTiltGroundEdgeDelta And 1& Then
 tPos.nGroundEdgeIndex = (tPos.nGroundEdgeIndex + nTiltGroundEdgeDelta) And 3&
 CheckPolyhedronStateEx tPos, tState, True
 If tState.nTiltY * m_tState.nTiltX - m_tState.nTiltY * tState.nTiltX > 0 Then 'check tilt angle
  tState.nState = 0
 End If
 If tState.nState = 0 Then
  tPos.nGroundEdgeIndex = (tPos.nGroundEdgeIndex - nTiltGroundEdgeDelta) And 3&
 Else
  nTiltGroundEdgeDelta = nTiltGroundEdgeDelta Or 4&
 End If
End If
'check normal move
If tState.nState = 0 Then
 CheckPolyhedronStateEx tPos, tState, True
End If
'check new state
bMove = False
Select Case tState.nState
Case 0
Case -1 'falling
 bMove = bAllowFalling
Case Else 'TODO:etc.
 bMove = True
End Select
If bMove Then
 m_tOldPos = m_tPos
 m_tOldState = m_tState
 m_tPos = tPos
 m_tState = tState
 '///
 If tState.nState = 2 Then m_nSlipDirection = nDirection + 1
 '///update animation (TEST ONLY)
 If nTiltGroundEdgeDelta And 1& Then
  objGameMgr.StartPolyhedronAnimation m_nIndex, 1, nTiltGroundEdgeDelta
 Else
  'TODO:etc.
  objGameMgr.StartPolyhedronAnimation m_nIndex, 1, 0
 End If
 '///onLeave and onMoveLeave events
 SendEventEx EventTypeOnLeave, m_tOldState
 SendEventEx EventTypeOnMoveLeave, m_tOldState
 '///
 Move = (m_tState.nState <> 0) And 1& '??
End If
End Function

Friend Sub SendEvent(ByVal nEventType As Long, Optional ByVal IsOld As Boolean)
If IsOld Then
 SendEventEx nEventType, m_tOldState
Else
 SendEventEx nEventType, m_tState
End If
End Sub

Friend Sub SendEventEx(ByVal nEventType As Long, ByRef tState As typePolyhedronState)
Dim tEvent As typeMapDataEvent
Dim i As Long
'///
If tState.nTiltY = 0 Then
 If tState.nState = 1 Then
  tEvent.nEventType = nEventType
  tEvent.nPolyhedronIndex = m_nIndex
  tEvent.fPressure = tState.fPressure
  tEvent.nOnGroundCount = tState.nOnGroundCount
  tEvent.nTileTypeCount = tState.nTileTypeCount
  tEvent.nObjTypeCount = tState.nObjTypeCount
  '///
  Select Case nEventType
  Case EventTypeOnHitTest
   For i = 1 To tState.nHitTestCount
    tEvent.p = tState.tHitTestPos(i)
    objGameMgr.AddMapEvent tEvent
   Next i
  Case Else
   For i = 1 To tState.nOnGroundCount
    tEvent.p = tState.tOnGroundPos(i)
    objGameMgr.AddMapEvent tEvent
   Next i
  End Select
 End If
End If
End Sub
