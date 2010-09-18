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

'    像素光照
'    Ambient
'    Diffuse
'    Specular (Specular map?)
'    (Emission?)
'    Bump map
'    Normal map
'    (Parallax map?)
'    阴影贴图（平行光）（点光源？？）
'    Displacement(Height map)
'    Soft shadow?
'    冰面反光（冰方块反光？？代码太长，可能运行得太慢）
'    HDR（山寨HDR）
'    Motion blur, radial blur

Private objEffect As D3DXEffect

Private m_tLightDir As D3DXVECTOR4, m_tLightPos As D3DXVECTOR4, m_tViewPos As D3DXVECTOR4
Private m_nLightType As Long

Private objOldTarget As Direct3DSurface9
Private objOldStencil As Direct3DSurface9

Private texNoise As Direct3DTexture9
Private objShadowMap As Direct3DTexture9, objShadowStencil As Direct3DSurface9
Private m_bShadowEnabled As Boolean
Private m_tLightViewProj As D3DMATRIX
Private m_nShadowMapSize As Long

Private m_fParam(3) As D3DXVECTOR4

Friend Property Get Effect() As D3DXEffect
Set Effect = objEffect
End Property

Friend Sub Create()
'///
'test
CreateEffect CStr(App.Path) + "\data\shader\pstest.txt", objEffect, , True
'///???
D3DXCreateTextureFromFileW d3dd9, CStr(App.Path) + "\data\gfx\noise.bmp", texNoise
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
Set objOldStencil = Nothing
Set objShadowMap = Nothing
Set objShadowStencil = Nothing
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

Friend Sub BeginRenderShadowMap()
Dim mat As D3DMATRIX
If Not m_bShadowEnabled Or objShadowMap Is Nothing Or objShadowStencil Is Nothing Then Exit Sub
'///
Set objOldTarget = d3dd9.GetRenderTarget(0)
Set objOldStencil = d3dd9.GetDepthStencilSurface
d3dd9.SetRenderTarget 0, objShadowMap.GetSurfaceLevel(0)
d3dd9.SetDepthStencilSurface objShadowStencil
'///
d3dd9.GetTransform D3DTS_WORLD, mat
D3DXMatrixMultiply mat, mat, m_tLightViewProj
objEffect.SetMatrix StrPtr(StrConv("matShadow", vbFromUnicode)), mat
objEffect.SetTechnique StrPtr(StrConv("test_shadow", vbFromUnicode))
objEffect.Begin 0, 0
objEffect.BeginPass 0
End Sub

Friend Sub EndRenderShadowMap()
If Not m_bShadowEnabled Or objShadowMap Is Nothing Or objShadowStencil Is Nothing Then Exit Sub
objEffect.EndPass
objEffect.End
d3dd9.SetRenderTarget 0, objOldTarget
d3dd9.SetDepthStencilSurface objOldStencil
Set objOldTarget = Nothing
Set objOldStencil = Nothing
End Sub

Friend Sub BeginRender()
Dim mat1 As D3DMATRIX, mat2 As D3DMATRIX, mat3 As D3DMATRIX, mat As D3DMATRIX
Dim obj As Direct3DTexture9
d3dd9.GetTransform D3DTS_WORLD, mat1
objEffect.SetMatrix StrPtr(StrConv("matWorld", vbFromUnicode)), mat1
d3dd9.GetTransform D3DTS_VIEW, mat2
d3dd9.GetTransform D3DTS_PROJECTION, mat3
D3DXMatrixMultiply mat, mat1, mat2
D3DXMatrixMultiply mat, mat, mat3
D3DXMatrixInverse mat2, 0, mat1 '[out] pDeterminant
objEffect.SetMatrixTranspose StrPtr(StrConv("matWorld1", vbFromUnicode)), mat2
'///
If m_bShadowEnabled And Not objShadowMap Is Nothing Then Set obj = objShadowMap
objEffect.SetTexture StrPtr(StrConv("texShadow", vbFromUnicode)), obj
objEffect.SetTexture StrPtr(StrConv("texNoise", vbFromUnicode)), texNoise
'///
objEffect.SetMatrix StrPtr(StrConv("mat", vbFromUnicode)), mat
objEffect.SetTechnique StrPtr(StrConv("test", vbFromUnicode))
objEffect.Begin 0, 0
objEffect.BeginPass 0
End Sub

Friend Sub EndRender()
objEffect.EndPass
objEffect.End
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
Set objShadowMap = Nothing
Set objShadowStencil = Nothing
Set texNoise = Nothing
Set objEffect = Nothing
End Sub

