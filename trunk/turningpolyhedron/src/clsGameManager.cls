VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsGameManager"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)

Private Const m_fAnimTime As Single = 250 'TODO:different time for different animation

'////////object type data

Private m_tObjType() As typeObjectType
Private m_nObjTypeCount As Long, m_nObjTypeMax As Long

Private m_nObjInteraction() As Long '0 to nInteractionCount,0 to nInteractionCount; 0="default"
Private m_bObjInteractionDirty As Boolean

'////////tile type data

Private Const m_nTileTypeCount_Max As Long = 1024&

Private m_tTileType() As typeTileType
Private m_nTileTypeCount As Long 'fixed index, start with 1 (this is not count, but just max index)
Private m_nTileTypeCount2 As Long 'dynamic index, start with m_nTileTypeCount_Max+1
Private m_nTileTypeMax As Long '=UBound(m_tTileType)

'////////tile mapping data

Private m_nTileTypeMap(1 To m_nTileTypeCount_Max) As Long

'////////level data (TEST ONLY)

Private m_bIsRuntime As Boolean

Private m_tLevel As typeLevelData

Private m_tMapDataInst() As typeMapDataRuntime '1 to map data count
Private m_tTileAnim() As typeCustomTileAnimation '1-based
Private m_nTileAnimMax As Long, m_nTileAnimFirstUnused As Long
Private m_tLevelInst As typeMeshInstanceCollection

Private m_objPoly() As New clsPolyhedron '1 to polyhedron count
Private m_tPolyInst() As typePolyhedronInstance '1 to polyhedron count

Private m_nCurrentPolyhedron As Long

Private m_bRuntimeDirty As Boolean

Private m_tEvent() As typeMapDataEvent '0-based
Private m_nEventStart As Long, m_nEventEnd As Long, m_nEventMax As Long
Private m_bPolyhedronDirty As Boolean

'////////game logic settings

Private m_bAutoReset As Boolean, m_bReset As Boolean

'////////render settings

Private m_bFollowPolyhedron As Boolean

Friend Property Get AutoReset() As Boolean
AutoReset = m_bAutoReset
End Property

Friend Property Let AutoReset(ByVal b As Boolean)
m_bAutoReset = b
End Property

Friend Property Get ResetOnNextUpdate() As Boolean
ResetOnNextUpdate = m_bReset
End Property

Friend Property Let ResetOnNextUpdate(ByVal b As Boolean)
m_bReset = b
End Property

Friend Property Get CurrentPolyhedron() As Long
CurrentPolyhedron = m_nCurrentPolyhedron
End Property

Friend Property Let CurrentPolyhedron(ByVal n As Long)
m_nCurrentPolyhedron = n
End Property

Friend Property Get FollowCurrentPolyhedron() As Boolean
FollowCurrentPolyhedron = m_bFollowPolyhedron
End Property

Friend Property Let FollowCurrentPolyhedron(ByVal b As Boolean)
m_bFollowPolyhedron = b
End Property

Friend Property Get PolyhedronCount() As Long
PolyhedronCount = m_tLevel.nPolyhedronCount
End Property

Friend Property Get CurrentPolyhedronObject() As clsPolyhedron
Set CurrentPolyhedronObject = PolyhedronObject(m_nCurrentPolyhedron)
End Property

Friend Property Get PolyhedronObject(ByVal nPolyhedronIndex As Long) As clsPolyhedron
If m_bRuntimeDirty Then Exit Property
If nPolyhedronIndex > 0 And nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then _
Set PolyhedronObject = m_objPoly(nPolyhedronIndex)
End Property

Friend Property Get IsCurrentPolyhedronMoving() As Boolean
IsCurrentPolyhedronMoving = IsPolyhedronMoving(m_nCurrentPolyhedron)
End Property

Friend Property Get IsPolyhedronMoving(ByVal nPolyhedronIndex As Long) As Boolean
If m_bRuntimeDirty Then Exit Property
If nPolyhedronIndex > 0 And nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then _
IsPolyhedronMoving = m_tPolyInst(nPolyhedronIndex).nAnimType <> 0
End Property

Friend Property Get IsPolyhedronVisible(ByVal nPolyhedronIndex As Long) As Boolean
If m_bRuntimeDirty Then Exit Property
If nPolyhedronIndex > 0 And nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then _
IsPolyhedronVisible = m_tPolyInst(nPolyhedronIndex).nFlags And &H100&
End Property

Friend Function MoveCurrentPolyhedron(ByVal nDirection As Long) As Long
MoveCurrentPolyhedron = MovePolyhedron(m_nCurrentPolyhedron, nDirection)
End Function

Friend Function MovePolyhedron(ByVal nPolyhedronIndex As Long, ByVal nDirection As Long) As Long
If m_bRuntimeDirty Then Exit Function
If nPolyhedronIndex > 0 And nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
 If m_tPolyInst(nPolyhedronIndex).nFlags And &H100& Then
  MovePolyhedron = m_objPoly(nPolyhedronIndex).Move(nDirection)
 End If
End If
End Function

Friend Sub StartTileAnimation(ByVal nInstIndex As Long, ByVal nType As Long)
Dim i As Long
Dim t As typeCustomTileAnimation
If nInstIndex > 0 Then
 i = GetEmptyTileAnimation
 t.nInstIndex = nInstIndex
 t.nAnimType = nType
 t.matWorld = m_tLevelInst.tInstance(nInstIndex).matWorld '???
 m_tTileAnim(i) = t
End If
End Sub

'nCurrentState=state return by clsPolyhedron::CheckPolyhedronStateEx
'///TODO:more arguments
Friend Sub StartPolyhedronAnimation(ByVal nPolyhedronIndex As Long, ByVal nCurrentState As Long, ByVal nReserved1 As Long)
Dim t1 As typePolyhedronState
Dim t2 As typePolyhedronState
Dim b As Boolean
'///
Select Case nCurrentState
Case 0 'not moveable
Case 1 'moveable
 If nReserved1 And 7& Then
  '???????? TODO:(nReserved1) tilt animation
  StartPolyhedronAnimationByType nPolyhedronIndex, (nReserved1 And 7&) Or 8&
  If nReserved1 And 4& Then
   t1 = m_objPoly(nPolyhedronIndex).PolyhedronState(True)
   t2 = m_objPoly(nPolyhedronIndex).PolyhedronState
   t2.nTiltY = t2.nTiltY * t1.nTiltX - t1.nTiltY * t2.nTiltX
   Debug.Assert t2.nTiltY <= 0
   If t2.nTiltY < 0 Then _
   SetPolyhedronAnimationStack4 nPolyhedronIndex, (nReserved1 And 6&) Or 8&
  Else 'fall to ground
   SetPolyhedronAnimationStack4 nPolyhedronIndex, (nReserved1 And 6&) Or 8&
  End If
 Else
  StartPolyhedronAnimationByType nPolyhedronIndex, 1
  SetPolyhedronAnimationStack4 nPolyhedronIndex
 End If
Case -1 'falling
 StartPolyhedronAnimationByType nPolyhedronIndex, -1
Case Else
 Debug.Assert False
End Select
End Sub

'internal function
Friend Sub StartPolyhedronAnimationByStack(ByVal nPolyhedronIndex As Long)
Dim i As Long
i = m_tPolyInst(nPolyhedronIndex).nAnimStackIndex
If i > 0 Then
 i = i - 1
 m_tPolyInst(nPolyhedronIndex).nAnimStackIndex = i
 i = m_tPolyInst(nPolyhedronIndex).nAnimStack(i)
End If
StartPolyhedronAnimationByType nPolyhedronIndex, i
End Sub

'internal function
'TODO:check animation type
Friend Sub StartPolyhedronAnimationByType(ByVal nPolyhedronIndex As Long, ByVal nType As Long)
Erase m_tPolyInst(nPolyhedronIndex).fAnimValue
m_tPolyInst(nPolyhedronIndex).nAnimType = nType
End Sub

'internal function
Friend Sub SetPolyhedronAnimationStack4(ByVal nPolyhedronIndex As Long, Optional ByVal a0 As Long, Optional ByVal a1 As Long, Optional ByVal a2 As Long, Optional ByVal a3 As Long)
If a0 = 0 Then
 m_tPolyInst(nPolyhedronIndex).nAnimStackIndex = 0
Else
 m_tPolyInst(nPolyhedronIndex).nAnimStack(0) = a0
 If a1 = 0 Then
  m_tPolyInst(nPolyhedronIndex).nAnimStackIndex = 1
 Else
  m_tPolyInst(nPolyhedronIndex).nAnimStack(1) = a1
  If a2 = 0 Then
   m_tPolyInst(nPolyhedronIndex).nAnimStackIndex = 2
  Else
   m_tPolyInst(nPolyhedronIndex).nAnimStack(2) = a2
   If a3 = 0 Then
    m_tPolyInst(nPolyhedronIndex).nAnimStackIndex = 3
   Else
    m_tPolyInst(nPolyhedronIndex).nAnimStackIndex = 4
    m_tPolyInst(nPolyhedronIndex).nAnimStack(3) = a3
   End If
  End If
 End If
End If
End Sub

Friend Function GetPolyhedronCenterPos(ByVal nPolyhedronIndex As Long) As D3DVECTOR
If m_bRuntimeDirty Then Exit Function
If nPolyhedronIndex > 0 And nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
 GetPolyhedronCenterPos = m_tPolyInst(nPolyhedronIndex).vCenter
End If
End Function

Friend Sub UpdateLevelRuntimeData(ByVal dt As Single)
Dim idx As Long
Dim f As Single, f2 As Single
Dim mat As D3DMATRIX, mat1 As D3DMATRIX
Dim vBase As D3DVECTOR, vNormal As D3DVECTOR, vAxis As D3DVECTOR
Dim v As D3DVECTOR, v2 As D3DVECTOR
Dim i As Long, j As Long, k As Long
Dim p As typePolyhedronPosition
Dim nAnimType As Long
'///
If m_bRuntimeDirty Then Exit Sub
'////////reset?
If m_bReset Then
 CreateLevelRuntimeData m_bIsRuntime
 m_bReset = False
End If
'////////update animation
'///polyhedron animation
For idx = 1 To m_tLevel.nPolyhedronCount
 If m_tPolyInst(idx).nFlags And &H100& Then
  nAnimType = m_tPolyInst(idx).nAnimType
  Select Case nAnimType
  Case 1, &H8& To &HF& 'rolling
   f = m_tPolyInst(idx).fAnimValue(0) + dt
   If f > m_fAnimTime Then
    StartPolyhedronAnimationByStack idx
    If nAnimType = 1 Or (nAnimType And 1&) = 0 Then
     m_bPolyhedronDirty = True
     m_objPoly(idx).SendEvent EventTypeOnEnter
     m_objPoly(idx).SendEvent EventTypeOnMoveEnter
    End If
   Else
    m_tPolyInst(idx).fAnimValue(0) = f
   End If
  Case -1 'falling
   f = m_tPolyInst(idx).fAnimValue(0) + dt
   If f > 3000 Then
    f = 3000
    'TODO:if discardable=true then don't reset
    If m_bAutoReset Then m_bReset = True
   End If
   m_tPolyInst(idx).fAnimValue(0) = f
  End Select
 End If
Next idx
'////////update event (?)
ProcessMapEvents
'///tile animation
For idx = 1 To m_nTileAnimMax
 i = m_tTileAnim(idx).nInstIndex
 If i > 0 Then
  f = m_tTileAnim(idx).fAnimValue(0) + dt
  Select Case m_tTileAnim(idx).nAnimType
  Case 1 'fade out TODO:
   If f > m_fAnimTime Then
    RemoveTileAnimation idx, True
   Else
    m_tTileAnim(idx).fAnimValue(0) = f
    mat = m_tTileAnim(idx).matWorld
    f = f / m_fAnimTime
    f = 1 / (1.01 - f * f) - 1
    mat.m43 = mat.m43 - f
    m_tLevelInst.tInstance(i).matWorld = mat
   End If
  Case 2 'fade in TODO:
   If f > m_fAnimTime Then
    m_tLevelInst.tInstance(i).matWorld = m_tTileAnim(idx).matWorld
    RemoveTileAnimation idx, False
   Else
    m_tTileAnim(idx).fAnimValue(0) = f
    mat = m_tTileAnim(idx).matWorld
    f = 1 - f / m_fAnimTime
    f = 1 / (1.01 - f * f) - 1
    mat.m43 = mat.m43 - f
    m_tLevelInst.tInstance(i).matWorld = mat
   End If
  Case -1 'falling
   If f > 3000 Then
    RemoveTileAnimation idx, True
   Else
    m_tTileAnim(idx).fAnimValue(0) = f
    mat = m_tTileAnim(idx).matWorld
    f = f / 190
    mat.m43 = mat.m43 - f * f
    m_tLevelInst.tInstance(i).matWorld = mat
   End If
  End Select
 End If
Next idx
'///TODO:other
'////////update position
'///setup polyhedron world matrix and center
'TODO:adjacency data
'TODO:animation: tilt angle, interpolation of mat1, interpolation of vAxis and vBase, etc. <== interpolation of vAxis IS WRONG
For idx = 1 To m_tLevel.nPolyhedronCount
 If m_tPolyInst(idx).nFlags And &H100& Then
  m_tPolyInst(idx).matWorld = D3DXMatrixIdentity
  p = m_objPoly(idx).Position
  If p.p.nMapDataIndex > 0 And p.p.nMapDataIndex <= m_tLevel.nMapDataCount Then
   Select Case m_tLevel.tPolyhedron(idx).nShape
   Case &H111 To &HFFF
    nAnimType = m_tPolyInst(idx).nAnimType
    'm_objPoly(idx).GetCurrentSize i, j, k
    Select Case nAnimType
    Case &H8& To &HF&
     If nAnimType And 1& Then 'tilt rolling
      If nAnimType And 4& Then p.nGroundEdgeIndex = (p.nGroundEdgeIndex + (nAnimType And 2&) - 1) And 3&
      m_objPoly(idx).GetPolyhedronCoordinatesEx p, vBase, vNormal, vAxis
      If nAnimType And 2& Then '???????? FIXME: ugly dirty code
       p.nGroundEdgeIndex = (p.nGroundEdgeIndex - 1) And 3&
       m_objPoly(idx).GetPolyhedronCoordinatesEx p, vBase, Vec3, Vec3
       '///
       vAxis.x = -vAxis.x
       vAxis.y = -vAxis.y
       vAxis.z = -vAxis.z
       '///
       p = m_objPoly(idx).Position(True) '????????
       p.nGroundEdgeIndex = (p.nGroundEdgeIndex - 1) And 3& '????????
      End If
     Else 'tilt falling
      If nAnimType And 4& Then
       m_objPoly(idx).GetPolyhedronCoordinatesEx p, vBase, vNormal, vAxis
       f = m_objPoly(idx).PolyhedronTiltTangent
      Else 'fall to ground
       p.nGroundEdgeIndex = (p.nGroundEdgeIndex + (nAnimType And 2&) + 1) And 3&
       m_objPoly(idx).GetPolyhedronCoordinatesEx p, vBase, vNormal, vAxis
       'f = m_objPoly(idx).PolyhedronTiltTangent
       f = 0 '???????? TODO:etc.
      End If
     End If
    Case Else
     'normal rolling
     m_objPoly(idx).GetPolyhedronCoordinatesEx p, vBase, vNormal, vAxis
     f = m_objPoly(idx).PolyhedronTiltTangent
     If f > 0.000001 Then
      D3DXVec3Normalize vNormal, D3DXVec3AddScale(vNormal, D3DXVec3Cross(vNormal, vAxis), f)
     End If
    End Select
    '///
    Select Case nAnimType
    Case 1 'rolling
     m_objPoly(idx).GetPolyhedronCoordinates Vec3, v, v2, True
     f = m_objPoly(idx).PolyhedronTiltTangent(True)
     If f > 0.000001 Then
      D3DXVec3Normalize v, D3DXVec3AddScale(v, D3DXVec3Cross(v, v2), f)
     End If
     f = m_tPolyInst(idx).fAnimValue(0) / m_fAnimTime
     D3DXVec3Normalize vNormal, D3DXVec3Lerp(v, vNormal, f)
    Case &H8& To &HF&
     If nAnimType And 1& Then 'tilt rolling
      m_objPoly(idx).GetPolyhedronCoordinates Vec3, v, Vec3, True
      f = m_tPolyInst(idx).fAnimValue(0) / m_fAnimTime
      D3DXVec3Normalize vNormal, D3DXVec3Lerp(v, vNormal, f)
      '///tilt rolling
      f = m_objPoly(idx).PolyhedronTiltTangent(True)
      If f > 0.000001 Then
       f2 = 1 / Sqr(1 + f * f) 'cos
       f = f * f2 'sin
       v = D3DXVec3Cross(vAxis, vNormal)
       '---
       v2.x = vNormal.x * f2 - vAxis.x * f
       v2.y = vNormal.y * f2 - vAxis.y * f
       v2.z = vNormal.z * f2 - vAxis.z * f
       '---
       vAxis.x = vAxis.x * f2 + vNormal.x * f
       vAxis.y = vAxis.y * f2 + vNormal.y * f
       vAxis.z = vAxis.z * f2 + vNormal.z * f
       '---
       vNormal = v2
      End If
     Else 'tilt falling
      'TODO:etc.
      f = f + (m_objPoly(idx).PolyhedronTiltTangent(True) - f) * (1 - m_tPolyInst(idx).fAnimValue(0) / m_fAnimTime)
      D3DXVec3Normalize vNormal, D3DXVec3AddScale(vNormal, D3DXVec3Cross(vNormal, vAxis), f)
     End If
    End Select
    '///
    v = D3DXVec3Cross(vAxis, vNormal)
    mat.m11 = vNormal.x
    mat.m12 = vNormal.y
    mat.m13 = vNormal.z
    mat.m21 = vAxis.x
    mat.m22 = vAxis.y
    mat.m23 = vAxis.z
    mat.m31 = v.x
    mat.m32 = v.y
    mat.m33 = v.z
    mat.m41 = vBase.x
    mat.m42 = vBase.y
    mat.m43 = vBase.z
    mat.m44 = 1
    D3DXMatrixInverse mat, 0, mat
    '///
    m_objPoly(idx).GetCurrentSizeEx p, i, j, k
    With m_tLevel.tMapData(p.p.nMapDataIndex)
     mat1.m11 = -.fPos(3).x
     mat1.m12 = -.fPos(3).y
     mat1.m13 = -.fPos(3).z
     Select Case (p.nGroundEdgeIndex - p.nFirstEdgeIndex) And 3&
     Case 0
      mat1.m21 = .fPos(1).x
      mat1.m22 = .fPos(1).y
      mat1.m23 = .fPos(1).z
      mat1.m31 = .fPos(2).x
      mat1.m32 = .fPos(2).y
      mat1.m33 = .fPos(2).z
      mat1.m41 = .fPos(0).x + p.p.x * .fPos(1).x + p.p.y * .fPos(2).x + p.p.z * .fPos(3).x
      mat1.m42 = .fPos(0).y + p.p.x * .fPos(1).y + p.p.y * .fPos(2).y + p.p.z * .fPos(3).y
      mat1.m43 = .fPos(0).z + p.p.x * .fPos(1).z + p.p.y * .fPos(2).z + p.p.z * .fPos(3).z
     Case 1
      mat1.m21 = -.fPos(2).x
      mat1.m22 = -.fPos(2).y
      mat1.m23 = -.fPos(2).z
      mat1.m31 = .fPos(1).x
      mat1.m32 = .fPos(1).y
      mat1.m33 = .fPos(1).z
      mat1.m41 = .fPos(0).x + p.p.x * .fPos(1).x + (p.p.y + j) * .fPos(2).x + p.p.z * .fPos(3).x
      mat1.m42 = .fPos(0).y + p.p.x * .fPos(1).y + (p.p.y + j) * .fPos(2).y + p.p.z * .fPos(3).y
      mat1.m43 = .fPos(0).z + p.p.x * .fPos(1).z + (p.p.y + j) * .fPos(2).z + p.p.z * .fPos(3).z
     Case 2
      mat1.m21 = -.fPos(1).x
      mat1.m22 = -.fPos(1).y
      mat1.m23 = -.fPos(1).z
      mat1.m31 = -.fPos(2).x
      mat1.m32 = -.fPos(2).y
      mat1.m33 = -.fPos(2).z
      mat1.m41 = .fPos(0).x + (p.p.x + i) * .fPos(1).x + (p.p.y + j) * .fPos(2).x + p.p.z * .fPos(3).x
      mat1.m42 = .fPos(0).y + (p.p.x + i) * .fPos(1).y + (p.p.y + j) * .fPos(2).y + p.p.z * .fPos(3).y
      mat1.m43 = .fPos(0).z + (p.p.x + i) * .fPos(1).z + (p.p.y + j) * .fPos(2).z + p.p.z * .fPos(3).z
     Case 3
      mat1.m21 = .fPos(2).x
      mat1.m22 = .fPos(2).y
      mat1.m23 = .fPos(2).z
      mat1.m31 = -.fPos(1).x
      mat1.m32 = -.fPos(1).y
      mat1.m33 = -.fPos(1).z
      mat1.m41 = .fPos(0).x + (p.p.x + i) * .fPos(1).x + p.p.y * .fPos(2).x + p.p.z * .fPos(3).x
      mat1.m42 = .fPos(0).y + (p.p.x + i) * .fPos(1).y + p.p.y * .fPos(2).y + p.p.z * .fPos(3).y
      mat1.m43 = .fPos(0).z + (p.p.x + i) * .fPos(1).z + p.p.y * .fPos(2).z + p.p.z * .fPos(3).z
     End Select
     mat1.m44 = 1
    End With
    '///
    D3DXMatrixMultiply m_tPolyInst(idx).matWorld, mat, mat1
    '///get center pos
    m_objPoly(idx).GetSize i, j, k
    v.x = i / 2
    v.y = j / 2
    v.z = k / 2
    D3DXVec3TransformCoord m_tPolyInst(idx).vCenter, v, m_tPolyInst(idx).matWorld
    '///
    Select Case nAnimType
    Case -1 'falling
     f = m_tPolyInst(idx).fAnimValue(0) / 200
     f = f * f
     m_tPolyInst(idx).matWorld.m43 = m_tPolyInst(idx).matWorld.m43 - f
     'f = f / (1 + 0.01 * f)
     m_tPolyInst(idx).vCenter.z = m_tPolyInst(idx).vCenter.z - f
    End Select
   Case Else
    Debug.Assert False
   End Select
  End If
  i = m_tPolyInst(idx).nInstIndex
  If i > 0 Then
   'TODO:multiple objects
   m_tLevelInst.tInstance(i).Visible = True
   m_tLevelInst.tInstance(i).matWorld = m_tPolyInst(idx).matWorld
  End If
 Else
  'invisible
  i = m_tPolyInst(idx).nInstIndex
  If i > 0 Then
   'TODO:multiple objects
   m_tLevelInst.tInstance(i).Visible = False
   m_tLevelInst.tInstance(i).matWorld = m_tPolyInst(idx).matWorld
  End If
 End If
Next idx
'///follow polyhedron?
If m_bFollowPolyhedron Then
 If m_nCurrentPolyhedron > 0 And m_nCurrentPolyhedron <= m_tLevel.nPolyhedronCount Then
  objCamera.MoveTargetTo m_tPolyInst(m_nCurrentPolyhedron).vCenter
 End If
End If
'///
End Sub

Friend Sub DrawLevel()
Dim idx As Long
Dim f(31) As Single
Dim d(23) As Integer
Dim i As Long, j As Long, k As Long, l As Long
Dim tmp As Long
'///
If m_bRuntimeDirty Then Exit Sub
If m_tLevel.nPolyhedronCount <= 0 Then Exit Sub
'///draw level
objEffectMgr.DrawInstanceEx m_tLevelInst, True, True
'///TEST ONLY
'///draw polyhedron which doesn't have appearance
d(0) = 0: d(1) = 1: d(2) = 1: d(3) = 3: d(4) = 3: d(5) = 2: d(6) = 2: d(7) = 0
d(8) = 4: d(9) = 5: d(10) = 5: d(11) = 7: d(12) = 7: d(13) = 6: d(14) = 6: d(15) = 4
d(16) = 0: d(17) = 4: d(18) = 1: d(19) = 5: d(20) = 2: d(21) = 6: d(22) = 3: d(23) = 7
f(3) = LongToSingle(&HFFFFFF)
For i = 1 To 7
 f(i * 4 + 3) = f(3)
Next i
'///
tmp = d3dd9.GetTextureStageState(0, D3DTSS_COLOROP)
d3dd9.SetTextureStageState 0, D3DTSS_COLOROP, D3DTOP_SELECTARG2
d3dd9.SetFVF D3DFVF_XYZ Or D3DFVF_DIFFUSE
'///
For idx = 1 To m_tLevel.nPolyhedronCount
 If m_tPolyInst(idx).nInstIndex = 0 And (m_tPolyInst(idx).nFlags And &H100&) <> 0 Then
  '///TEST ONLY
  '///assume it's cuboid
  m_objPoly(idx).GetSize i, j, k
  With m_tPolyInst(idx).matWorld
   For l = 0 To 7
    f(l * 4) = .m41 + _
    (i * (l And 1&)) * .m11 + _
    (j * ((l \ 2&) And 1&)) * .m21 + _
    (k * ((l \ 4&) And 1&)) * .m31
    f(l * 4 + 1) = .m42 + _
    (i * (l And 1&)) * .m12 + _
    (j * ((l \ 2&) And 1&)) * .m22 + _
    (k * ((l \ 4&) And 1&)) * .m32
    f(l * 4 + 2) = .m43 + _
    (i * (l And 1&)) * .m13 + _
    (j * ((l \ 2&) And 1&)) * .m23 + _
    (k * ((l \ 4&) And 1&)) * .m33
   Next l
  End With
  '///
  d3dd9.DrawIndexedPrimitiveUP D3DPT_LINELIST, 0, 8, 12, d(0), D3DFMT_INDEX16, f(0), 16&
  '///
 End If
Next idx
'///
d3dd9.SetTextureStageState 0, D3DTSS_COLOROP, tmp
'///
End Sub

Friend Property Get IsRuntime() As Boolean
IsRuntime = m_bIsRuntime
End Property

Friend Function CreateLevelRuntimeData(Optional ByVal bRuntime As Boolean = True) As Boolean
Dim i As Long, idx As Long
'///
ClearLevelRuntimeData
'///
m_bIsRuntime = bRuntime
m_bPolyhedronDirty = False
If Not GenerateMeshFromLevelDataEx(m_tLevel, m_tMapDataInst, m_tLevelInst, bRuntime) Then Exit Function
'///
If m_tLevel.nPolyhedronCount > 0 Then
 ReDim m_objPoly(1 To m_tLevel.nPolyhedronCount)
 ReDim m_tPolyInst(1 To m_tLevel.nPolyhedronCount)
 For i = 1 To m_tLevel.nPolyhedronCount
  If Not m_objPoly(i).CreateIndirect(m_tLevel, i) Then Exit Function
  '///
  idx = m_tLevel.tPolyhedron(i).nApprIndex
  If idx > 0 Then m_tPolyInst(i).nInstIndex = _
  objEffectMgr.AddInstanceFromAppearanceEx(m_tLevelInst, idx, D3DXMatrixIdentity)
  m_tPolyInst(i).nFlags = m_tLevel.tPolyhedron(i).nFlags
 Next i
 '///
 For i = 1 To m_tLevel.nPolyhedronCount
  If m_tPolyInst(i).nFlags And &H100& Then m_objPoly(i).CheckPolyhedronStateAndResponse
 Next i
 '///
 For i = 1 To m_tLevel.nPolyhedronCount
  If m_tPolyInst(i).nFlags And &H100& Then m_objPoly(i).SendEvent EventTypeOnEnter
 Next i
 '///set current polyhedron to the first one
 m_nCurrentPolyhedron = 1
End If
'///
ProcessMapEvents
'///
m_bRuntimeDirty = False
CreateLevelRuntimeData = True
End Function

Friend Sub ClearLevelRuntimeData()
Dim t As typeMeshInstanceCollection
'///
Erase m_objPoly
Erase m_tPolyInst
Erase m_tEvent
Erase m_tMapDataInst
Erase m_tTileAnim
m_tLevelInst = t
m_nCurrentPolyhedron = 0
m_nEventStart = 0
m_nEventEnd = 0
m_nEventMax = 0
m_bPolyhedronDirty = False
m_nTileAnimMax = 0
m_nTileAnimFirstUnused = 0
'///
m_bRuntimeDirty = True
End Sub

'internal
Friend Function GetEmptyTileAnimation() As Long
Dim i As Long, m As Long
If m_nTileAnimFirstUnused = 0 Then
 m = m_nTileAnimMax + 16
 ReDim Preserve m_tTileAnim(1 To m)
 For i = m_nTileAnimMax + 2 To m - 1
  m_tTileAnim(i).nInstIndex = &H80000000 Or (i + 1)
 Next i
 GetEmptyTileAnimation = m_nTileAnimMax + 1
 m_nTileAnimMax = m
Else
 GetEmptyTileAnimation = m_nTileAnimFirstUnused
 m_nTileAnimFirstUnused = m_tTileAnim(m_nTileAnimFirstUnused).nInstIndex And &H7FFFFFFF
End If
End Function

'internal
Friend Sub RemoveTileAnimation(ByVal nIndex As Long, ByVal bRemoveInstance As Boolean)
Dim t As typeCustomTileAnimation
If nIndex > 0 And nIndex <= m_nTileAnimMax Then
 If m_tTileAnim(nIndex).nInstIndex > 0 Then
  If bRemoveInstance Then
   objEffectMgr.RemoveInstanceEx m_tLevelInst, m_tTileAnim(nIndex).nInstIndex
  End If
  t.nInstIndex = &H80000000 Or m_nTileAnimFirstUnused
  m_tTileAnim(nIndex) = t
  m_nTileAnimFirstUnused = nIndex
 End If
End If
End Sub

Friend Sub ClearLevelData()
Dim t As typeLevelData
Dim i As Long
m_tLevel = t
'reset dynamic-mapped tile index
Erase m_nTileTypeMap
'reset runtime
ClearLevelRuntimeData
'///
m_bRuntimeDirty = False
End Sub

Friend Sub ClearTileMapData()
Erase m_nTileTypeMap
End Sub

Friend Property Get TileMapData(ByVal nIndex As Long) As Long
TileMapData = m_nTileTypeMap(nIndex)
End Property

Friend Property Let TileMapData(ByVal nIndex As Long, ByVal n As Long)
m_nTileTypeMap(nIndex) = n
End Property

Friend Function AddLevelDataFromNode(ByVal objNode As clsTreeStorageNode) As Boolean
AddLevelDataFromNode = AddLevelDataFromNodeEx(objNode, m_tLevel)
m_bRuntimeDirty = True
End Function

Friend Function ParseTileTypeFromString(ByVal s As String) As Long
Dim nIndex As Long
Dim lps As Long
'///
ParseTileTypeFromString = -1
'///
If IsNumeric(s) Then
 nIndex = Val(s)
 If nIndex > m_nTileTypeCount_Max Then 'out of range?
  For lps = m_nTileTypeCount_Max + 1 To m_nTileTypeCount_Max + m_nTileTypeCount2
   If m_tTileType(lps).nIndex = nIndex Then
    nIndex = lps
    Exit For
   End If
  Next lps
 ElseIf nIndex > 0 Then
  If nIndex <> m_tTileType(nIndex).nIndex Then 'invalid index
   Debug.Assert False
   Exit Function
  End If
 ElseIf nIndex < 0 And nIndex >= -m_nTileTypeCount_Max Then 'use dynamic mapping index?
  nIndex = m_nTileTypeMap(-nIndex)
  If nIndex <= 0 Then 'invalid index
   Debug.Assert False
   Exit Function
  End If
 End If
ElseIf s <> "" Then
 For lps = 1 To m_nTileTypeCount
  If m_tTileType(lps).nIndex > 0 Then
   If m_tTileType(lps).sID = s Then
    nIndex = lps
    Exit For
   End If
  End If
 Next lps
 If nIndex = 0 Then
  For lps = m_nTileTypeCount_Max + 1 To m_nTileTypeCount_Max + m_nTileTypeCount2
   If m_tTileType(lps).sID = s Then
    nIndex = lps
    Exit For
   End If
  Next lps
 End If
 If nIndex = 0 Then 'not found
  Debug.Assert False
  Exit Function
 End If
End If
ParseTileTypeFromString = nIndex
End Function

Friend Function ParseMapTypeArrayFromNode(ByVal objNode As clsTreeStorageNode, ByRef tMap As typeMapData) As Boolean
Dim s As String
Dim b As Boolean
Dim d() As Integer, lp As Long, lps As Long, m As Long
Dim C As Long
Dim i As Long, j As Long, k As Long
'///
Dim nIndex As Long
Dim sID As String
Dim nNewIndex As Long
Dim nPropertyIndex As Long
Dim sTag As String
Dim nCount As Long
'///
s = Replace(Replace(Replace(Replace(objNode.GetValueAsString, _
vbCr, ""), vbLf, ""), vbTab, ""), " ", "")
m = Len(s)
If m > 0 Then
 ReDim d(m - 1)
 CopyMemory d(0), ByVal StrPtr(s), m * 2&
 '///format: [<index>|<id>[@<new_index>]]["["<property_index>|<tag>"]"]["*"<count>]
 Do
  nIndex = 0
  sID = ""
  nNewIndex = 0
  nPropertyIndex = 0
  sTag = ""
  nCount = 1
  '///get [<index>|<id>]
  lps = lp
  b = True
  Do While lp < m
   C = d(lp)
   Select Case C
   Case 44, 59, 124, 64, 91, 42
    Exit Do
   End Select
   b = b And ((C >= &H30& And C <= &H39&) Or C = 45)
   lp = lp + 1
  Loop
  If lp > lps Then
   sID = Space(lp - lps)
   CopyMemory ByVal StrPtr(sID), d(lps), (lp - lps) * 2&
   If b Then
    nIndex = Val(sID)
    sID = ""
   End If
  End If
  '///get [@<new_index>]
  If C = 64 Then
   lp = lp + 1
   lps = lp
   Do While lp < m
    C = d(lp)
    Select Case C
    Case 44, 59, 124, 91, 42
     Exit Do
    End Select
    lp = lp + 1
   Loop
   If lp > lps Then
    s = Space(lp - lps)
    CopyMemory ByVal StrPtr(s), d(lps), (lp - lps) * 2&
    nNewIndex = Val(s)
   End If
  End If
  '///get ["["<property_index>|<tag>"]"]
  If C = 91 Then
   lp = lp + 1
   lps = lp
   b = True
   Do While lp < m
    C = d(lp)
    If C = 93 Then Exit Do
    b = b And (C >= &H30& And C <= &H39&)
    lp = lp + 1
   Loop
   If lp > lps Then
    sTag = Space(lp - lps)
    CopyMemory ByVal StrPtr(sTag), d(lps), (lp - lps) * 2&
    If b Then
     nPropertyIndex = Val(sTag)
     If nPropertyIndex > 0 Then sTag = "" Else nPropertyIndex = 0
    End If
   End If
   lp = lp + 1
   If lp < m Then C = d(lp)
  End If
  '///get ["*"<count>]
  If C = 42 Then
   lp = lp + 1
   lps = lp
   Do While lp < m
    C = d(lp)
    Select Case C
    Case 44, 59, 124
     Exit Do
    End Select
    lp = lp + 1
   Loop
   If lp > lps Then
    s = Space(lp - lps)
    CopyMemory ByVal StrPtr(s), d(lps), (lp - lps) * 2&
    nCount = Val(s)
    If nCount <= 0 Then 'invalid count
     Debug.Assert False
     Exit Function
    End If
   End If
  End If
  '///
  If nIndex > m_nTileTypeCount_Max Then 'out of range?
   For lps = m_nTileTypeCount_Max + 1 To m_nTileTypeCount_Max + m_nTileTypeCount2
    If m_tTileType(lps).nIndex = nIndex Then
     nIndex = lps
     Exit For
    End If
   Next lps
  ElseIf nIndex > 0 Then
   If nIndex <> m_tTileType(nIndex).nIndex Then 'invalid index
    Debug.Assert False
    Exit Function
   End If
  ElseIf nIndex < 0 And nIndex >= -m_nTileTypeCount_Max Then 'use dynamic mapping index?
   nIndex = m_nTileTypeMap(-nIndex)
   If nIndex <= 0 Then 'invalid index
    Debug.Assert False
    Exit Function
   End If
  End If
  'find tile named with sID? TODO:use a collection to look up
  If sID <> "" Then
   For lps = 1 To m_nTileTypeCount
    If m_tTileType(lps).nIndex > 0 Then
     If m_tTileType(lps).sID = sID Then
      nIndex = lps
      Exit For
     End If
    End If
   Next lps
   If nIndex = 0 Then
    For lps = m_nTileTypeCount_Max + 1 To m_nTileTypeCount_Max + m_nTileTypeCount2
     If m_tTileType(lps).sID = sID Then
      nIndex = lps
      Exit For
     End If
    Next lps
   End If
   If nIndex = 0 Then 'not found
    Debug.Assert False
    Exit Function
   End If
  End If
  'create dynamic mapping index?
  If nNewIndex < 0 And nNewIndex >= -m_nTileTypeCount_Max Then
   m_nTileTypeMap(-nNewIndex) = nIndex
  End If
  '///put data
  For lps = 1 To nCount
   tMap.nTypeArray(i, j, k) = nIndex
   tMap.sTagArray(i, j, k) = sTag
   tMap.nPropertyArray(i, j, k) = nPropertyIndex
   'next pos
   If lps < nCount Then
    i = i + 1
    If i >= tMap.nSize(0) Then
     i = 0
     j = j + 1
     If j >= tMap.nSize(1) Then
      j = 0
      k = k + 1
      If k >= tMap.nSize(2) Then Exit Do
     End If
    End If
   End If
  Next lps
  '///
  If lp >= m Then C = 44
  Select Case C
  Case 44 '[","]
   'next pos
   i = i + 1
   If i >= tMap.nSize(0) Then
    i = 0
    j = j + 1
    If j >= tMap.nSize(1) Then
     j = 0
     k = k + 1
     If k >= tMap.nSize(2) Then Exit Do
    End If
   End If
  Case 59 '[";"]
   'next row
   i = 0
   j = j + 1
   If j >= tMap.nSize(1) Then
    j = 0
    k = k + 1
    If k >= tMap.nSize(2) Then Exit Do
   End If
  Case 124 '["|"]
   'next plane
   i = 0
   j = 0
   k = k + 1
   If k >= tMap.nSize(2) Then Exit Do
  Case Else 'invalid character
   Debug.Assert False
   Exit Function
  End Select
  '///over
  lp = lp + 1
 Loop While lp < m
 '///
End If
'///
ParseMapTypeArrayFromNode = True
End Function

Friend Function ParseMapDataFromNode(ByVal objNode As clsTreeStorageNode, ByRef tLevel As typeLevelData, ByVal nIndex As Long) As Boolean
Dim i As Long, j As Long, k As Long, m As Long
Dim v As Variant
Dim s As String
Dim nFlags As Long
Dim obj As clsTreeStorageNode
Dim obj1 As clsTreeStorageNode
'///
tLevel.tMapData(nIndex).fScale.x = 1
tLevel.tMapData(nIndex).fScale.y = 1
tLevel.tMapData(nIndex).fScale.z = 1
tLevel.tMapData(nIndex).fStep.x = 1
tLevel.tMapData(nIndex).fStep.y = 1
tLevel.tMapData(nIndex).fStep.z = 1
tLevel.tMapData(nIndex).fPos(1).x = 1
tLevel.tMapData(nIndex).fPos(2).y = 1
tLevel.tMapData(nIndex).fPos(3).z = 1
'///
nFlags = tLevel.tMapData(nIndex).nFlags
ReDim tLevel.tMapData(nIndex).nTypeArray(0, 0, 0)
ReDim tLevel.tMapData(nIndex).sTagArray(0, 0, 0)
ReDim tLevel.tMapData(nIndex).nPropertyArray(0, 0, 0)
'///
For i = 1 To objNode.SubNodeCount
 If objNode.SubNodeType(i) = 0 Then
  s = objNode.GetSubNodeNameAsString(i)
  Select Case s
  Case "id"
   'TODO:check duplicated ID
   tLevel.tMapData(nIndex).sID = objNode.GetSubNodeValueAsString(i)
  Case "shape"
   s = objNode.GetSubNodeValueAsString(i)
   Select Case s
   Case "rect"
    j = 0
   Case Else 'currently unsupported TODO:
    Debug.Assert False
    Exit Function
   End Select
   nFlags = (nFlags And &HFFFFFFF0) Or j
  Case "size"
   nFlags = nFlags Or &H10&
   v = Split(Trim(objNode.GetSubNodeValueAsString(i)), ",")
   m = UBound(v)
   If m >= 0 Then
    For j = 0 To m
     If j > 2 Then Exit For
     k = Val(v(j))
     If k <= 0 Then
      nFlags = nFlags And Not &H10&
      Exit For
     End If
     tLevel.tMapData(nIndex).nSize(j) = k
    Next j
    For j = m + 1 To 2
     tLevel.tMapData(nIndex).nSize(j) = 1
    Next j
   Else
    nFlags = nFlags And Not &H10&
   End If
   If nFlags And &H10& Then
    j = tLevel.tMapData(nIndex).nSize(0) - 1
    k = tLevel.tMapData(nIndex).nSize(1) - 1
    m = tLevel.tMapData(nIndex).nSize(2) - 1
    ReDim tLevel.tMapData(nIndex).nTypeArray(j, k, m)
    ReDim tLevel.tMapData(nIndex).sTagArray(j, k, m)
    ReDim tLevel.tMapData(nIndex).nPropertyArray(j, k, m)
   Else
    tLevel.tMapData(nIndex).nSize(0) = 1
    tLevel.tMapData(nIndex).nSize(1) = 1
    tLevel.tMapData(nIndex).nSize(2) = 1
   End If
  Case "p", "p1", "p2", "p3"
   If Not FakeDXUtilReadVec4(objNode.GetSubNodeValueAsString(i), tLevel.tMapData(nIndex).fPos(Val(Mid(s, 2)))) Then Exit Function
  Case "r"
   If Not FakeDXUtilReadVec4(objNode.GetSubNodeValueAsString(i), tLevel.tMapData(nIndex).fRotation) Then Exit Function
  Case "s"
   If Not FakeDXUtilReadVec4(objNode.GetSubNodeValueAsString(i), tLevel.tMapData(nIndex).fScale) Then Exit Function
  Case "c"
   If Not FakeDXUtilReadVec4(objNode.GetSubNodeValueAsString(i), tLevel.tMapData(nIndex).fCenter) Then Exit Function
  Case "step"
   If Not FakeDXUtilReadVec4(objNode.GetSubNodeValueAsString(i), tLevel.tMapData(nIndex).fStep) Then Exit Function
  End Select
 Else
  Set obj = objNode.SubNodeObject(i)
  Select Case obj.GetNameAsString
  Case "typeArray"
   If Not ParseMapTypeArrayFromNode(obj, tLevel.tMapData(nIndex)) Then
    Exit Function
   End If
  Case "property"
   m = Val(obj.GetSubNodeValueAsStringByName("index"))
   If m <= 0 Then 'invalid or unspecified index
    Debug.Assert False
    Exit Function
   End If
   If m > tLevel.tMapData(nIndex).nPropertyCount Then
    tLevel.tMapData(nIndex).nPropertyCount = m
    ReDim Preserve tLevel.tMapData(nIndex).tProperties(1 To m)
   End If
   tLevel.tMapData(nIndex).tProperties(m).nIndex = m
   tLevel.tMapData(nIndex).tProperties(m).sTag = obj.GetSubNodeValueAsStringByName("tag")
   '///
   For j = 1 To obj.SubNodeCount
    If obj.SubNodeType(j) = 1 Then
     Set obj1 = obj.SubNodeObject(j)
'     k = 0
'     s = obj1.GetNameAsString
'     Select Case s
'     Case Else
'      k = ParseEventType(s)
'     End Select
     k = ParseEventType(obj1.GetNameAsString)
     '///event?
     If k > 0 Then
      tLevel.tMapData(nIndex).tProperties(m).nEventCount = _
      tLevel.tMapData(nIndex).tProperties(m).nEventCount + 1
      ReDim Preserve tLevel.tMapData(nIndex).tProperties(m).tEvent(1 To _
      tLevel.tMapData(nIndex).tProperties(m).nEventCount)
      If Not ParseEventFromNode(tLevel.tMapData(nIndex).tProperties(m).tEvent( _
      tLevel.tMapData(nIndex).tProperties(m).nEventCount), obj1, k) Then
       Exit Function
      End If
     End If
    End If
   Next j
  Case "polyhedron"
   tLevel.nPolyhedronCount = tLevel.nPolyhedronCount + 1
   ReDim Preserve tLevel.tPolyhedron(1 To tLevel.nPolyhedronCount)
   If Not ParseMapPolyhedronDataFromNode(obj, tLevel.tPolyhedron(tLevel.nPolyhedronCount), CStr(nIndex)) Then Exit Function
  Case Else
   'TODO:adjacent,etc.
   Debug.Assert False
   Exit Function
  End Select
 End If
Next i
'///calc world matrix
CalcMapDataWorldMatrix tLevel.tMapData(nIndex)
'///apply map array properties (?)
If nFlags And &H10& Then
 For k = 0 To tLevel.tMapData(nIndex).nSize(2) - 1
  For j = 0 To tLevel.tMapData(nIndex).nSize(1) - 1
   For i = 0 To tLevel.tMapData(nIndex).nSize(0) - 1
    m = tLevel.tMapData(nIndex).nPropertyArray(i, j, k)
    If m > 0 And m <= tLevel.tMapData(nIndex).nPropertyCount Then
     s = tLevel.tMapData(nIndex).tProperties(m).sTag
     If s <> "" Then tLevel.tMapData(nIndex).sTagArray(i, j, k) = s
    End If
   Next i
  Next j
 Next k
End If
'///over
tLevel.tMapData(nIndex).nFlags = nFlags
ParseMapDataFromNode = True
End Function

Friend Sub CalcMapDataWorldMatrix(ByRef t2 As typeMapData)
Dim p(3) As D3DXVECTOR4
Dim mat As D3DMATRIX
'///scale
t2.fPos(1).x = t2.fPos(1).x * t2.fScale.x
t2.fPos(1).y = t2.fPos(1).y * t2.fScale.x
t2.fPos(1).z = t2.fPos(1).z * t2.fScale.x
t2.fPos(2).x = t2.fPos(2).x * t2.fScale.y
t2.fPos(2).y = t2.fPos(2).y * t2.fScale.y
t2.fPos(2).z = t2.fPos(2).z * t2.fScale.y
t2.fPos(3).x = t2.fPos(3).x * t2.fScale.z
t2.fPos(3).y = t2.fPos(3).y * t2.fScale.z
t2.fPos(3).z = t2.fPos(3).z * t2.fScale.z
'///rotate
D3DXMatrixRotationYawPitchRoll mat, t2.fRotation.x, t2.fRotation.y, t2.fRotation.z
D3DXVec4TransformArray p(1), 16&, t2.fPos(1), 16&, mat, 3
'///multiply by step
t2.fPos(1).x = p(1).x * t2.fStep.x
t2.fPos(1).y = p(1).y * t2.fStep.x
t2.fPos(1).z = p(1).z * t2.fStep.x
t2.fPos(2).x = p(2).x * t2.fStep.y
t2.fPos(2).y = p(2).y * t2.fStep.y
t2.fPos(2).z = p(2).z * t2.fStep.y
t2.fPos(3).x = p(3).x * t2.fStep.z
t2.fPos(3).y = p(3).y * t2.fStep.z
t2.fPos(3).z = p(3).z * t2.fStep.z
'///calc center
p(0).x = t2.fPos(0).x - t2.fCenter.x * t2.fPos(1).x * t2.nSize(0) _
- t2.fCenter.y * t2.fPos(2).x * t2.nSize(1) - t2.fCenter.z * t2.fPos(3).x * t2.nSize(2)
p(0).y = t2.fPos(0).y - t2.fCenter.x * t2.fPos(1).y * t2.nSize(0) _
- t2.fCenter.y * t2.fPos(2).y * t2.nSize(1) - t2.fCenter.z * t2.fPos(3).y * t2.nSize(2)
p(0).z = t2.fPos(0).z - t2.fCenter.x * t2.fPos(1).z * t2.nSize(0) _
- t2.fCenter.y * t2.fPos(2).z * t2.nSize(1) - t2.fCenter.z * t2.fPos(3).z * t2.nSize(2)
'///over
CopyMemory t2.matWorld.m11, p(1), 48&
CopyMemory t2.matWorld.m41, p(0), 16&
t2.matWorld.m44 = 1
t2.fPos(0) = p(0)
End Sub

Friend Function pFlagsFromBooleanString(ByRef s As String, ByVal nFlags As Long, ByVal nMask As Long) As Long
Dim j As Long
If s = "true" Then j = -1 Else If Val(s) <> 0 Then j = -1
pFlagsFromBooleanString = (nFlags And Not nMask) Or (j And nMask)
End Function

Friend Function ParseMapPolyhedronDataFromNode(ByVal objNode As clsTreeStorageNode, ByRef tPoly As typeMapData_Polyhedron, Optional ByVal sBasePosition As String) As Boolean
Dim i As Long, j As Long, k As Long
Dim s As String
Dim obj As clsTreeStorageNode
Dim nFlags As Long
Dim nSizeX As Single, nSizeY As Single, nSizeZ As Single
Dim bAutoSize As Boolean
'///
nFlags = &H1FE&
tPoly.nShape = &H112&
'///
For i = 1 To objNode.SubNodeCount
 If objNode.SubNodeType(i) = 0 Then
  s = Trim(objNode.GetSubNodeValueAsString(i))
  Select Case objNode.GetSubNodeNameAsString(i)
  Case "id"
   'TODO:check duplicated ID
   tPoly.sID = s
  Case "shape"
   Select Case s
   Case "cube"
    tPoly.nShape = &H111&
   Case "cuboid", "classical"
    tPoly.nShape = &H112&
   Case "tetrahedron"
    tPoly.nShape = 1
   Case "octahedron"
    tPoly.nShape = 2
   Case "icosahedron"
    tPoly.nShape = 3
   Case "triangularBipyramid"
    tPoly.nShape = 4
   Case "pentagonalBipyramid"
    tPoly.nShape = 5
   Case "rhomboid"
    tPoly.nShape = 6
   Case "heptahedron"
    tPoly.nShape = 7
   Case "snubDisphenoid"
    tPoly.nShape = 8
   Case "triaugmentedTriangularPrism"
    tPoly.nShape = 9
   Case "gyroelongatedSquareDipyramid"
    tPoly.nShape = 10
   Case "truncatedTetrahedron"
    tPoly.nShape = 11
   Case Else
    s = Replace(s, "x", "*")
    s = Replace(s, "X", "*")
    k = Val(s) And &HF&
    If k = 0 Then
     Debug.Assert False
     Exit Function
    End If
    tPoly.nShape = k * &H100&
    j = InStr(1, s, "*")
    If j = 0 Then
     Debug.Assert False
     Exit Function
    End If
    s = Mid(s, j + 1)
    k = Val(s) And &HF&
    If k = 0 Then
     Debug.Assert False
     Exit Function
    End If
    tPoly.nShape = tPoly.nShape Or (k * &H10&)
    j = InStr(1, s, "*")
    If j = 0 Then
     Debug.Assert False
     Exit Function
    End If
    s = Mid(s, j + 1)
    k = Val(s) And &HF&
    If k = 0 Then
     Debug.Assert False
     Exit Function
    End If
    tPoly.nShape = tPoly.nShape Or k
   End Select
  Case "type"
   j = FindObjectType(s)
   If j = 0 Then
    Debug.Assert False
    Exit Function
   End If
   tPoly.nObjType = j
  Case "p"
   If s = "" Then
    Debug.Assert False
    Exit Function
   End If
   If sBasePosition = "" Then
    tPoly.sPos = s
   Else
    Select Case AscW(s)
    Case 40, 46 '["."], ["("]
    Case &H30 To &H39 '["0"] To ["9"]
     j = InStr(1, s, ":")
     If j > 0 Then s = "(" + Left(s, j - 1) + ")" + Mid(s, j) _
     Else s = "(" + s + ")"
    Case Else
     s = "." + s
    End Select
    tPoly.sPos = sBasePosition + s
   End If
   '///debug
   'Debug.Print "Polyhedron start:" + tPoly.sPos
  Case "autoSize"
   bAutoSize = pFlagsFromBooleanString(s, 0, 1)
  Case "discardable"
   nFlags = pFlagsFromBooleanString(s, nFlags, &H1&)
  Case "main"
   nFlags = pFlagsFromBooleanString(s, nFlags, &H2&)
  Case "fragile"
   nFlags = pFlagsFromBooleanString(s, nFlags, &H4&)
  Case "supportable"
   nFlags = pFlagsFromBooleanString(s, nFlags, &H8&)
  Case "supporter"
   nFlags = pFlagsFromBooleanString(s, nFlags, &H10&)
  Case "tiltable"
   nFlags = pFlagsFromBooleanString(s, nFlags, &H20&)
  Case "tilt-supporter"
   nFlags = pFlagsFromBooleanString(s, nFlags, &H40&)
  Case "spannable"
   nFlags = pFlagsFromBooleanString(s, nFlags, &H80&)
  Case "visible"
   nFlags = pFlagsFromBooleanString(s, nFlags, &H100&)
  End Select
 Else
  'etc.
  Set obj = objNode.SubNodeObject(i)
  Select Case obj.GetNameAsString
  Case "appearance"
   nSizeX = 1
   nSizeY = 1
   nSizeZ = 1
   If bAutoSize Then
    Select Case tPoly.nShape
    Case &H111 To &HFFF
     'new: default size
     nSizeX = (tPoly.nShape And &HF00&) \ &H100&
     nSizeY = (tPoly.nShape And &HF0&) \ &H10&
     nSizeZ = tPoly.nShape And &HF&
    Case Else
     '??? TODO:
    End Select
   End If
   tPoly.nApprIndex = objEffectMgr.AddAppearanceFromNode(obj, nSizeX, nSizeY, nSizeZ)
  End Select
 End If
Next i
'///over
tPoly.nFlags = nFlags
ParseMapPolyhedronDataFromNode = True
End Function

Friend Function AddLevelDataFromNodeEx(ByVal objNode As clsTreeStorageNode, ByRef tLevel As typeLevelData) As Boolean
Dim i As Long, j As Long, k As Long
Dim s As String
Dim obj As clsTreeStorageNode
'///
Select Case objNode.GetNameAsString
Case "level"
Case Else
 Exit Function
End Select
'///
For i = 1 To objNode.SubNodeCount
 If objNode.SubNodeType(i) = 0 Then
  'TODO:
  Debug.Assert False
'  Select Case objNode.GetSubNodeNameAsString(i)
'  Case "name"
'  End Select
 Else
  Set obj = objNode.SubNodeObject(i)
  Select Case obj.GetNameAsString
  Case "mapData"
   tLevel.nMapDataCount = tLevel.nMapDataCount + 1
   ReDim Preserve tLevel.tMapData(1 To tLevel.nMapDataCount)
   If Not ParseMapDataFromNode(obj, tLevel, tLevel.nMapDataCount) Then Exit Function
  Case "polyhedron"
   tLevel.nPolyhedronCount = tLevel.nPolyhedronCount + 1
   ReDim Preserve tLevel.tPolyhedron(1 To tLevel.nPolyhedronCount)
   If Not ParseMapPolyhedronDataFromNode(obj, tLevel.tPolyhedron(tLevel.nPolyhedronCount)) Then Exit Function
  Case "tileMapping"
   s = obj.GetSubNodeValueAsStringByName("id")
   If s <> "" Then
    k = -Val(obj.GetSubNodeValueAsStringByName("index"))
    If k > 0 And k <= m_nTileTypeCount_Max Then
     j = 0
     For j = 1 To m_nTileTypeCount
      If m_tTileType(j).nIndex > 0 Then
       If m_tTileType(j).sID = s Then
        j = -j
        Exit For
       End If
      End If
     Next j
     If j >= 0 Then
      For j = m_nTileTypeCount_Max + 1 To m_nTileTypeCount_Max + m_nTileTypeCount2
       If m_tTileType(j).sID = s Then
        j = -j
        Exit For
       End If
      Next j
     End If
     If j < 0 Then m_nTileTypeMap(k) = -j
    End If
   End If
  Case "polyhedronMerge"
   'TODO:
   Debug.Print "TODO:polyhedronMerge"
  End Select
 End If
Next i
'///
AddLevelDataFromNodeEx = True
End Function

'Friend Function GenerateMeshFromLevelData(ByRef tMapDataInst() As typeMapDataRuntime, ByRef tInst As typeMeshInstanceCollection, Optional ByVal bRuntime As Boolean = True) As Boolean
'GenerateMeshFromLevelData = GenerateMeshFromLevelDataEx(m_tLevel, tMapDataInst, tInst, bRuntime)
'End Function

Friend Function GenerateMeshFromLevelDataEx(ByRef tLevel As typeLevelData, ByRef tMapDataInst() As typeMapDataRuntime, ByRef tInst As typeMeshInstanceCollection, Optional ByVal bRuntime As Boolean = True) As Boolean
Dim idx As Long
Dim i As Long, j As Long, k As Long
Dim mat As D3DMATRIX, mat1 As D3DMATRIX, mat2 As D3DMATRIX
Dim nIndex As Long
'///
If tLevel.nMapDataCount > 0 Then
 ReDim tMapDataInst(1 To tLevel.nMapDataCount)
Else
 Erase tMapDataInst
End If
'///
For idx = 1 To tLevel.nMapDataCount
 '///
 ReDim tMapDataInst(idx).nTypeArray(tLevel.tMapData(idx).nSize(0) - 1, _
 tLevel.tMapData(idx).nSize(1) - 1, tLevel.tMapData(idx).nSize(2) - 1)
 ReDim tMapDataInst(idx).nInstIndex(tLevel.tMapData(idx).nSize(0) - 1, _
 tLevel.tMapData(idx).nSize(1) - 1, tLevel.tMapData(idx).nSize(2) - 1)
 '///
 Select Case tLevel.tMapData(idx).nFlags And &HF&
 Case 0 'rect
  mat = tLevel.tMapData(idx).matWorld
  For k = 0 To tLevel.tMapData(idx).nSize(2) - 1
   mat1 = mat
   For j = 0 To tLevel.tMapData(idx).nSize(1) - 1
    mat2 = mat1
    For i = 0 To tLevel.tMapData(idx).nSize(0) - 1
     nIndex = tLevel.tMapData(idx).nTypeArray(i, j, k)
     tMapDataInst(idx).nTypeArray(i, j, k) = nIndex
     If nIndex > 0 And nIndex <= m_nTileTypeMax Then
      'invisibleAtRuntime (?)
      If (bRuntime And m_tTileType(nIndex).nFlags And 1&) = 0 Then
       tMapDataInst(idx).nInstIndex(i, j, k) = objEffectMgr.AddInstanceFromAppearanceEx(tInst, m_tTileType(nIndex).nApprIndex, mat2)
      End If
     End If
     '///
     mat2.m41 = mat2.m41 + tLevel.tMapData(idx).fPos(1).x
     mat2.m42 = mat2.m42 + tLevel.tMapData(idx).fPos(1).y
     mat2.m43 = mat2.m43 + tLevel.tMapData(idx).fPos(1).z
    Next i
    mat1.m41 = mat1.m41 + tLevel.tMapData(idx).fPos(2).x
    mat1.m42 = mat1.m42 + tLevel.tMapData(idx).fPos(2).y
    mat1.m43 = mat1.m43 + tLevel.tMapData(idx).fPos(2).z
   Next j
   mat.m41 = mat.m41 + tLevel.tMapData(idx).fPos(3).x
   mat.m42 = mat.m42 + tLevel.tMapData(idx).fPos(3).y
   mat.m43 = mat.m43 + tLevel.tMapData(idx).fPos(3).z
  Next k
 Case Else
  'TODO:
  Debug.Assert False
 End Select
Next idx
GenerateMeshFromLevelDataEx = True
End Function

Friend Sub Destroy()
Erase m_tObjType, m_nObjInteraction
m_nObjTypeCount = 0
m_nObjTypeMax = 0
m_bObjInteractionDirty = False
Erase m_tTileType
m_nTileTypeCount = 0
m_nTileTypeCount2 = 0
m_nTileTypeMax = 0
'///
ClearLevelData
End Sub

'Friend Sub ClearObjectTypes()
'Erase m_tObjType, m_nObjInteraction
'm_nObjTypeCount = 0
'm_nObjTypeMax = 0
'm_bObjInteractionDirty = False
'End Sub

Friend Property Get ObjectTypeCount() As Long
ObjectTypeCount = m_nObjTypeCount
End Property

Friend Property Get ObjectTypeName(ByVal nIndex As Long) As String
ObjectTypeName = m_tObjType(nIndex).sName
End Property

Friend Function FindObjectType(ByVal sName As String) As Long
Dim i As Long
For i = 1 To m_nObjTypeCount
 If sName = m_tObjType(i).sName Then
  FindObjectType = i
  Exit Function
 End If
Next i
End Function

Friend Property Get TileTypeID(ByVal nIndex As Long) As String
TileTypeID = m_tTileType(nIndex).sID
End Property

Friend Function FindTileType(ByVal sID As String) As Long
Dim i As Long
For i = 1 To m_nTileTypeCount
 If m_tTileType(i).nIndex = i Then
  If sID = m_tTileType(i).sID Then
   FindTileType = i
   Exit Function
  End If
 End If
Next i
For i = m_nTileTypeCount_Max + 1 To m_nTileTypeCount_Max + m_nTileTypeCount2
 If sID = m_tTileType(i).sID Then
  FindTileType = i
  Exit Function
 End If
Next i
End Function

Friend Property Get TileTypeName(ByVal nIndex As Long, Optional ByVal bTranslate As Boolean) As String
If bTranslate Then TileTypeName = objText.GetText(m_tTileType(nIndex).sName) _
Else TileTypeName = m_tTileType(nIndex).sName
End Property

Friend Property Get TileTypeDescription(ByVal nIndex As Long, Optional ByVal bTranslate As Boolean) As String
If bTranslate Then TileTypeDescription = objText.GetText(m_tTileType(nIndex).sDesc) _
Else TileTypeDescription = m_tTileType(nIndex).sDesc
End Property

Friend Property Let TileTypeName(ByVal nIndex As Long, Optional ByVal bTranslate As Boolean, ByRef s As String)
m_tTileType(nIndex).sName = s
End Property

Friend Property Let TileTypeDescription(ByVal nIndex As Long, Optional ByVal bTranslate As Boolean, ByRef s As String)
m_tTileType(nIndex).sDesc = s
End Property

Friend Function GetDualObjectInteractionType(ByVal nType As Long) As Long
Select Case nType
Case &H102 To &H105
 nType = nType Xor 1&
End Select
GetDualObjectInteractionType = nType
End Function

Friend Sub CalcObjectInteractionType()
On Error Resume Next
Dim i As Long, j As Long, k As Long
Dim nType As Long, nType2 As Long
Dim obj As New Collection
If m_bObjInteractionDirty Then
 ReDim m_nObjInteraction(0 To m_nObjTypeCount, 0 To m_nObjTypeCount)
 '///
 For i = 1 To m_nObjTypeCount
  obj.Add i, m_tObjType(i).sName
  nType = m_tObjType(i).tInteraction(0).nType
  If nType > 0 Then
   nType2 = GetDualObjectInteractionType(nType)
   For j = 0 To m_nObjTypeCount
    m_nObjInteraction(i, j) = nType
    If m_nObjInteraction(j, i) = 0 Then m_nObjInteraction(j, i) = nType2
   Next j
  End If
 Next i
 '///
 For i = 1 To m_nObjTypeCount
  For k = 1 To m_tObjType(i).nInteractionCount
   Err.Clear
   j = obj.Item(m_tObjType(i).tInteraction(k).sName2)
   If Err.Number = 0 Then
    nType = m_tObjType(i).tInteraction(k).nType
    m_nObjInteraction(i, j) = &H80000000 Or nType
    If m_nObjInteraction(j, i) >= 0 Then m_nObjInteraction(j, i) = &H80000000 Or GetDualObjectInteractionType(nType)
   End If
  Next k
 Next i
 '///
End If
m_bObjInteractionDirty = False
End Sub

Friend Function GetObjectInteractionType(ByVal nIndex1 As Long, ByVal nIndex2 As Long) As Long
If nIndex1 >= 0 And nIndex1 <= m_nObjTypeCount And nIndex2 >= 0 And nIndex2 <= m_nObjTypeCount Then
 If m_bObjInteractionDirty Then CalcObjectInteractionType
 GetObjectInteractionType = m_nObjInteraction(nIndex1, nIndex2) And &H7FFFFFFF
End If
End Function

'internal
Friend Sub ParseInteraction(ByRef t As typeObjectInteractionType, ByVal s As String)
Dim j As Long, s1 As String
j = InStr(1, s, ":")
If j > 0 Then
 s1 = Mid(s, j + 1)
 s = Left(s, j - 1)
End If
Select Case s
Case "moveable"
 t.nType = 0
Case "not-moveable"
 t.nType = 1
Case "slippery"
 t.nType = 2
Case "superSlippery"
 t.nType = 3
Case "game-over"
 j = 0
 Select Case s1
 Case "immediately"
  j = 1
 Case "breakdown"
  j = 2
 Case "breakdown:2"
  j = 3
 Case "melting"
  j = 4
 Case "melting:2"
  j = 5
 End Select
 t.nType = &H100 Or j
Case Else
 Debug.Assert False
End Select
End Sub

'internal
Friend Function AddObjectTypeFromNode(ByVal objNode As clsTreeStorageNode) As Long
Dim i As Long, j As Long
Dim s As String
Dim obj As clsTreeStorageNode
Dim nCount As Long, nMax As Long
'///
Select Case objNode.GetNameAsString
Case "objectType"
Case Else
 Exit Function
End Select
'///
m_nObjTypeCount = m_nObjTypeCount + 1
If m_nObjTypeCount > m_nObjTypeMax Then
 m_nObjTypeMax = m_nObjTypeMax + 16&
 ReDim Preserve m_tObjType(1 To m_nObjTypeMax)
End If
'///
ReDim m_tObjType(m_nObjTypeCount).tInteraction(0 To 0)
'///
For i = 1 To objNode.SubNodeCount
 If objNode.SubNodeType(i) = 0 Then
  Select Case objNode.GetSubNodeNameAsString(i)
  Case "name"
   m_tObjType(m_nObjTypeCount).sName = objNode.GetSubNodeValueAsString(i)
  End Select
 Else
  Set obj = objNode.SubNodeObject(i)
  Select Case obj.GetNameAsString
  Case "interaction"
   For j = 1 To obj.SubNodeCount
    If obj.SubNodeType(j) = 0 Then
     s = obj.GetSubNodeNameAsString(j)
     Select Case s
     Case "default"
      ParseInteraction m_tObjType(m_nObjTypeCount).tInteraction(0), obj.GetSubNodeValueAsString(j)
     Case Else
      nCount = nCount + 1
      If nCount > nMax Then
       nMax = nMax + 8
       ReDim Preserve m_tObjType(m_nObjTypeCount).tInteraction(0 To nMax)
      End If
      m_tObjType(m_nObjTypeCount).nInteractionCount = nCount
      m_tObjType(m_nObjTypeCount).tInteraction(nCount).sName2 = s
      ParseInteraction m_tObjType(m_nObjTypeCount).tInteraction(nCount), obj.GetSubNodeValueAsString(j)
     End Select
    End If
   Next j
  End Select
 End If
Next i
'///
m_bObjInteractionDirty = True
AddObjectTypeFromNode = m_nObjTypeCount
End Function

Friend Sub LoadObjectTypesFromSubNodes(ByVal objNode As clsTreeStorageNode)
Dim i As Long
Dim obj As clsTreeStorageNode
For i = 1 To objNode.SubNodeCount
 Set obj = objNode.SubNodeObject(i)
 If Not obj Is Nothing Then AddObjectTypeFromNode obj
Next i
End Sub

Friend Function ParseEventType(ByRef s As String) As Long
Select Case s
Case "onEnter"
 ParseEventType = EventTypeOnEnter
Case "onLeave"
 ParseEventType = EventTypeOnLeave
Case "onMoveEnter"
 ParseEventType = EventTypeOnMoveEnter
Case "onMoveLeave"
 ParseEventType = EventTypeOnMoveLeave
Case "onPressKey"
 ParseEventType = EventTypeOnPressKey
Case "onCustomEvent", "onTriggeredEvent", "onEvent"
 ParseEventType = EventTypeOnCustomEvent
End Select
End Function

'internal
Friend Function ParseEventFromNode(ByRef ret As typeTileEvent, ByVal objNode As clsTreeStorageNode, ByVal nEventType As Long) As Boolean
On Error Resume Next
Dim v As Variant, m As Long
Dim s As String, s1 As String
Dim i As Long, j As Long
Dim lps As Long
Dim nType As Long
Dim nCompareType As Long
Dim nDataType As Long
'///
ret.nEventType = nEventType
'///process conditions
s = Trim(objNode.GetSubNodeValueAsStringByName("condition"))
If Right(s, 1) = ";" Then s = Left(s, Len(s) - 1)
v = Split(s, ";")
ret.nConditionCount = UBound(v) + 1
If ret.nConditionCount > 0 Then ReDim ret.tCondition(1 To ret.nConditionCount)
For i = 1 To ret.nConditionCount
 s = Trim(v(i - 1))
 lps = InStr(1, s, "=")
 If lps > 0 Then
  s1 = Trim(Mid(s, lps + 1))
  If Mid(s, lps - 1, 1) = "!" Then
   nCompareType = 1
   lps = lps - 1
  End If
 Else
  lps = InStr(1, s, "!")
  If lps > 0 Then
   If Mid(s, lps + 1, 1) = "!" Then
    nCompareType = 3
    s1 = Trim(Mid(s, lps + 2))
   Else
    nCompareType = 2
    s1 = Trim(Mid(s, lps + 1))
   End If
  Else
   Debug.Assert False
   Exit Function
  End If
 End If
 '///
 Select Case Trim(Left(s, lps - 1))
 Case "pressure"
  nType = 1
  nDataType = 2
 Case "onGroundCount"
  nType = 2
  nDataType = 2
 Case "onDifferentType"
  nType = 3
  nDataType = 1
 Case "eventType", "eventIndex"
  nType = 4
  nDataType = 3
 Case "discardable"
  nType = &H101
  nDataType = 1
 Case "main"
  nType = &H102
  nDataType = 1
 Case "fragile"
  nType = &H103
  nDataType = 1
 Case "supportable"
  nType = &H104
  nDataType = 1
 Case "supporter"
  nType = &H105
  nDataType = 1
 Case "tiltable"
  nType = &H106
  nDataType = 1
 Case "tilt-supporter"
  nType = &H107
  nDataType = 1
 Case "spannable"
  nType = &H108
  nDataType = 1
 Case "objectType"
  nType = &H121
  nDataType = 3
 Case "objectID"
  nType = &H122
  nDataType = 3
 Case Else
  Debug.Assert False
  Exit Function
 End Select
 '///
 If nDataType <> 3 Then
  nCompareType = nCompareType And 1&
 End If
 '///
 Select Case nDataType
 Case 1 'boolean
  j = 0
  If s1 = "true" Then j = 1 Else If Val(s1) <> 0 Then j = 1
  If nCompareType And 1& Then
   nCompareType = 0
   j = j Xor 1
  End If
  ret.tCondition(i).nValue1 = j
  ret.tCondition(i).nValue2 = j
 Case 2 'number
  lps = InStr(1, s1, "~")
  If lps > 0 Then
   s = Trim(Left(s1, lps - 1))
   s1 = Trim(Mid(s1, lps + 1))
   If s <> "" Then
    If s1 <> "" Then
     ret.tCondition(i).nValue1 = Val(s)
     ret.tCondition(i).nValue2 = Val(s1)
    Else
     ret.tCondition(i).nValue1 = Val(s)
     ret.tCondition(i).nValue2 = 1E+30
    End If
   Else
    If s1 <> "" Then
     ret.tCondition(i).nValue1 = -1E+30
     ret.tCondition(i).nValue2 = Val(s1)
    Else
     'ERR
     Debug.Assert False
     Exit Function
    End If
   End If
  Else
   ret.tCondition(i).nValue1 = Val(s1)
   ret.tCondition(i).nValue2 = ret.tCondition(i).nValue1
  End If
 Case 3 'string
  ret.tCondition(i).sStringValue = Split(s1, "|")
  ret.tCondition(i).nStringValueCount = UBound(ret.tCondition(i).sStringValue) + 1
 End Select
 '///
 ret.tCondition(i).nType = nType
 ret.tCondition(i).nCompareType = nCompareType
Next i
'///process events
s = Trim(objNode.GetSubNodeValueAsStringByName("event"))
If Right(s, 1) = ";" Then s = Left(s, Len(s) - 1)
v = Split(s, ";")
ret.nEventCount = UBound(v) + 1
If ret.nEventCount > 0 Then ReDim ret.tEvent(1 To ret.nEventCount)
For i = 1 To ret.nEventCount
 s = Trim(v(i - 1))
 lps = InStr(1, s, ":")
 If lps > 0 Then
  s1 = Trim(Mid(s, lps + 1))
  s = Trim(Left(s, lps - 1))
 Else
  s1 = vbNullString
 End If
 '///
 Select Case s
 Case "event", "sendEvent", "triggerEvent"
  nType = 1
  ret.tEvent(i).sStringParam = Split(s1, ":")
  ret.tEvent(i).nStringParamCount = UBound(ret.tEvent(i).sStringParam) + 1
 Case "teleport"
  nType = 3
  ret.tEvent(i).sStringParam = Split(s1, ":")
  ret.tEvent(i).nStringParamCount = UBound(ret.tEvent(i).sStringParam) + 1
 Case "convertTo"
  nType = 4
  ret.tEvent(i).nStringParamCount = 1
  ReDim ret.tEvent(i).sStringParam(0)
  ret.tEvent(i).sStringParam(0) = s1
 Case "move"
  Select Case s1
  Case "left"
   nType = 6
  Case "right"
   nType = 7
  Case "back"
   nType = 8
  Case Else
   nType = 5
  End Select
 Case "absolute-move"
  nType = 9
  'TODO:
 Case "game-finished"
  Select Case s1
  Case "unconditional"
   nType = 11
  Case Else
   nType = 10
  End Select
 Case "checkpoint"
  nType = 12
 Case "game-over"
  j = 0
  Select Case s1
  Case "immediately"
   j = 1
  Case "breakdown"
   j = 2
  Case "breakdown:2"
   j = 3
  Case "melting"
   j = 4
  Case "melting:2"
   j = 5
  End Select
  nType = &H100 Or j
 Case Else
  Debug.Assert False
  Exit Function
 End Select
 '///
 ret.tEvent(i).nType = nType
Next i
'///over
ParseEventFromNode = True
End Function

'internal
Friend Function AddTileTypeFromNode(ByVal objNode As clsTreeStorageNode) As Long
Dim i As Long, j As Long
Dim s As String
Dim obj As clsTreeStorageNode
Dim nIndex As Long
Dim nFlags As Long
Dim nEventType As Long
'///
Select Case objNode.GetNameAsString
Case "tileType"
Case Else
 Exit Function
End Select
'///
If m_nTileTypeMax <= 0 Then
 m_nTileTypeMax = m_nTileTypeCount_Max
 ReDim m_tTileType(1 To m_nTileTypeMax)
End If
'///get index
nIndex = Val(objNode.GetSubNodeValueAsStringByName("index"))
If nIndex > 0 And nIndex <= m_nTileTypeCount_Max Then
 If m_tTileType(nIndex).nIndex > 0 Then
  'already exists
  Debug.Assert False
  Exit Function
 End If
 m_tTileType(nIndex).nIndex = nIndex
 If m_nTileTypeCount < nIndex Then m_nTileTypeCount = nIndex
Else
 i = nIndex
 m_nTileTypeCount2 = m_nTileTypeCount2 + 1
 nIndex = m_nTileTypeCount2 + m_nTileTypeCount_Max
 If nIndex > m_nTileTypeMax Then
  m_nTileTypeMax = m_nTileTypeMax + 16&
  ReDim Preserve m_tTileType(1 To m_nTileTypeMax)
 End If
 If i > 0 Then m_tTileType(nIndex).nIndex = i
End If
'///
For i = 1 To objNode.SubNodeCount
 If objNode.SubNodeType(i) = 0 Then
  Select Case objNode.GetSubNodeNameAsString(i)
  Case "id"
   'TODO:check duplicated ID
   m_tTileType(nIndex).sID = objNode.GetSubNodeValueAsString(i)
  Case "invisibleAtRuntime" '? TODO:
   nFlags = nFlags Or ((objNode.GetSubNodeValueAsString(i) = "true") And &H1&)
  Case "checkpoint"
   nFlags = nFlags Or ((objNode.GetSubNodeValueAsString(i) = "true") And &H2&)
  Case "elevator"
   nFlags = nFlags Or ((objNode.GetSubNodeValueAsString(i) = "true") And &H4&)
  Case "non-block"
   nFlags = nFlags Or ((objNode.GetSubNodeValueAsString(i) = "true") And &H8&)
  Case "blocked"
   nFlags = nFlags Or ((objNode.GetSubNodeValueAsString(i) = "true") And &H100&)
  Case "tilt-supporter", "tiltable" '<== obsolete
   nFlags = nFlags Or ((objNode.GetSubNodeValueAsString(i) <> "true") And &H200&)
  Case "supporter", "supportable" '<== obsolete
   nFlags = nFlags Or ((objNode.GetSubNodeValueAsString(i) <> "true") And &H400&)
  Case "block-height"
   m_tTileType(nIndex).nBlockHeight = Val(objNode.GetSubNodeValueAsString(i))
  Case "type"
   j = FindObjectType(objNode.GetSubNodeValueAsString(i))
   If j = 0 Then
    Debug.Assert False
    Exit Function
   End If
   m_tTileType(nIndex).nObjType = j
  End Select
 Else
  nEventType = 0
  Set obj = objNode.SubNodeObject(i)
  s = obj.GetNameAsString
  Select Case s
  Case "name"
   m_tTileType(nIndex).sName = obj.GetValueAsString
  Case "description"
   m_tTileType(nIndex).sDesc = obj.GetValueAsString
  Case "appearance"
   If m_tTileType(nIndex).nApprIndex > 0 Then
    'TODO:multiple appearances
    Debug.Assert False
    Exit Function
   End If
   m_tTileType(nIndex).nApprIndex = objEffectMgr.AddAppearanceFromNode(obj)
  Case Else
   nEventType = ParseEventType(s)
  End Select
  '///event?
  If nEventType > 0 Then
   m_tTileType(nIndex).nEventCount = m_tTileType(nIndex).nEventCount + 1
   ReDim Preserve m_tTileType(nIndex).tEvent(1 To m_tTileType(nIndex).nEventCount)
   If Not ParseEventFromNode(m_tTileType(nIndex).tEvent(m_tTileType(nIndex).nEventCount), obj, nEventType) Then
    Exit Function
   End If
  End If
  '///
 End If
Next i
'///
m_tTileType(nIndex).nFlags = nFlags
'debug
'Debug.Print nIndex, m_tTileType(nIndex).nIndex, m_tTileType(nIndex).sID, m_tTileType(nIndex).sName
'///
AddTileTypeFromNode = nIndex
End Function

Friend Sub LoadTileTypesFromSubNodes(ByVal objNode As clsTreeStorageNode)
Dim i As Long
Dim obj As clsTreeStorageNode
For i = 1 To objNode.SubNodeCount
 Set obj = objNode.SubNodeObject(i)
 If Not obj Is Nothing Then AddTileTypeFromNode obj
Next i
End Sub

'TODO:adjacency
Friend Function IsOtherPolyhedronOn(ByVal nPolyhedronIndex As Long) As Boolean
Dim idx As Long
Dim i1 As Long, j1 As Long, k1 As Long, p1 As typePolyhedronPosition
Dim i2 As Long, j2 As Long, k2 As Long, p2 As typePolyhedronPosition
Dim tState As typePolyhedronState
Select Case m_tLevel.tPolyhedron(nPolyhedronIndex).nShape
Case &H111 To &HFFF
 tState = m_objPoly(nPolyhedronIndex).PolyhedronState
 If tState.nTiltY = 0 Then
  m_objPoly(nPolyhedronIndex).GetCurrentSize i1, j1, k1
  p1 = m_objPoly(nPolyhedronIndex).Position
  For idx = 1 To m_tLevel.nPolyhedronCount
   If idx <> nPolyhedronIndex And (m_tPolyInst(idx).nFlags And &H100&) <> 0 Then
    Select Case m_tLevel.tPolyhedron(idx).nShape
    Case &H111 To &HFFF
     m_objPoly(idx).GetCurrentSize i2, j2, k2
     p2 = m_objPoly(idx).Position
     tState = m_objPoly(idx).PolyhedronState
     '///
     If p1.p.nMapDataIndex = p2.p.nMapDataIndex Then
      If p2.p.x > p1.p.x - i2 And p2.p.x < p1.p.x + i1 Then
       If p2.p.y > p1.p.y - j2 And p2.p.y < p1.p.y + j1 Then
        If tState.nTiltY > 0 Then
         'TODO:??? still some bugs
         If p2.p.z > p1.p.z - tState.nTiltY And p2.p.z <= p1.p.z + k1 Then
          IsOtherPolyhedronOn = True
          Exit Function
         End If
        Else
         If p2.p.z = p1.p.z + k1 Then
          IsOtherPolyhedronOn = True
          Exit Function
         End If
        End If
       End If
      End If
     End If
     '///
    End Select
   End If
  Next idx
 End If
Case Else
 'TODO:
 Debug.Assert False
End Select
End Function

Friend Function GetAdjacentPosition(ByRef tPos As typeMapPosition, ByVal nDirection As Long, ByRef tNewPos As typeMapPosition, Optional ByRef nNewDirection As Long) As Boolean
tNewPos = tPos
GetAdjacentPosition = GetAdjacentPositionInPlace(tNewPos, nDirection, nNewDirection)
End Function

Friend Function GetAdjacentPositionInPlaceIfValid(ByRef tPos As typeMapPosition, ByVal nDirection As Long, Optional ByRef nNewDirection As Long) As Boolean
Dim p As typeMapPosition
p = tPos
If Not GetAdjacentPositionInPlace(p, nDirection, nNewDirection) Then Exit Function
'///
If p.nMapDataIndex > 0 And p.nMapDataIndex <= m_tLevel.nMapDataCount Then
 If p.x >= 0 And p.x < m_tLevel.tMapData(p.nMapDataIndex).nSize(0) Then
  If p.y >= 0 And p.y < m_tLevel.tMapData(p.nMapDataIndex).nSize(1) Then
   If p.z >= 0 And p.z < m_tLevel.tMapData(p.nMapDataIndex).nSize(2) Then
    tPos = p
    GetAdjacentPositionInPlaceIfValid = True
   End If
  End If
 End If
End If
End Function

'direction:
'0=up
'1=left
'2=down
'3=right
'4=
'5=
'6=bottom
'7=top
Friend Function GetAdjacentPositionInPlace(ByRef tPos As typeMapPosition, ByVal nDirection As Long, Optional ByRef nNewDirection As Long) As Boolean
'///
nNewDirection = nDirection
'///
If tPos.nMapDataIndex > 0 And tPos.nMapDataIndex <= m_tLevel.nMapDataCount Then
 'TODO:check adjacent data and change nNewDirection
 Select Case m_tLevel.tMapData(tPos.nMapDataIndex).nFlags And &HF&
 Case 0 'rect
  Select Case nDirection
  Case 0
   tPos.y = tPos.y - 1
  Case 1
   tPos.x = tPos.x - 1
  Case 2
   tPos.y = tPos.y + 1
  Case 3
   tPos.x = tPos.x + 1
  Case 6
   tPos.z = tPos.z - 1
  Case 7
   tPos.z = tPos.z + 1
  Case Else
   Debug.Assert False
  End Select
 Case Else
  'TODO:
  Debug.Assert False
 End Select
End If
'///
GetAdjacentPositionInPlace = True '???
End Function

Friend Function IsPositionInMapData(ByRef tPos As typeMapPosition) As Boolean
Dim idx As Long
idx = tPos.nMapDataIndex
If idx > 0 And idx <= m_tLevel.nMapDataCount Then
 If tPos.x >= 0 And tPos.x < m_tLevel.tMapData(idx).nSize(0) Then
  If tPos.y >= 0 And tPos.y < m_tLevel.tMapData(idx).nSize(1) Then
   If tPos.z >= 0 And tPos.z < m_tLevel.tMapData(idx).nSize(2) Then
    IsPositionInMapData = True
   End If
  End If
 End If
End If
End Function

'return value:
'-1: invalid position
Friend Function GetMapDataIndirect(ByRef tPos As typeMapPosition) As Long
Dim idx As Long
idx = tPos.nMapDataIndex
GetMapDataIndirect = -1
If idx > 0 And idx <= m_tLevel.nMapDataCount Then
 If tPos.x >= 0 And tPos.x < m_tLevel.tMapData(idx).nSize(0) Then
  If tPos.y >= 0 And tPos.y < m_tLevel.tMapData(idx).nSize(1) Then
   If tPos.z >= 0 And tPos.z < m_tLevel.tMapData(idx).nSize(2) Then
    'If m_bRuntimeDirty Then
    ' GetMapDataIndirect = m_tLevel.tMapData(idx).nTypeArray(tPos.x, tPos.y, tPos.z)
    'Else
     GetMapDataIndirect = m_tMapDataInst(tPos.nMapDataIndex).nTypeArray(tPos.x, tPos.y, tPos.z)
    'End If
   End If
  End If
 End If
End If
End Function

Friend Sub HitTest(ByRef tPos As typeMapPosition, ByRef ret As typeMapDataHitTest, Optional ByVal nExcludePolyhedronIndex As Long, Optional ByVal nHeight As Long = 1)
Dim idx As Long
Dim i As Long, j As Long, k As Long
Dim sz As Long, ez As Long
Dim p As typeMapPosition
Dim tState As typePolyhedronState
'///
ret.nType = -1
ret.nObjType = 0
'///check if it's on some polyhedron
For idx = 1 To m_tLevel.nPolyhedronCount
 If idx <> nExcludePolyhedronIndex And (m_tPolyInst(idx).nFlags And &H100&) <> 0 Then
  'TODO: if it's not a supporter then there should be some event
  Select Case m_tLevel.tPolyhedron(idx).nShape
  Case &H111 To &HFFF
   m_objPoly(idx).GetCurrentSize i, j, k
   p = m_objPoly(idx).Position.p
   tState = m_objPoly(idx).PolyhedronState
   '///
   'TODO: wrong code if there are adjacency data
   'TODO: COMPLETELY WRONG CODE --> should combine to the tile checking
   If p.nMapDataIndex = tPos.nMapDataIndex Then
    If tPos.x >= p.x And tPos.x < p.x + i Then
     If tPos.y >= p.y And tPos.y < p.y + j Then
      If tPos.z > p.z - nHeight And tPos.z < p.z + k Then '???
       If tState.nTiltY > 0 Then
        ret.nType = &H80010000 Or k 'WRONG
       Else
        If tPos.z > p.z Then k = p.z + k - tPos.z 'WRONG
        If m_tPolyInst(idx).nFlags And &H40& Then ret.nType = &H80000000 Or k _
        Else ret.nType = &H80010000 Or k
       End If
       ret.nObjType = m_tLevel.tPolyhedron(idx).nObjType
       Exit Sub
      ElseIf tPos.z = p.z + k And (m_tPolyInst(idx).nFlags And &H10&) <> 0 And tState.nTiltY = 0 Then
       If ret.nType < 0 Then
        ret.nType = 0
        ret.nObjType = m_tLevel.tPolyhedron(idx).nObjType
       End If
      End If
     End If
    End If
   End If
  Case Else
   'TODO:
   Debug.Assert False
  End Select
 End If
Next idx
'///check if it's on some tile
idx = tPos.nMapDataIndex
If idx > 0 And idx <= m_tLevel.nMapDataCount Then
 If tPos.x >= 0 And tPos.x < m_tLevel.tMapData(idx).nSize(0) Then
  If tPos.y >= 0 And tPos.y < m_tLevel.tMapData(idx).nSize(1) Then
   p = tPos
   k = 0
   For i = 1 To nHeight
    If Not GetAdjacentPositionInPlaceIfValid(p, 7) Then Exit For
    k = k + 1
   Next i
   '///
   Do While k > -256 'max iteration
    i = GetMapDataIndirect(p)
    If i < 0 Then Exit Do
    '///
    If i > 0 And i <= m_nTileTypeMax Then
     j = m_tTileType(i).nFlags
     '///
     If j And &H8& Then sz = k _
     Else sz = k - 1
     If j And &H100& Then
      ez = m_tTileType(i).nBlockHeight
      If ez <= 0 Then ez = &H7FFFFFFF _
      Else ez = ez + k
     Else
      ez = k
     End If
     '///
     If nHeight > sz And sz < ez And ez > 0 Then 'blocked
      If ez > nHeight Then ez = nHeight
      If (j And &H200&) = 0 Then ret.nType = &H80000000 Or ez _
      Else ret.nType = &H80010000 Or ez
      ret.nObjType = m_tTileType(i).nObjType
      Exit Sub
     ElseIf ez = 0 And (j And &H400&) = 0 Then 'supported
      If ret.nType < 0 Then
       ret.nType = 0
       ret.nObjType = m_tTileType(i).nObjType
      End If
     End If
     '///
    End If
    '///
    GetAdjacentPositionInPlace p, 6
    k = k - 1
   Loop
   Debug.Assert k > -256
  End If
 End If
End If
End Sub

Friend Sub DispatchTileEvent(ByRef t As typeMapDataEvent, ByRef tEvent As typeTileEventAction)
Dim tNew As typeMapDataEvent
Dim mat As D3DMATRIX
Dim p As typePolyhedronPosition
Dim i As Long, j As Long, k As Long, l As Long
Dim s As String
'///
Select Case tEvent.nType
Case 1 'custom event
 If tEvent.nStringParamCount > 1 Then
  tNew = t
  tNew.nEventType = EventTypeOnCustomEvent
  tNew.sEventType = tEvent.sStringParam(0)
  For i = 1 To tEvent.nStringParamCount - 1
   tNew.p = t.p
   AddMapEventFromPositionString tNew, tEvent.sStringParam(i)
  Next i
 ElseIf tEvent.nStringParamCount > 0 Then
  tNew = t
  tNew.nEventType = EventTypeOnCustomEvent
  tNew.sEventType = tEvent.sStringParam(0)
  AddMapEventFromPositionString tNew, vbNullString
 End If
Case 3 'teleport
 If tEvent.nStringParamCount > 0 And _
 t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
  m_bPolyhedronDirty = True
  '///
  For i = 0 To tEvent.nStringParamCount - 1
   s = tEvent.sStringParam(i)
   j = InStr(1, s, "@")
   If j = 0 Then
    If i = 0 Then
     'move current polyhedron to new pos
     m_objPoly(t.nPolyhedronIndex).SendEvent EventTypeOnLeave
     If m_objPoly(t.nPolyhedronIndex).SetPositionFromString(s, m_tLevel) Then
      m_objPoly(t.nPolyhedronIndex).CheckPolyhedronStateAndResponse '???
      m_objPoly(t.nPolyhedronIndex).SendEvent EventTypeOnEnter
     Else
      Debug.Assert False
     End If
    Else
     Debug.Assert False
    End If
    Exit Sub
   End If
   'show new polyhedron
   s = Left(s, j - 1)
   For k = 1 To m_tLevel.nPolyhedronCount
    If m_tLevel.tPolyhedron(k).sID = s Then Exit For
   Next k
   If k > m_tLevel.nPolyhedronCount Then
    Debug.Assert False
    Exit Sub
   End If
   If m_tPolyInst(k).nFlags And &H100& Then '??? err???
    m_objPoly(k).SendEvent EventTypeOnLeave
   Else
    m_tPolyInst(k).nFlags = m_tPolyInst(k).nFlags Or &H100&
   End If
   If m_objPoly(k).SetPositionFromString(Mid(tEvent.sStringParam(i), j + 1), m_tLevel) Then
    m_objPoly(k).CheckPolyhedronStateAndResponse '???
    m_objPoly(k).SendEvent EventTypeOnEnter
   Else
    Debug.Assert False
    Exit Sub
   End If
  Next i
  '///hide old polyhedron (???)
  m_tPolyInst(t.nPolyhedronIndex).nFlags = _
  m_tPolyInst(t.nPolyhedronIndex).nFlags And Not &H100&
 End If
Case 4 'convertTo
 If tEvent.nStringParamCount < 1 Then Exit Sub
 i = GetMapDataIndirect(t.p)
 If i < 0 Then Exit Sub
 j = ParseTileTypeFromString(tEvent.sStringParam(0))
 If j < 0 Then Exit Sub
 '///
 If i <> j Then
  m_bPolyhedronDirty = True
  k = m_tMapDataInst(t.p.nMapDataIndex).nInstIndex(t.p.x, t.p.y, t.p.z)
  If k > 0 Then
   'TODO:correct animation
   StartTileAnimation k, 1
  End If
  k = 0
  If j > 0 Then
   If (m_bIsRuntime And m_tTileType(j).nFlags And 1&) = 0 Then
    'TODO:correct animation
    With m_tLevel.tMapData(t.p.nMapDataIndex)
     mat = .matWorld
     mat.m41 = mat.m41 + t.p.x * .fPos(1).x + t.p.y * .fPos(2).x + t.p.z * .fPos(3).x
     mat.m42 = mat.m42 + t.p.x * .fPos(1).y + t.p.y * .fPos(2).y + t.p.z * .fPos(3).y
     mat.m43 = mat.m43 + t.p.x * .fPos(1).z + t.p.y * .fPos(2).z + t.p.z * .fPos(3).z
    End With
    k = objEffectMgr.AddInstanceFromAppearanceEx(m_tLevelInst, m_tTileType(j).nApprIndex, mat)
    StartTileAnimation k, 2
   End If
  End If
  m_tMapDataInst(t.p.nMapDataIndex).nTypeArray(t.p.x, t.p.y, t.p.z) = j
  m_tMapDataInst(t.p.nMapDataIndex).nInstIndex(t.p.x, t.p.y, t.p.z) = k
 End If
Case 5 'move:straight
 If t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
  p = m_objPoly(t.nPolyhedronIndex).Position
  Select Case m_tLevel.tPolyhedron(t.nPolyhedronIndex).nShape
  Case &H111 To &HFFF
   m_objPoly(t.nPolyhedronIndex).Move (p.nGroundEdgeIndex - p.nFirstEdgeIndex + 2) And 3&, True
  Case Else
   Debug.Assert False
  End Select
 End If
Case 6 'move:left
 If t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
  p = m_objPoly(t.nPolyhedronIndex).Position
  Select Case m_tLevel.tPolyhedron(t.nPolyhedronIndex).nShape
  Case &H111 To &HFFF
   m_objPoly(t.nPolyhedronIndex).Move (p.nGroundEdgeIndex - p.nFirstEdgeIndex - 1) And 3&, True
  Case Else
   Debug.Assert False
  End Select
 End If
Case 7 'move:right
 If t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
  p = m_objPoly(t.nPolyhedronIndex).Position
  Select Case m_tLevel.tPolyhedron(t.nPolyhedronIndex).nShape
  Case &H111 To &HFFF
   m_objPoly(t.nPolyhedronIndex).Move (p.nGroundEdgeIndex - p.nFirstEdgeIndex + 1) And 3&, True
  Case Else
   Debug.Assert False
  End Select
 End If
Case 8 'move:back
 If t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
  p = m_objPoly(t.nPolyhedronIndex).Position
  Select Case m_tLevel.tPolyhedron(t.nPolyhedronIndex).nShape
  Case &H111 To &HFFF
   m_objPoly(t.nPolyhedronIndex).Move (p.nGroundEdgeIndex - p.nFirstEdgeIndex) And 3&, True
  Case Else
   Debug.Assert False
  End Select
 End If
Case 9 'absolute-move
 Debug.Print "TODO:absolute-move"
Case 10 'game-finished
 Debug.Print "TODO:game-finished"
Case 11 'game-finished:unconditional
 Debug.Print "TODO:game-finished:unconditional"
Case 12 'checkpoint
 Debug.Print "TODO:checkpoint"
Case &H100 To &H1FF 'game-over:*
 m_bPolyhedronDirty = True
 Select Case tEvent.nType
 Case &H103, &H105 'game-over:*:2
  i = GetMapDataIndirect(t.p)
  If i <= 0 Then Exit Sub
  '///
  k = m_tMapDataInst(t.p.nMapDataIndex).nInstIndex(t.p.x, t.p.y, t.p.z)
  If k > 0 Then
   'TODO:correct animation
   StartTileAnimation k, -1
  End If
  m_tMapDataInst(t.p.nMapDataIndex).nTypeArray(t.p.x, t.p.y, t.p.z) = 0
  m_tMapDataInst(t.p.nMapDataIndex).nInstIndex(t.p.x, t.p.y, t.p.z) = 0
 Case &H101 'game-over:immediately
  m_bReset = True
 Case Else 'TODO:other type
  If t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
   StartPolyhedronAnimation t.nPolyhedronIndex, -1, 0 'TODO:game over type
  Else 'err???
   m_bReset = True
  End If
 End Select
Case Else
 Debug.Assert False
 Exit Sub
End Select
End Sub

Friend Function CheckNumberMatchesCondition(ByVal f As Single, ByRef t As typeTileEventCondition) As Boolean
Select Case t.nCompareType
Case 0
 CheckNumberMatchesCondition = f >= t.nValue1 And f <= t.nValue2
Case 1
 CheckNumberMatchesCondition = Not (f >= t.nValue1 And f <= t.nValue2)
Case Else
 Debug.Assert False
End Select
End Function

Friend Function CheckBooleanMatchesCondition(ByVal b As Boolean, ByRef t As typeTileEventCondition) As Boolean
Select Case t.nCompareType
Case 0
 CheckBooleanMatchesCondition = b = (t.nValue1 <> 0)
Case 1
 CheckBooleanMatchesCondition = b <> (t.nValue1 <> 0)
Case Else
 Debug.Assert False
End Select
End Function

Friend Function CheckStringMatchesCondition(ByVal s As String, ByRef t As typeTileEventCondition) As Boolean
Dim i As Long
Select Case t.nCompareType
Case 0
 For i = 0 To t.nStringValueCount - 1
  If s = t.sStringValue(i) Then
   CheckStringMatchesCondition = True
   Exit Function
  End If
 Next i
Case 1
 For i = 0 To t.nStringValueCount - 1
  If s = t.sStringValue(i) Then Exit Function
 Next i
 CheckStringMatchesCondition = True
Case 2
 For i = 0 To t.nStringValueCount - 1
  If s Like t.sStringValue(i) Then
   CheckStringMatchesCondition = True
   Exit Function
  End If
 Next i
Case 3
 For i = 0 To t.nStringValueCount - 1
  If s Like t.sStringValue(i) Then Exit Function
 Next i
 CheckStringMatchesCondition = True
Case Else
 Debug.Assert False
End Select
End Function

Friend Sub CheckMapEventMatchesTileEvent(ByRef t As typeMapDataEvent, ByRef tEvent As typeTileEvent)
Dim i As Long, j As Long
Dim s As String
Dim b As Boolean
'///
If t.nEventType <> tEvent.nEventType Then Exit Sub
'///check condition
For i = 1 To tEvent.nConditionCount
 b = False
 Select Case tEvent.tCondition(i).nType
 Case 1 'pressure
  b = CheckNumberMatchesCondition(t.fPressure, tEvent.tCondition(i))
 Case 2 'onGroundCount
  b = CheckNumberMatchesCondition(t.nOnGroundCount, tEvent.tCondition(i))
 Case 3 'onDifferentType
  b = CheckBooleanMatchesCondition(t.nTileTypeCount > 1, tEvent.tCondition(i))
 Case 4 'eventType
  b = CheckStringMatchesCondition(t.sEventType, tEvent.tCondition(i))
 Case &H101 'discardable
  If t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
   b = CheckBooleanMatchesCondition(m_tPolyInst(t.nPolyhedronIndex).nFlags And 1&, tEvent.tCondition(i))
  End If
 Case &H102 'main
  If t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
   b = CheckBooleanMatchesCondition(m_tPolyInst(t.nPolyhedronIndex).nFlags And 2&, tEvent.tCondition(i))
  End If
 Case &H103 'fragile
  If t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
   b = CheckBooleanMatchesCondition(m_tPolyInst(t.nPolyhedronIndex).nFlags And 4&, tEvent.tCondition(i))
  End If
 Case &H104 'supportable
  If t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
   b = CheckBooleanMatchesCondition(m_tPolyInst(t.nPolyhedronIndex).nFlags And 8&, tEvent.tCondition(i))
  End If
 Case &H105 'supporter
  If t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
   b = CheckBooleanMatchesCondition(m_tPolyInst(t.nPolyhedronIndex).nFlags And &H10&, tEvent.tCondition(i))
  End If
 Case &H106 'tiltable
  If t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
   b = CheckBooleanMatchesCondition(m_tPolyInst(t.nPolyhedronIndex).nFlags And &H20&, tEvent.tCondition(i))
  End If
 Case &H107 'tilt-supporter
  If t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
   b = CheckBooleanMatchesCondition(m_tPolyInst(t.nPolyhedronIndex).nFlags And &H40&, tEvent.tCondition(i))
  End If
 Case &H108 'spannable
  If t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
   b = CheckBooleanMatchesCondition(m_tPolyInst(t.nPolyhedronIndex).nFlags And &H80&, tEvent.tCondition(i))
  End If
 Case &H121 'objectType
  If t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
   j = m_tLevel.tPolyhedron(t.nPolyhedronIndex).nObjType
   If j > 0 And j <= m_nObjTypeCount Then
    s = m_tObjType(j).sName
   Else
    s = "default"
   End If
   b = CheckStringMatchesCondition(s, tEvent.tCondition(i))
  End If
 Case &H122 'objectID
  If t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
   b = CheckStringMatchesCondition(m_tLevel.tPolyhedron(t.nPolyhedronIndex).sID, tEvent.tCondition(i))
  End If
 Case Else
  Debug.Assert False
  Exit Sub
 End Select
 If Not b Then Exit Sub
Next i
'///dispatch event
For i = 1 To tEvent.nEventCount
 DispatchTileEvent t, tEvent.tEvent(i)
Next i
End Sub

Friend Sub DispatchMapEvent(ByRef tEvent As typeMapDataEvent)
Dim nType As Long
Dim i As Long
'///
nType = GetMapDataIndirect(tEvent.p)
If nType < 0 Then Exit Sub
'///check tile type's event
If nType > 0 Then
 For i = 1 To m_tTileType(nType).nEventCount
  CheckMapEventMatchesTileEvent tEvent, m_tTileType(nType).tEvent(i)
 Next i
End If
'///check custom event
nType = m_tLevel.tMapData(tEvent.p.nMapDataIndex).nPropertyArray(tEvent.p.x, tEvent.p.y, tEvent.p.z)
If nType > 0 And nType <= m_tLevel.tMapData(tEvent.p.nMapDataIndex).nPropertyCount Then
 For i = 1 To m_tLevel.tMapData(tEvent.p.nMapDataIndex).tProperties(nType).nEventCount
  CheckMapEventMatchesTileEvent tEvent, m_tLevel.tMapData(tEvent.p.nMapDataIndex).tProperties(nType).tEvent(i)
 Next i
End If
End Sub

Friend Sub ProcessMapEvents()
Dim i As Long
Dim tEvent As typeMapDataEvent
'///
For i = 1 To 16384 'max iteration
 If m_nEventStart >= m_nEventEnd Then
  m_nEventStart = 0
  m_nEventEnd = 0
  Exit For
 End If
 tEvent = m_tEvent(m_nEventStart)
 m_nEventStart = m_nEventStart + 1
 DispatchMapEvent tEvent
Next i
Debug.Assert i <= 16384
'///???
If m_bPolyhedronDirty Then
 For i = 1 To m_tLevel.nPolyhedronCount
  '????????
  If m_tPolyInst(i).nFlags And &H100& Then
   If m_tPolyInst(i).nAnimType = 0 Then
    m_objPoly(i).CheckPolyhedronStateAndResponse
   End If
  End If
 Next i
End If
m_bPolyhedronDirty = False
End Sub

Friend Sub AddMapEvent(ByRef tEvent As typeMapDataEvent)
If m_nEventEnd >= m_nEventMax Then
 m_nEventMax = m_nEventMax + 256&
 ReDim Preserve m_tEvent(m_nEventMax - 1)
End If
m_tEvent(m_nEventEnd) = tEvent
m_nEventEnd = m_nEventEnd + 1
End Sub

'will change the contents of tEvent.p
Friend Sub AddMapEventFromPositionString(ByRef tEvent As typeMapDataEvent, ByVal s As String)
Dim s1 As String
Dim idx As Long, i As Long, j As Long, k As Long
'///
i = InStr(1, s, "(")
If i > 0 Then '<id>"("<subscript>")"
 s1 = Mid(s, i + 1)
 s = Left(s, i - 1)
Else
 i = InStr(1, s, ".")
 If i > 0 Then '<id>.<tag>
  s1 = Mid(s, i + 1)
  s = Left(s, i - 1)
  i = -1
 End If
End If
'///
If i <> 0 Then
 'get id
 idx = Val(s)
 If idx <= 0 Or idx > m_tLevel.nMapDataCount Then
  For idx = 1 To m_tLevel.nMapDataCount
   If s = m_tLevel.tMapData(idx).sID Then Exit For
  Next idx
  If idx > m_tLevel.nMapDataCount Then Exit Sub
 End If
 tEvent.p.nMapDataIndex = idx
 tEvent.p.x = 0
 tEvent.p.y = 0
 tEvent.p.z = 0
 'get subscript
 If i > 0 Then '<id>"("<subscript>")"
  tEvent.p.x = Val(s1) 'FIXME: no sanity check :-3
  i = InStr(1, s1, ",")
  If i > 0 Then
   tEvent.p.y = Val(Mid(s1, i + 1))
   i = InStr(i + 1, s1, ",")
   If i > 0 Then
    tEvent.p.z = Val(Mid(s1, i + 1))
   End If
  End If
  AddMapEvent tEvent
 Else '<id>.<tag>
  For k = 0 To m_tLevel.tMapData(idx).nSize(2) - 1
   tEvent.p.z = k
   For j = 0 To m_tLevel.tMapData(idx).nSize(1) - 1
    tEvent.p.y = j
    For i = 0 To m_tLevel.tMapData(idx).nSize(0) - 1
     If m_tLevel.tMapData(idx).sTagArray(i, j, k) = s1 Then
      tEvent.p.x = i
      AddMapEvent tEvent
     End If
    Next i
   Next j
  Next k
 End If
ElseIf s = "this" Then
 AddMapEvent tEvent
ElseIf s = vbNullString Then 'all
 For idx = 1 To m_tLevel.nMapDataCount
  tEvent.p.nMapDataIndex = idx
  For k = 0 To m_tLevel.tMapData(idx).nSize(2) - 1
   tEvent.p.z = k
   For j = 0 To m_tLevel.tMapData(idx).nSize(1) - 1
    tEvent.p.y = j
    For i = 0 To m_tLevel.tMapData(idx).nSize(0) - 1
     tEvent.p.x = i
     AddMapEvent tEvent
    Next i
   Next j
  Next k
 Next idx
Else '<tag>
 For idx = 1 To m_tLevel.nMapDataCount
  tEvent.p.nMapDataIndex = idx
  For k = 0 To m_tLevel.tMapData(idx).nSize(2) - 1
   tEvent.p.z = k
   For j = 0 To m_tLevel.tMapData(idx).nSize(1) - 1
    tEvent.p.y = j
    For i = 0 To m_tLevel.tMapData(idx).nSize(0) - 1
     If m_tLevel.tMapData(idx).sTagArray(i, j, k) = s Then
      tEvent.p.x = i
      AddMapEvent tEvent
     End If
    Next i
   Next j
  Next k
 Next idx
End If
'///
End Sub
