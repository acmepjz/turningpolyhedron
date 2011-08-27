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

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)

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
Private m_idxForm2 As Long, m_idxLevels As Long

'////////level file verify and other

Implements ITreeStorageBuilder

Private m_bGetLevelName As Boolean
Private m_sLevelName As String, m_sLevelFile As String, m_nLevelType As Long
Private m_nLevelCountInLevelCollection As Long, m_objLevels() As clsTreeStorageNode
Private m_nTreeStorageLevel As Long

Private m_nCurrentLevelIndex As Long, m_sCurrentLevelName As String
Private m_nMoves As Long

'////////level files

Private Type typeGameLevelIndex
 sName As String
 nType As Long
 nLevelCount As Long
 sFileName As String
End Type

Private m_tLevelIdx() As typeGameLevelIndex
Private m_nLevelIdxCount As Long, m_nLevelIdxMax As Long

'////////random map

Private m_objRandomMapProgress As clsProgressDialog

Implements IRandomMap

Friend Sub LoadLevelList(ByVal fn As String)
Dim obj As New clsTreeStorageNode
Dim i As Long
'///
Erase m_tLevelIdx
m_nLevelIdxCount = 0
m_nLevelIdxMax = 0
'///
With New clsXMLSerializer
 If .LoadNodeFromFile(fn, obj) Then
  If obj.GetNameAsString = "levelList" Then
   For i = 1 To obj.SubNodeCount
    If obj.SubNodeType(i) Then
     With obj.SubNodeObject(i)
      If .GetNameAsString = "levelIndex" Then
       m_nLevelIdxCount = m_nLevelIdxCount + 1
       If m_nLevelIdxCount > m_nLevelIdxMax Then
        m_nLevelIdxMax = m_nLevelIdxMax + 256&
        ReDim Preserve m_tLevelIdx(1 To m_nLevelIdxMax)
       End If
       '///
       m_tLevelIdx(m_nLevelIdxCount).sName = .GetSubNodeValueAsStringByName("name")
       m_tLevelIdx(m_nLevelIdxCount).nType = (Val(.GetSubNodeValueAsStringByName("type")) <> 0) And 1&
       m_tLevelIdx(m_nLevelIdxCount).nLevelCount = Val(.GetSubNodeValueAsStringByName("levels"))
       m_tLevelIdx(m_nLevelIdxCount).sFileName = .GetSubNodeValueAsStringByName("file")
       '///
      End If
     End With
    End If
   Next i
  End If
 End If
End With
End Sub

Friend Sub SaveLevelList(ByVal fn As String)
Dim obj As New clsTreeStorageNode
Dim obj1 As clsTreeStorageNode
Dim i As Long
'///
If m_idxForm = 0 And m_nLevelIdxCount = 0 Then Exit Sub
'///
obj.SetNameFromString "levelList"
For i = 1 To m_nLevelIdxCount
 Set obj1 = New clsTreeStorageNode
 '///
 obj1.SetNameFromString "levelIndex"
 obj1.AddSubNode , , "name", m_tLevelIdx(i).sName
 obj1.AddSubNode , , "type", CStr(m_tLevelIdx(i).nType)
 obj1.AddSubNode , , "levels", CStr(m_tLevelIdx(i).nLevelCount)
 obj1.AddSubNode , , "file", m_tLevelIdx(i).sFileName
 '///
 obj.AddSubNode 1, obj1
Next i
'///
With New clsXMLSerializer
 .SaveNodeToFile fn, obj
End With
End Sub

Friend Function pVerifyLevelFile(ByVal s As String, ByVal objSerializer As ITreeSerializer) As Boolean
Dim i As Long
'///
m_sLevelName = s
i = InStrRev(s, "\")
If i > 0 Then m_sLevelName = Mid(s, i + 1) _
Else m_sLevelName = s
i = InStr(1, LCase(m_sLevelName), ".xml")
If i > 0 Then m_sLevelName = Left(m_sLevelName, i - 1)
'///
m_nLevelType = 0
m_nLevelCountInLevelCollection = 0
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
Dim i As Long, j As Long, m As Long
Dim objSerializer As ITreeSerializer
Dim obj As New Collection
Dim objProgress As New clsProgressDialog
'///show form
objProgress.CreateAndShow objText.GetText("Processing...")
'///get file list and combine to existing files
m = objFileMgr.EnumerateFile("levels", sFiles)
If m > 0 Then
 i = m_nLevelIdxCount + m
 If i > m_nLevelIdxMax Then
  m_nLevelIdxMax = i
  ReDim Preserve m_tLevelIdx(1 To i)
 End If
End If
'///
On Error Resume Next
'///
j = 0
For i = 1 To m_nLevelIdxCount
 Err.Clear
 obj.Add i, m_tLevelIdx(i).sFileName
 If Err.Number Then
  j = j + 1
 ElseIf j > 0 Then
  m_tLevelIdx(i - j).sFileName = m_tLevelIdx(i).sFileName
 End If
Next i
m_nLevelIdxCount = m_nLevelIdxCount - j
'///
For i = 1 To m
 s = sFiles(i)
 If LCase(Right(s, 4)) = ".xml" Or LCase(Right(s, 9)) = ".xml.lzma" Then
  Err.Clear
  obj.Add i, s
  If Err.Number = 0 Then
   m_nLevelIdxCount = m_nLevelIdxCount + 1
   m_tLevelIdx(m_nLevelIdxCount).sFileName = s
  End If
 End If
Next i
'///
On Error GoTo 0
'///
Set obj = Nothing
Erase sFiles
'///verify file
Set objSerializer = New clsXMLSerializer
objProgress.SetProgress , m_nLevelIdxCount
j = 0
For i = 1 To m_nLevelIdxCount
 If pVerifyLevelFile(m_tLevelIdx(i).sFileName, objSerializer) Then
  If j > 0 Then m_tLevelIdx(i - j).sFileName = m_tLevelIdx(i).sFileName
  m_tLevelIdx(i - j).sName = m_sLevelName
  m_tLevelIdx(i - j).nType = m_nLevelType
  m_tLevelIdx(i - j).nLevelCount = m_nLevelCountInLevelCollection
 Else
  j = j + 1
 End If
 '///
 If objTiming.GetMs > 50 Then
  objProgress.SetProgress i, , Format(i / m_nLevelIdxCount, "0%")
  FakeDXAppMainLoop , True
 End If
 '///
 If objProgress.Cancel Then
  m_nLevelIdxCount = i
  Exit For
 End If
Next i
m_nLevelIdxCount = m_nLevelIdxCount - j
If m_nLevelIdxCount < m_nLevelIdxMax Then
 m_nLevelIdxMax = m_nLevelIdxCount
 If m_nLevelIdxCount > 0 Then ReDim Preserve m_tLevelIdx(1 To m_nLevelIdxCount) _
 Else Erase m_tLevelIdx
End If
'///hide form
objProgress.HideAndDestroy
'///over
DisplayLevelList
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
  '///TEST ONLY
  .AddNewChildren FakeCtl_Button, -72, 104, -8, 128, FCS_TabStop Or FCS_CanGetFocus Or FBS_Cancel, , , , "Random", , "cmdRandom", 1, , 1
 End With
 '///form 2
 With .AddNewChildren(FakeCtl_Form, 0, 0, 600, 400, _
 FFS_CloseButton Or FFS_MaxButton Or FFS_Moveable Or FFS_TitleBar Or FFS_Sizable, _
 , False)
  m_idxForm2 = .Index
  Set .EventObject = Me
  '///list view
  With .AddNewChildren(FakeCtl_ListView, 8, 8, -80, -8, FCS_TabStop Or FCS_CanGetFocus, , , , , , "lstLevel", , , 1, 1)
   m_idxLevels = .Index
   With .ListViewObject
    .FullRowSelect = True
    .ColumnHeader = True
    .AddColumn objText.GetText("Level number"), , , efcfSizable Or efcfSortable Or efcfSortWithItemData, 96
    .AddColumn objText.GetText("Name"), , efctStringCaseInsensitive, efcfSizable Or efcfSortable, 320
   End With
  End With
  '///some buttons
  .AddNewChildren FakeCtl_Button, -72, 8, -8, 32, FCS_TabStop Or FCS_CanGetFocus Or FBS_Default, , , , objText.GetText("OK"), , "cmdOK2", 1, , 1
  .AddNewChildren FakeCtl_Button, -72, 40, -8, 64, FCS_TabStop Or FCS_CanGetFocus Or FBS_Cancel, , , , objText.GetText("Cancel"), , "cmdCancel2", 1, , 1
 End With
End With
'///load level index and show item
LoadLevelList FakeDXAppMyGamesPath + "level_list.xml"
DisplayLevelList
End Sub

Friend Sub DisplayLevelList()
Dim i As Long, j As Long, k As Long
Dim s1 As String, s2 As String
'///
Create
'///
With FakeDXUIControls(m_idxLvFile).ListViewObject
 .Clear
 For i = 1 To m_nLevelIdxCount
  j = m_tLevelIdx(i).nType
  If j Then
   s1 = objText.GetText("Level collection")
   k = m_tLevelIdx(i).nLevelCount
   s2 = CStr(k)
  Else
   s1 = objText.GetText("Level")
   k = -1
   s2 = vbNullString
  End If
  '///
  .AddItem m_tLevelIdx(i).sName, , , Array(Array(s1, j), Array(s2, k), m_tLevelIdx(i).sFileName)
 Next i
End With
End Sub

Friend Sub ShowLevelFileSelection()
Create
With FakeDXUIControls(m_idxForm)
 .MoveToCenter
 .Show 1
End With
If m_nLevelIdxCount = 0 Then RefreshLevelList
End Sub

Friend Sub ShowLevelSelection()
Create
With FakeDXUIControls(m_idxForm2)
 .MoveToCenter
 .Show 1
End With
End Sub

Friend Sub ShowGame()
Create
HideLevelFileSelection
FakeDXAppChangeRootObject &H7&, Me, Me, Me
objGameMgr.FollowCurrentPolyhedron = True
objCamera.RealLinearDamping = 1
End Sub

Friend Sub PauseGame()
Dim i As Long
'///stupid MsgBox
With New clsFakeDXUIMsgBox
 .AddButton objText.GetText("Back to game"), vbCancel, _
 objText.GetText("Continue playing the game.")
 If m_nMoves > 0 Then
  .AddButton objText.GetText("Undo"), &H104&, _
  objText.GetText("Undo last move.")
 End If
 .AddButton objText.GetText("Restart level"), &H100&, _
 objText.GetText("Restart current level.")
 .AddButton objText.GetText("Other levels"), &H102&, _
 objText.GetText("Back to level selection screen and select another level to play.")
 .AddButton objText.GetText("Options"), &H200&, _
 objText.GetText("Change the game settings.")
 .AddButton objText.GetText("Back to main menu"), &H101&, _
 objText.GetText("Abort the game and back to the main menu.")
 i = .MsgBox(objText.GetText("Game paused"), _
 &H2800007F, , &H100&, 160)
End With
pProcessMenuAction i
End Sub

Friend Sub DisplayGameOverMenu()
Dim i As Long
'///stupid MsgBox
With New clsFakeDXUIMsgBox
 If m_nMoves > 0 Then
  .AddButton objText.GetText("Undo"), &H104&, _
  objText.GetText("Undo last move.")
 End If
 .AddButton objText.GetText("Try again"), &H100&, _
 objText.GetText("Restart current level.")
 .AddButton objText.GetText("Other levels"), &H102&, _
 objText.GetText("Back to level selection screen and select another level to play.")
 .AddButton objText.GetText("Back to main menu"), &H101&, _
 objText.GetText("Abort the game and back to the main menu.")
 i = .MsgBox(objText.GetText("Game over. Watch your step next time!"), _
 vbInformation Or &H2800000F, _
 objText.GetText("Oops"), &H100&, 160)
End With
pProcessMenuAction i
End Sub

Friend Sub DisplayGameFinishedMenu()
Dim i As Long
'///stupid MsgBox
With New clsFakeDXUIMsgBox
 If m_nLevelType = 1 And m_nCurrentLevelIndex < m_nLevelCountInLevelCollection Then
  .AddButton objText.GetText("Next level"), &H103&, _
  objText.GetText("Play next level.")
 End If
 .AddButton objText.GetText("Other levels"), &H102&, _
 objText.GetText("Back to level selection screen and select another level to play.")
 .AddButton objText.GetText("Restart level"), &H100&, _
 objText.GetText("Restart current level.")
 .AddButton objText.GetText("Back to main menu"), &H101&, _
 objText.GetText("Abort the game and back to the main menu.")
 i = .MsgBox(objText.GetText("Congratulations! You have finished this level."), _
 vbInformation Or &H2800000F, , &H100&, 160)
End With
pProcessMenuAction i
End Sub

Friend Sub UndoLastMove()
If m_nMoves > 0 And m_nRecordPos = 0 Then
 m_nMoves = m_nMoves - 1
 objGameMgr.Undo m_nMoves
End If
End Sub

Friend Sub pProcessMenuAction(ByVal i As Long)
Select Case i
Case &H100&
 RestartCurrentLevel
Case &H101&
 BackToMainMenu
Case &H102&
 BackToLevelSelection
Case &H103&
 If m_nLevelType = 1 And m_nCurrentLevelIndex < m_nLevelCountInLevelCollection Then
  i = m_nCurrentLevelIndex + 1
  m_nCurrentLevelIndex = i
  If LoadNodeAndPlay(m_objLevels(i)) Then Exit Sub
  '///show error message
  With New clsFakeDXUIMsgBox
   .MsgBox Replace(objText.GetText("Error when loading level %d in level collection file:"), "%d", i) _
   + vbCrLf + m_sLevelFile, vbExclamation, objText.GetText("Error")
  End With
 End If
 BackToLevelSelection
Case &H104&
 UndoLastMove
Case &H200&
 frmSettings.Show
End Select
End Sub

Friend Sub BackToLevelSelection()
'///
objGameMgr.ClearLevelRuntimeData
FakeDXAppRemoveDataLevel 2
'///
With FakeDXUIControls(m_idxForm)
 .MoveToCenter
 .Show 1
End With
If m_nLevelType Then
 With FakeDXUIControls(m_idxForm2)
  .MoveToCenter
  .Show 1
 End With
End If
End Sub

Private Sub Class_Terminate()
SaveLevelList FakeDXAppMyGamesPath + "level_list.xml"
End Sub

Private Function IFakeDXAppEvent_OnEvent(ByVal nType As Long, ByVal nParam1 As Long, ByVal nParam2 As Long, ByVal nParam3 As Long) As Long
Dim v1 As D3DVECTOR, v2 As D3DVECTOR, v3 As D3DVECTOR
Dim f As Single
Dim i As Long
Dim Button As Long
Dim s As String
'///
Static nOldX As Long, nOldY As Long
Static vx As D3DVECTOR, vy As D3DVECTOR
'///
If FakeDXUIModalStackCount > 0 Then Exit Function
'///
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
  If objGameMgr.CanPlayerMovePolyhedron Then
   objGameMgr.CurrentPolyhedron = objGameMgr.GetNextVisiblePolyhedron
   objGameMgr.FollowCurrentPolyhedron = True
   objCamera.RealLinearDamping = 1
  End If
  Exit Function
 Case vbKeyR
  RestartCurrentLevel
  Exit Function
 Case vbKeyQ '??
  BackToMainMenu
  Exit Function
 Case vbKeyU
  UndoLastMove
  Exit Function
 Case vbKeyEscape
  PauseGame
  Exit Function
 Case vbKeyF12 'TEST ONLY
  With New clsFakeDXUIInputBox
   s = Trim(.InputBox("Input moves:", , objGameMgr.LevelSolution, , True, vbVertical))
  End With
  If s <> vbNullString Then
   m_sRecord = s
   m_nRecordPos = 1
  End If
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
    If objGameMgr.MoveCurrentPolyhedron(i, m_nMoves) Then
     objGameMgr.FollowCurrentPolyhedron = True
     objCamera.RealLinearDamping = 1
     m_nMoves = m_nMoves + 1
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
objCamera.RealLinearDamping = 1
m_sRecord = ""
m_nRecordPos = 0
m_nMoves = 0
End Sub

Friend Sub DisplayLevelInLevelCollection()
Dim i As Long, s As String
Dim obj As clsTreeStorageNode
'///
Create
'///
With FakeDXUIControls(m_idxLevels).ListViewObject
 .Clear
 For i = 1 To m_nLevelCountInLevelCollection
  Set obj = m_objLevels(i).GetSubNodeObjectByName("name")
  If obj Is Nothing Then s = Replace(objText.GetText("Level %d"), "%d", CStr(i)) _
  Else s = obj.GetValueAsString
  .AddItem CStr(i), , i, s
 Next i
End With
End Sub

Friend Function LoadNodeAndPlay(ByVal obj As clsTreeStorageNode) As Boolean
Dim s2 As String
Dim b As Boolean
'///
FakeDXAppRemoveDataLevel 2
FakeDXAppAddDataLevel 2
'///
b = m_nLevelType = 0
objGameMgr.ClearLevelData b
If objGameMgr.AddLevelDataFromNode(obj) Then
 '///get level name
 s2 = objGameMgr.LevelName
 If b Then
  If s2 <> vbNullString Then m_sLevelName = s2
  m_sCurrentLevelName = m_sLevelName
 Else
  m_sCurrentLevelName = Replace(objText.GetText("Level %d"), "%d", CStr(m_nCurrentLevelIndex))
  If s2 <> vbNullString Then m_sCurrentLevelName = m_sCurrentLevelName + ": " + s2
 End If
 '///
 objGameMgr.CreateLevelRuntimeData
 ShowGame
 m_nMoves = 0
 LoadNodeAndPlay = True
Else
 FakeDXAppRemoveDataLevel 2
End If
End Function

Friend Sub LoadFileAndPlay(ByVal s As String)
Dim i As Long, j As Long, idx As Long
Dim obj As New clsTreeStorageNode
Dim s1 As String, s2 As String
Dim bErr As Boolean
'///
FakeDXAppRemoveDataLevel 1
'///
m_sLevelName = s
i = InStrRev(s, "\")
If i > 0 Then m_sLevelName = Mid(s, i + 1) _
Else m_sLevelName = s
i = InStr(1, LCase(m_sLevelName), ".xml")
If i > 0 Then m_sLevelName = Left(m_sLevelName, i - 1)
'///
m_sLevelFile = s
m_nLevelType = 0
m_nLevelCountInLevelCollection = 0
'///
Create
'///check if it exists
s1 = LCase(s)
For i = 1 To m_nLevelIdxCount
 If s1 = LCase(m_tLevelIdx(i).sFileName) Then
  Exit For
 End If
Next i
If i > m_nLevelIdxCount Then i = 0
'///verify
bErr = True
idx = objFileMgr.LoadFile(s)
If idx > 0 Then
 With New clsXMLSerializer
  If .ReadNode(objFileMgr.FilePointer(idx), objFileMgr.FileSize(idx), obj) Then
   Select Case obj.GetNameAsString
   Case "level"
    bErr = Not LoadNodeAndPlay(obj)
   Case "levelCollection"
    FakeDXAppAddDataLevel 1
    m_nLevelType = 1
    objGameMgr.ClearLevelData
    If objGameMgr.LoadLevelCollectionFromNode(obj, m_nLevelCountInLevelCollection, m_objLevels, m_sLevelName) Then
     FakeDXUIControls(m_idxForm2).Caption = Replace(objText.GetText("Selet level in %s"), "%s", m_sLevelName)
     DisplayLevelInLevelCollection
     ShowLevelSelection
     '///
     bErr = False
    End If
   End Select
  End If
 End With
 objFileMgr.CloseFile idx
End If
'///
With FakeDXUIControls(m_idxLvFile).ListViewObject
 For j = 1 To .RowCount
  If s1 = LCase(.List(j, 4)) Then Exit For
 Next j
 If j > .RowCount Then j = 0
End With
'///
If bErr Then
 FakeDXAppRemoveDataLevel 1
 '///remove from level list
 If i > 0 Then
  For i = i To m_nLevelIdxCount - 1
   m_tLevelIdx(i) = m_tLevelIdx(i + 1)
  Next i
  m_nLevelIdxCount = m_nLevelIdxCount - 1
  If j > 0 Then _
  FakeDXUIControls(m_idxLvFile).ListViewObject.RemoveItem j
 End If
 '///show error message
 With New clsFakeDXUIMsgBox
  .MsgBox objText.GetText("Error when loading level file:") + vbCrLf + s, vbExclamation, objText.GetText("Error")
 End With
Else
 '///add to level list
 If i = 0 Then
  i = m_nLevelIdxCount + 1
  m_nLevelIdxCount = i
  If i > m_nLevelIdxMax Then
   m_nLevelIdxMax = m_nLevelIdxMax + 16&
   ReDim Preserve m_tLevelIdx(1 To m_nLevelIdxMax)
  End If
  m_tLevelIdx(i).sFileName = s
 End If
 '///update level info
 m_tLevelIdx(i).sName = m_sLevelName
 m_tLevelIdx(i).nType = m_nLevelType
 m_tLevelIdx(i).nLevelCount = m_nLevelCountInLevelCollection
 '///show
 With FakeDXUIControls(m_idxLvFile).ListViewObject
  If j = 0 Then j = .AddItem(vbNullString, , , Array(, , s))
  .List(j, 1) = m_sLevelName
  .ItemData(j, 2) = m_nLevelType
  If m_nLevelType Then
   .List(j, 2) = objText.GetText("Level collection")
   .ItemData(j, 3) = m_nLevelCountInLevelCollection
   .List(j, 3) = CStr(m_nLevelCountInLevelCollection)
  Else
   .List(j, 2) = objText.GetText("Level")
   .ItemData(j, 3) = -1
   .List(j, 3) = vbNullString
  End If
 End With
End If
End Sub

Private Function IRandomMap_Callback(ByVal nCurrentGeneration As Long, ByVal nGenerationCount As Long) As Long
If Not m_objRandomMapProgress Is Nothing Then
 If objTiming.GetMs > 50 Then
  m_objRandomMapProgress.SetProgress nCurrentGeneration, nGenerationCount
  FakeDXAppMainLoop , True
 End If
 If m_objRandomMapProgress.Cancel Then IRandomMap_Callback = 1
End If
End Function

'TEST ONLY
Friend Sub RandomTest()
Dim objMap As Long, objMap2 As Long
Dim objGA As Long
Dim s As String, m As Long
Dim b As Boolean
Dim obj As New clsTreeStorageNode
'///
Dim objCallback As IRandomMap
Dim lpCallback As Long, lpUserData As Long
'///
Set objCallback = Me
lpUserData = ObjPtr(objCallback)
CopyMemory m, ByVal lpUserData, 4&
CopyMemory lpCallback, ByVal m + 28&, 4&
Set objCallback = Nothing
'///
Set m_objRandomMapProgress = New clsProgressDialog
m_objRandomMapProgress.CreateAndShow "Generating..."
'///
MTInitFromString CStr(Timer)
'///
's = "Type SimpleSolverGA Width 15 Height 10 SizeX 1 SizeY 1 SizeZ 2"
s = "Type ColorZoneSolverGA Width 5 Height 5 SizeX 1 SizeY 1 SizeZ 2 ColorCount 4"
'///
objMap = StdMapCreateFromString(s, 32, 32, True)
objMap2 = StdMapCreateFromString("RandomFitness 10", 32, 32, True)
'///
objGA = GACreate
If GACreatePool(objGA, objMap, 5) Then
 If GARun(objGA, 5, objMap2, lpCallback, lpUserData) Then
  s = Space(65536)
  m = GABaseOutputToString(GAGetPoolItem(objGA, 0), ByVal StrPtr(s), 131072, 1)
  b = True
 End If
End If
GADestroy objGA
'///
StdMapDestroy objMap
StdMapDestroy objMap2
'///
m_objRandomMapProgress.HideAndDestroy
Set m_objRandomMapProgress = Nothing
'///
If b Then
 With New clsXMLSerializer
  b = .ReadNode(StrPtr(s), m, obj)
 End With
 If b Then
  m_nLevelType = 0
  m_sLevelName = "Random level"
  b = LoadNodeAndPlay(obj)
 End If
End If
If Not b Then
 Debug.Print "ERR"
End If
End Sub

Private Function IFakeDXUIEvent_OnEvent(ByVal obj As clsFakeDXUI, ByVal nType As Long, ByVal nParam1 As Long, ByVal nParam2 As Long, ByVal nParam3 As Long) As Long
Dim s As String
Dim bDblClickLevelFile As Boolean
Dim bDblClickLevel As Boolean
Dim i As Long
'///
Select Case nType
Case FakeCtl_Event_Click
 Select Case obj.Name
 Case "cmdOK"
  bDblClickLevelFile = True
 Case "cmdCancel"
  FakeDXUIControls(m_idxForm).Hide
  BackToMainMenu
 Case "cmdOK2"
  bDblClickLevel = True
 Case "cmdCancel2"
  FakeDXUIControls(m_idxForm2).Hide
 Case "cmdRefresh"
  RefreshLevelList
 Case "cmdOpen"
  With New clsFakeCommonDialog
   If .VBGetOpenFileName(s, , , , , objText.GetText("XML level file") + "|*.xml;*.xml.lzma", , App.Path + "\data\") Then
    LoadFileAndPlay s
   End If
  End With
 Case "cmdRandom" 'TEST ONLY
  RandomTest
 End Select
Case FakeCtl_Event_DblClick
 Select Case obj.Name
 Case "lstFile"
  bDblClickLevelFile = True
 Case "lstLevel"
  bDblClickLevel = True
 End Select
Case FakeCtl_Event_Unload
 obj.Hide
 IFakeDXUIEvent_OnEvent = 1
 '///
 If obj.Index = m_idxForm Then BackToMainMenu
End Select
'///
If bDblClickLevelFile Then
 With FakeDXUIControls(m_idxLvFile).ListViewObject
  If .SelectedRow > 0 And .SelectedRow <= .RowCount Then s = .List(.SelectedRow, 4)
 End With
 If s <> vbNullString Then LoadFileAndPlay s
ElseIf bDblClickLevel Then
 With FakeDXUIControls(m_idxLevels).ListViewObject
  If .SelectedRow > 0 And .SelectedRow <= .RowCount Then i = .ItemData(.SelectedRow, 1)
 End With
 If i > 0 And i <= m_nLevelCountInLevelCollection And m_nLevelType = 1 Then
  m_nCurrentLevelIndex = i
  If Not LoadNodeAndPlay(m_objLevels(i)) Then
   '///show error message
   With New clsFakeDXUIMsgBox
    .MsgBox Replace(objText.GetText("Error when loading level %d in level collection file:"), "%d", i) _
    + vbCrLf + m_sLevelFile, vbExclamation, objText.GetText("Error")
   End With
  End If
 End If
End If
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
    i = objGameMgr.MoveCurrentPolyhedron(i, m_nMoves)
    If i Then
     objGameMgr.FollowCurrentPolyhedron = True
     m_nMoves = m_nMoves + 1
    End If
    If i <> 1 Then '???
     objLogger.AddMessage "Invalid move", , &HFFFF0000
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
 DisplayGameOverMenu
ElseIf objGameMgr.IsGameFinished Then
 DisplayGameFinishedMenu
End If
End Property

Friend Sub BackToMainMenu()
'TODO:etc.
objMainMenu.Show
End Sub

Friend Sub HideLevelFileSelection()
If m_idxForm2 Then FakeDXUIControls(m_idxForm2).Hide
If m_idxForm Then FakeDXUIControls(m_idxForm).Hide
End Sub

Friend Sub Hide()
HideLevelFileSelection
'///
FakeDXAppRemoveDataLevel 1
End Sub

Private Sub IRenderableObject_Hide()
Hide
End Sub

Private Sub IRenderableObject_Render(ByVal nType As enumRenderPassType, ByVal objRender As clsRenderPipeline, ByVal objCamera As clsCamera, ByVal IsEffectBegin As Boolean, ByVal IsSceneBegin As Boolean)
Dim m As Long
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
 If Not IsSceneBegin Then d3dd9.BeginScene
 FakeDXGDIDrawText FakeDXUIDefaultFont, m_sCurrentLevelName, 0, 16, d3dpp.BackBufferWidth - 16, 32, 0.75, DT_RIGHT Or DT_SINGLELINE Or DT_NOCLIP, , , &HFF000000, , , , , True
 m = objGameMgr.CheckPointCount
 FakeDXGDIDrawText FakeDXUIDefaultFont, _
 objText.GetText("Moves: ") + CStr(m_nMoves) + vbCrLf + _
 objText.GetText("Checkpoints: ") + CStr(m - objGameMgr.CheckPointRemaining) + "/" + CStr(m), _
 d3dpp.BackBufferWidth - 128, 48, 128, 32, 0.5, DT_NOCLIP, , , &HFF000000, , , , , True
 If Not IsSceneBegin Then d3dd9.EndScene
End Select
End Sub

Private Sub ITreeStorageBuilder_EndNode(Cancel As Boolean)
m_nTreeStorageLevel = m_nTreeStorageLevel - 1
End Sub

Private Sub ITreeStorageBuilder_NewAttribute(ByVal lpName As Long, ByVal nNameLength As Long, ByVal lpValue As Long, ByVal nValueLength As Long, Cancel As Boolean)
'nothing to do
End Sub

Private Function ITreeStorageBuilder_NewNode() As ITreeStorageBuilder
m_nTreeStorageLevel = m_nTreeStorageLevel + 1
Set ITreeStorageBuilder_NewNode = Me
End Function

Private Sub ITreeStorageBuilder_SetName(ByVal lp As Long, ByVal nLength As Long, Cancel As Boolean)
Dim s As String
m_bGetLevelName = False
If m_nTreeStorageLevel <= 1 Then
 If nLength > 32 Then nLength = 32
 If nLength > 0 Then
  s = Space((nLength + 1) \ 2&)
  CopyMemory ByVal StrPtr(s), ByVal lp, nLength
 End If
 Select Case m_nTreeStorageLevel
 Case 0
  Select Case s
  Case "level"
   m_nLevelType = 0
  Case "levelCollection"
   m_nLevelType = 1
  Case Else
   Cancel = True
  End Select
 Case 1
  Select Case s
  Case "name"
   m_bGetLevelName = True
  Case "level"
   If m_nLevelType = 1 Then m_nLevelCountInLevelCollection = m_nLevelCountInLevelCollection + 1
  End Select
 End Select
End If
End Sub

Private Sub ITreeStorageBuilder_SetValue(ByVal lp As Long, ByVal nLength As Long, Cancel As Boolean)
If m_bGetLevelName And nLength > 0 Then
 m_sLevelName = Space((nLength + 1) \ 2&)
 CopyMemory ByVal StrPtr(m_sLevelName), ByVal lp, nLength
End If
m_bGetLevelName = False
End Sub
