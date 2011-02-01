Attribute VB_Name = "mdlMain"
Option Explicit

#Const UseSubclass = True

Private Declare Function SHGetSpecialFolderPath Lib "shell32.dll" Alias "SHGetSpecialFolderPathA" (ByVal hWnd As Long, ByVal pszPath As String, ByVal csidl As Long, ByVal fCreate As Long) As Long
Private Declare Function MakeSureDirectoryPathExists Lib "imagehlp.dll" (ByVal DirPath As String) As Long

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)
Private Declare Sub Sleep Lib "kernel32.dll" (ByVal dwMilliseconds As Long)

Private Declare Function GetActiveWindow Lib "user32.dll" () As Long
Private Declare Function GetAsyncKeyState Lib "user32.dll" (ByVal vKey As Long) As Integer

Private Declare Function IsIconic Lib "user32.dll" (ByVal hWnd As Long) As Long
Private Declare Function IsWindow Lib "user32.dll" (ByVal hWnd As Long) As Long

Private Declare Function GetWindowLong Lib "user32.dll" Alias "GetWindowLongA" (ByVal hWnd As Long, ByVal nIndex As Long) As Long
Private Declare Function SetWindowLong Lib "user32.dll" Alias "SetWindowLongA" (ByVal hWnd As Long, ByVal nIndex As Long, ByVal dwNewLong As Long) As Long
Private Declare Function SetWindowPos Lib "user32.dll" (ByVal hWnd As Long, ByVal hWndInsertAfter As Long, ByVal x As Long, ByVal y As Long, ByVal cx As Long, ByVal cy As Long, ByVal wFlags As Long) As Long
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

Private Const WM_INPUTLANGCHANGE As Long = &H51
Private Const WM_IME_COMPOSITION As Long = &H10F
Private Const WM_IME_STARTCOMPOSITION As Long = &H10D
Private Const WM_IME_ENDCOMPOSITION As Long = &H10E
Private Const WM_IME_NOTIFY As Long = &H282
Private Const WM_MOUSEWHEEL As Long = &H20A

Public d3d9 As Direct3D9
Public d3dd9 As Direct3DDevice9

Public d3dpp As D3DPRESENT_PARAMETERS
Public d3dc9 As D3DCAPS9

Public Type typeVertex
 p As D3DVECTOR
 n As D3DVECTOR
 b As D3DVECTOR
 ta As D3DVECTOR
 clr1 As Long 'diffuse
 clr2 As Long 'specular
 t As D3DXVECTOR2
End Type

Public Type typeVertex_XYZ_Diffuse
 p As D3DVECTOR
 clr1 As Long
End Type

Public m_tDefVertexDecl() As D3DVERTEXELEMENT9

Public objText As New clsGNUGetText

Public objTiming As New clsTiming

Public FakeDXAppMyGamesPath As String

Public FakeDXAppRequestUnload As Boolean, FakeDXAppCanUnload As Boolean

'////////test

'default camera
Public objCamera As New clsCamera

'test
Public objTest As D3DXMesh
Public objDrawTest As New clsRenderTexture, objRenderTest As New clsRenderPipeline
Public objLand As New clsRenderLandscape, objLandTexture As Direct3DTexture9

Public objTexture As Direct3DTexture9, objNormalTexture As Direct3DTexture9

Public objFontSprite As D3DXSprite
Public objFont As D3DXFont
'////////

'////////settings
Public frmSettings As New frmSettings

Public Sub CreateVertexDeclaration()
ReDim m_tDefVertexDecl(0 To 7)
m_tDefVertexDecl(0) = D3DVertexElementCreate(, 0, D3DDECLTYPE_FLOAT3, , D3DDECLUSAGE_POSITION)
m_tDefVertexDecl(1) = D3DVertexElementCreate(, 12&, D3DDECLTYPE_FLOAT3, , D3DDECLUSAGE_NORMAL)
m_tDefVertexDecl(2) = D3DVertexElementCreate(, 24&, D3DDECLTYPE_FLOAT3, , D3DDECLUSAGE_BINORMAL)
m_tDefVertexDecl(3) = D3DVertexElementCreate(, 36&, D3DDECLTYPE_FLOAT3, , D3DDECLUSAGE_TANGENT)
m_tDefVertexDecl(4) = D3DVertexElementCreate(, 48&, D3DDECLTYPE_D3DCOLOR, , D3DDECLUSAGE_COLOR)
m_tDefVertexDecl(5) = D3DVertexElementCreate(, 52&, D3DDECLTYPE_D3DCOLOR, , D3DDECLUSAGE_COLOR, 1)
m_tDefVertexDecl(6) = D3DVertexElementCreate(, 56&, D3DDECLTYPE_FLOAT2, , D3DDECLUSAGE_TEXCOORD)
m_tDefVertexDecl(7) = D3DDECL_END '64 bytes
End Sub

'Public Sub CreateCube1(ByVal lp As Long, ByVal clr1 As Long, ByVal clr2 As Long)
'Dim i As Long
'Dim d(23) As typeVertex
'For i = 0 To 23
' d(i).clr1 = clr1
' d(i).clr2 = clr2
'Next i
''///
'
''///
'CopyMemory ByVal lp, d(0), Len(d(0)) * 24&
'End Sub

Public Sub FakeDXAppMainLoop(Optional ByVal lpbCancel As Long)
Dim b As Byte
Do Until d3dd9 Is Nothing
 '///process key event
 FakeDXAppProcessKeyEvent
 '///
 objTiming.WaitForNextFrame
 FakeDXAppRender
 DoEvents
 '///
 If FakeDXAppRequestUnload Then Exit Do
 '///
 If lpbCancel Then
  CopyMemory b, ByVal lpbCancel, 1&
  If b Then Exit Do
 End If
Loop
End Sub

Public Sub FakeDXAppProcessKeyEvent()
Dim dx As Single, dz As Single
If GetActiveWindow = d3dpp.hDeviceWindow And FakeDXUIActiveWindow = 0 Then
 If GetAsyncKeyState(vbKeyA) And &H8000& Then
  dx = -0.5
 ElseIf GetAsyncKeyState(vbKeyD) And &H8000& Then
  dx = 0.5
 End If
 If GetAsyncKeyState(vbKeyS) And &H8000& Then
  dz = -0.5
 ElseIf GetAsyncKeyState(vbKeyW) And &H8000& Then
  dz = 0.5
 End If
 If dx <> 0 Or dz <> 0 Then objCamera.MoveByLocalCoordinatesLH dx, 0, dz
End If
End Sub

Public Sub FakeDXAppRender()
On Error Resume Next
Dim i As Long
Dim mat As D3DMATRIX, mat1 As D3DMATRIX, mat2 As D3DMATRIX
Dim r(3) As Long
Dim f(3) As Single
Dim s As String
If IsIconic(d3dpp.hDeviceWindow) Then
 Sleep 20
 Exit Sub
End If
With d3dd9
 i = .TestCooperativeLevel
 If i = D3DERR_DEVICENOTRESET Then
  Sleep 20
  '///it works!
  FakeDXAppOnLostDevice
  Err.Clear
  .Reset d3dpp
  i = Err.Number
  If i = 0 Then FakeDXAppOnInitalize True
  '///
 End If
 If i = 0 Then
  '///init
  FakeDXAppOnInitalize
  '///
  D3DXMatrixRotationZ mat1, 0.005
  .GetTransform D3DTS_WORLD, mat
  D3DXMatrixMultiply mat, mat1, mat
  .SetTransform D3DTS_WORLD, mat
  objCamera.Apply objRenderTest
  '///
  objRenderTest.SetDepthOfFieldParams objCamera.RealDistance, 0.01, 0.1, 40
  '///shadow map
  If objRenderTest.BeginRender(RenderPass_ShadowMap) Then
   .Clear 0, ByVal 0, D3DCLEAR_TARGET Or D3DCLEAR_ZBUFFER, -1, 1, 0
   .BeginScene
   objTest.DrawSubset 0
   .EndScene
   objRenderTest.EndRender
  End If
  '///draw cube with effects
  objRenderTest.BeginRenderToPostProcessTarget
  objRenderTest.SetTexture objTexture
  objRenderTest.SetNormalTexture objNormalTexture
  If objRenderTest.BeginRender(RenderPass_Main) Then
   .BeginScene
   objTest.DrawSubset 0
'   '////////draw landscape test (new and buggy) TODO:shouldn't use advanced shading effects
'   objRenderTest.SetTexture objLandTexture
'   .SetTransform D3DTS_WORLD, D3DXMatrixIdentity
'   objRenderTest.UpdateRenderState
'   objLand.Render objRenderTest, objCamera
'   .SetTransform D3DTS_WORLD, mat
'   '////////
   .EndScene
   objRenderTest.EndRender
  End If
  objRenderTest.EndRenderToPostProcessTarget
  '////////volumetric fog test
  If objRenderTest.BeginRender(RenderPass_FogVolume) Then
   D3DXMatrixScaling mat1, 5, 5, 5
   D3DXMatrixMultiply mat2, mat1, mat
   .SetTransform D3DTS_WORLD, mat2
   objRenderTest.UpdateRenderState '???
   .Clear 0, ByVal 0, D3DCLEAR_TARGET Or D3DCLEAR_ZBUFFER, 0, 1, 0
   .BeginScene
   objTest.DrawSubset 0
   .EndScene
   objRenderTest.EndRender
   .SetTransform D3DTS_WORLD, mat
  End If
  '////////perform post process
  objRenderTest.PerformPostProcess objDrawTest
  '////////draw text test
  .BeginScene
  s = "FPS:" + Format(objTiming.FPS, "0.0")
  FakeDXGDIDrawText FakeDXUIDefaultFont, s, 32, 32, 128, 32, 0.75, DT_NOCLIP, -1, , &HFF000000, , , , , True
  FakeDXGDIDrawText FakeDXUIDefaultFont, "Landscape Triangles:" + CStr(MyMini_IndexCount) + vbCrLf + "Fog Triangles:" + CStr(MyMini_FogIndexCount), _
  48, 256, 128, 32, 0.75, DT_NOCLIP, &HFFFF0000, , -1, , , , 0.2, True
  .EndScene
  '////////
  .BeginScene
  FakeDXUIRender
  .EndScene
  '////////
  .Present ByVal 0, ByVal 0, 0, ByVal 0
 End If
End With
End Sub

Public Sub FakeDXAppOnLostDevice()
Set objTexture = Nothing
Set objNormalTexture = Nothing
objRenderTest.OnLostDevice
objDrawTest.OnLostDevice
objFontSprite.OnLostDevice
objFont.OnLostDevice
End Sub

Public Sub FakeDXAppOnInitalize(Optional ByVal bReset As Boolean)
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
 FakeDXAppSetDefaultRenderState
 '///
End If
'///
D3DXCreateTexture d3dd9, 1024, 512, 0, D3DUSAGE_RENDERTARGET Or D3DUSAGE_AUTOGENMIPMAP, D3DFMT_A8R8G8B8, 0, objTexture
D3DXCreateTexture d3dd9, 1024, 512, 1, D3DUSAGE_RENDERTARGET Or D3DUSAGE_AUTOGENMIPMAP, D3DFMT_A8R8G8B8, 0, objNormalTexture
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
'///
objDrawTest.ProcessTextureEx obj2, objNormalTexture, "normal_map", 0, 0, 0, 0, Vec4(0.25, 0.25, 0, 1), Vec4, Vec4, Vec4
Set obj2 = Nothing
'///
bInit = True
End Sub

Public Sub FakeDXAppAdjustWindowPos()
On Error Resume Next
Dim r As RECT
'///resize window
If d3dpp.Windowed = 0 Then
 SetWindowLong d3dpp.hDeviceWindow, GWL_STYLE, &H160A0000
 SetWindowLong d3dpp.hDeviceWindow, GWL_EXSTYLE, &H40000
Else
 SetWindowLong d3dpp.hDeviceWindow, GWL_STYLE, &H16CA0000
 SetWindowLong d3dpp.hDeviceWindow, GWL_EXSTYLE, &H40100
 r.Right = d3dpp.BackBufferWidth
 r.Bottom = d3dpp.BackBufferHeight
 AdjustWindowRectEx r, &H16CA0000, 0, &H40100
 SetWindowPos d3dpp.hDeviceWindow, 0, 0, 0, r.Right - r.Left, r.Bottom - r.Top, SWP_NOMOVE Or SWP_NOZORDER Or SWP_NOACTIVATE
End If
'///resize FakeDXUI
If FakeDXUIControlCount > 0 Then
 With FakeDXUIControls(1)
  .SetRightEx d3dpp.BackBufferWidth, 0
  .SetBottomEx d3dpp.BackBufferHeight, 0
 End With
End If
End Sub

Public Sub FakeDXAppChangeResolution(Optional ByVal nWidth As Long, Optional ByVal nHeight As Long, Optional ByVal bFullscreen As VbTriState = vbUseDefault)
On Error Resume Next
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
 FakeDXAppOnLostDevice
 d3dd9.Reset d3dpp
 FakeDXAppOnInitalize True
 '///resize
 FakeDXAppAdjustWindowPos
End If
End Sub

Public Sub FakeDXAppSetDefaultRenderState()
'zFar can be very big and there's still small error, but zNear can't be very small
objRenderTest.SetProjection_PerspectiveFovLH Atn(1.732), d3dpp.BackBufferWidth / d3dpp.BackBufferHeight, 0.1, 1000
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
' .SetTextureStageState 1, D3DTSS_COLOROP, D3DTOP_DISABLE
' .SetTextureStageState 1, D3DTSS_ALPHAOP, D3DTOP_DISABLE
 .SetRenderState D3DRS_SRCBLEND, D3DBLEND_SRCALPHA
 .SetRenderState D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA
 .SetSamplerState 0, D3DSAMP_ADDRESSU, D3DTADDRESS_CLAMP
 .SetSamplerState 0, D3DSAMP_ADDRESSV, D3DTADDRESS_CLAMP
 '///
 .SetRenderState D3DRS_CULLMODE, D3DCULL_CCW
 '.SetRenderState D3DRS_NORMALIZENORMALS, 1
End With
End Sub

Public Sub FakeDXAppDestroy()
On Error Resume Next
'///
FakeDXUIDestroy
Set objLand = Nothing
Set objLandTexture = Nothing
Set objDrawTest = Nothing
Set objTest = Nothing
Set objTexture = Nothing
Set objNormalTexture = Nothing
Set d3dd9 = Nothing
Set d3d9 = Nothing
'///
Dim frm As Form
FakeDXAppCanUnload = True
For Each frm In Forms
 Unload frm
Next frm
'///
End Sub

Public Sub FakeDXAppInit(ByVal frm As Form, ByVal objSubclass As cSubclass, ByVal objCallback As iSubclass, ByVal objEventCallback As IFakeDXUIEvent)
On Error Resume Next
Dim i As Long
Dim s As String
'///
FakeDXAppMyGamesPath = Space(1024)
SHGetSpecialFolderPath 0, FakeDXAppMyGamesPath, 5, 1
FakeDXAppMyGamesPath = Left(FakeDXAppMyGamesPath, InStr(1, FakeDXAppMyGamesPath, vbNullChar) - 1) + "\My Games\Turning Polyhedron\"
MakeSureDirectoryPathExists FakeDXAppMyGamesPath
'///load config
frmSettings.FileName = FakeDXAppMyGamesPath + "config.xml"
frmSettings.LoadFile
'///
objText.LoadFileWithLocale App.Path + "\data\locale\*.mo", , True
'///
frm.Show
frm.Caption = objText.GetText("Initalizing...")
'///
Set d3d9 = Direct3DCreate9(D3D_SDK_VERSION)
If d3d9 Is Nothing Then
 MsgBox objText.GetText("Can't create D3D9!!!"), vbExclamation, objText.GetText("Fatal Error")
 End
End If
With d3dpp
 '.Windowed = 1 'already loaded
 .hDeviceWindow = frm.hWnd
 .SwapEffect = D3DSWAPEFFECT_DISCARD
 .BackBufferCount = 1
 .BackBufferFormat = D3DFMT_X8R8G8B8
 '.BackBufferWidth = 640 'already loaded
 '.BackBufferHeight = 480 'already loaded
 .EnableAutoDepthStencil = 1
 .AutoDepthStencilFormat = D3DFMT_D24S8
 '.PresentationInterval = D3DPRESENT_INTERVAL_IMMEDIATE
 .PresentationInterval = D3DPRESENT_INTERVAL_ONE
 '.MultiSampleType = D3DMULTISAMPLE_4_SAMPLES
End With
'///
FakeDXAppAdjustWindowPos
'///get device caps
d3d9.GetDeviceCaps 0, D3DDEVTYPE_HAL, d3dc9
If d3dc9.DevCaps And D3DDEVCAPS_HWTRANSFORMANDLIGHT Then i = D3DCREATE_HARDWARE_VERTEXPROCESSING _
Else i = D3DCREATE_SOFTWARE_VERTEXPROCESSING
'TODO:shader version, etc.
'///create device
Set d3dd9 = d3d9.CreateDevice(0, D3DDEVTYPE_HAL, frm.hWnd, i, d3dpp)
If d3dd9 Is Nothing Then
 MsgBox objText.GetText("Can't create device!!!"), vbExclamation, objText.GetText("Fatal Error")
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
Set objTest = pLoadMeshTest
'///
FakeDXAppCreateUI objEventCallback
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
 With objSubclass
  .AddMsg WM_IME_NOTIFY, MSG_AFTER
  .AddMsg WM_IME_COMPOSITION, MSG_AFTER
  .AddMsg WM_IME_STARTCOMPOSITION, MSG_AFTER
  .AddMsg WM_IME_ENDCOMPOSITION, MSG_AFTER
  .AddMsg WM_INPUTLANGCHANGE, MSG_AFTER
  .AddMsg WM_MOUSEWHEEL, MSG_AFTER
  .Subclass frm.hWnd, objCallback
 End With
End If
'////////test
Dim t As D3DXIMAGE_INFO
objLand.CreateFromFile App.Path + "\heightmap_test.png", , , 0.25, , , -15 ', App.Path + "\fogmap_test.png", , 0.01, , 0.1
'objLand.CreateFromFile App.Path + "\heightmap_test.png", 3, 5, 0.05, , , -15, App.Path + "\fogmap_test.png", 3, 0.05, 2
'objLand.FogEnabled = True
D3DXCreateTextureFromFileExW d3dd9, App.Path + "\test0.png", D3DX_DEFAULT, D3DX_DEFAULT, 1, 0, D3DFMT_FROM_FILE, D3DPOOL_MANAGED, D3DX_DEFAULT, D3DX_DEFAULT, 0, t, ByVal 0, objLandTexture
'////////over
frm.Caption = objText.GetText("Turning Polyhedron")
'////////
End Sub

'internal function
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

'internal function, and TEST ONLY
Private Function pLoadMeshTest() As D3DXMesh
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
Set pLoadMeshTest = obj
End Function

Public Sub FakeDXAppCreateUI(ByVal objEventCallback As IFakeDXUIEvent)
Dim i As Long
FakeDXUICreate 0, 0, d3dpp.BackBufferWidth, d3dpp.BackBufferHeight
With FakeDXUIControls(1)
 '///some buttons, including settings
 .AddNewChildren FakeCtl_Button, 8, -32, 80, -8, , , , , objText.GetText("Exit"), , "cmdExit", , 1, , 1, , , objText.GetText("Exit the game and return to desktop.")
 .AddNewChildren FakeCtl_Button, 208, -32, 280, -8, , , , , objText.GetText("Options"), , "cmdOptions", , 1, , 1, , , objText.GetText("Change the game settings.")
 '///following items are TEST ONLY
 .AddNewChildren(FakeCtl_Button, 108, -32, 180, -8, , , , , "Danger!!!", , "cmdDanger", , 1, , 1, , , "Debug").ForeColor = &HFF0000
 '///
 With .AddNewChildren(FakeCtl_Form, 40, 80, 560, 440, &HFF20FF, , False, , "Form1234°¡°¢")
  .Show
  With .AddNewChildren(FakeCtl_None, 0, 0, 800, 600)
  '///
  .AddNewChildren FakeCtl_Button, 0, 0, 78, 16, FBS_CheckBox Or FCS_CanGetFocus Or FCS_TabStop, , , , "Enabled", , "Check1", , , , , 1
  .AddNewChildren FakeCtl_Button, 0, 16, 78, 32, FBS_CheckBoxTristate Or FCS_CanGetFocus Or FCS_TabStop, , , , "Check2", , "Check2"
  .AddNewChildren FakeCtl_Button, 0, 32, 78, 48, FCS_CanGetFocus Or FCS_TabStop, , , , "Danger!!!", , "cmdDanger"
  '///scrollbar test
  With .AddNewChildren(FakeCtl_ScrollBar, 240, 8, 400, 24, FCS_CanGetFocus Or FCS_TabStop Or FSS_Slider, , , , , , "Slider1")
   .Max = 100
   .LargeChange = 10
  End With
  With .AddNewChildren(FakeCtl_ScrollBar, 408, 8, 424, 80, FCS_CanGetFocus Or FCS_TabStop Or FSS_Slider)
   .Orientation = 1
   .Max = 10
   .LargeChange = 0
  End With
  With .AddNewChildren(FakeCtl_ProgressBar, 240, 32, 400, 48, , , , , , , "Progress1")
   .Max = 100
  End With
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
Set FakeDXUIEvent = objEventCallback
End Sub

