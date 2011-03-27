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
 'bit0-4:
 '1,2=color0-1
 '&H10-&H1F=texcoord0-15
 '---
 'bit 6-7 = used count (0-3 --> 1-4)
 '---
 'bit8-15:xyzw (0=x 1=y 2=z 3=w)
 '///
 nValueType As Long
 '0=constant
 '&H10=rect_unwrap
 '&H11=rect
 '///
 fValue(3) As D3DXVECTOR4
End Type

Private Type typeMeshVertex_Temp
 nParent As Integer
 '>0=has parent (shared index) note: must < current index
 '=0=no parent
 '<0=this is the parent (shared index) node
 nFlags As Integer
 '&H1=bevel face vertex
 '&H4000=normal initialized
 '///
 fPos As D3DXVECTOR4
 fNormal(1) As D3DXVECTOR4 'must follow fPos ;)
 '0=average normal (if nParent=0) or result
 '1=per-face normal
 fTexcoord As D3DXVECTOR4 'w=index
End Type

Private Type typeMeshEdge_Temp
 nFlags As Long
 'bit 0-1=bevel index (0-x 1-y 2-z 3-w) for vertex 0-1
 'bit 2-3=bevel index for vertex 2-3
 nVertexIndex(3) As Long
 nVertexB As Long 'optional (whel nBevel=2)
 '|   F  |
 '3------2
 '(B+1) (B)
 '0------1
 '|   F  |
End Type

Private Type typeMeshFace_Temp
 nFlags As Long
 'bit 0-7=edge(0-3) bevel index (0-x 1-y 2-z 3-w)
 'edge N = vertex N to vertex N+1
 '///
 nCount As Long '3 or 4
 nVertex(3) As Long
 'note: order(??)=
 '0-1  -x
 ' /  |
 '2-3 y
End Type

Private Type typeMeshOptionalData
 nFlags As Long
 'bit 0-1=bevel (0-2)
 '///
 fNormalSmoothness As Single
 fBevelNormalSmoothness As Single
 '///
 nParamCount As Long
 tParams() As typeMeshParamData '1-based
 '///
 fPos(3) As D3DXVECTOR4
 fRotation As D3DXVECTOR4
 fScale As D3DXVECTOR4
 fCenter As D3DXVECTOR4
 '///
 fBevel As D3DXVECTOR4 '>0=relative <0=absolute
End Type

Private Type typeMeshMgrData
 nType As Long
 '0=unused
 '1=cube
 'TODO:...
 '///
 nVertexCount As Long
 nFaceCount As Long
 FVF As D3DFVFFLAGS 'only used D3DFVF_DIFFUSE, D3DFVF_SPECULAR and D3DFVF_TEX* (&H100& to &H1F00&)
 nVertexSize As Long
 '///
 objMesh As D3DXMesh
End Type

Private m_tData() As typeMeshMgrData
Private m_nCount As Long
Private m_nMax As Long

Friend Property Get Mesh(ByVal nIndex As Long) As D3DXMesh
If nIndex > 0 And nIndex <= m_nCount Then Set Mesh = m_tData(nIndex).objMesh
End Property

Friend Property Get Count() As Long
Count = m_nCount
End Property

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
Dim i As Long, j As Long, k As Long, m As Long
n = (n And &HFFFF003F) Or &HE400&
i = InStr(1, s, ".")
If i > 0 Then
 s = Mid(s, i + 1, 4)
 j = &H100&
 m = Len(s)
 For i = 1 To m
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
n = n Or (((m - 1) And 3&) * &H40&)
pReadComponent = True
End Function

'TODO:other options
Friend Function pReadComponentValue(ByVal s As String, ByRef t As typeMeshOptionalData, ByVal nIndex As Long, ByVal nDefaultType As Long) As Boolean
Dim i As Long
Dim s1 As String
Dim nType As Long
i = InStr(1, s, ":")
If i > 0 Then
 s1 = Mid(s, i + 1)
 s = Left(s, i - 1)
End If
'///
Select Case s
Case "unwrap"
 Select Case nDefaultType
 Case 1 'cube
  nType = &H10&
 Case Else
  Debug.Assert False
  Exit Function
 End Select
Case "rect_unwrap"
 nType = &H10&
Case "rect"
 nType = &H11&
Case Else 'constant (?)
 s1 = s
 i = 1
End Select
'///
t.tParams(nIndex).nValueType = nType
'///
If i > 0 Then
 pReadComponentValue = pReadVec4(s1, t.tParams(nIndex).fValue(0))
Else
 Select Case nType
 Case &H10&, &H11&
  t.tParams(nIndex).fValue(0) = t.fScale
 Case Else
  Debug.Assert False
  Exit Function
 End Select
 pReadComponentValue = True
End If
End Function

Friend Sub pCreateEmptyMesh(ByRef t As typeMeshMgrData, ByVal nVertexCount As Long, ByVal nFaceCount As Long)
Dim tt(63) As D3DVERTEXELEMENT9
Dim i As Long, m As Long
Dim nSize As Long
'///
tt(0) = D3DVertexElementCreate(, 0, D3DDECLTYPE_FLOAT3, , D3DDECLUSAGE_POSITION)
tt(1) = D3DVertexElementCreate(, 12&, D3DDECLTYPE_FLOAT3, , D3DDECLUSAGE_NORMAL)
If t.FVF And &H1F00& Then
 tt(2) = D3DVertexElementCreate(, 24&, D3DDECLTYPE_FLOAT3, , D3DDECLUSAGE_BINORMAL)
 tt(3) = D3DVertexElementCreate(, 36&, D3DDECLTYPE_FLOAT3, , D3DDECLUSAGE_TANGENT)
 m = 4
Else
 m = 2
End If
nSize = m * 12&
If t.FVF And D3DFVF_DIFFUSE Then
 tt(m) = D3DVertexElementCreate(, nSize, D3DDECLTYPE_FLOAT4, , D3DDECLUSAGE_COLOR)
 m = m + 1
 nSize = nSize + 16&
End If
If t.FVF And D3DFVF_SPECULAR Then
 tt(m) = D3DVertexElementCreate(, nSize, D3DDECLTYPE_FLOAT4, , D3DDECLUSAGE_COLOR, 1)
 m = m + 1
 nSize = nSize + 16&
End If
For i = 0 To (t.FVF And &H1F00&) \ &H100& - 1
 tt(m) = D3DVertexElementCreate(, nSize, D3DDECLTYPE_FLOAT4, , D3DDECLUSAGE_TEXCOORD, i)
 m = m + 1
 nSize = nSize + 16&
Next i
tt(m) = D3DDECL_END
'///
t.nVertexSize = nSize
'///
D3DXCreateMesh nFaceCount, nVertexCount, D3DXMESH_MANAGED, tt(0), d3dd9, t.objMesh
Debug.Assert Not t.objMesh Is Nothing
'Debug.Print nVertexCount, nFaceCount
'///
End Sub

'the coordinate system is annoying (LH)
Friend Sub pCreateCube(ByRef t As typeMeshMgrData, ByRef t2 As typeMeshOptionalData)
Dim p(3) As D3DXVECTOR4
'0=actual corner pos
'1-3=x,y,z vector
'4-6=(bevel x,y,z vector) (unused)
'7=tmp (unused)
Dim fLength(2) As Single
Dim mat As D3DMATRIX
Dim nVertexCount As Long, nFaceCount As Long, nFaceCount_1 As Long
Dim nBevel As Long
Dim tFace() As typeMeshFace_Temp
Dim tVertex() As typeMeshVertex_Temp
Dim i As Long, j As Long
'///init
ReDim tFace(1 To 128)
ReDim tVertex(1 To 512)
'///scale
t2.fPos(1).x = t2.fPos(1).x * t2.fScale.x
t2.fPos(1).y = t2.fPos(1).y * t2.fScale.x
t2.fPos(1).z = t2.fPos(1).z * t2.fScale.x
t2.fPos(2).x = t2.fPos(2).x * t2.fScale.y
t2.fPos(2).y = t2.fPos(2).y * t2.fScale.y
t2.fPos(2).z = t2.fPos(2).z * t2.fScale.y
t2.fPos(3).x = t2.fPos(3).x * t2.fScale.z
t2.fPos(3).y = t2.fPos(3).y * t2.fScale.z
t2.fPos(3).z = t2.fPos(3).z * t2.fScale.z
'///rotate
D3DXMatrixRotationYawPitchRoll mat, t2.fRotation.x, t2.fRotation.y, t2.fRotation.z
D3DXVec4TransformArray p(1), 16&, t2.fPos(1), 16&, mat, 3
'///calc center
p(0).x = t2.fPos(0).x - t2.fCenter.x * p(1).x - t2.fCenter.y * p(2).x - t2.fCenter.z * p(3).x
p(0).y = t2.fPos(0).y - t2.fCenter.x * p(1).y - t2.fCenter.y * p(2).y - t2.fCenter.z * p(3).y
p(0).z = t2.fPos(0).z - t2.fCenter.x * p(1).z - t2.fCenter.y * p(2).z - t2.fCenter.z * p(3).z
'///calc bevel
nBevel = t2.nFlags And 3&
If nBevel = 1 Or nBevel = 2 Then
 fLength(0) = Sqr(p(1).x * p(1).x + p(1).y * p(1).y + p(1).z * p(1).z)
 fLength(1) = Sqr(p(2).x * p(2).x + p(2).y * p(2).y + p(2).z * p(2).z)
 fLength(2) = Sqr(p(3).x * p(3).x + p(3).y * p(3).y + p(3).z * p(3).z)
 '///
 If t2.fBevel.x < 0 Then t2.fBevel.x = -t2.fBevel.x / fLength(0)
 If t2.fBevel.y < 0 Then t2.fBevel.y = -t2.fBevel.y / fLength(1)
 If t2.fBevel.z < 0 Then t2.fBevel.z = -t2.fBevel.z / fLength(2)
 '///
 If CLng(t2.fBevel.x < 0.000001!) + _
 CLng(t2.fBevel.y < 0.000001!) + _
 CLng(t2.fBevel.z < 0.000001!) <= -2 Then
  nBevel = 0
 End If
End If
'///calc count (?) TODO: when bevel component = 0
'// and create data
'nVertexCount = sum(FaceVertexCount)
'nFaceCount = sum(FaceVertexCount-2)
'--> nVertexCount = nFaceCount + nFaceCount_1 * 2
nVertexCount = 24
nFaceCount_1 = 6
'//========
'//bottom
pCreateFace tFace, 1, tVertex, 1, 2, 4, 3, p(0), p(2), p(1), Vec4(1), Vec4(, 1), Vec4(-1), , , , , , &H44&
'//top
pCreateFace tFace, 2, tVertex, 5, 8, 6, 7, D3DXVec4Add(p(0), p(3)), p(1), p(2), Vec4(1, 1, , 1), Vec4(-1), Vec4(, -1), , , , , , &H11&
'//front
pCreateFace tFace, 3, tVertex, 9, 10, 11, 12, p(0), p(0), p(0), Vec4(1, 1, , 2), Vec4(-1), Vec4(, -1), 1, 4, 5, 8, , &H22&
'//right
pCreateFace tFace, 4, tVertex, 13, 14, 15, 16, p(0), p(0), p(0), Vec4(1, 1, , 3), Vec4(-1), Vec4(, -1), 2, 1, 6, 5, , &H66&
'//back
pCreateFace tFace, 5, tVertex, 17, 18, 19, 20, p(0), p(0), p(0), Vec4(1, 1, , 4), Vec4(-1), Vec4(, -1), 3, 2, 7, 6, , &H22&
'//left
pCreateFace tFace, 6, tVertex, 21, 22, 23, 24, p(0), p(0), p(0), Vec4(1, 1, , 5), Vec4(-1), Vec4(, -1), 4, 3, 8, 7, , &H66&
'//========new
Select Case nBevel
Case 1, 2
 pPerformBevel tFace, nFaceCount_1, tVertex, nVertexCount, nBevel, t2.fBevel
End Select
nFaceCount = nVertexCount - nFaceCount_1 * 2&
'///calc normal
pCalcFaceNormal tFace, nFaceCount_1, tVertex
pCalcAverageNormal tVertex, nVertexCount
pApplyAverageNormal tVertex, nVertexCount, 0, 1, t2.fNormalSmoothness
pApplyAverageNormal tVertex, nVertexCount, 1, 1, t2.fBevelNormalSmoothness
'///create mesh
pCreateEmptyMesh t, nVertexCount, nFaceCount
'///apply data
pApplyMeshData t, t2, tFace, nFaceCount_1, nFaceCount, tVertex, nVertexCount
'TODO:custom main texcoord
If t.FVF And &H1F00& Then D3DXComputeTangentFrame t.objMesh, 0
'TODO:optimize mesh
End Sub

'assume nBevel=1 or 2, and all count >0
Friend Sub pPerformBevel(ByRef tFace() As typeMeshFace_Temp, ByRef nFaceCount As Long, ByRef tVertex() As typeMeshVertex_Temp, ByRef nVertexCount As Long, ByVal nBevel As Long, ByRef vBevel As D3DXVECTOR4)
'currently more than 3 edges meet together is unsupported
Const nVertexAdjacencyCount As Long = 3
'///
Dim fBevel(3) As Single
Dim nVertexToVertexIndex() As Long
Dim nVertexToEdgeIndex() As Long
Dim tEdge() As typeMeshEdge_Temp
Dim tVertexDelta() As D3DXVECTOR4
Dim nEdgeCount As Long
Dim nVertexCount_Old As Long
Dim nVertexMax As Long, nFaceMax As Long
'///
Dim i As Long, j As Long, n As Long
Dim k As Long, k1 As Long, k2 As Long
Dim k_0 As Long, k1_0 As Long, k2_0 As Long
Dim nFlags As Long
Dim p(15) As D3DXVECTOR4
'///
Debug.Assert nBevel = 1 Or nBevel = 2
'///
fBevel(0) = vBevel.x
fBevel(1) = vBevel.y
fBevel(2) = vBevel.z
fBevel(3) = vBevel.w
'///init
ReDim nVertexToVertexIndex(1 To nVertexCount, 0 To nVertexAdjacencyCount - 1)
ReDim nVertexToEdgeIndex(1 To nVertexCount, 0 To nVertexAdjacencyCount - 1)
ReDim tEdge(1 To nFaceCount * 4&)
ReDim tVertexDelta(1 To nVertexCount, 0 To 3)
'////////================================================================calc adjacency
For i = 1 To nFaceCount
 nFlags = tFace(i).nFlags And &HFF&
 '////////////////////////////////////////////////////////////////
 k1 = tFace(i).nVertex(0)
 k2 = tFace(i).nVertex(1)
 '////////COPY AND PASTE CODE BELOW
 k1_0 = tVertex(k1).nParent
 k2_0 = tVertex(k2).nParent
 If k1_0 <= 0 Then k1_0 = k1
 If k2_0 <= 0 Then k2_0 = k2
 'find and add
 For k = 0 To nVertexAdjacencyCount - 1
  n = nVertexToVertexIndex(k1_0, k)
  If n = k2_0 Or n = 0 Then Exit For
 Next k
 If k >= nVertexAdjacencyCount Or n = 0 Then
  n = nEdgeCount + 1
  nEdgeCount = n
  tEdge(n).nFlags = nFlags And 3&
  tEdge(n).nVertexIndex(0) = k1
  tEdge(n).nVertexIndex(1) = k2
 Else
  n = nVertexToEdgeIndex(k1_0, k)
  Debug.Assert n > 0
  n = n And &H7FFFFFFF
  tEdge(n).nFlags = tEdge(n).nFlags Or ((nFlags And 3&) * 4&)
  tEdge(n).nVertexIndex(2) = k1
  tEdge(n).nVertexIndex(3) = k2
  n = n Or &H80000000
 End If
 'save
 For k = 0 To nVertexAdjacencyCount - 1
  If nVertexToVertexIndex(k2_0, k) = 0 Then
   nVertexToVertexIndex(k2_0, k) = k1_0
   nVertexToEdgeIndex(k2_0, k) = n
   Exit For
  End If
 Next k
 If k >= nVertexAdjacencyCount Then
  Debug.Assert False
  Exit Sub
 End If
 nFlags = nFlags \ 4&
 '////////COPY AND PASTE CODE ABOVE
 Select Case tFace(i).nCount
 Case 4
 '////////////////////////////////////////////////////////////////
 k1 = tFace(i).nVertex(1)
 k2 = tFace(i).nVertex(3)
 '////////COPY AND PASTE CODE BELOW
 k1_0 = tVertex(k1).nParent
 k2_0 = tVertex(k2).nParent
 If k1_0 <= 0 Then k1_0 = k1
 If k2_0 <= 0 Then k2_0 = k2
 'find and add
 For k = 0 To nVertexAdjacencyCount - 1
  n = nVertexToVertexIndex(k1_0, k)
  If n = k2_0 Or n = 0 Then Exit For
 Next k
 If k >= nVertexAdjacencyCount Or n = 0 Then
  n = nEdgeCount + 1
  nEdgeCount = n
  tEdge(n).nFlags = nFlags And 3&
  tEdge(n).nVertexIndex(0) = k1
  tEdge(n).nVertexIndex(1) = k2
 Else
  n = nVertexToEdgeIndex(k1_0, k)
  Debug.Assert n > 0
  n = n And &H7FFFFFFF
  tEdge(n).nFlags = tEdge(n).nFlags Or ((nFlags And 3&) * 4&)
  tEdge(n).nVertexIndex(2) = k1
  tEdge(n).nVertexIndex(3) = k2
  n = n Or &H80000000
 End If
 'save
 For k = 0 To nVertexAdjacencyCount - 1
  If nVertexToVertexIndex(k2_0, k) = 0 Then
   nVertexToVertexIndex(k2_0, k) = k1_0
   nVertexToEdgeIndex(k2_0, k) = n
   Exit For
  End If
 Next k
 If k >= nVertexAdjacencyCount Then
  Debug.Assert False
  Exit Sub
 End If
 nFlags = nFlags \ 4&
 '////////COPY AND PASTE CODE ABOVE
 '////////////////////////////////////////////////////////////////
 k1 = tFace(i).nVertex(3)
 k2 = tFace(i).nVertex(2)
 '////////COPY AND PASTE CODE BELOW
 k1_0 = tVertex(k1).nParent
 k2_0 = tVertex(k2).nParent
 If k1_0 <= 0 Then k1_0 = k1
 If k2_0 <= 0 Then k2_0 = k2
 'find and add
 For k = 0 To nVertexAdjacencyCount - 1
  n = nVertexToVertexIndex(k1_0, k)
  If n = k2_0 Or n = 0 Then Exit For
 Next k
 If k >= nVertexAdjacencyCount Or n = 0 Then
  n = nEdgeCount + 1
  nEdgeCount = n
  tEdge(n).nFlags = nFlags And 3&
  tEdge(n).nVertexIndex(0) = k1
  tEdge(n).nVertexIndex(1) = k2
 Else
  n = nVertexToEdgeIndex(k1_0, k)
  Debug.Assert n > 0
  n = n And &H7FFFFFFF
  tEdge(n).nFlags = tEdge(n).nFlags Or ((nFlags And 3&) * 4&)
  tEdge(n).nVertexIndex(2) = k1
  tEdge(n).nVertexIndex(3) = k2
  n = n Or &H80000000
 End If
 'save
 For k = 0 To nVertexAdjacencyCount - 1
  If nVertexToVertexIndex(k2_0, k) = 0 Then
   nVertexToVertexIndex(k2_0, k) = k1_0
   nVertexToEdgeIndex(k2_0, k) = n
   Exit For
  End If
 Next k
 If k >= nVertexAdjacencyCount Then
  Debug.Assert False
  Exit Sub
 End If
 nFlags = nFlags \ 4&
 '////////COPY AND PASTE CODE ABOVE
 Case Else 'assume is 3
 '////////////////////////////////////////////////////////////////
 k1 = tFace(i).nVertex(1)
 k2 = tFace(i).nVertex(2)
 '////////COPY AND PASTE CODE BELOW
 k1_0 = tVertex(k1).nParent
 k2_0 = tVertex(k2).nParent
 If k1_0 <= 0 Then k1_0 = k1
 If k2_0 <= 0 Then k2_0 = k2
 'find and add
 For k = 0 To nVertexAdjacencyCount - 1
  n = nVertexToVertexIndex(k1_0, k)
  If n = k2_0 Or n = 0 Then Exit For
 Next k
 If k >= nVertexAdjacencyCount Or n = 0 Then
  n = nEdgeCount + 1
  nEdgeCount = n
  tEdge(n).nFlags = nFlags And 3&
  tEdge(n).nVertexIndex(0) = k1
  tEdge(n).nVertexIndex(1) = k2
 Else
  n = nVertexToEdgeIndex(k1_0, k)
  Debug.Assert n > 0
  n = n And &H7FFFFFFF
  tEdge(n).nFlags = tEdge(n).nFlags Or ((nFlags And 3&) * 4&)
  tEdge(n).nVertexIndex(2) = k1
  tEdge(n).nVertexIndex(3) = k2
  n = n Or &H80000000
 End If
 'save
 For k = 0 To nVertexAdjacencyCount - 1
  If nVertexToVertexIndex(k2_0, k) = 0 Then
   nVertexToVertexIndex(k2_0, k) = k1_0
   nVertexToEdgeIndex(k2_0, k) = n
   Exit For
  End If
 Next k
 If k >= nVertexAdjacencyCount Then
  Debug.Assert False
  Exit Sub
 End If
 nFlags = nFlags \ 4&
 '////////COPY AND PASTE CODE ABOVE
 End Select
 '////////////////////////////////////////////////////////////////
 k1 = tFace(i).nVertex(2)
 k2 = tFace(i).nVertex(0)
 '////////COPY AND PASTE CODE BELOW
 k1_0 = tVertex(k1).nParent
 k2_0 = tVertex(k2).nParent
 If k1_0 <= 0 Then k1_0 = k1
 If k2_0 <= 0 Then k2_0 = k2
 'find and add
 For k = 0 To nVertexAdjacencyCount - 1
  n = nVertexToVertexIndex(k1_0, k)
  If n = k2_0 Or n = 0 Then Exit For
 Next k
 If k >= nVertexAdjacencyCount Or n = 0 Then
  n = nEdgeCount + 1
  nEdgeCount = n
  tEdge(n).nFlags = nFlags And 3&
  tEdge(n).nVertexIndex(0) = k1
  tEdge(n).nVertexIndex(1) = k2
 Else
  n = nVertexToEdgeIndex(k1_0, k)
  Debug.Assert n > 0
  n = n And &H7FFFFFFF
  tEdge(n).nFlags = tEdge(n).nFlags Or ((nFlags And 3&) * 4&)
  tEdge(n).nVertexIndex(2) = k1
  tEdge(n).nVertexIndex(3) = k2
  n = n Or &H80000000
 End If
 'save
 For k = 0 To nVertexAdjacencyCount - 1
  If nVertexToVertexIndex(k2_0, k) = 0 Then
   nVertexToVertexIndex(k2_0, k) = k1_0
   nVertexToEdgeIndex(k2_0, k) = n
   Exit For
  End If
 Next k
 If k >= nVertexAdjacencyCount Then
  Debug.Assert False
  Exit Sub
 End If
 nFlags = nFlags \ 4&
 '////////COPY AND PASTE CODE ABOVE
 '////////////////////////////////////////////////////////////////over
Next i
'////////================================================================split face
For i = 1 To nFaceCount
 nFlags = tFace(i).nFlags And &HFF&
 n = tFace(i).nCount
 Debug.Assert n = 3 Or n = 4
 '///
 If n = 4 Then k1_0 = (nFlags \ &H40&) And 3& _
 Else k1_0 = (nFlags \ &H10&) And 3&
 k2_0 = nFlags And 3&
 k = tFace(i).nVertex(0)
 k1 = tFace(i).nVertex(2)
 k2 = tFace(i).nVertex(1)
 '////////COPY AND PASTE CODE BELOW
 p(0) = tVertex(k).fPos
 p(1).x = (tVertex(k1).fPos.x - p(0).x) * fBevel(k2_0)
 p(1).y = (tVertex(k1).fPos.y - p(0).y) * fBevel(k2_0)
 p(1).z = (tVertex(k1).fPos.z - p(0).z) * fBevel(k2_0)
 p(2).x = (tVertex(k2).fPos.x - p(0).x) * fBevel(k1_0)
 p(2).y = (tVertex(k2).fPos.y - p(0).y) * fBevel(k1_0)
 p(2).z = (tVertex(k2).fPos.z - p(0).z) * fBevel(k1_0)
 p(4) = D3DXVec4Add3(p(0), p(1), p(2))
 tVertexDelta(k, 0) = p(1)
 tVertexDelta(k, 1) = p(2)
 p(0) = tVertex(k).fTexcoord
 p(1).x = (tVertex(k1).fTexcoord.x - p(0).x) * fBevel(k2_0)
 p(1).y = (tVertex(k1).fTexcoord.y - p(0).y) * fBevel(k2_0)
 p(1).z = (tVertex(k1).fTexcoord.z - p(0).z) * fBevel(k2_0)
 p(2).x = (tVertex(k2).fTexcoord.x - p(0).x) * fBevel(k1_0)
 p(2).y = (tVertex(k2).fTexcoord.y - p(0).y) * fBevel(k1_0)
 p(2).z = (tVertex(k2).fTexcoord.z - p(0).z) * fBevel(k1_0)
 p(8) = D3DXVec4Add3(p(0), p(1), p(2))
 tVertexDelta(k, 2) = p(1)
 tVertexDelta(k, 3) = p(2)
 '////////COPY AND PASTE CODE ABOVE
 Select Case n
 Case 4
  k1 = k
  k = k2
  k2 = tFace(i).nVertex(3)
  k1_0 = k2_0
  k2_0 = (nFlags \ 4&) And 3&
  '////////COPY AND PASTE CODE BELOW
  p(0) = tVertex(k).fPos
  p(1).x = (tVertex(k1).fPos.x - p(0).x) * fBevel(k2_0)
  p(1).y = (tVertex(k1).fPos.y - p(0).y) * fBevel(k2_0)
  p(1).z = (tVertex(k1).fPos.z - p(0).z) * fBevel(k2_0)
  p(2).x = (tVertex(k2).fPos.x - p(0).x) * fBevel(k1_0)
  p(2).y = (tVertex(k2).fPos.y - p(0).y) * fBevel(k1_0)
  p(2).z = (tVertex(k2).fPos.z - p(0).z) * fBevel(k1_0)
  p(5) = D3DXVec4Add3(p(0), p(1), p(2))
  tVertexDelta(k, 0) = p(1)
  tVertexDelta(k, 1) = p(2)
  p(0) = tVertex(k).fTexcoord
  p(1).x = (tVertex(k1).fTexcoord.x - p(0).x) * fBevel(k2_0)
  p(1).y = (tVertex(k1).fTexcoord.y - p(0).y) * fBevel(k2_0)
  p(1).z = (tVertex(k1).fTexcoord.z - p(0).z) * fBevel(k2_0)
  p(2).x = (tVertex(k2).fTexcoord.x - p(0).x) * fBevel(k1_0)
  p(2).y = (tVertex(k2).fTexcoord.y - p(0).y) * fBevel(k1_0)
  p(2).z = (tVertex(k2).fTexcoord.z - p(0).z) * fBevel(k1_0)
  p(9) = D3DXVec4Add3(p(0), p(1), p(2))
  tVertexDelta(k, 2) = p(1)
  tVertexDelta(k, 3) = p(2)
  '////////COPY AND PASTE CODE ABOVE
  k1 = k
  k = k2
  k2 = tFace(i).nVertex(2)
  k1_0 = k2_0
  k2_0 = (nFlags \ &H10&) And 3&
  '////////COPY AND PASTE CODE BELOW
  p(0) = tVertex(k).fPos
  p(1).x = (tVertex(k1).fPos.x - p(0).x) * fBevel(k2_0)
  p(1).y = (tVertex(k1).fPos.y - p(0).y) * fBevel(k2_0)
  p(1).z = (tVertex(k1).fPos.z - p(0).z) * fBevel(k2_0)
  p(2).x = (tVertex(k2).fPos.x - p(0).x) * fBevel(k1_0)
  p(2).y = (tVertex(k2).fPos.y - p(0).y) * fBevel(k1_0)
  p(2).z = (tVertex(k2).fPos.z - p(0).z) * fBevel(k1_0)
  p(7) = D3DXVec4Add3(p(0), p(1), p(2))
  tVertexDelta(k, 0) = p(1)
  tVertexDelta(k, 1) = p(2)
  p(0) = tVertex(k).fTexcoord
  p(1).x = (tVertex(k1).fTexcoord.x - p(0).x) * fBevel(k2_0)
  p(1).y = (tVertex(k1).fTexcoord.y - p(0).y) * fBevel(k2_0)
  p(1).z = (tVertex(k1).fTexcoord.z - p(0).z) * fBevel(k2_0)
  p(2).x = (tVertex(k2).fTexcoord.x - p(0).x) * fBevel(k1_0)
  p(2).y = (tVertex(k2).fTexcoord.y - p(0).y) * fBevel(k1_0)
  p(2).z = (tVertex(k2).fTexcoord.z - p(0).z) * fBevel(k1_0)
  p(11) = D3DXVec4Add3(p(0), p(1), p(2))
  tVertexDelta(k, 2) = p(1)
  tVertexDelta(k, 3) = p(2)
  '////////COPY AND PASTE CODE ABOVE
  k1 = k
  k = k2
  k2 = tFace(i).nVertex(0)
  k1_0 = k2_0
  k2_0 = (nFlags \ &H40&) And 3&
  '////////COPY AND PASTE CODE BELOW
  p(0) = tVertex(k).fPos
  p(1).x = (tVertex(k1).fPos.x - p(0).x) * fBevel(k2_0)
  p(1).y = (tVertex(k1).fPos.y - p(0).y) * fBevel(k2_0)
  p(1).z = (tVertex(k1).fPos.z - p(0).z) * fBevel(k2_0)
  p(2).x = (tVertex(k2).fPos.x - p(0).x) * fBevel(k1_0)
  p(2).y = (tVertex(k2).fPos.y - p(0).y) * fBevel(k1_0)
  p(2).z = (tVertex(k2).fPos.z - p(0).z) * fBevel(k1_0)
  p(6) = D3DXVec4Add3(p(0), p(1), p(2))
  tVertexDelta(k, 0) = p(1)
  tVertexDelta(k, 1) = p(2)
  p(0) = tVertex(k).fTexcoord
  p(1).x = (tVertex(k1).fTexcoord.x - p(0).x) * fBevel(k2_0)
  p(1).y = (tVertex(k1).fTexcoord.y - p(0).y) * fBevel(k2_0)
  p(1).z = (tVertex(k1).fTexcoord.z - p(0).z) * fBevel(k2_0)
  p(2).x = (tVertex(k2).fTexcoord.x - p(0).x) * fBevel(k1_0)
  p(2).y = (tVertex(k2).fTexcoord.y - p(0).y) * fBevel(k1_0)
  p(2).z = (tVertex(k2).fTexcoord.z - p(0).z) * fBevel(k1_0)
  p(10) = D3DXVec4Add3(p(0), p(1), p(2))
  tVertexDelta(k, 2) = p(1)
  tVertexDelta(k, 3) = p(2)
  '////////COPY AND PASTE CODE ABOVE
 Case Else 'assume is 3
  nFlags = (nFlags \ 4&) And 3&
  '---
  p(0) = tVertex(k2).fPos
  p(1).x = (tVertex(k).fPos.x - p(0).x) * fBevel(nFlags)
  p(1).y = (tVertex(k).fPos.y - p(0).y) * fBevel(nFlags)
  p(1).z = (tVertex(k).fPos.z - p(0).z) * fBevel(nFlags)
  p(2).x = (tVertex(k1).fPos.x - p(0).x) * fBevel(k2_0)
  p(2).y = (tVertex(k1).fPos.y - p(0).y) * fBevel(k2_0)
  p(2).z = (tVertex(k1).fPos.z - p(0).z) * fBevel(k2_0)
  p(5) = D3DXVec4Add3(p(0), p(1), p(2))
  tVertexDelta(k2, 0) = p(1)
  tVertexDelta(k2, 1) = p(2)
  p(0) = tVertex(k2).fTexcoord
  p(1).x = (tVertex(k).fTexcoord.x - p(0).x) * fBevel(nFlags)
  p(1).y = (tVertex(k).fTexcoord.y - p(0).y) * fBevel(nFlags)
  p(1).z = (tVertex(k).fTexcoord.z - p(0).z) * fBevel(nFlags)
  p(2).x = (tVertex(k1).fTexcoord.x - p(0).x) * fBevel(k2_0)
  p(2).y = (tVertex(k1).fTexcoord.y - p(0).y) * fBevel(k2_0)
  p(2).z = (tVertex(k1).fTexcoord.z - p(0).z) * fBevel(k2_0)
  p(9) = D3DXVec4Add3(p(0), p(1), p(2))
  tVertexDelta(k2, 2) = p(1)
  tVertexDelta(k2, 3) = p(2)
  '---
  p(0) = tVertex(k1).fPos
  p(1).x = (tVertex(k2).fPos.x - p(0).x) * fBevel(k1_0)
  p(1).y = (tVertex(k2).fPos.y - p(0).y) * fBevel(k1_0)
  p(1).z = (tVertex(k2).fPos.z - p(0).z) * fBevel(k1_0)
  p(2).x = (tVertex(k).fPos.x - p(0).x) * fBevel(nFlags)
  p(2).y = (tVertex(k).fPos.y - p(0).y) * fBevel(nFlags)
  p(2).z = (tVertex(k).fPos.z - p(0).z) * fBevel(nFlags)
  p(6) = D3DXVec4Add3(p(0), p(1), p(2))
  tVertexDelta(k1, 0) = p(1)
  tVertexDelta(k1, 1) = p(2)
  p(0) = tVertex(k1).fTexcoord
  p(1).x = (tVertex(k2).fTexcoord.x - p(0).x) * fBevel(k1_0)
  p(1).y = (tVertex(k2).fTexcoord.y - p(0).y) * fBevel(k1_0)
  p(1).z = (tVertex(k2).fTexcoord.z - p(0).z) * fBevel(k1_0)
  p(2).x = (tVertex(k).fTexcoord.x - p(0).x) * fBevel(nFlags)
  p(2).y = (tVertex(k).fTexcoord.y - p(0).y) * fBevel(nFlags)
  p(2).z = (tVertex(k).fTexcoord.z - p(0).z) * fBevel(nFlags)
  p(10) = D3DXVec4Add3(p(0), p(1), p(2))
  tVertexDelta(k1, 2) = p(1)
  tVertexDelta(k1, 3) = p(2)
 End Select
 '///
 For j = 0 To n - 1
  k = tFace(i).nVertex(j)
  tVertex(k).nParent = 0
  tVertex(k).fPos = p(j + 4)
  tVertex(k).fTexcoord = p(j + 8)
 Next j
Next i
'///
nVertexCount_Old = nVertexCount
nVertexMax = UBound(tVertex)
nFaceMax = UBound(tFace)
'////////================================================================split edge
Select Case nBevel
Case 2
 For i = 1 To nEdgeCount
  If tEdge(i).nVertexIndex(3) Then
   j = nVertexCount + 8
   n = nFaceCount + 2
   If j > nVertexMax Then
    nVertexMax = j + 4096&
    ReDim Preserve tVertex(1 To nVertexMax)
   End If
   If n > nFaceMax Then
    nFaceMax = n + 4096&
    ReDim Preserve tFace(1 To nFaceMax)
   End If
   '///
   tEdge(i).nVertexB = j - 5
   '///
   k1 = tEdge(i).nVertexIndex(0)
   k2 = tEdge(i).nVertexIndex(3)
   p(0) = D3DXVec4Add3(tVertex(k1).fPos, D3DXVec4Scale(tVertexDelta(k1, 0), -0.7071068!), D3DXVec4Scale(tVertexDelta(k2, 1), 0.2928932!))
   p(2) = D3DXVec4Subtract(tVertex(k1).fTexcoord, tVertexDelta(k1, 2))
   p(4) = D3DXVec4Subtract(tVertex(k2).fTexcoord, tVertexDelta(k2, 3))
   '///
   k1 = tEdge(i).nVertexIndex(2)
   k2 = tEdge(i).nVertexIndex(1)
   p(1) = D3DXVec4Add3(tVertex(k1).fPos, D3DXVec4Scale(tVertexDelta(k1, 0), -0.7071068!), D3DXVec4Scale(tVertexDelta(k2, 1), 0.2928932!))
   p(3) = D3DXVec4Subtract(tVertex(k2).fTexcoord, tVertexDelta(k2, 3))
   p(5) = D3DXVec4Subtract(tVertex(k1).fTexcoord, tVertexDelta(k1, 2))
   '///
   pCreateFace tFace, n - 1, tVertex, j - 4, j - 5, j - 6, j - 7, _
   p(0), D3DXVec4Subtract(p(1), p(0)), p(0), _
   p(2), D3DXVec4Subtract(p(3), p(2)), p(0), _
   , , tEdge(i).nVertexIndex(0), tEdge(i).nVertexIndex(1), _
   1, , -1
   pCreateFace tFace, n, tVertex, j, j - 1, j - 2, j - 3, _
   p(0), p(0), p(0), _
   p(5), D3DXVec4Subtract(p(4), p(5)), p(0), _
   j - 5, j - 4, tEdge(i).nVertexIndex(2), tEdge(i).nVertexIndex(3), _
   1, , 12
   '///
   nVertexCount = j
   nFaceCount = n
  End If
 Next i
Case Else
 For i = 1 To nEdgeCount
  If tEdge(i).nVertexIndex(3) Then
   j = nVertexCount + 4
   n = nFaceCount + 1
   If j > nVertexMax Then
    nVertexMax = j + 4096&
    ReDim Preserve tVertex(1 To nVertexMax)
   End If
   If n > nFaceMax Then
    nFaceMax = n + 4096&
    ReDim Preserve tFace(1 To nFaceMax)
   End If
   pCreateFace tFace, n, tVertex, j - 3, j - 2, j - 1, j, p(0), p(0), p(0), p(0), p(0), p(0), _
   tEdge(i).nVertexIndex(1), tEdge(i).nVertexIndex(0), tEdge(i).nVertexIndex(2), tEdge(i).nVertexIndex(3), _
   1, , -1
   nVertexCount = j
   nFaceCount = n
  End If
 Next i
End Select
'////////================================================================split vertex
For i = 1 To nVertexCount_Old
 'FIXME:ugly code, only works when exactly 3 edges meet together
 k_0 = nVertexToEdgeIndex(i, 0)
 k1_0 = nVertexToEdgeIndex(i, 1)
 k2_0 = nVertexToEdgeIndex(i, 2)
 If k_0 <> 0 And k1_0 <> 0 And k2_0 <> 0 Then
  If k_0 < 0 Then
   k_0 = k_0 And &H7FFFFFFF
   k1 = tEdge(k_0).nVertexIndex(3)
   k2 = tEdge(k_0).nVertexIndex(0)
   k_0 = tEdge(k_0).nVertexB + 1
  Else
   k1 = tEdge(k_0).nVertexIndex(1)
   k2 = tEdge(k_0).nVertexIndex(2)
   k_0 = tEdge(k_0).nVertexB
  End If
  If k1_0 < 0 Then
   k1_0 = k1_0 And &H7FFFFFFF
   If k1 = tEdge(k1_0).nVertexIndex(0) Then
    k = tEdge(k1_0).nVertexIndex(3)
    j = tEdge(k1_0).nVertexB + 1
    n = tEdge(k2_0 And &H7FFFFFFF).nVertexB + ((k2_0 < 0) And 1&)
   ElseIf k2 = tEdge(k1_0).nVertexIndex(3) Then
    k = tEdge(k1_0).nVertexIndex(0)
    n = tEdge(k1_0).nVertexB + 1
    j = tEdge(k2_0 And &H7FFFFFFF).nVertexB + ((k2_0 < 0) And 1&)
   Else
    Debug.Assert False
    Exit For
   End If
  Else
   If k1 = tEdge(k1_0).nVertexIndex(2) Then
    k = tEdge(k1_0).nVertexIndex(1)
    j = tEdge(k1_0).nVertexB
    n = tEdge(k2_0 And &H7FFFFFFF).nVertexB + ((k2_0 < 0) And 1&)
   ElseIf k2 = tEdge(k1_0).nVertexIndex(1) Then
    k = tEdge(k1_0).nVertexIndex(2)
    n = tEdge(k1_0).nVertexB
    j = tEdge(k2_0 And &H7FFFFFFF).nVertexB + ((k2_0 < 0) And 1&)
   Else
    Debug.Assert False
    Exit For
   End If
  End If
  k1_0 = n
  k2_0 = j
  '///
  Debug.Assert k > 0 And k1 > 0 And k2 > 0
  '///
  'k
  '|
  'k2-k1
  '///
  Select Case nBevel
  Case 2
   j = nVertexCount + 18
   n = nFaceCount + 6
   If j > nVertexMax Then
    nVertexMax = j + 4096&
    ReDim Preserve tVertex(1 To nVertexMax)
   End If
   If n > nFaceMax Then
    nFaceMax = n + 4096&
    ReDim Preserve tFace(1 To nFaceMax)
   End If
   '///
   p(0) = D3DXVec4Add3(tVertex(k).fPos, D3DXVec4Scale(tVertexDelta(k1, 0), 0.4226497!), _
   D3DXVec4Scale(D3DXVec4Add(tVertexDelta(k, 0), tVertexDelta(k, 1)), -0.5773503!))
   p(1) = D3DXVec4Subtract3(tVertex(k).fTexcoord, tVertexDelta(k, 2), tVertexDelta(k, 3))
   p(2) = D3DXVec4Subtract3(tVertex(k1).fTexcoord, tVertexDelta(k1, 2), tVertexDelta(k1, 3))
   p(3) = D3DXVec4Subtract3(tVertex(k2).fTexcoord, tVertexDelta(k2, 2), tVertexDelta(k2, 3))
'   '///wrong code because violates the assumption: parent index must < current index
'   pCreateFace tFace, n - 5, tVertex, j, j - 17, j - 16, 0, p(0), p(0), p(0), p(1), tVertexDelta(k, 3), p(0), , k1_0, k, , 1, , 4
'   pCreateFace tFace, n - 4, tVertex, j - 15, j - 14, j - 13, 0, p(0), p(0), p(0), p(1), p(0), tVertexDelta(k, 2), j, k, k2_0, , 1, , 2
'   pCreateFace tFace, n - 3, tVertex, j - 12, j - 11, j - 10, 0, p(0), p(0), p(0), p(2), tVertexDelta(k1, 3), p(0), j, k2_0, k1, , 1, , 4
'   pCreateFace tFace, n - 2, tVertex, j - 9, j - 8, j - 7, 0, p(0), p(0), p(0), p(2), p(0), tVertexDelta(k1, 2), j, k1, k_0, , 1, , 2
'   pCreateFace tFace, n - 1, tVertex, j - 6, j - 5, j - 4, 0, p(0), p(0), p(0), p(3), tVertexDelta(k2, 3), p(0), j, k_0, k2, , 1, , 4
'   pCreateFace tFace, n, tVertex, j - 3, j - 2, j - 1, 0, p(0), p(0), p(0), p(3), p(0), tVertexDelta(k2, 2), j, k2, k1_0, , 1, , 2
   '///
   pCreateFace tFace, n - 5, tVertex, j - 17, j - 16, j - 15, 0, p(0), p(0), p(0), p(1), tVertexDelta(k, 3), p(0), , k1_0, k, , 1, , 4
   pCreateFace tFace, n - 4, tVertex, j - 14, j - 13, j - 12, 0, p(0), p(0), p(0), p(1), p(0), tVertexDelta(k, 2), j - 17, k, k2_0, , 1, , 2
   pCreateFace tFace, n - 3, tVertex, j - 11, j - 10, j - 9, 0, p(0), p(0), p(0), p(2), tVertexDelta(k1, 3), p(0), j - 17, k2_0, k1, , 1, , 4
   pCreateFace tFace, n - 2, tVertex, j - 8, j - 7, j - 6, 0, p(0), p(0), p(0), p(2), p(0), tVertexDelta(k1, 2), j - 17, k1, k_0, , 1, , 2
   pCreateFace tFace, n - 1, tVertex, j - 5, j - 4, j - 3, 0, p(0), p(0), p(0), p(3), tVertexDelta(k2, 3), p(0), j - 17, k_0, k2, , 1, , 4
   pCreateFace tFace, n, tVertex, j - 2, j - 1, j, 0, p(0), p(0), p(0), p(3), p(0), tVertexDelta(k2, 2), j - 17, k2, k1_0, , 1, , 2
   '///
   nVertexCount = j
   nFaceCount = n
  Case Else
   j = nVertexCount + 3
   n = nFaceCount + 1
   If j > nVertexMax Then
    nVertexMax = j + 4096&
    ReDim Preserve tVertex(1 To nVertexMax)
   End If
   If n > nFaceMax Then
    nFaceMax = n + 4096&
    ReDim Preserve tFace(1 To nFaceMax)
   End If
   pCreateFace tFace, n, tVertex, j - 2, j - 1, j, 0, p(0), p(0), p(0), p(0), p(0), p(0), _
   k, k1, k2, , _
   1, , -1
   nVertexCount = j
   nFaceCount = n
  End Select
  '///
 End If
Next i
End Sub

'note: will screw up data in tVertex
Friend Sub pApplyMeshData(ByRef t As typeMeshMgrData, ByRef t2 As typeMeshOptionalData, ByRef tFace() As typeMeshFace_Temp, ByVal nFaceCount As Long, ByVal m As Long, ByRef tVertex() As typeMeshVertex_Temp, ByVal nVertexCount As Long)
Dim lp As Long
Dim i As Long, j As Long, k As Long, kk As Long
Dim nOffset As Long, nOffset_0 As Long
Dim tParam As typeMeshParamData
Dim nIndex() As Integer
'///
nOffset_0 = 24& + (((t.FVF And &H1F00&) <> 0) And 24&)
'////////////////copy vertex buffer
t.objMesh.LockVertexBuffer 0, lp
'///position and normal
For i = 1 To nVertexCount
 '---screw up some data
 tVertex(i).fPos.w = tVertex(i).fNormal(0).x
 tVertex(i).fNormal(0).x = tVertex(i).fNormal(0).y
 tVertex(i).fNormal(0).y = tVertex(i).fNormal(0).z
 '---
 CopyMemory ByVal lp + (i - 1) * t.nVertexSize, tVertex(i).fPos, 24&
Next i
'///
For j = 1 To t2.nParamCount
 tParam = t2.tParams(j)
 Select Case tParam.nType And &H1F&
 Case 1
  nOffset = nOffset_0
 Case 2
  nOffset = nOffset_0 + ((t.FVF And D3DFVF_DIFFUSE) <> 0 And 16&)
 Case &H10& To &H1F&
  nOffset = nOffset_0 + ((t.FVF And D3DFVF_DIFFUSE) <> 0 And 16&) _
  + ((t.FVF And D3DFVF_SPECULAR) <> 0 And 16&) _
  + (tParam.nType And &HF&) * 16&
 Case Else
  Debug.Assert False
  Exit For
 End Select
 '///
 Select Case tParam.nValueType
 Case 0
  tParam.fValue(3) = tParam.fValue(0)
 Case &H10&
  'v direction
  tParam.fValue(0).w = tParam.fValue(0).y * 2 + tParam.fValue(0).z
  tParam.fValue(1).y = tParam.fValue(0).y / tParam.fValue(0).w
  tParam.fValue(1).z = tParam.fValue(0).z / tParam.fValue(0).w
  'u direction
  tParam.fValue(0).w = (tParam.fValue(0).x + tParam.fValue(0).y) * 2
  tParam.fValue(0).x = tParam.fValue(0).x / tParam.fValue(0).w
  tParam.fValue(0).y = tParam.fValue(0).y / tParam.fValue(0).w
 End Select
 '///
 For i = 1 To nVertexCount
  Select Case tParam.nValueType
  Case &H10&
   Select Case CLng(tVertex(i).fTexcoord.w)
   Case 0 'bottom
    tParam.fValue(3).x = tParam.fValue(0).x * tVertex(i).fTexcoord.x
    tParam.fValue(3).y = 1! - tParam.fValue(1).y * (1! - tVertex(i).fTexcoord.y)
   Case 1 'top
    tParam.fValue(3).x = tParam.fValue(0).x * tVertex(i).fTexcoord.x
    tParam.fValue(3).y = tParam.fValue(1).y * tVertex(i).fTexcoord.y
   Case 2 'front
    tParam.fValue(3).x = tParam.fValue(0).x * tVertex(i).fTexcoord.x
    tParam.fValue(3).y = tParam.fValue(1).y + tParam.fValue(1).z * tVertex(i).fTexcoord.y
   Case 3 'right
    tParam.fValue(3).x = tParam.fValue(0).x + tParam.fValue(0).y * tVertex(i).fTexcoord.x
    tParam.fValue(3).y = tParam.fValue(1).y + tParam.fValue(1).z * tVertex(i).fTexcoord.y
   Case 4 'back
    tParam.fValue(3).x = 0.5! + tParam.fValue(0).x * tVertex(i).fTexcoord.x
    tParam.fValue(3).y = tParam.fValue(1).y + tParam.fValue(1).z * tVertex(i).fTexcoord.y
   Case 5 'left
    tParam.fValue(3).x = 1! - tParam.fValue(0).y * (1! - tVertex(i).fTexcoord.x)
    tParam.fValue(3).y = tParam.fValue(1).y + tParam.fValue(1).z * tVertex(i).fTexcoord.y
   End Select
  Case &H11&
   Select Case CLng(tVertex(i).fTexcoord.w)
   Case 0, 1
    tParam.fValue(3).x = tParam.fValue(0).x * tVertex(i).fTexcoord.x
    tParam.fValue(3).y = tParam.fValue(0).y * tVertex(i).fTexcoord.y
   Case 2, 4
    tParam.fValue(3).x = tParam.fValue(0).x * tVertex(i).fTexcoord.x
    tParam.fValue(3).y = tParam.fValue(0).z * tVertex(i).fTexcoord.y
   Case 3, 5
    tParam.fValue(3).x = tParam.fValue(0).y * tVertex(i).fTexcoord.x
    tParam.fValue(3).y = tParam.fValue(0).z * tVertex(i).fTexcoord.y
   End Select
  End Select
  '///
  kk = &H100&
  For k = 0 To (tParam.nType And &HC0&) \ &H40&
   CopyMemory ByVal lp + (i - 1) * t.nVertexSize + nOffset + ((tParam.nType \ kk) And 3&) * 4&, _
   ByVal VarPtr(tParam.fValue(3)) + k * 4&, 4&
   kk = kk * 4&
  Next k
 Next i
Next j
'///
t.objMesh.UnlockVertexBuffer
'////////////////copy index buffer
ReDim nIndex(m * 3& - 1)
j = 0
For i = 1 To nFaceCount
 Select Case tFace(i).nCount
 Case 3
  nIndex(j) = tFace(i).nVertex(0) - 1
  nIndex(j + 1) = tFace(i).nVertex(1) - 1
  nIndex(j + 2) = tFace(i).nVertex(2) - 1
  j = j + 3
 Case 4
  nIndex(j) = tFace(i).nVertex(0) - 1
  nIndex(j + 1) = tFace(i).nVertex(1) - 1
  nIndex(j + 2) = tFace(i).nVertex(2) - 1
  nIndex(j + 3) = tFace(i).nVertex(3) - 1
  nIndex(j + 4) = tFace(i).nVertex(2) - 1
  nIndex(j + 5) = tFace(i).nVertex(1) - 1
  j = j + 6
 Case Else
  Debug.Assert False
  Exit For
 End Select
Next i
Debug.Assert j = m * 3&
'///
t.objMesh.LockIndexBuffer 0, lp
CopyMemory ByVal lp, nIndex(0), m * 6&
t.objMesh.UnlockIndexBuffer
'////////////////over
End Sub

Friend Sub pCalcFaceNormal(ByRef tFace() As typeMeshFace_Temp, ByVal nFaceCount As Long, ByRef tVertex() As typeMeshVertex_Temp)
Dim i As Long, j As Long, k As Long
Dim p As D3DXVECTOR4, p1 As D3DXVECTOR4, p2 As D3DXVECTOR4
For i = 1 To nFaceCount
 j = tFace(i).nVertex(0)
 k = tFace(i).nVertex(1)
 p1.x = tVertex(k).fPos.x - tVertex(j).fPos.x
 p1.y = tVertex(k).fPos.y - tVertex(j).fPos.y
 p1.z = tVertex(k).fPos.z - tVertex(j).fPos.z
 k = tFace(i).nVertex(2)
 p2.x = tVertex(k).fPos.x - tVertex(j).fPos.x
 p2.y = tVertex(k).fPos.y - tVertex(j).fPos.y
 p2.z = tVertex(k).fPos.z - tVertex(j).fPos.z
 '///cross product
 p.x = p1.y * p2.z - p2.y * p1.z
 p.y = p1.z * p2.x - p2.z * p1.x
 p.z = p1.x * p2.y - p2.x * p1.y
 '///normalize
 p1.w = Sqr(p.x * p.x + p.y * p.y + p.z * p.z)
 If p1.w > 0.000001! Then
  p.x = p.x / p1.w
  p.y = p.y / p1.w
  p.z = p.z / p1.w
 End If
 '///save
 For j = 0 To tFace(i).nCount - 1
  tVertex(tFace(i).nVertex(j)).fNormal(1) = p
 Next j
Next i
End Sub

Friend Sub pCalcAverageNormal(ByRef tVertex() As typeMeshVertex_Temp, ByVal nVertexCount As Long)
Dim i As Long, j As Long
Dim f As Single
For i = nVertexCount To 1 Step -1
 j = tVertex(i).nParent
 If j > 0 Then
  Debug.Assert j < i
  tVertex(j).fNormal(0).x = tVertex(j).fNormal(0).x + tVertex(i).fNormal(1).x
  tVertex(j).fNormal(0).y = tVertex(j).fNormal(0).y + tVertex(i).fNormal(1).y
  tVertex(j).fNormal(0).z = tVertex(j).fNormal(0).z + tVertex(i).fNormal(1).z
 ElseIf j < 0 Then
  tVertex(i).fNormal(0).x = tVertex(i).fNormal(0).x + tVertex(i).fNormal(1).x
  tVertex(i).fNormal(0).y = tVertex(i).fNormal(0).y + tVertex(i).fNormal(1).y
  tVertex(i).fNormal(0).z = tVertex(i).fNormal(0).z + tVertex(i).fNormal(1).z
  f = Sqr(tVertex(i).fNormal(0).x * tVertex(i).fNormal(0).x + _
  tVertex(i).fNormal(0).y * tVertex(i).fNormal(0).y + _
  tVertex(i).fNormal(0).z * tVertex(i).fNormal(0).z)
  If f > 0.000001! Then
   tVertex(i).fNormal(0).x = tVertex(i).fNormal(0).x / f
   tVertex(i).fNormal(0).y = tVertex(i).fNormal(0).y / f
   tVertex(i).fNormal(0).z = tVertex(i).fNormal(0).z / f
  End If
 End If
Next i
End Sub

Friend Sub pApplyAverageNormal(ByRef tVertex() As typeMeshVertex_Temp, ByVal nVertexCount As Long, ByVal nIndex As Long, ByVal nIndexMask As Long, ByVal fNormalSmoothness As Single)
Dim i As Long, kk As Long
Dim f As D3DXVECTOR4
For i = nVertexCount To 1 Step -1
 If (tVertex(i).nFlags And nIndexMask) = nIndex Then
  '///
  kk = tVertex(i).nParent
  If kk Then
   If kk < 0 Then kk = i
   f.x = tVertex(i).fNormal(1).x + fNormalSmoothness * (tVertex(kk).fNormal(0).x - tVertex(i).fNormal(1).x)
   f.y = tVertex(i).fNormal(1).y + fNormalSmoothness * (tVertex(kk).fNormal(0).y - tVertex(i).fNormal(1).y)
   f.z = tVertex(i).fNormal(1).z + fNormalSmoothness * (tVertex(kk).fNormal(0).z - tVertex(i).fNormal(1).z)
   f.w = Sqr(f.x * f.x + f.y * f.y + f.z * f.z)
   If f.w > 0.000001! Then
    tVertex(i).fNormal(0).x = f.x / f.w
    tVertex(i).fNormal(0).y = f.y / f.w
    tVertex(i).fNormal(0).z = f.z / f.w
   Else
    tVertex(i).fNormal(0) = tVertex(i).fNormal(1)
   End If
  Else
   tVertex(i).fNormal(0) = tVertex(i).fNormal(1)
  End If
  '///
  tVertex(i).nFlags = tVertex(i).nFlags Or &H4000&
 End If
Next i
End Sub

'if nVertexIndex4>0 then quad else tri
Friend Sub pCreateFace(ByRef tFace() As typeMeshFace_Temp, ByVal nFaceIndex As Long, ByRef tVertex() As typeMeshVertex_Temp, _
ByVal nVertexIndex1 As Long, ByVal nVertexIndex2 As Long, ByVal nVertexIndex3 As Long, ByVal nVertexIndex4 As Long, _
ByRef p As D3DXVECTOR4, ByRef pDelta1 As D3DXVECTOR4, ByRef pDelta2 As D3DXVECTOR4, _
ByRef pTex As D3DXVECTOR4, ByRef pTexDelta1 As D3DXVECTOR4, ByRef pTexDelta2 As D3DXVECTOR4, _
Optional ByVal nParentIndex1 As Long, Optional ByVal nParentIndex2 As Long, Optional ByVal nParentIndex3 As Long, Optional ByVal nParentIndex4 As Long, _
Optional ByVal nVertexFlags As Long, Optional ByVal nFaceFlags As Long, Optional ByVal nUseParentTexFlags As Long)
Dim t As D3DXVECTOR4, tTex As D3DXVECTOR4
'///Index1
If nParentIndex1 > 0 Then
 tVertex(nParentIndex1).nParent = -1
 tVertex(nVertexIndex1).nParent = nParentIndex1
 tVertex(nVertexIndex1).fPos = tVertex(nParentIndex1).fPos
 If nUseParentTexFlags And 1& Then _
 tVertex(nVertexIndex1).fTexcoord = tVertex(nParentIndex1).fTexcoord
Else
 tVertex(nVertexIndex1).fPos = p
 nUseParentTexFlags = nUseParentTexFlags And Not 1&
End If
tVertex(nVertexIndex1).nFlags = nVertexFlags
If (nUseParentTexFlags And 1&) = 0& Then _
tVertex(nVertexIndex1).fTexcoord = pTex
'///Index2
If nParentIndex2 > 0 Then
 tVertex(nParentIndex2).nParent = -1
 tVertex(nVertexIndex2).nParent = nParentIndex2
 tVertex(nVertexIndex2).fPos = tVertex(nParentIndex2).fPos
 If nUseParentTexFlags And 2& Then _
 tVertex(nVertexIndex2).fTexcoord = tVertex(nParentIndex2).fTexcoord
Else
 tVertex(nVertexIndex2).fPos = D3DXVec4Add(p, pDelta1)
 nUseParentTexFlags = nUseParentTexFlags And Not 2&
End If
tVertex(nVertexIndex2).nFlags = nVertexFlags
If (nUseParentTexFlags And 2&) = 0& Then _
tVertex(nVertexIndex2).fTexcoord = D3DXVec4Add(pTex, pTexDelta1)
'///
t = D3DXVec4Add(p, pDelta2)
tTex = D3DXVec4Add(pTex, pTexDelta2)
'///Index3
If nParentIndex3 > 0 Then
 tVertex(nParentIndex3).nParent = -1
 tVertex(nVertexIndex3).nParent = nParentIndex3
 tVertex(nVertexIndex3).fPos = tVertex(nParentIndex3).fPos
 If nUseParentTexFlags And 4& Then _
 tVertex(nVertexIndex3).fTexcoord = tVertex(nParentIndex3).fTexcoord
Else
 tVertex(nVertexIndex3).fPos = t
 nUseParentTexFlags = nUseParentTexFlags And Not 4&
End If
tVertex(nVertexIndex3).nFlags = nVertexFlags
If (nUseParentTexFlags And 4&) = 0& Then _
tVertex(nVertexIndex3).fTexcoord = tTex
'///Index4
If nVertexIndex4 > 0 Then
 If nParentIndex4 > 0 Then
  tVertex(nParentIndex4).nParent = -1
  tVertex(nVertexIndex4).nParent = nParentIndex4
  tVertex(nVertexIndex4).fPos = tVertex(nParentIndex4).fPos
  If nUseParentTexFlags And 8& Then _
  tVertex(nVertexIndex4).fTexcoord = tVertex(nParentIndex4).fTexcoord
 Else
  tVertex(nVertexIndex4).fPos = D3DXVec4Add(t, pDelta1)
  nUseParentTexFlags = nUseParentTexFlags And Not 8&
 End If
 tVertex(nVertexIndex4).nFlags = nVertexFlags
 If (nUseParentTexFlags And 8&) = 0& Then _
 tVertex(nVertexIndex4).fTexcoord = D3DXVec4Add(tTex, pTexDelta1)
 '///
 tFace(nFaceIndex).nCount = 4
 tFace(nFaceIndex).nVertex(3) = nVertexIndex4
Else
 tFace(nFaceIndex).nCount = 3
End If
'///Face
tFace(nFaceIndex).nFlags = nFaceFlags
tFace(nFaceIndex).nVertex(0) = nVertexIndex1
tFace(nFaceIndex).nVertex(1) = nVertexIndex2
tFace(nFaceIndex).nVertex(2) = nVertexIndex3
End Sub

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
 'TODO:template support
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
   'TODO:template support
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
     t.FVF = t.FVF Or (D3DFVF_DIFFUSE * j)
    Else
     Debug.Assert False
     Exit Function
    End If
   ElseIf Left(s, 8) = "texcoord" Then
    j = Val(Mid(s, 9))
    If j >= 0 And j < 16 Then
     k = (j + 1) * &H100&
     If (t.FVF And &H1F00&) < k Then t.FVF = (t.FVF And Not &H1F00&) Or k
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
    t2.tParams(t2.nParamCount).nType = j
    If Not pReadComponentValue(objNode.GetSubNodeValueAsString(i), t2, t2.nParamCount, t.nType) Then Exit Function
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
 pCreateCube t, t2
Case Else
 Debug.Assert False
 Exit Function
End Select
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
