Attribute VB_Name = "mdlMain"
Option Explicit

#Const IsDebug = 1

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)

Public d3d9 As Direct3D9
Public d3dd9 As Direct3DDevice9

Public d3dpp As D3DPRESENT_PARAMETERS

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
