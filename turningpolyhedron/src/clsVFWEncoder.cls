VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsVFWEncoder"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)

Private m_tInfo() As tagICINFO '0-based
Private m_bAboutEnabled() As Boolean
Private m_bConfigEnabled() As Boolean
Private m_nDefaultQuality() As Long
Private m_nInfoCount As Long, m_nInfoMax As Long

Private m_nFileSize As Long

Private m_tBI As BITMAPINFO
Private m_pfile As Long, m_ps As Long, m_psCompressed As Long
Private m_tOptions As AVICOMPRESSOPTIONS
Private m_bErr As Boolean
Private m_tStreamInfo As AVISTREAMINFOW
Private m_bState() As Byte

Friend Property Get EncoderInfo(ByVal nIndex As Long) As tagICINFO
If nIndex >= 0 And nIndex < m_nInfoCount Then EncoderInfo = m_tInfo(nIndex)
End Property

Friend Property Get EncoderCount() As Long
EncoderCount = m_nInfoCount
End Property

Friend Property Get EncoderDefaultQuality(ByVal nIndex As Long) As Long
If nIndex >= 0 And nIndex < m_nInfoCount Then EncoderDefaultQuality = m_nDefaultQuality(nIndex)
End Property

Friend Property Get EncoderFccType(ByVal nIndex As Long) As Long
If nIndex >= 0 And nIndex < m_nInfoCount Then EncoderFccType = m_tInfo(nIndex).fccType
End Property

Friend Property Get EncoderFccHandler(ByVal nIndex As Long) As Long
If nIndex >= 0 And nIndex < m_nInfoCount Then EncoderFccHandler = m_tInfo(nIndex).fccHandler
End Property

Friend Property Get EncoderName(ByVal nIndex As Long) As String
Dim s As String
If nIndex >= 0 And nIndex < m_nInfoCount Then
 s = String(17, vbNullChar)
 CopyMemory ByVal StrPtr(s), m_tInfo(nIndex).szName(0), 32&
 s = Left(s, InStr(1, s, vbNullChar) - 1)
 EncoderName = s
End If
End Property

Friend Property Get EncoderDescription(ByVal nIndex As Long) As String
Dim s As String
If nIndex >= 0 And nIndex < m_nInfoCount Then
 s = String(130, vbNullChar)
 CopyMemory ByVal StrPtr(s), m_tInfo(nIndex).szDescription(0), 256&
 s = Left(s, InStr(1, s, vbNullChar) - 1)
 EncoderDescription = s
End If
End Property

Friend Property Get EncoderFileName(ByVal nIndex As Long) As String
Dim s As String
If nIndex >= 0 And nIndex < m_nInfoCount Then
 s = String(130, vbNullChar)
 CopyMemory ByVal StrPtr(s), m_tInfo(nIndex).szDriver(0), 256&
 s = Left(s, InStr(1, s, vbNullChar) - 1)
 EncoderFileName = s
End If
End Property

Friend Property Get AboutEnabled(ByVal nIndex As Long) As Boolean
If nIndex >= 0 And nIndex < m_nInfoCount Then AboutEnabled = m_bAboutEnabled(nIndex)
End Property

Friend Property Get ConfigEnabled(ByVal nIndex As Long) As Boolean
If nIndex >= 0 And nIndex < m_nInfoCount Then ConfigEnabled = m_bConfigEnabled(nIndex)
End Property

Friend Sub ShowAbout(ByVal nIndex As Long, ByVal hwnd As Long)
If nIndex >= 0 And nIndex < m_nInfoCount Then ShowAboutEx m_tInfo(nIndex).fccType, m_tInfo(nIndex).fccHandler, hwnd
End Sub

Friend Sub ShowAboutEx(ByVal fccType As Long, ByVal fccHandler As Long, ByVal hwnd As Long)
Dim hic As Long
hic = ICOpen(fccType, fccHandler, ICMODE_QUERY)
If hic Then
 ICAbout hic, hwnd
 ICClose hic
End If
End Sub

Friend Sub ShowConfig(ByVal nIndex As Long, ByVal hwnd As Long)
If nIndex >= 0 And nIndex < m_nInfoCount Then ShowConfigEx m_tInfo(nIndex).fccType, m_tInfo(nIndex).fccHandler, hwnd
End Sub

Friend Sub ShowConfigEx(ByVal fccType As Long, ByVal fccHandler As Long, ByVal hwnd As Long)
Dim hic As Long
hic = ICOpen(fccType, fccHandler, ICMODE_QUERY)
If hic Then
 ICConfigure hic, hwnd
 ICClose hic
End If
End Sub

Friend Function CreateEncoderList() As Boolean
Dim i As Long
Dim hic As Long
'///
If m_nInfoCount > 0 Then
 CreateEncoderList = True
 Exit Function
End If
'///
m_nInfoCount = 0
m_nInfoMax = 64
ReDim m_tInfo(m_nInfoMax - 1)
ReDim m_bAboutEnabled(m_nInfoMax - 1)
ReDim m_bConfigEnabled(m_nInfoMax - 1)
ReDim m_nDefaultQuality(m_nInfoMax - 1)
'///
'If (((VideoForWindowsVersion And &HFFFF0000) \ &H10000) And &HFFFF&) < &H10A& Then
' 'MsgBox "Error! Video for Windows version too old!", vbCritical
' Exit Function
'End If
'///
Do
 m_tInfo(m_nInfoCount).dwSize = Len(m_tInfo(m_nInfoCount))
 If ICInfo(ICTYPE_VIDEO, i, m_tInfo(m_nInfoCount)) = 0 Then Exit Do
 '///
 hic = ICOpen(m_tInfo(m_nInfoCount).fccType, m_tInfo(m_nInfoCount).fccHandler, ICMODE_QUERY)
 If hic Then
  ICGetInfo hic, m_tInfo(m_nInfoCount), Len(m_tInfo(m_nInfoCount))
  m_bAboutEnabled(m_nInfoCount) = ICQueryAbout(hic)
  m_bConfigEnabled(m_nInfoCount) = ICQueryConfigure(hic)
  m_nDefaultQuality(m_nInfoCount) = ICGetDefaultQuality(hic)
  ICClose hic
  '///
  m_nInfoCount = m_nInfoCount + 1
  If m_nInfoCount >= m_nInfoMax Then
   m_nInfoMax = m_nInfoMax + 64&
   ReDim Preserve m_tInfo(m_nInfoMax - 1)
   ReDim Preserve m_bAboutEnabled(m_nInfoMax - 1)
   ReDim Preserve m_bConfigEnabled(m_nInfoMax - 1)
   ReDim Preserve m_nDefaultQuality(m_nInfoMax - 1)
  End If
 End If
 i = i + 1
Loop
'///over
CreateEncoderList = True
End Function

Private Sub Class_Terminate()
Destroy
End Sub

Friend Property Get IsRecordingBegin() As Boolean
IsRecordingBegin = m_pfile <> 0
End Property

Friend Function BeginRecording(ByVal fn As String, ByRef lpbiInput As BITMAPINFO, ByVal nIndex As Long, Optional ByVal nQuality As Long = 7000, Optional ByVal nFrameRate As Long = 30, Optional ByVal nKeyFrameEvery As Long) As Boolean
If nIndex >= 0 And nIndex < m_nInfoCount Then
 BeginRecording = BeginRecordingEx(fn, lpbiInput, m_tInfo(nIndex).fccType, m_tInfo(nIndex).fccHandler, nQuality, nFrameRate, nKeyFrameEvery)
End If
End Function

Friend Function BeginRecordingEx(ByVal fn As String, ByRef lpbiInput As BITMAPINFO, ByVal fccType As Long, ByVal fccHandler As Long, Optional ByVal nQuality As Long = 7000, Optional ByVal nFrameRate As Long = 30, Optional ByVal nKeyFrameEvery As Long) As Boolean
Dim hic As Long
Dim bErr As Boolean
'///
EndRecording
'///
m_tBI = lpbiInput
If nKeyFrameEvery = 0 Then nKeyFrameEvery = nFrameRate
'///
hic = ICOpen(fccType, fccHandler, ICMODE_QUERY)
If hic Then
 '///
 m_tOptions.cbParms = ICGetStateSize(hic)
 If m_tOptions.cbParms > 0 Then
  ReDim m_bState(m_tOptions.cbParms - 1)
  m_tOptions.lpParms = VarPtr(m_bState(0))
  ICGetState hic, m_tOptions.lpParms, m_tOptions.cbParms
 Else
  m_tOptions.lpParms = 0
  m_tOptions.cbParms = 0
 End If
 '///
 bErr = ICCompressQuery(hic, VarPtr(m_tBI), 0) <> ICERR_OK
 ICClose hic
 If bErr Then 'TODO: Try adjusting width/height a little bit
  Exit Function
 End If
Else
 Exit Function
End If
'///
On Error Resume Next
Err.Clear
hic = FreeFile
If Err.Number = 0 Then
 Open fn For Output As hic
 Close hic
End If
If Err.Number Then Exit Function
On Error GoTo 0
'///
AVIFileInit
If AVIFileOpenW(m_pfile, ByVal StrPtr(fn), OF_WRITE Or OF_CREATE, 0) = AVIERR_OK Then
 m_tStreamInfo.fccType = streamtypeVIDEO
 m_tStreamInfo.fccHandler = 0
 m_tStreamInfo.dwScale = 1
 m_tStreamInfo.dwRate = nFrameRate
 m_tStreamInfo.dwSuggestedBufferSize = m_tBI.bmiHeader.biSizeImage
 m_tStreamInfo.rcFrameRight = m_tBI.bmiHeader.biWidth
 m_tStreamInfo.rcFrameBottom = m_tBI.bmiHeader.biHeight
 If AVIFileCreateStreamW(m_pfile, m_ps, m_tStreamInfo) = AVIERR_OK Then
  m_tOptions.fccType = streamtypeVIDEO
  m_tOptions.fccHandler = fccHandler
  m_tOptions.dwKeyFrameEvery = nKeyFrameEvery        '// keyframe rate
  m_tOptions.dwQuality = nQuality     '// compress quality 0-10,000
  m_tOptions.dwBytesPerSecond = 0          '       // bytes per second
  m_tOptions.dwFlags = AVICOMPRESSF_VALID Or AVICOMPRESSF_KEYFRAMES               '// flags
  m_tOptions.lpFormat = 0          '                         // save format
  m_tOptions.cbFormat = 0
  m_tOptions.dwInterleaveEvery = 0            '// for non-video streams only
  If AVIMakeCompressedStream(m_psCompressed, m_ps, m_tOptions, ByVal 0) = AVIERR_OK Then
   If AVIStreamSetFormat(m_psCompressed, 0, m_tBI, m_tBI.bmiHeader.biSize) = AVIERR_OK Then '+ m_tBI.bmiHeader.biClrUsed * 16&
    BeginRecordingEx = True
    '///
    m_nFileSize = 0
    '///
    Exit Function
   End If
  End If
 End If
 '///
 EndRecording
Else
 AVIFileExit
End If
'///
On Error Resume Next
Kill fn
End Function

Friend Function RecordFrame(ByVal nFrameNumber As Long, ByVal lpBitmap As Long) As Boolean
Dim i As Long
Dim nSize As Long
If m_pfile <> 0 And m_psCompressed <> 0 Then
 i = AVIStreamWrite(m_psCompressed, nFrameNumber, 1, ByVal lpBitmap, m_tBI.bmiHeader.biSizeImage, 0, 0, nSize)
 m_nFileSize = m_nFileSize + nSize
 If i = AVIERR_OK Then
  RecordFrame = True
 End If
End If
End Function

Friend Property Get RecordFileSize() As Long
If m_pfile Then
 RecordFileSize = m_nFileSize
End If
End Property

Friend Sub EndRecording()
If m_pfile Then
' '///???
' m_tOptions.lpParms = 0
' m_tOptions.cbParms = 0
' AVISaveOptionsFree 1, VarPtr(m_tOptions) '???
 '///
 If m_psCompressed Then AVIStreamRelease m_psCompressed
 If m_ps Then AVIStreamRelease m_ps
 AVIFileRelease m_pfile
 AVIFileExit
 '///
 m_pfile = 0
 m_ps = 0
 m_psCompressed = 0
 '///
 Erase m_bState
End If
End Sub

Friend Sub Destroy()
EndRecording
End Sub
