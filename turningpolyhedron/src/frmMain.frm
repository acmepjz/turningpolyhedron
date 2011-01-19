VERSION 5.00
Begin VB.Form frmMain 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Form1"
   ClientHeight    =   7200
   ClientLeft      =   45
   ClientTop       =   435
   ClientWidth     =   9600
   BeginProperty Font 
      Name            =   "Tahoma"
      Size            =   8.25
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   KeyPreview      =   -1  'True
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   ScaleHeight     =   480
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   640
   StartUpPosition =   3  '´°¿ÚÈ±Ê¡
End
Attribute VB_Name = "frmMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

#Const UseSubclass = False

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)

Private Declare Function GetCursorPos Lib "user32.dll" (ByRef lpPoint As POINTAPI) As Long
Private Declare Function GetAsyncKeyState Lib "user32.dll" (ByVal vKey As Long) As Integer
Private Declare Function ScreenToClient Lib "user32.dll" (ByVal hwnd As Long, ByRef lpPoint As POINTAPI) As Long
Private Type POINTAPI
    x As Long
    y As Long
End Type

Private Declare Function SHGetSpecialFolderPath Lib "shell32.dll" Alias "SHGetSpecialFolderPathA" (ByVal hwnd As Long, ByVal pszPath As String, ByVal csidl As Long, ByVal fCreate As Long) As Long
Private Declare Function MakeSureDirectoryPathExists Lib "imagehlp.dll" (ByVal DirPath As String) As Long

Public m_sMyGamesPath As String

Implements IFakeDXUIEvent

'TODO:mouseleave event

Private cSub As New cSubclass

Implements iSubclass

Private Const WM_INPUTLANGCHANGE As Long = &H51
Private Const WM_IME_COMPOSITION As Long = &H10F
Private Const WM_IME_STARTCOMPOSITION As Long = &H10D
Private Const WM_IME_ENDCOMPOSITION As Long = &H10E
Private Const WM_IME_NOTIFY As Long = &H282
Private Const WM_MOUSEWHEEL As Long = &H20A

Private Function pGetFontName(ByVal s As String) As String
On Error Resume Next
Dim v As Variant, m As Long
Dim i As Long
Dim fnt As StdFont
Dim s0 As String
v = Split(s, ";")
m = UBound(v)
For i = 0 To m
 s = Trim(v(i))
 If s <> "" Then
  Set fnt = New StdFont
  s0 = fnt.Name
  If StrComp(s, s0, vbTextCompare) = 0 Then
   pGetFontName = s0
   Exit Function
  End If
  fnt.Name = s
  s = fnt.Name
  If StrComp(s, s0, vbTextCompare) Then
   pGetFontName = s
   Exit Function
  End If
 End If
Next i
End Function

Private Sub Form_DblClick()
Dim p As POINTAPI
GetCursorPos p
ScreenToClient Me.hwnd, p
Call FakeDXUIOnMouseEvent(1, 0, p.x, p.y, 4)
End Sub

Private Sub Form_KeyDown(KeyCode As Integer, Shift As Integer)
'///
If FakeDXUIOnKeyEvent(KeyCode, Shift, 1) Then Exit Sub
'///
If KeyCode = vbKeyS And Shift = vbCtrlMask Then
   '///test
   SaveRenderTargetToFile objTexture, CStr(App.Path) + "\test.bmp", D3DXIFF_BMP
   SaveRenderTargetToFile objNormalTexture, CStr(App.Path) + "\testnormal.bmp", D3DXIFF_BMP
   '///
End If
End Sub

Private Sub Form_KeyPress(KeyAscii As Integer)
'///
If FakeDXUIOnKeyEvent(KeyAscii, 0, 0) Then Exit Sub
'///
End Sub

Private Sub Form_KeyUp(KeyCode As Integer, Shift As Integer)
'///
If FakeDXUIOnKeyEvent(KeyCode, Shift, 2) Then Exit Sub
'///
End Sub

Private Sub Form_Load()
pInit
'///
objTiming.MinPeriod = 1000 / 30
FakeDXAppMainLoop
End Sub

Private Sub pInit()
On Error Resume Next
Dim i As Long
Dim s As String
'///
m_sMyGamesPath = Space(1024)
SHGetSpecialFolderPath 0, m_sMyGamesPath, 5, 1
m_sMyGamesPath = Left(m_sMyGamesPath, InStr(1, m_sMyGamesPath, vbNullChar) - 1) + "\My Games\Turning Polyhedron\"
MakeSureDirectoryPathExists m_sMyGamesPath
'///
objText.LoadFileWithLocale App.Path + "\data\locale\*.mo"
'///
Me.Show
Me.Caption = objText.GetText("Initalizing...")
'///
Set d3d9 = Direct3DCreate9(D3D_SDK_VERSION)
If d3d9 Is Nothing Then
 MsgBox objText.GetText("Can't create D3D9!!!"), vbExclamation, objText.GetText("Fatal Error")
 Form_Unload 0
 End
End If
With d3dpp
 .Windowed = 1
 .hDeviceWindow = Me.hwnd
 .SwapEffect = D3DSWAPEFFECT_DISCARD
 .BackBufferCount = 1
 .BackBufferFormat = D3DFMT_X8R8G8B8
 .BackBufferWidth = 640
 .BackBufferHeight = 480
 .EnableAutoDepthStencil = 1
 .AutoDepthStencilFormat = D3DFMT_D24S8
 '.PresentationInterval = D3DPRESENT_INTERVAL_IMMEDIATE
 .PresentationInterval = D3DPRESENT_INTERVAL_ONE
 '.MultiSampleType = D3DMULTISAMPLE_4_SAMPLES
End With
'///get device caps
d3d9.GetDeviceCaps 0, D3DDEVTYPE_HAL, d3dc9
If d3dc9.DevCaps And D3DDEVCAPS_HWTRANSFORMANDLIGHT Then i = D3DCREATE_HARDWARE_VERTEXPROCESSING _
Else i = D3DCREATE_SOFTWARE_VERTEXPROCESSING
'TODO:shader version, etc.
'///create device
Set d3dd9 = d3d9.CreateDevice(0, D3DDEVTYPE_HAL, Me.hwnd, i, d3dpp)
If d3dd9 Is Nothing Then
 MsgBox objText.GetText("Can't create device!!!"), vbExclamation, objText.GetText("Fatal Error")
 Form_Unload 0
 End
End If
'///font test
s = objText.GetText("Tahoma") 'I18N: Do NOT literally translate this string!! Please choose fonts you like in your language. example: "DejaVu Sans;Tahoma"
'///
D3DXCreateSprite d3dd9, objFontSprite
D3DXCreateFontW d3dd9, 32, 0, 0, 0, 0, 1, 0, 0, 0, pGetFontName(s), objFont
With FakeDXUIDefaultFont
 Set .objFont = objFont
 Set .objSprite = objFontSprite
End With
'CreateEffect CStr(App.Path) + "\data\shader\texteffect.txt", objFontEffect, , True
objDrawTest.Create
objRenderTest.Create
'///vertex declaration test
CreateVertexDeclaration
'///
FakeDXAppSetDefaultRenderState
'////////test
Set objTest = pLoasMeshTest
'///
pCreateUI
'///
frmSettings.Create
'///
objRenderTest.SetLightDirectionByVal 0, 4, 2.5, True 'new
objRenderTest.SetLightPosition Vec4(0, 8, 5, 0)
objRenderTest.SetLightType D3DLIGHT_DIRECTIONAL
'objRenderTest.SetLightType D3DLIGHT_POINT
'objCamera.SetCamrea Vec3(6, 2, 3), Vec3, Vec3(, , 1), True
objCamera.SetCamrea Vec3(6, 6, 1), Vec3, Vec3(, , 1), True
objCamera.AnimationEnabled = True
objCamera.LinearDamping = 0.5
'objRenderTest.CreateShadowMap 1024 'new
'objRenderTest.SetShadowState True, Atn(1), 0.1, 20   'point
'objRenderTest.SetShadowState True, 16, -100, 100  'directional
objRenderTest.SetFloatParams Vec4(0.5, 0.5, 0.5, 0.5), 30, -0.5, 0.02
objRenderTest.VolumetricFogEnabled = True
'////////new:subclass
#If UseSubclass Then
If True Then
#Else
If App.LogMode = 1 Then
#End If
 cSub.AddMsg WM_IME_NOTIFY, MSG_AFTER
 cSub.AddMsg WM_IME_COMPOSITION, MSG_AFTER
 cSub.AddMsg WM_IME_STARTCOMPOSITION, MSG_AFTER
 cSub.AddMsg WM_IME_ENDCOMPOSITION, MSG_AFTER
 cSub.AddMsg WM_INPUTLANGCHANGE, MSG_AFTER
 cSub.AddMsg WM_MOUSEWHEEL, MSG_AFTER
 cSub.Subclass Me.hwnd, Me
End If
'////////test
Dim t As D3DXIMAGE_INFO
objLand.CreateFromFile App.Path + "\heightmap_test.png", , , 0.25, , , -15 ', App.Path + "\fogmap_test.png", , 0.01, , 0.1
'objLand.CreateFromFile App.Path + "\heightmap_test.png", 3, 5, 0.05, , , -15, App.Path + "\fogmap_test.png", 3, 0.05, 2
'objLand.FogEnabled = True
D3DXCreateTextureFromFileExW d3dd9, App.Path + "\test0.png", D3DX_DEFAULT, D3DX_DEFAULT, 1, 0, D3DFMT_FROM_FILE, D3DPOOL_MANAGED, D3DX_DEFAULT, D3DX_DEFAULT, 0, t, ByVal 0, objLandTexture
'////////
Me.Caption = objText.GetText("Turning Polyhedron")
'////////
End Sub

Private Sub pCreateUI()
Dim i As Long
FakeDXUICreate 0, 0, d3dpp.BackBufferWidth, d3dpp.BackBufferHeight
With FakeDXUIControls(1)
 '///some buttons, including settings
 .AddNewChildren FakeCtl_Button, 8, -32, 80, -8, , , , , objText.GetText("Exit"), , "cmdExit", , 1, , 1, , , objText.GetText("Exit the game and return to desktop.")
 .AddNewChildren FakeCtl_Button, 208, -32, 280, -8, , , , , objText.GetText("Options"), , "cmdOptions", , 1, , 1, , , objText.GetText("Change the game settings.")
 '///
 .AddNewChildren(FakeCtl_Button, 108, -32, 180, -8, , , , , "Danger!!!", , "cmdDanger", , 1, , 1, , , "Debug").ForeColor = &HFF0000
 '///
 With .AddNewChildren(FakeCtl_Form, 40, 80, 560, 440, &HFF20FF, , False, , "Form1234°¡°¢")
  .Show
  With .AddNewChildren(FakeCtl_None, 0, 0, 800, 600)
  '///
  .AddNewChildren FakeCtl_Button, 0, 0, 78, 16, FBS_CheckBox Or FCS_CanGetFocus Or FCS_TabStop, , , , "Enabled", , "Check1", , , , , 1
  .AddNewChildren FakeCtl_Button, 0, 16, 78, 32, FBS_CheckBoxTristate Or FCS_CanGetFocus Or FCS_TabStop, , , , "Check2", , "Check2"
  .AddNewChildren FakeCtl_Button, 0, 32, 78, 48, FCS_CanGetFocus Or FCS_TabStop, , , , "Danger!!!", , "cmdDanger"
  '////////tab order debug
  .AddNewChildren FakeCtl_TextBox, 4, 52, 128, 76, &H3020000, , , , , "Single line text box blah blah blah °¡°¡°¡ blah blah"
  .AddNewChildren(FakeCtl_TextBox, 132, 52, 196, 76, &H3030004, , , , , "528").SmallChange = 1
  .AddNewChildren(FakeCtl_TextBox, 200, 52, 296, 76, &H3030000, , , , , "528").SmallChange = 0.0625
  With .AddNewChildren(FakeCtl_Frame, 120, 144, 240, 256, FCS_CanGetFocus, , , , "Form1234°¡°¢")
   .ForeColor = &HFF0000
   .ScrollBars = vbBoth
   .Min = -50
   .Max = 50
   .LargeChange = 10
   .Min(1) = -50
   .Max(1) = 50
   .LargeChange(1) = 10
   .AddNewChildren FakeCtl_Button, 0, 0, 64, 16, FBS_CheckBox Or FCS_CanGetFocus Or FCS_TabStop, , , , "Enabled", , "Check1", , , , , 1
   .AddNewChildren FakeCtl_Button, 0, 16, 64, 32, FBS_CheckBoxTristate Or FCS_CanGetFocus Or FCS_TabStop, , , , "Check2", , "Check2"
   .AddNewChildren FakeCtl_Button, 0, 32, 64, 48, FCS_CanGetFocus Or FCS_TabStop, , , , "Danger!!!", , "cmdDanger"
  End With
  .AddNewChildren FakeCtl_Button, 82, 0, 160, 16, FBS_CheckBox Or FCS_CanGetFocus Or FCS_TabStop, , , , "Enabled", , "Check1", , , , , 1
  .AddNewChildren FakeCtl_Button, 82, 16, 160, 32, FBS_CheckBoxTristate Or FCS_CanGetFocus Or FCS_TabStop, , , , "Check2", , "Check2"
  .AddNewChildren FakeCtl_Button, 82, 32, 160, 48, FCS_CanGetFocus Or FCS_TabStop, , , , "Danger!!!", , "cmdDanger"
  With .AddNewChildren(FakeCtl_Frame, 240, 144, 360, 256, FCS_CanGetFocus Or FCS_AutoScroll, , , , "Form5678°¡°¢")
   With .AddNewChildren(FakeCtl_None, 0, 0, 320, 240)
    .AddNewChildren FakeCtl_Button, 0, 0, 64, 16, FBS_CheckBox Or FCS_CanGetFocus Or FCS_TabStop, , , , "Enabled", , "Check1", , , , , 1
    .AddNewChildren FakeCtl_Button, 0, 16, 64, 32, FBS_CheckBoxTristate Or FCS_CanGetFocus Or FCS_TabStop, , , , "Check2", , "Check2"
    .AddNewChildren FakeCtl_Button, 0, 32, 64, 48, FCS_CanGetFocus Or FCS_TabStop, , , , "Danger!!!", , "cmdDanger"
   End With
  End With
  With .AddNewChildren(FakeCtl_PictureBox, 360, 144, 480, 256, FCS_CanGetFocus Or FCS_AutoScroll)
   With .AddNewChildren(FakeCtl_None, 0, 0, 320, 240)
    .AddNewChildren FakeCtl_Button, 0, 0, 64, 16, FBS_CheckBox Or FCS_CanGetFocus Or FCS_TabStop, , , , "Enabled", , "Check1", , , , , 1
    .AddNewChildren FakeCtl_Button, 0, 16, 64, 32, FBS_CheckBoxTristate Or FCS_CanGetFocus Or FCS_TabStop, , , , "Check2", , "Check2"
    .AddNewChildren FakeCtl_Button, 200, 200, 320, 240, FCS_CanGetFocus Or FCS_TabStop, , , , "Danger!!!", , "cmdDanger"
   End With
  End With
  '////////tabstrip test
  With .AddNewChildren(FakeCtl_TabStrip, 8, 260, -8, -8, &H3003000, , , , , , , , , 1, 1)
   .ScrollBars = vbBoth
   .Max(0) = 2048
   .Max(1) = 2048
   With .TabObject
    .ShowCloseButtonOnTab = True
    For i = 1 To 10
     .AddTab "LKSCT TEST " + CStr(i) + " ONLY", , i And 1&, , True
    Next i
   End With
   For i = 1 To 10
    .AddNewChildren FakeCtl_Button, 0, 0, 128 * i, 64 * i, , , False, , "TEST" + CStr(i), , , , , , , , , "This is test " + CStr(i)
   Next i
  End With
  '////////
  With .AddNewChildren(FakeCtl_ComboBox, 4, 88, 256, 108, &H3000018, , , , , "Dropdown CheckListBox")
   .ComboBoxDropdownHeight = 16
   With .ListViewObject
     .FullRowSelect = True
     .ColumnHeader = True
     .GridLines = True
     .AddColumn "A", , efctCheck, , 16
     .AddColumn "B", , efctCheck3State, , 16
     .AddColumn "he1", , , efcfSizable Or efcfSortable, 48
     .AddColumn "he2", , , efcfSizable Or efcfSortable Or efcfAlignCenter, 64
     .AddColumn "he3", , , efcfSizable Or efcfSortable Or efcfAlignRight, 80
     For i = 1 To 1000
      .AddItem "", , , Array(, CStr(i), CStr(i * i), CStr(i * i * i))
     Next i
   End With
  End With
  With .AddNewChildren(FakeCtl_ComboBox, 4, 112, 256, 132, &H3000000, , , , , "HEHE")
   With .ListViewObject
     .FullRowSelect = True
     .ColumnHeader = False
     .AddColumn "he1", , , efcfSizable Or efcfSortable, 48
     .AddColumn "he2", , , efcfSizable Or efcfSortable Or efcfAlignCenter, 64
     .AddColumn "he3", , , efcfSizable Or efcfSortable Or efcfAlignRight
     For i = 1 To 1000
      .AddItem CStr(i), , , Array(CStr(i * i), CStr(i * i * i))
     Next i
   End With
  End With
  With .AddNewChildren(FakeCtl_ComboBox, 4, 136, 256, 156, &H3000001, , , , , "HEHE 2")
   With .ListViewObject
     .FullRowSelect = True
     .ColumnHeader = False
     .AddColumn "he1", , , efcfSizable Or efcfSortable, 48
     .AddColumn "he2", , , efcfSizable Or efcfSortable Or efcfAlignCenter, 64
     .AddColumn "he3", , , efcfSizable Or efcfSortable Or efcfAlignRight
     For i = 1 To 1000
      .AddItem CStr(i), , , Array(CStr(i * i), CStr(i * i * i))
     Next i
   End With
  End With
  '///
  End With
 End With
 #If 0 Then
 With .AddNewChildren(FakeCtl_Form, 160, 120, 600, 400, &HFF00FF, , False, , "É½Õ¯MDIForm1")
  .ScrollBars = vbBoth
  .Min = -50
  .Max = 50
  .LargeChange = 10
  .Min(1) = -50
  .Max(1) = 50
  .LargeChange(1) = 10
  '///
  .AddNewChildren FakeCtl_Label, 8, 8, 128, 32, , , , , , , "Label1"
  .Show 1
  With .AddNewChildren(FakeCtl_Form, 0, 0, 320, 240, _
  3& Or FFS_TitleBar Or FFS_CloseButton Or FFS_MaxButton Or FFS_MinButton, , False, , "Form2")
   With .AddNewChildren(FakeCtl_TextBox, 0, 0, 0, 0, &H3000000, , , , , _
   Replace(Space(100), " ", "Text2 blah blah blah °¡°¡°¡°¡°¡°¡°¢°¡°¡°¡°¡°¡°¡°¡°¡°¡°¡°¡°¡ blah blah blah" + vbCrLf), , , , 0.5, 1)
    .ScrollBars = vbVertical
    .MultiLine = True
   End With
   With .AddNewChildren(FakeCtl_ListView, 0, 0, 0, 0, &H3000000, , , , , , , 0.5, , 1, 1)
    With .ListViewObject
     .FullRowSelect = True
     .ColumnHeader = True
     .GridLines = True
     .AddColumn "he1", , , efcfSizable Or efcfSortable, 48
     .AddColumn "he2", , , efcfSizable Or efcfSortable Or efcfAlignCenter, 48
     .AddColumn "he3", , , efcfSizable Or efcfSortable Or efcfAlignRight, 48
     .AddColumn "A", , efctCheck, , 16
     .AddColumn "B", , efctCheck3State, , 16
     For i = 1 To 1000
      .AddItem CStr(i), , , Array(CStr(i * i), CStr(i * i * i))
     Next i
    End With
   End With
   .Show 1
  End With
 End With
 With .AddNewChildren(FakeCtl_Form, 200, 280, 360, 340, 2& Or FCS_TopMost, , False, , , , "frmTopmost")
  .AddNewChildren FakeCtl_Label, 0, 0, 160, 96, , , , , "This is a topmost form." + vbCrLf + "Label1" + vbCrLf + "xxx"
  .AddNewChildren FakeCtl_Button, 80, 28, 140, 48, FBS_Default Or FBS_Cancel Or FCS_CanGetFocus, , , , "Close", , "cmdClose"
  .Show 1
 End With
 #End If
End With
'///
Set FakeDXUIEvent = Me
End Sub

Private Sub Form_MouseDown(Button As Integer, Shift As Integer, x As Single, y As Single)
'///
If FakeDXUIOnMouseEvent(Button, Shift, x, y, 1) Then Exit Sub
'///
Select Case Button
Case 1, 2
 objCamera.LockCamera = Button = 2
 objCamera.BeginDrag x, y
 FakeDXUISetCapture = -1
End Select
End Sub

Private Sub Form_MouseMove(Button As Integer, Shift As Integer, x As Single, y As Single)
'///
If FakeDXUIOnMouseEvent(Button, Shift, x, y, 0) Then Exit Sub
'///
Select Case Button
Case 1, 2
 objCamera.Drag x, y, 0.01
End Select
End Sub

Private Sub Form_MouseUp(Button As Integer, Shift As Integer, x As Single, y As Single)
'///
If FakeDXUIOnMouseEvent(Button, Shift, x, y, 2) Then Exit Sub
'///
FakeDXUISetCapture = 0
End Sub

Private Sub Form_QueryUnload(Cancel As Integer, UnloadMode As Integer)
cSub.UnSubclass
End Sub

Private Sub Form_Unload(Cancel As Integer)
pDestroy
End Sub

Friend Sub pDestroy()
FakeDXUIDestroy
Set objLand = Nothing
Set objLandTexture = Nothing
Set objDrawTest = Nothing
Set objTest = Nothing
Set objTexture = Nothing
Set objNormalTexture = Nothing
Set d3dd9 = Nothing
Set d3d9 = Nothing
End Sub

Private Function pLoasMeshTest() As D3DXMesh
Dim obj As D3DXMesh
Dim objAdjacency As D3DXBuffer
Dim i As Long, j As Long, lp As Long
Dim tDesc As D3DVERTEXBUFFER_DESC
'////////
'bug in x file loader: you must write "1.000" instead of "1" or it'll buggy :-3
D3DXLoadMeshFromXW CStr(App.Path) + "\media\cube1_2.x", D3DXMESH_MANAGED, d3dd9, objAdjacency, Nothing, Nothing, 0, obj
'D3DXLoadMeshFromXW CStr(App.Path) + "\media\test.x", 0, d3dd9, objAdjacency, Nothing, Nothing, 0, obj
Set obj = obj.CloneMesh(D3DXMESH_MANAGED, m_tDefVertexDecl(0), d3dd9)
'///recalculate normal
D3DXComputeTangentFrame obj, D3DXTANGENT_CALCULATE_NORMALS
'//poly20-can smooth, monkey can't :-3 cube1-1 can't either ---why?
'D3DXComputeTangentFrameEx obj, D3DDECLUSAGE_TEXCOORD, 0, D3DDECLUSAGE_BINORMAL, 0, D3DDECLUSAGE_TANGENT, 0, D3DDECLUSAGE_NORMAL, 0, _
'D3DXTANGENT_GENERATE_IN_PLACE Or D3DXTANGENT_CALCULATE_NORMALS, ByVal objAdjacency.GetBufferPointer, 0.01, 0.25, 0.01, Nothing, Nothing
'///set color
obj.LockVertexBuffer 0, lp
obj.GetVertexBuffer.GetDesc tDesc
For i = 48 To tDesc.Size - 1 Step 64
 CopyMemory ByVal lp + i, &HFFFFFFFF, 4& 'ambient
 CopyMemory ByVal lp + i + 4, &HFFFFFFCC, 4& 'specular
Next i
obj.UnlockVertexBuffer
'///
Set pLoasMeshTest = obj
End Function

Private Sub IFakeDXUIEvent_Change(ByVal obj As clsFakeDXUI)
Dim i As Long
i = FakeDXUIFindControl("Label1")
If i Then FakeDXUIControls(i).Caption = CStr(obj.Value) + "," + CStr(obj.Value(1))
End Sub

Private Sub IFakeDXUIEvent_Click(ByVal obj As clsFakeDXUI)
Dim i As Long
Select Case obj.Name
Case "cmdClose"
 i = FakeDXUIFindControl("frmTopmost")
 If i Then FakeDXUIControls(i).Unload
Case "cmdExit"
 With New clsFakeDXUIMsgBox
  If .MsgBox(objText.GetText("Are you sure?"), vbYesNo, objText.GetText("Exit game")) = vbYes Then Unload Me
 End With
Case "cmdDanger"
 With New clsFakeDXUIMsgBox
  For i = 1 To 9
   .AddButton , vbOK
  Next i
  .MsgBox CStr(.MsgBox("HAHA", 15)), 15
  .MsgBox , 15
 End With
 frmSettings.Show
' Randomize Timer
' For i = 1 To 1
'  With FakeDXUIControls(1).AddNewChildren(FakeCtl_Form, 160 + 160 * Rnd, 120 + 120 * Rnd, 480 + 160 * Rnd, 360 + 120 * Rnd, &HFFFFFF, , , , CStr(Rnd))
'   .AddNewChildren FakeCtl_Button, 16, 32, 80, 48, , , , , "Danger!!!", , "cmdDanger"
'  End With
' Next i
Case "Check1"
 i = FakeDXUIFindControl("Check2")
 If i Then FakeDXUIControls(i).Enabled = obj.Value
 i = FakeDXUIFindControl("cmdClose")
 If i Then FakeDXUIControls(i).Enabled = obj.Value
Case "cmdOptions"
 frmSettings.Show
End Select
End Sub

Private Sub IFakeDXUIEvent_Unload(ByVal obj As clsFakeDXUI, Cancel As Boolean)
'
End Sub

Private Sub iSubclass_After(lReturn As Long, ByVal hwnd As Long, ByVal uMsg As Long, ByVal wParam As Long, ByVal lParam As Long)
Dim i As Long
Dim p As POINTAPI
Select Case uMsg
Case WM_IME_NOTIFY
 FakeDXUI_IME.OnIMENotify wParam, lParam
Case WM_IME_COMPOSITION, WM_IME_STARTCOMPOSITION, WM_IME_ENDCOMPOSITION
 FakeDXUI_IME.OnIMEComposition wParam, lParam
Case WM_INPUTLANGCHANGE
 FakeDXUI_IME.OnInputLanguageChange
Case WM_MOUSEWHEEL
 i = (wParam And &HFFFF0000) \ &H10000
' p.x = (lParam And &H7FFF&) Or (&HFFFF8000 And ((lParam And &H8000&) <> 0))
' p.y = (lParam And &HFFFF0000) \ &H10000
 GetCursorPos p
 ScreenToClient Me.hwnd, p
 OnMouseWheel (wParam And 3&) Or (vbMiddleButton And ((wParam And &H10&) <> 0)), _
 ((wParam And &HC&) \ 4&) Or (vbAltMask And ((GetAsyncKeyState(vbKeyMenu) And &H8000&) <> 0)), p.x, p.y, i \ 120&
End Select
End Sub

Private Sub iSubclass_Before(bHandled As Boolean, lReturn As Long, hwnd As Long, uMsg As Long, wParam As Long, lParam As Long)
'
End Sub

Friend Sub OnMouseWheel(ByVal Button As MouseButtonConstants, ByVal Shift As ShiftConstants, ByVal x As Long, ByVal y As Long, ByVal nDelta As Long)
If FakeDXUIOnMouseWheel(nDelta, Shift) Then Exit Sub
'etc.
If nDelta > 0 Then
 objCamera.Zoom 0.8
Else
 objCamera.Zoom 1.25
End If
End Sub

