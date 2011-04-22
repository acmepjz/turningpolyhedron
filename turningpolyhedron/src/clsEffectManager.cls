VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsEffectManager"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'TODO:use collection for fast look up (?)

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)

Private Type typeFakeDXEffectArgument
 nType As Long '[3]
 '0=undefined
 '1=hard-coded constant[1]
 '2=shader argument constant[2]
 '&HF1=texture(2D) file[2][b]
 '---read vertex shader input = &H10000-&H1FFFFF
 '&H10000,&H20000=color0-1
 '&H100000-&H1F0000=texcoord0-15
 'bit0-3,4-7,8-11,12-15=components1,2,3,4 if all 0 then default order = &H4321
 '0=undefined/zero
 '1,2,3,4=components1,2,3,4
 '5=hard-coded constant[1]
 '6=shader argument constant[2]
 '7=one
 '---(2D)texture[1][2][a] = &H1000000-&H1FFFFFF
 '&H1xyzzww
 'x=texture sampler index (0-15)
 'y=texcoord index (0-15)
 'zz=output components (default=&HE4)
 'ww=input components (default=&HE4)
 '---
 'TODO:other (eg. expression, volume texture, etc.)
 '--------
 '[1] uses sData
 '[2] uses sOptionalData
 '[a] sData format = sampler properties ['\x01' ...]
 '    sOptionalData = file name (???)
 '[b] doesn't generate any argument code
 '////////following strings are BINARY data !!!
 sData As String '[3]
 sOptionalData As String '[4]
 '////////if use shader argument
 nParamOffset As Byte
 nParamSize As Byte
 '////////
 nReserved1 As Byte
 nReserved2 As Byte
End Type

'TODO:light type
Private Type typeFakeDXEffect
 nReferenceIndex As Long
 '0=no
 '>0=has same effect with nReferenceIndex
 '////////
 nTemplateIndex As Long
 '-1=this is a template
 '0=no template
 '>0=template index
 sTemplateName As String 'if this is a template
 '////////
 sShaderProgram As String '[3]
 '""         = don't use shader (alias "default" "none")
 '"standard" = standard shader
 nDiffuseAlgorithm As Long '[3]
 '0=default=Lambertian
 '1=Oren-Nayar
 nSpecularAlgorithm As Long '[3]
 '0=default=Blinn-Phong
 '1=Phong
 nFlags As Long '[3]
 '1=advanecd fog enabled (currently can't read from settings)
 '2=shadow map enabled (currently unsupported)
 '4=
 '8=
 '---
 'bit 4-7 = hardware instancing mode (will use POSITION4-7)
 '0=none
 '1=translation only
 'etc...
 '15=world matrix (full)
 '---
 '////////
 tArguments(63) As typeFakeDXEffectArgument
 '////////
 sEffectStates As String '[3]
 sShaderSourceCode As String 'optional
 '////////
 nParamUsed As Long 'used float4
 fParams(63) As D3DXVECTOR4
 '////////
 nTextureUsedFlag As Long 'bit 0-15
 objTextures(15) As Direct3DBaseTexture9
 '////////
 objEffect As D3DXEffect
End Type
'--------
'[3] compare (pCompareFakeDXEffect value=1)
'[4] optional compare (pCompareFakeDXEffect value=2)
'--------

Public Enum enumFakeDXEffectArgumentType
 IDA_BaseColor
 IDA_Ambient
 IDA_Diffuse
 IDA_Specular
 IDA_SpecularHardness
 IDA_OrenNayarRoughness
 IDA_Emissive
 '///
 IDA_NormalMap
 IDA_NormalMapScale
 '///
 IDA_ParallaxMap
 IDA_ParallaxMapOffset
 IDA_ParallaxMapScale
End Enum

Private m_tEffect() As typeFakeDXEffect '1-based
Private m_nEffectCount As Long, m_nEffectMax As Long

Private m_tInst As typeMeshInstanceCollection

Private Type typeAppearanceData
 nCount As Long
 tData() As typeMeshInstanceData
 'nType should always be 0 (?)
End Type

Private m_tAppr() As typeAppearanceData '1-based
Private m_nApprCount As Long, m_nApprMax As Long

Private m_sParamName(63) As String
Private m_nParamSize(63) As Long
Private m_sOutputName(31) As String
Private m_sOutputSemantics(31) As String

Private m_nLastIndex As Long

Implements ISort2

Friend Sub SetTexture(ByVal nIndex As Long, ByVal nType As enumFakeDXEffectArgumentType, ByVal obj As Direct3DBaseTexture9)
Dim t As Long
If nIndex > 0 And nIndex <= m_nEffectCount Then
 t = m_tEffect(nIndex).tArguments(nType).nType
 If t >= &H1000000 And t < &H2000000 Then
  t = (t And &HF00000) \ &H100000
  Set m_tEffect(nIndex).objTextures(t) = obj
 Else
  'TODO:other texture
 End If
End If
End Sub

Friend Sub EraseTexture(Optional ByVal nIndex As Long)
Dim i As Long
If nIndex = 0 Then
 For i = 1 To m_nEffectCount
  Erase m_tEffect(i).objTextures
 Next i
ElseIf nIndex > 0 And nIndex <= m_nEffectCount Then
 Erase m_tEffect(nIndex).objTextures
End If
End Sub

Friend Sub Destroy()
Erase m_tEffect, m_tInst.tInstance, m_tInst.nInstOrder, m_tAppr
m_nEffectCount = 0
m_nEffectMax = 0
m_tInst.nInstCount = 0
m_tInst.nInstUnused = 0
m_tInst.bInstDirty = False
m_nApprCount = 0
m_nApprMax = 0
End Sub

Friend Sub ClearInstance()
Erase m_tInst.tInstance, m_tInst.nInstOrder
m_tInst.nInstCount = 0
m_tInst.nInstUnused = 0
m_tInst.bInstDirty = False
End Sub

Friend Sub ClearAppearance()
Erase m_tAppr
m_nApprCount = 0
m_nApprMax = 0
End Sub

Friend Property Get InstanceCount() As Long
InstanceCount = m_tInst.nInstCount
End Property

Friend Property Get AppearanceCount() As Long
AppearanceCount = m_nApprCount
End Property

'internal use only
Friend Function pAddEmptyInstance(ByRef tInst As typeMeshInstanceCollection) As Long
Dim idx As Long, m As Long
If tInst.nInstUnused > 0 Then
 idx = tInst.nInstUnused
 tInst.nInstUnused = tInst.tInstance(idx).nEffectIndex And &H7FFFFFFF
Else
 m = tInst.nInstCount + 256&
 ReDim Preserve tInst.tInstance(1 To m)
 ReDim Preserve tInst.nInstOrder(1 To m)
 '///
 For idx = tInst.nInstCount + 2 To m - 1
  tInst.tInstance(idx).nEffectIndex = (idx + 1) Or &H80000000
 Next idx
 '///
 idx = tInst.nInstCount + 1
 tInst.nInstUnused = tInst.nInstCount + 2
End If
tInst.nInstCount = tInst.nInstCount + 1
tInst.nInstOrder(tInst.nInstCount) = idx
tInst.bInstDirty = True
pAddEmptyInstance = idx
End Function

Friend Function AddInstance(ByVal nEffectIndex As Long, ByVal nMeshIndex As Long, ByRef matWorld As D3DMATRIX) As Long
Dim idx As Long
If nEffectIndex > 0 And nEffectIndex <= m_nEffectCount And nMeshIndex > 0 Then
 idx = pAddEmptyInstance(m_tInst)
 m_tInst.tInstance(idx).nEffectIndex = nEffectIndex
 m_tInst.tInstance(idx).nMeshIndex = nMeshIndex
 m_tInst.tInstance(idx).matWorld = matWorld
 AddInstance = idx
End If
End Function

'only return last created instance if appearance data has more than one objects
Friend Function AddInstanceFromAppearance(ByVal nIndex As Long, ByRef matWorld As D3DMATRIX) As Long
Dim i As Long
Dim t As typeMeshInstanceData
If nIndex > 0 And nIndex <= m_nApprCount Then
 For i = 1 To m_tAppr(nIndex).nCount
  t = m_tAppr(nIndex).tData(i)
  D3DXMatrixMultiply t.matWorld, t.matWorld, matWorld
  AddInstanceFromAppearance = AddInstance(t.nEffectIndex, t.nMeshIndex, t.matWorld)
 Next i
End If
End Function

Friend Sub RemoveInstance(ByVal nIndex As Long)
pRemoveInstance m_tInst, nIndex
End Sub

'internal use only
Friend Sub pRemoveInstance(ByRef tInst As typeMeshInstanceCollection, ByVal nIndex As Long)
Dim i As Long
Dim t As typeMeshInstanceData
If tInst.tInstance(nIndex).nEffectIndex > 0 Then
 '///
 For i = 1 To tInst.nInstCount - 1
  If tInst.nInstOrder(i) = nIndex Then
   tInst.nInstOrder(i) = tInst.nInstOrder(tInst.nInstCount)
   Exit For
  End If
 Next i
 '///
 t.nEffectIndex = tInst.nInstUnused Or &H80000000
 tInst.tInstance(nIndex) = t
 tInst.nInstUnused = nIndex
 tInst.nInstCount = tInst.nInstCount - 1
 tInst.bInstDirty = True
End If
End Sub

Friend Property Get InstanceEffectIndex(ByVal nIndex As Long) As Long
InstanceEffectIndex = m_tInst.tInstance(nIndex).nEffectIndex
End Property

Friend Property Let InstanceEffectIndex(ByVal nIndex As Long, ByVal n As Long)
Dim i As Long
If n > 0 Then
 i = m_tInst.tInstance(nIndex).nEffectIndex
 If i > 0 And i <> n Then
  Select Case m_tInst.tInstance(nIndex).nType
  Case 1 To 15
   'TODO:change effect index when using hardware instancing
  Case Else
   m_tInst.tInstance(nIndex).nEffectIndex = n
   m_tInst.bInstDirty = True
  End Select
 End If
End If
End Property

Friend Property Get InstanceMeshIndex(ByVal nIndex As Long) As Long
InstanceMeshIndex = m_tInst.tInstance(nIndex).nMeshIndex
End Property

Friend Property Let InstanceMeshIndex(ByVal nIndex As Long, ByVal n As Long)
If n > 0 Then m_tInst.tInstance(nIndex).nMeshIndex = n
End Property

Friend Property Get InstanceTransform(ByVal nIndex As Long) As D3DMATRIX
InstanceTransform = m_tInst.tInstance(nIndex).matWorld
End Property

Friend Property Let InstanceTransform(ByVal nIndex As Long, ByRef mat As D3DMATRIX)
m_tInst.tInstance(nIndex).matWorld = mat
End Property

'has some code copied from SetupEffect
Friend Sub DrawInstance(ByVal objMeshMgr As clsMeshManager, Optional ByVal bSetupLight As Boolean, Optional ByVal bUseExistingTransform As Boolean)
Dim i As Long, ii As Long, j As Long, k As Long
Dim idx As Long
Dim nEffectIndex As Long
Dim objMesh As D3DXMesh
Dim obj As D3DXEffect, objNew As D3DXEffect
Dim mat As D3DMATRIX, matBackup As D3DMATRIX
Dim b As Boolean
'///
If m_nEffectCount <= 0 Or m_tInst.nInstCount <= 0 Or m_nLastIndex > 0 Then Exit Sub
'///
If m_tInst.bInstDirty Then
 With New ISort2
  .QuickSort m_tInst.nInstOrder, 1, m_tInst.nInstCount, Me
 End With
 m_tInst.bInstDirty = False
End If
'///
d3dd9.GetTransform D3DTS_WORLD, matBackup
'///
For i = 1 To m_tInst.nInstCount
 idx = m_tInst.nInstOrder(i)
 '///SetupEffect
 j = m_tInst.tInstance(idx).nEffectIndex
 If nEffectIndex <> j Then
  nEffectIndex = j
  Set objNew = m_tEffect(j).objEffect
  b = Not obj Is objNew
  If b Then 'change effect
   If Not obj Is Nothing Then
    obj.EndPass
    obj.End
   End If
   Set obj = objNew
  End If
  If obj Is Nothing Then
   'TODO:no HLSL
   Debug.Assert False
   Exit For
  Else
   '///SetupParam
   ii = m_tEffect(nEffectIndex).nParamUsed
   If ii > 0 Then _
   obj.SetVectorArray StrPtr(StrConv("_fParam", vbFromUnicode)), m_tEffect(nEffectIndex).fParams(0), ii
   '///SetupTexture
   j = 1
   k = m_tEffect(nEffectIndex).nTextureUsedFlag
   For ii = 0 To 15
    If j And k Then
     obj.SetTexture StrPtr(StrConv("tex" + CStr(ii), vbFromUnicode)), m_tEffect(nEffectIndex).objTextures(ii)
    End If
    j = j + j
   Next ii
   '///
   If b Then
    If bSetupLight Then
     objRenderTest.SetupLight obj
    End If
    If m_tEffect(nEffectIndex).nFlags And 1& Then objRenderTest.SetupZData obj
    obj.SetTechnique StrPtr(StrConv("test", vbFromUnicode))
    obj.Begin 0, 0
    obj.BeginPass 0
   End If
   '///
  End If
 End If
 '///SetupTransform
 If bUseExistingTransform Then
  D3DXMatrixMultiply mat, m_tInst.tInstance(idx).matWorld, matBackup
  d3dd9.SetTransform D3DTS_WORLD, mat
 Else
  d3dd9.SetTransform D3DTS_WORLD, m_tInst.tInstance(idx).matWorld
 End If
 objRenderTest.SetupTransform obj
 obj.CommitChanges
 '///draw
 j = m_tInst.tInstance(idx).nMeshIndex
 Set objMesh = objMeshMgr.Mesh(j)
 Select Case m_tInst.tInstance(idx).nType
 Case 1 To 15
  '///TEST hardware instancing
  d3dd9.SetStreamSourceFreq 0, D3DSTREAMSOURCE_INDEXEDDATA Or m_tInst.tInstance(idx).nCount
  d3dd9.SetStreamSource 0, objMesh.GetVertexBuffer, 0, objMeshMgr.MeshVertexSize(j)
  d3dd9.SetStreamSourceFreq 1, D3DSTREAMSOURCE_INSTANCEDATA Or 1
  d3dd9.SetStreamSource 1, m_tInst.tInstance(idx).objInstanceBuffer, 0, m_tInst.tInstance(idx).nInstanceVertexSize
  '///
  d3dd9.SetVertexDeclaration m_tInst.tInstance(idx).objDeclaration
  d3dd9.SetIndices objMesh.GetIndexBuffer
  d3dd9.DrawIndexedPrimitive D3DPT_TRIANGLELIST, 0, 0, objMesh.GetNumVertices, 0, objMesh.GetNumFaces
  '///
  d3dd9.SetStreamSourceFreq 0, 1
  d3dd9.SetStreamSource 0, Nothing, 0, 0
  d3dd9.SetStreamSourceFreq 1, 1
  d3dd9.SetStreamSource 1, Nothing, 0, 0
 Case Else
  objMesh.DrawSubset 0
 End Select
Next i
'///over
If Not obj Is Nothing Then
 obj.EndPass
 obj.End
End If
d3dd9.SetTransform D3DTS_WORLD, matBackup
End Sub

'TODO:per-instance color support, etc.
Friend Function AddHWInstance(ByVal objMeshMgr As clsMeshManager, ByVal nEffectIndex As Long, ByVal nMeshIndex As Long, ByRef matWorld() As D3DMATRIX, ByVal nStart As Long, ByVal nEnd As Long) As Long
Dim nHWInstancingMode As Long
Dim objInstanceBuffer As Direct3DVertexBuffer9
Dim objMesh As D3DXMesh
Dim t(64) As D3DVERTEXELEMENT9
Dim i As Long, lp As Long
Dim nSize As Long
'///
If nEffectIndex <= 0 Or nEffectIndex > m_nEffectCount Or nMeshIndex <= 0 Then Exit Function
'///
nEnd = nEnd - nStart + 1
If nEnd <= 0 Then Exit Function
'///
nHWInstancingMode = (m_tEffect(nEffectIndex).nFlags And &HF0&) \ &H10&
Select Case nHWInstancingMode
Case 1
 d3dd9.CreateVertexBuffer nEnd * 16&, 0, 0, D3DPOOL_MANAGED, objInstanceBuffer, ByVal 0
 objInstanceBuffer.Lock 0, 0, lp, D3DLOCK_DISCARD
 For i = nStart To nStart + nEnd - 1
  CopyMemory ByVal lp, matWorld(i).m41, 16&
  lp = lp + 16&
 Next i
 objInstanceBuffer.Unlock
 nSize = 16&
Case 15
 d3dd9.CreateVertexBuffer nEnd * 64&, 0, 0, D3DPOOL_MANAGED, objInstanceBuffer, ByVal 0
 objInstanceBuffer.Lock 0, 0, lp, D3DLOCK_DISCARD
 CopyMemory ByVal lp, matWorld(nStart), nEnd * 64&
 objInstanceBuffer.Unlock
 nSize = 64&
Case Else
 '///fallback to software instancing
 For i = nStart To nStart + nEnd - 1
  AddHWInstance = AddInstance(nEffectIndex, nMeshIndex, matWorld(i))
 Next i
 Exit Function
End Select
'///create vertex declaration
Set objMesh = objMeshMgr.Mesh(nMeshIndex)
objMesh.GetDeclaration t(0)
For i = 0 To 64
 If t(i).Stream = &HFF& Then
  Select Case nHWInstancingMode
  Case 1
   t(i) = D3DVertexElementCreate(1, 0, D3DDECLTYPE_FLOAT4, , D3DDECLUSAGE_POSITION, 4)
   t(i + 1) = D3DDECL_END
  Case 15
   t(i) = D3DVertexElementCreate(1, 0, D3DDECLTYPE_FLOAT4, , D3DDECLUSAGE_POSITION, 4)
   t(i + 1) = D3DVertexElementCreate(1, 16, D3DDECLTYPE_FLOAT4, , D3DDECLUSAGE_POSITION, 5)
   t(i + 2) = D3DVertexElementCreate(1, 32, D3DDECLTYPE_FLOAT4, , D3DDECLUSAGE_POSITION, 6)
   t(i + 3) = D3DVertexElementCreate(1, 48, D3DDECLTYPE_FLOAT4, , D3DDECLUSAGE_POSITION, 7)
   t(i + 4) = D3DDECL_END
  End Select
  Exit For
 End If
Next i
'///
i = pAddEmptyInstance(m_tInst)
m_tInst.tInstance(i).nType = nHWInstancingMode
m_tInst.tInstance(i).nEffectIndex = nEffectIndex
m_tInst.tInstance(i).nMeshIndex = nMeshIndex
m_tInst.tInstance(i).matWorld = D3DXMatrixIdentity 'TODO:custom base matrix
m_tInst.tInstance(i).nCount = nEnd
m_tInst.tInstance(i).nInstanceVertexSize = nSize
Set m_tInst.tInstance(i).objDeclaration = d3dd9.CreateVertexDeclaration(t(0))
Set m_tInst.tInstance(i).objInstanceBuffer = objInstanceBuffer
AddHWInstance = i
End Function

'only return last created instance if appearance data has more than one objects
'TODO:per-instance color support, etc.
Friend Function AddHWInstanceFromAppearance(ByVal objMeshMgr As clsMeshManager, ByVal nIndex As Long, ByRef matWorld() As D3DMATRIX, ByVal nStart As Long, ByVal nEnd As Long) As Long
Dim i As Long
'Dim t As typeMeshInstanceData
If nIndex > 0 And nIndex <= m_nApprCount Then
 For i = 1 To m_tAppr(nIndex).nCount
  '///TODO:custom base matrix (important if m_tAppr(nIndex).tData(i).matWorld is not identity)
  't = m_tAppr(nIndex).tData(i)
  'D3DXMatrixMultiply t.matWorld, t.matWorld, matWorld
  AddHWInstanceFromAppearance = AddHWInstance(objMeshMgr, m_tAppr(nIndex).tData(i).nEffectIndex, _
  m_tAppr(nIndex).tData(i).nMeshIndex, matWorld, nStart, nEnd)
 Next i
End If
End Function

Private Sub Class_Initialize()
Dim i As Long
'///
m_sParamName(IDA_BaseColor) = "baseColor"
m_sParamName(IDA_Ambient) = "ambient"
m_sParamName(IDA_Diffuse) = "diffuse"
m_sParamName(IDA_Specular) = "specular"
m_sParamName(IDA_SpecularHardness) = "specularHardness"
m_sParamName(IDA_OrenNayarRoughness) = "OrenNayarRoughness"
m_sParamName(IDA_Emissive) = "emissive"
m_sParamName(IDA_NormalMap) = "normalMap"
m_sParamName(IDA_NormalMapScale) = "normalMapScale"
m_sParamName(IDA_ParallaxMap) = "parallaxMap"
m_sParamName(IDA_ParallaxMapOffset) = "parallaxMapOffset"
m_sParamName(IDA_ParallaxMapScale) = "parallaxMapScale"
'///
m_nParamSize(IDA_BaseColor) = 4
m_nParamSize(IDA_Ambient) = 4
m_nParamSize(IDA_Diffuse) = 4
m_nParamSize(IDA_Specular) = 4
m_nParamSize(IDA_SpecularHardness) = 1
m_nParamSize(IDA_OrenNayarRoughness) = 1
m_nParamSize(IDA_Emissive) = 4
m_nParamSize(IDA_NormalMap) = 3
m_nParamSize(IDA_NormalMapScale) = 1
m_nParamSize(IDA_ParallaxMap) = 1
m_nParamSize(IDA_ParallaxMapOffset) = 1
m_nParamSize(IDA_ParallaxMapScale) = 1
'///
For i = 0 To 1
 m_sOutputSemantics(i + 1) = "COLOR" + CStr(i)
 m_sOutputName(i + 1) = "c" + CStr(i)
Next i
For i = 0 To 15
 m_sOutputSemantics(i + 16) = "TEXCOORD" + CStr(i)
 m_sOutputName(i + 16) = "t" + CStr(i)
Next i
End Sub

'0=not match
'1=shader program match
'2=shader argument match
Friend Function pCompareFakeDXEffect(ByRef t1 As typeFakeDXEffect, ByRef t2 As typeFakeDXEffect) As Long
Dim i As Long
'///
If t1.sShaderProgram <> t2.sShaderProgram Then Exit Function
If t1.nDiffuseAlgorithm <> t2.nDiffuseAlgorithm Then Exit Function
If t1.nSpecularAlgorithm <> t2.nSpecularAlgorithm Then Exit Function
If t1.nFlags <> t2.nFlags Then Exit Function
If t1.sEffectStates <> t2.sEffectStates Then Exit Function
For i = 0 To 63
 If t1.tArguments(i).nType <> t2.tArguments(i).nType Then Exit Function
 If t1.tArguments(i).sData <> t2.tArguments(i).sData Then Exit Function
Next i
'///
pCompareFakeDXEffect = 1
For i = 0 To 63
 If t1.tArguments(i).sOptionalData <> t2.tArguments(i).sOptionalData Then Exit Function
Next i
'///
pCompareFakeDXEffect = 2
End Function

Friend Function pFindExistingFakeDXEffect(ByRef t As typeFakeDXEffect, ByRef nIndex As Long) As Long
Dim i As Long
Dim j As Long, jj As Long
Dim idx As Long
'///
If t.nTemplateIndex > 0 Then
 nIndex = t.nTemplateIndex
 jj = 1
Else
 nIndex = 0
 jj = 0
End If
'///
For i = 1 To m_nEffectCount
 j = pCompareFakeDXEffect(m_tEffect(i), t)
 If j > jj Then
  jj = j
  nIndex = i
  If j >= 2 Then Exit For
 End If
Next i
'///
pFindExistingFakeDXEffect = jj
End Function

Friend Function pCombineFakeDXEffectFromTemplate(ByRef t As typeFakeDXEffect) As Boolean
Dim i As Long
Dim t1 As Long, t2 As Long
Dim m1 As Long, m2 As Long
Dim s As String
Dim nType As Long
Dim bTextureOverwrite(15) As Byte
Dim bErr As Boolean
'///
If t.nTemplateIndex > 0 Then
 With m_tEffect(t.nTemplateIndex)
  t.sShaderProgram = .sShaderProgram
  t.nDiffuseAlgorithm = .nDiffuseAlgorithm
  t.nSpecularAlgorithm = .nSpecularAlgorithm
  t.nFlags = .nFlags
  t.sEffectStates = .sEffectStates
  '///copy arguments and check type
  For i = 0 To 63
   t1 = .tArguments(i).nType
   t2 = t.tArguments(i).nType
   nType = 0
   If t1 = 2 Or (t1 >= &H10000 And t1 < &H200000) Then
    If t2 = 0 Then
    ElseIf t2 = 1 Or t2 = 2 Then
     nType = 1
    Else
     Debug.Assert False
     bErr = True
     Exit For
    End If
   ElseIf t1 >= &H1000000 And t1 < &H2000000 Then
    If t2 = 0 Then
    ElseIf t2 = &HF1& Then
     nType = 2
    Else
     Debug.Assert False
     bErr = True
     Exit For
    End If
   End If
   If nType Then
    s = t.tArguments(i).sData
    If s = vbNullString Then s = t.tArguments(i).sOptionalData
    m1 = LenB(s)
    If m1 <= 0 Then nType = 0
   End If
   t.tArguments(i) = .tArguments(i)
   Select Case nType
   Case 1
    m2 = LenB(t.tArguments(i).sOptionalData)
    If m1 >= m2 Then t.tArguments(i).sOptionalData = s _
    Else MidB(t.tArguments(i).sOptionalData, 1, m1) = s
   Case 2
    t.tArguments(i).sOptionalData = s
    bTextureOverwrite((t1 And &HF00000) \ &H100000) = 1
   End Select
  Next i
  '///
  If Not bErr Then
   t.nParamUsed = .nParamUsed
   Set t.objEffect = .objEffect
   'useless
   'For i = 0 To 63
   ' t.fParams(i) = .fParams(i)
   'Next i
   t.nTextureUsedFlag = .nTextureUsedFlag
   For i = 0 To 15
    If bTextureOverwrite(i) = 0 Then Set t.objTextures(i) = .objTextures(i)
   Next i
  End If
 End With
End If
'///
pCombineFakeDXEffectFromTemplate = Not bErr
End Function

Friend Function pFindUnusedInput(bInputUsed() As Byte, ByVal nStart As Long, ByVal nEnd As Long) As Long
Dim i As Long
For i = nStart To nEnd
 If bInputUsed(i) = 0 Then
  bInputUsed(i) = 1
  pFindUnusedInput = i
  Exit Function
 End If
Next i
pFindUnusedInput = -1
End Function

Friend Function pParseArgumentFromString(ByRef t As typeFakeDXEffect, ByVal s As String, ByVal nIndex As Long) As Boolean
Dim nDesiredSize As Long
Dim lps As Long
Dim s1 As String
Dim v As Variant, m As Long
Dim i As Long, ii As Long
Dim j As Long
Dim k As Long, kk As Long
Dim ret As typeFakeDXEffectArgument
Dim f As Single
'///
nDesiredSize = m_nParamSize(nIndex)
If nDesiredSize <= 0 Then
 Debug.Assert False
 Exit Function
End If
'///
v = Split(Trim(s), ":")
m = UBound(v) + 1
If m > 0 Then
 s = Trim(v(0))
 If Left(s, 5) = "color" Then
  i = Val(Mid(s, 6))
  If i = 0 Or i = 1 Then ret.nType = (i + 1) * &H10000 _
  Else Exit Function
 ElseIf Left(s, 8) = "texcoord" Then
  i = Val(Mid(s, 9))
  If i >= 0 And i < 16 Then ret.nType = (i + 16) * &H10000 _
  Else Exit Function
 ElseIf Left(s, 15) = "textureArgument" Then
  i = Val(Mid(s, 16))
  If i >= 0 And i < 16 Then ret.nType = (i + 16) * &H100000 _
  Else Exit Function
  'TODO:other texture
 ElseIf Left(s, 11) = "textureFile" Then
  ret.nType = &HF1&
  If m > 1 Then ret.sOptionalData = Trim(v(1))
 End If
 If ret.nType >= &H10000 And ret.nType < &H200000 Then
  '////////////////shader input
  If m > 1 Then
   s1 = Left(Trim(v(1)), 4)
   If m > 2 Then
    v = Split(Trim(v(2)), ",")
    m = UBound(v) + 1
   Else
    m = 0
   End If
   k = 1
   For i = 1 To Len(s1)
    '///
    Select Case Mid(s1, i, 1)
    Case "x", "r"
     kk = 1
    Case "y", "g"
     kk = 2
    Case "z", "b"
     kk = 3
    Case "w", "a"
     kk = 4
    Case "C"
     kk = 5
     If ii < m Then f = Val(v(ii)) Else f = 0
     s = Space(2)
     CopyMemory ByVal StrPtr(s), f, 4&
     ret.sData = ret.sData + s
     ii = ii + 1
    Case "A"
     kk = 6
     If ii < m Then f = Val(v(ii)) Else f = 0
     s = Space(2)
     CopyMemory ByVal StrPtr(s), f, 4&
     ret.sOptionalData = ret.sOptionalData + s
     ii = ii + 1
    Case "1"
     kk = 7
    Case Else
     kk = 0
    End Select
    ret.nType = ret.nType Or (k * kk)
    '///
    k = k * &H10&
   Next i
  End If
 ElseIf s = "shaderArgument" Then
  '////////////////shader argument (constant)
  ret.nType = 2
  If m > 1 Then
   v = Split(Trim(v(1)), ",")
   m = UBound(v) + 1
   If m > 0 Then
    ret.sOptionalData = Space(m * 2&)
    For i = 0 To m - 1
     f = Val(v(i))
     CopyMemory ByVal StrPtr(ret.sOptionalData) + i * 4&, f, 4&
    Next i
   End If
  End If
  ret.sOptionalData = Left(ret.sOptionalData + String(nDesiredSize * 2&, vbNullChar), nDesiredSize * 2&)
 ElseIf ret.nType >= &H1000000 And ret.nType < &H2000000 Then
  '////////////////texture
  'TODO:other texture
  ret.nType = ret.nType Or &HE4E4&
  'read output components
  i = InStr(1, s, ".")
  If i > 0 Then
   k = &H100&
   For i = i + 1 To i + 4
    Select Case Mid(s, i, 1)
    Case "x", "r": kk = 0
    Case "y", "g": kk = 1
    Case "z", "b": kk = 2
    Case "w", "a": kk = 3
    Case Else: Exit For
    End Select
    ret.nType = (ret.nType And Not (k * 3&)) Or (k * kk)
    k = k * 4&
   Next i
  End If
  'read input index and components
  If m > 1 Then
   s = Trim(v(1))
   If Left(s, 8) = "texcoord" Then
    i = Val(Mid(s, 9))
    If i >= 0 And i < 16 Then ret.nType = ret.nType Or (i * &H10000) _
    Else Exit Function
   Else
    Debug.Assert False
    Exit Function
   End If
   '///
   i = InStr(1, s, ".")
   If i > 0 Then
    k = &H1&
    For i = i + 1 To i + 4
     Select Case Mid(s, i, 1)
     Case "x", "r": kk = 0
     Case "y", "g": kk = 1
     Case "z", "b": kk = 2
     Case "w", "a": kk = 3
     Case Else: Exit For
     End Select
     ret.nType = (ret.nType And Not (k * 3&)) Or (k * kk)
     k = k * 4&
    Next i
   End If
   '///
  End If
  '///read file name (if any)
  i = 2
  If m > i Then
   If Trim(v(i)) = "textureFile" Then
    i = i + 1
    If m > i Then
     ret.sOptionalData = Trim(v(i))
     i = i + 1
    End If
   End If
  End If
  '///read sampler parameters
  If m > i Then
   ret.sData = Trim(v(i))
   If Right(ret.sData, 1) <> ";" Then ret.sData = ret.sData + ";"
  End If
 Else
  '////////////////fixed constant
  ret.nType = 1
  v = Split(s, ",")
  m = UBound(v) + 1
  If m > 0 Then
   ret.sData = Space(m * 2&)
   For i = 0 To m - 1
    f = Val(v(i))
    CopyMemory ByVal StrPtr(ret.sData) + i * 4&, f, 4&
   Next i
  End If
  ret.sData = Left(ret.sData + String(nDesiredSize * 2&, vbNullChar), nDesiredSize * 2&)
 End If
End If
'///
If nIndex = IDA_OrenNayarRoughness Then
 Select Case ret.nType
 Case 1
  m = LenB(ret.sData)
  If m >= 4 Then
   CopyMemory f, ByVal StrPtr(ret.sData), 4&
   ret.sData = Space(4)
   f = f * f
   CopyMemory ByVal StrPtr(ret.sData), CSng(1 - 0.5 * f / (f + 0.33)), 4&
   CopyMemory ByVal StrPtr(ret.sData) + 4&, CSng(0.45 * f / (f + 0.09)), 4&
  End If
 Case 2
  m = LenB(ret.sOptionalData)
  If m >= 4 Then
   CopyMemory f, ByVal StrPtr(ret.sOptionalData), 4&
   ret.sOptionalData = Space(4)
   f = f * f
   CopyMemory ByVal StrPtr(ret.sOptionalData), CSng(1 - 0.5 * f / (f + 0.33)), 4&
   CopyMemory ByVal StrPtr(ret.sOptionalData) + 4&, CSng(0.45 * f / (f + 0.09)), 4&
  End If
 End Select
End If
'///
t.tArguments(nIndex) = ret
pParseArgumentFromString = True
End Function

Friend Function pGenerateArgumentCode(ByRef t As typeFakeDXEffect, ByVal nIndex As Long, ByVal nDesiredSize As Long, Optional ByVal sAdditional As String = vbNullString) As String
Dim nType As Long
Dim i As Long, j As Long, jj As Long
Dim nLast As Long
Dim m As Long, lp As Long
Dim f As Single
Dim b As Boolean
Dim d(3) As Byte
'///
pGenerateArgumentCode = "0"
With t.tArguments(nIndex)
 nType = .nType
 If nType = 0 Then
 ElseIf nType = 1 Then
  m = LenB(.sData) \ 4&
  lp = StrPtr(.sData)
  If m = 1 Then
   CopyMemory f, ByVal lp, 4&
   pGenerateArgumentCode = "(" + CStr(f) + ")"
  ElseIf m > 1 Then
   pGenerateArgumentCode = "float" + CStr(nDesiredSize) + "("
   For i = 0 To nDesiredSize - 1
    If i > 0 Then pGenerateArgumentCode = pGenerateArgumentCode + ","
    If i >= m Then
     pGenerateArgumentCode = pGenerateArgumentCode + "0"
    Else
     CopyMemory f, ByVal lp + i * 4&, 4&
     pGenerateArgumentCode = pGenerateArgumentCode + CStr(f)
    End If
   Next i
   pGenerateArgumentCode = pGenerateArgumentCode + ")"
  End If
 ElseIf nType = 2 Then
  m = .nParamSize
  If m = 1 Or m >= nDesiredSize Then
   If nDesiredSize > m Then nDesiredSize = m
   pGenerateArgumentCode = "_fParam[" + CStr(.nParamOffset \ 4&) + "]"
   If nDesiredSize < 4 Then
    pGenerateArgumentCode = pGenerateArgumentCode + "." + Mid("xyzw", (.nParamOffset And 3&) + 1, nDesiredSize)
   End If
  ElseIf m > 1 Then
   pGenerateArgumentCode = "float" + CStr(nDesiredSize) + "(" + "_fParam[" + CStr(.nParamOffset \ 4&) + "]." _
   + Mid("xyzw", (.nParamOffset And 3&) + 1, m) + Replace(Space(nDesiredSize - m), " ", ",0") + ")"
  End If
 ElseIf nType >= &H10000 And nType < &H200000 Then
  If (nType And &HFFFF&) = 0 Then
   d(0) = 1
   d(1) = 2
   d(2) = 3
   d(3) = 4
  Else
   d(0) = nType And &HF&
   d(1) = (nType And &HF0&) \ &H10&
   d(2) = (nType And &HF00&) \ &H100&
   d(3) = (nType And &HF000&) \ &H1000&
  End If
  '///
  b = True
  For i = 0 To nDesiredSize - 1
   If d(i) < 1 Or d(i) > 4 Then
    b = False
    Exit For
   End If
  Next i
  If b Then
   pGenerateArgumentCode = "cin." + m_sOutputName(nType \ &H10000) + "."
   For i = 0 To nDesiredSize - 1
    pGenerateArgumentCode = pGenerateArgumentCode + Mid("xyzw", d(i), 1)
   Next i
  Else
   nLast = 0
   m = LenB(.sData) \ 4&
   lp = StrPtr(.sData)
   j = 0
   jj = 0
   '///
   If nDesiredSize > 1 Then pGenerateArgumentCode = "float" + CStr(nDesiredSize) + "(" _
   Else pGenerateArgumentCode = "("
   For i = 0 To nDesiredSize - 1
    If d(i) >= 1 And d(i) <= 4 Then
     If nLast <> 1 Then
      If i > 0 Then pGenerateArgumentCode = pGenerateArgumentCode + ","
      pGenerateArgumentCode = pGenerateArgumentCode + "cin." + m_sOutputName(nType \ &H10000) + "."
     End If
     nLast = 1
     pGenerateArgumentCode = pGenerateArgumentCode + Mid("xyzw", d(i), 1)
    Else
     Select Case d(i)
     Case 0
      nLast = 0
      If i > 0 Then pGenerateArgumentCode = pGenerateArgumentCode + ","
      pGenerateArgumentCode = pGenerateArgumentCode + "0"
     Case 5
      nLast = 0
      If i > 0 Then pGenerateArgumentCode = pGenerateArgumentCode + ","
      If j >= m Then
       pGenerateArgumentCode = pGenerateArgumentCode + "0"
      Else
       CopyMemory f, ByVal lp + j * 4&, 4&
       pGenerateArgumentCode = pGenerateArgumentCode + CStr(f)
      End If
      j = j + 1
     Case 6
      If nLast <> 2 Then
       If i > 0 Then pGenerateArgumentCode = pGenerateArgumentCode + ","
       pGenerateArgumentCode = pGenerateArgumentCode + "_fParam[" + CStr(.nParamOffset \ 4&) + "]."
      End If
      nLast = 2
      pGenerateArgumentCode = pGenerateArgumentCode + Mid("xyzw", ((.nParamOffset + jj) And 3&) + 1, 1)
      jj = jj + 1
     Case 7
      nLast = 0
      If i > 0 Then pGenerateArgumentCode = pGenerateArgumentCode + ","
      pGenerateArgumentCode = pGenerateArgumentCode + "1"
     Case Else
      Debug.Assert False
     End Select
    End If
   Next i
   pGenerateArgumentCode = pGenerateArgumentCode + ")"
  End If
  '///
 ElseIf nType >= &H1000000 And nType < &H2000000 Then
  'texture
  pGenerateArgumentCode = "tex2D(samp" + CStr((nType And &HF00000) \ &H100000) + ",cin.t" + CStr((nType And &HF0000) \ &H10000) + "."
  j = nType And &HFF&
  For i = 1 To 2
   pGenerateArgumentCode = pGenerateArgumentCode + Mid("xyzw", 1 + (j And 3&), 1)
   j = j \ 4&
  Next i
  pGenerateArgumentCode = pGenerateArgumentCode + sAdditional + ")."
  j = (nType And &HFF00&) \ &H100&
  For i = 1 To nDesiredSize
   pGenerateArgumentCode = pGenerateArgumentCode + Mid("xyzw", 1 + (j And 3&), 1)
   j = j \ 4&
  Next i
 Else
  'TODO:other texture, etc.
  Debug.Assert False
 End If
End With
End Function

Friend Function pGenerateHLSLCodeFromFakeDXEffect(ByRef t As typeFakeDXEffect, Optional ByVal bComment As Boolean) As Boolean
Dim sParam As String, sTexture As String
Dim sInput As String, sOutput As String
Dim s1 As String, s2 As String
'///
Dim bParamUsed(255) As Byte
Dim bInputUsed(31) As Byte
Dim bTextureUsed(15) As Byte
Dim sTextureArgument(15) As String
Dim nExtraInputCount As Long
Dim i As Long
Dim j As Long
Dim k As Long, kk As Long
Dim m As Long, mm As Long
Dim nType As Long
'///
Dim bMoreNormals As Boolean
Dim bFogEnabled As Boolean 'currently unsupported
Dim bShadowMap As Boolean 'currently unsupported
Dim nHWInstancingMode As Long
'///
t.sShaderSourceCode = vbNullString
t.nParamUsed = 0
'///
Select Case t.sShaderProgram
Case vbNullString
 'TODO:no HLSL shader
Case "standard"
 '////////////////////////////////generate declarations
 '///assign parameters space
 For i = 0 To 63
  With t.tArguments(i)
   .nParamOffset = 0
   .nParamSize = 0
   kk = 1
   '///
   nType = .nType
   If nType = 2 Or (nType >= &H10000 And nType < &H200000) Then
    m = LenB(.sOptionalData) \ 4&
    Debug.Assert m <= 4
    If m > 0 And m <= 4 Then
     '///assign space
     For j = 0 To 252 Step 4
      kk = 0
      For k = j To j + 3
       If bParamUsed(k) Then
        kk = 0
       Else
        kk = kk + 1
        If kk >= m Then Exit For
       End If
      Next k
      If kk >= m Then
       .nParamOffset = k - m + 1
       .nParamSize = m
       '///set used flag
       For kk = k - m + 1 To k
        bParamUsed(kk) = 1
       Next kk
       '///output comment
       If bComment Then _
       sParam = sParam + "// " + CStr(i) + " " + m_sParamName(i) + " in _fParam[" + CStr(k \ 4&) + "]." + Mid("xyzw", ((k - m + 1) And 3&) + 1, m) + vbCrLf
       '///
       k = k \ 4& + 1
       If mm < k Then mm = k
       kk = 1
       Exit For
      End If
     Next j
     '///
    End If
   Else
    'TODO:etc.
   End If
  End With
  If kk = 0 Then Exit Function 'failed to assign space
 Next i
 '///generate parameters
 t.nParamUsed = mm
 If bComment Then _
 sParam = sParam + "// parameters used:" + CStr(mm) + vbCrLf
 If mm > 0 Then sParam = sParam + "float4 _fParam[" + CStr(mm) + "];" + vbCrLf
 sParam = sParam + vbCrLf
 '///assign input space
 For i = 0 To 63
  With t.tArguments(i)
   nType = .nType
   If nType >= &H10000 And nType < &H200000 Then
    j = nType \ &H10000
    bInputUsed(j) = 45
    '///output comment
    If bComment Then _
    sOutput = sOutput + "// " + CStr(i) + " " + m_sParamName(i) + " in " + m_sOutputSemantics(j) + vbCrLf
    '///
   ElseIf nType >= &H1000000 And nType < &H2000000 Then
    'texture
    j = ((nType And &HF0000) \ &H10000) + 16&
    bInputUsed(j) = 45
    '///output comment
    If bComment Then
     sOutput = sOutput + "// " + CStr(i) + " " + m_sParamName(i) + " in " + m_sOutputSemantics(j) + vbCrLf
     sTexture = sTexture + "// " + CStr(i) + " " + m_sParamName(i) + " in texture #" + _
     CStr((nType And &HF00000) \ &H100000) + " using " + m_sOutputSemantics(j) + vbCrLf
    End If
    '///
    j = (nType And &HF00000) \ &H100000
    bTextureUsed(j) = 1
    If .sData <> vbNullString Then sTextureArgument(j) = .sData
   Else
    'TODO:other texture, etc.
   End If
  End With
 Next i
 '///generate input
 sInput = sInput + "struct VS_INPUT{" + vbCrLf
 sOutput = sOutput + "struct VS_OUTPUT{" + vbCrLf
 For i = 0 To 31
  If bInputUsed(i) Then
   sInput = sInput + vbTab + "float4 " + m_sOutputName(i) + ":" + m_sOutputSemantics(i) + ";" + vbCrLf
   sOutput = sOutput + vbTab + "float4 " + m_sOutputName(i) + ":" + m_sOutputSemantics(i) + ";" + vbCrLf
  End If
 Next i
 '///assign extra input
 bMoreNormals = t.tArguments(IDA_NormalMap).nType <> 0 Or t.tArguments(IDA_ParallaxMap).nType <> 0
 bFogEnabled = t.nFlags And 1&
 bShadowMap = t.nFlags And 2&
 nHWInstancingMode = (t.nFlags And &HF0&) \ &H10&
 '///generate extra input
 If bComment Then
  sInput = sInput + vbTab + "//---" + vbCrLf
  sOutput = sOutput + vbTab + "//---" + vbCrLf
 End If
 i = pFindUnusedInput(bInputUsed, 16, 31)
 If i < 0 Then Exit Function
 sInput = sInput + vbTab + "float4 vPos:POSITION;" + vbCrLf
 sOutput = sOutput + vbTab + "float4 vPos:" + m_sOutputSemantics(i) + ";" + vbCrLf
 i = pFindUnusedInput(bInputUsed, 16, 31)
 If i < 0 Then Exit Function
 sInput = sInput + vbTab + "float4 vNormal:NORMAL;" + vbCrLf
 sOutput = sOutput + vbTab + "float4 vNormal:" + m_sOutputSemantics(i) + ";" + vbCrLf
 If bMoreNormals Then
  i = pFindUnusedInput(bInputUsed, 16, 31)
  If i < 0 Then Exit Function
  sInput = sInput + vbTab + "float4 vBinormal:BINORMAL;" + vbCrLf
  sOutput = sOutput + vbTab + "float4 vBinormal:" + m_sOutputSemantics(i) + ";" + vbCrLf
  i = pFindUnusedInput(bInputUsed, 16, 31)
  If i < 0 Then Exit Function
  sInput = sInput + vbTab + "float4 vTangent:TANGENT;" + vbCrLf
  sOutput = sOutput + vbTab + "float4 vTangent:" + m_sOutputSemantics(i) + ";" + vbCrLf
 End If
 If bShadowMap Then
  i = pFindUnusedInput(bInputUsed, 16, 31)
  If i < 0 Then Exit Function
  sOutput = sOutput + vbTab + "float4 vShadow:" + m_sOutputSemantics(i) + ";" + vbCrLf
 End If
 '///new:hardware instancing
 Select Case nHWInstancingMode
 Case 1
  sInput = sInput + vbTab + "float4 vHWI_Translation:POSITION4;" + vbCrLf
 Case 15
  sInput = sInput + vbTab + "row_major float4x4 vHWI_World:POSITION4;" + vbCrLf
 End Select
 '///
 sInput = sInput + "};" + vbCrLf + vbCrLf
 sOutput = sOutput + "};" + vbCrLf + vbCrLf
 '///other parameters
 sParam = sParam + "float4x4 matWorld,matWorldInv,matTransform;" + vbCrLf + vbCrLf
 If bShadowMap Then _
 sParam = sParam + "float4x4 matShadow;" + vbCrLf + vbCrLf
 If bFogEnabled Then _
 sParam = sParam + "float4 zData;" + vbCrLf + vbCrLf
 '///TODO:custom light
 'test only
 sParam = sParam + "float4 lightDir,lightPos,viewPos;" + vbCrLf + "int lightType;" + vbCrLf + vbCrLf
 '///texture
 mm = 0
 sTexture = sTexture + vbCrLf
 j = 1
 k = 0
 For i = 0 To 15
  If bTextureUsed(i) Then
   k = k Or j
   sTexture = sTexture + "texture tex" + CStr(i) + ";" + vbCrLf + "sampler samp" + CStr(i) + "=sampler_state{" _
   + vbCrLf + vbTab + "Texture=<tex" + CStr(i) + ">;" + vbCrLf + vbTab + sTextureArgument(i) + vbCrLf + "};" + vbCrLf + vbCrLf
   mm = mm + 1
  End If
  j = j + j
 Next i
 t.nTextureUsedFlag = k
 sParam = sParam + "// texture used:" + CStr(mm) + vbCrLf + vbCrLf + sTexture
 '///
 '////////////////////////////////generate vertex shader
 sParam = sParam + "void vs_func(VS_INPUT cin,out VS_OUTPUT cout,out float4 vPos:POSITION){" + vbCrLf
 For i = 0 To 31
  If bInputUsed(i) = 45 Then
   sParam = sParam + vbTab + "cout." + m_sOutputName(i) + "=cin." + m_sOutputName(i) + ";" + vbCrLf
  End If
 Next i
 sParam = sParam + vbCrLf
 '///new:hardware instancing
 s1 = "matWorldInv"
 Select Case nHWInstancingMode
 Case 1
  sParam = sParam + vbTab + "cin.vPos+=float4(cin.vHWI_Translation.xyz,0);" + vbCrLf
 Case 15 'assume vHWI_World is orthogonal TODO:
  sParam = sParam + vbTab + "cin.vPos=mul(cin.vPos,cin.vHWI_World);" + vbCrLf
  sParam = sParam + vbTab + "float4x4 matNewInv=mul(float4x4(cin.vHWI_World[0],cin.vHWI_World[1],cin.vHWI_World[2],float4(0,0,0,0)),matWorldInv);" + vbCrLf
  s1 = "matNewInv"
 End Select
 '///
 sParam = sParam + vbTab + "vPos=mul(cin.vPos,matTransform);" + vbCrLf
 If bFogEnabled Then
  sParam = sParam + vbTab + "cout.vPos=float4(mul(cin.vPos,matWorld).xyz,vPos.z);" + vbCrLf
  sParam = sParam + vbTab + "cout.vNormal=float4(mul(cin.vNormal," + s1 + ").xyz,vPos.w);" + vbCrLf
 Else
  sParam = sParam + vbTab + "cout.vPos=mul(cin.vPos,matWorld);" + vbCrLf
  sParam = sParam + vbTab + "cout.vNormal=mul(cin.vNormal," + s1 + ");" + vbCrLf
 End If
 If bMoreNormals Then
  sParam = sParam + vbTab + "cout.vBinormal=mul(cin.vBinormal," + s1 + ");" + vbCrLf
  sParam = sParam + vbTab + "cout.vTangent=mul(cin.vTangent," + s1 + ");" + vbCrLf
 End If
 If bShadowMap Then
  sParam = sParam + vbTab + "cout.vShadow=mul(cin.vPos,matShadow);" + vbCrLf
 End If
 sParam = sParam + "}" + vbCrLf + vbCrLf
 '////////////////////////////////generate pixel shader
 sParam = sParam + "float4 ps_func(VS_OUTPUT cin):COLOR0{" + vbCrLf
 sParam = sParam + vbTab + "float3 vView=normalize(viewPos.xyz-cin.vPos.xyz);" + vbCrLf + vbCrLf
 '///parallax mapping
 'only working when type is texture
 nType = t.tArguments(IDA_ParallaxMap).nType
 If nType >= &H1000000 And nType < &H2000000 Then
  sParam = sParam + vbTab + "float2 parallaxBase=float2(dot(vView,cin.vBinormal),dot(vView,cin.vTangent));" + vbCrLf
  '///
  s1 = "cin.t" + CStr((nType And &HF0000) \ &H10000) + "."
  j = nType And &HFF&
  For i = 1 To 2
   s1 = s1 + Mid("xyzw", 1 + (j And 3&), 1)
   j = j \ 4&
  Next i
  '///
  s2 = "parallaxBase*(" + pGenerateArgumentCode(t, IDA_ParallaxMap, 1, ChrW(1)) + "+" + _
  pGenerateArgumentCode(t, IDA_ParallaxMapOffset, 1) + ")*" + pGenerateArgumentCode(t, IDA_ParallaxMapScale, 1)
  '///
  sParam = sParam + vbTab + "float2 parallaxOffset=" + Replace(s2, ChrW(1), "") + ";" + vbCrLf
  s2 = vbTab + "parallaxOffset=(parallaxOffset+" + Replace(s2, ChrW(1), "+parallaxOffset") + ")*0.5f;" + vbCrLf
  sParam = sParam + s2 + s2 + vbTab + s1 + "+=parallaxOffset;" + vbCrLf + vbCrLf
  '///
 End If
 sParam = sParam + vbTab + "float lightAmount=1.0f;" + vbCrLf + vbCrLf
 If bShadowMap Then
  'TODO:shadow map
 End If
 If t.tArguments(IDA_NormalMap).nType Then
  'normal mapping
  sParam = sParam + vbTab + "float3 vNormal=" + pGenerateArgumentCode(t, IDA_NormalMap, 3) + "*2.0f-1.0f;" + vbCrLf
  If t.tArguments(IDA_NormalMapScale).nType Then
'   'completely wrong code
'   sParam = sParam + vbTab + "float3 vNormal=(" + pGenerateArgumentCode(t, IDA_NormalMap, 3) + "-0.5f)*" + _
'   pGenerateArgumentCode(t, IDA_NormalMapScale, 1) + ";" + vbCrLf
   sParam = sParam + vbTab + "vNormal.xy*=" + pGenerateArgumentCode(t, IDA_NormalMapScale, 1) + ";" + vbCrLf
   '===fixed again (r152)
   'sParam = sParam + vbTab + "vNormal=normalize(vNormal);" + vbCrLf
  End If
  '===fixed again (r152)
  sParam = sParam + vbTab + "vNormal=normalize(vNormal.x*cin.vBinormal.xyz+vNormal.y*cin.vTangent.xyz+vNormal.z*cin.vNormal.xyz);" + vbCrLf + vbCrLf
 Else
  '===fixed again (r152)
  sParam = sParam + vbTab + "float3 vNormal=normalize(cin.vNormal.xyz);" + vbCrLf + vbCrLf
 End If
 '///TODO:custom light
 sParam = sParam + vbTab + "float3 vLight;" + vbCrLf + vbTab + "if(lightType==1) vLight=normalize(lightPos.xyz-cin.vPos.xyz);" + vbCrLf + vbTab + _
 "else vLight=lightDir.xyz;" + vbCrLf + vbCrLf
 '///diffuse
 Select Case t.nDiffuseAlgorithm
 Case 0
  sParam = sParam + vbTab + "float n_dot_l=dot(vNormal,vLight);" + vbCrLf + vbCrLf
 Case 1 'Oren-Nayar
  sParam = sParam + vbTab + "float n_dot_l=saturate(dot(vNormal,vLight));" + vbCrLf
  sParam = sParam + vbTab + "float n_dot_v=saturate(dot(vNormal,vView));" + vbCrLf
  '///
  nType = t.tArguments(IDA_OrenNayarRoughness).nType
  Select Case nType
  Case 0, 1, 2
   sParam = sParam + vbTab + "n_dot_l*=dot(" + pGenerateArgumentCode(t, IDA_OrenNayarRoughness, 2)
  Case Else
   sParam = sParam + vbTab + "float OrenNayarRoughness=" + pGenerateArgumentCode(t, IDA_OrenNayarRoughness, 1) + ";" + vbCrLf
   sParam = sParam + vbTab + "OrenNayarRoughness*=OrenNayarRoughness;" + vbCrLf
   sParam = sParam + vbTab + "n_dot_l*=dot(float2(1-0.5*OrenNayarRoughness/(OrenNayarRoughness+0.33),0.45*OrenNayarRoughness/(OrenNayarRoughness+0.09))"
  End Select
  sParam = sParam + ",float2(1," + _
  "saturate(dot(normalize(vLight-n_dot_l*vNormal),normalize(vView-n_dot_l*vNormal)))" + _
  "*sqrt(1.0f-n_dot_l*n_dot_l)*sqrt(1.0f-n_dot_v*n_dot_v)/max(n_dot_l,n_dot_v)));" + vbCrLf + vbCrLf
 Case Else
  Exit Function
 End Select
 '///specular
 Select Case t.nSpecularAlgorithm
 Case 0
  sParam = sParam + vbTab + "float fSpecular=dot(vNormal,normalize(vLight+vView));" + vbCrLf + vbCrLf
 Case 1
  sParam = sParam + vbTab + "float fSpecular=dot(vView,-reflect(vLight,vNormal));" + vbCrLf + vbCrLf
 Case Else
  Exit Function
 End Select
 '///
 If t.tArguments(IDA_BaseColor).nType Then
  sParam = sParam + vbTab + "float4 baseColor=" + pGenerateArgumentCode(t, IDA_BaseColor, 4) + ";" + vbCrLf
 End If
 sParam = sParam + vbTab + "float4 ambientColor=" + pGenerateArgumentCode(t, IDA_Ambient, 4) + ";" + vbCrLf
 sParam = sParam + vbTab + "float4 diffuseColor=" + pGenerateArgumentCode(t, IDA_Diffuse, 4) + ";" + vbCrLf
 sParam = sParam + vbTab + "float4 specularColor=" + pGenerateArgumentCode(t, IDA_Specular, 4) + ";" + vbCrLf
 sParam = sParam + vbTab + "float4 emissiveColor=" + pGenerateArgumentCode(t, IDA_Emissive, 4) + ";" + vbCrLf
 sParam = sParam + vbCrLf
 '///
 sParam = sParam + vbTab + "float4 lightResult=lightAmount*lit(n_dot_l,fSpecular," + pGenerateArgumentCode(t, IDA_SpecularHardness, 1) + ");" + vbCrLf
 If t.tArguments(IDA_BaseColor).nType Then
  sParam = sParam + vbTab + _
  "lightResult=baseColor*(ambientColor+lightResult.y*diffuseColor)+lightResult.z*specularColor+emissiveColor;" + vbCrLf + vbCrLf
 Else
  sParam = sParam + vbTab + _
  "lightResult=ambientColor+emissiveColor+lightResult.y*diffuseColor+lightResult.z*specularColor;" + vbCrLf + vbCrLf
 End If
 '///
 If bFogEnabled Then
  sParam = sParam + vbTab + "return float4(lightResult.xyz,1.0f/(zData.x+zData.y*cin.vPos.w/cin.vNormal.w));" + vbCrLf + "}" + vbCrLf + vbCrLf
 Else
  sParam = sParam + vbTab + "return float4(lightResult.xyz,1.0f);" + vbCrLf + "}" + vbCrLf + vbCrLf
 End If
 '////////////////////////////////generate effect
 sParam = sParam + "technique test{" + vbCrLf + vbTab + "pass{" + vbCrLf + vbTab + vbTab + "VertexShader=compile vs_3_0 vs_func();" + _
 vbCrLf + vbTab + vbTab + "PixelShader=compile ps_3_0 ps_func();" + vbCrLf
 If t.sEffectStates <> vbNullString Then _
 sParam = sParam + vbTab + vbTab + t.sEffectStates + vbCrLf
 sParam = sParam + vbTab + "}" + vbCrLf + "}" + vbCrLf
 '////////////////////////////////over
 t.sShaderSourceCode = sInput + sOutput + sParam
 pGenerateHLSLCodeFromFakeDXEffect = True
 '///
Case Else
 'TODO:unsupported
End Select
End Function

Friend Function AddAppearanceFromNode(ByVal objNode As clsTreeStorageNode, ByVal objMeshMgr As clsMeshManager) As Long
Dim i As Long, j As Long, k As Long
Dim nEffectIndex As Long, nMeshIndex As Long
Dim s As String
Dim obj As clsTreeStorageNode
Dim mat As D3DMATRIX
'///
mat.m11 = 1
mat.m22 = 1
mat.m33 = 1
mat.m44 = 1
'///
s = objNode.GetNameAsString
Select Case s
Case "appearance"
Case Else
 Debug.Assert False
 Exit Function
End Select
'///
m_nApprCount = m_nApprCount + 1
If m_nApprCount > m_nApprMax Then
 m_nApprMax = m_nApprMax + 16&
 ReDim Preserve m_tAppr(1 To m_nApprMax)
End If
'///
For i = 1 To objNode.SubNodeCount
 Select Case objNode.SubNodeType(i)
 Case 0
  'TODO:
 Case 1
  Set obj = objNode.SubNodeObject(i)
  s = obj.GetNameAsString
  Select Case s
  Case "shader"
   nEffectIndex = AddEffectFromNode(obj)
   Debug.Assert nEffectIndex > 0
   If nEffectIndex > 0 Then
    For j = 1 To obj.SubNodeCount
     If obj.SubNodeType(j) = 1 Then
      nMeshIndex = objMeshMgr.AddMeshFromNode(obj.SubNodeObject(j))
      Debug.Assert nMeshIndex > 0
      If nMeshIndex > 0 Then
       k = m_tAppr(m_nApprCount).nCount + 1
       m_tAppr(m_nApprCount).nCount = k
       ReDim Preserve m_tAppr(m_nApprCount).tData(1 To k)
       m_tAppr(m_nApprCount).tData(k).nEffectIndex = nEffectIndex
       m_tAppr(m_nApprCount).tData(k).nMeshIndex = nMeshIndex
       m_tAppr(m_nApprCount).tData(k).matWorld = mat 'TODO:custom hierarchical transform
      End If
     End If
    Next j
   End If
'  Case "mesh"
'   'TODO:
'   Debug.Assert False
  Case Else
   'TODO:
   Debug.Assert False
  End Select
 End Select
Next i
'///
AddAppearanceFromNode = m_nApprCount
End Function

Friend Function AddEffectFromNode(ByVal objNode As clsTreeStorageNode) As Long
'On Error Resume Next
Dim t As typeFakeDXEffect
Dim i As Long, j As Long, k As Long, m As Long
Dim s As String
'///
'?? TODO
t.nFlags = 1
'///
s = objNode.GetNameAsString
Select Case s
Case "shaderTemplate"
 t.nTemplateIndex = -1
Case "shader"
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
   s = objNode.GetSubNodeValueAsString(i)
   If t.nTemplateIndex = -1 Then
    t.sTemplateName = s
   Else
    For j = 1 To m_nEffectCount
     If m_tEffect(j).nTemplateIndex = -1 Then
      If m_tEffect(j).sTemplateName = s Then
       t.nTemplateIndex = j
       Exit For
      End If
     End If
    Next j
    If j > m_nEffectCount Then
     Debug.Assert False
     Exit Function
    End If
   End If
  Case "shaderProgram"
   s = objNode.GetSubNodeValueAsString(i)
   Select Case s
   Case vbNullString, "none", "default"
    t.sShaderProgram = vbNullString
   Case "standard"
    t.sShaderProgram = s
   Case Else
    Debug.Assert False
    Exit Function
   End Select
  Case "hardwareInstancing"
   s = objNode.GetSubNodeValueAsString(i)
   Select Case s
   Case vbNullString, "none", "default", "disable", "disabled"
    j = 0
   Case "translation", "translationOnly"
    j = 1
   Case "worldMatrix", "transformMatrix", "matrix"
    j = 15
   Case Else
    Debug.Assert False
    Exit Function
   End Select
   t.nFlags = (t.nFlags And &HFFFFFF0F) Or (j * 16&)
  Case "diffuseAlgorithm"
   s = objNode.GetSubNodeValueAsString(i)
   Select Case s
   Case vbNullString, "default", "Lambertian"
    t.nDiffuseAlgorithm = 0
   Case "Oren-Nayar"
    t.nDiffuseAlgorithm = 1
   Case Else
    Debug.Assert False
    Exit Function
   End Select
  Case "specularAlgorithm"
   s = objNode.GetSubNodeValueAsString(i)
   Select Case s
   Case vbNullString, "default", "Blinn-Phong"
    t.nSpecularAlgorithm = 0
   Case "Phong"
    t.nSpecularAlgorithm = 1
   Case Else
    Debug.Assert False
    Exit Function
   End Select
  Case "effectStates"
   s = Trim(objNode.GetSubNodeValueAsString(i))
   If s <> vbNullString Then
    If Right(s, 1) <> ";" Then s = s + ";"
    t.sEffectStates = s
   End If
  Case Else
   For j = 0 To 63
    If s = m_sParamName(j) Then
     If Not pParseArgumentFromString(t, objNode.GetSubNodeValueAsString(i), j) Then Exit Function
     Exit For
    End If
   Next j
   If j > 63 Then
    Debug.Assert False
    Exit Function
   End If
  End Select
 End If
Next i
'///
If Not pCombineFakeDXEffectFromTemplate(t) Then Exit Function
'///check if already exists
j = pFindExistingFakeDXEffect(t, i)
If j >= 2 And t.nTemplateIndex >= 0 Then
 AddEffectFromNode = i
 Exit Function
End If
'///compile effect
If j = 1 Then
 Set t.objEffect = m_tEffect(i).objEffect
 t.nReferenceIndex = i
ElseIf t.sShaderProgram <> vbNullString Then
 If Not pGenerateHLSLCodeFromFakeDXEffect(t, True) Then
  Debug.Assert False
  Exit Function
 End If
 'Debug.Print t.sShaderSourceCode
 If Not CreateEffect(t.sShaderSourceCode, t.objEffect) Then
  Debug.Assert False
  Exit Function
 End If
End If
'///copy parameters to array
For i = 0 To 63
 With t.tArguments(i)
  j = .nParamSize * 4&
  If j > 0 Then
   m = LenB(.sOptionalData)
   If m > j Then m = j
   If m > 0 Then _
   CopyMemory ByVal VarPtr(t.fParams(0)) + .nParamOffset * 4&, ByVal StrPtr(.sOptionalData), m
  Else
   '///load texture from file (if any)
   j = .nType
   If j >= &H1000000 And j < &H2000000 Then
    j = (j And &HF00000) \ &H100000
    If t.objTextures(j) Is Nothing Then
     If Len(.sOptionalData) > 0 Then
      'TODO:load file options
      k = objTextMgr.AddTextureFromFile(.sOptionalData, objFileMgr)
      If k > 0 Then Set t.objTextures(j) = objTextMgr.Texture(k)
     End If
    End If
   End If
  End If
 End With
Next i
'///add new effect
m = m_nEffectCount + 1
If m > m_nEffectMax Then
 m_nEffectMax = m_nEffectMax + 16&
 ReDim Preserve m_tEffect(1 To m_nEffectMax)
End If
m_tEffect(m) = t
m_nEffectCount = m
'///over
AddEffectFromNode = m
End Function

Friend Function LoadEffectsFromFile(ByVal FileName As String, ByVal objSerializer As ITreeSerializer) As Long
Dim objNode As New clsTreeStorageNode
If Not objSerializer.LoadNodeFromFile(FileName, objNode) Then Exit Function
LoadEffectsFromFile = LoadEffectsFromSubNodes(objNode)
End Function

Friend Function LoadEffectsFromMemory(ByVal lp As Long, ByVal nLength As Long, ByVal objSerializer As ITreeSerializer) As Long
Dim objNode As New clsTreeStorageNode
If Not objSerializer.ReadNode(lp, nLength, objNode) Then Exit Function
LoadEffectsFromMemory = LoadEffectsFromSubNodes(objNode)
End Function

Friend Function LoadEffectsFromSubNodes(ByVal objNode As clsTreeStorageNode) As Long
Dim i As Long, m As Long
Dim obj As clsTreeStorageNode
For i = 1 To objNode.SubNodeCount
 Set obj = objNode.SubNodeObject(i)
 If Not obj Is Nothing Then
  If AddEffectFromNode(obj) > 0 Then m = m + 1
 End If
Next i
LoadEffectsFromSubNodes = m
End Function

Friend Property Get EffectCount() As Long
EffectCount = m_nEffectCount
End Property

Friend Property Get Effect(ByVal nIndex As Long) As D3DXEffect
If nIndex > 0 And nIndex <= m_nEffectCount Then Set Effect = m_tEffect(nIndex).objEffect
End Property

Private Sub Class_Terminate()
Destroy
End Sub

Friend Sub OnLostDevice()
On Error Resume Next
Dim i As Long ', j As Long
For i = 1 To m_nEffectCount
 m_tEffect(i).objEffect.OnLostDevice
 'now no textures are default pool object, so we don't need this
' Erase m_tEffect(i).objTextures
'' 'TODO:only erase default pool object
'' For j = 0 To 15
''  If Not m_tEffect(i).objTextures(j) Is Nothing Then
''   m_tEffect(i).objTextures(j).GetType
''  End If
'' Next j
Next i
'TODO:other
End Sub

Friend Sub OnResetDevice()
On Error Resume Next
Dim i As Long
For i = 1 To m_nEffectCount
 m_tEffect(i).objEffect.OnResetDevice
Next i
'TODO:other
End Sub

Friend Sub SetupEffect(ByVal nIndex As Long, Optional ByVal bSetupParameters As Boolean, Optional ByVal bSetupLight As Boolean, Optional ByVal bSetupTransform As Boolean, Optional ByVal bSetupTexture As Boolean, Optional ByVal bCommitChanges As Boolean, Optional ByVal bBeginEffect As Boolean)
Dim obj As D3DXEffect
Dim i As Long, j As Long, k As Long
If nIndex > 0 And nIndex <= m_nEffectCount Then
 Set obj = m_tEffect(nIndex).objEffect
 If obj Is Nothing Then
  'TODO:no HLSL
 Else
  '///
  If bSetupParameters Then
   i = m_tEffect(nIndex).nParamUsed
   If i > 0 Then _
   obj.SetVectorArray StrPtr(StrConv("_fParam", vbFromUnicode)), m_tEffect(nIndex).fParams(0), i
  End If
  If bSetupLight Then
   objRenderTest.SetupLight obj
  End If
  If bSetupTransform Then
   objRenderTest.SetupTransform obj
   If m_tEffect(nIndex).nFlags And 1& Then objRenderTest.SetupZData obj
  End If
  If bSetupTexture Then
   j = 1
   k = m_tEffect(nIndex).nTextureUsedFlag
   For i = 0 To 15
    If j And k Then
     obj.SetTexture StrPtr(StrConv("tex" + CStr(i), vbFromUnicode)), m_tEffect(nIndex).objTextures(i)
    End If
    j = j + j
   Next i
  End If
  If bCommitChanges Then obj.CommitChanges
  If bBeginEffect Then
   m_nLastIndex = nIndex
   obj.SetTechnique StrPtr(StrConv("test", vbFromUnicode))
   obj.Begin 0, 0
   obj.BeginPass 0
  End If
  '///
 End If
End If
End Sub

Friend Sub BeginEffect(ByVal nIndex As Long)
Dim obj As D3DXEffect
'TODO:other
If nIndex > 0 And nIndex <= m_nEffectCount Then
 Set obj = m_tEffect(nIndex).objEffect
 If Not obj Is Nothing Then
  m_nLastIndex = nIndex
  obj.SetTechnique StrPtr(StrConv("test", vbFromUnicode))
  obj.Begin 0, 0
  obj.BeginPass 0
 End If
End If
End Sub

Friend Sub EndEffect()
Dim obj As D3DXEffect
'TODO:other
If m_nLastIndex > 0 And m_nLastIndex <= m_nEffectCount Then
 Set obj = m_tEffect(m_nLastIndex).objEffect
 If Not obj Is Nothing Then
  obj.EndPass
  obj.End
 End If
End If
m_nLastIndex = 0
End Sub

Private Function ISort2_Compare(ByVal Index1 As Long, ByVal Index2 As Long, ByVal nUserData As Long) As Long
Dim i As Long, j As Long
Dim ii As Long, jj As Long
i = m_tInst.tInstance(Index1).nEffectIndex
j = m_tInst.tInstance(Index2).nEffectIndex
ii = m_tEffect(i).nReferenceIndex
jj = m_tEffect(j).nReferenceIndex
If ii = 0 Then ii = i
If jj = 0 Then jj = j
'///
If ii < jj Then
 ISort2_Compare = -1
ElseIf ii > jj Then
 ISort2_Compare = 1
ElseIf i < j Then
 ISort2_Compare = -1
ElseIf i > j Then
 ISort2_Compare = 1
'Else
' i = m_tInst.tInstance(Index1).nMeshIndex
' j = m_tInst.tInstance(Index2).nMeshIndex
' If i < j Then ISort2_Compare = -1 _
' Else If i > j Then ISort2_Compare = 1
End If
End Function
