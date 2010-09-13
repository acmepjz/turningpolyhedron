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
   Begin VB.CommandButton Command2 
      Caption         =   "Windowed"
      Height          =   375
      Left            =   120
      TabIndex        =   1
      Top             =   600
      Visible         =   0   'False
      Width           =   1095
   End
   Begin VB.Timer Timer1 
      Interval        =   30
      Left            =   3480
      Top             =   1440
   End
   Begin VB.CommandButton Command1 
      Caption         =   "Exit"
      Height          =   375
      Left            =   120
      TabIndex        =   0
      Top             =   120
      Visible         =   0   'False
      Width           =   1095
   End
End
Attribute VB_Name = "frmMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Declare Function GetCursorPos Lib "user32.dll" (ByRef lpPoint As POINTAPI) As Long
Private Declare Function ScreenToClient Lib "user32.dll" (ByVal hwnd As Long, ByRef lpPoint As POINTAPI) As Long
Private Type POINTAPI
    x As Long
    y As Long
End Type

Implements IFakeDXUIEvent

'TODO:mouseleave event

Private objTest As D3DXMesh
Private objDrawTest As New clsRenderTexture, objRenderTest As New clsRenderPipeline

Private objTexture As Direct3DTexture9, objNormalTexture As Direct3DTexture9

Private nOldX As Long, nOldY As Long

'///test
Private objTextSprite As D3DXSprite
Private objText As D3DXFont
'Private objTextEffect As D3DXEffect
Private bUseTextEffect As Boolean
'///

Private objTiming As New clsTiming

Private Sub Command1_Click()
Unload Me
End Sub

Private Sub Command2_Click()
On Error Resume Next
d3dpp.Windowed = 1
'd3dpp.BackBufferWidth = 800
'd3dpp.BackBufferHeight = 600 'then change the window's size manually
d3dd9.Reset d3dpp
Me.Refresh
End Sub

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
ElseIf KeyCode = vbKeyT Then
 bUseTextEffect = Not bUseTextEffect
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
Set d3d9 = Direct3DCreate9(D3D_SDK_VERSION)
If d3d9 Is Nothing Then
 MsgBox "Can't create D3D9!!!", vbExclamation, "Fatal Error"
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
 '.MultiSampleType = D3DMULTISAMPLE_4_SAMPLES
End With
'create device
Set d3dd9 = d3d9.CreateDevice(0, D3DDEVTYPE_HAL, Me.hwnd, D3DCREATE_HARDWARE_VERTEXPROCESSING, d3dpp)
If d3dd9 Is Nothing Then
 MsgBox "Can't create device!!!", vbExclamation, "Fatal Error"
 Form_Unload 0
 End
End If
'///font test
D3DXCreateSprite d3dd9, objTextSprite
D3DXCreateFontW d3dd9, 32, 0, 0, 0, 0, 0, 0, 0, 0, "Tahoma", objText
With FakeDXUIDefaultFont
 Set .objFont = objText
 Set .objSprite = objTextSprite
End With
'CreateEffect CStr(App.Path) + "\data\shader\texteffect.txt", objTextEffect, , True
'///vertex declaration test
CreateVertexDeclaration
'///
pSetRenderState
'//////test
objDrawTest.Create
Set objTest = pTest
'new:mipmap
D3DXCreateTexture d3dd9, 1024, 512, 0, D3DUSAGE_RENDERTARGET, D3DFMT_A8R8G8B8, 0, objTexture
D3DXCreateTexture d3dd9, 1024, 512, 0, D3DUSAGE_RENDERTARGET, D3DFMT_A8R8G8B8, 0, objNormalTexture
'///
FakeDXUICreate 0, 0, 640, 480
FakeDXUIControls(1).AddNewChildren FakeCtl_Form, 120, 240, 260, 400, &HFFFFFF, , , , "Form1234°¡°¢"
i = FakeDXUIControls(1).AddNewChildren(FakeCtl_Form, 240, 200, 480, 360, &HFFFFFF, , , , "MDIForm1")
i = FakeDXUIControls(i).AddNewChildren(FakeCtl_Form, 0, 0, 0, 0, FakeCtl_Form_Moveable Or FakeCtl_Form_TitleBar Or FakeCtl_Form_CloseButton Or FakeCtl_Form_MaxButton Or FakeCtl_Form_MinButton, , , , "Form2")
With FakeDXUIControls(i)
 .SetLeftEx 0, 0.25
 .SetTopEx 0, 0.25
 .SetRightEx 0, 0.75
 .SetBottomEx 0, 0.75
End With
i = FakeDXUIControls(1).AddNewChildren(FakeCtl_Form, 200, 280, 360, 340, 3& Or FakeCtl_Style_TopMost)
FakeDXUIControls(i).AddNewChildren FakeCtl_Label, 0, 0, 160, 96, , , , , "This is a topmost form." + vbCrLf + "Label1" + vbCrLf + "xxx"
Set FakeDXUIEvent = Me
'///
objRenderTest.Create
objRenderTest.SetLightDirectionByVal 0, 4, 2.5, True 'new
objRenderTest.SetLightPositionByVal 0, 8, 5
objRenderTest.SetLightType D3DLIGHT_DIRECTIONAL
'objRenderTest.SetLightType D3DLIGHT_POINT
pLookAtLH Vec3(6, 2, 3), Vec3, Vec3(, , 1)
'pLookAtLH Vec3(1, 0, 8), Vec3, Vec3(, , 1)
objRenderTest.CreateShadowMap 1024 'new
'objRenderTest.SetShadowState True, Atn(1), 0.1, 20   'point
objRenderTest.SetShadowState True, 16, -100, 100  'directional
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

Private Sub pLookAtLH(pEye As D3DVECTOR, pAt As D3DVECTOR, pUp As D3DVECTOR)
Dim mat As D3DMATRIX
D3DXMatrixLookAtLH mat, pEye, pAt, pUp
d3dd9.SetTransform D3DTS_VIEW, mat
objRenderTest.SetViewPositionByVal pEye.x, pEye.y, pEye.z
End Sub

Private Sub Form_MouseDown(Button As Integer, Shift As Integer, x As Single, y As Single)
'///
If FakeDXUIOnMouseEvent(Button, Shift, x, y, 1) Then Exit Sub
'///
nOldX = x
nOldY = y
FakeDXUISetCapture = -1
End Sub

Private Sub Form_MouseMove(Button As Integer, Shift As Integer, x As Single, y As Single)
Dim xx As Long, yy As Long
Dim m As D3DMATRIX
'///
If FakeDXUIOnMouseEvent(Button, Shift, x, y, 0) Then Exit Sub
'///
Select Case Button
Case 1
 xx = x - nOldX
 yy = y - nOldY
 D3DXMatrixRotationZ m, -xx / 100
 d3dd9.MultiplyTransform D3DTS_VIEW, m
 D3DXMatrixRotationY m, yy / 100
 d3dd9.MultiplyTransform D3DTS_VIEW, m
End Select
nOldX = x
nOldY = y
End Sub

Private Sub Form_MouseUp(Button As Integer, Shift As Integer, x As Single, y As Single)
'///
If FakeDXUIOnMouseEvent(Button, Shift, x, y, 2) Then Exit Sub
'///
FakeDXUISetCapture = 0
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
'bug in x file loader: you must write "1.000" instead of "1" or it'll buggy :-3
'D3DXLoadMeshFromXW CStr(App.Path) + "\media\cube1_1.x", 0, d3dd9, objAdjacency, Nothing, Nothing, 0, obj
D3DXLoadMeshFromXW CStr(App.Path) + "\media\test.x", 0, d3dd9, objAdjacency, Nothing, Nothing, 0, obj
Set obj = obj.CloneMesh(0, m_tVertexDecl(0), d3dd9)
'///recalculate normal
D3DXComputeTangentFrame obj, D3DXTANGENT_CALCULATE_NORMALS
'//poly20-can smooth, monkey can't :-3 cube1-1 can't either ---why?
'D3DXComputeTangentFrameEx obj, D3DDECLUSAGE_TEXCOORD, 0, D3DDECLUSAGE_BINORMAL, 0, D3DDECLUSAGE_TANGENT, 0, D3DDECLUSAGE_NORMAL, 0, _
'D3DXTANGENT_GENERATE_IN_PLACE Or D3DXTANGENT_CALCULATE_NORMALS, ByVal objAdjacency.GetBufferPointer, 0.01, 0.25, 0.01, Nothing, Nothing
'///
Set pTest = obj
End Function

Private Sub IFakeDXUIEvent_Click(ByVal obj As clsFakeDXUI)
'
End Sub

Private Sub IFakeDXUIEvent_Unload(ByVal obj As clsFakeDXUI, Cancel As Boolean)
'Cancel = True
End Sub

Private Sub Timer1_Timer()
On Error Resume Next
Dim i As Long
Dim mat As D3DMATRIX, mat1 As D3DMATRIX
Dim r(3) As Long
Dim f(23) As Single, f1 As Single
Dim s As String
Static j As Long
If Me.WindowState = vbMinimized Then Exit Sub
With d3dd9
 i = .TestCooperativeLevel
 If i = D3DERR_DEVICENOTRESET Then
  .Reset d3dpp
'  j = 0
  i = .TestCooperativeLevel
  Debug.Print "Reset"
 End If
 If i = 0 Then
  If j = 0 Then
   '////////render texture
   Dim obj As Direct3DTexture9
   '///
   objDrawTest.BeginRenderToTexture objTexture
   .Clear 0, ByVal 0, D3DCLEAR_TARGET, 0, 1, 0
   .BeginScene
   objTest.DrawSubset 0
   .EndScene
   objDrawTest.EndRenderToTexture
   '///expand texture to eliminate seal
   D3DXCreateTexture d3dd9, 1024, 512, 1, D3DUSAGE_RENDERTARGET, D3DFMT_A8R8G8B8, 0, obj
   objDrawTest.ProcessTexture objTexture, obj, "expand8"
   objDrawTest.ProcessTexture obj, objTexture, "expand8"
   Set obj = Nothing
   objDrawTest.GenerateMipSubLevels objTexture
   '///
   D3DXCreateTexture d3dd9, 1024, 512, 1, D3DUSAGE_RENDERTARGET, D3DFMT_R32F, 0, obj
   objDrawTest.ProcessTexture objTexture, obj, "grayscale"
   objDrawTest.ProcessTexture obj, objNormalTexture, "normal_map"
   Set obj = Nothing
   objDrawTest.GenerateMipSubLevels objNormalTexture
   '////////
   j = 1
  End If
   D3DXMatrixRotationZ mat1, 0.01
   .GetTransform D3DTS_WORLD, mat
   D3DXMatrixMultiply mat, mat1, mat
   .SetTransform D3DTS_WORLD, mat
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
'   j = 1
'  End If
  '////////test
  f1 = objTiming.GetMs
  objTiming.Clear
  objTiming.StartTiming
  .BeginScene
  If f1 > 0.01 Then
   Static f2 As Single
   f1 = 1000 / f1
   f2 = (f1 + 15 * f2) / 16
   s = "FPS:" + Format(f2, "0.0")
   FakeDXGDIDrawText FakeDXUIDefaultFont, s, 32, 32, 128, 32, 0.75, DT_NOCLIP, -1, , &HFF000000, , , , , True
  End If
  FakeDXGDIDrawText FakeDXUIDefaultFont, "TEST 2 !!! °¡°¢", 32, 256, 128, 32, 1, DT_NOCLIP, &HFFFF0000, , -1, , , , 0.79, True
  .EndScene
'  '////////draw window test
'  .SetTexture 0, FakeDXUITexture
'  .SetRenderState D3DRS_ALPHABLENDENABLE, 1
'  .SetFVF D3DFVF_XYZRHW Or D3DFVF_TEX1
'  f1 = 1 / 1024
'  f(3) = 1: f(4) = f1: f(5) = f1
'  f(6) = 512: f(9) = 1: f(10) = 1 + f1: f(11) = f1
'  f(13) = 512: f(15) = 1: f(16) = f1: f(17) = 1 + f1
'  f(18) = 512: f(19) = 512: f(21) = 1: f(22) = 1 + f1: f(23) = 1 + f1
'  .DrawPrimitiveUP D3DPT_TRIANGLESTRIP, 2&, f(0), 24&
'  .SetRenderState D3DRS_ALPHABLENDENABLE, 0
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
