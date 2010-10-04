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
Private Declare Sub Sleep Lib "kernel32.dll" (ByVal dwMilliseconds As Long)

Private Declare Function GetCursorPos Lib "user32.dll" (ByRef lpPoint As POINTAPI) As Long
Private Declare Function GetAsyncKeyState Lib "user32.dll" (ByVal vKey As Long) As Integer
Private Declare Function ScreenToClient Lib "user32.dll" (ByVal hwnd As Long, ByRef lpPoint As POINTAPI) As Long
Private Type POINTAPI
    x As Long
    y As Long
End Type
Private Declare Function GetWindowLong Lib "user32.dll" Alias "GetWindowLongA" (ByVal hwnd As Long, ByVal nIndex As Long) As Long
Private Declare Function SetWindowLong Lib "user32.dll" Alias "SetWindowLongA" (ByVal hwnd As Long, ByVal nIndex As Long, ByVal dwNewLong As Long) As Long
Private Declare Function SetWindowPos Lib "user32.dll" (ByVal hwnd As Long, ByVal hWndInsertAfter As Long, ByVal x As Long, ByVal y As Long, ByVal cx As Long, ByVal cy As Long, ByVal wFlags As Long) As Long
Private Const SWP_NOMOVE As Long = &H2
Private Const SWP_NOZORDER As Long = &H4
Private Const SWP_NOACTIVATE As Long = &H10
Private Const GWL_STYLE As Long = -16
Private Const GWL_EXSTYLE As Long = -20
Private Declare Function AdjustWindowRectEx Lib "user32.dll" (ByRef lpRect As RECT, ByVal dwStyle As Long, ByVal bMenu As Long, ByVal dwExStyle As Long) As Long
Private Type RECT
    Left As Long
    Top As Long
    Right As Long
    Bottom As Long
End Type
Private Declare Function GetActiveWindow Lib "user32.dll" () As Long

Private Declare Function SHGetSpecialFolderPath Lib "shell32.dll" Alias "SHGetSpecialFolderPathA" (ByVal hwnd As Long, ByVal pszPath As String, ByVal csidl As Long, ByVal fCreate As Long) As Long
Private Declare Function MakeSureDirectoryPathExists Lib "imagehlp.dll" (ByVal DirPath As String) As Long

Public m_sMyGamesPath As String

Implements IFakeDXUIEvent

'TODO:mouseleave event

Private objTest As D3DXMesh
Private objDrawTest As New clsRenderTexture, objRenderTest As New clsRenderPipeline
Private objLand As New clsRenderLandscape, objLandTexture As Direct3DTexture9

Private objTexture As Direct3DTexture9, objNormalTexture As Direct3DTexture9

'///test
Private objFontSprite As D3DXSprite
Private objFont As D3DXFont
'///

Private objTiming As New clsTiming
Private objCamera As New clsCamera

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
pMainLoop
End Sub

Private Sub pMainLoop()
objTiming.MinPeriod = 1000 / 30
Do Until d3dd9 Is Nothing
 '///process key event
 pKeyEvent
 '///
 objTiming.WaitForNextFrame
 Timer1_Timer
 DoEvents
Loop
End Sub

Private Sub pKeyEvent()
Dim dx As Single, dz As Single
If GetActiveWindow = Me.hwnd And FakeDXUIActiveWindow = 0 Then
 If GetAsyncKeyState(vbKeyA) And &H8000& Then
  dx = -0.1
 ElseIf GetAsyncKeyState(vbKeyD) And &H8000& Then
  dx = 0.1
 End If
 If GetAsyncKeyState(vbKeyS) And &H8000& Then
  dz = -0.1
 ElseIf GetAsyncKeyState(vbKeyW) And &H8000& Then
  dz = 0.1
 End If
 If dx <> 0 Or dz <> 0 Then objCamera.MoveByLocalCoordinatesLH dx, 0, dz
End If
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
 .hDeviceWindow = Me.hwnd
 .SwapEffect = D3DSWAPEFFECT_DISCARD
 .BackBufferCount = 1
 .BackBufferFormat = D3DFMT_X8R8G8B8
 .BackBufferWidth = 640
 .BackBufferHeight = 480
 .Windowed = 1
 .hDeviceWindow = Me.hwnd
 .EnableAutoDepthStencil = 1
 .AutoDepthStencilFormat = D3DFMT_D24S8
 '.PresentationInterval = D3DPRESENT_INTERVAL_IMMEDIATE
 .PresentationInterval = D3DPRESENT_INTERVAL_ONE 'D3DPRESENT_INTERVAL_TWO 'Fullscreen only
 '.MultiSampleType = D3DMULTISAMPLE_4_SAMPLES
End With
'create device
Set d3dd9 = d3d9.CreateDevice(0, D3DDEVTYPE_HAL, Me.hwnd, D3DCREATE_HARDWARE_VERTEXPROCESSING, d3dpp)
If d3dd9 Is Nothing Then
 MsgBox objText.GetText("Can't create device!!!"), vbExclamation, objText.GetText("Fatal Error")
 Form_Unload 0
 End
End If
'///font test
s = objText.GetText("DejaVu Sans;Tahoma") 'I18N: Do NOT literally translate this string!! Please choose fonts you like in your language.
'///
D3DXCreateSprite d3dd9, objFontSprite
D3DXCreateFontW d3dd9, 32, 0, 0, 0, 0, 1, 0, 0, 0, pGetFontName(s), objFont
With FakeDXUIDefaultFont
 Set .objFont = objFont
 Set .objSprite = objFontSprite
End With
'CreateEffect CStr(App.Path) + "\data\shader\texteffect.txt", objFontEffect, , True
'///vertex declaration test
CreateVertexDeclaration
'///
pSetRenderState
'////////test
objDrawTest.Create
Set objTest = pTest
'///
pCreateUI
'///
objRenderTest.Create
objRenderTest.SetLightDirectionByVal 0, 4, 2.5, True 'new
objRenderTest.SetLightPosition Vec4(0, 8, 5, 0)
'objRenderTest.SetLightType D3DLIGHT_DIRECTIONAL
objRenderTest.SetLightType D3DLIGHT_POINT
objCamera.SetCamrea Vec3(6, 2, 3), Vec3, Vec3(, , 1)
'objCamera.SetCamrea Vec3(1, 0, 8), Vec3, Vec3(, , 1)
objRenderTest.CreateShadowMap 1024 'new
'objRenderTest.SetShadowState True, Atn(1), 0.1, 20   'point
objRenderTest.SetShadowState True, 16, -100, 100  'directional
objRenderTest.SetFloatParams Vec4(0.5, 0.5, 0.5, 0.5), 30, -0.5, 0.02
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
objLand.CreateFromFile App.Path + "\heightmap_test.png", , , 0.25, , -15
D3DXCreateTextureFromFileExW d3dd9, App.Path + "\test0.png", D3DX_DEFAULT, D3DX_DEFAULT, 1, 0, D3DFMT_FROM_FILE, D3DPOOL_MANAGED, D3DX_DEFAULT, D3DX_DEFAULT, 0, t, ByVal 0, objLandTexture
'////////
Me.Caption = objText.GetText("Turning Polyhedron")
'////////
End Sub

Private Sub pCreateUI()
Dim i As Long
FakeDXUICreate 0, 0, d3dpp.BackBufferWidth, d3dpp.BackBufferHeight
With FakeDXUIControls(1)
 .AddNewChildren FakeCtl_Button, 8, -24, 80, -8, FCS_CanGetFocus, , , , "Exit", , "cmdExit", , 1, , 1
 .AddNewChildren FakeCtl_Button, 8, -48, 80, -32, FBS_CheckBox Or FBS_Graphical Or FCS_CanGetFocus, , , , "Fullscreen", , "chkFullscreen", , 1, , 1
 With .AddNewChildren(FakeCtl_Form, 40, 80, 560, 440, &HFFFFFF, , , , "Form1234°¡°¢")
  .AddNewChildren FakeCtl_Button, 0, 0, 78, 16, FBS_CheckBox Or FCS_CanGetFocus Or FCS_TabStop, , , , "Enabled", , "Check1", , , , , 1
  .AddNewChildren FakeCtl_Button, 0, 16, 78, 32, FBS_CheckBoxTristate Or FCS_CanGetFocus Or FCS_TabStop, , , , "Check2", , "Check2"
  .AddNewChildren FakeCtl_Button, 0, 32, 78, 48, FCS_CanGetFocus Or FCS_TabStop, , , , "Danger!!!", , "cmdDanger"
  '////////tab debug
  .AddNewChildren FakeCtl_TextBox, 4, 52, 128, 80, &H3000000, , , , , "Single line text box blah blah blah °¡°¡°¡ blah blah"
  With .AddNewChildren(FakeCtl_Frame, 120, 80, 240, 200, FCS_CanGetFocus, , , , "Form1234°¡°¢")
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
  With .AddNewChildren(FakeCtl_Frame, 240, 80, 360, 200, , , , , "Form1234°¡°¢")
   .Enabled = False
   .AddNewChildren FakeCtl_Button, 0, 0, 64, 16, FBS_CheckBox Or FCS_CanGetFocus Or FCS_TabStop, , , , "Enabled", , "Check1", , , , , 1
   .AddNewChildren FakeCtl_Button, 0, 16, 64, 32, FBS_CheckBoxTristate Or FCS_CanGetFocus Or FCS_TabStop, , , , "Check2", , "Check2"
   .AddNewChildren FakeCtl_Button, 0, 32, 64, 48, FCS_CanGetFocus Or FCS_TabStop, , , , "Danger!!!", , "cmdDanger"
  End With
  With .AddNewChildren(FakeCtl_PictureBox, 360, 80, 480, 200, FCS_CanGetFocus)
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
  '////////
 End With
 With .AddNewChildren(FakeCtl_Form, 160, 120, 600, 400, &HFFFFFF, , , , "É½Õ¯MDIForm1")
  .ScrollBars = vbBoth
  .Min = -50
  .Max = 50
  .LargeChange = 10
  .Min(1) = -50
  .Max(1) = 50
  .LargeChange(1) = 10
  '///
  .AddNewChildren FakeCtl_Label, 8, 8, 128, 32, , , , , , , "Label1"
  With .AddNewChildren(FakeCtl_Form, 0, 0, 320, 240, _
  3& Or FFS_TitleBar Or FFS_CloseButton Or FFS_MaxButton Or FFS_MinButton, , , , "Form2")
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
  End With
 End With
 With .AddNewChildren(FakeCtl_Form, 200, 280, 360, 340, 2& Or FCS_TopMost, , , , , , "frmTopmost")
  .AddNewChildren FakeCtl_Label, 0, 0, 160, 96, , , , , "This is a topmost form." + vbCrLf + "Label1" + vbCrLf + "xxx"
  .AddNewChildren FakeCtl_Button, 80, 28, 140, 48, FBS_Default Or FBS_Cancel Or FCS_CanGetFocus, , , , "Close", , "cmdClose"
 End With
End With
'///
Set FakeDXUIEvent = Me
End Sub

Private Sub pSetRenderState()
'test only
objRenderTest.SetProjection_PerspectiveFovLH Atn(1), Me.ScaleWidth / Me.ScaleHeight, 0.1, 200
With d3dd9
 .SetRenderState D3DRS_LIGHTING, 0
 .SetSamplerState 0, D3DSAMP_MIPFILTER, D3DTEXF_LINEAR
 .SetSamplerState 0, D3DSAMP_MINFILTER, D3DTEXF_LINEAR
 .SetSamplerState 0, D3DSAMP_MAGFILTER, D3DTEXF_LINEAR
 .SetSamplerState 1, D3DSAMP_MIPFILTER, D3DTEXF_LINEAR
 .SetSamplerState 1, D3DSAMP_MINFILTER, D3DTEXF_LINEAR
 .SetSamplerState 1, D3DSAMP_MAGFILTER, D3DTEXF_LINEAR
 '///
 .SetTextureStageState 0, D3DTSS_COLOROP, D3DTOP_MODULATE
 .SetTextureStageState 0, D3DTSS_COLORARG1, D3DTA_TEXTURE
 .SetTextureStageState 0, D3DTSS_COLORARG2, D3DTA_DIFFUSE
 .SetTextureStageState 0, D3DTSS_ALPHAOP, D3DTOP_MODULATE
 .SetTextureStageState 0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE
 .SetTextureStageState 0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE
 .SetRenderState D3DRS_SRCBLEND, D3DBLEND_SRCALPHA
 .SetRenderState D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA
 .SetSamplerState 0, D3DSAMP_ADDRESSU, D3DTADDRESS_CLAMP
 .SetSamplerState 0, D3DSAMP_ADDRESSV, D3DTADDRESS_CLAMP
 '///
 .SetRenderState D3DRS_CULLMODE, D3DCULL_CCW
 '.SetRenderState D3DRS_NORMALIZENORMALS, 1
End With
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

Private Sub pDestroy()
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

Private Function pTest() As D3DXMesh
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
Set pTest = obj
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
 Unload Me
Case "cmdDanger"
 Randomize Timer
 For i = 1 To 1
  With FakeDXUIControls(1).AddNewChildren(FakeCtl_Form, 160 + 160 * Rnd, 120 + 120 * Rnd, 480 + 160 * Rnd, 360 + 120 * Rnd, &HFFFFFF, , , , CStr(Rnd))
   .AddNewChildren FakeCtl_Button, 16, 32, 80, 48, , , , , "Danger!!!", , "cmdDanger"
  End With
 Next i
Case "chkFullscreen"
 pChangeResolution 800, 600, obj.Value
Case "Check1"
 i = FakeDXUIFindControl("Check2")
 If i Then FakeDXUIControls(i).Enabled = obj.Value
 i = FakeDXUIFindControl("cmdClose")
 If i Then FakeDXUIControls(i).Enabled = obj.Value
End Select
End Sub

Friend Sub pChangeResolution(Optional ByVal nWidth As Long, Optional ByVal nHeight As Long, Optional ByVal bFullscreen As VbTriState = vbUseDefault)
On Error Resume Next
Dim r As RECT
'///
Select Case bFullscreen
Case vbFalse
 bFullscreen = 0
Case vbUseDefault
 bFullscreen = 1 - d3dpp.Windowed
Case Else
 bFullscreen = 1
End Select
If nWidth <= 0 Then nWidth = d3dpp.BackBufferWidth
If nHeight <= 0 Then nHeight = d3dpp.BackBufferHeight
If nWidth <> d3dpp.BackBufferWidth Or nHeight <> d3dpp.BackBufferHeight Or d3dpp.Windowed <> 1 - bFullscreen Then
 '///
 With d3dpp
  .BackBufferWidth = nWidth
  .BackBufferHeight = nHeight
  .Windowed = 1 - bFullscreen
 End With
 '///it works!
 pOnLostDevice
 d3dd9.Reset d3dpp
 pOnInitalize True
 '///resize window
 If bFullscreen Then
  SetWindowLong Me.hwnd, GWL_STYLE, &H160A0000
  SetWindowLong Me.hwnd, GWL_EXSTYLE, &H40000
 Else
  SetWindowLong Me.hwnd, GWL_STYLE, &H16CA0000
  SetWindowLong Me.hwnd, GWL_EXSTYLE, &H40100
  r.Right = nWidth
  r.Bottom = nHeight
  AdjustWindowRectEx r, &H16CA0000, 0, &H40100
  SetWindowPos Me.hwnd, 0, 0, 0, r.Right - r.Left, r.Bottom - r.Top, SWP_NOMOVE Or SWP_NOZORDER Or SWP_NOACTIVATE
 End If
 '///resize FakeDXUI
 If FakeDXUIControlCount > 0 Then
  With FakeDXUIControls(1)
   .SetRightEx nWidth, 0
   .SetBottomEx nHeight, 0
  End With
 End If
End If
End Sub

Friend Sub pOnLostDevice()
Set objTexture = Nothing
Set objNormalTexture = Nothing
objRenderTest.OnLostDevice
objDrawTest.OnLostDevice
objFontSprite.OnLostDevice
objFont.OnLostDevice
End Sub

Friend Sub pOnInitalize(Optional ByVal bReset As Boolean)
Static bInit As Boolean
If bReset Then bInit = False Else _
If bInit Then Exit Sub
'///
If bReset Then
 objRenderTest.OnResetDevice
 objDrawTest.OnResetDevice
 objFontSprite.OnResetDevice
 objFont.OnResetDevice
 '///
 pSetRenderState
 '///
End If
'///
D3DXCreateTexture d3dd9, 1024, 512, 0, D3DUSAGE_RENDERTARGET, D3DFMT_A8R8G8B8, 0, objTexture
D3DXCreateTexture d3dd9, 1024, 512, 1, D3DUSAGE_RENDERTARGET, D3DFMT_A8R8G8B8, 0, objNormalTexture
'///
Dim obj As Direct3DTexture9
Dim obj2 As Direct3DTexture9
'///
D3DXCreateTexture d3dd9, 1024, 512, 1, D3DUSAGE_RENDERTARGET, D3DFMT_R32F, 0, obj
D3DXCreateTexture d3dd9, 1024, 512, 1, D3DUSAGE_RENDERTARGET, D3DFMT_R32F, 0, obj2
objDrawTest.ProcessTextureEx Nothing, obj, "process_lerp", 0, 0, 0, 0, Vec4(-1024), Vec4(-1024), Vec4, Vec4
objDrawTest.BeginRenderToTexture obj, "gen_simplexnoise", 6, 0, 0, 0, Vec4(1, 1, 0.86, 1.85), Vec4, Vec4, Vec4
d3dd9.BeginScene
objTest.DrawSubset 0
d3dd9.EndScene
objDrawTest.EndRenderToTexture
'///expand texture to eliminate seal
objDrawTest.ProcessTexture obj, obj2, "expand8_r32f"
objDrawTest.ProcessTexture obj2, obj, "expand8_r32f"
'///
objDrawTest.ProcessTextureEx obj, obj2, "process_smoothstep", 0, 0, 0, 0, Vec4(-1, 1, 0, 1), Vec4, Vec4, Vec4
Set obj = Nothing
'///
objDrawTest.ProcessTextureEx obj2, objTexture, "process_lerp", 0, 0, 0, 0, Vec4(44 / 255, 36 / 255, 35 / 255, 1), Vec4(211 / 255, 120 / 255, 93 / 255, 1), Vec4, Vec4
objDrawTest.GenerateMipSubLevels objTexture
'///
objDrawTest.ProcessTextureEx obj2, objNormalTexture, "normal_map", 0, 0, 0, 0, Vec4(0.25, 0.25, 0, 1), Vec4, Vec4, Vec4
objDrawTest.GenerateMipSubLevels objNormalTexture
Set obj2 = Nothing
'///
bInit = True
End Sub

Private Sub IFakeDXUIEvent_Unload(ByVal obj As clsFakeDXUI, Cancel As Boolean)
'Cancel = True
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

Private Sub Timer1_Timer()
On Error Resume Next
Dim i As Long
Dim mat As D3DMATRIX, mat1 As D3DMATRIX
Dim r(3) As Long
Dim f(3) As Single
Dim s As String
If Me.WindowState = vbMinimized Then
 Sleep 20
 Exit Sub
End If
With d3dd9
 i = .TestCooperativeLevel
 If i = D3DERR_DEVICENOTRESET Then
  Sleep 20
  '///it works!
  pOnLostDevice
  Err.Clear
  .Reset d3dpp
  i = Err.Number
  If i = 0 Then pOnInitalize True
  '///
 End If
 If i = 0 Then
  '///init
  pOnInitalize
  '///
  D3DXMatrixRotationZ mat1, 0.005
  .GetTransform D3DTS_WORLD, mat
  D3DXMatrixMultiply mat, mat1, mat
  .SetTransform D3DTS_WORLD, mat
  objCamera.Apply objRenderTest
  '///
  objRenderTest.BeginRenderShadowMap
  .Clear 0, ByVal 0, D3DCLEAR_TARGET Or D3DCLEAR_ZBUFFER, -1, 1, 0
  .BeginScene
  objTest.DrawSubset 0
  .EndScene
  objRenderTest.EndRenderShadowMap
  '///
  objRenderTest.SetTexture objTexture
  objRenderTest.SetNormalTexture objNormalTexture
  objRenderTest.BeginRender
  .Clear 0, ByVal 0, D3DCLEAR_TARGET Or D3DCLEAR_ZBUFFER, 0, 1, 0
  .BeginScene
  objTest.DrawSubset 0
  .EndScene
  objRenderTest.EndRender
  '////////draw landscape test
  .SetTexture 0, objLandTexture
  .SetTransform D3DTS_WORLD, D3DXMatrixIdentity
  .BeginScene
  objLand.Render objRenderTest, objCamera
  .EndScene
  .SetTransform D3DTS_WORLD, mat
  '////////draw text test
  .BeginScene
  s = "FPS:" + Format(objTiming.FPS, "0.0")
  FakeDXGDIDrawText FakeDXUIDefaultFont, s, 32, 32, 128, 32, 0.75, DT_NOCLIP, -1, , &HFF000000, , , , , True
  FakeDXGDIDrawText FakeDXUIDefaultFont, "Landscape" + vbCrLf + "Triangles:" + CStr(MyMini_IndexCount), 48, 256, 128, 32, 1, DT_NOCLIP, &HFFFF0000, , -1, , , , 0.79, True
  .EndScene
  '////////
  .BeginScene
  FakeDXUIRender
  .EndScene
  '////////
  .Present ByVal 0, ByVal 0, 0, ByVal 0
 End If
End With
'Command1.Refresh
'Command2.Refresh
End Sub
