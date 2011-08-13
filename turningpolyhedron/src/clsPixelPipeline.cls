VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsRenderPipeline"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

#Const UseMultiSample = True

Private Const m_nFormat8UC1 As Long = D3DFMT_L8
Private Const m_nFormat8UC3 As Long = D3DFMT_X8R8G8B8
Private Const m_nFormat8UC4 As Long = D3DFMT_A8R8G8B8

Private Const m_nFormat32FC1 As Long = D3DFMT_R32F
Private Const m_nFormat32FC2 As Long = D3DFMT_G32R32F
Private Const m_nFormat32FC4 As Long = D3DFMT_A32B32G32R32F

Private Const m_nFormat1 As Long = D3DFMT_A8R8G8B8

Private objEffect As D3DXEffect

Private m_tLightDir As D3DXVECTOR4, m_tLightPos As D3DXVECTOR4, m_tViewPos As D3DXVECTOR4
Private m_nLightType As Long

#If UseMultiSample Then
Private objFloatTarget As Direct3DSurface9
#End If

Private objOldTarget As Direct3DSurface9
Private objOldTarget_1 As Direct3DSurface9
Private objOldStencil As Direct3DSurface9

Private texNoise As Direct3DTexture9
Private objShadowMap As Direct3DTexture9, objShadowStencil As Direct3DSurface9
Private m_bShadowEnabled As Boolean
Private m_tLightViewProj As D3DMATRIX
Private m_nShadowMapSize As Long

Public Enum enumRenderPassType
 RenderPass_Nothing = 0
 RenderPass_Main = 1
 RenderPass_ShadowMap = &H100&
 RenderPass_FogVolume = &H200&
 RenderPass_Overlay = &H10000
End Enum
Private m_nLastType As Long
'low 24-bit is render pass type
'&H1000000=effect was set up

'////////post process

Private Enum enumPostProcessTargetType
 IDR_Main = 0
 IDR_BlurPass1 'optional
 IDR_BlurPass2 'optional
 IDR_Luminance
 IDR_AverageLuminance
 IDR_VolumetricFogTarget
 IDR_Auxiliary
 IDR_DOF1 'optional
 IDR_DOF2 'optional
End Enum

Private m_bPostProcessEnabled As Boolean
Private objPostProcessTarget(15) As Direct3DTexture9
'HDR
Private m_nHDRBlurQuality As Long
'radial blur
Private m_bRadialBlur As Boolean
'fog
Private m_bFog As Boolean
'volumetric fog
Private m_bVolumeFog As Boolean
'depth of field
Private m_nDOFType As Long

'////////

Private m_fParam(3) As D3DXVECTOR4

Private m_fovy As Single, m_fAspect As Single, m_zn As Single, m_zf As Single
Private m_vZData As D3DXVECTOR4, m_vDistCorrection As D3DXVECTOR4
Private m_vDepthOfField As D3DXVECTOR4

Friend Property Get DepthOfFieldType(Optional ByVal bForceRefresh As Boolean) As Long
DepthOfFieldType = m_nDOFType
End Property

Friend Property Let DepthOfFieldType(Optional ByVal bForceRefresh As Boolean, ByVal n As Long)
If m_nDOFType <> n Or bForceRefresh Then
 m_nDOFType = n
 '///new
 If d3dd9 Is Nothing Then Exit Property
 '///
 Set objPostProcessTarget(IDR_DOF1) = Nothing
 Set objPostProcessTarget(IDR_DOF2) = Nothing
 If m_bPostProcessEnabled And n = 1 Then
  D3DXCreateTexture d3dd9, d3dpp.BackBufferWidth \ 2, d3dpp.BackBufferHeight \ 2, 1, _
  D3DUSAGE_RENDERTARGET, m_nFormat32FC4, D3DPOOL_DEFAULT, objPostProcessTarget(IDR_DOF1)
  D3DXCreateTexture d3dd9, d3dpp.BackBufferWidth \ 2, d3dpp.BackBufferHeight \ 2, 1, _
  D3DUSAGE_RENDERTARGET, m_nFormat32FC4, D3DPOOL_DEFAULT, objPostProcessTarget(IDR_DOF2)
 End If
End If
End Property

Friend Sub SetDepthOfFieldParams(ByVal u0 As Single, ByVal v0 As Single, ByVal f As Single, ByVal r0 As Single)
'current method is fixed f, move v0
m_vDepthOfField.x = r0 * f / (u0 - f)
m_vDepthOfField.y = -u0 * m_vDepthOfField.x
End Sub

Friend Property Get RadialBlurEnabled() As Boolean
RadialBlurEnabled = m_bRadialBlur
End Property

Friend Property Let RadialBlurEnabled(ByVal b As Boolean)
m_bRadialBlur = b
End Property

Friend Property Get FogEnabled() As Boolean
FogEnabled = m_bFog
End Property

Friend Property Let FogEnabled(ByVal b As Boolean)
m_bFog = b
End Property

Friend Property Get VolumetricFogEnabled() As Boolean
VolumetricFogEnabled = m_bVolumeFog
End Property

Friend Property Let VolumetricFogEnabled(ByVal b As Boolean)
m_bVolumeFog = b
'If m_bPostProcessEnabled And b Then
' If objPostProcessTarget(IDR_VolumetricFogTarget) Is Nothing Then
'  '6=volumetric fog target GR=fog far/fog near
'  D3DXCreateTexture d3dd9, d3dpp.BackBufferWidth, d3dpp.BackBufferHeight, 1, D3DUSAGE_RENDERTARGET, D3DFMT_G32R32F, D3DPOOL_DEFAULT, objPostProcessTarget(IDR_VolumetricFogTarget)
' End If
'End If
End Property

Friend Property Get Effect() As D3DXEffect
Set Effect = objEffect
End Property

Friend Property Get PostProcessEnabled() As Boolean
PostProcessEnabled = m_bPostProcessEnabled
End Property

Friend Property Let PostProcessEnabled(ByVal b As Boolean)
If m_bPostProcessEnabled <> b Then
 m_bPostProcessEnabled = b
 CreatePostProcessTarget
End If
End Property

Friend Sub Create(Optional ByVal bPostProcessEnabled As VbTriState = vbUseDefault)
'///
'test
CreateEffect CStr(App.Path) + "\data\shader\pstest.txt", objEffect, , True
'///???
D3DXCreateTextureFromFileW d3dd9, CStr(App.Path) + "\data\gfx\noise.bmp", texNoise
'///
If bPostProcessEnabled <> vbUseDefault Then m_bPostProcessEnabled = bPostProcessEnabled
CreatePostProcessTarget
End Sub

Friend Property Get HDRBlurQuality(Optional ByVal bForceRefresh As Boolean) As Long
HDRBlurQuality = m_nHDRBlurQuality
End Property

Friend Property Let HDRBlurQuality(Optional ByVal bForceRefresh As Boolean, ByVal n As Long)
Dim k As Long
If m_nHDRBlurQuality <> n Or bForceRefresh Then
 m_nHDRBlurQuality = n
 '///new
 If d3dd9 Is Nothing Then Exit Property
 '///
 Set objPostProcessTarget(IDR_BlurPass1) = Nothing
 Set objPostProcessTarget(IDR_BlurPass2) = Nothing
 If m_bPostProcessEnabled Then
  If n <= 0 Then k = 8 _
  Else If n = 1 Then k = 4 _
  Else k = 2
  D3DXCreateTexture d3dd9, d3dpp.BackBufferWidth \ k, d3dpp.BackBufferHeight \ k, 1, D3DUSAGE_RENDERTARGET, m_nFormat1, D3DPOOL_DEFAULT, objPostProcessTarget(IDR_BlurPass1)
  D3DXCreateTexture d3dd9, d3dpp.BackBufferWidth \ k, d3dpp.BackBufferHeight \ k, 1, D3DUSAGE_RENDERTARGET, m_nFormat1, D3DPOOL_DEFAULT, objPostProcessTarget(IDR_BlurPass2)
 End If
End If
End Property

Friend Sub CreatePostProcessTarget()
Erase objPostProcessTarget
#If UseMultiSample Then
Set objFloatTarget = Nothing
#End If
'///new
If d3dd9 Is Nothing Then Exit Sub
'///
'/!\ we need 30M video memory if 1024x768, 80M if 1920x1080 :-3
If m_bPostProcessEnabled Then
 #If UseMultiSample Then
 '///FSAA
 If d3dpp.MultiSampleType > 1 Then
  d3dd9.CreateRenderTarget d3dpp.BackBufferWidth, d3dpp.BackBufferHeight, D3DFMT_A32B32G32R32F, d3dpp.MultiSampleType, 0, 0, objFloatTarget, ByVal 0
 End If
 #End If
 '///
 'main render target BGR=color A=depth (0=0 zf=1)
 D3DXCreateTexture d3dd9, d3dpp.BackBufferWidth, d3dpp.BackBufferHeight, 1, D3DUSAGE_RENDERTARGET, m_nFormat32FC4, _
 D3DPOOL_DEFAULT, objPostProcessTarget(IDR_Main)
 'volumetric fog target
 D3DXCreateTexture d3dd9, d3dpp.BackBufferWidth, d3dpp.BackBufferHeight, 1, D3DUSAGE_RENDERTARGET, m_nFormat32FC2, _
 D3DPOOL_DEFAULT, objPostProcessTarget(IDR_VolumetricFogTarget)
 'auxiliary render target (for volumetric fog+HDR and depth of field)
 D3DXCreateTexture d3dd9, d3dpp.BackBufferWidth, d3dpp.BackBufferHeight, 1, D3DUSAGE_RENDERTARGET, m_nFormat32FC4, _
 D3DPOOL_DEFAULT, objPostProcessTarget(IDR_Auxiliary)
 'DOF
 DepthOfFieldType(True) = m_nDOFType
 'bright-pass
 HDRBlurQuality(True) = m_nHDRBlurQuality
 'luminance
 D3DXCreateTexture d3dd9, 128, 128, 0, D3DUSAGE_RENDERTARGET Or D3DUSAGE_AUTOGENMIPMAP, m_nFormat32FC1, D3DPOOL_DEFAULT, objPostProcessTarget(IDR_Luminance)
 'average luminance
 D3DXCreateTexture d3dd9, 1, 1, 1, D3DUSAGE_RENDERTARGET, m_nFormat32FC1, D3DPOOL_DEFAULT, objPostProcessTarget(IDR_AverageLuminance)
End If
End Sub

Friend Sub SetLightDirection(d As D3DXVECTOR4, Optional ByVal bNormalize As Boolean)
If bNormalize Then
 D3DXVec4Normalize m_tLightDir, d
Else
 m_tLightDir = d
End If
objEffect.SetVector StrPtr(StrConv("lightDir", vbFromUnicode)), m_tLightDir
End Sub

Friend Sub SetLightDirectionByVal(ByVal x As Single, ByVal y As Single, ByVal z As Single, Optional ByVal bNormalize As Boolean)
m_tLightDir.x = x
m_tLightDir.y = y
m_tLightDir.z = z
m_tLightDir.w = 0
If bNormalize Then D3DXVec4Normalize m_tLightDir, m_tLightDir
objEffect.SetVector StrPtr(StrConv("lightDir", vbFromUnicode)), m_tLightDir
End Sub

Friend Sub SetLightPosition(d As D3DXVECTOR4)
objEffect.SetVector StrPtr(StrConv("lightPos", vbFromUnicode)), d
m_tLightPos = d
End Sub

Friend Sub SetViewPosition(d As D3DXVECTOR4)
objEffect.SetVector StrPtr(StrConv("viewPos", vbFromUnicode)), d
m_tViewPos = d
End Sub

Friend Sub SetLightType(ByVal n As D3DLIGHTTYPE)
If n = D3DLIGHT_POINT Then
 m_nLightType = 1
Else
 m_nLightType = 0
End If
objEffect.SetInt StrPtr(StrConv("lightType", vbFromUnicode)), m_nLightType
End Sub

Friend Sub SetTexture(ByVal obj As Direct3DBaseTexture9)
On Error Resume Next
objEffect.SetTexture StrPtr(StrConv("tex0", vbFromUnicode)), obj
End Sub

Friend Sub SetNormalTexture(ByVal obj As Direct3DBaseTexture9)
On Error Resume Next
objEffect.SetTexture StrPtr(StrConv("texNormal", vbFromUnicode)), obj
End Sub

Friend Sub OnLostDevice()
Set objOldTarget = Nothing
Set objOldTarget_1 = Nothing
#If UseMultiSample Then
Set objFloatTarget = Nothing
#End If
Set objOldStencil = Nothing
Set objShadowMap = Nothing
Set objShadowStencil = Nothing
Erase objPostProcessTarget
'///
objEffect.OnLostDevice
End Sub

Friend Sub OnResetDevice()
If m_nShadowMapSize > 0 Then
 D3DXCreateTexture d3dd9, m_nShadowMapSize, m_nShadowMapSize, 1, D3DUSAGE_RENDERTARGET, D3DFMT_R32F, 0, objShadowMap
 d3dd9.CreateDepthStencilSurface m_nShadowMapSize, m_nShadowMapSize, D3DFMT_D24S8, 0, 0, 1, objShadowStencil, ByVal 0
End If
'///
objEffect.OnResetDevice
CreatePostProcessTarget
'TODO:etc.
End Sub

Friend Sub CreateShadowMap(ByVal nSize As Long)
D3DXCreateTexture d3dd9, nSize, nSize, 1, D3DUSAGE_RENDERTARGET, D3DFMT_R32F, 0, objShadowMap
d3dd9.CreateDepthStencilSurface nSize, nSize, D3DFMT_D24S8, 0, 0, 1, objShadowStencil, ByVal 0
m_nShadowMapSize = nSize
End Sub

Friend Sub SetShadowState(ByVal bEnabled As Boolean, Optional ByVal FOVOrViewSize As Single, Optional ByVal zn As Single, Optional ByVal zf As Single)
Dim mat As D3DMATRIX
m_bShadowEnabled = bEnabled
If bEnabled Then
 D3DXMatrixLookAtLH m_tLightViewProj, Vec3(m_tLightPos.x, m_tLightPos.y, m_tLightPos.z), _
 Vec3(m_tLightPos.x - m_tLightDir.x, m_tLightPos.y - m_tLightDir.y, m_tLightPos.z - m_tLightDir.z), _
 Vec3(0, 1, 0) '??
 If m_nLightType = 1 Then 'point
  D3DXMatrixPerspectiveFovLH mat, FOVOrViewSize, 1, zn, zf
 Else 'directional
  D3DXMatrixOrthoLH mat, FOVOrViewSize, FOVOrViewSize, zn, zf
 End If
 D3DXMatrixMultiply m_tLightViewProj, m_tLightViewProj, mat
End If
End Sub

Friend Sub UpdateRenderState()
On Error Resume Next
'///
SetupTransform objEffect
'///
objEffect.CommitChanges
End Sub

Friend Sub SetupLight(ByVal obj1 As D3DXEffect)
On Error Resume Next
obj1.SetVector StrPtr(StrConv("lightDir", vbFromUnicode)), m_tLightDir
obj1.SetVector StrPtr(StrConv("lightPos", vbFromUnicode)), m_tLightPos
obj1.SetVector StrPtr(StrConv("viewPos", vbFromUnicode)), m_tViewPos
obj1.SetInt StrPtr(StrConv("lightType", vbFromUnicode)), m_nLightType
End Sub

Friend Sub SetupTransform(ByVal obj1 As D3DXEffect)
On Error Resume Next
Dim mat1 As D3DMATRIX, mat2 As D3DMATRIX, mat3 As D3DMATRIX, mat As D3DMATRIX
d3dd9.GetTransform D3DTS_WORLD, mat1
obj1.SetMatrix StrPtr(StrConv("matWorld", vbFromUnicode)), mat1
d3dd9.GetTransform D3DTS_VIEW, mat2
d3dd9.GetTransform D3DTS_PROJECTION, mat3
D3DXMatrixMultiply mat, mat1, mat2
D3DXMatrixMultiply mat, mat, mat3
D3DXMatrixInverse mat2, 0, mat1 '[out] pDeterminant
obj1.SetMatrixTranspose StrPtr(StrConv("matWorldInv", vbFromUnicode)), mat2
obj1.SetMatrix StrPtr(StrConv("matTransform", vbFromUnicode)), mat
End Sub

Friend Sub SetupZData(ByVal obj1 As D3DXEffect)
On Error Resume Next
obj1.SetVector StrPtr(StrConv("zData", vbFromUnicode)), m_vZData
End Sub

'test only
Friend Function BeginRender(ByVal nType As enumRenderPassType, Optional ByVal SetupEffect As Boolean = True) As Boolean
On Error Resume Next
Dim obj As Direct3DTexture9
Dim mat As D3DMATRIX
Dim s As String
'///
If m_nLastType Then
 Debug.Assert False
 Exit Function
End If
'///
Select Case nType
Case RenderPass_ShadowMap
 If Not m_bShadowEnabled Or objShadowMap Is Nothing Or objShadowStencil Is Nothing Then Exit Function
 If SetupEffect Then
  Set objOldTarget = d3dd9.GetRenderTarget(0)
  Set objOldStencil = d3dd9.GetDepthStencilSurface
  d3dd9.SetRenderTarget 0, objShadowMap.GetSurfaceLevel(0)
  d3dd9.SetDepthStencilSurface objShadowStencil
  '///
  d3dd9.Clear 0, ByVal 0, D3DCLEAR_TARGET Or D3DCLEAR_ZBUFFER, -1, 1, 0
  '///
  d3dd9.GetTransform D3DTS_WORLD, mat
  D3DXMatrixMultiply mat, mat, m_tLightViewProj
  objEffect.SetMatrix StrPtr(StrConv("matShadow", vbFromUnicode)), mat
  '///
  s = "test_shadow"
 End If
Case RenderPass_FogVolume
 If Not (m_bPostProcessEnabled And m_bFog And m_bVolumeFog) Then Exit Function
 If SetupEffect Then
  Set objOldTarget_1 = d3dd9.GetRenderTarget(0)
  d3dd9.SetRenderTarget 0, objPostProcessTarget(IDR_VolumetricFogTarget).GetSurfaceLevel(0)
  objEffect.SetTexture StrPtr(StrConv("tex0", vbFromUnicode)), objPostProcessTarget(IDR_Main)
  '///
  s = "test_volumefog"
 End If
Case RenderPass_Main
 If m_bPostProcessEnabled Then
  '///this code is not compatible with FSAA
  Set objOldTarget = d3dd9.GetRenderTarget(0)
  #If UseMultiSample Then
  If d3dpp.MultiSampleType > 1 Then
   Debug.Assert Not objFloatTarget Is Nothing
   d3dd9.SetRenderTarget 0, objFloatTarget
  Else
  #End If
   d3dd9.SetRenderTarget 0, objPostProcessTarget(IDR_Main).GetSurfaceLevel(0)
  #If UseMultiSample Then
  End If
  #End If
 End If
 d3dd9.Clear 0, ByVal 0, D3DCLEAR_TARGET Or D3DCLEAR_ZBUFFER, &HFF000010, 1, 0 '??? TODO:backcolor,etc.
 '///
 If SetupEffect Then
  If m_bShadowEnabled And Not objShadowMap Is Nothing Then Set obj = objShadowMap
  objEffect.SetTexture StrPtr(StrConv("texShadow", vbFromUnicode)), obj
  objEffect.SetTexture StrPtr(StrConv("texNoise", vbFromUnicode)), texNoise
  s = "test"
 End If
Case RenderPass_Overlay 'dummy
 BeginRender = True
 Exit Function
Case Else
 Exit Function
End Select
'///
BeginRender = True
m_nLastType = nType
'///
UpdateRenderState
'///
If SetupEffect Then
 objEffect.SetTechnique StrPtr(StrConv(s, vbFromUnicode))
 objEffect.Begin 0, 0
 objEffect.BeginPass 0
 m_nLastType = m_nLastType Or &H1000000
End If
End Function

'TEST ONLY
Friend Sub EndEffect()
If m_nLastType And &H1000000 Then
 objEffect.EndPass
 objEffect.End
 m_nLastType = m_nLastType And Not &H1000000
End If
End Sub

Friend Sub EndRender()
On Error Resume Next
Dim nType As Long
'///
nType = m_nLastType
If nType = 0 Then Exit Sub
m_nLastType = 0
'///
If nType And &H1000000 Then
 objEffect.EndPass
 objEffect.End
End If
'///
Select Case nType And &HFFFFFF
Case RenderPass_ShadowMap
 If Not m_bShadowEnabled Or objShadowMap Is Nothing Or objShadowStencil Is Nothing Then Exit Sub
 d3dd9.SetRenderTarget 0, objOldTarget
 d3dd9.SetDepthStencilSurface objOldStencil
 Set objOldTarget = Nothing
 Set objOldStencil = Nothing
Case RenderPass_FogVolume
 d3dd9.SetRenderTarget 0, objOldTarget_1
 Set objOldTarget_1 = Nothing
Case RenderPass_Main
 If m_bPostProcessEnabled Then
  '///this code is not compatible with FSAA
  d3dd9.SetRenderTarget 0, objOldTarget
  Set objOldTarget = Nothing
  '///
  #If UseMultiSample Then
  'it looks ugly
  If d3dpp.MultiSampleType > 1 Then
   Debug.Assert Not objFloatTarget Is Nothing
   d3dd9.StretchRect objFloatTarget, ByVal 0, objPostProcessTarget(IDR_Main).GetSurfaceLevel(0), ByVal 0, D3DTEXF_NONE
  End If
  #End If
  '///
 End If
End Select
End Sub

Friend Sub PerformPostProcess()
Dim nOldState As Long
Dim i As Long, j As Long
Dim f As Single
Dim v As D3DXVECTOR4, v2 As D3DXVECTOR4, v3 As D3DXVECTOR4
Dim tDesc As D3DSURFACE_DESC
'///
If Not m_bPostProcessEnabled Then Exit Sub
'///convolve kernel
'v = Vec4(0.275591!, 0.220472!, 0.110236!, 0.0314961!) 'bimonial8
v = Vec4(0.251497!, 0.209581!, 0.11976!, 0.0449102!) 'bimonial10
'///
nOldState = d3dd9.GetRenderState(D3DRS_ALPHABLENDENABLE)
d3dd9.SetRenderState D3DRS_ALPHABLENDENABLE, 1
d3dd9.SetRenderState D3DRS_SRCBLEND, D3DBLEND_ONE
d3dd9.SetRenderState D3DRS_DESTBLEND, D3DBLEND_ONE
'///changed:render fog first
If m_bFog Then
 v2 = m_vDepthOfField
 v2.y = v2.y / m_zf
 'fog test
 'it looks ugly when FSAA is enabled. TODO:
 If m_bVolumeFog And Not objPostProcessTarget(IDR_VolumetricFogTarget) Is Nothing Then
  objTextMgr.ProcessTwoTextureEx objPostProcessTarget(IDR_Main), _
  objPostProcessTarget(IDR_VolumetricFogTarget), _
  objPostProcessTarget(IDR_Auxiliary), _
  "fx_linear_with_volume_fog", 0, 0, 0, 0, Vec4, v2, Vec4(0, 200, 1), m_vDistCorrection
 Else
  objTextMgr.ProcessTextureEx objPostProcessTarget(IDR_Main), _
  objPostProcessTarget(IDR_Auxiliary), _
  "fx_linear_with_fog", 0, 0, 0, 0, Vec4, v2, Vec4(0, 200, 1), m_vDistCorrection
 End If
ElseIf m_nDOFType > 0 Then
 v2 = m_vDepthOfField
 v2.y = v2.y / m_zf
 objTextMgr.ProcessTextureEx objPostProcessTarget(IDR_Main), _
 objPostProcessTarget(IDR_Auxiliary), _
 "fx_depth_of_field_only", 0, 0, 0, 0, v2, v2, v2, v2 'Vec4, v2, Vec4, Vec4
Else
 d3dd9.StretchRect objPostProcessTarget(IDR_Main).GetSurfaceLevel(0), ByVal 0, _
 objPostProcessTarget(IDR_Auxiliary).GetSurfaceLevel(0), ByVal 0, D3DTEXF_NONE
End If
'///depth of field test
If m_nDOFType = 1 Then
 '///
 objTextMgr.ProcessTextureEx objPostProcessTarget(IDR_Auxiliary), objPostProcessTarget(IDR_DOF2), _
 "convolve_h_symmetric4", 0, 0, 0, 0, v, Vec4, Vec4, Vec4, 2
 objTextMgr.ProcessTextureEx objPostProcessTarget(IDR_DOF2), objPostProcessTarget(IDR_DOF1), _
 "convolve_v_symmetric4", 0, 0, 0, 0, v, Vec4, Vec4, Vec4, 1
 objTextMgr.ProcessTextureEx objPostProcessTarget(IDR_DOF1), objPostProcessTarget(IDR_DOF2), _
 "convolve_h_symmetric4", 0, 0, 0, 0, v, Vec4, Vec4, Vec4, 3
 objTextMgr.ProcessTextureEx objPostProcessTarget(IDR_DOF2), objPostProcessTarget(IDR_DOF1), _
 "convolve_v_symmetric4", 0, 0, 0, 0, v, Vec4, Vec4, Vec4, 3
 '///
 objTextMgr.ProcessTwoTextureEx objPostProcessTarget(IDR_Auxiliary), objPostProcessTarget(IDR_DOF1), _
 objPostProcessTarget(IDR_Main), "process_lerp_ex", 0, 0, 0, 0, Vec4(2, 1), Vec4, Vec4, Vec4
 '///
 d3dd9.StretchRect objPostProcessTarget(IDR_Main).GetSurfaceLevel(0), ByVal 0, _
 objPostProcessTarget(IDR_Auxiliary).GetSurfaceLevel(0), ByVal 0, D3DTEXF_NONE
ElseIf m_nDOFType >= 2 Then
 objTextMgr.ProcessTextureEx objPostProcessTarget(IDR_Auxiliary), objPostProcessTarget(IDR_Main), "convolve_h_symmetric4_ex", 0, 0, 0, 0, v, Vec4, Vec4, Vec4
 objTextMgr.ProcessTextureEx objPostProcessTarget(IDR_Main), objPostProcessTarget(IDR_Auxiliary), "convolve_v_symmetric4_ex", 0, 0, 0, 0, v, Vec4, Vec4, Vec4
 objTextMgr.ProcessTextureEx objPostProcessTarget(IDR_Auxiliary), objPostProcessTarget(IDR_Main), "convolve_h_symmetric4_ex", 0, 0, 0, 0, v, Vec4, Vec4, Vec4, 3
 objTextMgr.ProcessTextureEx objPostProcessTarget(IDR_Main), objPostProcessTarget(IDR_Auxiliary), "convolve_v_symmetric4_ex", 0, 0, 0, 0, v, Vec4, Vec4, Vec4, 3
End If
'////////////////HDR
f = 4 '8
'///calc luminance
objTextMgr.ProcessTextureEx objPostProcessTarget(IDR_Auxiliary), objPostProcessTarget(IDR_Luminance), "fx_to_luminance", 0, 0, 0, 0, Vec4(f), Vec4, Vec4, Vec4
objTextMgr.ProcessTextureEx objPostProcessTarget(IDR_Luminance), objPostProcessTarget(IDR_AverageLuminance), "fx_from_luminance_bias", 0, 0, 0, 0, Vec4(f, 0, 0, 16), Vec4, Vec4, Vec4
'///bright pass
objTextMgr.ProcessTwoTextureEx objPostProcessTarget(IDR_Auxiliary), objPostProcessTarget(IDR_AverageLuminance), objPostProcessTarget(IDR_BlurPass1), _
"normalized_brightpass", 0, 0, 0, 0, Vec4(1), Vec4, Vec4, Vec4  'Vec4(1, 0.25) 'simple_brightpass
'////////////////
'///blur - see documentation
If m_bRadialBlur Then
 j = 1
Else
 i = m_nHDRBlurQuality
 If i <= 0 Then j = &H502& _
 Else If i = 1 Then j = &H90301 _
 Else j = &H110502
End If
For i = 0 To 2
 objTextMgr.ProcessTextureEx objPostProcessTarget(IDR_BlurPass1), objPostProcessTarget(IDR_BlurPass2), "convolve_h_symmetric4", 0, 0, 0, 0, v, Vec4, Vec4, Vec4, j And &HFF&
 objTextMgr.ProcessTextureEx objPostProcessTarget(IDR_BlurPass2), objPostProcessTarget(IDR_BlurPass1), "convolve_v_symmetric4", 0, 0, 0, 0, v, Vec4, Vec4, Vec4, j And &HFF&
 j = j \ &H100&
 If j <= 0 Then Exit For
Next i
'///test - radial blur
'the coefficients:
'Table[ToString[(ToString[#]<>"!")&/@N[z^-Table[n*t/5,{n,4}]/.{t->5^-k,z->10},10]],{k,0,3}]
If m_bRadialBlur Then
 objTextMgr.ProcessTextureEx objPostProcessTarget(IDR_BlurPass1), objPostProcessTarget(IDR_BlurPass2), "simple_radial_blur5", 0, 0, 0, 0, Vec4(0.6309574!, 0.3981072!, 0.2511886!, 0.1584893!), Vec4, Vec4, Vec4
 objTextMgr.ProcessTextureEx objPostProcessTarget(IDR_BlurPass2), objPostProcessTarget(IDR_BlurPass1), "simple_radial_blur5", 0, 0, 0, 0, Vec4(0.9120108!, 0.8317637!, 0.7585776!, 0.691831!), Vec4, Vec4, Vec4
 If m_nHDRBlurQuality > 1 Then
  objTextMgr.ProcessTextureEx objPostProcessTarget(IDR_BlurPass1), objPostProcessTarget(IDR_BlurPass2), "simple_radial_blur5", 0, 0, 0, 0, Vec4(0.9817479!, 0.963829!, 0.9462371!, 0.9289664!), Vec4, Vec4, Vec4
  objTextMgr.ProcessTextureEx objPostProcessTarget(IDR_BlurPass2), objPostProcessTarget(IDR_BlurPass1), "simple_radial_blur5", 0, 0, 0, 0, Vec4(0.9963226!, 0.9926588!, 0.9890084!, 0.9853715!), Vec4, Vec4, Vec4
 End If
End If
'////////////////
'...TODO:
'///
d3dd9.Clear 0, ByVal 0, D3DCLEAR_TARGET, 0, 1, 0
d3dd9.BeginScene
'///
objTextMgr.DrawTextureEx objPostProcessTarget(IDR_Auxiliary), "process_linear", 0, 0, 0, 0, Vec4, Vec4(1, 1, 1, 1), Vec4, Vec4
'objTextMgr.DrawTwoTextureEx objPostProcessTarget(IDR_Auxiliary), objPostProcessTarget(IDR_AverageLuminance), "simple_tonemapping", 0, 0, 0, 0, Vec4(0.1, 3), Vec4, Vec4, Vec4 'ugly
objTextMgr.DrawTextureEx objPostProcessTarget(IDR_BlurPass1), "process_linear", 0, 0, 0, 0, Vec4, Vec4(1, 1, 1, 1), Vec4, Vec4
'///
d3dd9.EndScene
d3dd9.SetRenderState D3DRS_ALPHABLENDENABLE, nOldState
d3dd9.SetRenderState D3DRS_SRCBLEND, D3DBLEND_SRCALPHA
d3dd9.SetRenderState D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA
End Sub

Friend Property Get AmbientColor() As D3DXVECTOR4
AmbientColor = m_fParam(0)
End Property

Friend Property Let AmbientColor(ByRef v As D3DXVECTOR4)
m_fParam(0) = v
objEffect.SetVectorArray StrPtr(StrConv("_fParam", vbFromUnicode)), m_fParam(0), 4&
End Property

Friend Property Get SpecularHardness() As Single
SpecularHardness = m_fParam(1).x
End Property

Friend Property Let SpecularHardness(ByVal f As Single)
m_fParam(1).x = f
objEffect.SetVectorArray StrPtr(StrConv("_fParam", vbFromUnicode)), m_fParam(0), 4&
End Property

Friend Property Get ParallaxOffset() As Single
ParallaxOffset = m_fParam(1).y
End Property

Friend Property Let ParallaxOffset(ByVal f As Single)
m_fParam(1).y = f
objEffect.SetVectorArray StrPtr(StrConv("_fParam", vbFromUnicode)), m_fParam(0), 4&
End Property

Friend Property Get ParallaxScale() As Single
ParallaxScale = m_fParam(1).z
End Property

Friend Property Let ParallaxScale(ByVal f As Single)
m_fParam(1).z = f
objEffect.SetVectorArray StrPtr(StrConv("_fParam", vbFromUnicode)), m_fParam(0), 4&
End Property

Friend Property Get OrenNayarParamA() As Single
OrenNayarParamA = m_fParam(3).z
End Property

Friend Property Let OrenNayarParamA(ByVal f As Single)
m_fParam(3).z = f
objEffect.SetVectorArray StrPtr(StrConv("_fParam", vbFromUnicode)), m_fParam(0), 4&
End Property

Friend Property Get OrenNayarParamB() As Single
OrenNayarParamB = m_fParam(3).w
End Property

Friend Property Let OrenNayarParamB(ByVal f As Single)
m_fParam(3).w = f
objEffect.SetVectorArray StrPtr(StrConv("_fParam", vbFromUnicode)), m_fParam(0), 4&
End Property

Friend Property Let OrenNayarRoughness(ByVal f As Single)
f = f * f
m_fParam(3).z = 1 - 0.5 * f / (f + 0.33)
m_fParam(3).w = 0.45 * f / (f + 0.09)
objEffect.SetVectorArray StrPtr(StrConv("_fParam", vbFromUnicode)), m_fParam(0), 4&
End Property

Friend Sub SetFloatParams(ByRef tAmbientColor As D3DXVECTOR4, ByVal fSpecularHardness As Single, ByVal fParallaxOffset As Single, ByVal fParallaxScale As Single)
m_fParam(0) = tAmbientColor
m_fParam(1).x = fSpecularHardness
m_fParam(1).y = fParallaxOffset
m_fParam(1).z = fParallaxScale
objEffect.SetVectorArray StrPtr(StrConv("_fParam", vbFromUnicode)), m_fParam(0), 4&
End Sub

Private Sub Class_Terminate()
Erase objPostProcessTarget
#If UseMultiSample Then
Set objFloatTarget = Nothing
#End If
Set objShadowMap = Nothing
Set objShadowStencil = Nothing
Set texNoise = Nothing
Set objEffect = Nothing
End Sub

Friend Sub SetProjection_PerspectiveFovLH(Optional ByVal fovy As Single = 0.7854, Optional ByVal Aspect As Single, Optional ByVal zn As Single = 0.1, Optional ByVal zf As Single = 100)
Dim mat As D3DMATRIX
If Aspect <= 0.0001 Then Aspect = d3dpp.BackBufferWidth / d3dpp.BackBufferHeight
m_fovy = fovy
m_fAspect = Aspect
m_zn = zn
m_zf = zf
D3DXMatrixPerspectiveFovLH mat, m_fovy, Aspect, zn, zf
d3dd9.SetTransform D3DTS_PROJECTION, mat
'///
m_vDistCorrection.y = Tan(fovy / 2) * 2 * zf
m_vDistCorrection.x = m_vDistCorrection.y * Aspect
m_vDistCorrection.z = zf
'///
m_vZData.x = zf / zn
m_vZData.y = 1 - m_vZData.x
objEffect.SetVector StrPtr(StrConv("zData", vbFromUnicode)), m_vZData
End Sub

Friend Sub GetProjection_PerspectiveFovLH(ByRef fovy As Single, ByRef Aspect As Single, ByRef zn As Single, ByRef zf As Single)
fovy = m_fovy
Aspect = m_fAspect
zn = m_zn
zf = m_zf
End Sub

Friend Property Get ShadowEnabled() As Boolean
ShadowEnabled = m_bShadowEnabled
End Property

'TODO:
Friend Property Let ShadowEnabled(ByVal b As Boolean)
If b <> m_bShadowEnabled Then
 'TODO:
End If
End Property
