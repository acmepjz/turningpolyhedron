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

Private Declare Function MakeSureDirectoryPathExists Lib "imagehlp.dll" (ByVal DirPath As String) As Long

Implements IFakeDXUIEvent
Implements IFakeDXAppEvent
Implements IRenderableObject
Implements IMainLoopCallback

'////////record (experimental)

Private m_sRecord As String
Private m_nRecordPos As Long, m_fRecordTimer As Single

Private Const m_fMovingTimer As Single = 250
Private Const m_fSwitchTimer As Single = 500

'Private Enum enumGameGUIState
' IDS_Nothing
' IDS_SelectLevel
' IDS_InGame
'End Enum
'
'Private m_nGUIState As enumGameGUIState

'////////controls

Private m_idxMenu As Long
Private m_idxForm As Long, m_idxLvFile As Long
Private m_idxForm2 As Long, m_idxLevels As Long

'////////level file verify and other

Implements ITreeStorageBuilder

Private m_bGetLevelName As Boolean
Private m_sLevelName As String, m_sLevelFile As String
Private m_nLevelType As Long
'0=level
'1=level collection
'2=random level (experimental)
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

'////////random map (experimental)

Private m_idxFormRnd As Long, m_idxFormRnd_1 As Long, m_idxSeed As Long
Private m_nRndOptionsTop As Long

Private m_objRandomMapProgress As clsProgressDialog

Implements IRandomMap

Private Type typeString
 s(127) As Byte
End Type

Private m_nLastProgress As Long, m_nNextProgress As Long, m_fAverageSpeed As Single

Private m_bRandomMapFile() As Byte

'////////solver (experimental)

Private m_idxFormSolver As Long, m_idxSolverType As Long, m_idxSolverDefault As Long

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
Dim y As Long
Dim t() As typeString, s As String, s2 As String
Dim i As Long, m As Long
'///
If m_idxForm Then Exit Sub
'///
With FakeDXUIControls(1)
 '///some button
 With .AddNewChildren(FakeCtl_None, 0, 0, 0, 0, , , False, , , , , , , 1, 1)
  m_idxMenu = .Index
  Set .EventObject = Me
  '///
  .AddNewChildren FakeCtl_Button, 8, -32, 72, -8, , , , , _
  objText.GetText("Menu"), , "cmdMenu", , 1, , 1, , , _
  objText.GetText("Pause the game and display in-game menu.") + " (Esc)"
  '///
 End With
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
  .AddNewChildren FakeCtl_Button, -328, 8, -208, 32, FCS_TabStop Or FCS_CanGetFocus, , , , objText.GetText("Open other file"), , "cmdOpen", 1, , 1
  '///TEST ONLY
  .AddNewChildren FakeCtl_Button, -200, 8, -80, 32, FCS_TabStop Or FCS_CanGetFocus, , , , objText.GetText("Random level"), , "cmdRandom", 1, , 1
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
 '///random level
 ReDim t(255)
 '///
 With .AddNewChildren(FakeCtl_Form, 0, 0, 600, 440, _
 FFS_CloseButton Or FFS_MaxButton Or FFS_Moveable Or FFS_TitleBar Or FFS_Sizable, , False, , _
 objText.GetText("Random level"))
  m_idxFormRnd = .Index
  Set .EventObject = Me
  '///some warning
  .AddNewChildren FakeCtl_Label, 8, 8, -8, -8, FLS_IconExclamation Or FLS_WordWrap, , , , _
  objText.GetText("Warning: Random level generator is an experimental feature. Inappropriate input arguments may produce wrong result, make the program out of response or crash the program. Use at your own risk."), _
  , , , , 1, 1
  '///
  With .AddNewChildren(FakeCtl_None, 0, 64, 0, -40, FCS_CanGetFocus Or FCS_TabStop Or FCS_AutoScroll, , , , , , , , , 1, 1)
   With .AddNewChildren(FakeCtl_None, 0, 0, 572, 320)
    m_idxFormRnd_1 = .Index
    '///
    y = 8
    '///combobox
    .AddNewChildren FakeCtl_Label, 8, y, 160, y + 24, , , , , objText.GetText("Type")
    With .AddNewChildren(FakeCtl_ComboBox, 168, y, -8, y + 24, FCS_CanGetFocus Or FCS_TabStop, , , , , , "ga__Type", , , 1).ListViewObject
     .FullRowSelect = True
     .AddColumn vbNullString
     '///
     m = GetAvaliableRandomMapGenerators(t(0), 128, 256)
     For i = 0 To m - 1
      s = StrConv(t(i).s, vbUnicode)
      s = Left(s, InStr(1, s, vbNullChar) - 1)
      .AddItem s
     Next i
     '///
    End With
    y = y + 32
    '///
    .AddNewChildren FakeCtl_Label, 8, y, 160, y + 24, , , , , objText.GetText("Pool size")
    .AddNewChildren(FakeCtl_TextBox, 168, y, -8, y + 24, FCS_CanGetFocus Or FCS_TabStop Or FTS_AutoSelect Or FTS_NumberOnly Or FTS_UpDown, , , , , "100", "txtPoolSize", , , 1).SmallChange = 1
    y = y + 32
    '///
    .AddNewChildren FakeCtl_Label, 8, y, 160, y + 24, , , , , objText.GetText("Generations")
    .AddNewChildren(FakeCtl_TextBox, 168, y, -8, y + 24, FCS_CanGetFocus Or FCS_TabStop Or FTS_AutoSelect Or FTS_NumberOnly Or FTS_UpDown, , , , , "100", "txtGenerations", , , 1).SmallChange = 1
    y = y + 32
    '///
    .AddNewChildren FakeCtl_Label, 8, y, 160, y + 24, , , , , objText.GetText("Random seed")
    m_idxSeed = .AddNewChildren(FakeCtl_TextBox, 168, y, -80, y + 24, FCS_CanGetFocus Or FCS_TabStop Or FTS_AutoSelect, , , , , "100", "txtSeed", , , 1).Index
    .AddNewChildren FakeCtl_Button, -72, y, -8, y + 24, FCS_CanGetFocus Or FCS_TabStop, , , , objText.GetText("New"), , "cmdSeed", 1, , 1
    y = y + 32
    '///GA options
    y = y + 8
    m = GetAvaliableGAOptions(t(0), 128, 128)
    For i = 0 To m - 1
     s = StrConv(t(i + i).s, vbUnicode)
     s = Left(s, InStr(1, s, vbNullChar) - 1)
     .AddNewChildren FakeCtl_Label, 8, y, 160, y + 24, , , , , s
     s2 = StrConv(t(i + i + 1).s, vbUnicode)
     s2 = Left(s2, InStr(1, s2, vbNullChar) - 1)
     .AddNewChildren FakeCtl_TextBox, 168, y, -8, y + 24, FCS_CanGetFocus Or FCS_TabStop Or FTS_AutoSelect, , , , , s2, "ga__" + s, , , 1
     y = y + 32
    Next i
    '///
    m_nRndOptionsTop = y + 8
    '///
    .SetBottomEx m_nRndOptionsTop, 0
   End With
  End With
  '///some buttons
  .AddNewChildren FakeCtl_Button, -144, -32, -80, -8, FCS_TabStop Or FCS_CanGetFocus Or FBS_Default, , , , objText.GetText("OK"), , "cmdOK3", 1, 1, 1, 1
  .AddNewChildren FakeCtl_Button, -72, -32, -8, -8, FCS_TabStop Or FCS_CanGetFocus Or FBS_Cancel, , , , objText.GetText("Cancel"), , "cmdCancel3", 1, 1, 1, 1
 End With
 '///solver
 With .AddNewChildren(FakeCtl_Form, 0, 0, 400, 200, _
 FFS_CloseButton Or FFS_Moveable Or FFS_TitleBar, , False, , _
 objText.GetText("Solve level"))
  m_idxFormSolver = .Index
  Set .EventObject = Me
  '///combobox
  .AddNewChildren FakeCtl_Label, 8, 8, 88, 32, , , , , objText.GetText("Type")
  With .AddNewChildren(FakeCtl_ComboBox, 96, 8, -8, 32, FCS_CanGetFocus Or FCS_TabStop, , , , , , , , , 1)
   m_idxSolverType = .Index
   With .ListViewObject
    .FullRowSelect = True
    .AddColumn vbNullString
    '///
    m = GetAvaliableSolvers(t(0), 128, 256)
    For i = 0 To m - 1
     s = StrConv(t(i).s, vbUnicode)
     s = Left(s, InStr(1, s, vbNullChar) - 1)
     .AddItem s
    Next i
   End With
  End With
  '///some warning
  .AddNewChildren FakeCtl_Label, 8, 40, -8, -40, FLS_IconExclamation Or FLS_WordWrap, , , , _
  objText.GetText("Warning: Automatic level solver is an experimental feature. Not all levels can be solved using level solver. Inappropriate solver types may produce wrong result, make the program out of response or crash the program. Use at your own risk."), _
  , , , , 1, 1
  '///default solution?
  With .AddNewChildren(FakeCtl_None, 0, -96, 0, -24, , , False, , , , , , 1, 1, 1)
   m_idxSolverDefault = .Index
   .AddNewChildren FakeCtl_Label, 8, 0, -120, 0, FLS_IconInformation Or FLS_WordWrap, , , , _
   objText.GetText("There is a solution included in the level file, but it may be incorrect. Do you want to view the solution?"), _
   , , , , 1, 1
   .AddNewChildren FakeCtl_Button, -112, 8, -8, -24, FCS_TabStop Or FCS_CanGetFocus, , , , objText.GetText("View solution"), , "cmdViewSolution", 1, , 1, 1, , , _
   objText.GetText("View the solution included in the level file.") + " (F12)"
  End With
  '///some buttons
  .AddNewChildren FakeCtl_Button, -144, -32, -80, -8, FCS_TabStop Or FCS_CanGetFocus Or FBS_Default, , , , objText.GetText("OK"), , "cmdOK4", 1, 1, 1, 1
  .AddNewChildren FakeCtl_Button, -72, -32, -8, -8, FCS_TabStop Or FCS_CanGetFocus Or FBS_Cancel, , , , objText.GetText("Cancel"), , "cmdCancel4", 1, 1, 1, 1
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

Friend Sub ShowSolver()
Dim b As Boolean
'///
Create
'///
b = objGameMgr.LevelSolutionIncluded
FakeDXUIControls(m_idxSolverDefault).Visible = b
'///
With FakeDXUIControls(m_idxFormSolver)
 If b Then .SetBottomEx .TopEx.a + 264, 0 _
 Else .SetBottomEx .TopEx.a + 200, 0
 .MoveToCenter
 .Show 1
End With
End Sub

Friend Sub HideSolver()
If m_idxFormSolver Then FakeDXUIControls(m_idxFormSolver).Hide
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
'///
FakeDXUIControls(m_idxMenu).Show
'///
objGameMgr.FollowCurrentPolyhedron = True
objCamera.RealLinearDamping = 1
End Sub

Friend Sub PauseGame()
Dim i As Long
'///stupid MsgBox
With New clsFakeDXUIMsgBox
 .AddButton objText.GetText("Back to game"), vbCancel, _
 objText.GetText("Continue playing the game.")
 If m_nMoves > 0 And m_nRecordPos = 0 Then
  .AddButton objText.GetText("Undo"), &H104&, _
  objText.GetText("Undo last move.") + " (U)"
 End If
 .AddButton objText.GetText("Restart level"), &H100&, _
 objText.GetText("Restart current level.") + " (R)"
 If m_nLevelType = 2 Then
  .AddButton objText.GetText("Save level"), &H106&, _
  objText.GetText("Save current level to file.") + " (Ctrl+S)"
  .AddButton objText.GetText("Next level"), &H103&, _
  objText.GetText("Play next level.")
 End If
 .AddButton objText.GetText("Solve level"), &H105&, _
 objText.GetText("Solve current level using automatic solvers.")
 .AddButton objText.GetText("Other levels"), &H102&, _
 objText.GetText("Back to level selection screen and select another level to play.")
 .AddButton objText.GetText("Options"), &H200&, _
 objText.GetText("Change the game settings.")
 .AddButton objText.GetText("Back to main menu"), &H101&, _
 objText.GetText("Abort the game and back to the main menu.") + " (Q)"
 i = .MsgBox(objText.GetText("Game paused"), _
 &H2800007F, , &H100&, 160)
End With
pProcessMenuAction i
End Sub

Friend Sub DisplayGameOverMenu()
Dim i As Long
'///
m_sRecord = vbNullString
m_nRecordPos = 0
'///stupid MsgBox
With New clsFakeDXUIMsgBox
 If m_nMoves > 0 Then
  .AddButton objText.GetText("Undo"), &H104&, _
  objText.GetText("Undo last move.") + " (U)"
 End If
 .AddButton objText.GetText("Try again"), &H100&, _
 objText.GetText("Restart current level.") + " (R)"
 If m_nLevelType = 2 Then
  .AddButton objText.GetText("Save level"), &H106&, _
  objText.GetText("Save current level to file.") + " (Ctrl+S)"
 End If
 .AddButton objText.GetText("Other levels"), &H102&, _
 objText.GetText("Back to level selection screen and select another level to play.")
 .AddButton objText.GetText("Back to main menu"), &H101&, _
 objText.GetText("Abort the game and back to the main menu.") + " (Q)"
 i = .MsgBox(objText.GetText("Game over. Watch your step next time!"), _
 vbInformation Or &H2800000F, _
 objText.GetText("Oops"), &H100&, 160)
End With
pProcessMenuAction i
End Sub

Friend Sub DisplayGameFinishedMenu()
Dim i As Long
'///
m_sRecord = vbNullString
m_nRecordPos = 0
'///stupid MsgBox
With New clsFakeDXUIMsgBox
 If (m_nLevelType = 1 And m_nCurrentLevelIndex < m_nLevelCountInLevelCollection) Or m_nLevelType = 2 Then
  .AddButton objText.GetText("Next level"), &H103&, _
  objText.GetText("Play next level.")
 End If
 If m_nLevelType = 2 Then
  .AddButton objText.GetText("Save level"), &H106&, _
  objText.GetText("Save current level to file.") + " (Ctrl+S)"
 End If
 .AddButton objText.GetText("Other levels"), &H102&, _
 objText.GetText("Back to level selection screen and select another level to play.")
 .AddButton objText.GetText("Restart level"), &H100&, _
 objText.GetText("Restart current level.") + " (R)"
 .AddButton objText.GetText("Back to main menu"), &H101&, _
 objText.GetText("Abort the game and back to the main menu.") + " (Q)"
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
 ElseIf m_nLevelType = 2 Then
  NewRandomSeed
  If GenerateRandomLevelAndPlay Then Exit Sub
 End If
 BackToLevelSelection
Case &H104&
 UndoLastMove
Case &H105&
 ShowSolver
Case &H106&
 SaveCurrentLevel
Case &H200&
 frmSettings.Show
End Select
End Sub

Friend Sub SaveCurrentLevel()
Dim s As String, s1 As String
Dim b As Boolean
'///
Select Case m_nLevelType
Case 0
 'TODO:
 Exit Sub
Case 1
 'TODO:
 Exit Sub
Case 2
 '///
 s1 = FakeDXAppMyGamesPath + "levels\"
 MakeSureDirectoryPathExists s1
 '///
 With New clsFakeCommonDialog
  If .VBGetSaveFileName(s, , , , objText.GetText("XML level file") + "|*.xml", , s1, , "xml") Then
   b = True
  End If
 End With
 '///
 If b Then
  On Error Resume Next
  Err.Clear
  Open s For Output As #1
  Close
  Open s For Binary As #1
  Put #1, 1, m_bRandomMapFile
  Close
  On Error GoTo 0
  If Err.Number Then
   With New clsFakeDXUIMsgBox
    .MsgBox objText.GetText("Error saving file."), vbExclamation, objText.GetText("Error")
   End With
  End If
 End If
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
If m_nLevelType = 1 Then
 With FakeDXUIControls(m_idxForm2)
  .MoveToCenter
  .Show 1
 End With
ElseIf m_nLevelType = 2 Then
 NewRandomSeed
 With FakeDXUIControls(m_idxFormRnd)
  .MoveToCenter
  .Show 1
 End With
End If
End Sub

Private Sub Class_Terminate()
SaveLevelList FakeDXAppMyGamesPath + "level_list.xml"
End Sub

Friend Sub MoveToNextVisiblePolyhedron()
If objGameMgr.CanPlayerMovePolyhedron Then
 objGameMgr.CurrentPolyhedron = objGameMgr.GetNextVisiblePolyhedron
 objGameMgr.FollowCurrentPolyhedron = True
 objCamera.RealLinearDamping = 1
End If
End Sub

Private Function IFakeDXAppEvent_OnEvent(ByVal nType As Long, ByVal nParam1 As Long, ByVal nParam2 As Long, ByVal nParam3 As Long) As Long
Dim v1 As D3DVECTOR, v2 As D3DVECTOR, v3 As D3DVECTOR
Dim f As Single
Dim i As Long
Dim Button As Long
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
  If m_nRecordPos = 0 Then MoveToNextVisiblePolyhedron
  Exit Function
 Case vbKeyR
  RestartCurrentLevel
  Exit Function
 Case vbKeyQ
  BackToMainMenu
  Exit Function
 Case vbKeyU
  If m_nRecordPos = 0 Then UndoLastMove
  Exit Function
 Case vbKeyS
  If nParam2 = vbCtrlMask Then SaveCurrentLevel
  Exit Function
 Case vbKeyEscape
  PauseGame
  Exit Function
 Case vbKeyF12 'TEST ONLY
  InputMoves
  Exit Function
 End Select
 If i >= 0 And m_nRecordPos = 0 Then
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
m_sRecord = vbNullString
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
b = m_nLevelType <> 1
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
 m_sRecord = vbNullString
 m_nRecordPos = 0
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
Dim f As Single, i As Long
If Not m_objRandomMapProgress Is Nothing Then
 i = nCurrentGeneration - m_nLastProgress
 If i >= m_nNextProgress Then
  f = objTiming.GetMs
  If f < 1! Then f = 1!
  m_nNextProgress = i / f * 200!
  m_fAverageSpeed = m_fAverageSpeed * 0.875! + f / i * 0.125!
  f = (nGenerationCount - nCurrentGeneration) * m_fAverageSpeed / 8.64E+07!
  m_nLastProgress = nCurrentGeneration
  '///
  m_objRandomMapProgress.SetProgress nCurrentGeneration, nGenerationCount, Format(nCurrentGeneration / nGenerationCount, "0.0%") + _
  objText.GetText(", ETA: ") + Format(f, "hh:mm:ss")
  FakeDXAppMainLoop , True
  If m_objRandomMapProgress.Cancel Then IRandomMap_Callback = 1
 End If
End If
End Function

'TEST ONLY
Friend Function GenerateRandomLevelAndPlay() As Boolean
Dim objMap As Long
Dim objGA As Long
Dim nPoolSize As Long, nGenerations As Long
Dim sRandomSeed As String
Dim s As String, m As Long
Dim i As Long, j As Long
Dim b As Boolean, bCancel As Boolean
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
objMap = StdMapCreate
'///get settings
With FakeDXUIControls(m_idxFormRnd_1)
 For i = 1 To .ChildrenCount
  s = FakeDXUIControls(.Children(i)).Name
  Select Case s
  Case "ga__Type"
   With FakeDXUIControls(.Children(i)).ListViewObject
    j = .SelectedRow
    If j > 0 And j <= .RowCount Then
     StdMapAdd objMap, "Type", .List(j, 1)
    End If
   End With
  Case "txtPoolSize"
   nPoolSize = Val(FakeDXUIControls(.Children(i)).Text)
  Case "txtGenerations"
   nGenerations = Val(FakeDXUIControls(.Children(i)).Text)
  Case "txtSeed"
   sRandomSeed = FakeDXUIControls(.Children(i)).Text
  Case Else
   Select Case Left(s, 4)
   Case "ga__", "opt_"
    StdMapAdd objMap, Mid(s, 5), FakeDXUIControls(.Children(i)).Text
   End Select
  End Select
 Next i
End With
'///
MTInitFromString sRandomSeed
'///
objGA = GACreate
If GACreatePool(objGA, objMap, nPoolSize) Then
 '///
 Set m_objRandomMapProgress = New clsProgressDialog
 m_nLastProgress = 0
 m_nNextProgress = 32
 m_fAverageSpeed = 0!
 m_objRandomMapProgress.CreateAndShow objText.GetText("Generating...")
 '///
 If GARun(objGA, nGenerations, objMap, lpCallback, lpUserData) Then
  s = Space(65536)
  m = GABaseOutputToString(GAGetPoolItem(objGA, 0), ByVal StrPtr(s), 131072, 1)
  b = True
 End If
 '///
 bCancel = m_objRandomMapProgress.Cancel
 m_objRandomMapProgress.HideAndDestroy
 Set m_objRandomMapProgress = Nothing
 '///
End If
GADestroy objGA
'///
StdMapDestroy objMap
'///
If Not bCancel Then
 If b Then
  '///save file
  m_bRandomMapFile = LeftB(s, m)
  '///
  With New clsXMLSerializer
   b = .ReadNode(StrPtr(s), m, obj)
  End With
  If b Then
   m_nLevelType = 2
   m_sLevelName = objText.GetText("Random level")
   b = LoadNodeAndPlay(obj)
  End If
  GenerateRandomLevelAndPlay = b
 End If
 If Not b Then
  With New clsFakeDXUIMsgBox
   .MsgBox objText.GetText("Error generating random level."), vbExclamation, objText.GetText("Error")
  End With
 End If
End If
End Function

Friend Sub ShowRandomLevelSelection()
Create
NewRandomSeed
'///
With FakeDXUIControls(m_idxFormRnd)
 .MoveToCenter
 .Show 1
End With
End Sub

Friend Sub NewRandomSeed()
Dim i As Long, s As String
If m_idxSeed Then
 MTInitFromString Format(Timer, "00000.000")
 For i = 1 To 4
  s = s + Right("00000000" + Hex(MTGenRandInt32), 8)
 Next i
 FakeDXUIControls(m_idxSeed).Text = s
End If
End Sub

Private Function IFakeDXUIEvent_OnEvent(ByVal obj As clsFakeDXUI, ByVal nType As Long, ByVal nParam1 As Long, ByVal nParam2 As Long, ByVal nParam3 As Long) As Long
Dim s As String, s2 As String
Dim bDblClickLevelFile As Boolean
Dim bDblClickLevel As Boolean
Dim i As Long, y As Long, m As Long
Dim t() As typeString
'///
Select Case nType
Case FakeCtl_Event_Click
 Select Case obj.Name
 Case "cmdMenu"
  PauseGame
 Case "cmdOK"
  bDblClickLevelFile = True
 Case "cmdCancel"
  FakeDXUIControls(m_idxForm).Hide
  BackToMainMenu
 Case "cmdOK2"
  bDblClickLevel = True
 Case "cmdCancel2"
  FakeDXUIControls(m_idxForm2).Hide
 Case "cmdOK3"
  GenerateRandomLevelAndPlay
 Case "cmdCancel3"
  FakeDXUIControls(m_idxFormRnd).Hide
 Case "cmdOK4"
  With FakeDXUIControls(m_idxSolverType).ListViewObject
   i = .SelectedRow
   If i > 0 And i <= .RowCount Then
    s = .List(i, 1)
   End If
  End With
  '///solve
  y = objGameMgr.GetSolver(s)
  If y Then
   s = Space(65536)
   m = 131072
   i = SolverSolve(y, ByVal StrPtr(s), m, ByVal 0, ByVal 0)
   s = StrConv(LeftB(s, m), vbUnicode)
   SolverDestroy y
   If i Then
    InputMoves s
   Else
    With New clsFakeDXUIMsgBox
     .MsgBox objText.GetText("No solution."), vbInformation, objText.GetText("Solve level")
    End With
   End If
  Else
   With New clsFakeDXUIMsgBox
    .MsgBox objText.GetText("Error creating level solver."), vbExclamation, objText.GetText("Error")
   End With
  End If
  '///
 Case "cmdCancel4"
  FakeDXUIControls(m_idxFormSolver).Hide
 Case "cmdViewSolution"
  InputMoves
 Case "cmdRefresh"
  RefreshLevelList
 Case "cmdOpen"
  With New clsFakeCommonDialog
   If .VBGetOpenFileName(s, , , , , objText.GetText("XML level file") + "|*.xml;*.xml.lzma", , App.Path + "\data\") Then
    LoadFileAndPlay s
   End If
  End With
 Case "cmdRandom"
  ShowRandomLevelSelection
 Case "ga__Type"
  '///remove old controls
  With FakeDXUIControls(m_idxFormRnd_1)
   For i = .ChildrenCount To 1 Step -1
    Select Case Left(FakeDXUIControls(.Children(i)).Name, 4)
    Case "lbl_", "opt_"
     .RemoveChildren i, False, True
    End Select
   Next i
  End With
  '///
  i = obj.ListViewObject.SelectedRow
  If i > 0 And i <= obj.ListViewObject.RowCount Then
   s = obj.ListViewObject.List(i, 1)
   '///random map options
   ReDim t(255)
   m = GetAvaliableRandomMapOptions(s, t(0), 128, 128)
   '///
   y = m_nRndOptionsTop + 8
   With FakeDXUIControls(m_idxFormRnd_1)
    For i = 0 To m - 1
     s = StrConv(t(i + i).s, vbUnicode)
     s = Left(s, InStr(1, s, vbNullChar) - 1)
     .AddNewChildren FakeCtl_Label, 8, y, 160, y + 24, , , , , s, , "lbl_"
     s2 = StrConv(t(i + i + 1).s, vbUnicode)
     s2 = Left(s2, InStr(1, s2, vbNullChar) - 1)
     .AddNewChildren FakeCtl_TextBox, 168, y, -8, y + 24, FCS_CanGetFocus Or FCS_TabStop Or FTS_AutoSelect, , , , , s2, "opt_" + s, , , 1
     y = y + 32
    Next i
    .SetBottomEx .TopEx.a + y + 8, 0
   End With
   '///over
  End If
 Case "cmdSeed"
  NewRandomSeed
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
 m_fRecordTimer = m_fRecordTimer - objTiming.GetDelta
 If m_fRecordTimer < 0 Then
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
   Case "S"
    i = 4
   Case Else
    'TODO:
    bErr = True
   End Select
   Select Case i
   Case 0 To 3
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
     m_fRecordTimer = m_fMovingTimer
    End If
   Case 4
    MoveToNextVisiblePolyhedron
    m_nRecordPos = m_nRecordPos + 1
    m_fRecordTimer = m_fSwitchTimer
   Case Else
    'TODO:
    m_nRecordPos = m_nRecordPos + 1
   End Select
  Else
   bErr = True
  End If
  '///
  If bErr Then
   m_sRecord = vbNullString
   m_nRecordPos = 0
  End If
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
If m_idxFormRnd Then FakeDXUIControls(m_idxFormRnd).Hide
If m_idxForm2 Then FakeDXUIControls(m_idxForm2).Hide
If m_idxForm Then FakeDXUIControls(m_idxForm).Hide
End Sub

Friend Sub Hide()
HideLevelFileSelection
If m_idxMenu Then FakeDXUIControls(m_idxMenu).Hide
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
 '///TEST ONLY
 objRenderTest.DrawSkydome objSkyTexture
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
 FakeDXGDIDrawText FakeDXUIDefaultFont, m_sCurrentLevelName, 16, 16, d3dpp.BackBufferWidth - 16, 32, 0.75, DT_SINGLELINE Or DT_NOCLIP, , , &HFF000000, , , , , True
 m = objGameMgr.CheckPointCount
 FakeDXGDIDrawText FakeDXUIDefaultFont, _
 objText.GetText("Moves: ") + CStr(m_nMoves) + vbCrLf + _
 objText.GetText("Checkpoints: ") + CStr(m - objGameMgr.CheckPointRemaining) + "/" + CStr(m), _
 16, 48, 128, 32, 0.5, DT_NOCLIP, , , &HFF000000, , , , , True
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

'TEST ONLY
Friend Sub InputMoves(Optional ByVal s As String)
With New clsFakeDXUIInputBox
 If s = vbNullString Then s = objGameMgr.LevelSolution
 s = Trim(.InputBox("Input moves:", , s, , True, vbVertical))
End With
If s <> vbNullString Then
 HideSolver
 m_sRecord = Replace(Replace(Replace(Replace(s, vbTab, ""), " ", ""), vbCr, ""), vbLf, "")
 m_nRecordPos = 1
 m_fRecordTimer = 0
End If
End Sub

