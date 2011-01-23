Attribute VB_Name = "mdlMain"
Option Explicit

#Const IsDebug = 1

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)
Private Declare Sub Sleep Lib "kernel32.dll" (ByVal dwMilliseconds As Long)

Private Declare Function GetActiveWindow Lib "user32.dll" () As Long
Private Declare Function GetAsyncKeyState Lib "user32.dll" (ByVal vKey As Long) As Integer

Private Declare Function IsIconic Lib "user32.dll" (ByVal hwnd As Long) As Long
Private Declare Function IsWindow Lib "user32.dll" (ByVal hwnd As Long) As Long

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

Public Sub FakeDXAppChangeResolution(Optional ByVal nWidth As Long, Optional ByVal nHeight As Long, Optional ByVal bFullscreen As VbTriState = vbUseDefault)
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
 FakeDXAppOnLostDevice
 d3dd9.Reset d3dpp
 FakeDXAppOnInitalize True
 '///resize window
 If bFullscreen Then
  SetWindowLong d3dpp.hDeviceWindow, GWL_STYLE, &H160A0000
  SetWindowLong d3dpp.hDeviceWindow, GWL_EXSTYLE, &H40000
 Else
  SetWindowLong d3dpp.hDeviceWindow, GWL_STYLE, &H16CA0000
  SetWindowLong d3dpp.hDeviceWindow, GWL_EXSTYLE, &H40100
  r.Right = nWidth
  r.Bottom = nHeight
  AdjustWindowRectEx r, &H16CA0000, 0, &H40100
  SetWindowPos d3dpp.hDeviceWindow, 0, 0, 0, r.Right - r.Left, r.Bottom - r.Top, SWP_NOMOVE Or SWP_NOZORDER Or SWP_NOACTIVATE
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

