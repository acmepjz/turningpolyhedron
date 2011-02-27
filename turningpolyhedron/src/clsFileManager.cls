VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsFileManager"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Declare Function PathCombine Lib "shlwapi.dll" Alias "PathCombineA" (ByVal szDest As String, ByVal lpszDir As String, ByVal lpszFile As String) As Long

Private Declare Function FindFirstFile Lib "kernel32.dll" Alias "FindFirstFileA" (ByVal lpFileName As String, ByRef lpFindFileData As WIN32_FIND_DATA) As Long
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

Private m_sPath() As String, m_nPathCount As Long

Private Type typeFileMgrData
 sName As String
 nSize As Long '<0=unused
 nArchiveIndex As Long
 nArchiveItemIndex As Long
 lpbData As Long
 bData() As Byte
End Type

Private m_tFiles() As typeFileMgrData '1-based
Private m_nFileCount As Long

Private Type typeFileMgrArchiveData
 sName As String
 obj As clsSimpleTarFile 'nothing=unused
End Type

Private m_tArchive() As typeFileMgrArchiveData
Private m_nArchiveCount As Long

Friend Sub Destroy()
Erase m_tFiles, m_tArchive
m_nFileCount = 0
m_nArchiveCount = 0
End Sub

Friend Function pFindFile(ByVal s As String) As String
Dim i As Long, j As Long
Dim s1 As String
'///
Dim h As Long, t As WIN32_FIND_DATA
'///
's = Replace(s, "/", "\")
'j = Len(s)
'Do
' i = j
' s = Replace(s, "\\", "\")
' j = Len(s)
'Loop Until i = j
'///
If Mid(s, 2, 1) = ":" Then
 h = FindFirstFile(s, t)
 If h = 0 Or h = -1 Then
 Else
  If (t.dwFileAttributes And vbDirectory) = 0 Then pFindFile = s
  FindClose h
 End If
Else
 For i = 1 To m_nPathCount
  s1 = Space(Len(m_sPath(i)) + Len(s) + 1024&)
  PathCombine s1, m_sPath(i), s
  j = InStr(1, s1, vbNullChar)
  If j > 0 Then s1 = Left(s1, j - 1)
  '///
  h = FindFirstFile(s1, t)
  If h = 0 Or h = -1 Then
  Else
   FindClose h
   If (t.dwFileAttributes And vbDirectory) = 0 Then
    pFindFile = s1
    Exit For
   End If
  End If
  '///
 Next i
End If
End Function

Friend Property Get ArchiveCount() As Long
ArchiveCount = m_nArchiveCount
End Property

Friend Property Get ArchiveName(ByVal nIndex As Long) As String
ArchiveName = m_tArchive(nIndex).sName
End Property

Friend Property Get ArchiveFile(ByVal nIndex As Long) As clsSimpleTarFile
Set ArchiveFile = m_tArchive(nIndex).obj
End Property

Friend Property Get FileCount() As Long
FileCount = m_nFileCount
End Property

Friend Property Get FileName(ByVal nIndex As Long) As String
FileName = m_tFiles(nIndex).sName
End Property

Friend Property Get FileSize(ByVal nIndex As Long) As Long
FileSize = m_tFiles(nIndex).nSize
End Property

Friend Property Get FilePointer(ByVal nIndex As Long) As Long
FilePointer = m_tFiles(nIndex).lpbData
End Property

Friend Sub CloseArchiveFile(ByVal nIndex As Long)
Dim i As Long
Dim t As typeFileMgrData
'///
If nIndex <= 0 Or nIndex > m_nArchiveCount Then Exit Sub
If m_tArchive(nIndex).obj Is Nothing Then Exit Sub
'///
t.nSize = -1
For i = 1 To m_nFileCount
 If m_tFiles(i).nArchiveIndex = nIndex Then m_tFiles(i) = t
Next i
'///
m_tArchive(nIndex).sName = vbNullString
Set m_tArchive(nIndex).obj = Nothing
End Sub

Friend Sub CloseFile(ByVal nIndex As Long)
Dim t As typeFileMgrData
If nIndex <= 0 Or nIndex > m_nFileCount Then Exit Sub
t.nSize = -1
m_tFiles(nIndex) = t
End Sub

Friend Function LoadFile(ByVal s As String) As Long
On Error Resume Next
Dim i As Long, j As Long
Dim nArchiveIndex As Long
Dim s1 As String
Dim b As Boolean
'///
s = Replace(s, "/", "\")
j = Len(s)
Do
 i = j
 s = Replace(s, "\\", "\")
 j = Len(s)
Loop Until i = j
'///
j = 0
s1 = LCase(s)
For i = 1 To m_nFileCount
 If m_tFiles(i).nSize >= 0 Then
  If s1 = LCase(m_tFiles(i).sName) Then
   LoadFile = i
   Exit Function
  End If
 Else
  j = i
 End If
Next i
'///
s1 = pFindFile(s)
If s1 = vbNullString Then
 '///maybe in archive file
 i = InStrRev(s, "\")
 Do While i > 1
  b = False
  If i > 4 Then b = b Or LCase(Mid(s, i - 4, 4)) = ".tar"
  If i > 9 Then b = b Or LCase(Mid(s, i - 9, 9)) = ".tar.lzma"
  If b Then
   nArchiveIndex = LoadArchiveFile(Left(s, i - 1))
   If nArchiveIndex > 0 Then Exit Do
  End If
  i = InStrRev(s, "\", i - 1)
 Loop
 If i <= 1 Then Exit Function
 s1 = Mid(s, i + 1)
 i = m_tArchive(nArchiveIndex).obj.FindOneFile(s1)
 If i <= 0 Then Exit Function
 '///
 If j = 0 Then
  m_nFileCount = m_nFileCount + 1
  ReDim Preserve m_tFiles(1 To m_nFileCount)
  j = m_nFileCount
 End If
 With m_tFiles(j)
  .sName = s
  .nSize = m_tArchive(nArchiveIndex).obj.FileSize(i)
  .nArchiveIndex = nArchiveIndex
  .nArchiveItemIndex = i
  .lpbData = m_tArchive(nArchiveIndex).obj.FilePointer(i)
 End With
Else
 Err.Clear
 Open s1 For Binary Access Read As #1
 If Err.Number Then
  Close
  Exit Function
 End If
 i = LOF(1)
 '///
 If j = 0 Then
  m_nFileCount = m_nFileCount + 1
  ReDim Preserve m_tFiles(1 To m_nFileCount)
  j = m_nFileCount
 End If
 With m_tFiles(j)
  .sName = s
  .nSize = i
  If i > 0 Then
   ReDim .bData(i - 1)
   Get #1, 1, .bData
   .lpbData = VarPtr(.bData(0))
  End If
 End With
 '///
 Close
End If
LoadFile = j
End Function

Friend Function FindArchiveFile(ByVal s As String) As Long
Dim i As Long
s = LCase(s)
For i = 1 To m_nArchiveCount
 If Not m_tArchive(i).obj Is Nothing Then
  If s = LCase(m_tArchive(i).sName) Then
   FindArchiveFile = i
   Exit Function
  End If
 End If
Next i
End Function

Friend Function FindFile(ByVal s As String) As Long
Dim i As Long
s = LCase(s)
For i = 1 To m_nFileCount
 If m_tFiles(i).nSize >= 0 Then
  If s = LCase(m_tFiles(i).sName) Then
   FindFile = i
   Exit Function
  End If
 End If
Next i
End Function

Friend Function LoadArchiveFile(ByVal s As String) As Long
Dim i As Long, j As Long
Dim s1 As String
Dim obj As New clsSimpleTarFile
'///
s = Replace(s, "/", "\")
j = Len(s)
Do
 i = j
 s = Replace(s, "\\", "\")
 j = Len(s)
Loop Until i = j
'///
j = 0
s1 = LCase(s)
For i = 1 To m_nArchiveCount
 If Not m_tArchive(i).obj Is Nothing Then
  If s1 = LCase(m_tArchive(i).sName) Then
   LoadArchiveFile = i
   Exit Function
  End If
 Else
  j = i
 End If
Next i
'///
s1 = pFindFile(s)
If s1 = vbNullString Then Exit Function
'///
If LCase(Right(s1, 4)) = ".tar" Then
 If Not obj.LoadFile(s1) Then Exit Function
ElseIf LCase(Right(s1, 9)) = ".tar.lzma" Then
 If Not obj.LoadTarLzmaFile(s1) Then Exit Function
Else
 'unsupported format
 Exit Function
End If
'///
If j = 0 Then
 m_nArchiveCount = m_nArchiveCount + 1
 ReDim Preserve m_tArchive(1 To m_nArchiveCount)
 j = m_nArchiveCount
End If
With m_tArchive(j)
 .sName = s
 Set .obj = obj
End With
LoadArchiveFile = j
End Function

Friend Sub ClearPath()
Erase m_sPath
m_nPathCount = 0
End Sub

'TODO:set path to archive file
Friend Sub AddPath(ByVal s As String)
Dim i As Long, j As Long
Dim v As Variant
Dim s1 As String
'///
s = Replace(s, "/", "\")
j = Len(s)
Do
 i = j
 s = Replace(s, "\\", "\")
 j = Len(s)
Loop Until i = j
'///
v = Split(s, "|")
For i = 0 To UBound(v)
 s = Trim(v(i))
 If Right(s, 1) <> "\" Then s = s + "\"
 s1 = LCase(s)
 For j = 1 To m_nPathCount
  If s1 = LCase(m_sPath(j)) Then Exit For
 Next j
 If j > m_nPathCount Then
  m_nPathCount = m_nPathCount + 1
  ReDim Preserve m_sPath(1 To m_nPathCount)
  m_sPath(m_nPathCount) = s
 End If
Next i
End Sub

Friend Property Get PathCount() As Long
PathCount = m_nPathCount
End Property

Friend Property Get Path(ByVal nIndex As Long) As String
Path = m_sPath(nIndex)
End Property

Friend Property Let Path(ByVal nIndex As Long, ByVal s As String)
Dim i As Long, j As Long
'///
s = Replace(s, "/", "\")
j = Len(s)
Do
 i = j
 s = Replace(s, "\\", "\")
 j = Len(s)
Loop Until i = j
If Right(s, 1) <> "\" Then s = s + "\"
'///
m_sPath(nIndex) = s
End Property

