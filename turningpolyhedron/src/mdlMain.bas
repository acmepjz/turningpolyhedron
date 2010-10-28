Attribute VB_Name = "mdlMain"
Option Explicit

#Const IsDebug = 1

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)

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

Public Type typeFakeDXGDILogFont
 objFont As D3DXFont
 objSprite As D3DXSprite
End Type

Public objText As New clsGNUGetText

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

Public Function CreateEffect(ByVal s As String, ByRef d3dxe As D3DXEffect, Optional ByRef sError As String, Optional ByVal bFromFile As Boolean) As Boolean
Dim ret As Long
Dim s2 As String
Dim buf As D3DXBuffer
If bFromFile Then
 ret = D3DXCreateEffectFromFileW(d3dd9, s, ByVal 0, ByVal 0, 0, Nothing, d3dxe, buf)
Else
 s = StrConv(s, vbFromUnicode)
 'create effect
 ret = D3DXCreateEffect(d3dd9, ByVal StrPtr(s), LenB(s), ByVal 0, ByVal 0, 0, Nothing, d3dxe, buf)
End If
If ret < 0 Then
 s2 = objText.GetText("Can't create D3DXEffect!! Error number: ") + "&H" + Hex(ret)
 If Not buf Is Nothing Then
  ret = buf.GetBufferSize
  s = Space(ret)
  CopyMemory ByVal StrPtr(s), ByVal buf.GetBufferPointer, ret
  s = StrConv(s, vbUnicode)
  ret = InStr(1, s, vbNullChar)
  If ret > 0 Then s = Left(s, ret - 1)
  s2 = s2 + vbCrLf + s
 End If
 #If IsDebug Then
 MsgBox s2, vbExclamation, objText.GetText("Error")
 #End If
 sError = s2
 Set d3dxe = Nothing
Else
 CreateEffect = True
End If
End Function

Public Sub CopyRenderTargetData(objSrc As Direct3DTexture9, objDest As Direct3DTexture9)
Dim tDesc As D3DSURFACE_DESC
Dim tDesc2 As D3DSURFACE_DESC
Dim tLR As D3DLOCKED_RECT, tLR2 As D3DLOCKED_RECT
Dim s As Direct3DSurface9, s2 As Direct3DSurface9
Dim d3dtex_sys As Direct3DTexture9
objSrc.GetLevelDesc 0, tDesc
If d3dtex_sys Is Nothing Then
 D3DXCreateTexture d3dd9, tDesc.Width, tDesc.Height, 1, 0, tDesc.Format, D3DPOOL_SYSTEMMEM, d3dtex_sys
 Debug.Assert Not d3dtex_sys Is Nothing
End If
Set s = d3dtex_sys.GetSurfaceLevel(0)
d3dd9.GetRenderTargetData objSrc.GetSurfaceLevel(0), s
'copy memory
Set s2 = objDest.GetSurfaceLevel(0)
s.LockRect tLR, ByVal 0, D3DLOCK_READONLY
s2.LockRect tLR2, ByVal 0, 0
CopyMemory ByVal tLR2.pBits, ByVal tLR.pBits, tLR.Pitch * tDesc.Height
s.UnlockRect
s2.UnlockRect
End Sub

Public Sub SaveRenderTargetToFile(ByVal objSrc As Direct3DTexture9, ByVal fn As String, ByVal nFormat As D3DXIMAGE_FILEFORMAT, Optional ByVal nLevel As Long)
Dim tDesc As D3DSURFACE_DESC
Dim tDesc2 As D3DSURFACE_DESC
Dim tLR As D3DLOCKED_RECT
Dim d3dtex_sys As Direct3DTexture9
objSrc.GetLevelDesc nLevel, tDesc
If d3dtex_sys Is Nothing Then
 D3DXCreateTexture d3dd9, tDesc.Width, tDesc.Height, 1, 0, tDesc.Format, D3DPOOL_SYSTEMMEM, d3dtex_sys
 Debug.Assert Not d3dtex_sys Is Nothing
End If
d3dd9.GetRenderTargetData objSrc.GetSurfaceLevel(nLevel), d3dtex_sys.GetSurfaceLevel(0)
'save file
D3DXSaveTextureToFileW fn, nFormat, d3dtex_sys, ByVal 0
End Sub

Public Sub FakeDXGDIStretchBlt(ByVal nLeft As Single, ByVal nTop As Single, ByVal nRight As Single, ByVal nBottom As Single, ByVal nSrcLeft As Single, ByVal nSrcTop As Single, ByVal nSrcRight As Single, ByVal nSrcBottom As Single, ByVal nSize As Single)
Dim f(23) As Single
f(0) = nLeft: f(1) = nTop: f(3) = 1: f(4) = (nSrcLeft + 0.5) / nSize: f(5) = (nSrcTop + 0.5) / nSize
f(6) = nRight: f(7) = nTop: f(9) = 1: f(10) = (nSrcRight + 0.5) / nSize: f(11) = f(5)
f(12) = nLeft: f(13) = nBottom: f(15) = 1: f(16) = f(4): f(17) = (nSrcBottom + 0.5) / nSize
f(18) = nRight: f(19) = nBottom: f(21) = 1: f(22) = f(10): f(23) = f(17)
d3dd9.SetFVF D3DFVF_XYZRHW Or D3DFVF_TEX1
d3dd9.DrawPrimitiveUP D3DPT_TRIANGLESTRIP, 2&, f(0), 24&
End Sub

Public Sub FakeDXGDIStretchBltColored(ByVal nLeft As Single, ByVal nTop As Single, ByVal nRight As Single, ByVal nBottom As Single, ByVal nSrcLeft As Single, ByVal nSrcTop As Single, ByVal nSrcRight As Single, ByVal nSrcBottom As Single, ByVal nSize As Single, ByVal nColor As Long)
Dim f(27) As Single
CopyMemory f(4), nColor, 4&
f(0) = nLeft: f(1) = nTop: f(3) = 1: f(5) = (nSrcLeft + 0.5) / nSize: f(6) = (nSrcTop + 0.5) / nSize
f(7) = nRight: f(8) = nTop: f(10) = 1: f(11) = f(4): f(12) = (nSrcRight + 0.5) / nSize: f(13) = f(6)
f(14) = nLeft: f(15) = nBottom: f(17) = 1: f(18) = f(4): f(19) = f(5): f(20) = (nSrcBottom + 0.5) / nSize
f(21) = nRight: f(22) = nBottom: f(24) = 1: f(25) = f(4): f(26) = f(12): f(27) = f(20)
d3dd9.SetFVF D3DFVF_XYZRHW Or D3DFVF_DIFFUSE Or D3DFVF_TEX1
d3dd9.DrawPrimitiveUP D3DPT_TRIANGLESTRIP, 2&, f(0), 28&
End Sub

Public Sub FakeDXGDIFillRect(ByVal nLeft As Single, ByVal nTop As Single, ByVal nRight As Single, ByVal nBottom As Single, ByVal nColor As Long)
Dim f(19) As Single
Dim i(4) As Long
CopyMemory f(4), nColor, 4&
f(0) = nLeft: f(1) = nTop: f(3) = 1
f(5) = nRight: f(6) = nTop: f(8) = 1: f(9) = f(4)
f(10) = nLeft: f(11) = nBottom: f(13) = 1: f(14) = f(4)
f(15) = nRight: f(16) = nBottom: f(18) = 1: f(19) = f(4)
'///
i(4) = d3dd9.GetFVF
d3dd9.SetFVF D3DFVF_XYZRHW Or D3DFVF_DIFFUSE
i(0) = d3dd9.GetTextureStageState(0, D3DTSS_COLOROP)
i(1) = d3dd9.GetTextureStageState(0, D3DTSS_ALPHAOP)
i(2) = d3dd9.GetTextureStageState(0, D3DTSS_COLORARG2)
i(3) = d3dd9.GetTextureStageState(0, D3DTSS_ALPHAARG2)
d3dd9.SetTextureStageState 0, D3DTSS_COLOROP, D3DTOP_SELECTARG2
d3dd9.SetTextureStageState 0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG2
d3dd9.SetTextureStageState 0, D3DTSS_COLORARG2, D3DTA_DIFFUSE
d3dd9.SetTextureStageState 0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE
d3dd9.DrawPrimitiveUP D3DPT_TRIANGLESTRIP, 2&, f(0), 20&
d3dd9.SetFVF i(4)
d3dd9.SetTextureStageState 0, D3DTSS_COLOROP, i(0)
d3dd9.SetTextureStageState 0, D3DTSS_ALPHAOP, i(1)
d3dd9.SetTextureStageState 0, D3DTSS_COLORARG2, i(2)
d3dd9.SetTextureStageState 0, D3DTSS_ALPHAARG2, i(3)
End Sub

Public Sub FakeDXGDIGradientFillRect(ByVal nLeft As Single, ByVal nTop As Single, ByVal nRight As Single, ByVal nBottom As Single, ByVal nColor1 As Long, ByVal nColor2 As Long, ByVal bVertical As Boolean)
Dim f(19) As Single
Dim i(4) As Long
CopyMemory f(4), nColor1, 4&
If bVertical Then
 CopyMemory f(14), nColor2, 4&
 f(9) = f(4)
 f(19) = f(14)
Else
 CopyMemory f(9), nColor2, 4&
 f(14) = f(4)
 f(19) = f(9)
End If
f(0) = nLeft: f(1) = nTop: f(3) = 1
f(5) = nRight: f(6) = nTop: f(8) = 1
f(10) = nLeft: f(11) = nBottom: f(13) = 1
f(15) = nRight: f(16) = nBottom: f(18) = 1
'///
i(4) = d3dd9.GetFVF
d3dd9.SetFVF D3DFVF_XYZRHW Or D3DFVF_DIFFUSE
i(0) = d3dd9.GetTextureStageState(0, D3DTSS_COLOROP)
i(1) = d3dd9.GetTextureStageState(0, D3DTSS_ALPHAOP)
i(2) = d3dd9.GetTextureStageState(0, D3DTSS_COLORARG2)
i(3) = d3dd9.GetTextureStageState(0, D3DTSS_ALPHAARG2)
d3dd9.SetTextureStageState 0, D3DTSS_COLOROP, D3DTOP_SELECTARG2
d3dd9.SetTextureStageState 0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG2
d3dd9.SetTextureStageState 0, D3DTSS_COLORARG2, D3DTA_DIFFUSE
d3dd9.SetTextureStageState 0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE
d3dd9.DrawPrimitiveUP D3DPT_TRIANGLESTRIP, 2&, f(0), 20&
d3dd9.SetFVF i(4)
d3dd9.SetTextureStageState 0, D3DTSS_COLOROP, i(0)
d3dd9.SetTextureStageState 0, D3DTSS_ALPHAOP, i(1)
d3dd9.SetTextureStageState 0, D3DTSS_COLORARG2, i(2)
d3dd9.SetTextureStageState 0, D3DTSS_ALPHAARG2, i(3)
End Sub

Public Sub FakeDXGDIFrameRect(ByVal nLeft As Single, ByVal nTop As Single, ByVal nRight As Single, ByVal nBottom As Single, ByVal nColor As Long)
Dim f(24) As Single
Dim i(4) As Long
CopyMemory f(4), nColor, 4&
f(0) = nLeft: f(1) = nTop: f(3) = 1
f(5) = nRight: f(6) = nTop: f(8) = 1: f(9) = f(4)
f(10) = nLeft: f(11) = nBottom: f(13) = 1: f(14) = f(4)
f(15) = nRight: f(16) = nBottom: f(18) = 1: f(19) = f(4)
f(20) = nLeft: f(21) = nTop: f(23) = 1: f(24) = f(4)
'///
i(4) = d3dd9.GetFVF
d3dd9.SetFVF D3DFVF_XYZRHW Or D3DFVF_DIFFUSE
i(0) = d3dd9.GetTextureStageState(0, D3DTSS_COLOROP)
i(1) = d3dd9.GetTextureStageState(0, D3DTSS_ALPHAOP)
i(2) = d3dd9.GetTextureStageState(0, D3DTSS_COLORARG2)
i(3) = d3dd9.GetTextureStageState(0, D3DTSS_ALPHAARG2)
d3dd9.SetTextureStageState 0, D3DTSS_COLOROP, D3DTOP_SELECTARG2
d3dd9.SetTextureStageState 0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG2
d3dd9.SetTextureStageState 0, D3DTSS_COLORARG2, D3DTA_DIFFUSE
d3dd9.SetTextureStageState 0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE
d3dd9.DrawPrimitiveUP D3DPT_LINESTRIP, 4&, f(0), 20&
d3dd9.SetFVF i(4)
d3dd9.SetTextureStageState 0, D3DTSS_COLOROP, i(0)
d3dd9.SetTextureStageState 0, D3DTSS_ALPHAOP, i(1)
d3dd9.SetTextureStageState 0, D3DTSS_COLORARG2, i(2)
d3dd9.SetTextureStageState 0, D3DTSS_ALPHAARG2, i(3)
End Sub

Public Sub FakeDXGDIStretchBltBlended(ByVal nLeft As Single, ByVal nTop As Single, ByVal nRight As Single, ByVal nBottom As Single, ByVal nSrcLeft As Single, ByVal nSrcTop As Single, ByVal nSrcRight As Single, ByVal nSrcBottom As Single, ByVal nSize As Single, ByVal nSrcLeft2 As Single, ByVal nSrcTop2 As Single, ByVal nFactor As Long, ByVal nColor As Long)
Dim f(31) As Single
nSrcLeft2 = (nSrcLeft2 - nSrcLeft) / nSize
nSrcTop2 = (nSrcTop2 - nSrcTop) / nSize
f(0) = nLeft: f(1) = nTop: f(3) = 1: f(4) = (nSrcLeft + 0.5) / nSize: f(5) = (nSrcTop + 0.5) / nSize: f(6) = f(4) + nSrcLeft2: f(7) = f(5) + nSrcTop2
f(8) = nRight: f(9) = nTop: f(11) = 1: f(12) = (nSrcRight + 0.5) / nSize: f(13) = f(5): f(14) = f(12) + nSrcLeft2: f(15) = f(13) + nSrcTop2
f(16) = nLeft: f(17) = nBottom: f(19) = 1: f(20) = f(4): f(21) = (nSrcBottom + 0.5) / nSize: f(22) = f(20) + nSrcLeft2: f(23) = f(21) + nSrcTop2
f(24) = nRight: f(25) = nBottom: f(27) = 1: f(28) = f(12): f(29) = f(21): f(30) = f(28) + nSrcLeft2: f(31) = f(29) + nSrcTop2
'///
nFactor = nFactor And &HFF&
nFactor = nFactor Or (nFactor * &H100&)
nFactor = nFactor Or ((nFactor And &H7FFF&) * &H10000) Or ((nFactor > &H7FFF&) And &H80000000)
d3dd9.SetFVF D3DFVF_XYZRHW Or D3DFVF_TEX2
d3dd9.SetTextureStageState 0, D3DTSS_COLOROP, D3DTOP_SELECTARG1
d3dd9.SetTextureStageState 0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1
d3dd9.SetTextureStageState 1, D3DTSS_COLOROP, D3DTOP_LERP
d3dd9.SetTextureStageState 1, D3DTSS_COLORARG0, D3DTA_CONSTANT
d3dd9.SetTextureStageState 1, D3DTSS_COLORARG1, D3DTA_CURRENT
d3dd9.SetTextureStageState 1, D3DTSS_COLORARG2, D3DTA_TEXTURE
d3dd9.SetTextureStageState 1, D3DTSS_ALPHAOP, D3DTOP_LERP
d3dd9.SetTextureStageState 1, D3DTSS_ALPHAARG0, D3DTA_CONSTANT
d3dd9.SetTextureStageState 1, D3DTSS_ALPHAARG1, D3DTA_CURRENT
d3dd9.SetTextureStageState 1, D3DTSS_ALPHAARG2, D3DTA_TEXTURE
d3dd9.SetTextureStageState 1, D3DTSS_CONSTANT, nFactor
d3dd9.SetTextureStageState 2, D3DTSS_COLOROP, D3DTOP_MODULATE
d3dd9.SetTextureStageState 2, D3DTSS_COLORARG1, D3DTA_CURRENT
d3dd9.SetTextureStageState 2, D3DTSS_COLORARG2, D3DTA_CONSTANT
d3dd9.SetTextureStageState 2, D3DTSS_ALPHAOP, D3DTOP_MODULATE
d3dd9.SetTextureStageState 2, D3DTSS_ALPHAARG1, D3DTA_CURRENT
d3dd9.SetTextureStageState 2, D3DTSS_ALPHAARG2, D3DTA_CONSTANT
d3dd9.SetTextureStageState 2, D3DTSS_CONSTANT, nColor
d3dd9.SetTexture 1, d3dd9.GetTexture(0)
d3dd9.DrawPrimitiveUP D3DPT_TRIANGLESTRIP, 2&, f(0), 32&
d3dd9.SetTextureStageState 0, D3DTSS_COLOROP, D3DTOP_MODULATE
d3dd9.SetTextureStageState 0, D3DTSS_ALPHAOP, D3DTOP_MODULATE
d3dd9.SetTextureStageState 1, D3DTSS_COLOROP, D3DTOP_DISABLE
d3dd9.SetTextureStageState 1, D3DTSS_ALPHAOP, D3DTOP_DISABLE
d3dd9.SetTexture 1, Nothing
End Sub

Public Sub FakeDXGDIStretchBltEx(ByVal nLeft As Single, ByVal nTop As Single, ByVal nRight As Single, ByVal nBottom As Single, ByVal nSrcLeft As Single, ByVal nSrcTop As Single, ByVal nSrcRight As Single, ByVal nSrcBottom As Single, ByVal nLeftMargin As Single, ByVal nTopMargin As Single, ByVal nRightMargin As Single, ByVal nBottomMargin As Single, ByVal nSize As Single)
Dim f(103) As Single
Dim idx(53) As Integer
Dim i As Long, j As Long, k As Long, l As Long
Dim ii As Long, jj As Long
f(96) = (nSrcLeft + 0.5) / nSize
f(97) = (nSrcLeft + nLeftMargin + 0.5) / nSize
f(98) = (nSrcRight - nRightMargin + 0.5) / nSize
f(99) = (nSrcRight + 0.5) / nSize
f(100) = (nSrcTop + 0.5) / nSize
f(101) = (nSrcTop + nTopMargin + 0.5) / nSize
f(102) = (nSrcBottom - nBottomMargin + 0.5) / nSize
f(103) = (nSrcBottom + 0.5) / nSize
For i = 0 To 72 Step 24
 f(i) = nLeft: f(i + 3) = 1: f(i + 4) = f(96)
 f(i + 6) = nLeft + nLeftMargin: f(i + 9) = 1: f(i + 10) = f(97)
 f(i + 12) = nRight - nRightMargin: f(i + 15) = 1: f(i + 16) = f(98)
 f(i + 18) = nRight: f(i + 21) = 1: f(i + 22) = f(99)
Next i
For i = 1 To 19 Step 6
 f(i) = nTop: f(i + 4) = f(100)
 f(i + 24) = nTop + nTopMargin: f(i + 28) = f(101)
 f(i + 48) = nBottom - nBottomMargin: f(i + 52) = f(102)
 f(i + 72) = nBottom: f(i + 76) = f(103)
Next i
If f(6) < f(12) Then ii = 1 Else ii = 3
If f(25) < f(49) Then jj = 1 Else jj = 3
For j = 0 To 2 Step jj
 For i = 0 To 2 Step ii
  l = j * 4& + i
  idx(k) = l: idx(k + 1) = l + ii: idx(k + 2) = l + jj * 4&
  idx(k + 3) = idx(k + 1): idx(k + 4) = idx(k + 2) + ii: idx(k + 5) = idx(k + 2)
  k = k + 6
 Next i
Next j
d3dd9.SetFVF D3DFVF_XYZRHW Or D3DFVF_TEX1
d3dd9.DrawIndexedPrimitiveUP D3DPT_TRIANGLELIST, 0, 16, k \ 3&, idx(0), D3DFMT_INDEX16, f(0), 24&
End Sub

Public Sub FakeDXGDIStretchBltExColored(ByVal nLeft As Single, ByVal nTop As Single, ByVal nRight As Single, ByVal nBottom As Single, ByVal nSrcLeft As Single, ByVal nSrcTop As Single, ByVal nSrcRight As Single, ByVal nSrcBottom As Single, ByVal nLeftMargin As Single, ByVal nTopMargin As Single, ByVal nRightMargin As Single, ByVal nBottomMargin As Single, ByVal nSize As Single, ByVal nColor As Long)
Dim f(119) As Single, f1 As Single
Dim idx(53) As Integer
Dim i As Long, j As Long, k As Long, l As Long
Dim ii As Long, jj As Long
CopyMemory f1, nColor, 4&
f(112) = (nSrcLeft + 0.5) / nSize
f(113) = (nSrcLeft + nLeftMargin + 0.5) / nSize
f(114) = (nSrcRight - nRightMargin + 0.5) / nSize
f(115) = (nSrcRight + 0.5) / nSize
f(116) = (nSrcTop + 0.5) / nSize
f(117) = (nSrcTop + nTopMargin + 0.5) / nSize
f(118) = (nSrcBottom - nBottomMargin + 0.5) / nSize
f(119) = (nSrcBottom + 0.5) / nSize
For i = 0 To 84 Step 28
 f(i) = nLeft: f(i + 3) = 1: f(i + 4) = f1: f(i + 5) = f(112)
 f(i + 7) = nLeft + nLeftMargin: f(i + 10) = 1: f(i + 11) = f1: f(i + 12) = f(113)
 f(i + 14) = nRight - nRightMargin: f(i + 17) = 1: f(i + 18) = f1: f(i + 19) = f(114)
 f(i + 21) = nRight: f(i + 24) = 1: f(i + 25) = f1: f(i + 26) = f(115)
Next i
For i = 1 To 22 Step 7
 f(i) = nTop: f(i + 5) = f(116)
 f(i + 28) = nTop + nTopMargin: f(i + 33) = f(117)
 f(i + 56) = nBottom - nBottomMargin: f(i + 61) = f(118)
 f(i + 84) = nBottom: f(i + 89) = f(119)
Next i
If f(7) < f(14) Then ii = 1 Else ii = 3
If f(29) < f(57) Then jj = 1 Else jj = 3
For j = 0 To 2 Step jj
 For i = 0 To 2 Step ii
  l = j * 4& + i
  idx(k) = l: idx(k + 1) = l + ii: idx(k + 2) = l + jj * 4&
  idx(k + 3) = idx(k + 1): idx(k + 4) = idx(k + 2) + ii: idx(k + 5) = idx(k + 2)
  k = k + 6
 Next i
Next j
d3dd9.SetFVF D3DFVF_XYZRHW Or D3DFVF_DIFFUSE Or D3DFVF_TEX1
d3dd9.DrawIndexedPrimitiveUP D3DPT_TRIANGLELIST, 0, 16, k \ 3&, idx(0), D3DFMT_INDEX16, f(0), 28&
End Sub

Public Sub FakeDXGDIStretchBltExBlended(ByVal nLeft As Single, ByVal nTop As Single, ByVal nRight As Single, ByVal nBottom As Single, ByVal nSrcLeft As Single, ByVal nSrcTop As Single, ByVal nSrcRight As Single, ByVal nSrcBottom As Single, ByVal nLeftMargin As Single, ByVal nTopMargin As Single, ByVal nRightMargin As Single, ByVal nBottomMargin As Single, ByVal nSize As Single, ByVal nSrcLeft2 As Single, ByVal nSrcTop2 As Single, ByVal nFactor As Long, ByVal nColor As Long)
Dim f(135) As Single
Dim idx(53) As Integer
Dim i As Long, j As Long, k As Long, l As Long
Dim ii As Long, jj As Long
f(128) = (nSrcLeft + 0.5) / nSize
f(129) = (nSrcLeft + nLeftMargin + 0.5) / nSize
f(130) = (nSrcRight - nRightMargin + 0.5) / nSize
f(131) = (nSrcRight + 0.5) / nSize
f(132) = (nSrcTop + 0.5) / nSize
f(133) = (nSrcTop + nTopMargin + 0.5) / nSize
f(134) = (nSrcBottom - nBottomMargin + 0.5) / nSize
f(135) = (nSrcBottom + 0.5) / nSize
nSrcLeft2 = (nSrcLeft2 - nSrcLeft) / nSize
nSrcTop2 = (nSrcTop2 - nSrcTop) / nSize
For i = 0 To 96 Step 32
 f(i) = nLeft: f(i + 3) = 1: f(i + 4) = f(128): f(i + 6) = f(128) + nSrcLeft2
 f(i + 8) = nLeft + nLeftMargin: f(i + 11) = 1: f(i + 12) = f(129): f(i + 14) = f(129) + nSrcLeft2
 f(i + 16) = nRight - nRightMargin: f(i + 19) = 1: f(i + 20) = f(130): f(i + 22) = f(130) + nSrcLeft2
 f(i + 24) = nRight: f(i + 27) = 1: f(i + 28) = f(131): f(i + 30) = f(131) + nSrcLeft2
Next i
For i = 1 To 25 Step 8
 f(i) = nTop: f(i + 4) = f(132): f(i + 6) = f(132) + nSrcTop2
 f(i + 32) = nTop + nTopMargin: f(i + 36) = f(133): f(i + 38) = f(133) + nSrcTop2
 f(i + 64) = nBottom - nBottomMargin: f(i + 68) = f(134): f(i + 70) = f(134) + nSrcTop2
 f(i + 96) = nBottom: f(i + 100) = f(135): f(i + 102) = f(135) + nSrcTop2
Next i
If f(8) < f(16) Then ii = 1 Else ii = 3
If f(33) < f(65) Then jj = 1 Else jj = 3
For j = 0 To 2 Step jj
 For i = 0 To 2 Step ii
  l = j * 4& + i
  idx(k) = l: idx(k + 1) = l + ii: idx(k + 2) = l + jj * 4&
  idx(k + 3) = idx(k + 1): idx(k + 4) = idx(k + 2) + ii: idx(k + 5) = idx(k + 2)
  k = k + 6
 Next i
Next j
'///
nFactor = nFactor And &HFF&
nFactor = nFactor Or (nFactor * &H100&)
nFactor = nFactor Or ((nFactor And &H7FFF&) * &H10000) Or ((nFactor > &H7FFF&) And &H80000000)
d3dd9.SetFVF D3DFVF_XYZRHW Or D3DFVF_TEX2
d3dd9.SetTextureStageState 0, D3DTSS_COLOROP, D3DTOP_SELECTARG1
d3dd9.SetTextureStageState 0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1
d3dd9.SetTextureStageState 1, D3DTSS_COLOROP, D3DTOP_LERP
d3dd9.SetTextureStageState 1, D3DTSS_COLORARG0, D3DTA_CONSTANT
d3dd9.SetTextureStageState 1, D3DTSS_COLORARG1, D3DTA_CURRENT
d3dd9.SetTextureStageState 1, D3DTSS_COLORARG2, D3DTA_TEXTURE
d3dd9.SetTextureStageState 1, D3DTSS_ALPHAOP, D3DTOP_LERP
d3dd9.SetTextureStageState 1, D3DTSS_ALPHAARG0, D3DTA_CONSTANT
d3dd9.SetTextureStageState 1, D3DTSS_ALPHAARG1, D3DTA_CURRENT
d3dd9.SetTextureStageState 1, D3DTSS_ALPHAARG2, D3DTA_TEXTURE
d3dd9.SetTextureStageState 1, D3DTSS_CONSTANT, nFactor
d3dd9.SetTextureStageState 2, D3DTSS_COLOROP, D3DTOP_MODULATE
d3dd9.SetTextureStageState 2, D3DTSS_COLORARG1, D3DTA_CURRENT
d3dd9.SetTextureStageState 2, D3DTSS_COLORARG2, D3DTA_CONSTANT
d3dd9.SetTextureStageState 2, D3DTSS_ALPHAOP, D3DTOP_MODULATE
d3dd9.SetTextureStageState 2, D3DTSS_ALPHAARG1, D3DTA_CURRENT
d3dd9.SetTextureStageState 2, D3DTSS_ALPHAARG2, D3DTA_CONSTANT
d3dd9.SetTextureStageState 2, D3DTSS_CONSTANT, nColor
d3dd9.SetTexture 1, d3dd9.GetTexture(0)
d3dd9.DrawIndexedPrimitiveUP D3DPT_TRIANGLELIST, 0, 16, k \ 3&, idx(0), D3DFMT_INDEX16, f(0), 32&
d3dd9.SetTextureStageState 0, D3DTSS_COLOROP, D3DTOP_MODULATE
d3dd9.SetTextureStageState 0, D3DTSS_ALPHAOP, D3DTOP_MODULATE
d3dd9.SetTextureStageState 1, D3DTSS_COLOROP, D3DTOP_DISABLE
d3dd9.SetTextureStageState 1, D3DTSS_ALPHAOP, D3DTOP_DISABLE
d3dd9.SetTexture 1, Nothing
End Sub

Public Sub FakeDXGDIDrawText(ByRef tFont As typeFakeDXGDILogFont, ByVal lpStr As String, ByVal nLeft As Single, ByVal nTop As Single, Optional ByVal nWidth As Long, Optional ByVal nHeight As Long, Optional ByVal nZoom As Single = 1, Optional ByVal wFormat As D3DXDRAWTEXTFORMAT, _
Optional ByVal nColor As Long = -1, Optional ByVal nTextLODBias As Single = -0.5, Optional ByVal nShadowColor As Long = 0, Optional ByVal nShadowOffsetX As Long = 2, Optional ByVal nShadowOffsetY As Long = 2, Optional ByVal nShadowLODBias As Single = 1.5, Optional ByVal nAngle As Single, Optional ByVal bSingle As Boolean, Optional ByRef nWidthReturn As Single, Optional ByRef nHeightReturn As Single)
Dim mat As D3DMATRIX
Dim p As D3DRECT
Dim obj As Direct3DDevice9
If bSingle Then tFont.objSprite.Begin D3DXSPRITE_ALPHABLEND
Set obj = tFont.objSprite.GetDevice
mat.m11 = nZoom * Cos(nAngle)
mat.m12 = nZoom * Sin(nAngle)
mat.m21 = -mat.m12
mat.m22 = mat.m11
mat.m33 = 1
mat.m41 = nLeft
mat.m42 = nTop
mat.m44 = 1
nWidth = nWidth / nZoom
nHeight = nHeight / nZoom
tFont.objSprite.SetTransform mat
If nShadowColor Then
 p.x1 = nShadowOffsetX
 p.y1 = nShadowOffsetY
 p.x2 = nWidth + nShadowOffsetX
 p.Y2 = nHeight + nShadowOffsetY
 obj.SetSamplerState 0, D3DSAMP_MIPMAPLODBIAS, SingleToLong(nShadowLODBias)
 tFont.objFont.DrawTextW tFont.objSprite, ByVal StrPtr(lpStr), -1, p, wFormat And Not DT_CALCRECT, nShadowColor
 tFont.objSprite.Flush
End If
If nColor Then
 p.x1 = 0
 p.y1 = 0
 p.x2 = nWidth
 p.Y2 = nHeight
 obj.SetSamplerState 0, D3DSAMP_MIPMAPLODBIAS, SingleToLong(nTextLODBias)
 If wFormat And DT_CALCRECT Then
  tFont.objFont.DrawTextW tFont.objSprite, ByVal StrPtr(lpStr), -1, p, wFormat, nColor
  nWidthReturn = p.x2 * nZoom
  nHeightReturn = p.Y2 * nZoom
 End If
 tFont.objFont.DrawTextW tFont.objSprite, ByVal StrPtr(lpStr), -1, p, wFormat And Not DT_CALCRECT, nColor
 tFont.objSprite.Flush
End If
If bSingle Then tFont.objSprite.End
End Sub

'Public Sub FakeDXGDIMaskBltExEx(ByVal nLeft As Single, ByVal nTop As Single, ByVal nRight As Single, ByVal nBottom As Single, ByVal nSrcLeft As Single, ByVal nSrcTop As Single, ByVal nSrcRight As Single, ByVal nSrcBottom As Single, _
'ByVal nLeftMargin As Single, ByVal nTopMargin As Single, ByVal nRightMargin As Single, ByVal nBottomMargin As Single, ByVal nSize As Single, _
'ByVal objTexture2 As Direct3DTexture9, ByVal nSrcLeft2 As Single, ByVal nSrcTop2 As Single, ByVal nSrcRight2 As Single, ByVal nSrcBottom2 As Single, _
'ByVal nLeftMargin2 As Single, ByVal nTopMargin2 As Single, ByVal nRightMargin2 As Single, ByVal nBottomMargin2 As Single, ByVal nSize2 As Single, _
'ByVal nColor As Long, ByVal nMipFilter As D3DTEXTUREFILTERTYPE, ByVal nMinFilter As D3DTEXTUREFILTERTYPE, ByVal nMagFilter As D3DTEXTUREFILTERTYPE)
''Dim f(135) As Single
''Dim idx(53) As Integer
''Dim i As Long, j As Long, k As Long, l As Long
''Dim ii As Long, jj As Long
''f(128) = (nSrcLeft + 0.5) / nSize
''f(129) = (nSrcLeft + nLeftMargin + 0.5) / nSize
''f(130) = (nSrcRight - nRightMargin + 0.5) / nSize
''f(131) = (nSrcRight + 0.5) / nSize
''f(132) = (nSrcTop + 0.5) / nSize
''f(133) = (nSrcTop + nTopMargin + 0.5) / nSize
''f(134) = (nSrcBottom - nBottomMargin + 0.5) / nSize
''f(135) = (nSrcBottom + 0.5) / nSize
''nSrcLeft2 = (nSrcLeft2 - nSrcLeft) / nSize
''nSrcTop2 = (nSrcTop2 - nSrcTop) / nSize
''For i = 0 To 96 Step 32
'' f(i) = nLeft: f(i + 3) = 1: f(i + 4) = f(128): f(i + 6) = f(128) + nSrcLeft2
'' f(i + 8) = nLeft + nLeftMargin: f(i + 11) = 1: f(i + 12) = f(129): f(i + 14) = f(129) + nSrcLeft2
'' f(i + 16) = nRight - nRightMargin: f(i + 19) = 1: f(i + 20) = f(130): f(i + 22) = f(130) + nSrcLeft2
'' f(i + 24) = nRight: f(i + 27) = 1: f(i + 28) = f(131): f(i + 30) = f(131) + nSrcLeft2
''Next i
''For i = 1 To 25 Step 8
'' f(i) = nTop: f(i + 4) = f(132): f(i + 6) = f(132) + nSrcTop2
'' f(i + 32) = nTop + nTopMargin: f(i + 36) = f(133): f(i + 38) = f(133) + nSrcTop2
'' f(i + 64) = nBottom - nBottomMargin: f(i + 68) = f(134): f(i + 70) = f(134) + nSrcTop2
'' f(i + 96) = nBottom: f(i + 100) = f(135): f(i + 102) = f(135) + nSrcTop2
''Next i
''If f(8) < f(16) Then ii = 1 Else ii = 3
''If f(33) < f(65) Then jj = 1 Else jj = 3
''For j = 0 To 2 Step jj
'' For i = 0 To 2 Step ii
''  l = j * 4& + i
''  idx(k) = l: idx(k + 1) = l + ii: idx(k + 2) = l + jj * 4&
''  idx(k + 3) = idx(k + 1): idx(k + 4) = idx(k + 2) + ii: idx(k + 5) = idx(k + 2)
''  k = k + 6
'' Next i
''Next j
'''///
''nFactor = nFactor And &HFF&
''nFactor = nFactor Or (nFactor * &H100&)
''nFactor = nFactor Or ((nFactor And &H7FFF&) * &H10000) Or ((nFactor > &H7FFF&) And &H80000000)
''d3dd9.SetFVF D3DFVF_XYZRHW Or D3DFVF_TEX2
''d3dd9.SetTextureStageState 0, D3DTSS_COLOROP, D3DTOP_SELECTARG1
''d3dd9.SetTextureStageState 0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1
''d3dd9.SetTextureStageState 1, D3DTSS_COLOROP, D3DTOP_LERP
''d3dd9.SetTextureStageState 1, D3DTSS_COLORARG0, D3DTA_CONSTANT
''d3dd9.SetTextureStageState 1, D3DTSS_COLORARG1, D3DTA_CURRENT
''d3dd9.SetTextureStageState 1, D3DTSS_COLORARG2, D3DTA_TEXTURE
''d3dd9.SetTextureStageState 1, D3DTSS_ALPHAOP, D3DTOP_LERP
''d3dd9.SetTextureStageState 1, D3DTSS_ALPHAARG0, D3DTA_CONSTANT
''d3dd9.SetTextureStageState 1, D3DTSS_ALPHAARG1, D3DTA_CURRENT
''d3dd9.SetTextureStageState 1, D3DTSS_ALPHAARG2, D3DTA_TEXTURE
''d3dd9.SetTextureStageState 1, D3DTSS_CONSTANT, nFactor
''d3dd9.SetTextureStageState 2, D3DTSS_COLOROP, D3DTOP_MODULATE
''d3dd9.SetTextureStageState 2, D3DTSS_COLORARG1, D3DTA_CURRENT
''d3dd9.SetTextureStageState 2, D3DTSS_COLORARG2, D3DTA_CONSTANT
''d3dd9.SetTextureStageState 2, D3DTSS_ALPHAOP, D3DTOP_MODULATE
''d3dd9.SetTextureStageState 2, D3DTSS_ALPHAARG1, D3DTA_CURRENT
''d3dd9.SetTextureStageState 2, D3DTSS_ALPHAARG2, D3DTA_CONSTANT
''d3dd9.SetTextureStageState 2, D3DTSS_CONSTANT, nColor
''d3dd9.SetTexture 1, d3dd9.GetTexture(0)
''d3dd9.DrawIndexedPrimitiveUP D3DPT_TRIANGLELIST, 0, 16, k \ 3&, idx(0), D3DFMT_INDEX16, f(0), 32&
''d3dd9.SetTextureStageState 0, D3DTSS_COLOROP, D3DTOP_MODULATE
''d3dd9.SetTextureStageState 0, D3DTSS_ALPHAOP, D3DTOP_MODULATE
''d3dd9.SetTextureStageState 1, D3DTSS_COLOROP, D3DTOP_DISABLE
''d3dd9.SetTextureStageState 1, D3DTSS_ALPHAOP, D3DTOP_DISABLE
''d3dd9.SetTexture 1, Nothing
'End Sub
