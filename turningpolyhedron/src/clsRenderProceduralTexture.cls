VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsSimplex"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private objEffect As D3DXEffect
Private texNoise As Direct3DTexture9

Private objOldTarget As Direct3DSurface9
Private objOldStencil As Direct3DSurface9

Friend Property Get Effect() As D3DXEffect
Set Effect = objEffect
End Property

Friend Sub Create()
'///
'test:perlin noise
Dim s As String, sErr As String
Open CStr(App.Path) + "\data\shader\test.txt" For Binary As #1
s = Input$(LOF(1), 1)
Close
's = s + "struct VS_OUTPUT{float4 p:POSITION,p0:TEXCOORD0;};" + vbCrLf
's = s + "float4x4 mat;" + vbCrLf
's = s + "VS_OUTPUT vs_func(float4 p:POSITION){" + vbCrLf
's = s + "VS_OUTPUT d;d.p=mul(p,mat);d.p0=p;return d;}" + vbCrLf
's = s + "float4 ps_func(VS_OUTPUT d):COLOR0{" + vbCrLf
's = s + "return 2*abs(d.p0-round(d.p0));}" + vbCrLf
's = s + "technique test{pass{VertexShader=compile vs_2_0 vs_func();PixelShader=compile ps_3_0 ps_func();}}" + vbCrLf
''s = s + "" + vbCrLf
'///
CreateEffect s, objEffect
'///
D3DXCreateTextureFromFileW d3dd9, CStr(App.Path) + "\data\gfx\noise.bmp", texNoise
End Sub

Friend Sub BeginRender()
Dim mat1 As D3DMATRIX, mat2 As D3DMATRIX, mat3 As D3DMATRIX, mat As D3DMATRIX
d3dd9.GetTransform D3DTS_WORLD, mat1
d3dd9.GetTransform D3DTS_VIEW, mat2
d3dd9.GetTransform D3DTS_PROJECTION, mat3
D3DXMatrixMultiply mat, mat1, mat2
D3DXMatrixMultiply mat, mat, mat3
''///test
'Dim v As D3DXVECTOR4
'v.X = 1
'v.Y = 1
'v.z = 2
'v.w = 1
'D3DXVec4Transform v, v, mat
'Debug.Print v.X / v.w, v.Y / v.w, v.z / v.w
''///
objEffect.SetMatrix StrPtr(StrConv("mat", vbFromUnicode)), mat
objEffect.SetTexture StrPtr(StrConv("texNoise", vbFromUnicode)), texNoise
objEffect.SetTechnique StrPtr(StrConv("test", vbFromUnicode))
objEffect.Begin 0, 0
objEffect.BeginPass 0
End Sub

Friend Sub BeginRenderToTexture(ByVal obj As Direct3DTexture9)
Set objOldTarget = d3dd9.GetRenderTarget(0)
Set objOldStencil = d3dd9.GetDepthStencilSurface
d3dd9.SetRenderTarget 0, obj.GetSurfaceLevel(0)
d3dd9.SetDepthStencilSurface Nothing
objEffect.SetTexture StrPtr(StrConv("texNoise", vbFromUnicode)), texNoise
objEffect.SetTechnique StrPtr(StrConv("test_rtt", vbFromUnicode))
objEffect.Begin 0, 0
objEffect.BeginPass 0
End Sub

Friend Sub EndRender()
objEffect.EndPass
objEffect.End
End Sub

Friend Sub EndRenderToTexture()
objEffect.EndPass
objEffect.End
d3dd9.SetRenderTarget 0, objOldTarget
d3dd9.SetDepthStencilSurface objOldStencil
Set objOldTarget = Nothing
Set objOldStencil = Nothing
End Sub

Friend Sub ProcessTexture(ByVal objSrc As Direct3DTexture9, ByVal objDest As Direct3DTexture9, ByVal sEffect As String)
Dim t As D3DSURFACE_DESC
Dim v As D3DXVECTOR4
Dim p(23) As Single
objDest.GetLevelDesc 0, t
v.x = 1 / t.Width
v.y = 1 / t.Height
objEffect.SetVector StrPtr(StrConv("pixelSize", vbFromUnicode)), v
'////////
p(3) = 1: p(4) = v.x / 2: p(5) = v.y / 2
p(6) = t.Width: p(9) = 1: p(10) = p(4) + 1: p(11) = p(5)
p(13) = t.Height: p(15) = 1: p(16) = p(4): p(17) = p(5) + 1
p(18) = p(6): p(19) = p(13): p(21) = 1: p(22) = p(10): p(23) = p(17)
'////////
Set objOldTarget = d3dd9.GetRenderTarget(0)
Set objOldStencil = d3dd9.GetDepthStencilSurface
d3dd9.SetRenderTarget 0, objDest.GetSurfaceLevel(0)
d3dd9.SetDepthStencilSurface Nothing
objEffect.SetTexture StrPtr(StrConv("tex", vbFromUnicode)), objSrc
objEffect.SetTechnique StrPtr(StrConv(sEffect, vbFromUnicode))
objEffect.Begin 0, 0
objEffect.BeginPass 0
'////////
d3dd9.Clear 0, ByVal 0, D3DCLEAR_TARGET, 0, 1, 0
d3dd9.BeginScene
d3dd9.SetFVF D3DFVF_XYZRHW Or D3DFVF_TEX1
d3dd9.DrawPrimitiveUP D3DPT_TRIANGLESTRIP, 2&, p(0), 24&
d3dd9.EndScene
'////////
objEffect.EndPass
objEffect.End
d3dd9.SetRenderTarget 0, objOldTarget
d3dd9.SetDepthStencilSurface objOldStencil
Set objOldTarget = Nothing
Set objOldStencil = Nothing
End Sub

Friend Sub GenerateMipSubLevels(ByVal obj As Direct3DTexture9)
Dim t As D3DSURFACE_DESC
Dim v As D3DXVECTOR4
Dim p(23) As Single
Dim i As Long, m As Long
m = obj.GetLevelCount
If m <= 1 Then Exit Sub
'////////
Set objOldTarget = d3dd9.GetRenderTarget(0)
Set objOldStencil = d3dd9.GetDepthStencilSurface
d3dd9.SetDepthStencilSurface Nothing
'??? maybe wrong ???
objEffect.SetTexture StrPtr(StrConv("tex", vbFromUnicode)), obj
objEffect.SetTechnique StrPtr(StrConv("mipmap4", vbFromUnicode))
objEffect.Begin 0, 0
objEffect.BeginPass 0
'////////
obj.GetLevelDesc 0, t
For i = 1 To m - 1
 v.x = 1 / t.Width
 v.y = 1 / t.Height
 objEffect.SetVector StrPtr(StrConv("pixelSize", vbFromUnicode)), v
 '////////
 obj.GetLevelDesc i, t
 p(3) = 1: p(4) = v.x / 2: p(5) = v.y / 2
 p(6) = t.Width: p(9) = 1: p(10) = p(4) + 1: p(11) = p(5)
 p(13) = t.Height: p(15) = 1: p(16) = p(4): p(17) = p(5) + 1
 p(18) = p(6): p(19) = p(13): p(21) = 1: p(22) = p(10): p(23) = p(17)
 '////////
 d3dd9.SetRenderTarget 0, obj.GetSurfaceLevel(i) '??? maybe wrong ???
 d3dd9.Clear 0, ByVal 0, D3DCLEAR_TARGET, 0, 1, 0
 d3dd9.BeginScene
 d3dd9.SetFVF D3DFVF_XYZRHW Or D3DFVF_TEX1
 d3dd9.DrawPrimitiveUP D3DPT_TRIANGLESTRIP, 2&, p(0), 24&
 d3dd9.EndScene
Next i
'////////
objEffect.EndPass
objEffect.End
d3dd9.SetRenderTarget 0, objOldTarget
d3dd9.SetDepthStencilSurface objOldStencil
Set objOldTarget = Nothing
Set objOldStencil = Nothing
End Sub

Private Sub Class_Terminate()
Set objEffect = Nothing
Set texNoise = Nothing
End Sub
