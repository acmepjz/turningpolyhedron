VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsMeshManager"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)

Private Type typeMeshParamData
 nType As Long
 '///
 'bit0-7:
 '1,2=color0-1
 '&H10-&H1F=texcoord0-15
 '---
 'bit8-15:xyzw ?
 '///
 sValue As String
End Type

Private Type typeMeshOptionalData
 nFlags As Long
 'bit 0-1=bevel (0-2)
 '///
 fNormalSmoothness As Long
 fBevelNormalSmoothness As Long
 '///
 nParamCount As Long
 tParams() As typeMeshParamData
 '///
 fPos(3) As D3DXVECTOR4
 fRotation As D3DXVECTOR4
 fScale As D3DXVECTOR4
 fCenter As D3DXVECTOR4
 '///
 fBevel As D3DXVECTOR4
End Type

Private Type typeMeshMgrData
 nType As Long
 '0=unused
 '1=cube
 'TODO:...
 '///
 nVertexCount As Long
 nFaceCount As Long
 FVF As D3DFVFFLAGS 'only used D3DFVF_DIFFUSE, D3DFVF_SPECULAR and D3DFVF_TEX*
 '///
 objMesh As D3DXMesh
End Type

Private m_tData() As typeMeshMgrData
Private m_nCount As Long
Private m_nMax As Long

Friend Sub Destroy()
Erase m_tData
m_nCount = 0
m_nMax = 0
End Sub

Friend Function pReadVec4(ByVal s As String, ByRef t As D3DXVECTOR4) As Boolean
Dim v As Variant, i As Long
Dim f(3) As Double
'///
v = Split(s, ",")
For i = 0 To UBound(v)
 s = Trim(v(i))
 f(i) = Val(s)
 If LCase(Right(s, 1)) = "d" Then
  f(i) = f(i) * 1.74532925199433E-02
 End If
 If i >= 3 Then Exit For
Next i
'///
t.x = f(0)
t.y = f(1)
t.z = f(2)
t.w = f(3)
'///
pReadVec4 = True
End Function

Friend Function pReadComponent(ByVal s As String, ByRef n As Long) As Boolean
Dim i As Long, j As Long, k As Long
n = (n And &HFFFF00FF) Or &HE400&
i = InStr(1, s, ".")
If i > 0 Then
 s = Mid(s, i + 1, 4)
 j = &H100&
 For i = 1 To Len(s)
  Select Case Mid(s, i, 1)
  Case "x", "r": k = 0
  Case "y", "g": k = 1
  Case "z", "b": k = 2
  Case "w", "a": k = 3
  Case Else
   Exit Function
  End Select
  n = (n And Not (j * 3&)) Or (j * k)
  j = j * 4&
 Next i
End If
pReadComponent = True
End Function

Friend Function pCreateCube(ByRef t As typeMeshMgrData, ByRef t2 As typeMeshOptionalData) As Boolean
'TODO:
End Function

Friend Function AddMeshFromNode(ByVal objNode As clsTreeStorageNode) As Long
On Error Resume Next
Dim t As typeMeshMgrData, t2 As typeMeshOptionalData
Dim i As Long, j As Long, k As Long, m As Long
Dim s As String
Dim v As Variant
Dim f As Single
'///
s = objNode.GetNameAsString
Select Case s
Case "meshTemplate"
 'TODO:
 Debug.Assert False
 Exit Function
Case "mesh"
Case Else
 Debug.Assert False
 Exit Function
End Select
'///
For i = 1 To objNode.SubNodeCount
 If objNode.SubNodeType(i) = 0 Then
  s = objNode.GetSubNodeNameAsString(i)
  Select Case s
  Case vbNullString
  Case "templateName"
   'TODO:
   Debug.Assert False
   Exit Function
  Case "type"
   s = objNode.GetSubNodeValueAsString(i)
   Select Case s
   Case "cube"
    t.nType = 1
    '///
    t2.fScale = Vec4(1, 1, 1, 1)
    t2.fPos(1) = Vec4(1)
    t2.fPos(2) = Vec4(, 1)
    t2.fPos(3) = Vec4(, , 1)
    '///
   Case Else
    Debug.Assert False
    Exit Function
   End Select
  Case "p", "p1", "p2", "p3"
   If Not pReadVec4(objNode.GetSubNodeValueAsString(i), t2.fPos(Val(Mid(s, 2)))) Then Exit Function
'  Case "p1"
'   If Not pReadVec4(objNode.GetSubNodeValueAsString(i), t2.fPos(1)) Then Exit Function
'  Case "p2"
'   If Not pReadVec4(objNode.GetSubNodeValueAsString(i), t2.fPos(2)) Then Exit Function
'  Case "p3"
'   If Not pReadVec4(objNode.GetSubNodeValueAsString(i), t2.fPos(3)) Then Exit Function
  Case "r"
   If Not pReadVec4(objNode.GetSubNodeValueAsString(i), t2.fRotation) Then Exit Function
  Case "s"
   If Not pReadVec4(objNode.GetSubNodeValueAsString(i), t2.fScale) Then Exit Function
  Case "c"
   If Not pReadVec4(objNode.GetSubNodeValueAsString(i), t2.fCenter) Then Exit Function
  Case "bevel"
   s = objNode.GetSubNodeValueAsString(i)
   j = Val(s)
   t2.nFlags = (t2.nFlags And &HFFFFFFFC) Or (j And &H3&)
   If j = 0 Then
   ElseIf j > 0 And j <= 2 Then
    j = InStr(1, s, ";")
    If j > 0 Then
     v = Split(Mid(s, j + 1), ",")
     m = UBound(v)
     For j = 0 To m
      s = Trim(v(j))
      If Right(s, 1) = "%" Then f = Val(Left(s, Len(s) - 1)) / 100 _
      Else f = -Val(s)
      If j = 0 Then
       t2.fBevel.x = f
      ElseIf j = 1 Then
       t2.fBevel.y = f
      Else
       t2.fBevel.z = f
       Exit For
      End If
     Next j
     If m = 0 Then
      t2.fBevel.y = t2.fBevel.x
      t2.fBevel.z = t2.fBevel.x
     End If
    End If
   Else
    Debug.Assert False
    Exit Function
   End If
  Case "bevelNormalSmoothness"
   t2.fBevelNormalSmoothness = Val(objNode.GetSubNodeValueAsString(i))
  Case "normalSmoothness"
   t2.fNormalSmoothness = Val(objNode.GetSubNodeValueAsString(i))
  Case Else
   j = 0
   If Left(s, 5) = "color" Then
    j = Val(Mid(s, 6))
    If j = 0 Or j = 1 Then
     j = j + 1
    Else
     Debug.Assert False
     Exit Function
    End If
   ElseIf Left(s, 8) = "texcoord" Then
    j = Val(Mid(s, 9))
    If j >= 0 And j < 16 Then
     j = j + 16
    Else
     Debug.Assert False
     Exit Function
    End If
   Else
    Debug.Assert False
    Exit Function
   End If
   '///
   If j > 0 And j < &H100& Then
    If Not pReadComponent(s, j) Then Exit Function
    t2.nParamCount = t2.nParamCount + 1
    ReDim Preserve t2.tParams(1 To t2.nParamCount)
    With t2.tParams(t2.nParamCount)
     .nType = j
     .sValue = objNode.GetSubNodeValueAsString(i)
    End With
   End If
   '///
  End Select
 End If
Next i
'///
'TODO:combine with template
'TODO:check if already exists (?)
'///create mesh
Select Case t.nType
Case 1 'cube
 If Not pCreateCube(t, t2) Then Exit Function
Case Else
 Debug.Assert False
 Exit Function
End If
'///add
m = m_nCount + 1
If m > m_nMax Then
 m_nMax = m_nMax + 16&
 ReDim Preserve m_tData(1 To m_nMax)
End If
m_tData(m) = t
m_nCount = m
'///over
AddMeshFromNode = m
End Function
