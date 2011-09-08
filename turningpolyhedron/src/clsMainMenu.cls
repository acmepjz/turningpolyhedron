VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsMainMenu"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Implements IFakeDXUIEvent
Implements IFakeDXAppEvent
Implements IRenderableObject

Private m_idxForm As Long

'////////new: some stupid animation

Private m_bShowAnimation As Boolean

Private Const m_fAnimTime As Single = 400 'TODO:

Private m_nPolyX As Long, m_nPolyY As Long
Private m_nPolySizeX As Long, m_nPolySizeY As Long, m_nPolySizeZ As Long
Private m_nDirection As Long

Private Type typeMainMenuAnimationQueue
 nPolyX As Long
 nPolyY As Long
 nPolySizeX As Long
 nPolySizeY As Long
 nPolySizeZ As Long
 nDirection As Long
End Type

Private m_tQueue(31) As typeMainMenuAnimationQueue
Private m_nQueueIndex As Long

Private m_matWorldOld As D3DMATRIX
Private m_fAnimValue As Single

Private m_nApprIndex As Long
Private m_tInst As typeMeshInstanceCollection

Private Type typeMainMenuTileChunk
 nPosX As Long
 nPosY As Long
 nCount As Long 'count of nInstIndex<>0; 0=unused
 '///
 nData(15, 15) As Long  'reference count
 nInstIndex(15, 15) As Long
 fAnimValue(15, 15) As Single
End Type

Private m_tTile() As typeMainMenuTileChunk '1-based
Private m_nTileCount As Long

Friend Sub AddTile(ByVal i As Long, ByVal j As Long, Optional ByVal bAnimation As Boolean = True)
Dim mat As D3DMATRIX
Dim idx As Long, idx2 As Long
Dim x As Long, y As Long
Dim k As Long
'///
x = (i And &HFFFFFFF0) \ &H10&
y = (j And &HFFFFFFF0) \ &H10&
'///
For idx = 1 To m_nTileCount
 If m_tTile(idx).nPosY = y Then
  If m_tTile(idx).nPosX = x Then Exit For
 ElseIf m_tTile(idx).nCount = 0 Then
  idx2 = idx
 End If
Next idx
'///
If idx > m_nTileCount Then
 If idx2 = 0 Then
  m_nTileCount = m_nTileCount + 1
  ReDim Preserve m_tTile(1 To m_nTileCount)
  idx = m_nTileCount
 Else
  idx = idx2
 End If
 m_tTile(idx).nPosX = x
 m_tTile(idx).nPosY = y
End If
'///
x = i And &HF&
y = j And &HF&
'///
k = m_tTile(idx).nData(x, y)
Debug.Assert k >= 0
m_tTile(idx).nData(x, y) = k + 1
If k = 0 Then
 If m_tTile(idx).nInstIndex(x, y) = 0 Then
  mat.m11 = 1
  mat.m22 = 1
  mat.m33 = 1
  mat.m41 = i
  mat.m42 = j
  mat.m44 = 1
  m_tTile(idx).nInstIndex(x, y) = objEffectMgr.AddInstanceFromAppearanceEx(m_tInst, m_nApprIndex, mat)
  If bAnimation Then m_tTile(idx).fAnimValue(x, y) = m_fAnimTime _
  Else m_tTile(idx).fAnimValue(x, y) = 0
  m_tTile(idx).nCount = m_tTile(idx).nCount + 1
 End If
End If
End Sub

Friend Sub RemoveTile(ByVal i As Long, ByVal j As Long)
Dim idx As Long
Dim x As Long, y As Long
Dim k As Long
Dim f As Single
'///
x = (i And &HFFFFFFF0) \ &H10&
y = (j And &HFFFFFFF0) \ &H10&
'///
For idx = 1 To m_nTileCount
 If m_tTile(idx).nPosY = y Then
  If m_tTile(idx).nPosX = x Then Exit For
 End If
Next idx
'///
If idx > m_nTileCount Then Exit Sub
'///
x = i And &HF&
y = j And &HF&
'///
k = m_tTile(idx).nData(x, y) - 1
If k < 0 Then Exit Sub
m_tTile(idx).nData(x, y) = k
End Sub

Friend Sub AddTileFromQueue(ByRef t As typeMainMenuAnimationQueue, Optional ByVal bAnimation As Boolean = True)
Dim i As Long, j As Long
For j = t.nPolyY To t.nPolyY + t.nPolySizeY - 1
 For i = t.nPolyX To t.nPolyX + t.nPolySizeX - 1
  AddTile i, j, bAnimation
 Next i
Next j
End Sub

Friend Sub RemoveTileFromQueue(ByRef t As typeMainMenuAnimationQueue)
Dim i As Long, j As Long
For j = t.nPolyY To t.nPolyY + t.nPolySizeY - 1
 For i = t.nPolyX To t.nPolyX + t.nPolySizeX - 1
  RemoveTile i, j
 Next i
Next j
End Sub

Friend Sub Create()
Dim i As Long
Dim x As Long, y As Long, tmp As Long
Dim sx As Long, sy As Long, sz As Long
Dim d As Long
'///
If m_idxForm Then Exit Sub
'///
With FakeDXUIControls(1)
 '///main menu test
 With .AddNewChildren(FakeCtl_None, 0, 0, 0, 0, , , False, , , , , , , 1, 1)
  m_idxForm = .Index
  Set .EventObject = Me
  '///some buttons
  .AddNewChildren FakeCtl_Button, 8, -32, 100, -8, , , , , _
  objText.GetText("Exit"), , "cmdExit", , 1, , 1, , , _
  objText.GetText("Exit the game and return to desktop.")
  .AddNewChildren FakeCtl_Button, 108, -32, 200, -8, , , , , _
  objText.GetText("Start game"), , "cmdStart", , 1, , 1, , , _
  objText.GetText("Select a level and start the game.")
  .AddNewChildren FakeCtl_Button, 208, -32, 300, -8, , , , , _
  objText.GetText("Options"), , "cmdOptions", , 1, , 1, , , _
  objText.GetText("Change the game settings.")
  .AddNewChildren FakeCtl_Button, 308, -32, 400, -8, , , , , _
  objText.GetText("About"), , "cmdAbout", , 1, , 1, , , _
  objText.GetText("Show information about the game.")
  '///ugly title
  With .AddNewChildren(FakeCtl_Label, 32, 32, -8, 96, FLS_Shadow, , , , _
  objText.GetText("Turning Polyhedron"), _
  , , , , 1)
   .FontZoom = 1
   .BackColor = 0
   .ForeColor = &HFFFFFF
  End With
  With .AddNewChildren(FakeCtl_Label, 32, 64, -8, 96, FLS_Shadow, , , , _
  objText.GetText("A puzzle game of rolling block mazes and its enhancements"), _
  , , , , 1)
   .FontZoom = 0.75
   .BackColor = 0
   .ForeColor = &HFFFFFF
  End With
 End With
End With
'///some stupid animation
m_nApprIndex = objGameMgr.TileTypeApprIndex(1)
m_matWorldOld = D3DXMatrixIdentity
m_bShowAnimation = True
'///
sx = 1: sy = 1: sz = 2
d = Int(4 * Rnd)
m_tQueue(0).nPolySizeX = sx
m_tQueue(0).nPolySizeY = sy
m_tQueue(0).nPolySizeZ = sz
m_tQueue(0).nDirection = d
'///
m_nPolySizeX = sx
m_nPolySizeY = sy
m_nPolySizeZ = sz
m_nDirection = d
'///
AddTileFromQueue m_tQueue(0), False
'///
For i = 1 To 16
 Select Case d
 Case 0 'up
  y = y - sz
 Case 1 'left
  x = x - sz
 Case 2 'down
  y = y + sy
 Case 3 'right
  x = x + sx
 End Select
 If d And 1& Then
  tmp = sx: sx = sz: sz = tmp
 Else
  tmp = sy: sy = sz: sz = tmp
 End If
 '///get new direction
 d = CLng(d - 1 + Int(3 * Rnd)) And 3&
 '///
 m_tQueue(i).nPolyX = x
 m_tQueue(i).nPolyY = y
 m_tQueue(i).nPolySizeX = sx
 m_tQueue(i).nPolySizeY = sy
 m_tQueue(i).nPolySizeZ = sz
 m_tQueue(i).nDirection = d
 '///
 AddTileFromQueue m_tQueue(i), False
Next i
End Sub

Friend Property Get ShowAnimation() As Boolean
ShowAnimation = m_bShowAnimation
End Property

Friend Property Let ShowAnimation(ByVal b As Boolean)
m_bShowAnimation = b
End Property

Friend Sub Show()
Create
FakeDXAppChangeRootObject &H7&, Me, Me
FakeDXUIControls(m_idxForm).Show
objCamera.RealLinearDamping = 1
End Sub

Friend Sub Hide()
If m_idxForm Then FakeDXUIControls(m_idxForm).Hide
End Sub

Private Function IFakeDXAppEvent_OnEvent(ByVal nType As Long, ByVal nParam1 As Long, ByVal nParam2 As Long, ByVal nParam3 As Long) As Long
Dim Button As Long
'///
If FakeDXUIModalStackCount > 0 Then Exit Function
'///
Select Case nType
Case FakeDXAppEvent_MouseDown
 Button = nParam3 And &HFFFF&
 Select Case Button
 Case 1, 2
  objCamera.LockCamera = Button = 2
  objCamera.BeginDrag nParam1, nParam2
 End Select
Case FakeDXAppEvent_MouseMove
 Button = nParam3 And &HFFFF&
 Select Case Button
 Case 1, 2
  objCamera.Drag nParam1, nParam2, 0.01
 End Select
Case FakeDXAppEvent_MouseWheel
 If nParam1 > 0 Then
  objCamera.Zoom 0.8
 Else
  objCamera.Zoom 1.25
 End If
End Select
End Function

Private Function IFakeDXUIEvent_OnEvent(ByVal obj As clsFakeDXUI, ByVal nType As Long, ByVal nParam1 As Long, ByVal nParam2 As Long, ByVal nParam3 As Long) As Long
'///
Select Case nType
Case FakeCtl_Event_Click
 Select Case obj.Name
 Case "cmdExit"
 ' With New clsFakeDXUIMsgBox
 '  If .MsgBox(objText.GetText("Are you sure?"), vbYesNo Or vbQuestion, objText.GetText("Exit game")) = vbYes Then Unload Me
 ' End With
  FakeDXAppRequestUnload = True '???
 Case "cmdStart"
  objGame.ShowLevelFileSelection
 Case "cmdOptions"
  frmSettings.Show
 Case "cmdAbout"
  frmAbout.Show
 End Select
End Select
End Function

Private Sub IRenderableObject_Hide()
Hide
End Sub

Friend Sub UpdateAnimation()
Dim mat As D3DMATRIX, mat1 As D3DMATRIX
Dim v As D3DVECTOR
Dim i As Long
Dim x As Long, y As Long, tmp As Long
Dim sx As Long, sy As Long, sz As Long
Dim d As Long
Dim f As Single, dt As Single
Dim b As Boolean
'////////////////polyhedron animation
mat = m_matWorldOld
If m_nDirection And 2& Then 'down,right
 x = m_nPolyX + m_nPolySizeX
 y = m_nPolyY + m_nPolySizeY
Else 'up,left
 x = m_nPolyX
 y = m_nPolyY
End If
D3DXMatrixTranslation mat1, -x, -y, 0
D3DXMatrixMultiply mat, mat, mat1
'///
dt = objTiming.GetDelta
m_fAnimValue = m_fAnimValue + dt
If m_fAnimValue > m_fAnimTime Then
 m_fAnimValue = m_fAnimTime
 b = True
End If
f = m_fAnimValue / m_fAnimTime * 1.570796!
'///
Select Case m_nDirection
Case 0 'up
 D3DXMatrixRotationX mat1, f
Case 1 'left
 D3DXMatrixRotationY mat1, -f
Case 2 'down
 D3DXMatrixRotationX mat1, -f
Case 3 'right
 D3DXMatrixRotationY mat1, f
End Select
D3DXMatrixMultiply mat, mat, mat1
D3DXMatrixTranslation mat1, x, y, 0
D3DXMatrixMultiply mat, mat, mat1
'///
d3dd9.SetTransform D3DTS_WORLD, mat
'///
v.x = 0.5!
v.y = 0.5!
v.z = 1!
D3DXVec3TransformCoord v, v, mat
objCamera.MoveTargetTo v
'///
If b Then
 m_fAnimValue = 0
 mat.m11 = Round(mat.m11): mat.m12 = Round(mat.m12): mat.m13 = Round(mat.m13)
 mat.m21 = Round(mat.m21): mat.m22 = Round(mat.m22): mat.m23 = Round(mat.m23)
 mat.m31 = Round(mat.m31): mat.m32 = Round(mat.m32): mat.m33 = Round(mat.m33)
 mat.m41 = Round(mat.m41): mat.m42 = Round(mat.m42): mat.m43 = Round(mat.m43)
 m_matWorldOld = mat
 '///
 i = (m_nQueueIndex + 1) And 31&
 m_nQueueIndex = i
 m_nPolyX = m_tQueue(i).nPolyX
 m_nPolyY = m_tQueue(i).nPolyY
 m_nPolySizeX = m_tQueue(i).nPolySizeX
 m_nPolySizeY = m_tQueue(i).nPolySizeY
 m_nPolySizeZ = m_tQueue(i).nPolySizeZ
 m_nDirection = m_tQueue(i).nDirection
 '///
 i = (i + 15) And 31&
 x = m_tQueue(i).nPolyX
 y = m_tQueue(i).nPolyY
 sx = m_tQueue(i).nPolySizeX
 sy = m_tQueue(i).nPolySizeY
 sz = m_tQueue(i).nPolySizeZ
 d = m_tQueue(i).nDirection
 '///
 Select Case d
 Case 0 'up
  y = y - sz
 Case 1 'left
  x = x - sz
 Case 2 'down
  y = y + sy
 Case 3 'right
  x = x + sx
 End Select
 If d And 1& Then
  tmp = sx: sx = sz: sz = tmp
 Else
  tmp = sy: sy = sz: sz = tmp
 End If
 '///get new direction
 d = CLng(d - 1 + Int(3 * Rnd)) And 3&
 '///
 i = (i + 1) And 31&
 RemoveTileFromQueue m_tQueue(i)
 m_tQueue(i).nPolyX = x
 m_tQueue(i).nPolyY = y
 m_tQueue(i).nPolySizeX = sx
 m_tQueue(i).nPolySizeY = sy
 m_tQueue(i).nPolySizeZ = sz
 m_tQueue(i).nDirection = d
 AddTileFromQueue m_tQueue(i)
End If
'////////////////tile animation
For i = 1 To m_nTileCount
 For y = 0 To 15
  For x = 0 To 15
   d = m_tTile(i).nInstIndex(x, y)
   If d > 0 Then
    f = m_tTile(i).fAnimValue(x, y)
    If m_tTile(i).nData(x, y) > 0 Then
     If f > 0 Then
      f = f - dt
      m_tTile(i).fAnimValue(x, y) = f
     Else
      f = 0
     End If
     f = f / m_fAnimTime
     f = f * f * -10!
     m_tInst.tInstance(d).matWorld.m43 = f
    Else
     f = f + dt
     If f > m_fAnimTime Then
      objEffectMgr.RemoveInstanceEx m_tInst, d
      m_tTile(i).nInstIndex(x, y) = 0
      m_tTile(i).nCount = m_tTile(i).nCount - 1
      Debug.Assert m_tTile(i).nCount >= 0
     Else
      m_tTile(i).fAnimValue(x, y) = f
      f = f / m_fAnimTime
      f = f * f * -10!
      m_tInst.tInstance(d).matWorld.m43 = f
     End If
    End If
   End If
  Next x
 Next y
Next i
End Sub

Private Sub IRenderableObject_Render(ByVal nType As enumRenderPassType, ByVal IsEffectBegin As Boolean, ByVal IsSceneBegin As Boolean)
Dim matOld As D3DMATRIX
'///
Select Case nType
Case RenderPass_Main
 '///
 If m_bShowAnimation Then
  d3dd9.GetTransform D3DTS_WORLD, matOld
  UpdateAnimation
 End If
 '///
 If Not IsEffectBegin Then
  objRenderTest.SetTexture objTexture
  objRenderTest.SetNormalTexture objNormalTexture
  If Not objRenderTest.BeginRender(nType) Then Exit Sub
 End If
 If Not IsSceneBegin Then d3dd9.BeginScene
 '///
 On Error Resume Next
 '///TEST ONLY
 objRenderTest.DrawSkydome objSkyTexture
 '///draw cube with effects
 objTest.DrawSubset 0
 objRenderTest.EndEffect
 'record triangle count
 FakeDXAppTriangleCount = FakeDXAppTriangleCount + objTest.GetNumFaces
 '///draw tiles
 If m_bShowAnimation Then
  d3dd9.SetTransform D3DTS_WORLD, matOld
  objEffectMgr.DrawInstanceEx m_tInst, True, False
 End If
 '////////draw landscape test (new and buggy) without advanced shading effects
 d3dd9.SetTexture 0, objLandTexture
 objLand.Render
 '////////
 '///
 If Not IsSceneBegin Then d3dd9.EndScene
 If Not IsEffectBegin Then objRenderTest.EndRender
Case RenderPass_FogVolume
 'TODO:
Case RenderPass_Overlay
 'doesn't need to draw here
End Select
End Sub
