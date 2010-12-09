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
Private m_tAdapterModes() As D3DDISPLAYMODE

Private m_sFileName As String

Private m_tDefaultPos As typeFakeDXUIRectEx
Private m_idx(31) As Long

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
 m_idx(0) = .Index
 m_tDefaultPos = .RectangleEx
 '///
 .AddNewChildren FakeCtl_Label, 10, 10, 198, 28, FCS_CanGetFocus Or FCS_TabStop, , , , objText.GetText("Resolution")
 With .AddNewChildren(FakeCtl_ComboBox, 100, 10, 198, 28, , , , , , , , , , , , , , objText.GetText("Change the screen resolution."))
  m_idx(1) = .Index
  With .ListViewObject
   .FullRowSelect = True
   .AddColumn ""
   For i = 0 To m_nAdapterModeCount - 1
    .AddItem CStr(m_tAdapterModes(i).Width) + "x" + CStr(m_tAdapterModes(i).Height)
   Next i
  End With
 End With
 '///
 With .AddNewChildren(FakeCtl_Button, 10, 30, 198, 50, FBS_CheckBox, , , , _
 objText.GetText("Fullscreen"), , , , , , , , , objText.GetText("Determines whether the program should run in full screen mode."))
  m_idx(2) = .Index
 End With
End With
'///
'TODO:
End Sub

'TODO:
Friend Sub Show()
Dim idx As Long
idx = m_idx(0)
If idx > 0 Then
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
