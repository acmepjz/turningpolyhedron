VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsFakeCommonDialog"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Declare Function GetLogicalDrives Lib "kernel32.dll" () As Long
Private Declare Function GetDriveType Lib "kernel32.dll" Alias "GetDriveTypeA" (ByVal nDrive As String) As Long
Private Declare Function GetVolumeInformation Lib "kernel32.dll" Alias "GetVolumeInformationA" (ByVal lpRootPathName As String, ByVal lpVolumeNameBuffer As String, ByVal nVolumeNameSize As Long, ByRef lpVolumeSerialNumber As Long, ByRef lpMaximumComponentLength As Long, ByRef lpFileSystemFlags As Long, ByVal lpFileSystemNameBuffer As String, ByVal nFileSystemNameSize As Long) As Long

Private Declare Function PathCombine Lib "shlwapi.dll" Alias "PathCombineA" (ByVal szDest As String, ByVal lpszDir As String, ByVal lpszFile As String) As Long

Private Declare Function SHGetSpecialFolderPath Lib "shell32.dll" Alias "SHGetSpecialFolderPathA" (ByVal hwnd As Long, ByVal pszPath As String, ByVal csidl As Long, ByVal fCreate As Long) As Long
Private Declare Function MakeSureDirectoryPathExists Lib "imagehlp.dll" (ByVal DirPath As String) As Long

Private Const CSIDL_PERSONAL As Long = &H5
Private Const CSIDL_DESKTOP As Long = &H0
Private Const CSIDL_DESKTOPDIRECTORY As Long = &H10

Private m_nType As Long
'0-unused
'1-open
'2-save
'3-choose folder

Private m_bCancel As Boolean
Private m_bUnload As Boolean

Private m_sValue As String
Private m_nFilterIndex As Long

'control index
Private m_idx(127) As Long

Private Enum enumCommonDialogControls
 IDC_Main = 0
 IDC_FileName
 IDC_Filter
 IDC_ListView
 IDC_Container
End Enum

Private Type typeFileFilter
 sName As String
 nCount As Long
 sValue() As Long
End Type

Private m_tFilter() As typeFileFilter
Private m_nFilterCount As Long

Implements IFakeDXUIEvent

Friend Sub pCreateFolderButtons(ByVal InitDir As String)
On Error Resume Next
Dim v As Variant
Dim i As Long, m As Long
Dim x As Single, w As Single
Dim s As String
v = Split(InitDir, "\")
With FakeDXUIControls(m_idx(IDC_Container))
 For i = 0 To UBound(v)
  s = Trim(v(i))
  If s = "" Or s = "." Or s = ".." Then
   'error
  Else
   'TODO:add combobox
   If Len(s) = 2 And Mid(s, 2, 1) = ":" Then
    'driver
   Else
    'folder
   End If
   '///
   FakeDXGDIDrawText FakeDXUIDefaultFont, s, 0, 0, 128, 24, 0.5, DT_SINGLELINE Or DT_CALCRECT, 0, , , , , , , , w
   w = w + 8
   .AddNewChildren FakeCtl_Button, x, 0, x + w, 24, FCS_TabStop Or FCS_CanGetFocus Or FBS_Graphical Or FBS_OptionButton, , , , s
   x = x + w
   '///
  End If
 Next i
 '///over
 .SetRightEx x + 4, 0
 '///
End With
End Sub

Friend Function VBGetOpenFileName(ByRef FileName As String, _
                           Optional ByRef FileTitle As String, _
                           Optional ByVal FileMustExist As Boolean = True, _
                           Optional ByVal MultiSelect As Boolean = False, _
                           Optional ByVal Filter As String, _
                           Optional ByRef FilterIndex As Long = 1, _
                           Optional ByVal InitDir As String, _
                           Optional ByVal DlgTitle As String, _
                           Optional ByVal DefaultExt As String) As Boolean
'////////////////////////////////////////////////////////////////
On Error Resume Next
Dim i As Long, j As Long, m As Long
Dim s As String, s1 As String
Dim v As Variant, v2 As Variant
'///
If m_idx(0) <> 0 Or m_nType <> 0 Then Exit Function
m_bUnload = False
m_bCancel = True
m_sValue = vbNullString
m_nFilterIndex = 0
Erase m_tFilter
m_nFilterCount = 0
'///init filter
v = Split(Filter, "|")
m_nFilterCount = (UBound(v) + 1) \ 2
If m_nFilterCount > 0 Then
 ReDim m_tFilter(1 To m_nFilterCount)
 For i = 1 To m_nFilterCount
  m_tFilter(i).sName = Trim(v(i + i - 2))
  v2 = Split(Trim(v(i + i - 1)), ";")
  m = UBound(v2) + 1
  If m > 0 Then
   m_tFilter(i).nCount = m
   ReDim m_tFilter(i).sValue(1 To m)
   For j = 1 To m
    s = Trim(v2(j - 1))
    If s = "*.*" Then s = "*"
    m_tFilter(i).sValue(j) = s
   Next j
  End If
 Next i
End If
If FilterIndex > 0 And FilterIndex <= m_nFilterCount Then m_nFilterIndex = FilterIndex
'///init title
If DlgTitle = "" Then DlgTitle = objText.GetText("Open")
'///init filename
FileName = Trim(Replace(FileName, "/", "\"))
j = Len(FileName)
If j > 0 Then
 Do
  i = j
  FileName = Replace(FileName, "\\", "\")
  j = Len(FileName)
 Loop Until i = j
End If
'///init directory
InitDir = Trim(Replace(InitDir, "/", "\"))
j = Len(InitDir)
If j > 0 Then
 Do
  i = j
  InitDir = Replace(InitDir, "\\", "\")
  j = Len(InitDir)
 Loop Until i = j
 If Right(InitDir, 1) <> "\" Then InitDir = InitDir + "\"
End If
'///
s1 = CurDir
s = Space(Len(InitDir) + Len(s1) + 1024)
PathCombine s, s1, InitDir
i = InStr(1, s, vbNullChar)
If i > 0 Then s = Left(s, i - 1)
'///
s = Replace(s, "/", "\")
j = Len(s)
Do
 i = j
 s = Replace(s, "\\", "\")
 j = Len(s)
Loop Until i = j
If Right(s, 1) <> "\" Then s = s + "\"
InitDir = s
'///
With FakeDXUIControls(1).AddNewChildren(FakeCtl_Form, -300, -200, 300, 200, _
FFS_CloseButton Or FFS_MaxButton Or FFS_Moveable Or FFS_Sizable Or FFS_TitleBar, , False, , DlgTitle, , , 0.5, 0.5, 0.5, 0.5)
 m_idx(0) = .Index
 Set .EventObject = Me
 '///
 'TODO:
 With .AddNewChildren(FakeCtl_TextBox, 88, -64, -72, -40, FCS_TabStop Or FCS_CanGetFocus Or FTS_AutoSelect, , , , , FileName, "txtFileName", , 1, 1, 1)
  m_idx(IDC_FileName) = .Index
 End With
 With .AddNewChildren(FakeCtl_ComboBox, 88, -32, -72, -8, FCS_TabStop Or FCS_CanGetFocus, , , , , , "cmbFilter", , 1, 1, 1)
  m_idx(IDC_Filter) = .Index
  With .ListViewObject
   .FullRowSelect = True
   .AddColumn ""
   If m_nFilterCount > 0 Then
    For i = 1 To m_nFilterCount
     .AddItem m_tFilter(i).sName
    Next i
    If m_nFilterIndex > 0 Then .SelectedRow = m_nFilterIndex
   End If
  End With
 End With
 .AddNewChildren FakeCtl_Label, 8, -64, 80, -40, , , , , objText.GetText("File name"), , , , 1, , 1
 .AddNewChildren FakeCtl_Label, 8, -32, 80, -8, , , , , objText.GetText("File type"), , , , 1, , 1
 .AddNewChildren FakeCtl_Button, -64, -64, -8, -40, FCS_TabStop Or FCS_CanGetFocus Or FBS_Default, , , , objText.GetText("Open"), , "cmdOK", 1, 1, 1, 1
 .AddNewChildren FakeCtl_Button, -64, -32, -8, -8, FCS_TabStop Or FCS_CanGetFocus Or FBS_Cancel, , , , objText.GetText("Cancel"), , "cmdCancel", 1, 1, 1, 1
 With .AddNewChildren(FakeCtl_ListView, 8, 56, -8, -72, FCS_TabStop Or FCS_CanGetFocus, , , , , , "lstFile", , , 1, 1)
  m_idx(IDC_ListView) = .Index
  With .ListViewObject
   .FullRowSelect = True
   .ColumnHeader = True
   .MultiSelect = MultiSelect
   .AddColumn objText.GetText("File name"), , , efcfSizable Or efcfSortable, 256
   .AddColumn objText.GetText("File size"), , , efcfSizable Or efcfSortable Or efcfSortWithItemData, 128
   .AddColumn objText.GetText("Extension"), , , efcfSizable Or efcfSortable, 128
   .AddColumn objText.GetText("Modification time"), , , efcfSizable Or efcfSortable, 128
  End With
 End With
 With .AddNewChildren(FakeCtl_None, 8, 8, -96, 52, FCS_TabStop Or FCS_CanGetFocus Or FCS_AutoScroll, , , , , , , , , 1)
  With .AddNewChildren(FakeCtl_None, 0, 0, 128, 26)
   m_idx(IDC_Container) = .Index
  End With
 End With
 pCreateFolderButtons InitDir
 .AddNewChildren FakeCtl_Button, -88, 8, -8, 32, FCS_TabStop Or FCS_CanGetFocus, , , , objText.GetText("New folder"), , "cmdNewFolder", 1, , 1
 '///
 .Show 1
End With
FakeDXUIDiscardAllMessages
'///wait for single object
FakeDXAppMainLoop VarPtr(m_bUnload)
'///
i = m_idx(0)
If i > 0 And i <= FakeDXUIControlCount Then
 FakeDXUIControls(i).Unload
End If
'///over TODO:
Erase m_idx
'////////////////////////////////////////////////////////////////
End Function

Friend Function VBGetSaveFileName(ByRef FileName As String, _
                           Optional ByRef FileTitle As String, _
                           Optional ByVal PathMustExist As Boolean = True, _
                           Optional ByVal OverWritePrompt As Boolean = True, _
                           Optional ByVal Filter As String = "All (*.*)| *.*", _
                           Optional ByRef FilterIndex As Long = 1, _
                           Optional ByVal InitDir As String, _
                           Optional ByVal DlgTitle As String, _
                           Optional ByVal DefaultExt As String) As Boolean
'////////////////////////////////////////////////////////////////
If m_idx(0) <> 0 Or m_nType <> 0 Then Exit Function
'////////////////////////////////////////////////////////////////
End Function

Friend Function VBChooseFolder(ByRef FileName As String, _
                           Optional ByVal PathMustExist As Boolean = True, _
                           Optional ByVal MultiSelect As Boolean = False, _
                           Optional ByVal InitDir As String, _
                           Optional ByVal DlgTitle As String) As Boolean
'////////////////////////////////////////////////////////////////
If m_idx(0) <> 0 Or m_nType <> 0 Then Exit Function
'////////////////////////////////////////////////////////////////
End Function

Private Sub IFakeDXUIEvent_Change(ByVal obj As clsFakeDXUI)
'
End Sub

Private Sub IFakeDXUIEvent_Click(ByVal obj As clsFakeDXUI)
Dim i As Long
'///
Select Case obj.Name
Case "cmdOK"
 m_bUnload = True
 m_bCancel = False
 i = m_idx(IDC_FileName)
 If i > 0 And i <= FakeDXUIControlCount Then
  m_sValue = FakeDXUIControls(i).Text
 End If
 i = m_idx(IDC_Filter)
 If i > 0 And i <= FakeDXUIControlCount Then
  m_nFilterIndex = FakeDXUIControls(i).ListViewObject.SelectedRow
 End If
 'TODO:validate
Case "cmdCancel"
 m_bUnload = True
Case Else
 'TODO:
End Select
End Sub

Private Sub IFakeDXUIEvent_Unload(ByVal obj As clsFakeDXUI, Cancel As Boolean)
m_bUnload = True
End Sub

