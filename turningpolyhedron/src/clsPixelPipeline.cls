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

'Private objOldTarget As Direct3DSurface9
'Private objOldStencil As Direct3DSurface9

Friend Property Get Effect() As D3DXEffect
Set Effect = objEffect
End Property

Friend Sub Create()
'///
'test
Dim s As String, sErr As String
Open CStr(App.Path) + "\data\shader\pstest.txt" For Binary As #1
s = Input$(LOF(1), 1)
Close
'///
CreateEffect s, objEffect
'///
End Sub

Friend Sub SetLightDirection(d As D3DXVECTOR4, Optional ByVal bNormalize As Boolean)
Dim v As D3DXVECTOR4
If bNormalize Then
 D3DXVec4Normalize v, d
 objEffect.SetVector StrPtr(StrConv("lightDir", vbFromUnicode)), v
Else
 objEffect.SetVector StrPtr(StrConv("lightDir", vbFromUnicode)), d
End If
End Sub

Friend Sub SetLightDirectionByVal(ByVal x As Single, ByVal y As Single, ByVal z As Single, Optional ByVal bNormalize As Boolean)
Dim v As D3DXVECTOR4
v.x = x
v.y = y
v.z = z
If bNormalize Then D3DXVec4Normalize v, v
objEffect.SetVector StrPtr(StrConv("lightDir", vbFromUnicode)), v
End Sub

Friend Sub SetLightPosition(d As D3DXVECTOR4)
objEffect.SetVector StrPtr(StrConv("lightPos", vbFromUnicode)), d
End Sub

Friend Sub SetLightPositionByVal(ByVal x As Single, ByVal y As Single, ByVal z As Single)
Dim v As D3DXVECTOR4
v.x = x
v.y = y
v.z = z
objEffect.SetVector StrPtr(StrConv("lightPos", vbFromUnicode)), v
End Sub

Friend Sub SetViewPosition(d As D3DXVECTOR4)
objEffect.SetVector StrPtr(StrConv("viewPos", vbFromUnicode)), d
End Sub

Friend Sub SetViewPositionByVal(ByVal x As Single, ByVal y As Single, ByVal z As Single)
Dim v As D3DXVECTOR4
v.x = x
v.y = y
v.z = z
objEffect.SetVector StrPtr(StrConv("viewPos", vbFromUnicode)), v
End Sub

Friend Sub SetLightType(ByVal n As D3DLIGHTTYPE)
Dim i As Long
If n = D3DLIGHT_POINT Then i = 1 Else i = 0
objEffect.SetInt StrPtr(StrConv("lightType", vbFromUnicode)), i
End Sub

Friend Sub SetTexture(ByVal obj As Direct3DBaseTexture9)
objEffect.SetTexture StrPtr(StrConv("tex", vbFromUnicode)), obj
End Sub

Friend Sub SetNormalTexture(ByVal obj As Direct3DBaseTexture9)
objEffect.SetTexture StrPtr(StrConv("texNormal", vbFromUnicode)), obj
End Sub

Friend Sub BeginRender()
Dim mat1 As D3DMATRIX, mat2 As D3DMATRIX, mat3 As D3DMATRIX, mat As D3DMATRIX
d3dd9.GetTransform D3DTS_WORLD, mat1
objEffect.SetMatrix StrPtr(StrConv("matWorld", vbFromUnicode)), mat1
d3dd9.GetTransform D3DTS_VIEW, mat2
d3dd9.GetTransform D3DTS_PROJECTION, mat3
D3DXMatrixMultiply mat, mat1, mat2
D3DXMatrixMultiply mat, mat, mat3
D3DXMatrixInverse mat2, D3DXMatrixDeterminant(mat1), mat1
objEffect.SetMatrixTranspose StrPtr(StrConv("matWorld1", vbFromUnicode)), mat2
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

Private Sub Class_Terminate()
Set objEffect = Nothing
End Sub

