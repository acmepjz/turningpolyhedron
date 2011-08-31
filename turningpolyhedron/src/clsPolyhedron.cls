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

'////////undo support (experimental)

Private Type typePolyhedronUndoData
 nUndoIndex As Long
 '///
 tPos As typePolyhedronPosition
 'tOldPos As typePolyhedronPosition
 tState As typePolyhedronState
 'tOldState As typePolyhedronState
 'nSlipDirection As Long
End Type

Private m_tUndo() As typePolyhedronUndoData '1-based
Private m_nUndoCount As Long, m_nUndoMax As Long
Private m_bUndoDirty As Boolean

Friend Sub AddUndoIndex(ByVal nUndoIndex As Long)
If Not m_bUndoDirty Then Exit Sub
'///
If m_nUndoCount > 0 Then
 If m_tUndo(m_nUndoCount).nUndoIndex < nUndoIndex Then
  m_nUndoCount = m_nUndoCount + 1
 Else
  Debug.Assert False '???
 End If
Else
 m_nUndoCount = m_nUndoCount + 1
End If
'///
If m_nUndoCount > m_nUndoMax Then
 m_nUndoMax = m_nUndoMax + 256&
 ReDim Preserve m_tUndo(1 To m_nUndoMax)
End If
'///
m_tUndo(m_nUndoCount).nUndoIndex = nUndoIndex
m_tUndo(m_nUndoCount).tPos = m_tPos
'm_tUndo(m_nUndoCount).tOldPos = m_tOldPos
m_tUndo(m_nUndoCount).tState = m_tState
'm_tUndo(m_nUndoCount).tOldState = m_tOldState
'm_tUndo(m_nUndoCount).nSlipDirection = m_nSlipDirection
'///
m_bUndoDirty = False
End Sub

Friend Sub Undo(ByVal nUndoIndex As Long)
Dim i As Long
For i = m_nUndoCount To 1 Step -1
 If m_tUndo(i).nUndoIndex <= nUndoIndex Then Exit For '???
Next i
If i <= 0 Or i > m_nUndoCount Then Exit Sub
If i = m_nUndoCount And Not m_bUndoDirty Then Exit Sub
'///
m_tPos = m_tUndo(i).tPos
'm_tOldPos = m_tUndo(i).tOldPos
m_tState = m_tUndo(i).tState
'm_tOldState = m_tUndo(i).tOldState
'm_nSlipDirection = m_tUndo(i).nSlipDirection
m_nSlipDirection = 0
'///
m_bUndoDirty = False
m_nUndoCount = i
End Sub

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
 m_bUndoDirty = True
End If
End Property

Friend Function SetPositionFromString(ByVal s As String, ByRef tLevel As typeLevelData) As Boolean
Dim t As typePolyhedronPosition
If ParsePolyhedronPosition(s, t, tLevel) Then
 m_tPos = t
 SetPositionFromString = True
 m_bUndoDirty = True
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
Erase m_tUndo
m_nUndoCount = 0
m_nUndoMax = 0
m_bUndoDirty = True
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

Friend Sub CheckPolyhedronStateAndResponse(ByRef tPoly As typeMapData_Polyhedron, ByVal bUseOldState As Boolean)
Dim i As Long
Dim tPos As typePolyhedronPosition
Dim tState As typePolyhedronState
'///
'FIXME:
'should add some tilt checking in CheckPolyhedronStateEx when bMoving=False
CheckPolyhedronStateEx m_tPos, m_tState, False, bUseOldState, tPoly
m_bUndoDirty = True
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
   m_nSlipDirection = 0
   '///check
   CheckPolyhedronStateEx tPos, tState, False, bUseOldState, tPoly '<== bUseOldState ????????
   If tState.nState Then
    If tState.nTiltY * m_tState.nTiltX - m_tState.nTiltY * tState.nTiltX <= 0 Then
     m_tOldPos = m_tPos
     m_tOldState = m_tState
     m_tPos = tPos
     m_tState = tState
     'TODO:events
     'wrong code because some tile receives event more than one
     SendEventEx EventTypeOnLeave, m_tOldState, m_tOldPos
     SendEventEx EventTypeOnMoveLeave, m_tOldState, m_tOldPos
     'animation
     objGameMgr.StartPolyhedronAnimation m_nIndex, 2, 0
     'over
     m_nSlipDirection = i + 1
    End If
   End If
  Else
   m_nSlipDirection = 0
  End If
 End If
Case &H100 To &H1FF 'game over
 objGameMgr.ProcessGameOver m_nIndex, m_tState.nState, m_tPos.p
End Select
End Sub

Friend Sub CheckPolyhedronStateEx(ByRef tPos As typePolyhedronPosition, ByRef ret As typePolyhedronState, ByVal bMoving As Boolean, ByVal bUseOldState As Boolean, ByRef tPoly As typeMapData_Polyhedron)
Dim i As Long, j As Long, k As Long
Dim x As Long, y As Long, z As Long
Dim nHeight As Long, nHeight2 As Long
Dim tmp As Long, tHitTest As typeMapDataHitTest
Dim p As typeMapPosition
Dim p1 As typeMapPosition
Dim nDirX As Long, nDirXDelta As Long, nDirY As Long
Dim nMax As Long, nState As Long
Dim f As Single
Dim bFirstEmpty As Boolean, b As Boolean
'///custom shape
Dim ci As Long, cj As Long, ck As Long
Dim cii As Long, cjj As Long, ckk As Long
Dim cxi As Long, cxj As Long, cxk As Long
Dim cyi As Long, cyj As Long, cyk As Long
Dim czi As Long, czj As Long, czk As Long
Dim v As D3DVECTOR, v1 As D3DVECTOR
'///
Dim nOldTiltX As Long, nOldTiltY As Long
'///
Dim nMask(31) As Long
j = 1
For i = 0 To 29
 nMask(i) = j
 j = j + j
Next i
nMask(30) = &H40000000
nMask(31) = &H80000000
'///
If bUseOldState Then
 nOldTiltX = ret.nTiltX
 nOldTiltY = ret.nTiltY
End If
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
 If tPoly.bCustomShapeEnabled Then
  v = m_tLogic.tFace(tPos.nGroundFaceIndex).vBase(tPos.nGroundEdgeIndex)
  ci = v.x
  cj = v.y
  ck = v.z
  If ci > 0 Then ci = ci - 1
  If cj > 0 Then cj = cj - 1
  If ck > 0 Then ck = ck - 1
  '///
  D3DXVec3Normalize v1, D3DXVec3Subtract(m_tLogic.tFace(tPos.nGroundFaceIndex).vBase((tPos.nGroundEdgeIndex - 1) And 3&), v)
  cxi = v1.x
  cxj = v1.y
  cxk = v1.z
  '///
  D3DXVec3Normalize v1, D3DXVec3Subtract(m_tLogic.tFace(tPos.nGroundFaceIndex).vBase((tPos.nGroundEdgeIndex + 1) And 3&), v)
  cyi = v1.x
  cyj = v1.y
  cyk = v1.z
  '///
  czi = cxj * cyk - cxk * cyj
  czj = cxk * cyi - cxi * cyk
  czk = cxi * cyj - cxj * cyi
 End If
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
  tmp = x: x = y: y = tmp
  '///
  If tPoly.bCustomShapeEnabled Then
   ci = ci + (x - 1) * cxi
   cj = cj + (x - 1) * cxj
   ck = ck + (x - 1) * cxk
   cxi = -cxi
   cxj = -cxj
   cxk = -cxk
  End If
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
  '///
  If tPoly.bCustomShapeEnabled Then
   ci = ci + (x - 1) * cxi
   cj = cj + (x - 1) * cxj
   ck = ck + (x - 1) * cxk
   cxi = -cxi
   cxj = -cxj
   cxk = -cxk
  End If
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
  tmp = x: x = y: y = tmp
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
  nDirX = (nDirY + nDirXDelta) And 3&
  '///get polyhedron height (???)
  If bMoving Or (bUseOldState And nOldTiltY > 0) Then
   nHeight = j - 1
   nHeight = y * y - nHeight * nHeight
   'TODO: WRONG CODE --> if wall height is infinity and nHeight>nHeight2 then it produces wrong result
   nHeight2 = -Int(-Sqr(nHeight))
   nHeight = -Int(-Sqr(nHeight + z * z))
'  ElseIf bUseOldState And nOldTiltY > 0 Then
'   'TODO:
  Else
   nHeight = z
   nHeight2 = z
  End If
  '///debug
  'Debug.Print y, z, j, bMoving, nHeight, nHeight2
  '///
  If tPoly.bCustomShapeEnabled Then
   cii = ci
   cjj = cj
   ckk = ck
  End If
  '///
  For i = 1 To x
   If i > 1 Then
    If Not objGameMgr.GetAdjacentPositionInPlace(p1, nDirX, nDirX) Then 'err
     Debug.Assert False
     Exit Sub
    End If
   End If
   '///
   objGameMgr.HitTest p1, tHitTest, ret, m_nIndex, nHeight, nHeight2, z, ret.nTiltY = 0
   Select Case tHitTest.nType
   Case 0
    If ret.nTiltY = 0 Then
     If tPoly.bCustomShapeEnabled Then
      b = tPoly.nCustomShape(cii, cjj, ckk)
     Else
      b = True
     End If
     If b Then
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
    End If
   Case -1 'no supporter
    If tPoly.bCustomShapeEnabled Then
     b = tPoly.nCustomShape(cii, cjj, ckk)
    Else
     b = True
    End If
    If b Then
     If j = 1 Then bFirstEmpty = True
     If ret.nTiltY = 0 Then '????????
      If (m_tLogic.nFlags And &H8&) = 0 Then
       If nState > 0 Then nState = -1 '???
 '     ElseIf tPoly.nStabilityCount > 0 Then 'custom stability support (experimental) TODO:
 '      'TODO:
      Else
       If x + y <= 3 Then '1x1 or 1x2 or 2x1
        If nState > 0 Then nState = -1
       ElseIf x + y = 4 Then
        '!!!!!!!!TEST ONLY
        Dim kkk As Long
        If x = 2 Then '2x2
         If m_tLogic.nFlags And &H80& Then
          If kkk Then
           If (i Xor j Xor kkk) And 1& Then
            If nState > 0 Then nState = -1
           End If
          Else
           kkk = ((i Xor j) And 1&) Or 2&
          End If
         Else
          kkk = kkk + 1
          If kkk > 1 Then
           If nState > 0 Then nState = -1
          End If
         End If
        Else '1x3 or 3x1
         If m_tLogic.nFlags And &H80& Then
          If i <> 2 And j <> 2 Then
           If nState > 0 Then nState = -1
          End If
         Else
          If nState > 0 Then nState = -1 '???
         End If
        End If
        '!!!!!!!!
       Else
        'TODO:
        Debug.Assert False
       End If
      End If
     End If
    End If
   Case &H80000000 To &H8001FFFF 'block tiltable AND block not tiltable
    If tPoly.bCustomShapeEnabled Then
     b = False
     tmp = tHitTest.nType And &HFFFF&
     For k = 0 To z - 1
      '///
      If k >= tmp Then Exit For
      If tPoly.nCustomShape(cii, cjj, ckk) Then
       b = True
       Exit For
      End If
      '///
      cii = cii + czi
      cjj = cjj + czj
      ckk = ckk + czk
     Next k
     cii = cii - k * czi
     cjj = cjj - k * czj
     ckk = ckk - k * czk
    Else
     b = True
    End If
    If b Then
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
    End If
   Case Else
    'error???
    Debug.Assert False
    Exit Sub
   End Select
   '///
   If tPoly.bCustomShapeEnabled Then
    cii = cii + cxi
    cjj = cjj + cxj
    ckk = ckk + cxk
   End If
   '///
  Next i
  '///
  If tPoly.bCustomShapeEnabled Then
   ci = ci + cyi
   cj = cj + cyj
   ck = ck + cyk
  End If
  '///
 Next j
 '///custom stability support (experimental) TODO:
 If nState = 1 And ret.nTiltY = 0 Then
  For i = 1 To tPoly.nStabilityCount
   If tPoly.tStability(i).nFaceIndexMask And nMask(tPos.nGroundFaceIndex) Then
    'TODO:
    nState = tPoly.tStability(i).nValue
    Exit For
   End If
  Next i
 End If
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
Friend Function Move(ByVal nDirection As Long, ByRef tPoly As typeMapData_Polyhedron, Optional ByVal bAllowFalling As Boolean, Optional ByVal nUndoIndex As Long = -1) As Long
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
 CheckPolyhedronStateEx tPos, tState, True, False, tPoly
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
 CheckPolyhedronStateEx tPos, tState, True, False, tPoly
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
 '///new:undo
 If nUndoIndex >= 0 Then objGameMgr.AddUndoIndex nUndoIndex
 '///
 m_bUndoDirty = True
 '///
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
 SendEventEx EventTypeOnLeave, m_tOldState, m_tOldPos
 SendEventEx EventTypeOnMoveLeave, m_tOldState, m_tOldPos
 '///
 Move = (m_tState.nState <> 0) And 1& '??
End If
End Function

Friend Sub SendEvent(ByVal nEventType As Long, Optional ByVal IsOld As Boolean)
If IsOld Then
 SendEventEx nEventType, m_tOldState, m_tOldPos
Else
 SendEventEx nEventType, m_tState, m_tPos
End If
End Sub

Friend Sub SendEventEx(ByVal nEventType As Long, ByRef tState As typePolyhedronState, ByRef tPos As typePolyhedronPosition)
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
  '///new: polyhedron event
  Select Case nEventType
  Case EventTypeOnEnter, EventTypeOnLeave, EventTypeOnMoveEnter, EventTypeOnMoveLeave, EventTypeOnPressKey
   tEvent.nEventType = nEventType Or &H1000000
   tEvent.p = tPos.p
   tEvent.nFirstEdgeIndex = tPos.nFirstEdgeIndex
   tEvent.nGroundFaceIndex = tPos.nGroundFaceIndex
   tEvent.nGroundEdgeIndex = tPos.nGroundEdgeIndex
   tEvent.tOnGroundPos = tState.tOnGroundPos
   tEvent.nTileTypes = tState.nTileTypes
   tEvent.nObjTypes = tState.nObjTypes
   objGameMgr.AddMapEvent tEvent
  End Select
 End If
End If
End Sub
