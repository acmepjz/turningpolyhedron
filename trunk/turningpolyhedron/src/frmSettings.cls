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

'dirty workaround for show in center of screen. TODO:
Private m_tDefaultPos As typeFakeDXUIRectEx

'control index
Private m_idx(127) As Long

Private Enum enumSettingsDialogControls
 IDC_Main = 0
 IDC_Resolution
 IDC_Fullscreen
 IDC_PostProcess
 IDC_HDRBlurQuality
 IDC_ShadowMap
 IDC_Fog
 IDC_VolumetricFog
 IDC_DepthOfField
 IDC_RadialBlur
 IDC_
End Enum

'config file name
Private m_sFileName As String

Implements IFakeDXUIEvent

Friend Property Get FileName() As String
FileName = m_sFileName
End Property

Friend Property Let FileName(ByVal s As String)
m_sFileName = s
End Property

'TODO:other
Friend Sub LoadFile()
On Error Resume Next
Dim b As Boolean
Dim obj As New clsTreeStorageNode
'///
With New clsXMLSerializer
 .LoadNodeFromFile m_sFileName, obj
End With
'///
With obj.GetSubNodeObjectByName("GraphicsConfig", True)
 d3dpp.BackBufferWidth = Val(.GetSubNodeValueAsStringByName("Width", 640))
 d3dpp.BackBufferHeight = Val(.GetSubNodeValueAsStringByName("Height", 480))
 d3dpp.FullScreen_RefreshRateInHz = Val(.GetSubNodeValueAsStringByName("RefreshRate", 0))
 '///
 b = False
 b = CBool(.GetSubNodeValueAsStringByName("Fullscreen", False))
 d3dpp.Windowed = (b And 1&) Xor 1&
 '///
 objRenderTest.PostProcessEnabled = CBool(.GetSubNodeValueAsStringByName("PostProcessEnabled", False))
 objRenderTest.HDRBlurQuality = Val(.GetSubNodeValueAsStringByName("HDRBlurQuality", 0))
 objRenderTest.VolumetricFogEnabled = CBool(.GetSubNodeValueAsStringByName("VolumetricFogEnabled", False))
 objRenderTest.DepthOfFiendEnabled = CBool(.GetSubNodeValueAsStringByName("DepthOfFieldEnabled", False))
 objRenderTest.RadialBlurEnabled = CBool(.GetSubNodeValueAsStringByName("RadialBlurEnabled", False))
End With
'///
End Sub

'TODO:other
Friend Sub SaveFile()
Dim obj As New clsTreeStorageNode
'///
obj.SetNameFromString "Config"
With obj.GetSubNodeObjectByName("GraphicsConfig", True)
 .AddSubNode , , "Width", CStr(d3dpp.BackBufferWidth)
 .AddSubNode , , "Height", CStr(d3dpp.BackBufferHeight)
 .AddSubNode , , "RefreshRate", CStr(d3dpp.FullScreen_RefreshRateInHz)
 .AddSubNode , , "Fullscreen", CStr(d3dpp.Windowed = 0)
 '///
 .AddSubNode , , "PostProcessEnabled", CStr(objRenderTest.PostProcessEnabled)
 .AddSubNode , , "HDRBlurQuality", CStr(objRenderTest.HDRBlurQuality)
 .AddSubNode , , "ShadowMapEnabled", False 'TODO:
 .AddSubNode , , "FogEnabled", True 'TODO:
 .AddSubNode , , "VolumetricFogEnabled", CStr(objRenderTest.VolumetricFogEnabled)
 .AddSubNode , , "DepthOfFieldEnabled", CStr(objRenderTest.DepthOfFiendEnabled)
 .AddSubNode , , "RadialBlurEnabled", CStr(objRenderTest.RadialBlurEnabled)
End With
'///
With New clsXMLSerializer
 .SaveNodeToFile m_sFileName, obj
End With
End Sub

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
If m_idx(0) Then Exit Sub
'///
GetAdapterModes
'///
'TODO:
'///
With FakeDXUIControls(1).AddNewChildren(FakeCtl_Form, -200, -200, _
200, 200, FFS_CloseButton Or FFS_Moveable Or FFS_TitleBar, , False, , objText.GetText("Options"), , , 0.5, 0.5, 0.5, 0.5)
 Set .EventObject = Me
 m_idx(IDC_Main) = .Index
 m_tDefaultPos = .RectangleEx
 '///tab control
 With .AddNewChildren(FakeCtl_TabStrip, 8, 8, -8, -40, &H3003000, , , , , , , , , 1, 1)
  '///graphics
  With .AddNewChildren(FakeCtl_None, 0, 0, 320, 320, , , False)
   'resolution
   .AddNewChildren FakeCtl_Label, 10, 10, 198, 28, FCS_CanGetFocus Or FCS_TabStop, , , , objText.GetText("Resolution")
   With .AddNewChildren(FakeCtl_ComboBox, 100, 10, 298, 28, , , , , , , , , , , , , , objText.GetText("Change the screen resolution."))
    m_idx(IDC_Resolution) = .Index
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
    m_idx(IDC_ShadowMap) = .Index
   End With
   'post process?
   With .AddNewChildren(FakeCtl_Button, 10, 90, 198, 108, FBS_CheckBox, , , , _
   objText.GetText("Post process"), , , , , , , , , objText.GetText("Enables post process effects."))
    m_idx(IDC_PostProcess) = .Index
   End With
   'HDR blur quality
   .AddNewChildren FakeCtl_Label, 20, 110, 198, 128, FCS_CanGetFocus Or FCS_TabStop, , , , objText.GetText("HDR quality")
   With .AddNewChildren(FakeCtl_ComboBox, 100, 110, 298, 128, , , , , , , , , , , , , , objText.GetText("Set the quality of HDR blur."))
    m_idx(IDC_HDRBlurQuality) = .Index
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
    m_idx(IDC_Fog) = .Index
   End With
   'volumetric fog?
   With .AddNewChildren(FakeCtl_Button, 30, 150, 198, 168, FBS_CheckBox, , , , _
   objText.GetText("Volumetric fog"), , , , , , , , , objText.GetText("Enables volumetric fog effect."))
    m_idx(IDC_VolumetricFog) = .Index
   End With
   'DOF?
   With .AddNewChildren(FakeCtl_Button, 20, 170, 198, 188, FBS_CheckBox, , , , _
   objText.GetText("Depth of field"), , , , , , , , , objText.GetText("Enables depth of field effect."))
    m_idx(IDC_DepthOfField) = .Index
   End With
   'radial blur?
   With .AddNewChildren(FakeCtl_Button, 20, 190, 198, 208, FBS_CheckBox, , , , _
   objText.GetText("Radial blur"), , , , , , , , , objText.GetText("Enables radial blur effect."))
    m_idx(IDC_RadialBlur) = .Index
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

'TODO:read other settings
Friend Sub Show()
Dim idx As Long
Dim i As Long
'///
Create
'///
idx = m_idx(0)
If idx = 0 Then Exit Sub
'///graphics
'screen resolution
For i = 0 To m_nAdapterModeCount - 1
 If d3dpp.BackBufferWidth = m_tAdapterModes(i).Width And d3dpp.BackBufferHeight = m_tAdapterModes(i).Height Then
  If d3dpp.FullScreen_RefreshRateInHz = 0 Or d3dpp.FullScreen_RefreshRateInHz = m_tAdapterModes(i).RefreshRate Then
   FakeDXUIControls(m_idx(IDC_Resolution)).ListViewObject.SelectedRow = i + 1
   Exit For
  End If
 End If
Next i
'fullscreen?
FakeDXUIControls(m_idx(IDC_Fullscreen)).Value = (d3dpp.Windowed = 0) And 1&
'other
FakeDXUIControls(m_idx(IDC_PostProcess)).Value = objRenderTest.PostProcessEnabled And 1&
FakeDXUIControls(m_idx(IDC_HDRBlurQuality)).ListViewObject.SelectedRow = objRenderTest.HDRBlurQuality + 1
'///
FakeDXUIControls(m_idx(IDC_ShadowMap)).Value = 0 'TODO:
FakeDXUIControls(m_idx(IDC_Fog)).Value = 1 'TODO:
FakeDXUIControls(m_idx(IDC_VolumetricFog)).Value = objRenderTest.VolumetricFogEnabled And 1&
FakeDXUIControls(m_idx(IDC_DepthOfField)).Value = objRenderTest.DepthOfFiendEnabled And 1&
FakeDXUIControls(m_idx(IDC_RadialBlur)).Value = objRenderTest.RadialBlurEnabled And 1&
'///over
With FakeDXUIControls(idx)
 .RectangleEx = m_tDefaultPos 'dirty code:centering window
 .Show 1
End With
End Sub

'TODO:
Friend Sub Hide()
Dim idx As Long
idx = m_idx(0)
If idx = 0 Then Exit Sub
'///
With FakeDXUIControls(idx)
 .Hide
End With
End Sub

'TODO:
Friend Sub Apply()
Dim i As Long
Dim w As Long, h As Long
Dim nFull As Long
'///
If m_idx(0) = 0 Then Exit Sub
'///graphics
'resolution and fullscreen
With FakeDXUIControls(m_idx(IDC_Resolution)).ListViewObject
 i = .SelectedRow
 If i > 0 And i <= m_nAdapterModeCount Then
  With m_tAdapterModes(i - 1)
   w = .Width
   h = .Height
   'TODO:refresh rate
  End With
 End If
End With
nFull = FakeDXUIControls(m_idx(IDC_Fullscreen)).Value
If w > 0 And h > 0 Then
 FakeDXAppChangeResolution w, h, nFull
End If
'///other
objRenderTest.PostProcessEnabled = FakeDXUIControls(m_idx(IDC_PostProcess)).Value
objRenderTest.HDRBlurQuality = FakeDXUIControls(m_idx(IDC_HDRBlurQuality)).ListViewObject.SelectedRow - 1
objRenderTest.VolumetricFogEnabled = FakeDXUIControls(m_idx(IDC_VolumetricFog)).Value
objRenderTest.DepthOfFiendEnabled = FakeDXUIControls(m_idx(IDC_DepthOfField)).Value
objRenderTest.RadialBlurEnabled = FakeDXUIControls(m_idx(IDC_RadialBlur)).Value
End Sub

Private Sub IFakeDXUIEvent_Change(ByVal obj As clsFakeDXUI)
'
End Sub

Private Sub IFakeDXUIEvent_Click(ByVal obj As clsFakeDXUI)
Select Case obj.Name
Case "cmdApply"
 Apply
 SaveFile
Case "cmdOK"
 Apply
 SaveFile
 Hide
Case "cmdCancel"
 Hide
End Select
End Sub

Private Sub IFakeDXUIEvent_Unload(ByVal obj As clsFakeDXUI, Cancel As Boolean)
obj.Hide
Cancel = True
End Sub
