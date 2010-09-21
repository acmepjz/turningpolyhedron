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
   Begin VB.Timer Timer1 
      Enabled         =   0   'False
      Interval        =   30
      Left            =   3480
      Top             =   1440
   End
End
Attribute VB_Name = "frmMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

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

Private Declare Function SHGetSpecialFolderPath Lib "shell32.dll" Alias "SHGetSpecialFolderPathA" (ByVal hwnd As Long, ByVal pszPath As String, ByVal csidl As Long, ByVal fCreate As Long) As Long
Private Declare Function MakeSureDirectoryPathExists Lib "imagehlp.dll" (ByVal DirPath As String) As Long

Public m_sMyGamesPath As String

Implements IFakeDXUIEvent

'TODO:mouseleave event

Private objTest As D3DXMesh
Private objDrawTest As New clsRenderTexture, objRenderTest As New clsRenderPipeline

Private objTexture As Direct3DTexture9, objNormalTexture As Direct3DTexture9

'///test
Private objFontSprite As D3DXSprite
Private objFont As D3DXFont
'///

Private objTiming As New clsTiming
Private objCamera As New clsCamera

Private cSub As New cSubclass

Implements iSubclass

Private Const WM_IME_COMPOSITION As Long = &H10F
Private Const WM_IME_STARTCOMPOSITION As Long = &H10D
Private Const WM_IME_NOTIFY As Long = &H282
Private Const WM_MOUSEWHEEL As Long = &H20A

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
On Error Resume Next
Dim i As Long
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
D3DXCreateSprite d3dd9, objFontSprite
D3DXCreateFontW d3dd9, 32, 0, 0, 0, 0, 0, 0, 0, 0, "Tahoma", objFont
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
'///
Me.Caption = objText.GetText("Turning Polyhedron")
'////////new:subclass
cSub.AddMsg WM_IME_NOTIFY, MSG_AFTER
cSub.AddMsg WM_IME_COMPOSITION, MSG_AFTER
cSub.AddMsg WM_IME_STARTCOMPOSITION, MSG_AFTER
cSub.AddMsg WM_MOUSEWHEEL, MSG_AFTER
cSub.Subclass Me.hwnd, Me
'////////
objTiming.MinPeriod = 1000 / 30
'////////new:deadloop
Do Until d3dd9 Is Nothing
 objTiming.WaitForNextFrame
 Timer1_Timer
 DoEvents
Loop
End Sub

Private Sub pCreateUI()
FakeDXUICreate 0, 0, d3dpp.BackBufferWidth, d3dpp.BackBufferHeight
With FakeDXUIControls(1)
 .AddNewChildren FakeCtl_Button, 8, -24, 80, -8, , , , , "Exit", , "cmdExit", , 1, , 1
 .AddNewChildren FakeCtl_Button, 8, -48, 80, -32, FakeCtl_Button_CheckBox Or FakeCtl_Button_Graphical, , , , "Fullscreen", , "chkFullscreen", , 1, , 1
 With .AddNewChildren(FakeCtl_Form, 120, 240, 320, 400, &HFFFFFF, , , , "Form1234°¡°¢")
  .AddNewChildren FakeCtl_Button, 0, 0, 64, 16, FakeCtl_Button_CheckBox, , , , "Enabled", , "Check1", , , , , 1
  .AddNewChildren FakeCtl_Button, 0, 16, 64, 32, FakeCtl_Button_CheckBoxTristate, , , , "Check2", , "Check2"
  .AddNewChildren FakeCtl_Button, 0, 32, 64, 48, , , , , "Danger!!!", , "cmdDanger"
 End With
 With .AddNewChildren(FakeCtl_Form, 240, 200, 480, 360, &HFFFFFF, , , , "MDIForm1")
  .ScrollBars = vbBoth
  .Min = -50
  .Max = 50
  .LargeChange = 10
  .Min(1) = -50
  .Max(1) = 50
  .LargeChange(1) = 10
  '///
  .AddNewChildren FakeCtl_Form, 0, 0, 0, 0, _
  FakeCtl_Form_Moveable Or FakeCtl_Form_TitleBar Or FakeCtl_Form_CloseButton Or FakeCtl_Form_MaxButton Or FakeCtl_Form_MinButton, , , , "Form2", , , _
  0.25, 0.25, 0.75, 0.75
 End With
 With .AddNewChildren(FakeCtl_Form, 200, 280, 360, 340, 2& Or FakeCtl_Style_TopMost, , , , , , "frmTopmost")
  .AddNewChildren FakeCtl_Label, 0, 0, 160, 96, , , , , "This is a topmost form." + vbCrLf + "Label1" + vbCrLf + "xxx"
  .AddNewChildren FakeCtl_Button, 80, 28, 140, 48, FakeCtl_Button_Default Or FakeCtl_Button_Cancel, , , , "Close", , "cmdClose"
 End With
End With
'///
Set FakeDXUIEvent = Me
End Sub

Private Sub pSetRenderState()
'test only
Dim mat As D3DMATRIX
With d3dd9
 .SetRenderState D3DRS_LIGHTING, 0
 .SetSamplerState 0, D3DSAMP_MIPFILTER, D3DTEXF_LINEAR
 .SetSamplerState 0, D3DSAMP_MINFILTER, D3DTEXF_LINEAR
 .SetSamplerState 0, D3DSAMP_MAGFILTER, D3DTEXF_LINEAR
 D3DXMatrixPerspectiveFovLH mat, Atn(1), Me.ScaleWidth / Me.ScaleHeight, 0.1, 100
 .SetTransform D3DTS_PROJECTION, mat
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
FakeDXUIDestroy
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
Dim i As Long, lp As Long
Dim tDesc As D3DVERTEXBUFFER_DESC
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
 For i = 1 To 100
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
 i = FakeDXUIFindControl("hs1")
 If i Then FakeDXUIControls(i).Enabled = obj.Value
 i = FakeDXUIFindControl("vs1")
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
Dim h As Long
Dim s As String
Dim i As Long, m As Long
Dim p As POINTAPI
Select Case uMsg
'Case WM_IME_NOTIFY
' Select Case wParam
' Case IMN_OPENCANDIDATE, IMN_CHANGECANDIDATE
'  Timer1_Timer 'ABC-OK ,M$PY-doesn't work
' Case IMN_CLOSECANDIDATE
'  Label1.Caption = ""
' End Select
'Case WM_IME_COMPOSITION, WM_IME_STARTCOMPOSITION
' h = ImmGetContext(Me.hwnd)
' If h Then
'  '///
'  s = Space(1024)
'  m = ImmGetCompositionString(h, GCS_COMPSTR, ByVal StrPtr(s), 2048)
'  If m Then
'   s = LeftB(s, m)
'   i = ImmGetCompositionString(h, GCS_CURSORPOS, ByVal 0, 0)
'   If i >= 0 And i <= m Then
'    s = LeftB(s, i) + LeftB("|", 1) + MidB(s, i + 1)
'   End If
'   s = StrConv(s, vbUnicode)
'  Else
'   s = ""
'  End If
'  '///
'  Label2.Caption = s
'  '///
'  ImmReleaseContext Me.hwnd, h
' End If
Case WM_MOUSEWHEEL
 i = (wParam And &HFFFF0000) \ &H10000
' p.x = (lParam And &H7FFF&) Or (&HFFFF8000 And ((lParam And &H8000&) <> 0))
' p.y = (lParam And &HFFFF0000) \ &H10000
 GetCursorPos p
 ScreenToClient Me.hwnd, p
 OnMouseWheel (wParam And 3&) Or (vbMiddleButton And ((wParam And &H10&) <> 0)), _
 ((wParam And &HC&) \ 4&) Or (vbAltMask And ((GetAsyncKeyState(vbKeyMenu) And 1&) <> 0)), p.x, p.y, i
End Select
End Sub

Private Sub iSubclass_Before(bHandled As Boolean, lReturn As Long, hwnd As Long, uMsg As Long, wParam As Long, lParam As Long)
'
End Sub

Friend Sub OnMouseWheel(ByVal Button As MouseButtonConstants, ByVal Shift As ShiftConstants, ByVal x As Long, ByVal y As Long, ByVal nDelta As Long)
If FakeDXUIOnMouseWheel(nDelta, Shift) Then Exit Sub
'etc.
End Sub

Private Sub Timer1_Timer()
On Error Resume Next
Dim i As Long
Dim mat As D3DMATRIX, mat1 As D3DMATRIX
Dim r(3) As Long
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
  '////////test
  s = "FPS:" + Format(objTiming.FPS, "0.0")
  FakeDXGDIDrawText FakeDXUIDefaultFont, s, 32, 32, 128, 32, 0.75, DT_NOCLIP, -1, , &HFF000000, , , , , True
  FakeDXGDIDrawText FakeDXUIDefaultFont, "TEST 2 !!! °¡°¢", 32, 256, 128, 32, 1, DT_NOCLIP, &HFFFF0000, , -1, , , , 0.79, True
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
