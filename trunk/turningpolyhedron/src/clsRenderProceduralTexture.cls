VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsTextureManager"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'TextureManager: store texture load from file or procedural generated
'and perform procedural texture generation

'TODO:use collection for fast look up (?)

Private Type typeTextMgrData
 sName As String
 objTexture As Direct3DBaseTexture9
End Type

Private m_tData() As typeTextMgrData
Private m_nCount As Long

Private objEffect As D3DXEffect
Private texNoise As Direct3DTexture9

Private objOldTarget As Direct3DSurface9
Private objOldStencil As Direct3DSurface9

Friend Sub Clear()
Erase m_tData
m_nCount = 0
End Sub

Friend Function AddTexture(ByVal obj As Direct3DBaseTexture9, Optional ByVal sName As String) As Long
Dim i As Long, j As Long
If Not obj Is Nothing Then
 For i = 1 To m_nCount
  If obj Is m_tData(i).objTexture Then
   AddTexture = i
   Exit Function
  ElseIf m_tData(i).objTexture Is Nothing Then
   j = i
  End If
 Next i
 '///
 If j = 0 Then
  m_nCount = m_nCount + 1
  ReDim Preserve m_tData(1 To m_nCount)
  j = m_nCount
 End If
 '///
 With m_tData(j)
  .sName = sName
  Set .objTexture = obj
 End With
 AddTexture = j
End If
End Function

Friend Function AddTextureFromRenderTarget(ByVal obj As Direct3DTexture9, Optional ByVal sName As String) As Long
Dim obj2 As Direct3DTexture9
CopyRenderTargetData obj, obj2
AddTextureFromRenderTarget = AddTexture(obj2, sName)
End Function

'TODO:load file options
Friend Function AddTextureFromFile(ByVal sName As String, Optional ByVal f As clsFileManager) As Long
Dim i As Long, j As Long
Dim obj As Direct3DTexture9
'///
'TODO:case insensitive (???)
For i = 1 To m_nCount
 If sName = m_tData(i).sName Then
  AddTextureFromFile = i
  Exit Function
 ElseIf m_tData(i).objTexture Is Nothing Then
  j = i
 End If
Next i
'///
If j = 0 Then
 m_nCount = m_nCount + 1
 ReDim Preserve m_tData(1 To m_nCount)
 j = m_nCount
End If
'///
If f Is Nothing Then
 D3DXCreateTextureFromFileW d3dd9, sName, obj
Else
 i = f.LoadFile(sName)
 If i = 0 Then Exit Function
 D3DXCreateTextureFromFileInMemory d3dd9, ByVal f.FilePointer(i), f.FileSize(i), obj
End If
'///
If obj Is Nothing Then Exit Function
With m_tData(j)
 .sName = sName
 Set .objTexture = obj
End With
AddTextureFromFile = j
End Function

Friend Property Get TextureName(ByVal nIndex As Long) As String
If nIndex > 0 And nIndex <= m_nCount Then _
TextureName = m_tData(nIndex).sName
End Property

Friend Property Let TextureName(ByVal nIndex As Long, ByRef s As String)
If nIndex > 0 And nIndex <= m_nCount Then _
m_tData(nIndex).sName = s
End Property

Friend Property Get Texture(ByVal nIndex As Long) As Direct3DBaseTexture9
If nIndex > 0 And nIndex <= m_nCount Then _
Set Texture = m_tData(nIndex).objTexture
End Property

Friend Property Set Texture(ByVal nIndex As Long, ByVal obj As Direct3DBaseTexture9)
If nIndex > 0 And nIndex <= m_nCount Then _
Set m_tData(nIndex).objTexture = obj
End Property

Friend Property Get TextureCount() As Long
TextureCount = m_nCount
End Property

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

Friend Sub ProcessTexture(ByVal objSrc As Direct3DTexture9, ByVal objDest As Direct3DTexture9, ByVal sEffect As String, Optional ByVal fPixelSizeScale As Single = 1, Optional ByVal bErase As Boolean = True)
ProcessTwoTextureEx objSrc, Nothing, objDest, sEffect, 0, 0, 0, 0, Vec4, Vec4, Vec4, Vec4, fPixelSizeScale, bErase
End Sub

Friend Sub ProcessTwoTexture(ByVal objSrc As Direct3DTexture9, ByVal objSrc2 As Direct3DTexture9, ByVal objDest As Direct3DTexture9, ByVal sEffect As String, Optional ByVal fPixelSizeScale As Single = 1, Optional ByVal bErase As Boolean = True)
ProcessTwoTextureEx objSrc, objSrc2, objDest, sEffect, 0, 0, 0, 0, Vec4, Vec4, Vec4, Vec4, fPixelSizeScale, bErase
End Sub

Friend Sub ProcessTextureEx(ByVal objSrc As Direct3DTexture9, ByVal objDest As Direct3DTexture9, ByVal sEffect As String, ByVal iParam1 As Long, ByVal iParam2 As Long, ByVal iParam3 As Long, ByVal iParam4 As Long, ByRef fParam1 As D3DXVECTOR4, ByRef fParam2 As D3DXVECTOR4, ByRef fParam3 As D3DXVECTOR4, ByRef fParam4 As D3DXVECTOR4, Optional ByVal fPixelSizeScale As Single = 1, Optional ByVal bErase As Boolean = True)
ProcessTwoTextureEx objSrc, Nothing, objDest, sEffect, iParam1, iParam2, iParam3, iParam4, fParam1, fParam2, fParam3, fParam4, fPixelSizeScale, bErase
End Sub

Friend Sub ProcessTwoTextureEx(ByVal objSrc As Direct3DTexture9, ByVal objSrc2 As Direct3DTexture9, ByVal objDest As Direct3DTexture9, ByVal sEffect As String, ByVal iParam1 As Long, ByVal iParam2 As Long, ByVal iParam3 As Long, ByVal iParam4 As Long, ByRef fParam1 As D3DXVECTOR4, ByRef fParam2 As D3DXVECTOR4, ByRef fParam3 As D3DXVECTOR4, ByRef fParam4 As D3DXVECTOR4, Optional ByVal fPixelSizeScale As Single = 1, Optional ByVal bErase As Boolean = True)
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
If bErase Then d3dd9.Clear 0, ByVal 0, D3DCLEAR_TARGET, 0, 1, 0
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

Friend Sub DrawTexture(ByVal objSrc As Direct3DTexture9, ByVal sEffect As String, Optional ByVal fPixelSizeScale As Single = 1, Optional ByVal bErase As Boolean)
DrawTwoTextureEx objSrc, Nothing, sEffect, 0, 0, 0, 0, Vec4, Vec4, Vec4, Vec4, fPixelSizeScale, bErase
End Sub

Friend Sub DrawTwoTexture(ByVal objSrc As Direct3DTexture9, ByVal objSrc2 As Direct3DTexture9, ByVal sEffect As String, Optional ByVal fPixelSizeScale As Single = 1, Optional ByVal bErase As Boolean)
DrawTwoTextureEx objSrc, objSrc2, sEffect, 0, 0, 0, 0, Vec4, Vec4, Vec4, Vec4, fPixelSizeScale, bErase
End Sub

Friend Sub DrawTextureEx(ByVal objSrc As Direct3DTexture9, ByVal sEffect As String, ByVal iParam1 As Long, ByVal iParam2 As Long, ByVal iParam3 As Long, ByVal iParam4 As Long, ByRef fParam1 As D3DXVECTOR4, ByRef fParam2 As D3DXVECTOR4, ByRef fParam3 As D3DXVECTOR4, ByRef fParam4 As D3DXVECTOR4, Optional ByVal fPixelSizeScale As Single = 1, Optional ByVal bErase As Boolean)
DrawTwoTextureEx objSrc, Nothing, sEffect, iParam1, iParam2, iParam3, iParam4, fParam1, fParam2, fParam3, fParam4, fPixelSizeScale, bErase
End Sub

Friend Sub DrawTwoTextureEx(ByVal objSrc As Direct3DTexture9, ByVal objSrc2 As Direct3DTexture9, ByVal sEffect As String, ByVal iParam1 As Long, ByVal iParam2 As Long, ByVal iParam3 As Long, ByVal iParam4 As Long, ByRef fParam1 As D3DXVECTOR4, ByRef fParam2 As D3DXVECTOR4, ByRef fParam3 As D3DXVECTOR4, ByRef fParam4 As D3DXVECTOR4, Optional ByVal fPixelSizeScale As Single = 1, Optional ByVal bErase As Boolean)
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
If bErase Then d3dd9.Clear 0, ByVal 0, D3DCLEAR_TARGET, 0, 1, 0
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
