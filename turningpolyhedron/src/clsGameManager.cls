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

'////////object type data

Private m_tObjType() As typeObjectType
Private m_nObjTypeCount As Long, m_nObjTypeMax As Long

Private m_nObjInteraction() As Long '0 to nInteractionCount,0 to nInteractionCount; 0="default"
Private m_bObjInteractionDirty As Boolean

'////////tile type data

Private Const m_nTileTypeCount_Max As Long = 1024&

Private m_tTileType() As typeTileType
Private m_nTileTypeCount As Long 'fixed index, start with 1 (this is not count, but just max index)
Private m_nTileTypeCount2 As Long 'dynamic index, srart with m_nTileTypeCount_Max+1
Private m_nTileTypeMax As Long

'////////level data (TEST ONLY)

Private m_tLevel As typeLevelData

Friend Sub ClearLevelData()
Dim t As typeLevelData
m_tLevel = t
'TODO: reset dynamic-mapped tile index
End Sub

Friend Sub AddLevelDataFromNode(ByVal objNode As clsTreeStorageNode)
AddLevelDataFromNodeEx objNode, m_tLevel
End Sub

Friend Function ParseMapDataFromNode(ByVal objNode As clsTreeStorageNode, ByRef tLevel As typeLevelData, ByVal nIndex As Long) As Boolean
Dim i As Long, j As Long, k As Long, m As Long
Dim v As Variant
Dim s As String
Dim nFlags As Long
Dim obj As clsTreeStorageNode
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
'///
For i = 1 To objNode.SubNodeCount
 If objNode.SubNodeType(i) = 0 Then
  Select Case objNode.GetSubNodeNameAsString(i)
  Case "id"
   'TODO:check duplicated ID
   tLevel.tMapData(nIndex).sID = objNode.GetSubNodeValueAsString(i)
  Case "shape"
   s = objNode.GetSubNodeValueAsString(i)
   Select Case s
   Case "rect"
    j = 0
   Case Else 'currently unsupported
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
   tLevel.tMapData(nIndex).nFlags = nFlags
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
   'TODO:
   Debug.Assert False
  Case "property"
   'TODO:
   Debug.Assert False
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
'///over
tLevel.tMapData(nIndex).nFlags = nFlags
ParseMapDataFromNode = True
End Function

Friend Function pFlagsFromBooleanString(ByRef s As String, ByVal nFlags As Long, ByVal nMask As Long) As Long
Dim j As Long
If s = "true" Then j = -1 Else If Val(s) <> 0 Then j = -1
pFlagsFromBooleanString = (nFlags And Not nMask) Or (j And nMask)
End Function

Friend Function ParseMapPolyhedronDataFromNode(ByVal objNode As clsTreeStorageNode, ByRef tPoly As typeMapData_Polyhedron, Optional ByVal sBasePosition As String) As Boolean
Dim i As Long
Dim s As String
Dim obj As clsTreeStorageNode
Dim nFlags As Long
'///
nFlags = &HFE&
'///
For i = 1 To objNode.SubNodeCount
 If objNode.SubNodeType(i) = 0 Then
  s = Trim(objNode.GetSubNodeValueAsString(i))
  Select Case objNode.GetSubNodeNameAsString(i)
  Case "id"
   'TODO:check duplicated ID
   tPoly.sID = s
  Case "p"
   If sBasePosition = "" Then
    tPoly.sPos = s
   Else
    Select Case Left(s, 1)
    Case ".", "("
    Case Else
     s = "." + s
    End Select
    tPoly.sPos = sBasePosition + s
   End If
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
  Debug.Assert False
'  'TODO:
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
Dim i As Long
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
  End Select
 End If
Next i
'///
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
 If m_tTileType(i).nIndex > 0 Then
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
Case "onTriggeredEvent"
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
  Case "blocked"
   nFlags = nFlags Or ((objNode.GetSubNodeValueAsString(i) = "true") And &H100&)
  Case "tiltable"
   nFlags = nFlags Or ((objNode.GetSubNodeValueAsString(i) <> "true") And &H200&)
  Case "supportable"
   nFlags = nFlags Or ((objNode.GetSubNodeValueAsString(i) <> "true") And &H400&)
  Case "block-height"
   'currently unsupported TODO:
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

