VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsGameGUI"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Implements IFakeDXUIEvent
Implements IFakeDXAppEvent
Implements IRenderableObject
Implements IMainLoopCallback

Private m_sRecord As String
Private m_nRecordPos As Long

'Private Enum enumGameGUIState
' IDS_Nothing
' IDS_SelectLevel
' IDS_InGame
'End Enum
'
'Private m_nGUIState As enumGameGUIState

'////////controls

Private m_idxForm As Long, m_idxLvFile As Long

Private m_idxProgressForm As Long, m_idxProgress As Long

'////////level file verify

Implements ITreeStorageBuilder

Private m_sLevelName As String, m_nLevelType As Long, m_nLevelCount As Long
Private m_nTreeStorageLevel As Long

Friend Function pVerifyLevelFile(ByRef s As String, ByVal objSerializer As ITreeSerializer) As Boolean
Dim i As Long
'///
m_sLevelName = vbNullString
m_nLevelType = 0
m_nLevelCount = 0
m_nTreeStorageLevel = 0
'///
i = objFileMgr.LoadFile(s)
If i > 0 Then
 If objSerializer.ReadNode(objFileMgr.FilePointer(i), objFileMgr.FileSize(i), Me) Then
  pVerifyLevelFile = True
 End If
End If
End Function

Friend Sub RefreshLevelList()
Dim sFiles() As String
Dim s As String
Dim i As Long, m As Long
Dim objSerializer As ITreeSerializer
'///show form
Create
FakeDXUIControls(m_idxProgressForm).MoveToCenter
FakeDXUIControls(m_idxProgressForm).Show 1
FakeDXAppMainLoop , True
'///get file list
m = objFileMgr.EnumerateFile("levels", sFiles)
'///TODO:process existing files
'///verify file
Set objSerializer = New clsXMLSerializer
FakeDXUIControls(m_idxProgress).Max = m
For i = 1 To m
 s = sFiles(i)
 If LCase(Right(s, 4)) = ".xml" Or LCase(Right(s, 9)) = ".xml.lzma" Then
  If pVerifyLevelFile(s, objSerializer) Then
   'TODO:
  End If
 End If
 '///
 If objTiming.GetMs > 50 Then
  FakeDXUIControls(m_idxProgress).Value = i
  FakeDXUIControls(m_idxProgress).Caption = Format(i / m, "0%")
  FakeDXAppMainLoop , True
 End If
 '///
Next i
'///hide form
FakeDXUIControls(m_idxProgressForm).Hide
'///
End Sub

Friend Sub Create()
If m_idxForm Then Exit Sub
'///
With FakeDXUIControls(1)
 '///level selection screen
 With .AddNewChildren(FakeCtl_Form, 0, 0, 600, 400, _
 FFS_CloseButton Or FFS_MaxButton Or FFS_Moveable Or FFS_TitleBar Or FFS_Sizable, _
 , False, , objText.GetText("Select level"))
  m_idxForm = .Index
  Set .EventObject = Me
  '///list view
  With .AddNewChildren(FakeCtl_ListView, 8, 40, -80, -8, FCS_TabStop Or FCS_CanGetFocus, , , , , , "lstFile", , , 1, 1)
   m_idxLvFile = .Index
   With .ListViewObject
    .FullRowSelect = True
    .ColumnHeader = True
    .AddColumn objText.GetText("Name"), , efctStringCaseInsensitive, efcfSizable Or efcfSortable, 160
    .AddColumn objText.GetText("Type"), , , efcfSizable Or efcfSortable Or efcfSortWithItemData, 96
    .AddColumn objText.GetText("Level count"), , , efcfSizable Or efcfSortable Or efcfSortWithItemData, 96
    .AddColumn objText.GetText("File name"), , efctStringCaseInsensitive, efcfSizable Or efcfSortable, 256
   End With
  End With
  '///some buttons
  .AddNewChildren FakeCtl_Button, -72, 40, -8, 64, FCS_TabStop Or FCS_CanGetFocus Or FBS_Default, , , , objText.GetText("OK"), , "cmdOK", 1, , 1
  .AddNewChildren FakeCtl_Button, -72, 72, -8, 96, FCS_TabStop Or FCS_CanGetFocus Or FBS_Cancel, , , , objText.GetText("Cancel"), , "cmdCancel", 1, , 1
  .AddNewChildren FakeCtl_Button, 8, 8, 72, 32, FCS_TabStop Or FCS_CanGetFocus, , , , objText.GetText("Refresh"), , "cmdRefresh"
  .AddNewChildren FakeCtl_Button, -200, 8, -80, 32, FCS_TabStop Or FCS_CanGetFocus, , , , objText.GetText("Open other file"), , "cmdOpen", 1, , 1
 End With
 '///progress form
 With .AddNewChildren(FakeCtl_Form, 0, 0, 256, 96, _
 FFS_Moveable Or FFS_TitleBar, , False)
  m_idxProgressForm = .Index
  m_idxProgress = .AddNewChildren(FakeCtl_ProgressBar, 8, -10, -80, 10, FTS_UpperCaseOnly, , , , , , , , 0.5, 1, 0.5).Index
  .AddNewChildren FakeCtl_Button, -72, -12, -8, 12, FCS_TabStop Or FCS_CanGetFocus Or FBS_Cancel, , , , objText.GetText("Cancel"), , "cmdCancelProgress", 1, 0.5, 1, 0.5
 End With
End With
'///
End Sub

Friend Sub ShowLevelFileSelection()
Create
With FakeDXUIControls(m_idxForm)
 .MoveToCenter
 .Show 1
End With
'm_nGUIState = IDS_SelectLevel
End Sub

Friend Sub ShowGame()
Create
FakeDXAppChangeRootObject &H7&, Me, Me, Me
objGameMgr.FollowCurrentPolyhedron = True
'm_nGUIState = IDS_InGame
End Sub

Private Function IFakeDXAppEvent_OnEvent(ByVal nType As Long, ByVal nParam1 As Long, ByVal nParam2 As Long, ByVal nParam3 As Long) As Long
Dim v1 As D3DVECTOR, v2 As D3DVECTOR, v3 As D3DVECTOR
Dim f As Single
Dim i As Long
Dim Button As Long
'///
Static nOldX As Long, nOldY As Long
Static vx As D3DVECTOR, vy As D3DVECTOR
'///TEST ONLY
Select Case nType
Case FakeDXAppEvent_KeyDown
 i = -1
 Select Case nParam1
 Case vbKeyUp
  i = 0
 Case vbKeyLeft
  i = 1
 Case vbKeyDown
  i = 2
 Case vbKeyRight
  i = 3
 Case vbKeySpace
  'TODO:when a polyhedron is falling then can't change polyhedron index
  'TODO:skip invalid polyhedron
  i = objGameMgr.CurrentPolyhedron + 1
  If i > objGameMgr.PolyhedronCount Then i = 1
  objGameMgr.CurrentPolyhedron = i
  objGameMgr.FollowCurrentPolyhedron = True
  Exit Function
 Case vbKeyR
  RestartCurrentLevel
  Exit Function
 Case vbKeyQ '??
  BackToMainMenu
  Exit Function
 Case vbKeyF12
  With New clsFakeDXUIInputBox
   m_sRecord = Trim(.InputBox("Input moves:", , , , True, vbVertical))
  End With
  If m_sRecord <> "" Then m_nRecordPos = 1 _
  Else m_nRecordPos = 0
  Exit Function
 End Select
 If i >= 0 Then
  If Not objGameMgr.CurrentPolyhedronObject Is Nothing Then
   '///TODO:get z direction
   objCamera.GetRealCamera v1, v2, v3
   v1.x = v1.x - v2.x
   v1.y = v1.y - v2.y
   v2.x = v1.x - v1.y
   v2.y = v1.x + v1.y
   If v2.x > 0 Then
    If v2.y > 0 Then i = i + 1 _
    Else i = i + 2
   Else
    If v2.y < 0 Then i = i - 1
   End If
   i = i And 3&
   '///
   If objGameMgr.CanPlayerMovePolyhedron Then
    If objGameMgr.MoveCurrentPolyhedron(i) Then
     objGameMgr.FollowCurrentPolyhedron = True
    End If
   End If
  End If
 End If
Case FakeDXAppEvent_MouseDown
 Button = nParam3 And &HFFFF&
 Select Case Button
 Case 1 'rotate
  objCamera.LockCamera = False
  objCamera.BeginDrag nParam1, nParam2
 Case 2 'drag
  nOldX = nParam1
  nOldY = nParam2
  '///TODO:
  objCamera.GetRealCamera v1, v2, v3
  D3DXVec3Normalize v3, v3
  v1.x = v1.x - v2.x
  v1.y = v1.y - v2.y
  v1.z = v1.z - v2.z
  objRenderTest.GetProjection_PerspectiveFovLH f, 0, 0, 0
  f = Tan(f / 2) * 2 / d3dpp.BackBufferHeight
  '---
  v2.x = D3DXVec3LengthSq(v1)
  v2.y = -D3DXVec3Dot(v1, v3)
  vy = Vec3
  If v2.y > 0.000001! Or v2.y < -0.000001! Then
   v2.z = v2.x / v2.y * f
   If v2.z < 1000! And v2.z > -1000! Then
    D3DXVec3Normalize vy, D3DXVec3AddScale(v1, v3, v2.y)
    vy.x = vy.x * v2.z
    vy.y = vy.y * v2.z
    vy.z = vy.z * v2.z
   End If
  End If
  '---
  f = f * Sqr(v2.x)
  v2 = D3DXVec3Cross(v3, v1)
  D3DXVec3Normalize v2, v2
  vx.x = v2.x * f
  vx.y = v2.y * f
  vx.z = v2.z * f
  '///
 End Select
Case FakeDXAppEvent_MouseMove
 Button = nParam3 And &HFFFF&
 Select Case Button
 Case 1
  objCamera.Drag nParam1, nParam2, 0.01
 Case 2
  objGameMgr.FollowCurrentPolyhedron = False
  objCamera.Move vx.x * (nParam1 - nOldX) + vy.x * (nParam2 - nOldY), _
  vx.y * (nParam1 - nOldX) + vy.y * (nParam2 - nOldY), _
  vx.z * (nParam1 - nOldX) + vy.z * (nParam2 - nOldY)
  nOldX = nParam1
  nOldY = nParam2
 End Select
Case FakeDXAppEvent_MouseWheel
 If nParam1 > 0 Then
  objCamera.Zoom 0.8
 Else
  objCamera.Zoom 1.25
 End If
End Select
End Function

Friend Sub RestartCurrentLevel()
objGameMgr.ResetOnNextUpdate = True
objGameMgr.FollowCurrentPolyhedron = True
m_sRecord = ""
m_nRecordPos = 0
End Sub

Private Function IFakeDXUIEvent_OnEvent(ByVal obj As clsFakeDXUI, ByVal nType As Long, ByVal nParam1 As Long, ByVal nParam2 As Long, ByVal nParam3 As Long) As Long
Select Case nType
Case FakeCtl_Event_Click
 Select Case obj.Name
 Case "cmdOK"
 Case "cmdCancel"
  FakeDXUIControls(m_idxForm).Hide
 Case "cmdRefresh"
  RefreshLevelList
 Case "cmdOpen"
 End Select
Case FakeCtl_Event_Unload
 obj.Hide
 IFakeDXUIEvent_OnEvent = 1
End Select
End Function

Private Property Let IMainLoopCallback_Cancel(ByVal RHS As Boolean)
'
End Property

Private Property Get IMainLoopCallback_Cancel() As Boolean
Dim i As Long
Dim bErr As Boolean
'///???
'objGameMgr.UpdateLevelRuntimeData objTiming.GetDelta
'///
If m_nRecordPos > 0 Then
 i = Len(m_sRecord)
 If m_nRecordPos <= i Then
  i = -1
  Select Case UCase(Mid(m_sRecord, m_nRecordPos, 1))
  Case "U"
   i = 0
  Case "L"
   i = 1
  Case "D"
   i = 2
  Case "R"
   i = 3
  Case Else
   'TODO:
   bErr = True
  End Select
  If i >= 0 And i < 4 Then
   If objGameMgr.CanPlayerMovePolyhedron Then
    i = objGameMgr.MoveCurrentPolyhedron(i)
    If i Then objGameMgr.FollowCurrentPolyhedron = True
    If i <> 1 Then
     Debug.Print "???"
     bErr = True
    End If
    m_nRecordPos = m_nRecordPos + 1
   End If
  Else
   'TODO:
   m_nRecordPos = m_nRecordPos + 1
  End If
 Else
  bErr = True
 End If
 '///
 If bErr Then
  m_sRecord = ""
  m_nRecordPos = 0
 End If
End If
'///
If objGameMgr.IsGameOver Then
 With New clsFakeDXUIMsgBox
  .AddButton objText.GetText("Try again"), &H100&, _
  objText.GetText("Restart current level.")
  .AddButton objText.GetText("Back to main menu"), &H101&, _
  objText.GetText("Abort the game and back to the main menu.")
  i = .MsgBox(objText.GetText("Game over. Watch your step next time!"), _
  vbInformation Or &H2800000F, _
  objText.GetText("Oops"), &H100&, 160)
 End With
 Select Case i
 Case &H101&
  BackToMainMenu
 Case Else
  RestartCurrentLevel
 End Select
End If
End Property

Friend Sub BackToMainMenu()
'TODO:etc.
objMainMenu.Show
End Sub

Friend Sub Hide()
If m_idxForm Then FakeDXUIControls(m_idxForm).Hide
'm_nGUIState = 0
End Sub

Private Sub IRenderableObject_Hide()
Hide
End Sub

Private Sub IRenderableObject_Render(ByVal nType As enumRenderPassType, ByVal objRender As clsRenderPipeline, ByVal objCamera As clsCamera, ByVal IsEffectBegin As Boolean, ByVal IsSceneBegin As Boolean)
Dim s As String
'///
Select Case nType
Case RenderPass_Main
 If Not IsEffectBegin Then
  objRenderTest.SetTexture objTexture
  objRenderTest.SetNormalTexture objNormalTexture
  If Not objRender.BeginRender(nType, False) Then Exit Sub
 End If
 '---???
 If FakeDXUIModalStackCount = 0 Then objGameMgr.UpdateLevelRuntimeData objTiming.GetDelta
 '---
 If Not IsSceneBegin Then d3dd9.BeginScene
 objRenderTest.EndEffect
 '///draw level
 objGameMgr.DrawLevel
 '////////draw landscape test (new and buggy) without advanced shading effects
 d3dd9.SetTexture 0, objLandTexture
 objLand.Render objRender, objCamera
 '////////
 '///
 If Not IsSceneBegin Then d3dd9.EndScene
 If Not IsEffectBegin Then objRender.EndRender
Case RenderPass_FogVolume
 'TODO:
Case RenderPass_Overlay
 s = objGameMgr.LevelName
 If s <> vbNullString Then
  If Not IsSceneBegin Then d3dd9.BeginScene
  FakeDXGDIDrawText FakeDXUIDefaultFont, s, 0, 16, d3dpp.BackBufferWidth - 16, 32, , DT_RIGHT Or DT_SINGLELINE Or DT_NOCLIP, , , , , , , , True
  If Not IsSceneBegin Then d3dd9.EndScene
 End If
End Select
End Sub

Private Sub ITreeStorageBuilder_EndNode(Cancel As Boolean)
'TODO:
End Sub

Private Sub ITreeStorageBuilder_NewAttribute(ByVal lpName As Long, ByVal nNameLength As Long, ByVal lpValue As Long, ByVal nValueLength As Long, Cancel As Boolean)
'TODO:
End Sub

Private Function ITreeStorageBuilder_NewNode() As ITreeStorageBuilder
'TODO:
End Function

Private Sub ITreeStorageBuilder_SetName(ByVal lp As Long, ByVal nLength As Long, Cancel As Boolean)
'TODO:
End Sub

Private Sub ITreeStorageBuilder_SetValue(ByVal lp As Long, ByVal nLength As Long, Cancel As Boolean)
'TODO:
End Sub
