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

'////////unused :-3

Private Declare Function FindFirstFile Lib "kernel32.dll" Alias "FindFirstFileA" (ByVal lpFileName As String, ByRef lpFindFileData As WIN32_FIND_DATA) As Long
Private Declare Function FindFirstFileEx Lib "kernel32.dll" Alias "FindFirstFileExA" (ByVal lpFileName As String, ByVal fInfoLevelId As Long, ByRef lpFindFileData As WIN32_FIND_DATA, ByVal fSearchOp As Long, ByRef lpSearchFilter As Any, ByVal dwAdditionalFlags As Long) As Long
Private Declare Function FindNextFile Lib "kernel32.dll" Alias "FindNextFileA" (ByVal hFindFile As Long, ByRef lpFindFileData As WIN32_FIND_DATA) As Long
Private Declare Function FindClose Lib "kernel32.dll" (ByVal hFindFile As Long) As Long
Private Type WIN32_FIND_DATA
    dwFileAttributes As Long
    ftCreationTime As Currency
    ftLastAccessTime As Currency
    ftLastWriteTime As Currency
    nFileSizeHigh As Long
    nFileSizeLow As Long
    dwReserved0 As Long
    dwReserved1 As Long
    cFileName(259) As Byte
    cAlternate(13) As Byte
End Type

Private Const ERROR_NO_MORE_FILES As Long = 18&
Private Const ERROR_FILE_NOT_FOUND As Long = 2&
Private Const ERROR_PATH_NOT_FOUND As Long = 3&

Private Declare Function FormatMessage Lib "kernel32.dll" Alias "FormatMessageA" (ByVal dwFlags As Long, ByRef lpSource As Any, ByVal dwMessageId As Long, ByVal dwLanguageId As Long, ByVal lpBuffer As String, ByVal nSize As Long, ByRef Arguments As Long) As Long
Private Const FORMAT_MESSAGE_FROM_SYSTEM As Long = &H1000

Private Declare Function FileTimeToLocalFileTime Lib "kernel32.dll" (ByRef lpFileTime As Currency, ByRef lpLocalFileTime As Currency) As Long
Private Declare Function FileTimeToSystemTime Lib "kernel32.dll" (ByRef lpFileTime As Currency, ByRef lpSystemTime As Any) As Long
Private Declare Function SystemTimeToVariantTime Lib "oleaut32.dll" (ByRef lpSystemTime As Any, ByRef pvtime As Double) As Long

Private Const FindExSearchNameMatch As Long = 0
Private Const FindExSearchLimitToDirectories As Long = 1
Private Const FindExSearchLimitToDevices As Long = 2

'////////

Private m_nType As Long
'0-unused
'1-open
'2-save
'3-choose folder

Private m_bCancel As Boolean
Private m_bUnload As Boolean
Private m_bDiscardEvent As Boolean

Private m_sTitle As String
Private m_sValue As String
Private m_nFilterIndex As Long

Private m_bPathMustExist As Boolean
Private m_bFileMustExist As Boolean '=OverWritePrompt
Private m_bMultiSelect As Boolean
Private m_sDefaultExt As String

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
 sDefaultExt As String
 nCount As Long
 sValue() As String
End Type

Private m_tFilter() As typeFileFilter
Private m_nFilterCount As Long

Private Type typeFileData
 sName As String
 sExtension As String
 nTime As Double
 nSize As Double '<0:directory
End Type

Private Type typeFileCollection
 sPath As String 'must end with "\"
 nCount As Long
 nMax As Long
 tData() As typeFileData
End Type

Private m_tFolders() As typeFileCollection
Private m_nFolderCount As Long
Private m_nFolderMax As Long

Private m_nSelectedFolder As Long

Implements IFakeDXUIEvent

Friend Function pGetLastDllErrorMessage() As String
Dim s As String
Dim i As Long
s = Space(1024)
FormatMessage FORMAT_MESSAGE_FROM_SYSTEM, ByVal 0, Err.LastDllError, 0, s, 1024, 0
i = InStr(1, s, vbNullChar)
If i > 0 Then s = Left(s, i - 1)
pGetLastDllErrorMessage = s
End Function

'sPath must end with "\"
Friend Function pEnumerateFiles(ByVal sPath As String, ByRef ret As typeFileCollection, Optional ByVal fSearchOp As Long) As Long
On Error Resume Next
Dim h As Long
Dim t As WIN32_FIND_DATA
Dim s As String, i As Long
Dim f As Double
Dim tmp(7) As Currency
'///
With ret
 .sPath = sPath
 .nCount = 0
 .nMax = 0
 Erase .tData
End With
'///
h = FindFirstFileEx(sPath + "*", 0, t, fSearchOp, ByVal 0, 0)
'///
If h = 0 Or h = -1 Then
 If Err.LastDllError <> ERROR_NO_MORE_FILES Then pEnumerateFiles = -1
 Exit Function
End If
'///
Do
 s = StrConv(t.cFileName, vbUnicode)
 i = InStr(1, s, vbNullChar)
 If i > 0 Then s = Left(s, i - 1)
 If s <> "." And s <> ".." Then
  ret.nCount = ret.nCount + 1
  If ret.nCount > ret.nMax Then
   ret.nMax = ret.nMax + 256&
   ReDim Preserve ret.tData(1 To ret.nMax)
  End If
  With ret.tData(ret.nCount)
   .sName = s
   i = InStrRev(s, ".")
   If i > 0 Then .sExtension = LCase(Mid(s, i + 1))
   If t.dwFileAttributes And vbDirectory Then
    .nSize = -1
   Else
    f = t.nFileSizeHigh
    If f < 0 Then f = f + 4294967296#
    .nSize = f * 4294967296#
    f = t.nFileSizeLow
    If f < 0 Then f = f + 4294967296#
    .nSize = .nSize + f
   End If
   'get time
   FileTimeToLocalFileTime t.ftLastWriteTime, tmp(0)
   FileTimeToSystemTime tmp(0), tmp(1)
   SystemTimeToVariantTime tmp(1), f
   .nTime = f
  End With
 End If
Loop While FindNextFile(h, t)
'///
FindClose h
pEnumerateFiles = ret.nCount
End Function

Friend Function pCreateFolderButtons(ByVal sPath As String) As Boolean
On Error Resume Next
'///
Dim v As Variant
Dim i As Long, ii As Long
Dim j As Long, jj As Long
Dim k As Long, kk As Long
Dim m As Long
Dim x As Single, w As Single
Dim s As String, s1 As String
Dim bChanged As Boolean
'///
Dim objComboBox As clsFakeDXUI
Dim objButton As clsFakeDXUI
'///
jj = AscW(Left(sPath, 1)) And 31&
v = Split(sPath, "\")
sPath = ""
pCreateFolderButtons = True
'///
With FakeDXUIControls(m_idx(IDC_Container))
 m = .ChildrenCount \ 2
 For i = 0 To UBound(v)
  s = Trim(v(i))
  If s = "" Or s = "." Or s = ".." Then
   Exit For 'end of file or error
  Else
   '///
   sPath = sPath + s + "\"
   bChanged = True
   If ii >= 0 And ii < m_nFolderCount Then
    bChanged = LCase(sPath) <> LCase(m_tFolders(ii + 1).sPath)
   End If
   '///combobox
   If ii < m Then Set objComboBox = FakeDXUIControls(.Children(ii + ii + 1)) _
   Else Set objComboBox = .AddNewChildren(FakeCtl_ComboBox, x, 0, x + 128, 24, FCS_CanGetFocus Or FCBS_FixedText, , , , , , "cmbFolder")
   If bChanged Or ii >= m Then
    With objComboBox
     With .ListViewObject
      .FullRowSelect = True
      .ClearAll
      .AddColumn ""
      If i = 0 Then
       'drive
       .AddItem objText.GetText("Desktop"), , -1
       .AddItem objText.GetText("My Documents"), , -2
       kk = GetLogicalDrives
       k = 1
       For j = 1 To 26
        If kk And k Then
         '///get volume label
         s1 = Space(1024)
         GetVolumeInformation ChrW(64 + j) + ":\", s1, 1024, 0, 0, 0, vbNullString, 0
         i = InStr(1, s1, vbNullChar)
         If i > 1 Then s1 = Left(s1, i - 1) + " " Else s1 = ""
         .AddItem s1 + "(" + ChrW(64 + j) + ":)", , j
        End If
        k = k + k
       Next j
       i = 0
      Else
       'folder
       For j = 1 To m_tFolders(ii).nCount
        If m_tFolders(ii).tData(j).nSize < 0 Then
         s1 = m_tFolders(ii).tData(j).sName
         .AddItem s1, , j
         If LCase(s) = LCase(s1) Then .SelectedRow = .RowCount
        End If
       Next j
      End If
     End With
    End With
   End If
   '///enumerate files
   If bChanged Then
    m_nFolderCount = ii + 1
    If m_nFolderCount > m_nFolderMax Then
     m_nFolderMax = m_nFolderCount + 16&
     ReDim Preserve m_tFolders(1 To m_nFolderMax)
    End If
    j = pEnumerateFiles(sPath, m_tFolders(m_nFolderCount), m_nType = 3 And FindExSearchLimitToDirectories)
   End If
   '///add button
   FakeDXGDIDrawText FakeDXUIDefaultFont, s, 0, 0, 128, 24, 0.5, DT_SINGLELINE Or DT_CALCRECT, 0, , , , , , , , w
   w = w + 8
   If ii < m Then Set objButton = FakeDXUIControls(.Children(ii + ii + 2)) _
   Else Set objButton = .AddNewChildren(FakeCtl_Button, x, 0, x + w, 24, _
   FCS_TabStop Or FCS_CanGetFocus Or FBS_Graphical Or FBS_OptionButton, , , , s, , "optFolder")
   With objButton
    .Visible = True
    .Caption = s
    .SetLeftEx x, 0
    .SetRightEx x + w, 0
   End With
   w = w + 16
   With objComboBox
    .Visible = True
    .SetLeftEx x, 0
    .SetRightEx x + w, 0
    .ComboBoxDropdownWidth = (w < 256) And 256&
   End With
   x = x + w
   ii = ii + 1
   '///
   If j < 0 Then
    pCreateFolderButtons = False
    With New clsFakeDXUIMsgBox
     .MsgBox sPath + vbCrLf + pGetLastDllErrorMessage, vbExclamation, objText.GetText("Error")
    End With
    Exit For
   End If
  End If
 Next i
 m_nFolderCount = ii
 '///
 ii = ii + ii
 For i = ii + 1 To .ChildrenCount
  FakeDXUIControls(.Children(i)).Visible = False
 Next i
 '///over
 .SetRightEx .LeftEx.a + x + 4, 0
 i = .ChildrenCount
 If ii > 0 And ii <= i Then FakeDXUIControls(.Children(ii)).Value = 1
 If i >= 1 Then
  With FakeDXUIControls(.Children(1)).ListViewObject
   For k = 1 To .RowCount
    If .ItemData(k, 1) = jj Then
     .SelectedRow = k
     Exit For
    End If
   Next k
  End With
 End If
 m_nSelectedFolder = m_nFolderCount
End With
'///
pShowFile
End Function

Friend Sub pShowFile(Optional ByVal nIndex As Long = -1)
On Error Resume Next
Dim obj As clsFakeDXUIListView
Dim i As Long, j As Long
Dim b As Boolean
Dim s As String
If nIndex < 0 Then nIndex = m_nSelectedFolder
If nIndex > 0 And nIndex <= m_nFolderCount Then
 Set obj = FakeDXUIControls(m_idx(IDC_ListView)).ListViewObject
 obj.Clear
 With m_tFolders(nIndex)
  For i = 1 To .nCount
   With .tData(i)
    If .nSize < 0 Then
     'directory
     obj.AddItem vbTab + .sName, , i, Array(Array("", -1), vbTab + objText.GetText("Folder"), vbTab + Format(.nTime, "yyyy-mm-dd hh:mm:ss"))
    ElseIf m_nType <> 3 Then
     'file
     If m_nFilterIndex <= 0 Or m_nFilterIndex > m_nFilterCount Then
      b = True
     Else
      b = False
      For j = 1 To m_tFilter(m_nFilterIndex).nCount
       If .sName Like m_tFilter(m_nFilterIndex).sValue(j) Then
        b = True
        Exit For
       End If
      Next j
     End If
     If b Then
      If .nSize > 2147483647# Then j = &H7FFFFFFF _
      Else j = .nSize
      If j < 1000 Then
       s = CStr(j) + " " + objText.GetText("Bytes")
      Else
       s = Format(.nSize / 1024#, "#,0") + " KB"
      End If
      obj.AddItem .sName, , i, Array(Array(s, j), vbLf + .sExtension, Format(.nTime, "yyyy-mm-dd hh:mm:ss"))
     End If
    End If
   End With
  Next i
 End With
 obj.Sort
End If
End Sub

Friend Sub pInitFilter(Optional ByVal Filter As String, Optional ByVal FilterIndex As Long = 1, Optional ByVal DefaultExt As String)
On Error Resume Next
Dim i As Long, j As Long, k As Long, m As Long
Dim s As String
Dim v As Variant, v2 As Variant
'///
Erase m_tFilter
m_nFilterCount = 0
m_nFilterIndex = 0
'///init default extension
m_sDefaultExt = vbNullString
If InStr(1, DefaultExt, "/") > 0 Then
ElseIf InStr(1, DefaultExt, "\") > 0 Then
ElseIf InStr(1, DefaultExt, ":") > 0 Then
ElseIf InStr(1, DefaultExt, "*") > 0 Then
ElseIf InStr(1, DefaultExt, "?") > 0 Then
ElseIf InStr(1, DefaultExt, """") > 0 Then
ElseIf InStr(1, DefaultExt, "<") > 0 Then
ElseIf InStr(1, DefaultExt, ">") > 0 Then
ElseIf InStr(1, DefaultExt, "|") > 0 Then
Else
 m_sDefaultExt = Trim(DefaultExt)
End If
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
   '///get default extension
   m_tFilter(i).sDefaultExt = m_sDefaultExt
   For j = 1 To m
    s = m_tFilter(i).sValue(j)
    k = InStrRev(s, ".")
    If k > 0 Then
     s = Trim(Mid(s, k + 1))
     If s = vbNullString Then
     ElseIf InStr(1, s, "/") > 0 Then
     ElseIf InStr(1, s, "\") > 0 Then
     ElseIf InStr(1, s, ":") > 0 Then
     ElseIf InStr(1, s, "*") > 0 Then
     ElseIf InStr(1, s, "?") > 0 Then
     ElseIf InStr(1, s, """") > 0 Then
     ElseIf InStr(1, s, "<") > 0 Then
     ElseIf InStr(1, s, ">") > 0 Then
     ElseIf InStr(1, s, "|") > 0 Then
     Else
      m_tFilter(i).sDefaultExt = s
      Exit For
     End If
    End If
   Next j
   '///
  End If
 Next i
 If FilterIndex > 0 And FilterIndex <= m_nFilterCount Then m_nFilterIndex = FilterIndex
End If
End Sub

Friend Function pShowFileDialog(Optional ByRef FileName As String, Optional ByRef FileTitle As String, Optional ByRef FilterIndex As Long = 1, Optional ByVal InitDir As String) As Boolean
On Error Resume Next
Dim i As Long, j As Long
Dim s As String, s1 As String
'///
m_bUnload = False
m_bCancel = True
m_sValue = vbNullString
Erase m_tFolders
m_nFolderCount = 0
m_nFolderMax = 0
m_nSelectedFolder = 0
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
FFS_CloseButton Or FFS_MaxButton Or FFS_Moveable Or FFS_Sizable Or FFS_TitleBar, , False, , m_sTitle, , , 0.5, 0.5, 0.5, 0.5)
 m_idx(0) = .Index
 Set .EventObject = Me
 '///
 If m_nType = 3 Then
  With .AddNewChildren(FakeCtl_TextBox, 104, -32, -136, -8, FCS_TabStop Or FCS_CanGetFocus Or FTS_AutoSelect, , , , , FileName, "txtFileName", , 1, 1, 1)
   m_idx(IDC_FileName) = .Index
  End With
  .AddNewChildren FakeCtl_Label, 8, -32, 96, -8, , , , , objText.GetText("Folder name"), , , , 1, , 1
  s = objText.GetText("OK")
  i = -128
  j = -32
 Else
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
  If m_nType = 2 Then s = objText.GetText("Save") _
  Else s = objText.GetText("Open")
  i = -64
  j = -64
 End If
 .AddNewChildren FakeCtl_Button, i, j, i + 56, j + 24, FCS_TabStop Or FCS_CanGetFocus Or FBS_Default, , , , s, , "cmdOK", 1, 1, 1, 1
 .AddNewChildren FakeCtl_Button, -64, -32, -8, -8, FCS_TabStop Or FCS_CanGetFocus Or FBS_Cancel, , , , objText.GetText("Cancel"), , "cmdCancel", 1, 1, 1, 1
 With .AddNewChildren(FakeCtl_ListView, 8, 56, -8, (32 And m_nType = 3) - 72, FCS_TabStop Or FCS_CanGetFocus, , , , , , "lstFile", , , 1, 1)
  m_idx(IDC_ListView) = .Index
  With .ListViewObject
   .FullRowSelect = True
   .ColumnHeader = True
   .MultiSelect = m_bMultiSelect
   .AddColumn objText.GetText("File name"), , efctStringCaseInsensitive, efcfSizable Or efcfSortable, 256
   .AddColumn objText.GetText("File size"), , , efcfSizable Or efcfSortable Or efcfSortWithItemData Or efcfAlignRight Or (efcfHidden And m_nType = 3), 128
   .AddColumn objText.GetText("Extension"), , , efcfSizable Or efcfSortable Or (efcfHidden And m_nType = 3), 128
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
'///
m_bDiscardEvent = True
FakeDXAppMainLoop VarPtr(1&)
m_bDiscardEvent = False
'///wait for single object
FakeDXAppMainLoop VarPtr(m_bUnload)
'///
i = m_idx(0)
If i > 0 And i <= FakeDXUIControlCount Then
 FakeDXUIControls(i).Unload
End If
'///return value
If m_bCancel Then
 FileName = vbNullString
 FileTitle = vbNullString
 FilterIndex = 0
Else
 FileName = m_sValue
 If Not m_bMultiSelect Then
  i = InStrRev(m_sValue, "\")
  If i > 0 Then FileTitle = Mid(m_sValue, i + 1) Else FileTitle = m_sValue
 End If
 FilterIndex = m_nFilterIndex
 pShowFileDialog = True
End If
'///over
Erase m_idx
m_nType = 0
End Function

Friend Function VBGetOpenFileName(ByRef FileName As String, _
                           Optional ByRef FileTitle As String, _
                           Optional ByVal PathMustExist As Boolean = True, _
                           Optional ByVal FileMustExist As Boolean = True, _
                           Optional ByVal MultiSelect As Boolean = False, _
                           Optional ByVal Filter As String, _
                           Optional ByRef FilterIndex As Long = 1, _
                           Optional ByVal InitDir As String, _
                           Optional ByVal DlgTitle As String, _
                           Optional ByVal DefaultExt As String) As Boolean
'////////////////////////////////////////////////////////////////
On Error Resume Next
'///
If m_idx(0) <> 0 Or m_nType <> 0 Then Exit Function
'///
m_nType = 1
m_bPathMustExist = PathMustExist
m_bFileMustExist = FileMustExist
m_bMultiSelect = MultiSelect
'///init filter
pInitFilter Filter, FilterIndex, DefaultExt
'///init title
If DlgTitle = "" Then m_sTitle = objText.GetText("Open") Else m_sTitle = DlgTitle
'///show
VBGetOpenFileName = pShowFileDialog(FileName, FileTitle, FilterIndex, InitDir)
'////////////////////////////////////////////////////////////////
End Function

Friend Function VBGetSaveFileName(ByRef FileName As String, _
                           Optional ByRef FileTitle As String, _
                           Optional ByVal PathMustExist As Boolean = True, _
                           Optional ByVal OverWritePrompt As Boolean = True, _
                           Optional ByVal Filter As String, _
                           Optional ByRef FilterIndex As Long = 1, _
                           Optional ByVal InitDir As String, _
                           Optional ByVal DlgTitle As String, _
                           Optional ByVal DefaultExt As String) As Boolean
'////////////////////////////////////////////////////////////////
On Error Resume Next
'///
If m_idx(0) <> 0 Or m_nType <> 0 Then Exit Function
'///
m_nType = 2
m_bPathMustExist = PathMustExist
m_bFileMustExist = OverWritePrompt
m_bMultiSelect = False
'///init filter
pInitFilter Filter, FilterIndex, DefaultExt
'///init title
If DlgTitle = "" Then m_sTitle = objText.GetText("Save as") Else m_sTitle = DlgTitle
'///show
VBGetSaveFileName = pShowFileDialog(FileName, FileTitle, FilterIndex, InitDir)
'////////////////////////////////////////////////////////////////
End Function

Friend Function VBChooseFolder(ByRef FileName As String, _
                           Optional ByVal PathMustExist As Boolean = True, _
                           Optional ByVal MultiSelect As Boolean = False, _
                           Optional ByVal InitDir As String, _
                           Optional ByVal DlgTitle As String) As Boolean
'////////////////////////////////////////////////////////////////
On Error Resume Next
'///
If m_idx(0) <> 0 Or m_nType <> 0 Then Exit Function
'///
m_nType = 3
m_bPathMustExist = PathMustExist
m_bFileMustExist = PathMustExist
m_bMultiSelect = MultiSelect
'///init title
If DlgTitle = "" Then m_sTitle = objText.GetText("Choose folder") Else m_sTitle = DlgTitle
'///show
VBChooseFolder = pShowFileDialog(FileName, , , InitDir)
'////////////////////////////////////////////////////////////////
End Function

Private Function pCheckFileExist(ByVal s As String) As Long
Dim h As Long, i As Long, j As Long
Dim t As WIN32_FIND_DATA
Dim s1 As String
'///
s = Replace(s, "/", "\")
j = Len(s)
Do
 i = j
 s = Replace(s, "\\", "\")
 j = Len(s)
Loop Until i = j
If Right(s, 1) = "\" Then s = Left(s, i - 1)
'///
If Len(s) = 2 And Mid(s, 2, 1) = ":" Then
 'fix a bug: can't recognize "C:\"
 h = FindFirstFile(s + "\*", t)
 If h = 0 Or h = -1 Then
  i = Err.LastDllError
  If i <> ERROR_NO_MORE_FILES Then Exit Function
 Else
  FindClose h
 End If
 pCheckFileExist = vbDirectory Or &H10000
Else
 h = FindFirstFile(s, t)
 If h = 0 Or h = -1 Then
 Else
  s1 = StrConv(t.cFileName, vbUnicode)
  i = InStr(1, s1, vbNullChar)
  If i > 0 Then s1 = Left(s1, i - 1)
  i = InStrRev(s, "\")
  If i > 0 Then s = Mid(s, i + 1)
  If LCase(Trim(s)) = LCase(Trim(s1)) Then _
  pCheckFileExist = t.dwFileAttributes Or &H10000
  FindClose h
 End If
End If
End Function

Private Function pValidateFile(ByVal s0 As String, ByVal s As String, Optional ByVal bHasExtension As Boolean) As String
Dim i As Long, j As Long
Dim s1 As String
Dim bError As Boolean
'///
s = Trim(Replace(s, "/", "\"))
j = Len(s)
If j = 0 Then
 If m_nType <> 3 Then Exit Function
 s = s0
 If Right(s, 1) = "\" Then s = Left(s, Len(s) - 1)
 s1 = s
Else
 Do
  i = j
  s = Replace(s, "\\", "\")
  j = Len(s)
 Loop Until i = j
 If Right(s, 1) = "\" Then s = Left(s, i - 1)
 '///
 s1 = Space(Len(s0) + i + 1024)
 PathCombine s1, s0, s
 i = InStr(1, s1, vbNullChar)
 If i > 0 Then s1 = Left(s1, i - 1)
End If
'///
If InStr(3, s1, ":") > 0 Then Exit Function
If InStr(1, s1, "*") > 0 Then Exit Function
If InStr(1, s1, "?") > 0 Then Exit Function
If InStr(1, s1, """") > 0 Then Exit Function
If InStr(1, s1, "<") > 0 Then Exit Function
If InStr(1, s1, ">") > 0 Then Exit Function
If InStr(1, s1, "|") > 0 Then Exit Function
'///get default extension
If m_nFilterIndex > 0 And m_nFilterIndex <= m_nFilterCount Then s0 = m_tFilter(m_nFilterIndex).sDefaultExt _
Else s0 = m_sDefaultExt
'///check validate and append default extension if necessary
i = InStrRev(s1, "\")
If i > 0 Then i = InStr(i, s1, ".")
If i > 0 Or s0 = vbNullString Or m_nType = 3 Or bHasExtension Then
 i = pCheckFileExist(s1)
ElseIf m_nType = 2 Then
 s1 = s1 + "." + s0
 i = pCheckFileExist(s1)
Else
 i = pCheckFileExist(s1)
 If i = 0 Then
  s1 = s1 + "." + s0
  i = pCheckFileExist(s1)
 End If
End If
'///
If i = 0 Then
 Select Case Err.LastDllError
 Case 0
 Case ERROR_NO_MORE_FILES, ERROR_FILE_NOT_FOUND
  bError = m_bFileMustExist And m_nType <> 2
 Case ERROR_PATH_NOT_FOUND
  bError = m_bPathMustExist Or (m_bFileMustExist And m_nType <> 2)
 Case Else
  bError = True
 End Select
 If bError Then
  With New clsFakeDXUIMsgBox
   .MsgBox s + vbCrLf + pGetLastDllErrorMessage, vbExclamation, objText.GetText("Error")
  End With
 Else
  pValidateFile = s1
 End If
ElseIf i And vbDirectory Then
 If m_nType = 3 Then
  If Right(s1, 1) <> "\" Then s1 = s1 + "\"
  pValidateFile = s1
 ElseIf Not m_bMultiSelect Then
  pCreateFolderButtons s1 + "\"
 End If
ElseIf m_nType = 2 Then
 With New clsFakeDXUIMsgBox
  If .MsgBox(s + vbCrLf + objText.GetText("The file already exists. Do you want to overwrite it?"), _
  vbExclamation Or vbYesNo Or vbDefaultButton2, m_sTitle) = vbYes Then _
  pValidateFile = s1
 End With
ElseIf m_nType <> 3 Then
 pValidateFile = s1
End If
End Function

Private Function IFakeDXUIEvent_OnEvent(ByVal obj As clsFakeDXUI, ByVal nType As Long, ByVal nParam1 As Long, ByVal nParam2 As Long, ByVal nParam3 As Long) As Long
On Error Resume Next
Dim i As Long, j As Long, k As Long
Dim s As String, s1 As String
Dim f As Double
'///
Select Case nType
Case FakeCtl_Event_Click
 '////////////////////////////////
 If m_bDiscardEvent Then Exit Function
 Select Case obj.Name
 Case "cmdOK"
  If m_nSelectedFolder > 0 And m_nSelectedFolder <= m_nFolderCount Then
   i = m_idx(IDC_FileName)
   If i > 0 And i <= FakeDXUIControlCount Then
    s = FakeDXUIControls(i).Text
   End If
   i = m_idx(IDC_Filter)
   If i > 0 And i <= FakeDXUIControlCount Then
    m_nFilterIndex = FakeDXUIControls(i).ListViewObject.SelectedRow
   End If
   '///validate
   i = 0
   If m_bMultiSelect Then i = InStr(1, s, """")
   If i > 0 Then
    m_sValue = ""
    Do
     j = InStr(i + 1, s, """")
     If j = 0 Then s1 = Mid(s, i + 1) _
     Else s1 = Mid(s, i + 1, j - i - 1)
     s1 = pValidateFile(m_tFolders(m_nSelectedFolder).sPath, s1)
     If s1 = "" Then Exit Function
     m_sValue = m_sValue + "|" + s1
     If j = 0 Then Exit Do
     i = InStr(j + 1, s, """")
    Loop Until i = 0
    m_sValue = Mid(m_sValue, 2)
   Else
    s1 = pValidateFile(m_tFolders(m_nSelectedFolder).sPath, s)
    If s1 = "" Then Exit Function
    m_sValue = s1
   End If
   '///
   m_bUnload = True
   m_bCancel = False
  End If
 Case "cmdCancel"
  m_bUnload = True
 Case "optFolder"
  m_nSelectedFolder = obj.ChildIndex \ 2
  pShowFile
 Case "cmbFolder"
  i = obj.ChildIndex \ 2
  If i = 0 Then
   j = obj.ListViewObject.SelectedRow
   If j > 0 Then j = obj.ListViewObject.ItemData(j, 1)
   Select Case j
   Case -1
    s = Space(1024)
    SHGetSpecialFolderPath 0, s, CSIDL_DESKTOPDIRECTORY, 1
   Case -2
    s = Space(1024)
    SHGetSpecialFolderPath 0, s, CSIDL_PERSONAL, 1
   Case 1 To 26
    s = ChrW(64 + j) + ":\"
   End Select
   i = InStr(1, s, vbNullChar)
   If i > 0 Then s = Left(s, i - 1)
   If Right(s, 1) <> "\" Then s = s + "\"
   '///
   pCreateFolderButtons s
  ElseIf i <= m_nFolderCount Then
   j = obj.ListViewObject.SelectedRow
   If j > 0 Then j = obj.ListViewObject.ItemData(j, 1)
   If j > 0 And j <= m_tFolders(i).nCount Then
    pCreateFolderButtons m_tFolders(i).sPath + m_tFolders(i).tData(j).sName + "\"
   End If
  End If
  '///???
  m_bDiscardEvent = True
  FakeDXAppMainLoop VarPtr(1&)
  m_bDiscardEvent = False
  '///
 Case "cmdNewFolder"
  If m_nSelectedFolder > 0 And m_nSelectedFolder <= m_nFolderCount Then
   With New clsFakeDXUIInputBox
    s = Trim(.InputBox(objText.GetText("Input folder name"), objText.GetText("New folder")))
   End With
   If s <> "" And InStr(1, s, "/") = 0 And InStr(1, s, "\") = 0 Then
    If Replace(s, ".", "") <> "" Then
     s1 = m_tFolders(m_nSelectedFolder).sPath + s + "\"
     If pCheckFileExist(s1) Then
      With New clsFakeDXUIMsgBox
       .MsgBox objText.GetText(s1 + vbCrLf + _
       objText.GetText("The folder already exists. Please input a different name.")), vbExclamation, objText.GetText("Error")
      End With
     ElseIf MakeSureDirectoryPathExists(s1) Then
      With m_tFolders(m_nSelectedFolder)
       i = .nCount + 1
       .nCount = i
       If i > .nMax Then
        .nMax = i + 16
        ReDim Preserve .tData(1 To .nMax)
       End If
       With .tData(i)
        .sName = s
        .nSize = -1
        .sExtension = vbNullString
        f = CDbl(Now)
        .nTime = f
       End With
      End With
      '///
      With FakeDXUIControls(m_idx(IDC_ListView)).ListViewObject
       .EnsureVisible .AddItem(vbTab + s, , i, Array(Array("", -1), vbTab + objText.GetText("Folder"), vbTab + Format(f, "yyyy-mm-dd hh:mm:ss")))
      End With
      '///
      With FakeDXUIControls(m_idx(IDC_Container))
       j = m_nSelectedFolder * 2 + 1
       If j <= .ChildrenCount Then
        With FakeDXUIControls(.Children(j)).ListViewObject
         .AddItem s, , i
        End With
       End If
      End With
      '///
     Else
      With New clsFakeDXUIMsgBox
       .MsgBox s1 + vbCrLf + pGetLastDllErrorMessage, vbExclamation, objText.GetText("Error")
      End With
     End If
    End If
   End If
  End If
 Case "lstFile"
  If m_nSelectedFolder > 0 And m_nSelectedFolder <= m_nFolderCount Then
   With obj.ListViewObject
    If m_bMultiSelect Then
     For i = 1 To .RowCount
      If .ItemSelected(i, 1) Then
       j = .ItemData(i, 1)
       If j > 0 And j <= m_tFolders(m_nSelectedFolder).nCount Then
        If m_tFolders(m_nSelectedFolder).tData(j).nSize >= 0 Xor m_nType = 3 Then
         k = k + 1
         If k > 1 Then s = s + """ """
         s = s + m_tFolders(m_nSelectedFolder).tData(j).sName
        End If
       End If
      End If
     Next i
     '///
     If k > 1 Then s = """" + s + """"
     If k > 0 Then FakeDXUIControls(m_idx(IDC_FileName)).Text = s
    Else
     i = .SelectedRow
     If i > 0 Then
      j = .ItemData(i, 1)
      If j > 0 And j <= m_tFolders(m_nSelectedFolder).nCount Then
       If m_tFolders(m_nSelectedFolder).tData(j).nSize >= 0 Xor m_nType = 3 Then
        FakeDXUIControls(m_idx(IDC_FileName)).Text = m_tFolders(m_nSelectedFolder).tData(j).sName
       End If
      End If
     End If
    End If
   End With
  End If
 Case "cmbFilter"
  m_nFilterIndex = obj.ListViewObject.SelectedRow
  pShowFile
 End Select
 '////////////////////////////////
Case FakeCtl_Event_DblClick
 '////////////////////////////////
 If m_bDiscardEvent Then Exit Function
 Select Case obj.Name
 Case "lstFile"
  If m_nSelectedFolder > 0 And m_nSelectedFolder <= m_nFolderCount Then
   i = obj.ListViewObject.SelectedRow
   If i > 0 Then i = obj.ListViewObject.ItemData(i, 1)
   If i > 0 And i <= m_tFolders(m_nSelectedFolder).nCount Then
    If m_tFolders(m_nSelectedFolder).tData(i).nSize < 0 Then
     'open folder
     pCreateFolderButtons m_tFolders(m_nSelectedFolder).sPath + m_tFolders(m_nSelectedFolder).tData(i).sName + "\"
    ElseIf nType <> 3 Then
     'selected this
     s1 = pValidateFile(m_tFolders(m_nSelectedFolder).sPath, m_tFolders(m_nSelectedFolder).tData(i).sName, True)
     If s1 <> "" Then
      m_sValue = s1
      m_bUnload = True
      m_bCancel = False
     End If
    End If
   End If
  End If
 End Select
 '////////////////////////////////
Case FakeCtl_Event_Unload
 m_bUnload = True
End Select
End Function

