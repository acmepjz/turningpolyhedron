VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsRenderTexture"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private objEffect As D3DXEffect
Private texNoise As Direct3DTexture9

Private objOldTarget As Direct3DSurface9
Private objOldStencil As Direct3DSurface9

Friend Sub OnLostDevice()
Set objOldTarget = Nothing
Set objOldStencil = Nothing
'///
objEffect.OnLostDevice
End Sub

Friend Sub OnResetDevice()
objEffect.OnResetDevice
End Sub

Friend Property Get Effect() As D3DXEffect
Set Effect = objEffect
End Property

Friend Sub Create()
'///
'test:perlin noise
CreateEffect CStr(App.Path) + "\data\shader\test.txt", objEffect, , True
'///
D3DXCreateTextureFromFileW d3dd9, CStr(App.Path) + "\data\gfx\noise.bmp", texNoise
End Sub

'Friend Sub BeginRender()
'Dim mat1 As D3DMATRIX, mat2 As D3DMATRIX, mat3 As D3DMATRIX, mat As D3DMATRIX
'd3dd9.GetTransform D3DTS_WORLD, mat1
'd3dd9.GetTransform D3DTS_VIEW, mat2
'd3dd9.GetTransform D3DTS_PROJECTION, mat3
'D3DXMatrixMultiply mat, mat1, mat2
'D3DXMatrixMultiply mat, mat, mat3
'''///test
''Dim v As D3DXVECTOR4
''v.X = 1
''v.Y = 1
''v.z = 2
''v.w = 1
''D3DXVec4Transform v, v, mat
''Debug.Print v.X / v.w, v.Y / v.w, v.z / v.w
'''///
'objEffect.SetMatrix StrPtr(StrConv("mat", vbFromUnicode)), mat
'objEffect.SetTexture StrPtr(StrConv("texNoise", vbFromUnicode)), texNoise
'objEffect.SetTechnique StrPtr(StrConv("test", vbFromUnicode))
'objEffect.Begin 0, 0
'objEffect.BeginPass 0
'End Sub

Friend Sub BeginRenderToTexture(ByVal obj As Direct3DTexture9, ByVal sTechniqueName As String, ByVal iParam1 As Long, ByVal iParam2 As Long, ByVal iParam3 As Long, ByVal iParam4 As Long, ByRef fParam1 As D3DXVECTOR4, ByRef fParam2 As D3DXVECTOR4, ByRef fParam3 As D3DXVECTOR4, ByRef fParam4 As D3DXVECTOR4)
'///dirty code
Dim fParam(1 To 4) As D3DXVECTOR4
fParam(1) = fParam1
fParam(2) = fParam2
fParam(3) = fParam3
fParam(4) = fParam4
objEffect.SetIntArray StrPtr(StrConv("_iParam", vbFromUnicode)), iParam1, 4&
objEffect.SetVectorArray StrPtr(StrConv("_fParam", vbFromUnicode)), fParam(1), 4&
'///
Set objOldTarget = d3dd9.GetRenderTarget(0)
Set objOldStencil = d3dd9.GetDepthStencilSurface
d3dd9.SetRenderTarget 0, obj.GetSurfaceLevel(0)
d3dd9.SetDepthStencilSurface Nothing
objEffect.SetTexture StrPtr(StrConv("texNoise", vbFromUnicode)), texNoise
objEffect.SetTechnique StrPtr(StrConv(sTechniqueName, vbFromUnicode))
objEffect.Begin 0, 0
objEffect.BeginPass 0
End Sub

'Friend Sub EndRender()
'objEffect.EndPass
'objEffect.End
'End Sub

Friend Sub EndRenderToTexture()
objEffect.EndPass
objEffect.End
d3dd9.SetRenderTarget 0, objOldTarget
d3dd9.SetDepthStencilSurface objOldStencil
Set objOldTarget = Nothing
Set objOldStencil = Nothing
End Sub

Friend Sub ProcessTexture(ByVal objSrc As Direct3DTexture9, ByVal objDest As Direct3DTexture9, ByVal sEffect As String)
ProcessTwoTextureEx objSrc, Nothing, objDest, sEffect, 0, 0, 0, 0, Vec4, Vec4, Vec4, Vec4
End Sub

Friend Sub ProcessTwoTexture(ByVal objSrc As Direct3DTexture9, ByVal objSrc2 As Direct3DTexture9, ByVal objDest As Direct3DTexture9, ByVal sEffect As String)
ProcessTwoTextureEx objSrc, objSrc2, objDest, sEffect, 0, 0, 0, 0, Vec4, Vec4, Vec4, Vec4
End Sub

Friend Sub ProcessTextureEx(ByVal objSrc As Direct3DTexture9, ByVal objDest As Direct3DTexture9, ByVal sEffect As String, ByVal iParam1 As Long, ByVal iParam2 As Long, ByVal iParam3 As Long, ByVal iParam4 As Long, ByRef fParam1 As D3DXVECTOR4, ByRef fParam2 As D3DXVECTOR4, ByRef fParam3 As D3DXVECTOR4, ByRef fParam4 As D3DXVECTOR4, Optional ByVal fPixelSizeScale As Single = 1)
ProcessTwoTextureEx objSrc, Nothing, objDest, sEffect, iParam1, iParam2, iParam3, iParam4, fParam1, fParam2, fParam3, fParam4, fPixelSizeScale
End Sub

Friend Sub ProcessTwoTextureEx(ByVal objSrc As Direct3DTexture9, ByVal objSrc2 As Direct3DTexture9, ByVal objDest As Direct3DTexture9, ByVal sEffect As String, ByVal iParam1 As Long, ByVal iParam2 As Long, ByVal iParam3 As Long, ByVal iParam4 As Long, ByRef fParam1 As D3DXVECTOR4, ByRef fParam2 As D3DXVECTOR4, ByRef fParam3 As D3DXVECTOR4, ByRef fParam4 As D3DXVECTOR4, Optional ByVal fPixelSizeScale As Single = 1)
Dim t As D3DSURFACE_DESC
Dim v As D3DXVECTOR4
Dim p(23) As Single
'///
If Not objSrc Is Nothing Then
 objSrc.GetLevelDesc 0, t
 v.x = 1 / t.Width
 v.y = 1 / t.Height
End If
objDest.GetLevelDesc 0, t
'///
p(3) = 1: p(4) = v.x / 2: p(5) = v.y / 2
p(6) = t.Width: p(9) = 1: p(10) = p(4) + 1: p(11) = p(5)
p(13) = t.Height: p(15) = 1: p(16) = p(4): p(17) = p(5) + 1
p(18) = p(6): p(19) = p(13): p(21) = 1: p(22) = p(10): p(23) = p(17)
'///
v.x = v.x * fPixelSizeScale
v.y = v.y * fPixelSizeScale
objEffect.SetVector StrPtr(StrConv("pixelSize", vbFromUnicode)), v
'///
Set objOldTarget = d3dd9.GetRenderTarget(0)
Set objOldStencil = d3dd9.GetDepthStencilSurface
d3dd9.SetRenderTarget 0, objDest.GetSurfaceLevel(0)
d3dd9.SetDepthStencilSurface Nothing
'///dirty code
Dim fParam(1 To 4) As D3DXVECTOR4
fParam(1) = fParam1
fParam(2) = fParam2
fParam(3) = fParam3
fParam(4) = fParam4
objEffect.SetIntArray StrPtr(StrConv("_iParam", vbFromUnicode)), iParam1, 4&
objEffect.SetVectorArray StrPtr(StrConv("_fParam", vbFromUnicode)), fParam(1), 4&
'///
objEffect.SetTexture StrPtr(StrConv("tex", vbFromUnicode)), objSrc
objEffect.SetTexture StrPtr(StrConv("tex2", vbFromUnicode)), objSrc2
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

Friend Sub DrawTexture(ByVal objSrc As Direct3DTexture9, ByVal sEffect As String)
DrawTwoTextureEx objSrc, Nothing, sEffect, 0, 0, 0, 0, Vec4, Vec4, Vec4, Vec4
End Sub

Friend Sub DrawTwoTexture(ByVal objSrc As Direct3DTexture9, ByVal objSrc2 As Direct3DTexture9, ByVal sEffect As String)
DrawTwoTextureEx objSrc, objSrc2, sEffect, 0, 0, 0, 0, Vec4, Vec4, Vec4, Vec4
End Sub

Friend Sub DrawTextureEx(ByVal objSrc As Direct3DTexture9, ByVal sEffect As String, ByVal iParam1 As Long, ByVal iParam2 As Long, ByVal iParam3 As Long, ByVal iParam4 As Long, ByRef fParam1 As D3DXVECTOR4, ByRef fParam2 As D3DXVECTOR4, ByRef fParam3 As D3DXVECTOR4, ByRef fParam4 As D3DXVECTOR4, Optional ByVal fPixelSizeScale As Single = 1)
DrawTwoTextureEx objSrc, Nothing, sEffect, iParam1, iParam2, iParam3, iParam4, fParam1, fParam2, fParam3, fParam4, fPixelSizeScale
End Sub

Friend Sub DrawTwoTextureEx(ByVal objSrc As Direct3DTexture9, ByVal objSrc2 As Direct3DTexture9, ByVal sEffect As String, ByVal iParam1 As Long, ByVal iParam2 As Long, ByVal iParam3 As Long, ByVal iParam4 As Long, ByRef fParam1 As D3DXVECTOR4, ByRef fParam2 As D3DXVECTOR4, ByRef fParam3 As D3DXVECTOR4, ByRef fParam4 As D3DXVECTOR4, Optional ByVal fPixelSizeScale As Single = 1)
Dim t As D3DSURFACE_DESC
Dim v As D3DXVECTOR4
Dim p(23) As Single
'///
If Not objSrc Is Nothing Then
 objSrc.GetLevelDesc 0, t
 v.x = 1 / t.Width
 v.y = 1 / t.Height
End If
'///
p(3) = 1: p(4) = v.x / 2: p(5) = v.y / 2
p(6) = d3dpp.BackBufferWidth: p(9) = 1: p(10) = p(4) + 1: p(11) = p(5)
p(13) = d3dpp.BackBufferHeight: p(15) = 1: p(16) = p(4): p(17) = p(5) + 1
p(18) = p(6): p(19) = p(13): p(21) = 1: p(22) = p(10): p(23) = p(17)
'///
v.x = v.x * fPixelSizeScale
v.y = v.y * fPixelSizeScale
objEffect.SetVector StrPtr(StrConv("pixelSize", vbFromUnicode)), v
'///dirty code
Dim fParam(1 To 4) As D3DXVECTOR4
fParam(1) = fParam1
fParam(2) = fParam2
fParam(3) = fParam3
fParam(4) = fParam4
objEffect.SetIntArray StrPtr(StrConv("_iParam", vbFromUnicode)), iParam1, 4&
objEffect.SetVectorArray StrPtr(StrConv("_fParam", vbFromUnicode)), fParam(1), 4&
'///
objEffect.SetTexture StrPtr(StrConv("tex", vbFromUnicode)), objSrc
objEffect.SetTexture StrPtr(StrConv("tex2", vbFromUnicode)), objSrc2
objEffect.SetTechnique StrPtr(StrConv(sEffect, vbFromUnicode))
objEffect.Begin 0, 0
objEffect.BeginPass 0
'////////
d3dd9.SetFVF D3DFVF_XYZRHW Or D3DFVF_TEX1
d3dd9.DrawPrimitiveUP D3DPT_TRIANGLESTRIP, 2&, p(0), 24&
'////////
objEffect.EndPass
objEffect.End
End Sub

Private Sub Class_Terminate()
Set objEffect = Nothing
Set texNoise = Nothing
End Sub
