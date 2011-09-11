Attribute VB_Name = "mdlMain"
Option Explicit

#Const UseSubclassInIDE = False
#Const VideoCaptureEnabled = True
#Const SVN = True

#If SVN Then
Public Const FakeDXAppVersion As String = "SVN"
#Else
Public Const FakeDXAppVersion As String = "0.0.1-2 (SVN r217)"
#End If

'Private Declare Function GetStdHandle Lib "kernel32.dll" (ByVal nStdHandle As Long) As Long
'Private Declare Function AllocConsole Lib "kernel32.dll" () As Long
'Private Declare Function FreeConsole Lib "kernel32.dll" () As Long
'Private Declare Function WriteFile Lib "kernel32.dll" (ByVal hFile As Long, ByRef lpBuffer As Any, ByVal nNumberOfBytesToWrite As Long, ByRef lpNumberOfBytesWritten As Long, ByRef lpOverlapped As Any) As Long
'Private Const STD_ERROR_HANDLE As Long = -12&

'Public m_hStdErr As Long

Private Declare Function SHGetSpecialFolderPath Lib "shell32.dll" Alias "SHGetSpecialFolderPathA" (ByVal hwnd As Long, ByVal pszPath As String, ByVal csidl As Long, ByVal fCreate As Long) As Long
Private Declare Function SHCreateDirectory Lib "shell32.dll" (ByVal hwnd As Long, ByVal pszPath As Long) As Long

Private Const CSIDL_PERSONAL As Long = &H5
Private Const CSIDL_DESKTOP As Long = &H0
Private Const CSIDL_DESKTOPDIRECTORY As Long = &H10

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)
Private Declare Sub Sleep Lib "kernel32.dll" (ByVal dwMilliseconds As Long)

Private Declare Function GetActiveWindow Lib "user32.dll" () As Long
Private Declare Function GetAsyncKeyState Lib "user32.dll" (ByVal vKey As Long) As Integer

Private Declare Function IsIconic Lib "user32.dll" (ByVal hwnd As Long) As Long
Private Declare Function IsWindow Lib "user32.dll" (ByVal hwnd As Long) As Long

Private Declare Function GetWindowLong Lib "user32.dll" Alias "GetWindowLongA" (ByVal hwnd As Long, ByVal nIndex As Long) As Long
Private Declare Function SetWindowLong Lib "user32.dll" Alias "SetWindowLongA" (ByVal hwnd As Long, ByVal nIndex As Long, ByVal dwNewLong As Long) As Long
Private Declare Function CallWindowProc Lib "user32.dll" Alias "CallWindowProcA" (ByVal lpPrevWndFunc As Long, ByVal hwnd As Long, ByVal msg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
Private Declare Function SetWindowPos Lib "user32.dll" (ByVal hwnd As Long, ByVal hWndInsertAfter As Long, ByVal x As Long, ByVal y As Long, ByVal cx As Long, ByVal cy As Long, ByVal wFlags As Long) As Long
Private Const SWP_NOMOVE As Long = &H2
Private Const SWP_NOZORDER As Long = &H4
Private Const SWP_NOACTIVATE As Long = &H10
Private Const GWL_STYLE As Long = -16
Private Const GWL_EXSTYLE As Long = -20
Private Const GWL_WNDPROC As Long = -4
Private Declare Function AdjustWindowRectEx Lib "user32.dll" (ByRef lpRect As RECT, ByVal dwStyle As Long, ByVal bMenu As Long, ByVal dwExStyle As Long) As Long
Private Type RECT
    Left As Long
    Top As Long
    Right As Long
    Bottom As Long
End Type

Private Declare Function GetCursorPos Lib "user32.dll" (ByRef lpPoint As POINTAPI) As Long
Private Declare Function ScreenToClient Lib "user32.dll" (ByVal hwnd As Long, ByRef lpPoint As POINTAPI) As Long
Private Type POINTAPI
    x As Long
    y As Long
End Type

Private Const WM_INPUTLANGCHANGE As Long = &H51
Private Const WM_IME_COMPOSITION As Long = &H10F
Private Const WM_IME_STARTCOMPOSITION As Long = &H10D
Private Const WM_IME_ENDCOMPOSITION As Long = &H10E
Private Const WM_IME_NOTIFY As Long = &H282
Private Const WM_MOUSEWHEEL As Long = &H20A

Public d3d9 As Direct3D9
Public d3dd9 As Direct3DDevice9

Public d3dpp As D3DPRESENT_PARAMETERS, m_nRefreshRate As Long
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

Public m_nMaxFPS As Long, m_bMaxFPSEnabled As Boolean, m_bShowFPS As Boolean
Public objTiming As New clsTiming

Public FakeDXAppMyGamesPath As String

Public FakeDXAppRequestUnload As Boolean, FakeDXAppCanUnload As Boolean

Public FakeDXAppMainLoopCallback As IMainLoopCallback

Public objLogger As New clsFakeDXUILogger

'////////not-so-stable but DEP friendly subclass

Private m_lpPrevWndProc As Long

'////////receives unprocessed window event

Public FakeDXAppEvent As IFakeDXAppEvent

Public Const FakeDXAppEvent_Click As Long = 1
Public Const FakeDXAppEvent_DblClick As Long = 2
Public Const FakeDXAppEvent_MouseMove As Long = 3
Public Const FakeDXAppEvent_MouseDown As Long = 4
Public Const FakeDXAppEvent_MouseUp As Long = 5
Public Const FakeDXAppEvent_MouseWheel As Long = 6
Public Const FakeDXAppEvent_KeyPress As Long = &H101
Public Const FakeDXAppEvent_KeyDown As Long = &H102
Public Const FakeDXAppEvent_KeyUp As Long = &H103

'////////test

Public FakeDXAppRootObject As IRenderableObject

'default camera
Public objCamera As New clsCamera

'test
Public objTest As D3DXMesh

Public objTextMgr As New clsTextureManager
Public objRenderTest As New clsRenderPipeline
Public objLand As New clsRenderLandscape, objLandTexture As Direct3DTexture9

Public objTexture As Direct3DTexture9, objNormalTexture As Direct3DTexture9

Public objSkyTexture As Direct3DTexture9 'TEST ONLY

Public objFontSprite As D3DXSprite
Public objFont As D3DXFont

Public objEffectMgr As New clsEffectManager

Public FakeDXAppTriangleCount As Long

'////////

Public FakeDXAppShaderAvaliable As Boolean, FakeDXAppShaderEnabled As Boolean, FakeDXAppShaderEnabled_New As Boolean

'////////game UI objects

Public objMainMenu As New clsMainMenu
Public objGame As New clsGameGUI

'////////

Public objFileMgr As New clsFileManager
Public objMeshMgr As New clsMeshManager
Public objGameMgr As New clsGameManager

'////////settings
Public frmSettings As New frmSettings

#If VideoCaptureEnabled Then
Public Const FakeDXAppVideoCaptureEnabled As Boolean = True

Private Declare Function MessageBeep Lib "user32.dll" (ByVal wType As Long) As Long

Public frmVideo As New frmVideoOptions
Public m_bRecordingVideo As Boolean
#Else
Public Const FakeDXAppVideoCaptureEnabled As Boolean = False
#End If

'////////about

Public frmAbout As New frmAbout

'////////some dirty code

Private Declare Function GetModuleHandle Lib "kernel32.dll" Alias "GetModuleHandleA" (ByVal lpModuleName As String) As Long
Private Declare Function GetProcAddress Lib "kernel32.dll" (ByVal hModule As Long, ByVal lpProcName As String) As Long
Private Declare Function VirtualProtect Lib "kernel32.dll" (ByRef lpAddress As Any, ByVal dwSize As Long, ByVal flNewProtect As Long, ByRef lpflOldProtect As Long) As Long
Private Declare Function VirtualQuery Lib "kernel32.dll" (ByRef lpAddress As Any, ByRef lpBuffer As MEMORY_BASIC_INFORMATION, ByVal dwLength As Long) As Long
Private Type MEMORY_BASIC_INFORMATION
    BaseAddress As Long
    AllocationBase As Long
    AllocationProtect As Long
    RegionSize As Long
    State As Long
    Protect As Long
    lType As Long
End Type

Private Const PAGE_EXECUTE_READ As Long = &H20
Private Const PAGE_EXECUTE_READWRITE As Long = &H40

Public Sub DirtyCode()
Dim tMBI As MEMORY_BASIC_INFORMATION, i As Long
Dim ThePointer As Long
Static bHooked As Boolean
If Not bHooked Then
 If App.LogMode = 1 Then
  ThePointer = GetProcAddress(GetModuleHandle("msvbvm60.dll"), "__vbaFailedFriend")
  '///
  VirtualQuery ByVal ThePointer, tMBI, Len(tMBI)
  VirtualProtect ByVal tMBI.BaseAddress, tMBI.RegionSize, PAGE_EXECUTE_READWRITE, i
  CopyMemory ByVal ThePointer, &HC3&, 1&
  VirtualProtect ByVal tMBI.BaseAddress, tMBI.RegionSize, PAGE_EXECUTE_READ, i
  '///
  bHooked = True
 End If
End If
End Sub

'Public Sub DirtyCode2()
'Dim tMBI As MEMORY_BASIC_INFORMATION, i As Long
'Dim ThePointer As Long
'Static bHooked As Boolean
'If Not bHooked Then
' If App.LogMode = 1 Then
'  ThePointer = GetProcAddress(GetModuleHandle("user32.dll"), "MessageBoxIndirectA")
'  '///
'  VirtualQuery ByVal ThePointer, tMBI, Len(tMBI)
'  VirtualProtect ByVal tMBI.BaseAddress, tMBI.RegionSize, PAGE_EXECUTE_READWRITE, i
'  CopyMemory ByVal ThePointer, &H90CC&, 2&
'  VirtualProtect ByVal tMBI.BaseAddress, tMBI.RegionSize, PAGE_EXECUTE_READ, i
'  '///
'  bHooked = True
' End If
'End If
'End Sub

Public Sub FakeDXAppShowVideoCaptureOptions()
#If VideoCaptureEnabled Then
frmVideo.Show
#End If
End Sub

Public Sub CreateVertexDeclaration()
ReDim m_tDefVertexDecl(0 To 63)
m_tDefVertexDecl(0) = D3DVertexElementCreate(, 0, D3DDECLTYPE_FLOAT3, , D3DDECLUSAGE_POSITION)
m_tDefVertexDecl(1) = D3DVertexElementCreate(, 12&, D3DDECLTYPE_FLOAT3, , D3DDECLUSAGE_NORMAL)
m_tDefVertexDecl(2) = D3DVertexElementCreate(, 24&, D3DDECLTYPE_FLOAT3, , D3DDECLUSAGE_BINORMAL)
m_tDefVertexDecl(3) = D3DVertexElementCreate(, 36&, D3DDECLTYPE_FLOAT3, , D3DDECLUSAGE_TANGENT)
m_tDefVertexDecl(4) = D3DVertexElementCreate(, 48&, D3DDECLTYPE_D3DCOLOR, , D3DDECLUSAGE_COLOR)
m_tDefVertexDecl(5) = D3DVertexElementCreate(, 52&, D3DDECLTYPE_D3DCOLOR, , D3DDECLUSAGE_COLOR, 1)
m_tDefVertexDecl(6) = D3DVertexElementCreate(, 56&, D3DDECLTYPE_FLOAT2, , D3DDECLUSAGE_TEXCOORD)
m_tDefVertexDecl(7) = D3DDECL_END '64 bytes
End Sub

Public Sub FakeDXAppMainLoop(Optional ByVal objCallback As IMainLoopCallback, Optional ByVal bRunOnce As Boolean)
Dim b As Byte
Do Until d3dd9 Is Nothing
 '///process key event
 FakeDXAppProcessKeyEvent
 '///
 objTiming.WaitForNextFrame
 FakeDXAppRender
 DoEvents
 '///
 If bRunOnce Then Exit Do
 If FakeDXAppRequestUnload Then Exit Do
 '///
 If Not objCallback Is Nothing Then
  If objCallback.Cancel Then Exit Do
 ElseIf Not FakeDXAppMainLoopCallback Is Nothing Then
  If FakeDXAppMainLoopCallback.Cancel Then Exit Do
 End If
Loop
End Sub

Public Sub FakeDXAppProcessKeyEvent()
Dim dx As Single, dz As Single
If GetActiveWindow = d3dpp.hDeviceWindow Then
 If FakeDXUIActiveWindow = 0 Then
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
 #If VideoCaptureEnabled Then
 If GetAsyncKeyState(vbKeyF8) = &H8001 Then
  If frmVideo.BeginRecording Then
   m_bRecordingVideo = Not m_bRecordingVideo
   If m_bRecordingVideo Then
    MessageBeep vbInformation
   Else
    frmMain.Caption = objText.GetText("Video capture paused")
    MessageBeep 0
   End If
  Else
   With New clsFakeDXUIMsgBox
    .MsgBox objText.GetText("Failed to begin video capture"), vbCritical, objText.GetText("Error")
   End With
  End If
 ElseIf GetAsyncKeyState(vbKeyF9) = &H8001 Then
  If GetAsyncKeyState(vbKeyControl) And &H8000& Then
   FakeDXAppShowVideoCaptureOptions
  Else
   If frmVideo.BeginRecording Then
    frmVideo.EndRecording
    frmMain.Caption = objText.GetText("Turning Polyhedron")
    MessageBeep vbInformation
   End If
   m_bRecordingVideo = False
  End If
 End If
 #End If
 If GetAsyncKeyState(vbKeyF11) = &H8001 Then
  m_bShowFPS = Not m_bShowFPS
 End If
End If
End Sub

Public Sub FakeDXAppRender()
On Local Error Resume Next
'///
Dim i As Long
Dim mat As D3DMATRIX, mat1 As D3DMATRIX, mat2 As D3DMATRIX
Dim r(3) As Long
Dim f(3) As Single
Dim s As String
'///
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
  '///init (if first time run this sub or after device reset
  FakeDXAppOnInitalize
  '///reset counter
  MyMini_IndexCount = 0
  MyMini_FogIndexCount = 0
  FakeDXAppTriangleCount = 0
  '///
  If FakeDXAppRootObject Is Nothing Then
   '??? nothing to render
   .Clear 0, ByVal 0, D3DCLEAR_TARGET Or D3DCLEAR_ZBUFFER Or D3DCLEAR_STENCIL, &HFF000000, 1, 0
   'show something ridiculous
   .BeginScene
   FakeDXGDIDrawText FakeDXUIDefaultFont, "Nothing to render", 0, 0, d3dpp.BackBufferWidth, d3dpp.BackBufferHeight, , _
   DT_CENTER Or DT_VCENTER Or DT_SINGLELINE Or DT_NOCLIP, , , , , , , , True
   .EndScene
  Else
   '///
   objCamera.Apply objRenderTest
   '///
   objRenderTest.SetDepthOfFieldParams objCamera.RealDistance, 0.01, 0.1, 40
   '///shadow map
   FakeDXAppRootObject.Render RenderPass_ShadowMap, False, False
   '///
   FakeDXAppRootObject.Render RenderPass_Main, False, False
'   objRenderTest.BeginRenderToPostProcessTarget
'   If bTestOnly Then
'    objGameMgr.UpdateLevelRuntimeData objTiming.GetDelta
'    .BeginScene
'    '///TEST TEST TEST
'    objGameMgr.DrawLevel
'    '////////draw landscape
'    d3dd9.SetTexture 0, objLandTexture
'    objLand.Render objRenderTest, objCamera
'    '////////
'    .EndScene
'   Else
'    objRenderTest.SetTexture objTexture
'    objRenderTest.SetNormalTexture objNormalTexture
'    If objRenderTest.BeginRender(RenderPass_Main) Then
'     .BeginScene
'     objTest.DrawSubset 0
'     objRenderTest.EndRender 'xx
'     '////////draw landscape test (new and buggy) TODO:shouldn't use advanced shading effects
'     d3dd9.SetTexture 0, objLandTexture
'     objLand.Render objRenderTest, objCamera
'     '////////
'     .EndScene
'    End If
'   End If
'   objRenderTest.EndRenderToPostProcessTarget
   '////////volumetric fog test
   FakeDXAppRootObject.Render RenderPass_FogVolume, False, False
'   If objRenderTest.BeginRender(RenderPass_FogVolume) Then
'    D3DXMatrixScaling mat1, 5, 5, 5
'    D3DXMatrixMultiply mat2, mat1, mat
'    .SetTransform D3DTS_WORLD, mat2
'    objRenderTest.UpdateRenderState '???
'    .Clear 0, ByVal 0, D3DCLEAR_TARGET Or D3DCLEAR_ZBUFFER Or D3DCLEAR_STENCIL, 0, 1, 0
'    .BeginScene
'    objTest.DrawSubset 0
'    .EndScene
'    objRenderTest.EndRender
'    .SetTransform D3DTS_WORLD, mat
'   End If
   '////////perform post process
   objRenderTest.PerformPostProcess
  End If
  '////////draw overlay
  .BeginScene
  '///custom overlay (order?)
  If Not FakeDXAppRootObject Is Nothing Then
   FakeDXAppRootObject.Render RenderPass_Overlay, False, True
  End If
  '///UI
  FakeDXUIRender
  '///logger
  objLogger.Render 8, 80, d3dpp.BackBufferWidth - 8, d3dpp.BackBufferHeight - 64
  '///
  .EndScene
  '///overlay text
  If m_bShowFPS Then
'   s = "FPS:" + Format(objTiming.FPS, "0.0") + vbCrLf + _
'   "Landscape Triangles:" + CStr(MyMini_IndexCount) + vbCrLf + _
'   "Fog Triangles:" + CStr(MyMini_FogIndexCount)
   s = objText.GetText("FPS: ") + Format(objTiming.FPS, "0.0") + vbCrLf + _
   objText.GetText("Triangles: ") + CStr(FakeDXAppTriangleCount)
   FakeDXGDIDrawText FakeDXUIDefaultFont, s, d3dpp.BackBufferWidth - 128, 16, 128, 64, 0.5, DT_NOCLIP, -1, , &HFF000000, , , , , True
  End If
  '////////over
  .Present ByVal 0, ByVal 0, 0, ByVal 0
  '///
  #If VideoCaptureEnabled Then
  If m_bRecordingVideo Then
   frmVideo.RecordFrame
   frmMain.Caption = objText.GetText("Video capture started, video size: ") + _
   Format(frmVideo.RecordFileSize / 1048576, "0.00") + "MB"
  End If
  #End If
 End If
End With
End Sub

Public Sub FakeDXAppOnLostDevice()
objRenderTest.OnLostDevice
objTextMgr.OnLostDevice
objFontSprite.OnLostDevice
objFont.OnLostDevice
objEffectMgr.OnLostDevice
End Sub

Public Sub FakeDXAppOnInitalize(Optional ByVal bReset As Boolean)
Static bInit As Boolean
Const nSize As Long = 512
'If bReset Then bInit = False Else _
'If bInit Then Exit Sub
'///
If bReset Then
 objRenderTest.OnResetDevice
 objTextMgr.OnResetDevice
 objFontSprite.OnResetDevice
 objFont.OnResetDevice
 objEffectMgr.OnResetDevice
 '///
 FakeDXAppSetDefaultRenderState
 '///
End If
If bInit Then Exit Sub
If Not FakeDXAppShaderEnabled Then Exit Sub
'///modified: generate texture and copy to managed memory pool (slow?)
'D3DXCreateTexture d3dd9, nSize, nSize, 0, D3DUSAGE_RENDERTARGET Or D3DUSAGE_AUTOGENMIPMAP, D3DFMT_A8R8G8B8, 0, objTexture
'D3DXCreateTexture d3dd9, nSize, nSize, 1, D3DUSAGE_RENDERTARGET Or D3DUSAGE_AUTOGENMIPMAP, D3DFMT_A8R8G8B8, 0, objNormalTexture
'///
Dim obj As Direct3DTexture9
Dim obj2 As Direct3DTexture9
'///
D3DXCreateTexture d3dd9, nSize, nSize, 1, D3DUSAGE_RENDERTARGET, D3DFMT_R32F, 0, obj
D3DXCreateTexture d3dd9, nSize, nSize, 1, D3DUSAGE_RENDERTARGET, D3DFMT_R32F, 0, obj2
objTextMgr.ProcessTextureEx Nothing, obj, "process_lerp", 0, 0, 0, 0, Vec4(-1024), Vec4(-1024), Vec4, Vec4
objTextMgr.BeginRenderToTexture obj, "gen_simplexnoise", 6, 0, 0, 0, Vec4(1, 1, 0.86, 1.85), Vec4, Vec4, Vec4
d3dd9.BeginScene
objTest.DrawSubset 0
d3dd9.EndScene
objTextMgr.EndRenderToTexture
'///expand texture to eliminate seal
objTextMgr.ProcessTexture obj, obj2, "expand8_r32f"
objTextMgr.ProcessTexture obj2, obj, "expand8_r32f"
'///
objTextMgr.ProcessTextureEx obj, obj2, "process_smoothstep", 0, 0, 0, 0, Vec4(-1, 1, 0, 1), Vec4, Vec4, Vec4
Set obj = Nothing
'///
D3DXCreateTexture d3dd9, nSize, nSize, 1, D3DUSAGE_RENDERTARGET, D3DFMT_A8R8G8B8, 0, obj
D3DXCreateTexture d3dd9, nSize, nSize, 0, D3DUSAGE_AUTOGENMIPMAP, D3DFMT_A8R8G8B8, D3DPOOL_MANAGED, objTexture
D3DXCreateTexture d3dd9, nSize, nSize, 1, D3DUSAGE_AUTOGENMIPMAP, D3DFMT_A8R8G8B8, D3DPOOL_MANAGED, objNormalTexture
objTextMgr.ProcessTextureEx obj2, obj, "process_lerp", 0, 0, 0, 0, Vec4(44 / 255, 36 / 255, 35 / 255, 1), Vec4(211 / 255, 120 / 255, 93 / 255, 1), Vec4, Vec4
CopyRenderTargetData obj, objTexture
'///
objTextMgr.ProcessTextureEx obj2, obj, "normal_map", 0, 0, 0, 0, Vec4(0.25, 0.25, 0, 1), Vec4, Vec4, Vec4
CopyRenderTargetData obj, objNormalTexture
Set obj = Nothing
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

Public Sub FakeDXAppChangeResolution(Optional ByVal nWidth As Long, Optional ByVal nHeight As Long, Optional ByVal bFullscreen As VbTriState = vbUseDefault, Optional ByVal nRefreshRate As Long = -1, Optional ByVal nMultiSample As Long = -1, Optional ByVal nPresentationInterval As Long = -1)
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
If nRefreshRate <= 0 Then nRefreshRate = m_nRefreshRate _
Else m_nRefreshRate = nRefreshRate
If bFullscreen = 0 Then nRefreshRate = 0
If nMultiSample < 0 Then nMultiSample = d3dpp.MultiSampleType
If nPresentationInterval = -1 Then nPresentationInterval = d3dpp.PresentationInterval
'///
If nWidth <> d3dpp.BackBufferWidth Or nHeight <> d3dpp.BackBufferHeight _
Or d3dpp.Windowed <> 1 - bFullscreen _
Or nRefreshRate <> d3dpp.FullScreen_RefreshRateInHz _
Or nMultiSample <> d3dpp.MultiSampleType _
Or nPresentationInterval <> d3dpp.PresentationInterval _
Then
 '///
 With d3dpp
  .BackBufferWidth = nWidth
  .BackBufferHeight = nHeight
  .Windowed = 1 - bFullscreen
  .FullScreen_RefreshRateInHz = nRefreshRate
  .MultiSampleType = nMultiSample
  .PresentationInterval = nPresentationInterval
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
objRenderTest.SetProjection_PerspectiveFovLH , d3dpp.BackBufferWidth / d3dpp.BackBufferHeight, 0.1, 1000
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
objEffectMgr.Destroy
objMeshMgr.Destroy
'///
Set FakeDXAppMainLoopCallback = Nothing
Set FakeDXAppEvent = Nothing
'///
Set objLand = Nothing
Set objLandTexture = Nothing
Set objTextMgr = Nothing
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
'FakeDXAppEndLog
'///
End Sub

Public Sub FakeDXAppUnSubclass()
If m_lpPrevWndProc Then
 SetWindowLong d3dpp.hDeviceWindow, GWL_WNDPROC, m_lpPrevWndProc
 m_lpPrevWndProc = 0
End If
End Sub

Private Function FakeDXAppWndProc(ByVal hwnd As Long, ByVal uMsg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
Dim i As Long
Dim p As POINTAPI
'///
If m_lpPrevWndProc Then FakeDXAppWndProc = CallWindowProc(m_lpPrevWndProc, hwnd, uMsg, wParam, lParam)
'///
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
 ScreenToClient hwnd, p
 FakeDXAppOnMouseWheel (wParam And 3&) Or (vbMiddleButton And ((wParam And &H10&) <> 0)), _
 ((wParam And &HC&) \ 4&) Or (vbAltMask And ((GetAsyncKeyState(vbKeyMenu) And &H8000&) <> 0)), p.x, p.y, i \ 120&
End Select
End Function

Private Sub FakeDXAppOnMouseWheel(ByVal Button As MouseButtonConstants, ByVal Shift As ShiftConstants, ByVal x As Long, ByVal y As Long, ByVal nDelta As Long)
If FakeDXUIOnMouseWheel(nDelta, Shift) Then Exit Sub
If Not FakeDXAppEvent Is Nothing Then FakeDXAppEvent.OnEvent FakeDXAppEvent_MouseWheel, nDelta, Shift, 0
End Sub

Public Sub FakeDXAppInit(ByVal frm As Form)
On Error Resume Next
Dim i As Long
Dim s As String
Dim obj As clsTreeStorageNode
'///
DirtyCode
'If Dir(App.Path + "\hook.txt") <> "" Then DirtyCode2
'///
Randomize Timer
'///init logger
objLogger.CreateNew , , , DT_NOCLIP
'///
FakeDXAppMyGamesPath = Space(1024)
SHGetSpecialFolderPath 0, FakeDXAppMyGamesPath, CSIDL_PERSONAL, 1
FakeDXAppMyGamesPath = Left(FakeDXAppMyGamesPath, InStr(1, FakeDXAppMyGamesPath, vbNullChar) - 1) + "\My Games\Turning Polyhedron\"
SHCreateDirectory 0, StrPtr(FakeDXAppMyGamesPath)
'///init file manager
objFileMgr.AddPath App.Path + "\data\|" + FakeDXAppMyGamesPath
'///load config
frmSettings.FileName = FakeDXAppMyGamesPath + "config.xml"
frmSettings.LoadFile
'///init timer
objTiming.AverageFPSEnabled = True
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
 .hDeviceWindow = frm.hwnd
 .SwapEffect = D3DSWAPEFFECT_DISCARD
 .BackBufferCount = 1
 .BackBufferFormat = D3DFMT_X8R8G8B8
 '.BackBufferWidth = 640 'already loaded
 '.BackBufferHeight = 480 'already loaded
 .EnableAutoDepthStencil = 1
 .AutoDepthStencilFormat = D3DFMT_D24S8
 '.PresentationInterval = D3DPRESENT_INTERVAL_ONE 'already loaded
 '.MultiSampleType = D3DMULTISAMPLE_4_SAMPLES 'already loaded
End With
'///
FakeDXAppAdjustWindowPos
'///get device caps
d3d9.GetDeviceCaps 0, D3DDEVTYPE_HAL, d3dc9
i = 0
If d3dc9.DevCaps And D3DDEVCAPS_HWTRANSFORMANDLIGHT Then
 If (d3dc9.VertexShaderVersion And &HFFFF&) >= &H200& Then
  i = D3DCREATE_HARDWARE_VERTEXPROCESSING
 End If
End If
If i = 0 Then
 i = D3DCREATE_SOFTWARE_VERTEXPROCESSING '<-- ??? something goes wrong
 d3dc9.VertexShaderVersion = 0
End If
'shader version, etc.
FakeDXAppShaderAvaliable = (d3dc9.VertexShaderVersion And &HFFFF&) >= &H300& And (d3dc9.PixelShaderVersion And &HFFFF&) >= &H300&
If FakeDXAppShaderEnabled And Not FakeDXAppShaderAvaliable Then
 MsgBox objText.GetText("Your video card or video card driver is unsupported.") _
 + vbCrLf + objText.GetText("Advanced graphical effects will be disabled."), vbExclamation, _
 objText.GetText("Error")
 FakeDXAppShaderEnabled = False
 FakeDXAppShaderEnabled_New = False
 frmSettings.SaveFile
End If
'///create device
Set d3dd9 = d3d9.CreateDevice(0, D3DDEVTYPE_HAL, frm.hwnd, i, d3dpp)
If d3dd9 Is Nothing Then
 MsgBox objText.GetText("Can't create device!!!"), vbExclamation, objText.GetText("Fatal Error")
 frmSettings.ResetAndSaveFile
 End
End If
'///
On Error GoTo 0
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
objTextMgr.Create
objRenderTest.Create
'///vertex declaration test
CreateVertexDeclaration
'///
FakeDXAppSetDefaultRenderState
'////////test
Set objTest = pLoadMeshTest
'///
FakeDXAppCreateUI
'///
objRenderTest.SetLightDirectionByVal 0, 4, 2.5, True
objRenderTest.SetLightPosition Vec4(0, 8, 5, 0)
objRenderTest.SetLightType D3DLIGHT_DIRECTIONAL
'objRenderTest.SetLightType D3DLIGHT_POINT
'objCamera.SetCamrea Vec3(6, 2, 3), Vec3, Vec3(, , 1), True
objCamera.SetCamrea Vec3(-3, 9, 6), Vec3, Vec3(, , 1), True
objCamera.AnimationEnabled = True
objCamera.LinearDamping = 0.5
objCamera.DampingOfDamping = 0.9
'objRenderTest.CreateShadowMap 1024 'new
'objRenderTest.SetShadowState True, Atn(1), 0.1, 20   'point
'objRenderTest.SetShadowState True, 16, -100, 100  'directional
objRenderTest.SetFloatParams Vec4(0.5, 0.5, 0.5, 0.5), 50, -0.5, 0.02
objRenderTest.OrenNayarRoughness = 0
'////////new:subclass
#If UseSubclassInIDE Then
If True Then
#Else
If App.LogMode = 1 Then
#End If
 If m_lpPrevWndProc = 0 Then
  m_lpPrevWndProc = GetWindowLong(frm.hwnd, GWL_WNDPROC)
  SetWindowLong frm.hwnd, GWL_WNDPROC, AddressOf FakeDXAppWndProc
 End If
End If
'///load data
With New clsXMLSerializer
 '////////load default effects
 i = objFileMgr.LoadFile("DefaultShaders.xml")
 If i > 0 Then
  Set obj = New clsTreeStorageNode
  If .ReadNode(objFileMgr.FilePointer(i), objFileMgr.FileSize(i), obj) Then _
  objEffectMgr.LoadEffectsFromSubNodes obj
 End If
 '////////load default object types
 i = objFileMgr.LoadFile("DefaultObjectTypes.xml")
 If i > 0 Then
  Set obj = New clsTreeStorageNode
  If .ReadNode(objFileMgr.FilePointer(i), objFileMgr.FileSize(i), obj) Then _
  objGameMgr.LoadObjectTypesFromSubNodes obj
 End If
 '////////load default tile types
 i = objFileMgr.LoadFile("DefaultTileTypes.xml")
 If i > 0 Then
  Set obj = New clsTreeStorageNode
  If .ReadNode(objFileMgr.FilePointer(i), objFileMgr.FileSize(i), obj) Then _
  objGameMgr.LoadTileTypesFromSubNodes obj
 End If
End With
''////////TEST TEST TEST load appearance, and add instance (software and hardware), and draw
'Dim obj As New clsTreeStorageNode
'Dim j As Long, k As Long, lp As Long
'Dim mat() As D3DMATRIX
'ReDim mat(1 To 100)
''---
'With New clsXMLSerializer
' .LoadNodeFromFile App.Path + "\data\test.xml", obj
'End With
'i = objEffectMgr.AddAppearanceFromNode(obj)
'If i > 0 Then
' '---software
' lp = 1
' For j = -5 To 4
'  For k = -5 To 4
'   D3DXMatrixRotationYawPitchRoll mat(lp), j * -0.1, k * 0.1, 0
'   mat(lp).m41 = j
'   mat(lp).m42 = k
'   objEffectMgr.AddInstanceFromAppearance i, mat(lp)
'   mat(lp).m43 = 3
'   lp = lp + 1
'  Next k
' Next j
' '---hardware
' objEffectMgr.AddHWInstanceFromAppearance objMeshMgr, i, mat, 1, 100
'End If
'////////landscape test
Dim t As D3DXIMAGE_INFO
objLand.CreateFromFile App.Path + "\heightmap_test.png", , , 0.25, , , -25
'objLand.CreateFromFile App.Path + "\heightmap_test.png", 3, 5, 0.05, , , -15, App.Path + "\fogmap_test.png", 3, 0.05, 2
'objLand.FogEnabled = True
D3DXCreateTextureFromFileExW d3dd9, App.Path + "\test0.png", D3DX_DEFAULT, D3DX_DEFAULT, 1, 0, D3DFMT_FROM_FILE, D3DPOOL_MANAGED, D3DX_DEFAULT, D3DX_DEFAULT, 0, t, ByVal 0, objLandTexture
'////////TEST ONLY
D3DXCreateTextureFromFileExW d3dd9, App.Path + "\data\gfx\sky7.jpg", D3DX_DEFAULT, D3DX_DEFAULT, 1, 0, D3DFMT_FROM_FILE, D3DPOOL_MANAGED, D3DX_DEFAULT, D3DX_DEFAULT, 0, t, ByVal 0, objSkyTexture
'////////set caption
frm.Caption = objText.GetText("Turning Polyhedron")
'////////show first game UI
objMainMenu.Show
'TODO:etc.
End Sub

Public Sub FakeDXAppChangeRootObject(ByVal nFlags As Long, Optional ByVal objAppEvent As IFakeDXAppEvent, Optional ByVal objRoot As IRenderableObject, Optional ByVal objCallback As IMainLoopCallback, Optional ByVal objUIEvent As IFakeDXUIEvent)
If nFlags And 1& Then
 Set FakeDXAppEvent = objAppEvent
End If
If nFlags And 2& Then
 If Not FakeDXAppRootObject Is objRoot Then
  If Not FakeDXAppRootObject Is Nothing Then FakeDXAppRootObject.Hide
  Set FakeDXAppRootObject = objRoot
  'If Not objRoot Is Nothing Then objRoot.Show '???
 End If
End If
If nFlags And 4& Then
 Set FakeDXAppMainLoopCallback = objCallback
End If
If nFlags And 8& Then
 Set FakeDXUIEvent = objUIEvent
End If
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

Public Sub FakeDXAppCreateUI()
FakeDXUICreate 0, 0, d3dpp.BackBufferWidth, d3dpp.BackBufferHeight
End Sub

Public Function FakeDXUtilReadVec4(ByVal s As String, ByRef t As D3DXVECTOR4) As Boolean
Dim v As Variant, i As Long
Dim f(3) As Double
'///
v = Split(s, ",")
For i = 0 To UBound(v)
 s = Trim(v(i))
 f(i) = Val(s)
 If LCase(Right(s, 1)) = "d" Then
  f(i) = f(i) * 1.74532925199433E-02
 End If
 If i >= 3 Then Exit For
Next i
'///
t.x = f(0)
t.y = f(1)
t.z = f(2)
t.w = f(3)
'///
FakeDXUtilReadVec4 = True
End Function

'Public Sub FakeDXAppBeginLog()
'If m_hStdErr = 0 Then
' m_hStdErr = GetStdHandle(STD_ERROR_HANDLE)
' If m_hStdErr = 0 Or m_hStdErr = -1 Then
'  AllocConsole
'  m_hStdErr = GetStdHandle(STD_ERROR_HANDLE)
'  If m_hStdErr = 0 Or m_hStdErr = -1 Then m_hStdErr = 0
' End If
'End If
'End Sub
'
'Public Sub FakeDXAppEndLog()
'If m_hStdErr Then
' FreeConsole
' m_hStdErr = 0
'End If
'End Sub
'
'Public Sub FakeDXAppLog(ByVal s As String)
'If m_hStdErr Then
' s = StrConv(s, vbFromUnicode)
' WriteFile m_hStdErr, ByVal StrPtr(s), LenB(s), 0, ByVal 0
'End If
'End Sub

Public Sub FakeDXAppAddDataLevel(ByVal nDataLevel As Long)
objGameMgr.AddDataLevel nDataLevel
objEffectMgr.AddDataLevel nDataLevel
objTextMgr.AddDataLevel nDataLevel
objMeshMgr.AddDataLevel nDataLevel
objFileMgr.AddDataLevel nDataLevel
End Sub

Public Sub FakeDXAppRemoveDataLevel(ByVal nDataLevel As Long)
objGameMgr.RemoveDataLevel nDataLevel
objEffectMgr.RemoveDataLevel nDataLevel
objTextMgr.RemoveDataLevel nDataLevel
objMeshMgr.RemoveDataLevel nDataLevel
objFileMgr.RemoveDataLevel nDataLevel
End Sub

