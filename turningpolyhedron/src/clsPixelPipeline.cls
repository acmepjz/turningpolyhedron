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

Private Const m_nFormat1 = D3DFMT_A8R8G8B8 'D3DFMT_A32B32G32R32F

Private objEffect As D3DXEffect

Private m_tLightDir As D3DXVECTOR4, m_tLightPos As D3DXVECTOR4, m_tViewPos As D3DXVECTOR4
Private m_nLightType As Long

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
 RenderPass_ShadowMap = 100
 RenderPass_FogVolume = 200
End Enum
Private m_nLastType As Long

'////////post process

Private m_bPostProcessEnabled As Boolean
Private objPostProcessTarget(15) As Direct3DTexture9
'HDR
Private m_nHDRBlurQuality As Long
'radial blur
Private m_bRadialBlur As Boolean
'volumetric fog
Private m_bVolumeFog As Boolean
'depth of field
Private m_bDetphOfField As Boolean

'////////

Private m_fParam(3) As D3DXVECTOR4

Private m_fovy As Single, m_fAspect As Single, m_zn As Single, m_zf As Single
Private m_vDistCorrection As D3DXVECTOR4
Private m_vDepthOfField As D3DXVECTOR4

Friend Property Get DepthOfFiendEnabled() As Boolean
DepthOfFiendEnabled = m_bDetphOfField
End Property

Friend Property Let DepthOfFiendEnabled(ByVal b As Boolean)
m_bDetphOfField = b
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

Friend Property Get VolumetricFogEnabled() As Boolean
VolumetricFogEnabled = m_bVolumeFog
End Property

Friend Property Let VolumetricFogEnabled(ByVal b As Boolean)
m_bVolumeFog = b
'If m_bPostProcessEnabled And b Then
' If objPostProcessTarget(6) Is Nothing Then
'  '6=volumetric fog target GR=fog far/fog near
'  D3DXCreateTexture d3dd9, d3dpp.BackBufferWidth, d3dpp.BackBufferHeight, 1, D3DUSAGE_RENDERTARGET, D3DFMT_G32R32F, D3DPOOL_DEFAULT, objPostProcessTarget(6)
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
 Set objPostProcessTarget(1) = Nothing
 Set objPostProcessTarget(4) = Nothing
 Set objPostProcessTarget(5) = Nothing
 If m_bPostProcessEnabled Then
  If n <= 0 Then k = 8 _
  Else If n = 1 Then k = 4 _
  Else k = 2
  D3DXCreateTexture d3dd9, d3dpp.BackBufferWidth \ k, d3dpp.BackBufferHeight \ k, 1, D3DUSAGE_RENDERTARGET, m_nFormat1, D3DPOOL_DEFAULT, objPostProcessTarget(1)
  D3DXCreateTexture d3dd9, d3dpp.BackBufferWidth \ k, d3dpp.BackBufferHeight \ k, 1, D3DUSAGE_RENDERTARGET, m_nFormat1, D3DPOOL_DEFAULT, objPostProcessTarget(4)
  D3DXCreateTexture d3dd9, d3dpp.BackBufferWidth \ k, d3dpp.BackBufferHeight \ k, 1, D3DUSAGE_RENDERTARGET, m_nFormat1, D3DPOOL_DEFAULT, objPostProcessTarget(5)
 End If
End If
End Property

Friend Sub CreatePostProcessTarget()
Erase objPostProcessTarget
'///new
If d3dd9 Is Nothing Then Exit Sub
'///
'/!\ we need 30M video memory if 1024x768, 80M if 1920x1080 :-3
If m_bPostProcessEnabled Then
 '0=main render target BGR=color A=depth (0=0 zf=1)
 D3DXCreateTexture d3dd9, d3dpp.BackBufferWidth, d3dpp.BackBufferHeight, 1, D3DUSAGE_RENDERTARGET, D3DFMT_A32B32G32R32F, D3DPOOL_DEFAULT, objPostProcessTarget(0)
 '6=volumetric fog target
 'VolumetricFogEnabled = m_bVolumeFog
 D3DXCreateTexture d3dd9, d3dpp.BackBufferWidth, d3dpp.BackBufferHeight, 1, D3DUSAGE_RENDERTARGET, D3DFMT_G32R32F, D3DPOOL_DEFAULT, objPostProcessTarget(6)
 '7=auxiliary render target (for volumetric fog+HDR and depth of field)
 D3DXCreateTexture d3dd9, d3dpp.BackBufferWidth, d3dpp.BackBufferHeight, 1, D3DUSAGE_RENDERTARGET, D3DFMT_A32B32G32R32F, D3DPOOL_DEFAULT, objPostProcessTarget(7)
 'bright-pass (1,4,5)
 HDRBlurQuality(True) = m_nHDRBlurQuality
 '///
 '2=luminance
 D3DXCreateTexture d3dd9, 128, 128, 0, D3DUSAGE_RENDERTARGET Or D3DUSAGE_AUTOGENMIPMAP, D3DFMT_R32F, D3DPOOL_DEFAULT, objPostProcessTarget(2)
 '3=average luminance
 D3DXCreateTexture d3dd9, 1, 1, 1, D3DUSAGE_RENDERTARGET, D3DFMT_R32F, D3DPOOL_DEFAULT, objPostProcessTarget(3)
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

Friend Sub SetTexture(ByVal obj As Direct3DTexture9)
objEffect.SetTexture StrPtr(StrConv("tex", vbFromUnicode)), obj
End Sub

Friend Sub SetNormalTexture(ByVal obj As Direct3DTexture9)
objEffect.SetTexture StrPtr(StrConv("texNormal", vbFromUnicode)), obj
End Sub

Friend Sub OnLostDevice()
Set objOldTarget = Nothing
Set objOldTarget_1 = Nothing
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
Dim mat1 As D3DMATRIX, mat2 As D3DMATRIX, mat3 As D3DMATRIX, mat As D3DMATRIX
d3dd9.GetTransform D3DTS_WORLD, mat1
objEffect.SetMatrix StrPtr(StrConv("matWorld", vbFromUnicode)), mat1
d3dd9.GetTransform D3DTS_VIEW, mat2
d3dd9.GetTransform D3DTS_PROJECTION, mat3
D3DXMatrixMultiply mat, mat1, mat2
D3DXMatrixMultiply mat, mat, mat3
D3DXMatrixInverse mat2, 0, mat1 '[out] pDeterminant
objEffect.SetMatrixTranspose StrPtr(StrConv("matWorld1", vbFromUnicode)), mat2
objEffect.SetMatrix StrPtr(StrConv("mat", vbFromUnicode)), mat
'///
objEffect.CommitChanges
End Sub

Friend Function BeginRender(ByVal nType As enumRenderPassType) As Boolean
On Error Resume Next
Dim obj As Direct3DTexture9
Dim mat As D3DMATRIX
Dim s As String
'///
Select Case nType
Case RenderPass_ShadowMap
 If Not m_bShadowEnabled Or objShadowMap Is Nothing Or objShadowStencil Is Nothing Then Exit Function
 '///
 Set objOldTarget = d3dd9.GetRenderTarget(0)
 Set objOldStencil = d3dd9.GetDepthStencilSurface
 d3dd9.SetRenderTarget 0, objShadowMap.GetSurfaceLevel(0)
 d3dd9.SetDepthStencilSurface objShadowStencil
 '///
 d3dd9.GetTransform D3DTS_WORLD, mat
 D3DXMatrixMultiply mat, mat, m_tLightViewProj
 objEffect.SetMatrix StrPtr(StrConv("matShadow", vbFromUnicode)), mat
 '///
 s = "test_shadow"
Case RenderPass_FogVolume
 If Not m_bPostProcessEnabled Or Not m_bVolumeFog Then Exit Function
 Set objOldTarget_1 = d3dd9.GetRenderTarget(0)
 d3dd9.SetRenderTarget 0, objPostProcessTarget(6).GetSurfaceLevel(0)
 objEffect.SetTexture StrPtr(StrConv("tex", vbFromUnicode)), objPostProcessTarget(0)
 '///
 s = "test_volumefog"
Case RenderPass_Main
 If m_bShadowEnabled And Not objShadowMap Is Nothing Then Set obj = objShadowMap
 objEffect.SetTexture StrPtr(StrConv("texShadow", vbFromUnicode)), obj
 objEffect.SetTexture StrPtr(StrConv("texNoise", vbFromUnicode)), texNoise
 s = "test"
Case Else
 Exit Function
End Select
'///
BeginRender = True
m_nLastType = nType
'///
UpdateRenderState
'///
objEffect.SetTechnique StrPtr(StrConv(s, vbFromUnicode))
objEffect.Begin 0, 0
objEffect.BeginPass 0
End Function

Friend Sub EndRender()
On Error Resume Next
Dim nType As Long
'///
nType = m_nLastType
If nType = 0 Then Exit Sub
m_nLastType = 0
'///
objEffect.EndPass
objEffect.End
'///
Select Case nType
Case RenderPass_ShadowMap
 If Not m_bShadowEnabled Or objShadowMap Is Nothing Or objShadowStencil Is Nothing Then Exit Sub
 d3dd9.SetRenderTarget 0, objOldTarget
 d3dd9.SetDepthStencilSurface objOldStencil
 Set objOldTarget = Nothing
 Set objOldStencil = Nothing
Case RenderPass_FogVolume
 d3dd9.SetRenderTarget 0, objOldTarget_1
 Set objOldTarget_1 = Nothing
End Select
End Sub

Friend Sub BeginRenderToPostProcessTarget()
If m_bPostProcessEnabled Then
 Set objOldTarget = d3dd9.GetRenderTarget(0)
 d3dd9.SetRenderTarget 0, objPostProcessTarget(0).GetSurfaceLevel(0)
End If
d3dd9.Clear 0, ByVal 0, D3DCLEAR_TARGET Or D3DCLEAR_ZBUFFER, &HFF000010, 1, 0 '??? TODO:backcolor,etc.
End Sub

Friend Sub EndRenderToPostProcessTarget()
If m_bPostProcessEnabled Then
 d3dd9.SetRenderTarget 0, objOldTarget
 Set objOldTarget = Nothing
End If
End Sub

Friend Sub PerformPostProcess(ByVal objDraw As clsRenderTexture)
Dim nOldState As Long
Dim i As Long, j As Long
Dim f As Single
Dim v As D3DXVECTOR4, v2 As D3DXVECTOR4, v3 As D3DXVECTOR4
Dim tDesc As D3DSURFACE_DESC
'///convolve kernel
'v = Vec4(0.275591!, 0.220472!, 0.110236!, 0.0314961!) 'bimonial8
v = Vec4(0.251497!, 0.209581!, 0.11976!, 0.0449102!) 'bimonial10
'///
If Not m_bPostProcessEnabled Then Exit Sub
'///
nOldState = d3dd9.GetRenderState(D3DRS_ALPHABLENDENABLE)
d3dd9.SetRenderState D3DRS_ALPHABLENDENABLE, 1
d3dd9.SetRenderState D3DRS_SRCBLEND, D3DBLEND_ONE
d3dd9.SetRenderState D3DRS_DESTBLEND, D3DBLEND_ONE
'///changed:render fog first
v2 = m_vDepthOfField
v2.y = v2.y / m_zf
'fog test
If m_bVolumeFog And Not objPostProcessTarget(6) Is Nothing Then
 objDraw.ProcessTwoTextureEx objPostProcessTarget(0), objPostProcessTarget(6), objPostProcessTarget(7), _
 "fx_linear_with_volume_fog", 0, 0, 0, 0, Vec4, v2, Vec4(0, 200, 1), m_vDistCorrection
Else
 objDraw.ProcessTextureEx objPostProcessTarget(0), objPostProcessTarget(7), _
 "fx_linear_with_fog", 0, 0, 0, 0, Vec4, v2, Vec4(0, 200, 1), m_vDistCorrection
End If
'///depth of field test
If m_bDetphOfField Then
 objDraw.ProcessTextureEx objPostProcessTarget(7), objPostProcessTarget(0), "convolve_h_symmetric4_ex", 0, 0, 0, 0, v, Vec4, Vec4, Vec4
 objDraw.ProcessTextureEx objPostProcessTarget(0), objPostProcessTarget(7), "convolve_v_symmetric4_ex", 0, 0, 0, 0, v, Vec4, Vec4, Vec4
 objDraw.ProcessTextureEx objPostProcessTarget(7), objPostProcessTarget(0), "convolve_h_symmetric4_ex", 0, 0, 0, 0, v, Vec4, Vec4, Vec4, 3
 objDraw.ProcessTextureEx objPostProcessTarget(0), objPostProcessTarget(7), "convolve_v_symmetric4_ex", 0, 0, 0, 0, v, Vec4, Vec4, Vec4, 3
End If
'////////////////HDR
f = 4 '8
'///calc luminance
objDraw.ProcessTextureEx objPostProcessTarget(7), objPostProcessTarget(2), "fx_to_luminance", 0, 0, 0, 0, Vec4(f), Vec4, Vec4, Vec4
objDraw.ProcessTextureEx objPostProcessTarget(2), objPostProcessTarget(3), "fx_from_luminance_bias", 0, 0, 0, 0, Vec4(f, 0, 0, 16), Vec4, Vec4, Vec4
'///bright pass
objDraw.ProcessTwoTextureEx objPostProcessTarget(7), objPostProcessTarget(3), objPostProcessTarget(1), _
"simple_brightpass", 0, 0, 0, 0, Vec4(1), Vec4, Vec4, Vec4  'Vec4(1, 0.25)
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
 objDraw.ProcessTextureEx objPostProcessTarget(1), objPostProcessTarget(4), "convolve_h_symmetric4", 0, 0, 0, 0, v, Vec4, Vec4, Vec4, j And &HFF&
 objDraw.ProcessTextureEx objPostProcessTarget(4), objPostProcessTarget(1), "convolve_v_symmetric4", 0, 0, 0, 0, v, Vec4, Vec4, Vec4, j And &HFF&
 j = j \ &H100&
 If j <= 0 Then Exit For
Next i
'///test - radial blur
'the coefficients:
'Table[ToString[(ToString[#]<>"!")&/@N[z^-Table[n*t/5,{n,4}]/.{t->5^-k,z->10},10]],{k,0,3}]
If m_bRadialBlur Then
 objDraw.ProcessTextureEx objPostProcessTarget(1), objPostProcessTarget(4), "simple_radial_blur5", 0, 0, 0, 0, Vec4(0.6309574!, 0.3981072!, 0.2511886!, 0.1584893!), Vec4, Vec4, Vec4
 objDraw.ProcessTextureEx objPostProcessTarget(4), objPostProcessTarget(1), "simple_radial_blur5", 0, 0, 0, 0, Vec4(0.9120108!, 0.8317637!, 0.7585776!, 0.691831!), Vec4, Vec4, Vec4
 If m_nHDRBlurQuality > 1 Then
  objDraw.ProcessTextureEx objPostProcessTarget(1), objPostProcessTarget(4), "simple_radial_blur5", 0, 0, 0, 0, Vec4(0.9817479!, 0.963829!, 0.9462371!, 0.9289664!), Vec4, Vec4, Vec4
  objDraw.ProcessTextureEx objPostProcessTarget(4), objPostProcessTarget(1), "simple_radial_blur5", 0, 0, 0, 0, Vec4(0.9963226!, 0.9926588!, 0.9890084!, 0.9853715!), Vec4, Vec4, Vec4
 End If
End If
'////////////////
'...TODO:
'///
d3dd9.Clear 0, ByVal 0, D3DCLEAR_TARGET, 0, 1, 0
d3dd9.BeginScene
'///
objDraw.DrawTextureEx objPostProcessTarget(7), "process_linear", 0, 0, 0, 0, Vec4, Vec4(1, 1, 1, 1), Vec4, Vec4
'objDraw.DrawTwoTextureEx objPostProcessTarget(0), objPostProcessTarget(3), "simple_tonemapping", 0, 0, 0, 0, Vec4(0.1, 3), Vec4, Vec4, Vec4 'ugly
objDraw.DrawTextureEx objPostProcessTarget(1), "process_linear", 0, 0, 0, 0, Vec4, Vec4(1, 1, 1, 1), Vec4, Vec4
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

Friend Sub SetFloatParams(ByRef tAmbientColor As D3DXVECTOR4, ByVal fSpecularHardness As Single, ByVal fParallaxOffset As Single, ByVal fParallaxScale As Single)
m_fParam(0) = tAmbientColor
m_fParam(1).x = fSpecularHardness
m_fParam(1).y = fParallaxOffset
m_fParam(1).z = fParallaxScale
objEffect.SetVectorArray StrPtr(StrConv("_fParam", vbFromUnicode)), m_fParam(0), 4&
End Sub

Private Sub Class_Terminate()
Erase objPostProcessTarget
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
Dim v As D3DXVECTOR4
v.x = zf / zn
v.y = 1 - v.x
objEffect.SetVector StrPtr(StrConv("zData", vbFromUnicode)), v
End Sub

Friend Sub GetProjection_PerspectiveFovLH(ByRef fovy As Single, ByRef Aspect As Single, ByRef zn As Single, ByRef zf As Single)
fovy = m_fovy
Aspect = m_fAspect
zn = m_zn
zf = m_zf
End Sub

