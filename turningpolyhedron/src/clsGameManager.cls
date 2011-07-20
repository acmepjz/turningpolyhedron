VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsGameManager"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)

'////////object type data

Private m_tObjType() As typeObjectType
Private m_nObjTypeCount As Long, m_nObjTypeMax As Long

Private m_nObjInteraction() As Long '0 to nInteractionCount,0 to nInteractionCount; 0="default"
Private m_bObjInteractionDirty As Boolean

'////////tile type data

Private Const m_nTileTypeCount_Max As Long = 1024&

Private m_tTileType() As typeTileType
Private m_nTileTypeCount As Long 'fixed index, start with 1 (this is not count, but just max index)
Private m_nTileTypeCount2 As Long 'dynamic index, start with m_nTileTypeCount_Max+1
Private m_nTileTypeMax As Long '=UBound(m_tTileType)

'////////tile mapping data
Private m_nTileTypeMap(1 To m_nTileTypeCount_Max) As Long

'////////level data (TEST ONLY)

Private m_tLevel As typeLevelData
Private m_objPoly() As New clsPolyhedron '1-based

Private m_bRuntimeDirty As Boolean

Friend Property Get PolyhedronObject(ByVal nPolyhedronIndex As Long) As clsPolyhedron
If m_bRuntimeDirty Then Exit Property
If nPolyhedronIndex > 0 And nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then _
Set PolyhedronObject = m_objPoly(nPolyhedronIndex)
End Property

Friend Function DrawPolyhedron(Optional ByVal nPolyhedronIndex As Long) As Boolean
Dim idx As Long
'///TEST ONLY
Dim f(31) As Single
Dim d(23) As Integer
Dim i As Long, j As Long, k As Long, l As Long
Dim tmp As Long
Dim p As typePolyhedronPosition
'///
If m_bRuntimeDirty Then Exit Function
'///
d(0) = 0: d(1) = 1: d(2) = 1: d(3) = 3: d(4) = 3: d(5) = 2: d(6) = 2: d(7) = 0
d(8) = 4: d(9) = 5: d(10) = 5: d(11) = 7: d(12) = 7: d(13) = 6: d(14) = 6: d(15) = 4
d(16) = 0: d(17) = 4: d(18) = 1: d(19) = 5: d(20) = 2: d(21) = 6: d(22) = 3: d(23) = 7
f(3) = LongToSingle(&HFFFFFF)
For i = 1 To 7
 f(i * 4 + 3) = f(3)
Next i
'///
tmp = d3dd9.GetTextureStageState(0, D3DTSS_COLOROP)
d3dd9.SetTextureStageState 0, D3DTSS_COLOROP, D3DTOP_SELECTARG2
d3dd9.SetFVF D3DFVF_XYZ Or D3DFVF_DIFFUSE
'///
For idx = 1 To m_tLevel.nPolyhedronCount
 If idx = nPolyhedronIndex Or nPolyhedronIndex <= 0 Then
  '///TEST ONLY
  m_objPoly(idx).GetCurrentSize i, j, k
  p = m_objPoly(idx).Position
  If p.nMapDataIndex > 0 And p.nMapDataIndex <= m_tLevel.nMapDataCount Then
   '///
   With m_tLevel.tMapData(p.nMapDataIndex)
    For l = 0 To 7
     f(l * 4) = .fPos(0).x + _
     (p.x + i * (l And 1&)) * .fPos(1).x + _
     (p.y + j * ((l \ 2&) And 1&)) * .fPos(2).x + _
     (p.z + k * ((l \ 4&) And 1&)) * .fPos(3).x
     f(l * 4 + 1) = .fPos(0).y + _
     (p.x + i * (l And 1&)) * .fPos(1).y + _
     (p.y + j * ((l \ 2&) And 1&)) * .fPos(2).y + _
     (p.z + k * ((l \ 4&) And 1&)) * .fPos(3).y
     f(l * 4 + 2) = .fPos(0).z + _
     (p.x + i * (l And 1&)) * .fPos(1).z + _
     (p.y + j * ((l \ 2&) And 1&)) * .fPos(2).z + _
     (p.z + k * ((l \ 4&) And 1&)) * .fPos(3).z
    Next l
   End With
   '///
   d3dd9.DrawIndexedPrimitiveUP D3DPT_LINELIST, 0, 8, 12, d(0), D3DFMT_INDEX16, f(0), 16&
  End If
  '///
  'TODO:
 End If
Next idx
'///
d3dd9.SetTextureStageState 0, D3DTSS_COLOROP, tmp
'///
DrawPolyhedron = True
End Function

Friend Function CreateLevelRuntimeData() As Boolean
Dim i As Long
'///
ClearLevelRuntimeData
'///
If m_tLevel.nPolyhedronCount > 0 Then
 ReDim m_objPoly(1 To m_tLevel.nPolyhedronCount)
 For i = 1 To m_tLevel.nPolyhedronCount
  If Not m_objPoly(i).CreateIndirect(m_tLevel, i) Then Exit Function
 Next i
End If
'///
m_bRuntimeDirty = False
CreateLevelRuntimeData = True
End Function

Friend Sub ClearLevelRuntimeData()
Erase m_objPoly
'///
m_bRuntimeDirty = True
End Sub

Friend Sub ClearLevelData()
Dim t As typeLevelData
Dim i As Long
m_tLevel = t
'reset dynamic-mapped tile index
Erase m_nTileTypeMap
'reset runtime
ClearLevelRuntimeData
'///
m_bRuntimeDirty = False
End Sub

Friend Sub ClearTileMapData()
Erase m_nTileTypeMap
End Sub

Friend Property Get TileMapData(ByVal nIndex As Long) As Long
TileMapData = m_nTileTypeMap(nIndex)
End Property

Friend Property Let TileMapData(ByVal nIndex As Long, ByVal n As Long)
m_nTileTypeMap(nIndex) = n
End Property

Friend Function AddLevelDataFromNode(ByVal objNode As clsTreeStorageNode) As Boolean
AddLevelDataFromNode = AddLevelDataFromNodeEx(objNode, m_tLevel)
m_bRuntimeDirty = True
End Function

Friend Function ParseMapTypeArrayFromNode(ByVal objNode As clsTreeStorageNode, ByRef tMap As typeMapData) As Boolean
Dim s As String
Dim b As Boolean
Dim d() As Integer, lp As Long, lps As Long, m As Long
Dim c As Long
Dim i As Long, j As Long, k As Long
'///
Dim nIndex As Long
Dim sID As String
Dim nNewIndex As Long
Dim nPropertyIndex As Long
Dim sTag As String
Dim nCount As Long
'///
s = Replace(Replace(Replace(Replace(objNode.GetValueAsString, _
vbCr, ""), vbLf, ""), vbTab, ""), " ", "")
m = Len(s)
If m > 0 Then
 ReDim d(m - 1)
 CopyMemory d(0), ByVal StrPtr(s), m * 2&
 '///format: [<index>|<id>[@<new_index>]]["["<property_index>|<tag>"]"]["*"<count>]
 Do
  nIndex = 0
  sID = ""
  nNewIndex = 0
  nPropertyIndex = 0
  sTag = ""
  nCount = 1
  '///get [<index>|<id>]
  lps = lp
  b = True
  Do While lp < m
   c = d(lp)
   Select Case c
   Case 44, 59, 124, 64, 91, 42
    Exit Do
   End Select
   b = b And ((c >= &H30& And c <= &H39&) Or c = 45)
   lp = lp + 1
  Loop
  If lp > lps Then
   sID = Space(lp - lps)
   CopyMemory ByVal StrPtr(sID), d(lps), (lp - lps) * 2&
   If b Then
    nIndex = Val(sID)
    sID = ""
   End If
  End If
  '///get [@<new_index>]
  If c = 64 Then
   lp = lp + 1
   lps = lp
   Do While lp < m
    c = d(lp)
    Select Case c
    Case 44, 59, 124, 91, 42
     Exit Do
    End Select
    lp = lp + 1
   Loop
   If lp > lps Then
    s = Space(lp - lps)
    CopyMemory ByVal StrPtr(s), d(lps), (lp - lps) * 2&
    nNewIndex = Val(s)
   End If
  End If
  '///get ["["<property_index>|<tag>"]"]
  If c = 91 Then
   lp = lp + 1
   lps = lp
   b = True
   Do While lp < m
    c = d(lp)
    If c = 93 Then Exit Do
    b = b And (c >= &H30& And c <= &H39&)
    lp = lp + 1
   Loop
   If lp > lps Then
    sTag = Space(lp - lps)
    CopyMemory ByVal StrPtr(sTag), d(lps), (lp - lps) * 2&
    If b Then
     nPropertyIndex = Val(sTag)
     If nPropertyIndex > 0 Then sTag = "" Else nPropertyIndex = 0
    End If
   End If
   lp = lp + 1
   If lp < m Then c = d(lp)
  End If
  '///get ["*"<count>]
  If c = 42 Then
   lp = lp + 1
   lps = lp
   Do While lp < m
    c = d(lp)
    Select Case c
    Case 44, 59, 124
     Exit Do
    End Select
    lp = lp + 1
   Loop
   If lp > lps Then
    s = Space(lp - lps)
    CopyMemory ByVal StrPtr(s), d(lps), (lp - lps) * 2&
    nCount = Val(s)
    If nCount <= 0 Then 'invalid count
     Debug.Assert False
     Exit Function
    End If
   End If
  End If
  '///
  If nIndex > m_nTileTypeCount_Max Then 'out of range?
   For lps = m_nTileTypeCount_Max + 1 To m_nTileTypeCount_Max + m_nTileTypeCount2
    If m_tTileType(lps).nIndex = nIndex Then
     nIndex = lps
     Exit For
    End If
   Next lps
  ElseIf nIndex > 0 Then
   If nIndex <> m_tTileType(nIndex).nIndex Then 'invalid index
    Debug.Assert False
    Exit Function
   End If
  ElseIf nIndex < 0 And nIndex >= -m_nTileTypeCount_Max Then 'use dynamic mapping index?
   nIndex = m_nTileTypeMap(-nIndex)
   If nIndex <= 0 Then 'invalid index
    Debug.Assert False
    Exit Function
   End If
  End If
  'find tile named with sID? TODO:use a collection to look up
  If sID <> "" Then
   For lps = 1 To m_nTileTypeCount
    If m_tTileType(lps).nIndex > 0 Then
     If m_tTileType(lps).sID = sID Then
      nIndex = lps
      Exit For
     End If
    End If
   Next lps
   If nIndex = 0 Then
    For lps = m_nTileTypeCount_Max + 1 To m_nTileTypeCount_Max + m_nTileTypeCount2
     If m_tTileType(lps).sID = sID Then
      nIndex = lps
      Exit For
     End If
    Next lps
   End If
   If nIndex = 0 Then 'not found
    Debug.Assert False
    Exit Function
   End If
  End If
  'create dynamic mapping index?
  If nNewIndex < 0 And nNewIndex >= -m_nTileTypeCount_Max Then
   m_nTileTypeMap(-nNewIndex) = nIndex
  End If
  '///put data
  For lps = 1 To nCount
   tMap.nTypeArray(i, j, k) = nIndex
   tMap.sTagArray(i, j, k) = sTag
   tMap.nPropertyArray(i, j, k) = nPropertyIndex
   'next pos
   If lps < nCount Then
    i = i + 1
    If i >= tMap.nSize(0) Then
     i = 0
     j = j + 1
     If j >= tMap.nSize(1) Then
      j = 0
      k = k + 1
      If k >= tMap.nSize(2) Then Exit Do
     End If
    End If
   End If
  Next lps
  '///
  If lp >= m Then c = 44
  Select Case c
  Case 44 '[","]
   'next pos
   i = i + 1
   If i >= tMap.nSize(0) Then
    i = 0
    j = j + 1
    If j >= tMap.nSize(1) Then
     j = 0
     k = k + 1
     If k >= tMap.nSize(2) Then Exit Do
    End If
   End If
  Case 59 '[";"]
   'next row
   i = 0
   j = j + 1
   If j >= tMap.nSize(1) Then
    j = 0
    k = k + 1
    If k >= tMap.nSize(2) Then Exit Do
   End If
  Case 124 '["|"]
   'next plane
   i = 0
   j = 0
   k = k + 1
   If k >= tMap.nSize(2) Then Exit Do
  Case Else 'invalid character
   Debug.Assert False
   Exit Function
  End Select
  '///over
  lp = lp + 1
 Loop While lp < m
 '///
End If
'///debug
'For j = 0 To tMap.nSize(1) - 1
' For i = 0 To tMap.nSize(0) - 1
'  Debug.Print tMap.nTypeArray(i, j, 0);
' Next i
' Debug.Print
'Next j
'///
ParseMapTypeArrayFromNode = True
End Function

Friend Function ParseMapDataFromNode(ByVal objNode As clsTreeStorageNode, ByRef tLevel As typeLevelData, ByVal nIndex As Long) As Boolean
Dim i As Long, j As Long, k As Long, m As Long
Dim v As Variant
Dim s As String
Dim nFlags As Long
Dim obj As clsTreeStorageNode
Dim obj1 As clsTreeStorageNode
'///
tLevel.tMapData(nIndex).fScale.x = 1
tLevel.tMapData(nIndex).fScale.y = 1
tLevel.tMapData(nIndex).fScale.z = 1
tLevel.tMapData(nIndex).fStep.x = 1
tLevel.tMapData(nIndex).fStep.y = 1
tLevel.tMapData(nIndex).fStep.z = 1
tLevel.tMapData(nIndex).fPos(1).x = 1
tLevel.tMapData(nIndex).fPos(2).y = 1
tLevel.tMapData(nIndex).fPos(3).z = 1
'///
nFlags = tLevel.tMapData(nIndex).nFlags
ReDim tLevel.tMapData(nIndex).nTypeArray(0, 0, 0)
ReDim tLevel.tMapData(nIndex).sTagArray(0, 0, 0)
ReDim tLevel.tMapData(nIndex).nPropertyArray(0, 0, 0)
'///
For i = 1 To objNode.SubNodeCount
 If objNode.SubNodeType(i) = 0 Then
  s = objNode.GetSubNodeNameAsString(i)
  Select Case s
  Case "id"
   'TODO:check duplicated ID
   tLevel.tMapData(nIndex).sID = objNode.GetSubNodeValueAsString(i)
  Case "shape"
   s = objNode.GetSubNodeValueAsString(i)
   Select Case s
   Case "rect"
    j = 0
   Case Else 'currently unsupported TODO:
    Debug.Assert False
    Exit Function
   End Select
   nFlags = (nFlags And &HFFFFFFF0) Or j
  Case "size"
   nFlags = nFlags Or &H10&
   v = Split(Trim(objNode.GetSubNodeValueAsString(i)), ",")
   m = UBound(v)
   If m >= 0 Then
    For j = 0 To m
     If j > 2 Then Exit For
     k = Val(v(j))
     If k <= 0 Then
      nFlags = nFlags And Not &H10&
      Exit For
     End If
     tLevel.tMapData(nIndex).nSize(j) = k
    Next j
    For j = m + 1 To 2
     tLevel.tMapData(nIndex).nSize(j) = 1
    Next j
   Else
    nFlags = nFlags And Not &H10&
   End If
   If nFlags And &H10& Then
    j = tLevel.tMapData(nIndex).nSize(0) - 1
    k = tLevel.tMapData(nIndex).nSize(1) - 1
    m = tLevel.tMapData(nIndex).nSize(2) - 1
    ReDim tLevel.tMapData(nIndex).nTypeArray(j, k, m)
    ReDim tLevel.tMapData(nIndex).sTagArray(j, k, m)
    ReDim tLevel.tMapData(nIndex).nPropertyArray(j, k, m)
   Else
    tLevel.tMapData(nIndex).nSize(0) = 1
    tLevel.tMapData(nIndex).nSize(1) = 1
    tLevel.tMapData(nIndex).nSize(2) = 1
   End If
  Case "p", "p1", "p2", "p3"
   If Not FakeDXUtilReadVec4(objNode.GetSubNodeValueAsString(i), tLevel.tMapData(nIndex).fPos(Val(Mid(s, 2)))) Then Exit Function
  Case "r"
   If Not FakeDXUtilReadVec4(objNode.GetSubNodeValueAsString(i), tLevel.tMapData(nIndex).fRotation) Then Exit Function
  Case "s"
   If Not FakeDXUtilReadVec4(objNode.GetSubNodeValueAsString(i), tLevel.tMapData(nIndex).fScale) Then Exit Function
  Case "c"
   If Not FakeDXUtilReadVec4(objNode.GetSubNodeValueAsString(i), tLevel.tMapData(nIndex).fCenter) Then Exit Function
  Case "step"
   If Not FakeDXUtilReadVec4(objNode.GetSubNodeValueAsString(i), tLevel.tMapData(nIndex).fStep) Then Exit Function
  End Select
 Else
  Set obj = objNode.SubNodeObject(i)
  Select Case obj.GetNameAsString
  Case "typeArray"
   If Not ParseMapTypeArrayFromNode(obj, tLevel.tMapData(nIndex)) Then
    Exit Function
   End If
  Case "property"
   m = Val(obj.GetSubNodeValueAsStringByName("index"))
   If m <= 0 Then 'invalid or unspecified index
    Debug.Assert False
    Exit Function
   End If
   If m > tLevel.tMapData(nIndex).nPropertyCount Then
    tLevel.tMapData(nIndex).nPropertyCount = m
    ReDim Preserve tLevel.tMapData(nIndex).tProperties(1 To m)
   End If
   tLevel.tMapData(nIndex).tProperties(m).nIndex = m
   tLevel.tMapData(nIndex).tProperties(m).sTag = obj.GetSubNodeValueAsStringByName("tag")
   '///
   For j = 1 To obj.SubNodeCount
    If obj.SubNodeType(j) = 1 Then
     Set obj1 = obj.SubNodeObject(j)
'     k = 0
'     s = obj1.GetNameAsString
'     Select Case s
'     Case Else
'      k = ParseEventType(s)
'     End Select
     k = ParseEventType(obj1.GetNameAsString)
     '///event?
     If k > 0 Then
      tLevel.tMapData(nIndex).tProperties(m).nEventCount = _
      tLevel.tMapData(nIndex).tProperties(m).nEventCount + 1
      ReDim Preserve tLevel.tMapData(nIndex).tProperties(m).tEvent(1 To _
      tLevel.tMapData(nIndex).tProperties(m).nEventCount)
      If Not ParseEventFromNode(tLevel.tMapData(nIndex).tProperties(m).tEvent( _
      tLevel.tMapData(nIndex).tProperties(m).nEventCount), obj1, k) Then
       Exit Function
      End If
     End If
    End If
   Next j
  Case "polyhedron"
   tLevel.nPolyhedronCount = tLevel.nPolyhedronCount + 1
   ReDim Preserve tLevel.tPolyhedron(1 To tLevel.nPolyhedronCount)
   If Not ParseMapPolyhedronDataFromNode(obj, tLevel.tPolyhedron(tLevel.nPolyhedronCount), CStr(nIndex)) Then Exit Function
  Case Else
   'TODO:adjacent,etc.
   Debug.Assert False
   Exit Function
  End Select
 End If
Next i
'///calc world matrix
CalcMapDataWorldMatrix tLevel.tMapData(nIndex)
'///apply map array properties (?)
If nFlags And &H10& Then
 For k = 0 To tLevel.tMapData(nIndex).nSize(2) - 1
  For j = 0 To tLevel.tMapData(nIndex).nSize(1) - 1
   For i = 0 To tLevel.tMapData(nIndex).nSize(0) - 1
    m = tLevel.tMapData(nIndex).nPropertyArray(i, j, k)
    If m > 0 And m <= tLevel.tMapData(nIndex).nPropertyCount Then
     s = tLevel.tMapData(nIndex).tProperties(m).sTag
     If s <> "" Then tLevel.tMapData(nIndex).sTagArray(i, j, k) = s
    End If
   Next i
  Next j
 Next k
End If
'///over
tLevel.tMapData(nIndex).nFlags = nFlags
ParseMapDataFromNode = True
End Function

Friend Sub CalcMapDataWorldMatrix(ByRef t2 As typeMapData)
Dim p(3) As D3DXVECTOR4
Dim mat As D3DMATRIX
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
'///multiply by step
t2.fPos(1).x = p(1).x * t2.fStep.x
t2.fPos(1).y = p(1).y * t2.fStep.x
t2.fPos(1).z = p(1).z * t2.fStep.x
t2.fPos(2).x = p(2).x * t2.fStep.y
t2.fPos(2).y = p(2).y * t2.fStep.y
t2.fPos(2).z = p(2).z * t2.fStep.y
t2.fPos(3).x = p(3).x * t2.fStep.z
t2.fPos(3).y = p(3).y * t2.fStep.z
t2.fPos(3).z = p(3).z * t2.fStep.z
'///calc center
p(0).x = t2.fPos(0).x - t2.fCenter.x * t2.fPos(1).x * t2.nSize(0) _
- t2.fCenter.y * t2.fPos(2).x * t2.nSize(1) - t2.fCenter.z * t2.fPos(3).x * t2.nSize(2)
p(0).y = t2.fPos(0).y - t2.fCenter.x * t2.fPos(1).y * t2.nSize(0) _
- t2.fCenter.y * t2.fPos(2).y * t2.nSize(1) - t2.fCenter.z * t2.fPos(3).y * t2.nSize(2)
p(0).z = t2.fPos(0).z - t2.fCenter.x * t2.fPos(1).z * t2.nSize(0) _
- t2.fCenter.y * t2.fPos(2).z * t2.nSize(1) - t2.fCenter.z * t2.fPos(3).z * t2.nSize(2)
'///over
CopyMemory t2.matWorld.m11, p(1), 48&
CopyMemory t2.matWorld.m41, p(0), 16&
t2.matWorld.m44 = 1
t2.fPos(0) = p(0)
End Sub

Friend Function pFlagsFromBooleanString(ByRef s As String, ByVal nFlags As Long, ByVal nMask As Long) As Long
Dim j As Long
If s = "true" Then j = -1 Else If Val(s) <> 0 Then j = -1
pFlagsFromBooleanString = (nFlags And Not nMask) Or (j And nMask)
End Function

Friend Function ParseMapPolyhedronDataFromNode(ByVal objNode As clsTreeStorageNode, ByRef tPoly As typeMapData_Polyhedron, Optional ByVal sBasePosition As String) As Boolean
Dim i As Long, j As Long, k As Long
Dim s As String
Dim obj As clsTreeStorageNode
Dim nFlags As Long
'///
nFlags = &HFE&
tPoly.nShape = &H112&
'///
For i = 1 To objNode.SubNodeCount
 If objNode.SubNodeType(i) = 0 Then
  s = Trim(objNode.GetSubNodeValueAsString(i))
  Select Case objNode.GetSubNodeNameAsString(i)
  Case "id"
   'TODO:check duplicated ID
   tPoly.sID = s
  Case "shape"
   Select Case s
   Case "cube"
    tPoly.nShape = &H111&
   Case "cuboid", "classical"
    tPoly.nShape = &H112&
   Case "tetrahedron"
    tPoly.nShape = 1
   Case "octahedron"
    tPoly.nShape = 2
   Case "icosahedron"
    tPoly.nShape = 3
   Case "triangularBipyramid"
    tPoly.nShape = 4
   Case "pentagonalBipyramid"
    tPoly.nShape = 5
   Case "rhomboid"
    tPoly.nShape = 6
   Case "heptahedron"
    tPoly.nShape = 7
   Case "snubDisphenoid"
    tPoly.nShape = 8
   Case "triaugmentedTriangularPrism"
    tPoly.nShape = 9
   Case "gyroelongatedSquareDipyramid"
    tPoly.nShape = 10
   Case "truncatedTetrahedron"
    tPoly.nShape = 11
   Case Else
    s = Replace(s, "x", "*")
    s = Replace(s, "X", "*")
    k = Val(s) And &HF&
    If k = 0 Then
     Debug.Assert False
     Exit Function
    End If
    tPoly.nShape = k * &H100&
    j = InStr(1, s, "*")
    If j = 0 Then
     Debug.Assert False
     Exit Function
    End If
    s = Mid(s, j + 1)
    k = Val(s) And &HF&
    If k = 0 Then
     Debug.Assert False
     Exit Function
    End If
    tPoly.nShape = tPoly.nShape Or (k * &H10&)
    j = InStr(1, s, "*")
    If j = 0 Then
     Debug.Assert False
     Exit Function
    End If
    s = Mid(s, j + 1)
    k = Val(s) And &HF&
    If k = 0 Then
     Debug.Assert False
     Exit Function
    End If
    tPoly.nShape = tPoly.nShape Or k
   End Select
  Case "type"
   j = FindObjectType(s)
   If j = 0 Then
    Debug.Assert False
    Exit Function
   End If
   tPoly.nObjType = j
  Case "p"
   If s = "" Then
    Debug.Assert False
    Exit Function
   End If
   If sBasePosition = "" Then
    tPoly.sPos = s
   Else
    Select Case AscW(s)
    Case 40, 46 '["."], ["("]
    Case &H30 To &H39 '["0"] To ["9"]
     j = InStr(1, s, ":")
     If j > 0 Then s = "(" + Left(s, j - 1) + ")" + Mid(s, j) _
     Else s = "(" + s + ")"
    Case Else
     s = "." + s
    End Select
    tPoly.sPos = sBasePosition + s
   End If
   '///debug
   'Debug.Print "Polyhedron start:" + tPoly.sPos
  Case "discardable"
   nFlags = pFlagsFromBooleanString(s, nFlags, &H1&)
  Case "main"
   nFlags = pFlagsFromBooleanString(s, nFlags, &H2&)
  Case "fragile"
   nFlags = pFlagsFromBooleanString(s, nFlags, &H4&)
  Case "supportable"
   nFlags = pFlagsFromBooleanString(s, nFlags, &H8&)
  Case "supporter"
   nFlags = pFlagsFromBooleanString(s, nFlags, &H10&)
  Case "tiltable"
   nFlags = pFlagsFromBooleanString(s, nFlags, &H20&)
  Case "tilt-supporter"
   nFlags = pFlagsFromBooleanString(s, nFlags, &H40&)
  Case "spannable"
   nFlags = pFlagsFromBooleanString(s, nFlags, &H80&)
  End Select
 Else
  'TODO:appearance,etc.
  Debug.Assert False
'  Set obj = objNode.SubNodeObject(i)
'  Select Case obj.GetNameAsString
'  Case "mapData"
'  End Select
 End If
Next i
'///over
tPoly.nFlags = nFlags
ParseMapPolyhedronDataFromNode = True
End Function

Friend Function AddLevelDataFromNodeEx(ByVal objNode As clsTreeStorageNode, ByRef tLevel As typeLevelData) As Boolean
Dim i As Long, j As Long, k As Long
Dim s As String
Dim obj As clsTreeStorageNode
'///
Select Case objNode.GetNameAsString
Case "level"
Case Else
 Exit Function
End Select
'///
For i = 1 To objNode.SubNodeCount
 If objNode.SubNodeType(i) = 0 Then
  'TODO:
  Debug.Assert False
'  Select Case objNode.GetSubNodeNameAsString(i)
'  Case "name"
'  End Select
 Else
  Set obj = objNode.SubNodeObject(i)
  Select Case obj.GetNameAsString
  Case "mapData"
   tLevel.nMapDataCount = tLevel.nMapDataCount + 1
   ReDim Preserve tLevel.tMapData(1 To tLevel.nMapDataCount)
   If Not ParseMapDataFromNode(obj, tLevel, tLevel.nMapDataCount) Then Exit Function
  Case "polyhedron"
   tLevel.nPolyhedronCount = tLevel.nPolyhedronCount + 1
   ReDim Preserve tLevel.tPolyhedron(1 To tLevel.nPolyhedronCount)
   If Not ParseMapPolyhedronDataFromNode(obj, tLevel.tPolyhedron(tLevel.nPolyhedronCount)) Then Exit Function
  Case "tileMapping"
   s = obj.GetSubNodeValueAsStringByName("id")
   If s <> "" Then
    k = -Val(obj.GetSubNodeValueAsStringByName("index"))
    If k > 0 And k <= m_nTileTypeCount_Max Then
     j = 0
     For j = 1 To m_nTileTypeCount
      If m_tTileType(j).nIndex > 0 Then
       If m_tTileType(j).sID = s Then
        j = -j
        Exit For
       End If
      End If
     Next j
     If j >= 0 Then
      For j = m_nTileTypeCount_Max + 1 To m_nTileTypeCount_Max + m_nTileTypeCount2
       If m_tTileType(j).sID = s Then
        j = -j
        Exit For
       End If
      Next j
     End If
     If j < 0 Then m_nTileTypeMap(k) = -j
    End If
   End If
  End Select
 End If
Next i
'///
AddLevelDataFromNodeEx = True
End Function

Friend Function GenerateMeshFromLevelData(ByVal objEffectMgr As clsEffectManager, ByRef tInst As typeMeshInstanceCollection) As Boolean
GenerateMeshFromLevelData = GenerateMeshFromLevelDataEx(m_tLevel, objEffectMgr, tInst)
End Function

'test only
Friend Function GenerateMeshFromLevelDataEx(ByRef tLevel As typeLevelData, ByVal objEffectMgr As clsEffectManager, ByRef tInst As typeMeshInstanceCollection, Optional ByVal bRuntime As Boolean = True) As Boolean
Dim idx As Long
Dim i As Long, j As Long, k As Long
Dim mat As D3DMATRIX, mat1 As D3DMATRIX, mat2 As D3DMATRIX
Dim nIndex As Long
'///
For idx = 1 To tLevel.nMapDataCount
 Select Case tLevel.tMapData(idx).nFlags And &HF&
 Case 0 'rect
  mat = tLevel.tMapData(idx).matWorld
  For k = 0 To tLevel.tMapData(idx).nSize(2) - 1
   mat1 = mat
   For j = 0 To tLevel.tMapData(idx).nSize(1) - 1
    mat2 = mat1
    For i = 0 To tLevel.tMapData(idx).nSize(0) - 1
     '///
     nIndex = tLevel.tMapData(idx).nTypeArray(i, j, k)
     If nIndex > 0 And nIndex <= m_nTileTypeMax Then
      'invisibleAtRuntime (?)
      If (bRuntime And m_tTileType(nIndex).nFlags And 1&) = 0 Then
       objEffectMgr.AddInstanceFromAppearanceEx tInst, m_tTileType(nIndex).nApprIndex, mat2
      End If
     End If
     '///
     mat2.m41 = mat2.m41 + tLevel.tMapData(idx).fPos(1).x
     mat2.m42 = mat2.m42 + tLevel.tMapData(idx).fPos(1).y
     mat2.m43 = mat2.m43 + tLevel.tMapData(idx).fPos(1).z
    Next i
    mat1.m41 = mat1.m41 + tLevel.tMapData(idx).fPos(2).x
    mat1.m42 = mat1.m42 + tLevel.tMapData(idx).fPos(2).y
    mat1.m43 = mat1.m43 + tLevel.tMapData(idx).fPos(2).z
   Next j
   mat.m41 = mat.m41 + tLevel.tMapData(idx).fPos(3).x
   mat.m42 = mat.m42 + tLevel.tMapData(idx).fPos(3).y
   mat.m43 = mat.m43 + tLevel.tMapData(idx).fPos(3).z
  Next k
 Case Else
  'TODO:
  Debug.Assert False
 End Select
Next idx
GenerateMeshFromLevelDataEx = True
End Function

Friend Sub Destroy()
Erase m_tObjType, m_nObjInteraction
m_nObjTypeCount = 0
m_nObjTypeMax = 0
m_bObjInteractionDirty = False
Erase m_tTileType
m_nTileTypeCount = 0
m_nTileTypeCount2 = 0
m_nTileTypeMax = 0
'///
ClearLevelData
End Sub

'Friend Sub ClearObjectTypes()
'Erase m_tObjType, m_nObjInteraction
'm_nObjTypeCount = 0
'm_nObjTypeMax = 0
'm_bObjInteractionDirty = False
'End Sub

Friend Property Get ObjectTypeCount() As Long
ObjectTypeCount = m_nObjTypeCount
End Property

Friend Property Get ObjectTypeName(ByVal nIndex As Long) As String
ObjectTypeName = m_tObjType(nIndex).sName
End Property

Friend Function FindObjectType(ByVal sName As String) As Long
Dim i As Long
For i = 1 To m_nObjTypeCount
 If sName = m_tObjType(i).sName Then
  FindObjectType = i
  Exit Function
 End If
Next i
End Function

Friend Property Get TileTypeID(ByVal nIndex As Long) As String
TileTypeID = m_tTileType(nIndex).sID
End Property

Friend Function FindTileType(ByVal sID As String) As Long
Dim i As Long
For i = 1 To m_nTileTypeCount
 If m_tTileType(i).nIndex = i Then
  If sID = m_tTileType(i).sID Then
   FindTileType = i
   Exit Function
  End If
 End If
Next i
For i = m_nTileTypeCount_Max + 1 To m_nTileTypeCount_Max + m_nTileTypeCount2
 If sID = m_tTileType(i).sID Then
  FindTileType = i
  Exit Function
 End If
Next i
End Function

Friend Property Get TileTypeName(ByVal nIndex As Long, Optional ByVal bTranslate As Boolean) As String
If bTranslate Then TileTypeName = objText.GetText(m_tTileType(nIndex).sName) _
Else TileTypeName = m_tTileType(nIndex).sName
End Property

Friend Property Get TileTypeDescription(ByVal nIndex As Long, Optional ByVal bTranslate As Boolean) As String
If bTranslate Then TileTypeDescription = objText.GetText(m_tTileType(nIndex).sDesc) _
Else TileTypeDescription = m_tTileType(nIndex).sDesc
End Property

Friend Property Let TileTypeName(ByVal nIndex As Long, Optional ByVal bTranslate As Boolean, ByRef s As String)
m_tTileType(nIndex).sName = s
End Property

Friend Property Let TileTypeDescription(ByVal nIndex As Long, Optional ByVal bTranslate As Boolean, ByRef s As String)
m_tTileType(nIndex).sDesc = s
End Property

Friend Function GetDualObjectInteractionType(ByVal nType As Long) As Long
Select Case nType
Case &H102 To &H105
 nType = nType Xor 1&
End Select
GetDualObjectInteractionType = nType
End Function

Friend Sub CalcObjectInteractionType()
On Error Resume Next
Dim i As Long, j As Long, k As Long
Dim nType As Long, nType2 As Long
Dim obj As New Collection
If m_bObjInteractionDirty Then
 ReDim m_nObjInteraction(0 To m_nObjTypeCount, 0 To m_nObjTypeCount)
 '///
 For i = 1 To m_nObjTypeCount
  obj.Add i, m_tObjType(i).sName
  nType = m_tObjType(i).tInteraction(0).nType
  If nType > 0 Then
   nType2 = GetDualObjectInteractionType(nType)
   For j = 0 To m_nObjTypeCount
    m_nObjInteraction(i, j) = nType
    If m_nObjInteraction(j, i) = 0 Then m_nObjInteraction(j, i) = nType2
   Next j
  End If
 Next i
 '///
 For i = 1 To m_nObjTypeCount
  For k = 1 To m_tObjType(i).nInteractionCount
   Err.Clear
   j = obj.Item(m_tObjType(i).tInteraction(k).sName2)
   If Err.Number = 0 Then
    nType = m_tObjType(i).tInteraction(k).nType
    m_nObjInteraction(i, j) = &H80000000 Or nType
    If m_nObjInteraction(j, i) >= 0 Then m_nObjInteraction(j, i) = &H80000000 Or GetDualObjectInteractionType(nType)
   End If
  Next k
 Next i
 '///
End If
m_bObjInteractionDirty = False
End Sub

Friend Function GetObjectInteractionType(ByVal nIndex1 As Long, ByVal nIndex2 As Long) As Long
If nIndex1 >= 0 And nIndex1 <= m_nObjTypeCount And nIndex2 >= 0 And nIndex2 <= m_nObjTypeCount Then
 If m_bObjInteractionDirty Then CalcObjectInteractionType
 GetObjectInteractionType = m_nObjInteraction(nIndex1, nIndex2) And &H7FFFFFFF
End If
End Function

'internal
Friend Sub ParseInteraction(ByRef t As typeObjectInteractionType, ByVal s As String)
Dim j As Long, s1 As String
j = InStr(1, s, ":")
If j > 0 Then
 s1 = Mid(s, j + 1)
 s = Left(s, j - 1)
End If
Select Case s
Case "moveable"
 t.nType = 0
Case "not-moveable"
 t.nType = 1
Case "slippery"
 t.nType = 2
Case "superSlippery"
 t.nType = 3
Case "game-over"
 j = 0
 Select Case s1
 Case "immediately"
  j = 1
 Case "breakdown"
  j = 2
 Case "breakdown:2"
  j = 3
 Case "melting"
  j = 4
 Case "melting:2"
  j = 5
 End Select
 t.nType = &H100 Or j
Case Else
 Debug.Assert False
End Select
End Sub

'internal
Friend Function AddObjectTypeFromNode(ByVal objNode As clsTreeStorageNode) As Long
Dim i As Long, j As Long
Dim s As String
Dim obj As clsTreeStorageNode
Dim nCount As Long, nMax As Long
'///
Select Case objNode.GetNameAsString
Case "objectType"
Case Else
 Exit Function
End Select
'///
m_nObjTypeCount = m_nObjTypeCount + 1
If m_nObjTypeCount > m_nObjTypeMax Then
 m_nObjTypeMax = m_nObjTypeMax + 16&
 ReDim Preserve m_tObjType(1 To m_nObjTypeMax)
End If
'///
ReDim m_tObjType(m_nObjTypeCount).tInteraction(0 To 0)
'///
For i = 1 To objNode.SubNodeCount
 If objNode.SubNodeType(i) = 0 Then
  Select Case objNode.GetSubNodeNameAsString(i)
  Case "name"
   m_tObjType(m_nObjTypeCount).sName = objNode.GetSubNodeValueAsString(i)
  End Select
 Else
  Set obj = objNode.SubNodeObject(i)
  Select Case obj.GetNameAsString
  Case "interaction"
   For j = 1 To obj.SubNodeCount
    If obj.SubNodeType(j) = 0 Then
     s = obj.GetSubNodeNameAsString(j)
     Select Case s
     Case "default"
      ParseInteraction m_tObjType(m_nObjTypeCount).tInteraction(0), obj.GetSubNodeValueAsString(j)
     Case Else
      nCount = nCount + 1
      If nCount > nMax Then
       nMax = nMax + 8
       ReDim Preserve m_tObjType(m_nObjTypeCount).tInteraction(0 To nMax)
      End If
      m_tObjType(m_nObjTypeCount).nInteractionCount = nCount
      m_tObjType(m_nObjTypeCount).tInteraction(nCount).sName2 = s
      ParseInteraction m_tObjType(m_nObjTypeCount).tInteraction(nCount), obj.GetSubNodeValueAsString(j)
     End Select
    End If
   Next j
  End Select
 End If
Next i
'///
m_bObjInteractionDirty = True
AddObjectTypeFromNode = m_nObjTypeCount
End Function

Friend Sub LoadObjectTypesFromSubNodes(ByVal objNode As clsTreeStorageNode)
Dim i As Long
Dim obj As clsTreeStorageNode
For i = 1 To objNode.SubNodeCount
 Set obj = objNode.SubNodeObject(i)
 If Not obj Is Nothing Then AddObjectTypeFromNode obj
Next i
End Sub

Friend Function ParseEventType(ByRef s As String) As Long
Select Case s
Case "onEnter"
 ParseEventType = 1
Case "onLeave"
 ParseEventType = 2
Case "onMoveEnter"
 ParseEventType = 3
Case "onMoveLeave"
 ParseEventType = 4
Case "onPressKey"
 ParseEventType = 5
Case "onCustomEvent"
 ParseEventType = 6
Case "onTriggeredEvent", "onEvent" 'onEvent????????
 ParseEventType = 7
End Select
End Function

'internal
Friend Function ParseEventFromNode(ByRef ret As typeTileEvent, ByVal objNode As clsTreeStorageNode, ByVal nEventType As Long) As Boolean
On Error Resume Next
Dim v As Variant, m As Long
Dim s As String, s1 As String
Dim i As Long, j As Long
Dim lps As Long
Dim nType As Long
Dim nCompareType As Long
Dim nDataType As Long
'///
ret.nEventType = nEventType
'///process conditions
v = Split(Trim(objNode.GetSubNodeValueAsStringByName("condition")), ";")
ret.nConditionCount = UBound(v) + 1
If ret.nConditionCount > 0 Then ReDim ret.tCondition(1 To ret.nConditionCount)
For i = 1 To ret.nConditionCount
 s = Trim(v(i - 1))
 lps = InStr(1, s, "=")
 If lps <= 1 Then
  Debug.Assert False
  Exit Function
 End If
 s1 = Trim(Mid(s, lps + 1))
 If Mid(s, lps - 1, 1) = "!" Then
  nCompareType = 1
  lps = lps - 1
 End If
 Select Case Trim(Left(s, lps - 1))
 Case "pressure"
  nType = 1
  nDataType = 2
 Case "onGroundCount"
  nType = 2
  nDataType = 2
 Case "onDifferentType"
  nType = 3
  nDataType = 1
 Case "eventType"
  nType = 4
  nDataType = 3
 Case "eventIndex"
  nType = 5
  nDataType = 2
 Case "discardable"
  nType = &H101
  nDataType = 1
 Case "main"
  nType = &H102
  nDataType = 1
 Case "fragile"
  nType = &H103
  nDataType = 1
 Case "supportable"
  nType = &H104
  nDataType = 1
 Case "supporter"
  nType = &H105
  nDataType = 1
 Case "tiltable"
  nType = &H106
  nDataType = 1
 Case "tilt-supporter"
  nType = &H107
  nDataType = 1
 Case "spannable"
  nType = &H108
  nDataType = 1
 Case "objectType"
  nType = &H121
  nDataType = 3
 Case Else
  Debug.Assert False
  Exit Function
 End Select
 '///
 Select Case nDataType
 Case 1 'boolean
  j = 0
  If s1 = "true" Then j = 1 Else If Val(s1) <> 0 Then j = 1
  If nCompareType And 1& Then
   nCompareType = 0
   j = j Xor 1
  End If
  ret.tCondition(i).nValue1 = j
  ret.tCondition(i).nValue2 = j
 Case 2 'number
  lps = InStr(1, s1, "~")
  If lps > 0 Then
   s = Trim(Left(s1, lps - 1))
   s1 = Trim(Mid(s1, lps + 1))
   If s <> "" Then
    If s1 <> "" Then
     ret.tCondition(i).nValue1 = Val(s)
     ret.tCondition(i).nValue2 = Val(s1)
    Else
     ret.tCondition(i).nValue1 = Val(s)
     ret.tCondition(i).nValue2 = 1E+30
    End If
   Else
    If s1 <> "" Then
     ret.tCondition(i).nValue1 = -1E+30
     ret.tCondition(i).nValue2 = Val(s1)
    Else
     'ERR
     Debug.Assert False
     Exit Function
    End If
   End If
  Else
   ret.tCondition(i).nValue1 = Val(s1)
   ret.tCondition(i).nValue2 = ret.tCondition(i).nValue1
  End If
 Case 3 'string
  ret.tCondition(i).sStringValue = Split(s1, "|")
  ret.tCondition(i).nStringValueCount = UBound(ret.tCondition(i).sStringValue) + 1
 End Select
 '///
 ret.tCondition(i).nType = nType
 ret.tCondition(i).nCompareType = nCompareType
Next i
'///process events
v = Split(Trim(objNode.GetSubNodeValueAsStringByName("event")), ";")
ret.nEventCount = UBound(v) + 1
If ret.nEventCount > 0 Then ReDim ret.tEvent(1 To ret.nEventCount)
For i = 1 To ret.nEventCount
 s = Trim(v(i - 1))
 lps = InStr(1, s, ":")
 If lps > 0 Then
  s1 = Trim(Mid(s, lps + 1))
  s = Trim(Left(s, lps - 1))
 Else
  s1 = vbNullString
 End If
 '///
 Select Case s
 Case "triggerEvent"
  nType = 1
  j = Val(s1)
  If j <= 0 Then j = 1
  ret.tEvent(i).nParam = j
 Case "sendEvent"
  nType = 2
  ret.tEvent(i).sStringParam = Split(s1, ":")
  ret.tEvent(i).nStringParamCount = UBound(ret.tEvent(i).sStringParam) + 1
 Case "teleport"
  nType = 3
  'TODO:
 Case "convertTo"
  nType = 4
  ret.tEvent(i).nStringParamCount = 1
  ReDim ret.tEvent(i).sStringParam(0)
  ret.tEvent(i).sStringParam(0) = s1
 Case "move"
  Select Case s1
  Case "left"
   nType = 6
  Case "right"
   nType = 7
  Case "back"
   nType = 8
  Case Else
   nType = 5
  End Select
 Case "absolute-move"
  nType = 9
  'TODO:
 Case "game-finished"
  Select Case s1
  Case "unconditional"
   nType = 11
  Case Else
   nType = 10
  End Select
 Case "checkpoint"
  nType = 12
 Case "game-over"
  j = 0
  Select Case s1
  Case "immediately"
   j = 1
  Case "breakdown"
   j = 2
  Case "breakdown:2"
   j = 3
  Case "melting"
   j = 4
  Case "melting:2"
   j = 5
  End Select
  nType = &H100 Or j
 Case Else
  Debug.Assert False
  Exit Function
 End Select
 '///
 ret.tEvent(i).nType = nType
Next i
'///over
ParseEventFromNode = True
End Function

'internal
Friend Function AddTileTypeFromNode(ByVal objNode As clsTreeStorageNode, ByVal objEffectMgr As clsEffectManager, ByVal objMeshMgr As clsMeshManager) As Long
Dim i As Long, j As Long
Dim s As String
Dim obj As clsTreeStorageNode
Dim nIndex As Long
Dim nFlags As Long
Dim nEventType As Long
'///
Select Case objNode.GetNameAsString
Case "tileType"
Case Else
 Exit Function
End Select
'///
If m_nTileTypeMax <= 0 Then
 m_nTileTypeMax = m_nTileTypeCount_Max
 ReDim m_tTileType(1 To m_nTileTypeMax)
End If
'///get index
nIndex = Val(objNode.GetSubNodeValueAsStringByName("index"))
If nIndex > 0 And nIndex <= m_nTileTypeCount_Max Then
 If m_tTileType(nIndex).nIndex > 0 Then
  'already exists
  Debug.Assert False
  Exit Function
 End If
 m_tTileType(nIndex).nIndex = nIndex
 If m_nTileTypeCount < nIndex Then m_nTileTypeCount = nIndex
Else
 i = nIndex
 m_nTileTypeCount2 = m_nTileTypeCount2 + 1
 nIndex = m_nTileTypeCount2 + m_nTileTypeCount_Max
 If nIndex > m_nTileTypeMax Then
  m_nTileTypeMax = m_nTileTypeMax + 16&
  ReDim Preserve m_tTileType(1 To m_nTileTypeMax)
 End If
 If i > 0 Then m_tTileType(nIndex).nIndex = i
End If
'///
For i = 1 To objNode.SubNodeCount
 If objNode.SubNodeType(i) = 0 Then
  Select Case objNode.GetSubNodeNameAsString(i)
  Case "id"
   'TODO:check duplicated ID
   m_tTileType(nIndex).sID = objNode.GetSubNodeValueAsString(i)
  Case "invisibleAtRuntime" '? TODO:
   nFlags = nFlags Or ((objNode.GetSubNodeValueAsString(i) = "true") And &H1&)
  Case "checkpoint"
   nFlags = nFlags Or ((objNode.GetSubNodeValueAsString(i) = "true") And &H2&)
  Case "elevator"
   nFlags = nFlags Or ((objNode.GetSubNodeValueAsString(i) = "true") And &H4&)
  Case "non-block"
   nFlags = nFlags Or ((objNode.GetSubNodeValueAsString(i) = "true") And &H8&)
  Case "blocked"
   nFlags = nFlags Or ((objNode.GetSubNodeValueAsString(i) = "true") And &H100&)
  Case "tilt-supporter", "tiltable" '<== obsolete
   nFlags = nFlags Or ((objNode.GetSubNodeValueAsString(i) <> "true") And &H200&)
  Case "supporter", "supportable" '<== obsolete
   nFlags = nFlags Or ((objNode.GetSubNodeValueAsString(i) <> "true") And &H400&)
  Case "block-height"
   m_tTileType(nIndex).nBlockHeight = Val(objNode.GetSubNodeValueAsString(i))
  Case "type"
   j = FindObjectType(objNode.GetSubNodeValueAsString(i))
   If j = 0 Then
    Debug.Assert False
    Exit Function
   End If
   m_tTileType(nIndex).nObjType = j
  End Select
 Else
  nEventType = 0
  Set obj = objNode.SubNodeObject(i)
  s = obj.GetNameAsString
  Select Case s
  Case "name"
   m_tTileType(nIndex).sName = obj.GetValueAsString
  Case "description"
   m_tTileType(nIndex).sDesc = obj.GetValueAsString
  Case "appearance"
   If m_tTileType(nIndex).nApprIndex > 0 Then
    'TODO:multiple appearances
    Debug.Assert False
    Exit Function
   End If
   m_tTileType(nIndex).nApprIndex = objEffectMgr.AddAppearanceFromNode(obj, objMeshMgr)
  Case Else
   nEventType = ParseEventType(s)
  End Select
  '///event?
  If nEventType > 0 Then
   m_tTileType(nIndex).nEventCount = m_tTileType(nIndex).nEventCount + 1
   ReDim Preserve m_tTileType(nIndex).tEvent(1 To m_tTileType(nIndex).nEventCount)
   If Not ParseEventFromNode(m_tTileType(nIndex).tEvent(m_tTileType(nIndex).nEventCount), obj, nEventType) Then
    Exit Function
   End If
  End If
  '///
 End If
Next i
'///
m_tTileType(nIndex).nFlags = nFlags
'debug
'Debug.Print nIndex, m_tTileType(nIndex).nIndex, m_tTileType(nIndex).sID, m_tTileType(nIndex).sName
'///
AddTileTypeFromNode = nIndex
End Function

Friend Sub LoadTileTypesFromSubNodes(ByVal objNode As clsTreeStorageNode, ByVal objEffectMgr As clsEffectManager, ByVal objMeshMgr As clsMeshManager)
Dim i As Long
Dim obj As clsTreeStorageNode
For i = 1 To objNode.SubNodeCount
 Set obj = objNode.SubNodeObject(i)
 If Not obj Is Nothing Then AddTileTypeFromNode obj, objEffectMgr, objMeshMgr
Next i
End Sub

Friend Function IsOtherPolyhedronOn(ByVal nPolyhedronIndex As Long) As Boolean
Dim idx As Long
Dim i1 As Long, j1 As Long, k1 As Long, p1 As typePolyhedronPosition
Dim i2 As Long, j2 As Long, k2 As Long, p2 As typePolyhedronPosition
Select Case m_tLevel.tPolyhedron(nPolyhedronIndex).nShape
Case &H111 To &HFFF
 m_objPoly(nPolyhedronIndex).GetCurrentSize i1, j1, k1
 p1 = m_objPoly(nPolyhedronIndex).Position
 For idx = 1 To m_tLevel.nPolyhedronCount
  If idx <> nPolyhedronIndex Then
   Select Case m_tLevel.tPolyhedron(idx).nShape
   Case &H111 To &HFFF
    m_objPoly(idx).GetCurrentSize i2, j2, k2
    p2 = m_objPoly(idx).Position
    If p1.nMapDataIndex = p2.nMapDataIndex Then
     If p2.x > p1.x - i2 And p2.x < p1.x + i1 Then
      If p2.y > p1.y - j2 And p2.y < p1.y + j1 Then
       If p2.z = p1.z + k1 Then
        IsOtherPolyhedronOn = True
        Exit Function
       End If
      End If
     End If
    End If
   End Select
  End If
 Next idx
Case Else
 'TODO:
 Debug.Assert False
End Select
End Function

Friend Function GetAdjacentPosition(ByRef tPos As typePolyhedronPosition, ByVal nDirection As Long, ByRef tNewPos As typePolyhedronPosition, Optional ByRef nNewDirection As Long) As Boolean
tNewPos = tPos
GetAdjacentPosition = GetAdjacentPositionInPlace(tPos, nDirection, nNewDirection)
End Function

'direction:
'0=up
'1=left
'2=down
'3=right
'4=
'5=
'6=bottom
'7=top
Friend Function GetAdjacentPositionInPlace(ByRef tPos As typePolyhedronPosition, ByVal nDirection As Long, Optional ByRef nNewDirection As Long) As Boolean
'///
nNewDirection = nDirection
'///
If tPos.nMapDataIndex > 0 And tPos.nMapDataIndex <= m_tLevel.nMapDataCount Then
 'TODO:check adjacent data and change nNewDirection
 Select Case m_tLevel.tMapData(tPos.nMapDataIndex).nFlags And &HF&
 Case 0 'rect
  Select Case nDirection
  Case 0
   tPos.y = tPos.y - 1
  Case 1
   tPos.x = tPos.x - 1
  Case 2
   tPos.y = tPos.y + 1
  Case 3
   tPos.x = tPos.x + 1
  Case 6
   tPos.z = tPos.z - 1
  Case 7
   tPos.z = tPos.z + 1
  Case Else
   Debug.Assert False
  End Select
 Case Else
  'TODO:
  Debug.Assert False
 End Select
End If
'///
GetAdjacentPositionInPlace = True '???
End Function

'return value:
'-3 : blocked and not tiltable
'-2 : this position is blocked
'-1 : can't stand on there (maybe no supporter or something's supporter=false)
'>=0: stand on something, return value is nObjType
'---
'TODO:return more info
Friend Function HitTest(ByRef tPos As typePolyhedronPosition, Optional ByVal nExcludePolyhedronIndex As Long) As Long
Dim idx As Long
Dim i As Long, j As Long, k As Long
Dim sz As Long, ez As Long
Dim t As typePolyhedronPosition
Dim ret As Long
'///
ret = -1
'///check if it's on some polyhedron
For idx = 1 To m_tLevel.nPolyhedronCount
 If idx <> nExcludePolyhedronIndex Then
  'TODO: if it's not a supporter then there should be some event
  Select Case m_tLevel.tPolyhedron(idx).nShape
  Case &H111 To &HFFF
   m_objPoly(idx).GetCurrentSize i, j, k
   t = m_objPoly(idx).Position
   '///
   'TODO: wrong code if there are adjacency data
   If t.nMapDataIndex = tPos.nMapDataIndex Then
    If tPos.x >= t.x And tPos.x < t.x + i Then
     If tPos.y >= t.y And tPos.y < t.y + j Then
      If tPos.z >= t.z And tPos.z < t.z + k Then
       If m_tLevel.tPolyhedron(idx).nFlags And &H40& Then HitTest = -2 _
       Else HitTest = -3
       Exit Function
      ElseIf tPos.z = t.z + k And (m_tLevel.tPolyhedron(idx).nFlags And &H10&) <> 0 Then
       If ret < 0 Then ret = m_tLevel.tPolyhedron(idx).nObjType
      End If
     End If
    End If
   End If
  Case Else
   'TODO:
   Debug.Assert False
  End Select
 End If
Next idx
'///check if it's on some tile
idx = tPos.nMapDataIndex
If idx > 0 And idx <= m_tLevel.nMapDataCount Then
 'TODO:adjacency data
 If tPos.x >= 0 And tPos.x < m_tLevel.tMapData(idx).nSize(0) Then
  If tPos.y >= 0 And tPos.y < m_tLevel.tMapData(idx).nSize(1) Then
   k = m_tLevel.tMapData(idx).nSize(2) - 1
   If k > tPos.z + 1 Then k = tPos.z + 1 'TODO:higher
   Do While k >= 0
    i = m_tLevel.tMapData(idx).nTypeArray(tPos.x, tPos.y, k)
    If i > 0 And i <= m_nTileTypeMax Then
     j = m_tTileType(i).nFlags
     '///
     If j And &H8& Then sz = k _
     Else sz = k - 1
     If j And &H100& Then
      ez = m_tTileType(i).nBlockHeight
      If ez <= 0 Then ez = &H7FFFFFFF _
      Else ez = ez + k
     Else
      ez = k
     End If
     '///
     If tPos.z >= sz And tPos.z < ez Then 'blocked
      If (j And &H200&) = 0 Then HitTest = -2 _
      Else HitTest = -3
      Exit Function
     ElseIf tPos.z = ez And (j And &H400&) = 0 Then 'supported
      If ret < 0 Then ret = m_tTileType(i).nObjType
     End If
     '///
    End If
    '///
    k = k - 1
   Loop
  End If
 End If
End If
'///
HitTest = ret
End Function
