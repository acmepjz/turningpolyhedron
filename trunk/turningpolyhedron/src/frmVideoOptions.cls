VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "frmVideoOptions"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)
Private Type SAFEARRAYBOUND
    cElements As Long
    lLbound As Long
End Type
Private Type SAFEARRAY2D
    cDims As Integer
    fFeatures As Integer
    cbElements As Long
    cLocks As Long
    pvData As Long
    Bounds(0 To 1) As SAFEARRAYBOUND
End Type
Private Declare Function VarPtrArray Lib "msvbvm60.dll" Alias "VarPtr" (Ptr() As Any) As Long

Private Declare Function GetCursor Lib "user32.dll" () As Long
Private Declare Function GetCursorPos Lib "user32.dll" (ByRef lpPoint As POINTAPI) As Long
Private Declare Function ScreenToClient Lib "user32.dll" (ByVal hwnd As Long, ByRef lpPoint As POINTAPI) As Long
Private Declare Function GetIconInfo Lib "user32.dll" (ByVal hIcon As Long, ByRef piconinfo As ICONINFO) As Long
Private Declare Function DeleteObject Lib "gdi32.dll" (ByVal hObject As Long) As Long
Private Declare Function DrawIcon Lib "user32.dll" (ByVal hdc As Long, ByVal x As Long, ByVal y As Long, ByVal hIcon As Long) As Long
Private Type POINTAPI
    x As Long
    y As Long
End Type

Private Type ICONINFO
    fIcon As Long
    xHotspot As Long
    yHotspot As Long
    hbmMask As Long
    hbmColor As Long
End Type

Private m_nIndex As Long
Private m_nQuality As Long, m_nFPS As Long, m_nFPS_1 As Long

Private m_tSA As SAFEARRAY2D

Private m_fTime As Single, m_nOldFrame As Long

Private m_objEncoder As New clsVFWEncoder

Private m_idxForm As Long, m_idxSlider As Long, m_idxQuality As Long, m_idxAbout As Long, m_idxConfig As Long

Private d3dtex_rt As Direct3DTexture9
Private d3dtex_sys As Direct3DTexture9

Implements IFakeDXUIEvent

Friend Property Get IsRecordingBegin() As Boolean
IsRecordingBegin = m_objEncoder.IsRecordingBegin
End Property

Friend Property Get RecordFileSize() As Long
RecordFileSize = m_objEncoder.RecordFileSize
End Property

Friend Sub Create()
Dim i As Long
'///
If m_idxForm Then Exit Sub
'///
If Not m_objEncoder.CreateEncoderList Then
 With New clsFakeDXUIMsgBox
  .MsgBox "Can't create encoder list", vbCritical, "Error"
 End With
End If
'///
With FakeDXUIControls(1).AddNewChildren(FakeCtl_Form, 0, 0, _
600, 256, FFS_CloseButton Or FFS_Moveable Or FFS_TitleBar, , False, , "Video capture options")
 m_idxForm = .Index
 Set .EventObject = Me
 '///
 .AddNewChildren FakeCtl_Label, 8, 8, -8, 32, , , , , "Encoder", , , , , 1
 With .AddNewChildren(FakeCtl_ComboBox, 80, 8, -80, 32, FCS_CanGetFocus Or FCS_TabStop, , , , , , "cmbEncoder", , , 1)
  With .ListViewObject
   .FullRowSelect = True
   .ColumnHeader = True
   .AddColumn "Name", , efctStringCaseInsensitive, efcfSizable Or efcfSortable, 128
   .AddColumn "Description", , efctStringCaseInsensitive, efcfSizable Or efcfSortable, 256
   .AddColumn "File name", , efctStringCaseInsensitive, efcfSizable Or efcfSortable, 256
   '///
   For i = 0 To m_objEncoder.EncoderCount - 1
    .AddItem m_objEncoder.EncoderName(i), , i, Array(m_objEncoder.EncoderDescription(i), m_objEncoder.EncoderFileName(i))
   Next i
  End With
  .ComboBoxPrimaryColumn = 2
  .ComboBoxDropdownHeight = 16
 End With
 '///
 .AddNewChildren FakeCtl_Label, 8, 40, -8, 64, , , , , "Quality", , , , , 1
 With .AddNewChildren(FakeCtl_ScrollBar, 80, 40, -128, 64, FSS_Slider Or FCS_CanGetFocus Or FCS_TabStop, , , , , , "hsQuality", , , 1)
  m_idxSlider = .Index
  .Max = 10000
  .Value = 7000
  .SmallChange = 1
  .LargeChange = 1000
 End With
 With .AddNewChildren(FakeCtl_Label, -120, 40, 0, 64, , , , , "70.00", , , 1, , 1)
  m_idxQuality = .Index
 End With
 '///
 With .AddNewChildren(FakeCtl_Button, -72, 8, -8, 32, FCS_CanGetFocus Or FCS_TabStop, False, , , "About", , "cmdAbout", 1, , 1)
  m_idxAbout = .Index
 End With
 With .AddNewChildren(FakeCtl_Button, -72, 40, -8, 64, FCS_CanGetFocus Or FCS_TabStop, False, , , "Config", , "cmdConfig", 1, , 1)
  m_idxConfig = .Index
 End With
 '///
 .AddNewChildren FakeCtl_Label, 8, 72, -8, 96, , , , , "Framerate", , , , , 1
 With .AddNewChildren(FakeCtl_TextBox, 128, 72, -8, 96, FCS_CanGetFocus Or FCS_TabStop Or FTS_AutoSelect Or FTS_NumberOnly Or FTS_UpDown, , , , , "30", "txtFPS", , , 1)
  .SmallChange = 1
 End With
 .AddNewChildren FakeCtl_Label, 8, 104, -8, 128, , , , , "Key frame every", , , , , 1
 With .AddNewChildren(FakeCtl_TextBox, 128, 104, -8, 128, FCS_CanGetFocus Or FCS_TabStop Or FTS_AutoSelect Or FTS_NumberOnly Or FTS_UpDown, , , , , "0", "txtFPS_1", , , 1)
  .SmallChange = 1
 End With
 '///
 .AddNewChildren FakeCtl_Button, -72, -32, -8, -8, FCS_CanGetFocus Or FCS_TabStop, , , , "Close", , "cmdClose", 1, 1, 1, 1
End With
'///
m_nQuality = 7000
m_nFPS = 30
m_nFPS_1 = 0
m_nIndex = -1
End Sub

Friend Sub Show()
Create
FakeDXUIControls(m_idxForm).MoveToCenter
FakeDXUIControls(m_idxForm).Show 1
End Sub

Friend Sub Hide()
If m_idxForm Then FakeDXUIControls(m_idxForm).Hide
End Sub

Friend Function BeginRecording() As Boolean
Dim tBI As BITMAPINFO
'///
If m_objEncoder.IsRecordingBegin Then
 BeginRecording = True
 Exit Function
End If
'///
If m_nIndex < 0 Or m_nIndex >= m_objEncoder.EncoderCount Then Exit Function
'///
m_tSA.cDims = 1
m_tSA.cbElements = 4
m_tSA.Bounds(0).cElements = d3dpp.BackBufferWidth * d3dpp.BackBufferHeight
'///
tBI.bmiHeader.biSize = Len(tBI.bmiHeader)
tBI.bmiHeader.biWidth = d3dpp.BackBufferWidth
tBI.bmiHeader.biHeight = d3dpp.BackBufferHeight
tBI.bmiHeader.biPlanes = 1
tBI.bmiHeader.biBitCount = 32
tBI.bmiHeader.biSizeImage = m_tSA.Bounds(0).cElements * 4&
'///
Set d3dtex_sys = Nothing
D3DXCreateTexture d3dd9, d3dpp.BackBufferWidth, d3dpp.BackBufferHeight, 1, 0, d3dpp.BackBufferFormat, D3DPOOL_SYSTEMMEM, d3dtex_sys
Set d3dtex_rt = Nothing
If d3dpp.MultiSampleType > 1 Then
 D3DXCreateTexture d3dd9, d3dpp.BackBufferWidth, d3dpp.BackBufferHeight, 1, D3DUSAGE_RENDERTARGET, d3dpp.BackBufferFormat, D3DPOOL_DEFAULT, d3dtex_rt
End If
'///
m_fTime = 0
m_nOldFrame = -1
BeginRecording = m_objEncoder.BeginRecording(FakeDXAppMyGamesPath + _
Format(Now, "yyyy_mm_dd_hh_mm_ss") + ".avi", tBI, m_nIndex, m_nQuality, m_nFPS, m_nFPS_1)
End Function

Friend Sub EndRecording()
m_objEncoder.EndRecording
'///
Set d3dtex_sys = Nothing
Set d3dtex_rt = Nothing
End Sub

Friend Sub RecordFrame()
Dim tLR As D3DLOCKED_RECT
Dim d() As Long
Dim i As Long, j As Long, k As Long
Dim lp As Long, lp2 As Long
Dim hCur As Long
Dim p As POINTAPI
Dim tInfo As ICONINFO
'///
If Not m_objEncoder.IsRecordingBegin Then Exit Sub
'///
i = m_fTime / 1000 * m_nFPS
m_fTime = m_fTime + objTiming.GetDelta
If i < m_nOldFrame Then Exit Sub
If i = m_nOldFrame Then i = i + 1
m_nOldFrame = i
'///
If d3dpp.MultiSampleType > 1 Then
 d3dd9.StretchRect d3dd9.GetRenderTarget(0), ByVal 0, d3dtex_rt.GetSurfaceLevel(0), ByVal 0, D3DTEXF_NONE
 d3dd9.GetRenderTargetData d3dtex_rt.GetSurfaceLevel(0), d3dtex_sys.GetSurfaceLevel(0)
Else
 d3dd9.GetRenderTargetData d3dd9.GetRenderTarget(0), d3dtex_sys.GetSurfaceLevel(0)
End If
'///draw cursor
GetCursorPos p
ScreenToClient d3dpp.hDeviceWindow, p
If p.x >= -32 And p.y >= -32 And p.x < d3dpp.BackBufferWidth + 32 And p.y < d3dpp.BackBufferHeight + 32 Then
 hCur = GetCursor
 If hCur Then
  If GetIconInfo(hCur, tInfo) Then
   p.x = p.x - tInfo.xHotspot
   p.y = p.y - tInfo.yHotspot
   If tInfo.hbmMask Then DeleteObject tInfo.hbmMask
   If tInfo.hbmColor Then DeleteObject tInfo.hbmColor
  End If
  i = d3dtex_sys.GetSurfaceLevel(0).GetDC
  DrawIcon i, p.x, p.y, hCur
  d3dtex_sys.GetSurfaceLevel(0).ReleaseDC i
 End If
End If
'///
d3dtex_sys.LockRect 0, tLR, ByVal 0, 0
'///dirty code:upside down
m_tSA.pvData = tLR.pBits
CopyMemory ByVal VarPtrArray(d), VarPtr(m_tSA), 4
lp2 = d3dpp.BackBufferWidth * (d3dpp.BackBufferHeight - 1)
For j = 0 To d3dpp.BackBufferHeight \ 2 - 1
 For i = 0 To d3dpp.BackBufferWidth - 1
  k = d(lp + i)
  d(lp + i) = d(lp2 + i)
  d(lp2 + i) = k
 Next i
 lp = lp + d3dpp.BackBufferWidth
 lp2 = lp2 - d3dpp.BackBufferWidth
Next j
CopyMemory ByVal VarPtrArray(d), 0&, 4
'///
If Not m_objEncoder.RecordFrame(m_nOldFrame, tLR.pBits) Then
 'error!!!
 Debug.Print "error!!!"
End If
d3dtex_sys.UnlockRect 0
End Sub

Private Function IFakeDXUIEvent_OnEvent(ByVal obj As clsFakeDXUI, ByVal nType As Long, ByVal nParam1 As Long, ByVal nParam2 As Long, ByVal nParam3 As Long) As Long
Dim i As Long
'///
Select Case nType
Case FakeCtl_Event_Click
 Select Case obj.Name
 Case "cmbEncoder"
  With obj.ListViewObject
   i = .SelectedRow
   If i > 0 And i <= .RowCount Then
    i = .ItemData(i, 1)
   Else
    i = -1
   End If
  End With
  '///
  m_nIndex = i
  FakeDXUIControls(m_idxAbout).Enabled = m_objEncoder.AboutEnabled(i)
  FakeDXUIControls(m_idxConfig).Enabled = m_objEncoder.ConfigEnabled(i)
  m_nQuality = m_objEncoder.EncoderDefaultQuality(i)
  FakeDXUIControls(m_idxSlider).Value = m_nQuality
  FakeDXUIControls(m_idxQuality).Caption = Format(m_nQuality / 100, "0.00")
 Case "cmdAbout"
  m_objEncoder.ShowAbout m_nIndex, d3dpp.hDeviceWindow
 Case "cmdConfig"
  m_objEncoder.ShowConfig m_nIndex, d3dpp.hDeviceWindow
 Case "cmdClose"
  Hide
 End Select
Case FakeCtl_Event_Change
 Select Case obj.Name
 Case "txtFPS"
  m_nFPS = Val(obj.Text)
 Case "txtFPS_1"
  m_nFPS_1 = Val(obj.Text)
 Case "hsQuality"
  m_nQuality = obj.Value
  FakeDXUIControls(m_idxQuality).Caption = Format(m_nQuality / 100, "0.00")
 End Select
Case FakeCtl_Event_Unload
 obj.Hide
 IFakeDXUIEvent_OnEvent = 1
End Select
End Function
