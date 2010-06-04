Attribute VB_Name = "mdlMain"
Option Explicit

#Const IsDebug = 1

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)

Public d3d9 As Direct3D9
Public d3dd9 As Direct3DDevice9

Public d3dpp As D3DPRESENT_PARAMETERS

Public Type typeVertex
 p As D3DVECTOR
 n As D3DVECTOR
 clr1 As Long 'diffuse
 clr2 As Long 'specular
 t As D3DXVECTOR2
End Type

Public Const m_nDefaultFVF = D3DFVF_XYZ Or D3DFVF_NORMAL Or D3DFVF_DIFFUSE Or D3DFVF_SPECULAR Or D3DFVF_TEX1

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

Public Function CreateEffect(ByVal s As String, ByRef d3dxe As D3DXEffect, Optional ByRef sError As String) As Boolean
Dim ret As Long
Dim s2 As String
Dim buf As D3DXBuffer
s = StrConv(s, vbFromUnicode)
'create effect
ret = D3DXCreateEffect(d3dd9, ByVal StrPtr(s), LenB(s), ByVal 0, ByVal 0, 0, Nothing, d3dxe, buf)
If ret < 0 Then
 s2 = "Can't create D3DXEffect!! &H" + Hex(ret)
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
 MsgBox s2
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

Public Sub SaveRenderTargetToFile(objSrc As Direct3DTexture9, ByVal fn As String, ByVal nFormat As D3DXIMAGE_FILEFORMAT)
Dim tDesc As D3DSURFACE_DESC
Dim tDesc2 As D3DSURFACE_DESC
Dim tLR As D3DLOCKED_RECT
Dim s As Direct3DSurface9
Dim d3dtex_sys As Direct3DTexture9
objSrc.GetLevelDesc 0, tDesc
If d3dtex_sys Is Nothing Then
 D3DXCreateTexture d3dd9, tDesc.Width, tDesc.Height, 1, 0, tDesc.Format, D3DPOOL_SYSTEMMEM, d3dtex_sys
 Debug.Assert Not d3dtex_sys Is Nothing
End If
Set s = d3dtex_sys.GetSurfaceLevel(0)
d3dd9.GetRenderTargetData objSrc.GetSurfaceLevel(0), s
'save file
D3DXSaveTextureToFileW fn, nFormat, d3dtex_sys, ByVal 0
End Sub

