VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "frmSettings"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private m_nAdapterModeCount As Long
Private m_tAdapterModes() As D3DDISPLAYMODE '0-based

Private m_sFileName As String

'dirty workaround for show in center of screen. TODO:
Private m_tDefaultPos As typeFakeDXUIRectEx

'control index
Private m_idx(127) As Long

Implements IFakeDXUIEvent

Friend Function LoadFile(Optional ByVal sFileName As String) As Boolean
'TODO:
End Function

Friend Function SaveFile(Optional ByVal sFileName As String) As Boolean
'TODO:
End Function

Friend Sub GetAdapterModes()
Dim i As Long
m_nAdapterModeCount = d3d9.GetAdapterModeCount(0, D3DFMT_X8R8G8B8)
If m_nAdapterModeCount > 0 Then
 ReDim m_tAdapterModes(m_nAdapterModeCount - 1)
 For i = 0 To m_nAdapterModeCount - 1
  d3d9.EnumAdapterModes 0, D3DFMT_X8R8G8B8, i, m_tAdapterModes(i)
 Next i
End If
End Sub

Friend Sub Create()
Dim i As Long
'///
GetAdapterModes
'///
'TODO:
'///
With FakeDXUIControls(1).AddNewChildren(FakeCtl_Form, -200, -200, _
200, 200, FFS_CloseButton Or FFS_Moveable Or FFS_TitleBar, , False, , objText.GetText("Options"), , , 0.5, 0.5, 0.5, 0.5)
 Set .EventObject = Me
 m_idx(0) = .Index
 m_tDefaultPos = .RectangleEx
 '///tab control
 With .AddNewChildren(FakeCtl_TabStrip, 8, 8, -8, -40, &H3003000, , , , , , , , , 1, 1)
  '///graphics
  With .AddNewChildren(FakeCtl_None, 0, 0, 320, 320, , , False)
   'resolution
   .AddNewChildren FakeCtl_Label, 10, 10, 198, 28, FCS_CanGetFocus Or FCS_TabStop, , , , objText.GetText("Resolution")
   With .AddNewChildren(FakeCtl_ComboBox, 100, 10, 298, 28, , , , , , , , , , , , , , objText.GetText("Change the screen resolution."))
    m_idx(1) = .Index
    With .ListViewObject
     .FullRowSelect = True
     .AddColumn ""
     For i = 0 To m_nAdapterModeCount - 1
      .AddItem CStr(m_tAdapterModes(i).Width) + "x" + CStr(m_tAdapterModes(i).Height) + "," + CStr(m_tAdapterModes(i).RefreshRate) + "Hz"
     Next i
    End With
   End With
   'fullscreen?
   With .AddNewChildren(FakeCtl_Button, 10, 30, 198, 48, FBS_CheckBox, , , , _
   objText.GetText("Fullscreen"), , , , , , , , , objText.GetText("Determines whether the program should run in full screen mode."))
    m_idx(2) = .Index
   End With
   'shadow map?
   With .AddNewChildren(FakeCtl_Button, 10, 60, 198, 78, FBS_CheckBox, , , , _
   objText.GetText("Shadow"), , , , , , , , , objText.GetText("Enables shadow effect."))
    m_idx(5) = .Index
   End With
   'post process?
   With .AddNewChildren(FakeCtl_Button, 10, 90, 198, 108, FBS_CheckBox, , , , _
   objText.GetText("Post process"), , , , , , , , , objText.GetText("Enables post process effects."))
    m_idx(3) = .Index
   End With
   'HDR blur quality
   .AddNewChildren FakeCtl_Label, 20, 110, 198, 128, FCS_CanGetFocus Or FCS_TabStop, , , , objText.GetText("HDR quality")
   With .AddNewChildren(FakeCtl_ComboBox, 100, 110, 298, 128, , , , , , , , , , , , , , objText.GetText("Set the quality of HDR blur."))
    m_idx(4) = .Index
    With .ListViewObject
     .FullRowSelect = True
     .AddColumn ""
     .AddItem objText.GetText("Low")
     .AddItem objText.GetText("Medium")
     .AddItem objText.GetText("High")
    End With
   End With
   'fog?
   With .AddNewChildren(FakeCtl_Button, 20, 130, 198, 148, FBS_CheckBox, , , , _
   objText.GetText("Fog"), , , , , , , , , objText.GetText("Enables fog effect."))
    m_idx(6) = .Index
   End With
   'volumetric fog?
   With .AddNewChildren(FakeCtl_Button, 30, 150, 198, 168, FBS_CheckBox, , , , _
   objText.GetText("Volumetric fog"), , , , , , , , , objText.GetText("Enables volumetric fog effect."))
    m_idx(7) = .Index
   End With
   'DOF?
   With .AddNewChildren(FakeCtl_Button, 20, 170, 198, 188, FBS_CheckBox, , , , _
   objText.GetText("Depth of fiend"), , , , , , , , , objText.GetText("Enables depth of field effect."))
    m_idx(8) = .Index
   End With
   'radial blur?
   With .AddNewChildren(FakeCtl_Button, 20, 190, 198, 208, FBS_CheckBox, , , , _
   objText.GetText("Radial blur"), , , , , , , , , objText.GetText("Enables radial blur effect."))
    m_idx(9) = .Index
   End With
  End With
  '///
  With .TabObject
   .AddTab objText.GetText("Graphics"), , , , , objText.GetText("Change the graphics settings.")
   .AddTab objText.GetText("Game"), , , , , objText.GetText("Change the game settings.")
   .SelectedTab = 1
  End With
 End With
 '///buttons
 .AddNewChildren FakeCtl_Button, -192, -32, -136, -8, FBS_Default Or &H3000000, , , , _
 objText.GetText("OK"), , "cmdOK", 1, 1, 1, 1, , , objText.GetText("Apply changes and close dialog.")
 .AddNewChildren FakeCtl_Button, -128, -32, -72, -8, FBS_Cancel Or &H3000000, , , , _
 objText.GetText("Cancel"), , "cmdCancel", 1, 1, 1, 1, , , objText.GetText("Discard changes and close dialog.")
 .AddNewChildren FakeCtl_Button, -64, -32, -8, -8, &H3000000, , , , _
 objText.GetText("Apply"), , "cmdApply", 1, 1, 1, 1, , , objText.GetText("Apply changes immediately.")
End With
'///
'TODO:
End Sub

'TODO:read current settings
Friend Sub Show()
Dim idx As Long
Dim i As Long
'///
Dim b(7) As Boolean, n(7) As Long
'///
idx = m_idx(0)
If idx > 0 Then
 '///graphics
 'screen resolution
 For i = 0 To m_nAdapterModeCount - 1
  If d3dpp.BackBufferWidth = m_tAdapterModes(i).Width And d3dpp.BackBufferHeight = m_tAdapterModes(i).Height Then
   If d3dpp.FullScreen_RefreshRateInHz = 0 Or d3dpp.FullScreen_RefreshRateInHz = m_tAdapterModes(i).RefreshRate Then
    FakeDXUIControls(m_idx(1)).ListViewObject.SelectedRow = i + 1
    Exit For
   End If
  End If
 Next i
 'fullscreen?
 FakeDXUIControls(m_idx(2)).Value = (d3dpp.Windowed = 0) And 1&
 'other
 frmMain.pGetPostProcessSettings b(0), n(0), b(1), b(2), b(3), b(4), b(5)
 FakeDXUIControls(m_idx(3)).Value = b(0) And 1&
 FakeDXUIControls(m_idx(4)).ListViewObject.SelectedRow = n(0) + 1
 For i = 1 To 5
  FakeDXUIControls(m_idx(4 + i)).Value = b(i) And 1&
 Next i
 '///over
 With FakeDXUIControls(idx)
  .RectangleEx = m_tDefaultPos
  .Show 1
 End With
End If
End Sub

'TODO:
Friend Sub Hide()
Dim idx As Long
idx = m_idx(0)
If idx > 0 Then
 With FakeDXUIControls(idx)
  .Hide
 End With
End If
End Sub

'TODO:
Friend Sub Apply()
Dim i As Long
Dim w As Long, h As Long
Dim nFull As Long
'///graphics
'resolution and fullscreen
With FakeDXUIControls(m_idx(1)).ListViewObject
 i = .SelectedRow
 If i > 0 And i <= m_nAdapterModeCount Then
  With m_tAdapterModes(i - 1)
   w = .Width
   h = .Height
   'TODO:refresh rate
  End With
 End If
End With
nFull = FakeDXUIControls(m_idx(2)).Value
If w > 0 And h > 0 Then
 FakeDXAppChangeResolution w, h, nFull
End If
'other
frmMain.pSetPostProcessSettings FakeDXUIControls(m_idx(3)).Value, FakeDXUIControls(m_idx(4)).ListViewObject.SelectedRow - 1, _
FakeDXUIControls(m_idx(5)).Value, FakeDXUIControls(m_idx(6)).Value, FakeDXUIControls(m_idx(7)).Value, _
FakeDXUIControls(m_idx(8)).Value, FakeDXUIControls(m_idx(9)).Value
'///
End Sub

Private Sub IFakeDXUIEvent_Change(ByVal obj As clsFakeDXUI)
'
End Sub

Private Sub IFakeDXUIEvent_Click(ByVal obj As clsFakeDXUI)
Select Case obj.Name
Case "cmdApply"
 Apply
Case "cmdOK"
 Apply
 Hide
Case "cmdCancel"
 Hide
End Select
End Sub

Private Sub IFakeDXUIEvent_Unload(ByVal obj As clsFakeDXUI, Cancel As Boolean)
obj.Hide
Cancel = True
End Sub
