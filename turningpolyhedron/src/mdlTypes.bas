Attribute VB_Name = "mdlTypes"
Option Explicit

'////////mesh instance data

Public Type typeMeshInstanceData 'N bytes :(
 nType As Long
 '0=mesh
 '1-15=hardware instancing mesh, same as hardware instancing mode
 'TODO:etc.
 '///
 nEffectIndex As Long '<=0 is unused, if <0 then is &H80000000 | (next unused index)
 nMeshIndex As Long 'must >0
 '///when nType=0
 matWorld As D3DMATRIX
 '///when nType=1-15
 nCount As Long
 nInstanceVertexSize As Long
 '///
 objDeclaration As Direct3DVertexDeclaration9
 objInstanceBuffer As Direct3DVertexBuffer9
End Type

Public Type typeMeshInstanceCollection
 tInstance() As typeMeshInstanceData 'WARNING: use some dirty code so this member must be the first one
 nInstOrder() As Long '1-based
 nInstCount As Long
 nInstUnused As Long ', nInstMax As Long
 bInstDirty As Boolean
End Type

'////////mesh data

Public Type typeMeshParamData
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

Public Type typeMeshVertex_Temp
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

Public Type typeMeshEdge_Temp
 nFlags As Long
 'bit 0-1=bevel index (0-x 1-y 2-z 3-w) for vertex 0-1
 'bit 2-3=bevel index for vertex 2-3
 nVertexIndex(3) As Long
 nVertexB As Long 'optional (when nBevel=2)
 '|   F  |
 '3------2
 '(B+1) (B)
 '0------1
 '|   F  |
End Type

Public Type typeMeshFace_Temp
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

Public Type typeMeshOptionalData
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

Public Type typeMeshMgrData
 nType As Long
 '0=unused
 '1=cube
 'TODO:...
 '///
' nVertexCount As Long
' nFaceCount As Long
 FVF As D3DFVFFLAGS 'only used D3DFVF_DIFFUSE, D3DFVF_SPECULAR and D3DFVF_TEX* (&H100& to &H1F00&)
 nVertexSize As Long
 '///
 objMesh As D3DXMesh
End Type

'////////effect data

Public Type typeFakeDXEffectArgument
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
Public Type typeFakeDXEffect
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

'////////appearance data

Public Type typeAppearanceData
 nCount As Long
 tData() As typeMeshInstanceData
 'nType should always be 0 (?)
End Type

'////////object type data

Public Type typeObjectInteractionType
 sName2 As String
 '///
 nType As Long
 '---should use only 31 bits
 '0=moveable (default)
 '1=not-moveable
 '2=slippery
 '3=superSlippery
 '&H100=game-over
 '&H101=game-over:immediately
 '&H102=game-over:breakdown
 '&H103=game-over:breakdown:2
 '&H104=game-over:melting
 '&H105=game-over:melting:2
 'etc...
 '---
 '&H80000000 reserved for internal use
 '///
End Type

Public Type typeObjectType
 sName As String
 nInteractionCount As Long
 tInteraction() As typeObjectInteractionType '0 to nInteractionCount; 0="default"
End Type

'////////tile type data

Public Type typeTileEventCondition
 nType As Long
 '========
 '0=unused
 '1=pressure[n]
 '2=onGroundCount[n]
 '3=onDifferentType[b]
 '4=eventType[s]
 '5=eventIndex[n]
 '----polyhedron properties[b]
 '--&H101=discardable
 '--&H102=main
 '--&H103=fragile
 '--&H104=supportable
 '--&H105=supporter
 '--&H106=tiltable
 '--&H107=tilt-supporter
 '--&H108=spannable
 '----other polyhedron properties
 '--&H121=objectType[s] (string??)
 '========data type
 '1 [b]=boolean
 '2 [n]=number(integer or float)
 '3 [s]=string
 nCompareType As Long
 '0="=" (default)
 '1="!="
 nValue1 As Single
 nValue2 As Single
 nStringValueCount As Long
 sStringValue() As String '0-based
End Type

Public Type typeTileEventAction
 nType As Long
 '0=unused
 '1=triggerEvent
 '2=sendEvent
 '3=teleport (currently unsupported TODO:)
 '4=convertTo
 '5=move:straight
 '6=move:left
 '7=move:right
 '8=move:back
 '9=absolute-move:* (currently unsupported TODO:)
 '10=game-finished
 '11=game-finished:unconditional
 '12=checkpoint
 '&H100-x=game-over:*
 nParam As Long
 nStringParamCount As Long
 sStringParam() As String '0-based
End Type

Public Type typeTileEvent
 nEventType As Long
 '1=onEnter
 '2=onLeave
 '3=onMoveEnter
 '4=onMoveLeave
 '5=onPressKey
 '6=onCustomEvent
 '7=onTriggeredEvent
 nConditionCount As Long
 tCondition() As typeTileEventCondition '1-based
 nEventCount As Long
 tEvent() As typeTileEventAction '1-based
End Type

Public Type typeTileType
 nIndex As Long '???
 'if actual index<m_nTileTypeCount_Max then it should be actual index
 'if =0 and actual index<m_nTileTypeCount_Max then it's unused
 'obsolete ==> if <0 then it's dynamic-mapped index (&H80000000 or actual index) <=== obsolete
 sID As String
 sName As String
 sDesc As String
 '///
 nFlags As Long
 '1=invisibleAtRuntime (? TODO:)
 '2=checkpoint
 '4=elevator (currently unsupported TODO:)
 '&H100=blocked
 '  &H200=not tiltable
 '  &H400=not supportable
 nObjType As Long '0 to nInteractionCount; 0="default"
 nReserved3 As Long 'block height ??? (currently unused and unsupported)
 nReserved4 As Long
 '///
 'TODO:multiple appearances
 nApprIndex As Long
 '///events
 nEventCount As Long
 tEvent() As typeTileEvent '1-based
End Type

'////////level data

Public Type typeMapData_Properties
 nIndex As Long '???
 sTag As String
 '///events
 nEventCount As Long
 tEvent() As typeTileEvent '1-based
End Type

Public Type typeMapData
 sID As String
 nFlags As Long
 'bit 0-3=shape
 '0=rect
 '---
 '&H10=has size
 nSize(2) As Long
 '///
 fPos(3) As D3DXVECTOR4
 fRotation As D3DXVECTOR4
 fScale As D3DXVECTOR4
 fCenter As D3DXVECTOR4
 fStep As D3DXVECTOR4
 '///
 matWorld As D3DMATRIX
 '///0 to x-1,0 to y-1,0 to z-1
 nTypeArray() As Long
 sTagArray() As String
 nPropertyArray() As Long
 '///
 nPropertyCount As Long
 tProperties() As typeMapData_Properties '1-based
 'TODO:adjacency
End Type

Public Type typeMapData_Polyhedron
 sID As String
 nShape As Long
 '/// (currently unsupported)
 '&H1=tetrahedron
 '&H2=octahedron
 '&H3=icosahedron (??)
 '&H4=triangularBipyramid (??)
 '&H5=pentagonalBipyramid (??)
 '&H6=rhomboid
 '&H7=heptahedron (??)
 '&H8=snub disphenoid (??)
 '&H9=triaugmented triangular prism (??)
 '&HA=gyroelongated square dipyramid (??)
 '&HB=truncated tetrahedron (??)
 '///
 '&H111-&HFFF=cubic x*y*z (&Hxyz)
 '///
 'TODO:etc.
 nObjType As Long
 nFlags As Long
 '&H1=discardable
 '&H2=main
 '&H4=fragile
 '&H8=supportable
 '&H10=supporter
 '&H20=tiltable
 '&H40=tilt-supporter
 '&H80=spannable
 'TODO:etc.
 sPos As String 'start pos (and start direction)
 'TODO:controller, etc.
End Type

Public Type typeLevelData
 'map data (tiles)
 nMapDataCount As Long
 tMapData() As typeMapData '1-based
 'polyhedrons
 nPolyhedronCount As Long
 tPolyhedron() As typeMapData_Polyhedron '1-based
End Type

Public Type typePolyhedronFaceLogic
 nType As Integer
 '0=rect
 'etc.
 '///
 nEdgeCount As Integer
 nSize(2) As Long
 'rect: w,h (length of edge 0, length of edge 1)
 'etc.
 '///
 nAdjacentFace(7) As Byte
 nAdjacentFaceEdge(7) As Byte
 '///
End Type

Public Type typePolyhedronLogic
 nFaceCount As Long
 tFace() As typePolyhedronFaceLogic '0-based
End Type

Public Type typePolyhedronPosition
 '///pos
 nMapDataIndex As Long
 x As Long
 y As Long
 z As Long
 '///edge 0 on ground --> edge ? on polyhedron
 nFirstEdgeIndex As Long
 '///which face is on ground
 nGroundFaceIndex As Long
 '///which edge is on ground
 nGroundEdgeIndex As Long
End Type
