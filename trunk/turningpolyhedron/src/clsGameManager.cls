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

Private Const m_fAnimTime As Single = 250 'TODO:different time for different animation

'////////object type data

Private m_tObjType() As typeObjectType '1-based, continuous data
Private m_nObjTypeCount As Long, m_nObjTypeMax As Long

Private m_nObjInteraction() As Long '0 to nInteractionCount,0 to nInteractionCount; 0="default"
Private m_bObjInteractionDirty As Boolean

'////////tile type data

Private Const m_nTileTypeCount_Max As Long = 1024&

Private m_tTileType() As typeTileType '1-based, sparse and continuous data
Private m_nTileTypeCount As Long 'fixed index, start with 1 (this is not count, but just max index)
Private m_nTileTypeCount2 As Long 'dynamic index, start with m_nTileTypeCount_Max+1
Private m_nTileTypeMax As Long '=UBound(m_tTileType)

'////////tile mapping data

Private m_nTileTypeMap(1 To m_nTileTypeCount_Max) As Long

'////////level data (TEST ONLY)

Private m_tLevel As typeLevelData

'runtime data

Private m_bRuntimeDirty As Boolean

Private m_bIsRuntime As Boolean

Private m_tMapDataInst() As typeMapDataRuntime '1 to map data count
Private m_tTileAnim() As typeCustomTileAnimation '1-based
Private m_nTileAnimMax As Long, m_nTileAnimFirstUnused As Long
Private m_tLevelInst As typeMeshInstanceCollection

Private m_objPoly() As New clsPolyhedron '1 to polyhedron count
Private m_tPolyInst() As typePolyhedronInstance '1 to polyhedron count

Private m_nCurrentPolyhedron As Long

Private m_tEvent() As typeMapDataEvent '0-based
Private m_nEventStart As Long, m_nEventEnd As Long, m_nEventMax As Long
Private m_bPolyhedronDirty As Boolean

Private m_nCheckPointRemaining As Long
Private m_bGameOver As Boolean, m_bGameFinished As Boolean
Private m_bGameFinishedEvent As Boolean

Private m_nWinningConditionValue() As Boolean  '(not inverted) value

'////////undo support (experimental)

#Const UndoPolyhedronAnimation = False

Private Type typeGameMgrUndoData
 nUndoIndex As Long
 nFlags As Long
 '&H1=MapDataInst, etc. dirty
 '&H2=PolyInst, etc. dirty
 '&H4=some numbers dirty (but always save)
 '&H8=WinningConditionValue dirty
 '///MapDataInst, etc.
 tMapDataInst() As typeMapDataRuntime
 tTileAnim() As typeCustomTileAnimation
 nTileAnimMax As Long
 nTileAnimFirstUnused As Long
 tLevelInst As typeMeshInstanceCollection
 '///PolyInst, etc. (excluding animation)
 tPolyInst() As typePolyhedronInstance
 '///some numbers (always save)
 nCurrentPolyhedron As Long
 nCheckPointRemaining As Long
 bPolyhedronDirty As Boolean
 bGameOver As Boolean
 bGameFinished As Boolean
 bGameFinishedEvent As Boolean
 '///
 nWinningConditionValue() As Boolean
End Type

Private m_tUndo() As typeGameMgrUndoData '1-based
Private m_nUndoCount As Long, m_nUndoMax As Long
Private m_nUndoDirtyFlags As Long

'////////game logic settings

Private m_bAutoReset As Boolean, m_bReset As Boolean

'////////render settings

Private m_bFollowPolyhedron As Boolean

'////////new:data level

Private Type typeGameMgrDataLevel
 nDataLevel As Long
 nObjTypeCount As Long
 nTileTypeCount As Long
 nTileTypeCount2 As Long
 nTileTypeMap(1 To m_nTileTypeCount_Max) As Long
End Type

Private m_nDataLevel As Long
Private m_tDataLevelArray() As typeGameMgrDataLevel '1-based
Private m_nDataLevelCount As Long

Friend Sub AddUndoIndex(ByVal nUndoIndex As Long)
Dim i As Long
'///
If m_bRuntimeDirty Then Exit Sub
'///
If m_nUndoDirtyFlags Then
 If m_nUndoCount > 0 Then
  If m_tUndo(m_nUndoCount).nUndoIndex < nUndoIndex Then
   m_nUndoCount = m_nUndoCount + 1
  Else
   Debug.Assert False '???
  End If
 Else
  m_nUndoCount = m_nUndoCount + 1
 End If
 '///
 If m_nUndoCount > m_nUndoMax Then
  m_nUndoMax = m_nUndoMax + 256&
  ReDim Preserve m_tUndo(1 To m_nUndoMax)
 End If
 '///
 m_tUndo(m_nUndoCount).nUndoIndex = nUndoIndex
 m_tUndo(m_nUndoCount).nFlags = m_nUndoDirtyFlags
 '///
 If m_nUndoDirtyFlags And 1& Then
  m_tUndo(m_nUndoCount).tMapDataInst = m_tMapDataInst
  m_tUndo(m_nUndoCount).tTileAnim = m_tTileAnim
  m_tUndo(m_nUndoCount).nTileAnimMax = m_nTileAnimMax
  m_tUndo(m_nUndoCount).nTileAnimFirstUnused = m_nTileAnimFirstUnused
  m_tUndo(m_nUndoCount).tLevelInst = m_tLevelInst
 End If
 '///
 If m_nUndoDirtyFlags And 2& Then
  m_tUndo(m_nUndoCount).tPolyInst = m_tPolyInst
 End If
 '///
 m_tUndo(m_nUndoCount).nCurrentPolyhedron = m_nCurrentPolyhedron
 m_tUndo(m_nUndoCount).nCheckPointRemaining = m_nCheckPointRemaining
 m_tUndo(m_nUndoCount).bPolyhedronDirty = m_bPolyhedronDirty
 m_tUndo(m_nUndoCount).bGameOver = m_bGameOver
 m_tUndo(m_nUndoCount).bGameFinished = m_bGameFinished
 m_tUndo(m_nUndoCount).bGameFinishedEvent = m_bGameFinishedEvent
 '///
 If m_nUndoDirtyFlags And 8& Then
  m_tUndo(m_nUndoCount).nWinningConditionValue = m_nWinningConditionValue
 End If
 '///
End If
m_nUndoDirtyFlags = 0
'///polyhedron
For i = 1 To m_tLevel.nPolyhedronCount
 m_objPoly(i).AddUndoIndex nUndoIndex
Next i
End Sub

Friend Sub Undo(ByVal nUndoIndex As Long)
Dim i As Long, j As Long
'///
If m_bRuntimeDirty Then Exit Sub
'///
For i = m_nUndoCount To 1 Step -1
 If m_tUndo(i).nUndoIndex <= nUndoIndex Then Exit For '???
Next i
If i > 0 And i <= m_nUndoCount Then
 If i < m_nUndoCount Then m_nUndoDirtyFlags = -1
 If m_nUndoDirtyFlags Then
  '///
  If m_nUndoDirtyFlags And 1& Then
   For j = i To 1 Step -1
    If m_tUndo(j).nFlags And 1& Then Exit For
   Next j
   If j > 0 Then
    m_tMapDataInst = m_tUndo(j).tMapDataInst
    m_tTileAnim = m_tUndo(j).tTileAnim
    m_nTileAnimMax = m_tUndo(j).nTileAnimMax
    m_nTileAnimFirstUnused = m_tUndo(j).nTileAnimFirstUnused
    m_tLevelInst = m_tUndo(j).tLevelInst
   End If
  End If
  '///
  If m_nUndoDirtyFlags And 2& Then
   For j = i To 1 Step -1
    If m_tUndo(j).nFlags And 2& Then Exit For
   Next j
   If j > 0 Then
    m_tPolyInst = m_tUndo(j).tPolyInst
   End If
  End If
  #If UndoPolyhedronAnimation Then
  #Else
  For j = 1 To m_tLevel.nPolyhedronCount
   m_tPolyInst(j).nAnimType = 0
   m_tPolyInst(j).nAnimStackIndex = 0
  Next j
  #End If
  '///
  m_nCurrentPolyhedron = m_tUndo(i).nCurrentPolyhedron
  m_nCheckPointRemaining = m_tUndo(i).nCheckPointRemaining
  m_bPolyhedronDirty = m_tUndo(i).bPolyhedronDirty
  m_bGameOver = m_tUndo(i).bGameOver
  m_bGameFinished = m_tUndo(i).bGameFinished
  m_bGameFinishedEvent = m_tUndo(i).bGameFinishedEvent
  '///
  If m_nUndoDirtyFlags And 8& Then
   For j = i To 1 Step -1
    If m_tUndo(j).nFlags And 8& Then Exit For
   Next j
   If j > 0 Then
    m_nWinningConditionValue = m_tUndo(j).nWinningConditionValue
   End If
  End If
  '///clear event ???
  Erase m_tEvent
  m_nEventStart = 0
  m_nEventEnd = 0
  m_nEventMax = 0
  '///
  m_nUndoDirtyFlags = 0
  m_nUndoCount = i
 End If
End If
'///polyhedron
For i = 1 To m_tLevel.nPolyhedronCount
 m_objPoly(i).Undo nUndoIndex
Next i
End Sub

Friend Property Get CheckPointCount() As Long
CheckPointCount = m_tLevel.nCheckPointCount
End Property

Friend Property Get CheckPointRemaining() As Long
If m_bRuntimeDirty Then Exit Property
CheckPointRemaining = m_nCheckPointRemaining
End Property

Friend Sub AddDataLevel(ByVal nDataLevel As Long)
If nDataLevel <= m_nDataLevel Then Exit Sub
If m_nDataLevelCount > 0 Then
 If nDataLevel < m_tDataLevelArray(m_nDataLevelCount).nDataLevel Then
  Exit Sub
 End If
End If
'///
m_nDataLevelCount = m_nDataLevelCount + 1
ReDim Preserve m_tDataLevelArray(1 To m_nDataLevelCount)
m_tDataLevelArray(m_nDataLevelCount).nDataLevel = nDataLevel
m_tDataLevelArray(m_nDataLevelCount).nObjTypeCount = m_nObjTypeCount
m_tDataLevelArray(m_nDataLevelCount).nTileTypeCount = m_nTileTypeCount
m_tDataLevelArray(m_nDataLevelCount).nTileTypeCount2 = m_nTileTypeCount2
CopyMemory m_tDataLevelArray(m_nDataLevelCount).nTileTypeMap(1), m_nTileTypeMap(1), m_nTileTypeCount_Max * 4&
'///
m_nDataLevel = nDataLevel
End Sub

Friend Sub RemoveDataLevel(ByVal nDataLevel As Long)
Dim i As Long, j As Long
Dim t As typeTileType
If nDataLevel <= 0 Then
 Destroy
ElseIf m_nDataLevelCount > 0 Then
 For i = m_nDataLevelCount To 1 Step -1
  If m_tDataLevelArray(i).nDataLevel < nDataLevel Then Exit For
 Next i
 If i < m_nDataLevelCount Then
  If i > 0 Then m_nDataLevel = m_tDataLevelArray(i).nDataLevel _
  Else m_nDataLevel = 0
  '///
  m_nDataLevelCount = i
  i = i + 1
  '///object types
  j = m_tDataLevelArray(i).nObjTypeCount
  If j < m_nObjTypeCount Then
   m_nObjTypeCount = j
   m_nObjTypeMax = j
   If j > 0 Then ReDim Preserve m_tObjType(1 To j) _
   Else Erase m_tObjType
   m_bObjInteractionDirty = True
  End If
  '///tile types
  m_nTileTypeCount = m_tDataLevelArray(i).nTileTypeCount
  For j = 1 To m_nTileTypeCount
   If m_tTileType(j).nIndex > 0 And m_tTileType(j).nDataLevel >= nDataLevel Then _
   m_tTileType(j) = t
  Next j
  For j = m_nTileTypeCount + 1 To m_nTileTypeCount_Max
   m_tTileType(j) = t
  Next j
  '///
  j = m_tDataLevelArray(i).nTileTypeCount2
  If j < m_nTileTypeCount2 Then
   m_nTileTypeCount2 = j
   m_nTileTypeMax = m_nTileTypeCount_Max + j
   ReDim Preserve m_tTileType(1 To m_nTileTypeMax)
  End If
  '///tile type mapping
  CopyMemory m_nTileTypeMap(1), m_tDataLevelArray(i).nTileTypeMap(1), m_nTileTypeCount_Max * 4&
 End If
End If
End Sub

Friend Property Get LevelName() As String
LevelName = m_tLevel.sName
End Property

Friend Property Get AutoReset() As Boolean
AutoReset = m_bAutoReset
End Property

Friend Property Let AutoReset(ByVal b As Boolean)
m_bAutoReset = b
End Property

Friend Property Get ResetOnNextUpdate() As Boolean
ResetOnNextUpdate = m_bReset
End Property

Friend Property Let ResetOnNextUpdate(ByVal b As Boolean)
m_bReset = b
End Property

Friend Property Get CurrentPolyhedron() As Long
CurrentPolyhedron = m_nCurrentPolyhedron
End Property

Friend Property Let CurrentPolyhedron(ByVal n As Long)
m_nCurrentPolyhedron = n
End Property

Friend Property Get FollowCurrentPolyhedron() As Boolean
FollowCurrentPolyhedron = m_bFollowPolyhedron
End Property

Friend Property Let FollowCurrentPolyhedron(ByVal b As Boolean)
m_bFollowPolyhedron = b
End Property

Friend Property Get PolyhedronCount() As Long
PolyhedronCount = m_tLevel.nPolyhedronCount
End Property

Friend Property Get CurrentPolyhedronObject() As clsPolyhedron
Set CurrentPolyhedronObject = PolyhedronObject(m_nCurrentPolyhedron)
End Property

Friend Property Get PolyhedronObject(ByVal nPolyhedronIndex As Long) As clsPolyhedron
If m_bRuntimeDirty Then Exit Property
If nPolyhedronIndex > 0 And nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then _
Set PolyhedronObject = m_objPoly(nPolyhedronIndex)
End Property

'Friend Property Get IsCurrentPolyhedronMoving() As Boolean
'IsCurrentPolyhedronMoving = IsPolyhedronMoving(m_nCurrentPolyhedron)
'End Property
'
'Friend Property Get IsPolyhedronMoving(ByVal nPolyhedronIndex As Long) As Boolean
'If m_bRuntimeDirty Then Exit Property
'If nPolyhedronIndex > 0 And nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then _
'IsPolyhedronMoving = m_tPolyInst(nPolyhedronIndex).nAnimType <> 0
'End Property

Friend Property Get CanPlayerMovePolyhedron() As Boolean
Dim idx As Long
'///
If m_bRuntimeDirty Then Exit Property
If m_bGameOver Then Exit Property
'///
For idx = 1 To m_tLevel.nPolyhedronCount
 If m_tPolyInst(idx).nFlags And &H100& Then
  If m_tPolyInst(idx).nAnimType <> 0 Then
   Exit Property
  End If
 End If
Next idx
'///
CanPlayerMovePolyhedron = True
End Property

Friend Property Get IsPolyhedronVisible(ByVal nPolyhedronIndex As Long) As Boolean
If m_bRuntimeDirty Then Exit Property
If nPolyhedronIndex > 0 And nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then _
IsPolyhedronVisible = m_tPolyInst(nPolyhedronIndex).nFlags And &H100&
End Property

Friend Function GetNextVisiblePolyhedron(Optional ByVal nPolyhedronIndex As Long = -1) As Long
Dim i As Long
'///
If m_bRuntimeDirty Then Exit Function
'///
If nPolyhedronIndex < 0 Then nPolyhedronIndex = m_nCurrentPolyhedron
If nPolyhedronIndex <= 0 Or nPolyhedronIndex > m_tLevel.nPolyhedronCount Then nPolyhedronIndex = 0
'///
For i = 1 To m_tLevel.nPolyhedronCount
 nPolyhedronIndex = nPolyhedronIndex + 1
 If nPolyhedronIndex > m_tLevel.nPolyhedronCount Then nPolyhedronIndex = 1
 '///
 If m_tPolyInst(nPolyhedronIndex).nFlags And &H100& Then
  GetNextVisiblePolyhedron = nPolyhedronIndex
  Exit Function
 End If
Next i
End Function

Friend Function MoveCurrentPolyhedron(ByVal nDirection As Long, Optional ByVal nUndoIndex As Long = -1) As Long
MoveCurrentPolyhedron = MovePolyhedron(m_nCurrentPolyhedron, nDirection, nUndoIndex)
End Function

Friend Function MovePolyhedron(ByVal nPolyhedronIndex As Long, ByVal nDirection As Long, Optional ByVal nUndoIndex As Long = -1) As Long
If m_bRuntimeDirty Then Exit Function
If nPolyhedronIndex > 0 And nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
 If m_tPolyInst(nPolyhedronIndex).nFlags And &H100& Then
  MovePolyhedron = m_objPoly(nPolyhedronIndex).Move(nDirection, , nUndoIndex)
 End If
End If
End Function

Friend Sub StartTileAnimation(ByVal nInstIndex As Long, ByVal nType As Long)
Dim i As Long
Dim t As typeCustomTileAnimation
If nInstIndex > 0 Then
 i = GetEmptyTileAnimation
 t.nInstIndex = nInstIndex
 t.nAnimType = nType
 t.matWorld = m_tLevelInst.tInstance(nInstIndex).matWorld '???
 m_tTileAnim(i) = t
 '///
 m_nUndoDirtyFlags = m_nUndoDirtyFlags Or 1&
End If
End Sub

'nCurrentState=state return by clsPolyhedron::CheckPolyhedronStateEx
'///TODO:more arguments
Friend Sub StartPolyhedronAnimation(ByVal nPolyhedronIndex As Long, ByVal nCurrentState As Long, ByVal nReserved1 As Long)
Dim t1 As typePolyhedronState
Dim t2 As typePolyhedronState
Dim b As Boolean
'///
Select Case nCurrentState
Case 0 'not moveable
Case -1 'falling
 StartPolyhedronAnimationByType nPolyhedronIndex, -1
Case 1 '(???) moveable
 If nReserved1 And 7& Then
  '???????? TODO:(nReserved1) tilt animation
  StartPolyhedronAnimationByType nPolyhedronIndex, (nReserved1 And 7&) Or 8&
  If nReserved1 And 4& Then
   t1 = m_objPoly(nPolyhedronIndex).PolyhedronState(True)
   t2 = m_objPoly(nPolyhedronIndex).PolyhedronState
   t2.nTiltY = t2.nTiltY * t1.nTiltX - t1.nTiltY * t2.nTiltX
   Debug.Assert t2.nTiltY <= 0
   If t2.nTiltY < 0 Then _
   SetPolyhedronAnimationStack4 nPolyhedronIndex, (nReserved1 And 6&) Or 8&
  Else 'fall to ground
   SetPolyhedronAnimationStack4 nPolyhedronIndex, (nReserved1 And 6&) Or 8&
  End If
 Else
  StartPolyhedronAnimationByType nPolyhedronIndex, 1
  SetPolyhedronAnimationStack4 nPolyhedronIndex
 End If
Case 2 'slip
 StartPolyhedronAnimationByType nPolyhedronIndex, 2
 '///
 t1 = m_objPoly(nPolyhedronIndex).PolyhedronState(True)
 t2 = m_objPoly(nPolyhedronIndex).PolyhedronState
 t2.nTiltY = t2.nTiltY * t1.nTiltX - t1.nTiltY * t2.nTiltX
 Debug.Assert t2.nTiltY <= 0
 SetPolyhedronAnimationStack4 nPolyhedronIndex, (t2.nTiltY < 0) And 8& '???
Case Else
 Debug.Assert False
End Select
End Sub

'internal function
Friend Sub StartPolyhedronAnimationByStack(ByVal nPolyhedronIndex As Long)
Dim i As Long
i = m_tPolyInst(nPolyhedronIndex).nAnimStackIndex
If i > 0 Then
 i = i - 1
 m_tPolyInst(nPolyhedronIndex).nAnimStackIndex = i
 i = m_tPolyInst(nPolyhedronIndex).nAnimStack(i)
End If
StartPolyhedronAnimationByType nPolyhedronIndex, i
'///
#If UndoPolyhedronAnimation Then
m_nUndoDirtyFlags = m_nUndoDirtyFlags Or 2&
#Else
m_nUndoDirtyFlags = m_nUndoDirtyFlags Or 4&
#End If
End Sub

'internal function
'TODO:check animation type
Friend Sub StartPolyhedronAnimationByType(ByVal nPolyhedronIndex As Long, ByVal nType As Long)
Erase m_tPolyInst(nPolyhedronIndex).fAnimValue
m_tPolyInst(nPolyhedronIndex).nAnimType = nType
'///
#If UndoPolyhedronAnimation Then
m_nUndoDirtyFlags = m_nUndoDirtyFlags Or 2&
#Else
m_nUndoDirtyFlags = m_nUndoDirtyFlags Or 4&
#End If
End Sub

'internal function
Friend Sub SetPolyhedronAnimationStack4(ByVal nPolyhedronIndex As Long, Optional ByVal a0 As Long, Optional ByVal a1 As Long, Optional ByVal a2 As Long, Optional ByVal a3 As Long)
If a0 = 0 Then
 m_tPolyInst(nPolyhedronIndex).nAnimStackIndex = 0
Else
 m_tPolyInst(nPolyhedronIndex).nAnimStack(0) = a0
 If a1 = 0 Then
  m_tPolyInst(nPolyhedronIndex).nAnimStackIndex = 1
 Else
  m_tPolyInst(nPolyhedronIndex).nAnimStack(1) = a1
  If a2 = 0 Then
   m_tPolyInst(nPolyhedronIndex).nAnimStackIndex = 2
  Else
   m_tPolyInst(nPolyhedronIndex).nAnimStack(2) = a2
   If a3 = 0 Then
    m_tPolyInst(nPolyhedronIndex).nAnimStackIndex = 3
   Else
    m_tPolyInst(nPolyhedronIndex).nAnimStackIndex = 4
    m_tPolyInst(nPolyhedronIndex).nAnimStack(3) = a3
   End If
  End If
 End If
End If
'///
#If UndoPolyhedronAnimation Then
m_nUndoDirtyFlags = m_nUndoDirtyFlags Or 2&
#Else
m_nUndoDirtyFlags = m_nUndoDirtyFlags Or 4&
#End If
End Sub

Friend Function GetPolyhedronCenterPos(ByVal nPolyhedronIndex As Long) As D3DVECTOR
If m_bRuntimeDirty Then Exit Function
If nPolyhedronIndex > 0 And nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
 GetPolyhedronCenterPos = m_tPolyInst(nPolyhedronIndex).vCenter
End If
End Function

Friend Sub UpdateLevelRuntimeData(ByVal dt As Single)
Dim idx As Long
Dim f As Single, f2 As Single
Dim mat As D3DMATRIX, mat1 As D3DMATRIX
Dim vBase As D3DVECTOR, vNormal As D3DVECTOR, vAxis As D3DVECTOR
Dim v As D3DVECTOR, v2 As D3DVECTOR
Dim i As Long, j As Long, k As Long
Dim p As typePolyhedronPosition
Dim nAnimType As Long
Dim b As Boolean
'///
If m_bRuntimeDirty Then Exit Sub
'////////reset?
If m_bReset Then
 CreateLevelRuntimeData m_bIsRuntime
 m_bReset = False
End If
'////////update animation
'///polyhedron animation
For idx = 1 To m_tLevel.nPolyhedronCount
 If m_tPolyInst(idx).nFlags And &H100& Then
  nAnimType = m_tPolyInst(idx).nAnimType
  Select Case nAnimType
  Case 1, 2, &H8& To &HF& 'rolling
   f = m_tPolyInst(idx).fAnimValue(0) + dt
   If f > m_fAnimTime Then
    StartPolyhedronAnimationByStack idx
    If m_tPolyInst(idx).nAnimType = 0 Then '?
     m_bPolyhedronDirty = True
     m_objPoly(idx).SendEvent EventTypeOnEnter
     m_objPoly(idx).SendEvent EventTypeOnMoveEnter
     m_objPoly(idx).SendEvent EventTypeOnHitTest
    End If
   Else
    m_tPolyInst(idx).fAnimValue(0) = f
   End If
  Case -1 'falling
   f = m_tPolyInst(idx).fAnimValue(0) + dt
   If f > 3000 Then
    StartPolyhedronAnimationByStack idx
    '///
    i = m_tPolyInst(idx).nFlags
    'hide this polyhedron
    m_tPolyInst(idx).nFlags = i And Not &H100&
    #If UndoPolyhedronAnimation Then
    #Else
    m_nUndoDirtyFlags = m_nUndoDirtyFlags Or 2&
    #End If
    If (i And &H1&) = 0 Then 'if not discardable
     'TODO:game over
     m_bGameOver = True
     If m_bAutoReset Then m_bReset = True
    End If
   Else
    m_tPolyInst(idx).fAnimValue(0) = f
   End If
  End Select
  '///
  #If UndoPolyhedronAnimation Then
  If nAnimType Then m_nUndoDirtyFlags = m_nUndoDirtyFlags Or 2&
  #Else
  If nAnimType Then m_nUndoDirtyFlags = m_nUndoDirtyFlags Or 4&
  #End If
 End If
Next idx
'////////update event (?)
ProcessMapEvents
'////////check winning condition (?)
If m_tLevel.nWinningConditionCount > 0 Then
 For idx = 1 To m_tLevel.nWinningConditionCount
  If (m_tLevel.tWinningCondition(idx).nFlags And 1&) = 0 Or Not m_nWinningConditionValue(idx) Then
   b = m_nWinningConditionValue(idx)
   '///
   Select Case m_tLevel.tWinningCondition(idx).nType
   Case 0 'logical
    i = m_tLevel.tWinningCondition(idx).nParams(2)
    j = 0
    Do While i > 0
     If m_nWinningConditionValue(i) Xor ((m_tLevel.tWinningCondition(i).nFlags And 2&) <> 0) Then
      j = j + 1
     End If
     i = m_tLevel.tWinningCondition(i).NextSibling
    Loop
    m_nWinningConditionValue(idx) = _
    j >= m_tLevel.tWinningCondition(idx).nParams(0) And _
    j <= m_tLevel.tWinningCondition(idx).nParams(1)
   Case 1 'move
    m_nWinningConditionValue(idx) = False
    For i = 0 To m_tLevel.tWinningCondition(idx).nParams(0) - 1
     j = m_tLevel.tWinningCondition(idx).nSrcIndex(i)
     If j > 0 And j <= m_tLevel.nPolyhedronCount Then
      If (m_tPolyInst(j).nFlags And &H100&) <> 0 And m_tPolyInst(j).nAnimType = 0 Then
       p = m_objPoly(j).Position
       If p.p.nMapDataIndex = m_tLevel.tWinningCondition(idx).tPos.nMapDataIndex Then
        If p.p.x = m_tLevel.tWinningCondition(idx).tPos.x Then
         If p.p.y = m_tLevel.tWinningCondition(idx).tPos.y Then
          If p.p.z = m_tLevel.tWinningCondition(idx).tPos.z Then
           m_objPoly(j).GetCurrentSize j, k
           If j = m_tLevel.tWinningCondition(idx).nParams(1) Then
            If k = m_tLevel.tWinningCondition(idx).nParams(2) Then
             m_nWinningConditionValue(idx) = True
             Exit For
            End If
           End If
          End If
         End If
        End If
       End If
      End If
     End If
    Next i
   Case 2 'checkpoint
    j = m_tLevel.nCheckPointCount - m_nCheckPointRemaining
    m_nWinningConditionValue(idx) = _
    j >= m_tLevel.tWinningCondition(idx).nParams(0) And _
    j <= m_tLevel.tWinningCondition(idx).nParams(1)
   Case 3 'game-finished event
    m_nWinningConditionValue(idx) = m_bGameFinishedEvent
   End Select
   '///
   If b <> m_nWinningConditionValue(idx) Then m_nUndoDirtyFlags = m_nUndoDirtyFlags Or 8&
  End If
 Next idx
 i = m_tLevel.nWinningConditionCount
 m_bGameFinished = m_nWinningConditionValue(i) Xor ((m_tLevel.tWinningCondition(i).nFlags And 2&) <> 0)
 m_bGameFinishedEvent = False
End If
'///tile animation
For idx = 1 To m_nTileAnimMax
 i = m_tTileAnim(idx).nInstIndex
 If i > 0 Then
  f = m_tTileAnim(idx).fAnimValue(0) + dt
  Select Case m_tTileAnim(idx).nAnimType
  Case 1 'fade out TODO:
   If f > m_fAnimTime Then
    RemoveTileAnimation idx, True
   Else
    m_tTileAnim(idx).fAnimValue(0) = f
    mat = m_tTileAnim(idx).matWorld
    f = f / m_fAnimTime
    f = 1 / (1.01 - f * f) - 1
    mat.m43 = mat.m43 - f
    m_tLevelInst.tInstance(i).matWorld = mat
   End If
  Case 2 'fade in TODO:
   If f > m_fAnimTime Then
    m_tLevelInst.tInstance(i).matWorld = m_tTileAnim(idx).matWorld
    RemoveTileAnimation idx, False
   Else
    m_tTileAnim(idx).fAnimValue(0) = f
    mat = m_tTileAnim(idx).matWorld
    f = 1 - f / m_fAnimTime
    f = 1 / (1.01 - f * f) - 1
    mat.m43 = mat.m43 - f
    m_tLevelInst.tInstance(i).matWorld = mat
   End If
  Case -1 'falling
   If f > 3000 Then
    RemoveTileAnimation idx, True
   Else
    m_tTileAnim(idx).fAnimValue(0) = f
    mat = m_tTileAnim(idx).matWorld
    f = f / 190
    mat.m43 = mat.m43 - f * f
    m_tLevelInst.tInstance(i).matWorld = mat
   End If
  End Select
  '///
  m_nUndoDirtyFlags = m_nUndoDirtyFlags Or 1&
 End If
Next idx
'///TODO:other
'////////update position
'///setup polyhedron world matrix and center
'TODO:adjacency data
'TODO:animation: tilt angle, interpolation of mat1, interpolation of vAxis and vBase, etc. <== interpolation of vAxis IS WRONG
For idx = 1 To m_tLevel.nPolyhedronCount
 If m_tPolyInst(idx).nFlags And &H100& Then
  m_tPolyInst(idx).matWorld = D3DXMatrixIdentity
  p = m_objPoly(idx).Position
  If p.p.nMapDataIndex > 0 And p.p.nMapDataIndex <= m_tLevel.nMapDataCount Then
   Select Case m_tLevel.tPolyhedron(idx).nShape
   Case &H111 To &HFFF
    nAnimType = m_tPolyInst(idx).nAnimType
    'm_objPoly(idx).GetCurrentSize i, j, k
    Select Case nAnimType
    Case &H8& To &HF&
     If nAnimType And 1& Then 'tilt rolling
      If nAnimType And 4& Then p.nGroundEdgeIndex = (p.nGroundEdgeIndex + (nAnimType And 2&) - 1) And 3&
      m_objPoly(idx).GetPolyhedronCoordinatesEx p, vBase, vNormal, vAxis
      If nAnimType And 2& Then '???????? FIXME: ugly dirty code
       p.nGroundEdgeIndex = (p.nGroundEdgeIndex - 1) And 3&
       m_objPoly(idx).GetPolyhedronCoordinatesEx p, vBase, Vec3, Vec3
       '///
       vAxis.x = -vAxis.x
       vAxis.y = -vAxis.y
       vAxis.z = -vAxis.z
       '///
       p = m_objPoly(idx).Position(True) '????????
       p.nGroundEdgeIndex = (p.nGroundEdgeIndex - 1) And 3& '????????
      End If
     Else 'tilt falling
      If nAnimType And 4& Then
       m_objPoly(idx).GetPolyhedronCoordinatesEx p, vBase, vNormal, vAxis
       f = m_objPoly(idx).PolyhedronTiltTangent
      Else 'fall to ground
       p.nGroundEdgeIndex = (p.nGroundEdgeIndex + (nAnimType And 2&) + 1) And 3&
       m_objPoly(idx).GetPolyhedronCoordinatesEx p, vBase, vNormal, vAxis
       'f = m_objPoly(idx).PolyhedronTiltTangent
       f = 0 '???????? TODO:etc.
      End If
     End If
    Case Else
     'normal rolling
     m_objPoly(idx).GetPolyhedronCoordinatesEx p, vBase, vNormal, vAxis
     f = m_objPoly(idx).PolyhedronTiltTangent
     If f > 0.000001 Then
      D3DXVec3Normalize vNormal, D3DXVec3AddScale(vNormal, D3DXVec3Cross(vNormal, vAxis), f)
     End If
    End Select
    '///
    Select Case nAnimType
    Case 1 'rolling
     m_objPoly(idx).GetPolyhedronCoordinates Vec3, v, v2, True
     f = m_objPoly(idx).PolyhedronTiltTangent(True)
     If f > 0.000001 Then
      D3DXVec3Normalize v, D3DXVec3AddScale(v, D3DXVec3Cross(v, v2), f)
     End If
     f = m_tPolyInst(idx).fAnimValue(0) / m_fAnimTime
     D3DXVec3Normalize vNormal, D3DXVec3Lerp(v, vNormal, f)
    Case &H8& To &HF&
     If nAnimType And 1& Then 'tilt rolling
      m_objPoly(idx).GetPolyhedronCoordinates Vec3, v, Vec3, True
      f = m_tPolyInst(idx).fAnimValue(0) / m_fAnimTime
      D3DXVec3Normalize vNormal, D3DXVec3Lerp(v, vNormal, f)
      '///tilt rolling
      f = m_objPoly(idx).PolyhedronTiltTangent(True)
      If f > 0.000001 Then
       f2 = 1 / Sqr(1 + f * f) 'cos
       f = f * f2 'sin
       v = D3DXVec3Cross(vAxis, vNormal)
       '---
       v2.x = vNormal.x * f2 - vAxis.x * f
       v2.y = vNormal.y * f2 - vAxis.y * f
       v2.z = vNormal.z * f2 - vAxis.z * f
       '---
       vAxis.x = vAxis.x * f2 + vNormal.x * f
       vAxis.y = vAxis.y * f2 + vNormal.y * f
       vAxis.z = vAxis.z * f2 + vNormal.z * f
       '---
       vNormal = v2
      End If
     Else 'tilt falling
      'TODO:etc.
      f = f + (m_objPoly(idx).PolyhedronTiltTangent(True) - f) * (1 - m_tPolyInst(idx).fAnimValue(0) / m_fAnimTime)
      D3DXVec3Normalize vNormal, D3DXVec3AddScale(vNormal, D3DXVec3Cross(vNormal, vAxis), f)
     End If
    End Select
    '///
    v = D3DXVec3Cross(vAxis, vNormal)
    mat.m11 = vNormal.x
    mat.m12 = vNormal.y
    mat.m13 = vNormal.z
    mat.m21 = vAxis.x
    mat.m22 = vAxis.y
    mat.m23 = vAxis.z
    mat.m31 = v.x
    mat.m32 = v.y
    mat.m33 = v.z
    mat.m41 = vBase.x
    mat.m42 = vBase.y
    mat.m43 = vBase.z
    mat.m44 = 1
    D3DXMatrixInverse mat, 0, mat
    '///
    m_objPoly(idx).GetCurrentSizeEx p, i, j, k
    With m_tLevel.tMapData(p.p.nMapDataIndex)
     mat1.m11 = -.fPos(3).x
     mat1.m12 = -.fPos(3).y
     mat1.m13 = -.fPos(3).z
     Select Case (p.nGroundEdgeIndex - p.nFirstEdgeIndex) And 3&
     Case 0
      mat1.m21 = .fPos(1).x
      mat1.m22 = .fPos(1).y
      mat1.m23 = .fPos(1).z
      mat1.m31 = .fPos(2).x
      mat1.m32 = .fPos(2).y
      mat1.m33 = .fPos(2).z
      mat1.m41 = .fPos(0).x + p.p.x * .fPos(1).x + p.p.y * .fPos(2).x + p.p.z * .fPos(3).x
      mat1.m42 = .fPos(0).y + p.p.x * .fPos(1).y + p.p.y * .fPos(2).y + p.p.z * .fPos(3).y
      mat1.m43 = .fPos(0).z + p.p.x * .fPos(1).z + p.p.y * .fPos(2).z + p.p.z * .fPos(3).z
     Case 1
      mat1.m21 = -.fPos(2).x
      mat1.m22 = -.fPos(2).y
      mat1.m23 = -.fPos(2).z
      mat1.m31 = .fPos(1).x
      mat1.m32 = .fPos(1).y
      mat1.m33 = .fPos(1).z
      mat1.m41 = .fPos(0).x + p.p.x * .fPos(1).x + (p.p.y + j) * .fPos(2).x + p.p.z * .fPos(3).x
      mat1.m42 = .fPos(0).y + p.p.x * .fPos(1).y + (p.p.y + j) * .fPos(2).y + p.p.z * .fPos(3).y
      mat1.m43 = .fPos(0).z + p.p.x * .fPos(1).z + (p.p.y + j) * .fPos(2).z + p.p.z * .fPos(3).z
     Case 2
      mat1.m21 = -.fPos(1).x
      mat1.m22 = -.fPos(1).y
      mat1.m23 = -.fPos(1).z
      mat1.m31 = -.fPos(2).x
      mat1.m32 = -.fPos(2).y
      mat1.m33 = -.fPos(2).z
      mat1.m41 = .fPos(0).x + (p.p.x + i) * .fPos(1).x + (p.p.y + j) * .fPos(2).x + p.p.z * .fPos(3).x
      mat1.m42 = .fPos(0).y + (p.p.x + i) * .fPos(1).y + (p.p.y + j) * .fPos(2).y + p.p.z * .fPos(3).y
      mat1.m43 = .fPos(0).z + (p.p.x + i) * .fPos(1).z + (p.p.y + j) * .fPos(2).z + p.p.z * .fPos(3).z
     Case 3
      mat1.m21 = .fPos(2).x
      mat1.m22 = .fPos(2).y
      mat1.m23 = .fPos(2).z
      mat1.m31 = -.fPos(1).x
      mat1.m32 = -.fPos(1).y
      mat1.m33 = -.fPos(1).z
      mat1.m41 = .fPos(0).x + (p.p.x + i) * .fPos(1).x + p.p.y * .fPos(2).x + p.p.z * .fPos(3).x
      mat1.m42 = .fPos(0).y + (p.p.x + i) * .fPos(1).y + p.p.y * .fPos(2).y + p.p.z * .fPos(3).y
      mat1.m43 = .fPos(0).z + (p.p.x + i) * .fPos(1).z + p.p.y * .fPos(2).z + p.p.z * .fPos(3).z
     End Select
     mat1.m44 = 1
    End With
    '///
    Select Case nAnimType
    Case 2 'slip
     p = m_objPoly(idx).Position(True)
     m_objPoly(idx).GetCurrentSizeEx p, i, j, k
     With m_tLevel.tMapData(p.p.nMapDataIndex)
      Select Case (p.nGroundEdgeIndex - p.nFirstEdgeIndex) And 3&
      Case 0
       v.x = .fPos(0).x + p.p.x * .fPos(1).x + p.p.y * .fPos(2).x + p.p.z * .fPos(3).x
       v.y = .fPos(0).y + p.p.x * .fPos(1).y + p.p.y * .fPos(2).y + p.p.z * .fPos(3).y
       v.z = .fPos(0).z + p.p.x * .fPos(1).z + p.p.y * .fPos(2).z + p.p.z * .fPos(3).z
      Case 1
       v.x = .fPos(0).x + p.p.x * .fPos(1).x + (p.p.y + j) * .fPos(2).x + p.p.z * .fPos(3).x
       v.y = .fPos(0).y + p.p.x * .fPos(1).y + (p.p.y + j) * .fPos(2).y + p.p.z * .fPos(3).y
       v.z = .fPos(0).z + p.p.x * .fPos(1).z + (p.p.y + j) * .fPos(2).z + p.p.z * .fPos(3).z
      Case 2
       v.x = .fPos(0).x + (p.p.x + i) * .fPos(1).x + (p.p.y + j) * .fPos(2).x + p.p.z * .fPos(3).x
       v.y = .fPos(0).y + (p.p.x + i) * .fPos(1).y + (p.p.y + j) * .fPos(2).y + p.p.z * .fPos(3).y
       v.z = .fPos(0).z + (p.p.x + i) * .fPos(1).z + (p.p.y + j) * .fPos(2).z + p.p.z * .fPos(3).z
      Case 3
       v.x = .fPos(0).x + (p.p.x + i) * .fPos(1).x + p.p.y * .fPos(2).x + p.p.z * .fPos(3).x
       v.y = .fPos(0).y + (p.p.x + i) * .fPos(1).y + p.p.y * .fPos(2).y + p.p.z * .fPos(3).y
       v.z = .fPos(0).z + (p.p.x + i) * .fPos(1).z + p.p.y * .fPos(2).z + p.p.z * .fPos(3).z
      End Select
     End With
     f = m_tPolyInst(idx).fAnimValue(0) / m_fAnimTime
     mat1.m41 = v.x + (mat1.m41 - v.x) * f
     mat1.m42 = v.y + (mat1.m42 - v.y) * f
     mat1.m43 = v.z + (mat1.m43 - v.z) * f
    End Select
    '///
    D3DXMatrixMultiply m_tPolyInst(idx).matWorld, mat, mat1
    '///get center pos
    m_objPoly(idx).GetSize i, j, k
    v.x = i / 2
    v.y = j / 2
    v.z = k / 2
    D3DXVec3TransformCoord m_tPolyInst(idx).vCenter, v, m_tPolyInst(idx).matWorld
    '///
    Select Case nAnimType
    Case -1 'falling
     f = m_tPolyInst(idx).fAnimValue(0) / 200
     f = f * f
     m_tPolyInst(idx).matWorld.m43 = m_tPolyInst(idx).matWorld.m43 - f
     'f = f / (1 + 0.01 * f)
     m_tPolyInst(idx).vCenter.z = m_tPolyInst(idx).vCenter.z - f
    End Select
   Case Else
    Debug.Assert False
   End Select
  End If
  i = m_tPolyInst(idx).nInstIndex
  If i > 0 Then
   'TODO:multiple objects
   m_tLevelInst.tInstance(i).Visible = True
   m_tLevelInst.tInstance(i).matWorld = m_tPolyInst(idx).matWorld
  End If
 Else
  'invisible
  i = m_tPolyInst(idx).nInstIndex
  If i > 0 Then
   'TODO:multiple objects
   m_tLevelInst.tInstance(i).Visible = False
   m_tLevelInst.tInstance(i).matWorld = m_tPolyInst(idx).matWorld
  End If
 End If
Next idx
'///follow polyhedron?
If m_bFollowPolyhedron Then
 If m_nCurrentPolyhedron > 0 And m_nCurrentPolyhedron <= m_tLevel.nPolyhedronCount Then
  If m_tPolyInst(m_nCurrentPolyhedron).nFlags And &H100& Then
   objCamera.MoveTargetTo m_tPolyInst(m_nCurrentPolyhedron).vCenter
  End If
 End If
End If
'///
End Sub

Friend Sub DrawLevel()
Dim idx As Long
Dim f(31) As Single
Dim d(23) As Integer
Dim i As Long, j As Long, k As Long, l As Long
Dim tmp As Long
'///
If m_bRuntimeDirty Then Exit Sub
If m_tLevel.nPolyhedronCount <= 0 Then Exit Sub
'///draw level
objEffectMgr.DrawInstanceEx m_tLevelInst, True, True
'///TEST ONLY
'///draw polyhedron which doesn't have appearance
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
 If m_tPolyInst(idx).nInstIndex = 0 And (m_tPolyInst(idx).nFlags And &H100&) <> 0 Then
  '///TEST ONLY
  '///assume it's cuboid
  m_objPoly(idx).GetSize i, j, k
  With m_tPolyInst(idx).matWorld
   For l = 0 To 7
    f(l * 4) = .m41 + _
    (i * (l And 1&)) * .m11 + _
    (j * ((l \ 2&) And 1&)) * .m21 + _
    (k * ((l \ 4&) And 1&)) * .m31
    f(l * 4 + 1) = .m42 + _
    (i * (l And 1&)) * .m12 + _
    (j * ((l \ 2&) And 1&)) * .m22 + _
    (k * ((l \ 4&) And 1&)) * .m32
    f(l * 4 + 2) = .m43 + _
    (i * (l And 1&)) * .m13 + _
    (j * ((l \ 2&) And 1&)) * .m23 + _
    (k * ((l \ 4&) And 1&)) * .m33
   Next l
  End With
  '///
  d3dd9.DrawIndexedPrimitiveUP D3DPT_LINELIST, 0, 8, 12, d(0), D3DFMT_INDEX16, f(0), 16&
  '///
 End If
Next idx
'///
d3dd9.SetTextureStageState 0, D3DTSS_COLOROP, tmp
'///
End Sub

Friend Property Get IsRuntime() As Boolean
IsRuntime = m_bIsRuntime
End Property

Friend Function CreateLevelRuntimeData(Optional ByVal bRuntime As Boolean = True) As Boolean
Dim i As Long, idx As Long
'///
ClearLevelRuntimeData
'///
m_bIsRuntime = bRuntime
m_bPolyhedronDirty = False
If Not GenerateMeshFromLevelDataEx(m_tLevel, m_tMapDataInst, m_tLevelInst, bRuntime) Then Exit Function
'///
m_nCurrentPolyhedron = 0
m_nCheckPointRemaining = m_tLevel.nCheckPointCount
'///
If m_tLevel.nWinningConditionCount > 0 Then
 ReDim m_nWinningConditionValue(1 To m_tLevel.nWinningConditionCount)
Else
 Erase m_nWinningConditionValue
End If
'///
If m_tLevel.nPolyhedronCount > 0 Then
 ReDim m_objPoly(1 To m_tLevel.nPolyhedronCount)
 ReDim m_tPolyInst(1 To m_tLevel.nPolyhedronCount)
 For i = 1 To m_tLevel.nPolyhedronCount
  If Not m_objPoly(i).CreateIndirect(m_tLevel, i) Then Exit Function
  '///
  idx = m_tLevel.tPolyhedron(i).nApprIndex
  If idx > 0 Then m_tPolyInst(i).nInstIndex = _
  objEffectMgr.AddInstanceFromAppearanceEx(m_tLevelInst, idx, D3DXMatrixIdentity)
  m_tPolyInst(i).nFlags = m_tLevel.tPolyhedron(i).nFlags
 Next i
 '///
 For i = 1 To m_tLevel.nPolyhedronCount
  If m_tPolyInst(i).nFlags And &H100& Then
   If m_nCurrentPolyhedron = 0 Then m_nCurrentPolyhedron = i
   m_objPoly(i).CheckPolyhedronStateAndResponse
  End If
 Next i
 '///
 For i = 1 To m_tLevel.nPolyhedronCount
  If m_tPolyInst(i).nFlags And &H100& Then
   m_objPoly(i).SendEvent EventTypeOnEnter
   m_objPoly(i).SendEvent EventTypeOnHitTest
  End If
 Next i
End If
'///
ProcessMapEvents
ProcessPolyhedronMerge
'///
m_bRuntimeDirty = False
CreateLevelRuntimeData = True
End Function

Friend Property Get IsGameOver() As Boolean
IsGameOver = m_bGameOver
End Property

Friend Property Get IsGameFinished() As Boolean
IsGameFinished = m_bGameFinished And Not m_bGameOver '?
End Property

Friend Sub ClearLevelRuntimeData()
Dim t As typeMeshInstanceCollection
'///
Erase m_objPoly
Erase m_tPolyInst
Erase m_tEvent
Erase m_tMapDataInst
Erase m_tTileAnim
Erase m_nWinningConditionValue
m_tLevelInst = t
m_nCurrentPolyhedron = 0
m_nEventStart = 0
m_nEventEnd = 0
m_nEventMax = 0
m_bPolyhedronDirty = False
m_nTileAnimMax = 0
m_nTileAnimFirstUnused = 0
m_bGameOver = False
m_bGameFinished = False
m_bGameFinishedEvent = False
'///
Erase m_tUndo
m_nUndoCount = 0
m_nUndoMax = 0
m_nUndoDirtyFlags = -1
'///
m_bRuntimeDirty = True
End Sub

'internal
Friend Function GetEmptyTileAnimation() As Long
Dim i As Long, m As Long
If m_nTileAnimFirstUnused = 0 Then
 m = m_nTileAnimMax + 16
 ReDim Preserve m_tTileAnim(1 To m)
 For i = m_nTileAnimMax + 2 To m - 1
  m_tTileAnim(i).nInstIndex = &H80000000 Or (i + 1)
 Next i
 GetEmptyTileAnimation = m_nTileAnimMax + 1
 m_nTileAnimMax = m
Else
 GetEmptyTileAnimation = m_nTileAnimFirstUnused
 m_nTileAnimFirstUnused = m_tTileAnim(m_nTileAnimFirstUnused).nInstIndex And &H7FFFFFFF
End If
'///
m_nUndoDirtyFlags = m_nUndoDirtyFlags Or 1&
End Function

'internal
Friend Sub RemoveTileAnimation(ByVal nIndex As Long, ByVal bRemoveInstance As Boolean)
Dim t As typeCustomTileAnimation
If nIndex > 0 And nIndex <= m_nTileAnimMax Then
 If m_tTileAnim(nIndex).nInstIndex > 0 Then
  If bRemoveInstance Then
   objEffectMgr.RemoveInstanceEx m_tLevelInst, m_tTileAnim(nIndex).nInstIndex
  End If
  t.nInstIndex = &H80000000 Or m_nTileAnimFirstUnused
  m_tTileAnim(nIndex) = t
  m_nTileAnimFirstUnused = nIndex
  '///
  m_nUndoDirtyFlags = m_nUndoDirtyFlags Or 1&
 End If
End If
End Sub

Friend Sub ClearLevelData(Optional ByVal bClearTileTypeMap As Boolean = True)
Dim t As typeLevelData
Dim i As Long
m_tLevel = t
'reset dynamic-mapped tile index
If bClearTileTypeMap Then Erase m_nTileTypeMap
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

Friend Function ParseTileTypeFromString(ByVal s As String) As Long
Dim nIndex As Long
Dim lps As Long
'///
ParseTileTypeFromString = -1
'///
If IsNumeric(s) Then
 nIndex = Val(s)
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
ElseIf s <> "" Then
 nIndex = FindTileType(s)
 If nIndex = 0 Then 'not found
  Debug.Assert False
  Exit Function
 End If
End If
ParseTileTypeFromString = nIndex
End Function

Friend Function ParseMapTypeArrayFromNode(ByVal objNode As clsTreeStorageNode, ByRef tMap As typeMapData, ByRef nCheckPointCount As Long) As Boolean
Dim s As String
Dim b As Boolean
Dim d() As Integer, lp As Long, lps As Long, m As Long
Dim C As Long
Dim i As Long, j As Long, k As Long
'///
Dim nIndex As Long
Dim sID As String
Dim nNewIndex As Long
Dim nPropertyIndex As Long
Dim sTag As String
Dim nCount As Long
'///
Dim nCheckPoint As Long
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
   C = d(lp)
   Select Case C
   Case 44, 59, 124, 64, 91, 42
    Exit Do
   End Select
   b = b And ((C >= &H30& And C <= &H39&) Or C = 45)
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
  If C = 64 Then
   lp = lp + 1
   lps = lp
   Do While lp < m
    C = d(lp)
    Select Case C
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
  If C = 91 Then
   lp = lp + 1
   lps = lp
   b = True
   Do While lp < m
    C = d(lp)
    If C = 93 Then Exit Do
    b = b And (C >= &H30& And C <= &H39&)
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
   If lp < m Then C = d(lp)
  End If
  '///get ["*"<count>]
  If C = 42 Then
   lp = lp + 1
   lps = lp
   Do While lp < m
    C = d(lp)
    Select Case C
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
   nIndex = FindTileType(sID)
   If nIndex = 0 Then 'not found
    Debug.Assert False
    Exit Function
   End If
  End If
  'create dynamic mapping index?
  If nNewIndex < 0 And nNewIndex >= -m_nTileTypeCount_Max Then
   m_nTileTypeMap(-nNewIndex) = nIndex
  End If
  '///checkpoint?
  nCheckPoint = 0
  If nIndex > 0 Then
   If m_tTileType(nIndex).nFlags And &H2& Then nCheckPoint = 1
  End If
  '///put data
  For lps = 1 To nCount
   tMap.nTypeArray(i, j, k) = nIndex
   tMap.sTagArray(i, j, k) = sTag
   tMap.nPropertyArray(i, j, k) = nPropertyIndex
   '///
   If nCheckPointCount >= 0 Then _
   nCheckPointCount = nCheckPointCount + nCheckPoint
   '///
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
  If lp >= m Then C = 44
  Select Case C
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
   If Not ParseMapTypeArrayFromNode(obj, tLevel.tMapData(nIndex), tLevel.nCheckPointCount) Then
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

Friend Function ParseMapPolyMergeDataFromNode(ByVal objNode As clsTreeStorageNode, ByRef t As typeMapData_PolyhedronMerge) As Boolean
On Error Resume Next
'///
Dim i As Long
Dim s As String
'///
For i = 1 To objNode.SubNodeCount
 If objNode.SubNodeType(i) = 0 Then
  s = Trim(objNode.GetSubNodeValueAsString(i))
  Select Case objNode.GetSubNodeNameAsString(i)
  Case "src"
   t.sSrcID = Split(Trim(objNode.GetSubNodeValueAsString(i)), ",")
   t.nSrcCount = UBound(t.sSrcID) + 1
  Case "dest"
   t.sDestID = Trim(objNode.GetSubNodeValueAsString(i))
  End Select
 Else
  'TODO:
 End If
Next i
'///
ParseMapPolyMergeDataFromNode = True
End Function

Friend Function ParseMapPolyhedronDataFromNode(ByVal objNode As clsTreeStorageNode, ByRef tPoly As typeMapData_Polyhedron, Optional ByVal sBasePosition As String) As Boolean
Dim i As Long, j As Long, k As Long
Dim s As String
Dim obj As clsTreeStorageNode
Dim nFlags As Long
Dim nSizeX As Single, nSizeY As Single, nSizeZ As Single
Dim bAutoSize As Boolean
'///
nFlags = &H1FE&
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
    s = Replace(s, ",", "*")
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
  Case "autoSize"
   bAutoSize = pFlagsFromBooleanString(s, 0, 1)
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
  Case "visible"
   nFlags = pFlagsFromBooleanString(s, nFlags, &H100&)
  End Select
 Else
  'etc.
  Set obj = objNode.SubNodeObject(i)
  s = obj.GetNameAsString
  Select Case s
  Case "appearance"
   nSizeX = 1
   nSizeY = 1
   nSizeZ = 1
   If bAutoSize Then
    Select Case tPoly.nShape
    Case &H111 To &HFFF
     'new: default size
     nSizeX = (tPoly.nShape And &HF00&) \ &H100&
     nSizeY = (tPoly.nShape And &HF0&) \ &H10&
     nSizeZ = tPoly.nShape And &HF&
    Case Else
     '??? TODO:
    End Select
   End If
   tPoly.nApprIndex = objEffectMgr.AddAppearanceFromNode(obj, nSizeX, nSizeY, nSizeZ)
  Case Else
   'new: polyhedron event
   j = ParseEventType(s)
   If j > 0 Then
    tPoly.nEventCount = tPoly.nEventCount + 1
    ReDim Preserve tPoly.tEvent(1 To tPoly.nEventCount)
    If Not ParseEventFromNode(tPoly.tEvent(tPoly.nEventCount), obj, j) Then Exit Function
   End If
  End Select
 End If
Next i
'///over
tPoly.nFlags = nFlags
ParseMapPolyhedronDataFromNode = True
End Function

'<=0: failed
'>0 : winning condition node index
Friend Function ParseWinningConditionFromNode(ByVal objNode As clsTreeStorageNode, ByRef tLevel As typeLevelData) As Long
Dim i As Long, j As Long, k As Long, m As Long, n As Long
Dim v As Variant
Dim s As String
Dim t As typeMapData_WinningCondition
'///
Select Case objNode.GetNameAsString
Case "winningCondition"
 t.nType = 0
 t.nParams(0) = &H80000000
 t.nParams(1) = &H80000000
Case "moveCondition"
 t.nType = 1
 t.nParams(1) = 1
 t.nParams(2) = 1
Case "checkpointCondition"
 t.nType = 2
 t.nParams(0) = &H80000000
 t.nParams(1) = &H80000000
Case "gameFinishedCondition"
 t.nType = 3
Case Else
 Debug.Assert False
 Exit Function
End Select
'///get attributes
m = objNode.SubNodeCount
For i = 1 To m
 If objNode.SubNodeType(i) = 0 Then
  s = objNode.GetSubNodeValueAsString(i)
  Select Case objNode.GetSubNodeNameAsString(i)
  Case "persistent"
   t.nFlags = pFlagsFromBooleanString(s, t.nFlags, &H1&)
  Case "invert"
   t.nFlags = pFlagsFromBooleanString(s, t.nFlags, &H2&)
  Case "src"
   If t.nType = 1 Then
    On Error Resume Next
    Err.Clear
    v = Split(s, "|")
    t.nParams(0) = UBound(v) + 1
    If Err.Number Then t.nParams(0) = 0
    On Error GoTo 0
    '///
    If t.nParams(0) > 0 Then
     ReDim t.nSrcIndex(t.nParams(0) - 1)
     For j = 0 To t.nParams(0) - 1
      t.nSrcIndex(j) = FindPolyhedron(Trim(v(j)))
      If t.nSrcIndex(j) = 0 Then
       Debug.Assert False
       Exit Function
      End If
     Next j
    End If
   Else
    Debug.Assert False
    Exit Function
   End If
  Case "target"
   If t.nType = 1 Then
    If Not FindPosition(s, t.tPos) Then
     Debug.Assert False
     Exit Function
    End If
   Else
    Debug.Assert False
    Exit Function
   End If
  Case "targetSize"
   If t.nType = 1 Then
    s = Replace(s, "x", ",")
    s = Replace(s, "X", ",")
    s = Replace(s, "*", ",")
    j = InStr(1, s, ",")
    If j > 0 Then
     t.nParams(1) = Val(Left(s, j - 1))
     t.nParams(2) = Val(Mid(s, j + 1))
    Else
     t.nParams(1) = Val(s)
     t.nParams(2) = 1
    End If
   Else
    Debug.Assert False
    Exit Function
   End If
  Case "count"
   If t.nType = 0 Or t.nType = 2 Then
    s = Trim(s)
    j = InStr(1, s, "~")
    '///
    If j = 1 Then
     t.nParams(0) = 0
    Else
     If Left(s, 1) = "-" Then t.nParams(0) = &H80000000 Or Val(Mid(s, 2)) _
     Else t.nParams(0) = Val(s)
    End If
    '///
    If j > 0 Then
     s = Trim(Mid(s, j + 1))
     If s = vbNullString Then
      t.nParams(1) = &H7FFFFFFF
     Else
      If Left(s, 1) = "-" Then t.nParams(1) = &H80000000 Or Val(Mid(s, 2)) _
      Else t.nParams(1) = Val(s)
     End If
    Else
     t.nParams(1) = t.nParams(0)
    End If
   Else
    Debug.Assert False
    Exit Function
   End If
  Case Else
   Debug.Assert False
   Exit Function
  End Select
 End If
Next i
'///get subnodes
If t.nType = 0 Then
 j = 0
 n = 0
 For i = 1 To m
  If objNode.SubNodeType(i) Then
   k = ParseWinningConditionFromNode(objNode.SubNodeObject(i), tLevel)
   If k = 0 Then Exit Function
   '///
   If j = 0 Then t.nParams(2) = k _
   Else tLevel.tWinningCondition(j).NextSibling = k
   j = k
   '///
   n = n + 1
  End If
 Next i
 If t.nParams(0) And &H80000000 Then t.nParams(0) = n - (t.nParams(0) And &H7FFFFFFF)
 If t.nParams(1) And &H80000000 Then t.nParams(1) = n - (t.nParams(1) And &H7FFFFFFF)
ElseIf t.nType = 2 Then
 n = tLevel.nCheckPointCount And &H7FFFFFFF
 If t.nParams(0) And &H80000000 Then t.nParams(0) = n - (t.nParams(0) And &H7FFFFFFF)
 If t.nParams(1) And &H80000000 Then t.nParams(1) = n - (t.nParams(1) And &H7FFFFFFF)
End If
'///over
i = tLevel.nWinningConditionCount + 1
tLevel.nWinningConditionCount = i
ReDim Preserve tLevel.tWinningCondition(1 To i)
tLevel.tWinningCondition(i) = t
ParseWinningConditionFromNode = i
End Function

Friend Function AddLevelDataFromNodeEx(ByVal objNode As clsTreeStorageNode, ByRef tLevel As typeLevelData) As Boolean
Dim i As Long
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
  'TODO:other
  Select Case objNode.GetSubNodeNameAsString(i)
  Case "checkpointCount"
   tLevel.nCheckPointCount = Val(objNode.GetSubNodeValueAsString(i)) Or &H80000000
  End Select
 Else
  Set obj = objNode.SubNodeObject(i)
  Select Case obj.GetNameAsString
  Case "name"
   tLevel.sName = obj.GetValueAsString
  Case "mapData"
   tLevel.nMapDataCount = tLevel.nMapDataCount + 1
   ReDim Preserve tLevel.tMapData(1 To tLevel.nMapDataCount)
   If Not ParseMapDataFromNode(obj, tLevel, tLevel.nMapDataCount) Then Exit Function
  Case "polyhedron"
   tLevel.nPolyhedronCount = tLevel.nPolyhedronCount + 1
   ReDim Preserve tLevel.tPolyhedron(1 To tLevel.nPolyhedronCount)
   If Not ParseMapPolyhedronDataFromNode(obj, tLevel.tPolyhedron(tLevel.nPolyhedronCount)) Then Exit Function
  Case "tileMapping"
   If Not ParseTileMapping(obj) Then Exit Function
  Case "polyhedronMerge"
   tLevel.nPolyMergeCount = tLevel.nPolyMergeCount + 1
   ReDim Preserve tLevel.tPolyMerge(1 To tLevel.nPolyMergeCount)
   If Not ParseMapPolyMergeDataFromNode(obj, tLevel.tPolyMerge(tLevel.nPolyMergeCount)) Then Exit Function
  Case "winningCondition"
   tLevel.nWinningConditionCount = 0
   Erase tLevel.tWinningCondition
   If ParseWinningConditionFromNode(obj, tLevel) <= 0 Then Exit Function
  '///new: use with data level support
  Case "objectType"
   If AddObjectTypeFromNode(obj) = 0 Then Exit Function
  Case "tileType"
   If AddTileTypeFromNode(obj) = 0 Then Exit Function
  End Select
 End If
Next i
'///
tLevel.nCheckPointCount = tLevel.nCheckPointCount And &H7FFFFFFF
'///
AddLevelDataFromNodeEx = True
End Function

Friend Function ParseTileMapping(ByVal objNode As clsTreeStorageNode) As Boolean
Dim j As Long, k As Long
Dim s As String
'///
s = objNode.GetSubNodeValueAsStringByName("id")
If s <> "" Then
 k = -Val(objNode.GetSubNodeValueAsStringByName("index"))
 If k > 0 And k <= m_nTileTypeCount_Max Then
  j = FindTileType(s)
  If j > 0 Then m_nTileTypeMap(k) = j
 End If
End If
'///
ParseTileMapping = True
End Function

Friend Function LoadLevelCollectionFromNode(ByVal objNode As clsTreeStorageNode, ByRef nLevelCount As Long, ByRef objLevels() As clsTreeStorageNode, Optional ByRef sName As String) As Boolean
Dim i As Long
Dim obj As clsTreeStorageNode
Dim m As Long
'///
Erase objLevels
nLevelCount = 0
'///
Select Case objNode.GetNameAsString
Case "levelCollection"
Case Else
 Exit Function
End Select
'///
For i = 1 To objNode.SubNodeCount
 If objNode.SubNodeType(i) = 0 Then
'  'TODO:other
'  Select Case objNode.GetSubNodeNameAsString(i)
'  Case "name"
'   sName = objNode.GetSubNodeValueAsString(i)
'  End Select
 Else
  Set obj = objNode.SubNodeObject(i)
  Select Case obj.GetNameAsString
  Case "name"
   sName = obj.GetValueAsString
  Case "tileMapping"
   If Not ParseTileMapping(obj) Then Exit Function
  Case "level"
   nLevelCount = nLevelCount + 1
   If nLevelCount > m Then
    m = m + 16&
    ReDim Preserve objLevels(1 To m)
   End If
   Set objLevels(nLevelCount) = obj
  '///new: use with data level support
  Case "objectType"
   If AddObjectTypeFromNode(obj) = 0 Then Exit Function
  Case "tileType"
   If AddTileTypeFromNode(obj) = 0 Then Exit Function
  End Select
 End If
Next i
'///
LoadLevelCollectionFromNode = True
End Function

'Friend Function GenerateMeshFromLevelData(ByRef tMapDataInst() As typeMapDataRuntime, ByRef tInst As typeMeshInstanceCollection, Optional ByVal bRuntime As Boolean = True) As Boolean
'GenerateMeshFromLevelData = GenerateMeshFromLevelDataEx(m_tLevel, tMapDataInst, tInst, bRuntime)
'End Function

Friend Function GenerateMeshFromLevelDataEx(ByRef tLevel As typeLevelData, ByRef tMapDataInst() As typeMapDataRuntime, ByRef tInst As typeMeshInstanceCollection, Optional ByVal bRuntime As Boolean = True) As Boolean
Dim idx As Long
Dim i As Long, j As Long, k As Long
Dim mat As D3DMATRIX, mat1 As D3DMATRIX, mat2 As D3DMATRIX
Dim nIndex As Long
'///
If tLevel.nMapDataCount > 0 Then
 ReDim tMapDataInst(1 To tLevel.nMapDataCount)
Else
 Erase tMapDataInst
End If
'///
For idx = 1 To tLevel.nMapDataCount
 '///
 ReDim tMapDataInst(idx).nTypeArray(tLevel.tMapData(idx).nSize(0) - 1, _
 tLevel.tMapData(idx).nSize(1) - 1, tLevel.tMapData(idx).nSize(2) - 1)
 ReDim tMapDataInst(idx).nInstIndex(tLevel.tMapData(idx).nSize(0) - 1, _
 tLevel.tMapData(idx).nSize(1) - 1, tLevel.tMapData(idx).nSize(2) - 1)
 '///
 Select Case tLevel.tMapData(idx).nFlags And &HF&
 Case 0 'rect
  mat = tLevel.tMapData(idx).matWorld
  For k = 0 To tLevel.tMapData(idx).nSize(2) - 1
   mat1 = mat
   For j = 0 To tLevel.tMapData(idx).nSize(1) - 1
    mat2 = mat1
    For i = 0 To tLevel.tMapData(idx).nSize(0) - 1
     nIndex = tLevel.tMapData(idx).nTypeArray(i, j, k)
     tMapDataInst(idx).nTypeArray(i, j, k) = nIndex
     If nIndex > 0 And nIndex <= m_nTileTypeMax Then
      'invisibleAtRuntime (?)
      If (bRuntime And m_tTileType(nIndex).nFlags And 1&) = 0 Then
       tMapDataInst(idx).nInstIndex(i, j, k) = objEffectMgr.AddInstanceFromAppearanceEx(tInst, m_tTileType(nIndex).nApprIndex, mat2)
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
'///
m_nDataLevel = 0
Erase m_tDataLevelArray
m_nDataLevelCount = 0
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

Friend Function FindObjectType(ByRef sName As String) As Long
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

Friend Function FindTileType(ByRef sID As String) As Long
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
Case "blocked"
 t.nType = 4
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
 ParseEventType = EventTypeOnEnter
Case "onLeave"
 ParseEventType = EventTypeOnLeave
Case "onMoveEnter"
 ParseEventType = EventTypeOnMoveEnter
Case "onMoveLeave"
 ParseEventType = EventTypeOnMoveLeave
Case "onPressKey"
 ParseEventType = EventTypeOnPressKey
Case "onCustomEvent", "onTriggeredEvent", "onEvent"
 ParseEventType = EventTypeOnCustomEvent
Case "onHitTest"
 ParseEventType = EventTypeOnHitTest
End Select
End Function

'internal
Friend Function ParseEventFromNode(ByRef ret As typeTileEvent, ByVal objNode As clsTreeStorageNode, ByVal nEventType As Long) As Boolean
On Error Resume Next
Dim v As Variant, m As Long
Dim s As String, s1 As String
Dim i As Long, ii As Long, j As Long
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
i = 0
For ii = 1 To ret.nConditionCount
 s = Trim(v(ii - 1))
 If s <> "" Then
  i = i + 1
  lps = InStr(1, s, "=")
  If lps > 0 Then
   s1 = Trim(Mid(s, lps + 1))
   If Mid(s, lps - 1, 1) = "!" Then
    nCompareType = 1
    lps = lps - 1
   End If
  Else
   lps = InStr(1, s, "~")
   If lps > 0 Then
    s1 = Trim(Mid(s, lps + 1))
    If Mid(s, lps - 1, 1) = "!" Then
     nCompareType = 3
     lps = lps - 1
    Else
     nCompareType = 2
    End If
   Else
    Debug.Assert False
    Exit Function
   End If
  End If
  '///
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
  Case "eventType", "eventIndex"
   nType = 4
   nDataType = 3
  Case "tileTypeCount"
   nType = 5
   nDataType = 2
  Case "objectTypeCount"
   nType = 6
   nDataType = 2
  Case "checkpoint", "checkpointCount"
   nType = 7
   nDataType = 2
  Case "checkpointRemaining"
   nType = 8
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
  Case "objectID"
   nType = &H122
   nDataType = 3
  Case "tileType"
   nType = &H1001
   nDataType = 3
  Case "objectTypeContains"
   nType = &H1002
   nDataType = 3
  Case "tileTypeContains"
   nType = &H1003
   nDataType = 3
  Case "target"
   nType = &H1004
   nDataType = 3
  Case "targetSize"
   nType = &H1005
   nDataType = 3
  Case Else
   Debug.Assert False
   Exit Function
  End Select
  '///
  If nDataType <> 3 Then
   nCompareType = nCompareType And 1&
  End If
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
 End If
Next ii
ret.nConditionCount = i
'///process events
v = Split(Trim(objNode.GetSubNodeValueAsStringByName("event")), ";")
ret.nEventCount = UBound(v) + 1
If ret.nEventCount > 0 Then ReDim ret.tEvent(1 To ret.nEventCount)
i = 0
For ii = 1 To ret.nEventCount
 s = Trim(v(ii - 1))
 If s <> "" Then
  i = i + 1
  lps = InStr(1, s, ":")
  If lps > 0 Then
   s1 = Trim(Mid(s, lps + 1))
   s = Trim(Left(s, lps - 1))
  Else
   s1 = vbNullString
  End If
  '///
  Select Case s
  Case "event", "sendEvent", "triggerEvent"
   nType = 1
   ret.tEvent(i).sStringParam = Split(s1, ":")
   ret.tEvent(i).nStringParamCount = UBound(ret.tEvent(i).sStringParam) + 1
  Case "teleport"
   nType = 3
   ret.tEvent(i).sStringParam = Split(s1, ":")
   ret.tEvent(i).nStringParamCount = UBound(ret.tEvent(i).sStringParam) + 1
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
 End If
Next ii
ret.nEventCount = i
'///over
ParseEventFromNode = True
End Function

'internal
Friend Function AddTileTypeFromNode(ByVal objNode As clsTreeStorageNode) As Long
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
 '///new: tile mapping when creating tile type
 If i < 0 And i >= -m_nTileTypeCount_Max Then
  m_nTileTypeMap(-i) = nIndex
 End If
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
   m_tTileType(nIndex).nApprIndex = objEffectMgr.AddAppearanceFromNode(obj)
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

Friend Sub LoadTileTypesFromSubNodes(ByVal objNode As clsTreeStorageNode)
Dim i As Long
Dim obj As clsTreeStorageNode
For i = 1 To objNode.SubNodeCount
 Set obj = objNode.SubNodeObject(i)
 If Not obj Is Nothing Then AddTileTypeFromNode obj
Next i
End Sub

'TODO:adjacency
Friend Function IsOtherPolyhedronOn(ByVal nPolyhedronIndex As Long) As Boolean
Dim idx As Long
Dim i1 As Long, j1 As Long, k1 As Long, p1 As typePolyhedronPosition
Dim i2 As Long, j2 As Long, k2 As Long, p2 As typePolyhedronPosition
Dim tState As typePolyhedronState
Select Case m_tLevel.tPolyhedron(nPolyhedronIndex).nShape
Case &H111 To &HFFF
 tState = m_objPoly(nPolyhedronIndex).PolyhedronState
 If tState.nTiltY = 0 Then
  m_objPoly(nPolyhedronIndex).GetCurrentSize i1, j1, k1
  p1 = m_objPoly(nPolyhedronIndex).Position
  For idx = 1 To m_tLevel.nPolyhedronCount
   If idx <> nPolyhedronIndex And (m_tPolyInst(idx).nFlags And &H100&) <> 0 Then
    Select Case m_tLevel.tPolyhedron(idx).nShape
    Case &H111 To &HFFF
     m_objPoly(idx).GetCurrentSize i2, j2, k2
     p2 = m_objPoly(idx).Position
     tState = m_objPoly(idx).PolyhedronState
     '///
     If p1.p.nMapDataIndex = p2.p.nMapDataIndex Then
      If p2.p.x > p1.p.x - i2 And p2.p.x < p1.p.x + i1 Then
       If p2.p.y > p1.p.y - j2 And p2.p.y < p1.p.y + j1 Then
        If tState.nTiltY > 0 Then
         'TODO:??? still some bugs
         If p2.p.z > p1.p.z - tState.nTiltY And p2.p.z <= p1.p.z + k1 Then
          IsOtherPolyhedronOn = True
          Exit Function
         End If
        Else
         If p2.p.z = p1.p.z + k1 Then
          IsOtherPolyhedronOn = True
          Exit Function
         End If
        End If
       End If
      End If
     End If
     '///
    End Select
   End If
  Next idx
 End If
Case Else
 'TODO:
 Debug.Assert False
End Select
End Function

Friend Function GetAdjacentPosition(ByRef tPos As typeMapPosition, ByVal nDirection As Long, ByRef tNewPos As typeMapPosition, Optional ByRef nNewDirection As Long) As Boolean
tNewPos = tPos
GetAdjacentPosition = GetAdjacentPositionInPlace(tNewPos, nDirection, nNewDirection)
End Function

Friend Function GetAdjacentPositionInPlaceIfValid(ByRef tPos As typeMapPosition, ByVal nDirection As Long, Optional ByRef nNewDirection As Long) As Boolean
Dim p As typeMapPosition
p = tPos
If Not GetAdjacentPositionInPlace(p, nDirection, nNewDirection) Then Exit Function
'///
If p.nMapDataIndex > 0 And p.nMapDataIndex <= m_tLevel.nMapDataCount Then
 If p.x >= 0 And p.x < m_tLevel.tMapData(p.nMapDataIndex).nSize(0) Then
  If p.y >= 0 And p.y < m_tLevel.tMapData(p.nMapDataIndex).nSize(1) Then
   If p.z >= 0 And p.z < m_tLevel.tMapData(p.nMapDataIndex).nSize(2) Then
    tPos = p
    GetAdjacentPositionInPlaceIfValid = True
   End If
  End If
 End If
End If
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
Friend Function GetAdjacentPositionInPlace(ByRef tPos As typeMapPosition, ByVal nDirection As Long, Optional ByRef nNewDirection As Long) As Boolean
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

Friend Function IsPositionInMapData(ByRef tPos As typeMapPosition) As Boolean
Dim idx As Long
idx = tPos.nMapDataIndex
If idx > 0 And idx <= m_tLevel.nMapDataCount Then
 If tPos.x >= 0 And tPos.x < m_tLevel.tMapData(idx).nSize(0) Then
  If tPos.y >= 0 And tPos.y < m_tLevel.tMapData(idx).nSize(1) Then
   If tPos.z >= 0 And tPos.z < m_tLevel.tMapData(idx).nSize(2) Then
    IsPositionInMapData = True
   End If
  End If
 End If
End If
End Function

'return value:
'-1: invalid position
Friend Function GetMapDataIndirect(ByRef tPos As typeMapPosition) As Long
Dim idx As Long
idx = tPos.nMapDataIndex
GetMapDataIndirect = -1
If idx > 0 And idx <= m_tLevel.nMapDataCount Then
 If tPos.x >= 0 And tPos.x < m_tLevel.tMapData(idx).nSize(0) Then
  If tPos.y >= 0 And tPos.y < m_tLevel.tMapData(idx).nSize(1) Then
   If tPos.z >= 0 And tPos.z < m_tLevel.tMapData(idx).nSize(2) Then
    'If m_bRuntimeDirty Then
    ' GetMapDataIndirect = m_tLevel.tMapData(idx).nTypeArray(tPos.x, tPos.y, tPos.z)
    'Else
     GetMapDataIndirect = m_tMapDataInst(tPos.nMapDataIndex).nTypeArray(tPos.x, tPos.y, tPos.z)
    'End If
   End If
  End If
 End If
End If
End Function

Friend Sub HitTest(ByRef tPos As typeMapPosition, ByRef ret As typeMapDataHitTest, ByRef ret2 As typePolyhedronState, ByVal nExcludePolyhedronIndex As Long, ByVal nHeight As Long, ByVal nHeight2 As Long, ByVal nRawHeight As Long, ByVal bCalculateHitTestPos As Boolean)
Dim idx As Long
Dim i As Long, j As Long, k As Long
Dim sz As Long, ez As Long
Dim p As typeMapPosition
Dim tState As typePolyhedronState
'///
ret.nType = -1
ret.nTileType = 0
ret.nObjType = 0
'///check if it's on some polyhedron
For idx = 1 To m_tLevel.nPolyhedronCount
 If idx <> nExcludePolyhedronIndex And (m_tPolyInst(idx).nFlags And &H100&) <> 0 Then
  'TODO: if it's not a supporter then there should be some event
  Select Case m_tLevel.tPolyhedron(idx).nShape
  Case &H111 To &HFFF
   m_objPoly(idx).GetCurrentSize i, j, k
   p = m_objPoly(idx).Position.p
   tState = m_objPoly(idx).PolyhedronState
   '///
   'TODO: wrong code if there are adjacency data
   'TODO: COMPLETELY WRONG CODE --> should combine to the tile checking
   If p.nMapDataIndex = tPos.nMapDataIndex Then
    If tPos.x >= p.x And tPos.x < p.x + i Then
     If tPos.y >= p.y And tPos.y < p.y + j Then
      If tPos.z > p.z - nHeight And tPos.z < p.z + k Then '???
       If tState.nTiltY > 0 Then
        ret.nType = &H80010000 Or k 'WRONG
       Else
        If tPos.z > p.z Then k = p.z + k - tPos.z 'WRONG
        If m_tPolyInst(idx).nFlags And &H40& Then ret.nType = &H80000000 Or k _
        Else ret.nType = &H80010000 Or k
       End If
       ret.nTileType = &H80000000 Or idx
       ret.nObjType = m_tLevel.tPolyhedron(idx).nObjType
       Exit Sub
      ElseIf tPos.z = p.z + k And (m_tPolyInst(idx).nFlags And &H10&) <> 0 And tState.nTiltY = 0 Then
       If ret.nType < 0 Then
        ret.nType = 0
        ret.nTileType = &H80000000 Or idx
        ret.nObjType = m_tLevel.tPolyhedron(idx).nObjType
       End If
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
 If tPos.x >= 0 And tPos.x < m_tLevel.tMapData(idx).nSize(0) Then
  If tPos.y >= 0 And tPos.y < m_tLevel.tMapData(idx).nSize(1) Then
   p = tPos
   k = 0
   For i = 1 To nHeight
    If Not GetAdjacentPositionInPlaceIfValid(p, 7) Then Exit For
    k = k + 1
   Next i
   '///
   Do While k > -256 'max iteration
    i = GetMapDataIndirect(p)
    If i < 0 Then Exit Do
    '///
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
     If nHeight > sz And sz < ez And ez > 0 Then 'blocked
      If ez > nHeight Then ez = nHeight
      If (j And &H200&) = 0 Then ret.nType = &H80000000 Or ez _
      Else ret.nType = &H80010000 Or ez
      ret.nTileType = i
      ret.nObjType = m_tTileType(i).nObjType
      Exit Sub
     ElseIf ez = 0 And (j And &H400&) = 0 Then 'supported
      If ret.nType < 0 Then
       ret.nType = 0
       ret.nTileType = i
       ret.nObjType = m_tTileType(i).nObjType
      End If
     End If
     '///???
     If k > 0 And k <= nRawHeight And bCalculateHitTestPos Then
      ret2.nHitTestCount = ret2.nHitTestCount + 1
      ReDim Preserve ret2.tHitTestPos(1 To ret2.nHitTestCount)
      ret2.tHitTestPos(ret2.nHitTestCount) = p
     End If
     '///
    End If
    '///
    GetAdjacentPositionInPlace p, 6
    k = k - 1
   Loop
   Debug.Assert k > -256
  End If
 End If
End If
End Sub

Friend Function FindPolyhedron(ByRef s As String) As Long
Dim i As Long
For i = 1 To m_tLevel.nPolyhedronCount
 If m_tLevel.tPolyhedron(i).sID = s Then
  FindPolyhedron = i
  Exit Function
 End If
Next i
End Function

Friend Function FindMapData(ByRef s As String) As Long
Dim i As Long
For i = 1 To m_tLevel.nMapDataCount
 If m_tLevel.tMapData(i).sID = s Then
  FindMapData = i
  Exit Function
 End If
Next i
End Function

Friend Function FindPosition(ByRef s As String, ByRef ret As typeMapPosition) As Boolean
FindPosition = FindPositionEx(m_tLevel, s, ret)
End Function

Friend Function FindPositionEx(ByRef tLevel As typeLevelData, ByVal s As String, ByRef ret As typeMapPosition) As Boolean
Dim s1 As String
Dim i As Long, j As Long, k As Long
Dim idx As Long
'///
i = InStr(1, s, "(")
If i > 0 Then
 s1 = Mid(s, i + 1)
 s = Left(s, i - 1)
Else
 i = InStr(1, s, ".")
 If i > 0 Then
  s1 = Mid(s, i + 1)
  s = Left(s, i - 1)
  i = -1
 End If
End If
idx = Val(s)
If idx <= 0 Or idx > tLevel.nMapDataCount Then
 idx = FindMapData(s)
 If idx = 0 Then Exit Function
End If
ret.nMapDataIndex = idx
ret.x = 0
ret.y = 0
ret.z = 0
If i > 0 Then
 ret.x = Val(s1) 'FIXME: no sanity check :-3
 i = InStr(1, s1, ",")
 If i > 0 Then
  ret.y = Val(Mid(s1, i + 1))
  i = InStr(i + 1, s1, ",")
  If i > 0 Then
   ret.z = Val(Mid(s1, i + 1))
  End If
 End If
ElseIf i < 0 Then
 Do
  For k = 0 To tLevel.tMapData(idx).nSize(2) - 1
   For j = 0 To tLevel.tMapData(idx).nSize(1) - 1
    For i = 0 To tLevel.tMapData(idx).nSize(0) - 1
     If tLevel.tMapData(idx).sTagArray(i, j, k) = s1 Then
      ret.x = i
      ret.y = j
      ret.z = k
      Exit Do
     End If
    Next i
   Next j
  Next k
  '///not found
  Exit Function
 Loop While False
End If
'///over
FindPositionEx = True
End Function

Friend Sub DispatchTileEvent(ByRef t As typeMapDataEvent, ByRef tEvent As typeTileEventAction)
Dim tNew As typeMapDataEvent
Dim mat As D3DMATRIX
Dim p As typePolyhedronPosition
'///
Dim ps() As typeMapPosition
Dim idx As Long, m As Long
'///
Dim i As Long, j As Long, k As Long, l As Long
Dim s As String
'///
Select Case tEvent.nType
Case 1 'custom event
 If tEvent.nStringParamCount > 1 Then
  tNew = t
  Erase tNew.tOnGroundPos, tNew.nTileTypes, tNew.nObjTypes
  tNew.nEventType = EventTypeOnCustomEvent
  tNew.sEventType = tEvent.sStringParam(0)
  For i = 1 To tEvent.nStringParamCount - 1
   tNew.p = t.p
   AddMapEventFromPositionString tNew, tEvent.sStringParam(i)
  Next i
 ElseIf tEvent.nStringParamCount > 0 Then
  tNew = t
  Erase tNew.tOnGroundPos, tNew.nTileTypes, tNew.nObjTypes
  tNew.nEventType = EventTypeOnCustomEvent
  tNew.sEventType = tEvent.sStringParam(0)
  If t.nEventType And &H1000000 Then
   For i = 1 To t.nOnGroundCount
    tNew.p = t.tOnGroundPos(i)
    AddMapEvent tNew
   Next i
  Else
   AddMapEventFromPositionString tNew, vbNullString
  End If
 End If
Case 3 'teleport
 'TODO:animation
 If tEvent.nStringParamCount > 0 And _
 t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
  objCamera.RealLinearDamping = 1
  '///
  m_nUndoDirtyFlags = m_nUndoDirtyFlags Or 2&
  m_bPolyhedronDirty = True
  '///
  For i = 0 To tEvent.nStringParamCount - 1
   s = tEvent.sStringParam(i)
   j = InStr(1, s, "@")
   If j = 0 Then
    If i = 0 Then
     'move current polyhedron to new pos
     m_objPoly(t.nPolyhedronIndex).SendEvent EventTypeOnLeave
     If m_objPoly(t.nPolyhedronIndex).SetPositionFromString(s, m_tLevel) Then
      m_objPoly(t.nPolyhedronIndex).CheckPolyhedronStateAndResponse '???
      m_objPoly(t.nPolyhedronIndex).SendEvent EventTypeOnEnter
      m_objPoly(t.nPolyhedronIndex).SendEvent EventTypeOnHitTest
     Else
      Debug.Assert False
     End If
    Else
     Debug.Assert False
    End If
    Exit Sub
   End If
   'show new polyhedron
   k = FindPolyhedron(Left(s, j - 1))
   If k = 0 Then
    Debug.Assert False
    Exit Sub
   End If
   If m_tPolyInst(k).nFlags And &H100& Then '??? err???
    Debug.Assert False
    m_objPoly(k).SendEvent EventTypeOnLeave
   Else
    m_tPolyInst(k).nFlags = m_tPolyInst(k).nFlags Or &H100&
   End If
   If m_objPoly(k).SetPositionFromString(Mid(tEvent.sStringParam(i), j + 1), m_tLevel) Then
    m_objPoly(k).CheckPolyhedronStateAndResponse '???
    m_objPoly(k).SendEvent EventTypeOnEnter
    m_objPoly(k).SendEvent EventTypeOnHitTest
   Else
    Debug.Assert False
    Exit Sub
   End If
   'set current polyhedron to new one
   If i = 0 Then m_nCurrentPolyhedron = k
  Next i
  '///hide old polyhedron (???)
  m_tPolyInst(t.nPolyhedronIndex).nFlags = _
  m_tPolyInst(t.nPolyhedronIndex).nFlags And Not &H100&
 End If
Case 4 'convertTo
 If tEvent.nStringParamCount < 1 Then Exit Sub
 If t.nEventType And &H1000000 Then
  m = t.nOnGroundCount
  ps = t.tOnGroundPos
 Else
  m = 1
  ReDim ps(1 To 1)
  ps(1) = t.p
 End If
 '///
 j = ParseTileTypeFromString(tEvent.sStringParam(0))
 If j < 0 Then Exit Sub
 '///
 For idx = 1 To m
  i = GetMapDataIndirect(ps(idx))
  If i >= 0 And i <> j Then
   m_bPolyhedronDirty = True
   m_nUndoDirtyFlags = m_nUndoDirtyFlags Or 1&
   '///
   k = m_tMapDataInst(ps(idx).nMapDataIndex).nInstIndex(ps(idx).x, ps(idx).y, ps(idx).z)
   If k > 0 Then
    'TODO:correct animation
    StartTileAnimation k, 1
   End If
   k = 0
   If j > 0 Then
    If (m_bIsRuntime And m_tTileType(j).nFlags And 1&) = 0 Then
     'TODO:correct animation
     With m_tLevel.tMapData(ps(idx).nMapDataIndex)
      mat = .matWorld
      mat.m41 = mat.m41 + ps(idx).x * .fPos(1).x + ps(idx).y * .fPos(2).x + ps(idx).z * .fPos(3).x
      mat.m42 = mat.m42 + ps(idx).x * .fPos(1).y + ps(idx).y * .fPos(2).y + ps(idx).z * .fPos(3).y
      mat.m43 = mat.m43 + ps(idx).x * .fPos(1).z + ps(idx).y * .fPos(2).z + ps(idx).z * .fPos(3).z
     End With
     k = objEffectMgr.AddInstanceFromAppearanceEx(m_tLevelInst, m_tTileType(j).nApprIndex, mat)
     StartTileAnimation k, 2
    End If
   End If
   m_tMapDataInst(ps(idx).nMapDataIndex).nTypeArray(ps(idx).x, ps(idx).y, ps(idx).z) = j
   m_tMapDataInst(ps(idx).nMapDataIndex).nInstIndex(ps(idx).x, ps(idx).y, ps(idx).z) = k
  End If
 Next idx
Case 5 'move:straight
 If t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
  p = m_objPoly(t.nPolyhedronIndex).Position
  Select Case m_tLevel.tPolyhedron(t.nPolyhedronIndex).nShape
  Case &H111 To &HFFF
   m_objPoly(t.nPolyhedronIndex).Move (p.nGroundEdgeIndex - p.nFirstEdgeIndex + 2) And 3&, True
  Case Else
   Debug.Assert False
  End Select
 End If
Case 6 'move:left
 If t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
  p = m_objPoly(t.nPolyhedronIndex).Position
  Select Case m_tLevel.tPolyhedron(t.nPolyhedronIndex).nShape
  Case &H111 To &HFFF
   m_objPoly(t.nPolyhedronIndex).Move (p.nGroundEdgeIndex - p.nFirstEdgeIndex - 1) And 3&, True
  Case Else
   Debug.Assert False
  End Select
 End If
Case 7 'move:right
 If t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
  p = m_objPoly(t.nPolyhedronIndex).Position
  Select Case m_tLevel.tPolyhedron(t.nPolyhedronIndex).nShape
  Case &H111 To &HFFF
   m_objPoly(t.nPolyhedronIndex).Move (p.nGroundEdgeIndex - p.nFirstEdgeIndex + 1) And 3&, True
  Case Else
   Debug.Assert False
  End Select
 End If
Case 8 'move:back
 If t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
  p = m_objPoly(t.nPolyhedronIndex).Position
  Select Case m_tLevel.tPolyhedron(t.nPolyhedronIndex).nShape
  Case &H111 To &HFFF
   m_objPoly(t.nPolyhedronIndex).Move (p.nGroundEdgeIndex - p.nFirstEdgeIndex) And 3&, True
  Case Else
   Debug.Assert False
  End Select
 End If
Case 9 'absolute-move
 Debug.Print "TODO:absolute-move"
Case 10 'game-finished
 'TODO:animation (?)
 If m_tLevel.nWinningConditionCount > 0 Then
  m_bGameFinishedEvent = True
 ElseIf m_nCheckPointRemaining <= 0 Then
  m_bGameFinished = True
 End If
Case 11 'game-finished:unconditional
 'TODO:animation (?)
 m_bGameFinished = True
Case 12 'checkpoint
 m_nCheckPointRemaining = m_nCheckPointRemaining - 1
Case &H100 To &H1FF 'game-over:*
 ProcessGameOver t.nPolyhedronIndex, tEvent.nType, t.p
Case Else
 Debug.Assert False
 Exit Sub
End Select
End Sub

Friend Sub ProcessGameOver(ByVal nPolyhedronIndex As Long, ByVal nType As Long, ByRef p As typeMapPosition)
Dim i As Long, k As Long
'///
m_bPolyhedronDirty = True
'///
Select Case nType
Case &H103, &H105 'game-over:*:2
 i = GetMapDataIndirect(p)
 If i <= 0 Then Exit Sub
 '///
 m_nUndoDirtyFlags = m_nUndoDirtyFlags Or 1&
 '///
 k = m_tMapDataInst(p.nMapDataIndex).nInstIndex(p.x, p.y, p.z)
 If k > 0 Then
  'TODO:correct animation
  StartTileAnimation k, -1
 End If
 m_tMapDataInst(p.nMapDataIndex).nTypeArray(p.x, p.y, p.z) = 0
 m_tMapDataInst(p.nMapDataIndex).nInstIndex(p.x, p.y, p.z) = 0
Case &H101 'game-over:immediately
 m_bGameOver = True
Case Else 'TODO:other type
 If nPolyhedronIndex > 0 And nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
  StartPolyhedronAnimation nPolyhedronIndex, -1, 0 'TODO:game over type
 Else 'err???
  m_bGameOver = True
 End If
End Select
End Sub

Friend Function CheckNumberMatchesCondition(ByVal f As Single, ByRef t As typeTileEventCondition) As Boolean
Select Case t.nCompareType
Case 0
 CheckNumberMatchesCondition = f >= t.nValue1 And f <= t.nValue2
Case 1
 CheckNumberMatchesCondition = Not (f >= t.nValue1 And f <= t.nValue2)
Case Else
 Debug.Assert False
End Select
End Function

Friend Function CheckBooleanMatchesCondition(ByVal b As Boolean, ByRef t As typeTileEventCondition) As Boolean
Select Case t.nCompareType
Case 0
 CheckBooleanMatchesCondition = b = (t.nValue1 <> 0)
Case 1
 CheckBooleanMatchesCondition = b <> (t.nValue1 <> 0)
Case Else
 Debug.Assert False
End Select
End Function

Friend Function CheckStringMatchesCondition(ByVal s As String, ByRef t As typeTileEventCondition) As Boolean
Dim i As Long
Select Case t.nCompareType
Case 0
 For i = 0 To t.nStringValueCount - 1
  If s = t.sStringValue(i) Then
   CheckStringMatchesCondition = True
   Exit Function
  End If
 Next i
Case 1
 For i = 0 To t.nStringValueCount - 1
  If s = t.sStringValue(i) Then Exit Function
 Next i
 CheckStringMatchesCondition = True
Case 2
 For i = 0 To t.nStringValueCount - 1
  If s Like t.sStringValue(i) Then
   CheckStringMatchesCondition = True
   Exit Function
  End If
 Next i
Case 3
 For i = 0 To t.nStringValueCount - 1
  If s Like t.sStringValue(i) Then Exit Function
 Next i
 CheckStringMatchesCondition = True
Case Else
 Debug.Assert False
End Select
End Function

Friend Sub CheckMapEventMatchesTileEvent(ByRef t As typeMapDataEvent, ByRef tEvent As typeTileEvent)
Dim i As Long, j As Long
Dim x1 As Long, y1 As Long
Dim x2 As Long, y2 As Long
Dim s As String
Dim b As Boolean
Dim p As typePolyhedronPosition
'///
If (t.nEventType Xor tEvent.nEventType) And &HFFFFFF Then Exit Sub
'///check condition
For i = 1 To tEvent.nConditionCount
 b = False
 Select Case tEvent.tCondition(i).nType
 Case 1 'pressure
  b = CheckNumberMatchesCondition(t.fPressure, tEvent.tCondition(i))
 Case 2 'onGroundCount
  b = CheckNumberMatchesCondition(t.nOnGroundCount, tEvent.tCondition(i))
 Case 3 'onDifferentType
  b = CheckBooleanMatchesCondition(t.nTileTypeCount > 1, tEvent.tCondition(i))
 Case 4 'eventType
  b = CheckStringMatchesCondition(t.sEventType, tEvent.tCondition(i))
 Case 5 'tileTypeCount
  b = CheckNumberMatchesCondition(t.nTileTypeCount, tEvent.tCondition(i))
 Case 6 'objectTypeCount
  b = CheckNumberMatchesCondition(t.nObjTypeCount, tEvent.tCondition(i))
 Case 7 'checkpoint
  b = CheckNumberMatchesCondition(m_tLevel.nCheckPointCount - m_nCheckPointRemaining, tEvent.tCondition(i))
 Case 8 'checkpointRemaining
  b = CheckNumberMatchesCondition(m_nCheckPointRemaining, tEvent.tCondition(i))
 Case &H101 'discardable
  If t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
   b = CheckBooleanMatchesCondition(m_tPolyInst(t.nPolyhedronIndex).nFlags And 1&, tEvent.tCondition(i))
  End If
 Case &H102 'main
  If t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
   b = CheckBooleanMatchesCondition(m_tPolyInst(t.nPolyhedronIndex).nFlags And 2&, tEvent.tCondition(i))
  End If
 Case &H103 'fragile
  If t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
   b = CheckBooleanMatchesCondition(m_tPolyInst(t.nPolyhedronIndex).nFlags And 4&, tEvent.tCondition(i))
  End If
 Case &H104 'supportable
  If t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
   b = CheckBooleanMatchesCondition(m_tPolyInst(t.nPolyhedronIndex).nFlags And 8&, tEvent.tCondition(i))
  End If
 Case &H105 'supporter
  If t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
   b = CheckBooleanMatchesCondition(m_tPolyInst(t.nPolyhedronIndex).nFlags And &H10&, tEvent.tCondition(i))
  End If
 Case &H106 'tiltable
  If t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
   b = CheckBooleanMatchesCondition(m_tPolyInst(t.nPolyhedronIndex).nFlags And &H20&, tEvent.tCondition(i))
  End If
 Case &H107 'tilt-supporter
  If t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
   b = CheckBooleanMatchesCondition(m_tPolyInst(t.nPolyhedronIndex).nFlags And &H40&, tEvent.tCondition(i))
  End If
 Case &H108 'spannable
  If t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
   b = CheckBooleanMatchesCondition(m_tPolyInst(t.nPolyhedronIndex).nFlags And &H80&, tEvent.tCondition(i))
  End If
 Case &H121 'objectType
  If t.nEventType And &H1000000 Then
   If t.nObjTypeCount = 1 Then
    j = t.nObjTypes(1)
    If j > 0 And j <= m_nObjTypeCount Then
     s = m_tObjType(j).sName
    Else
     s = "default"
    End If
    b = CheckStringMatchesCondition(s, tEvent.tCondition(i))
   End If
  ElseIf t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
   j = m_tLevel.tPolyhedron(t.nPolyhedronIndex).nObjType
   If j > 0 And j <= m_nObjTypeCount Then
    s = m_tObjType(j).sName
   Else
    s = "default"
   End If
   b = CheckStringMatchesCondition(s, tEvent.tCondition(i))
  End If
 Case &H122 'objectID
  If t.nEventType And &H1000000 Then
   'invalid
   Debug.Assert False
  ElseIf t.nPolyhedronIndex > 0 And t.nPolyhedronIndex <= m_tLevel.nPolyhedronCount Then
   b = CheckStringMatchesCondition(m_tLevel.tPolyhedron(t.nPolyhedronIndex).sID, tEvent.tCondition(i))
  End If
 Case &H1001& 'tileType [POLYHEDRON EVENT ONLY]
  If t.nEventType And &H1000000 Then
   If t.nTileTypeCount = 1 Then
    j = t.nTileTypes(1)
    If j > 0 Then b = CheckStringMatchesCondition(m_tTileType(j).sID, tEvent.tCondition(i))
   End If
  Else
   'invalid
   Debug.Assert False
  End If
 Case &H1002& 'objectTypeContains [POLYHEDRON EVENT ONLY]
  If t.nEventType And &H1000000 Then
   For x1 = 1 To t.nObjTypeCount
    j = t.nObjTypes(x1)
    If j > 0 And j <= m_nObjTypeCount Then
     s = m_tObjType(j).sName
    Else
     s = "default"
    End If
    If CheckStringMatchesCondition(s, tEvent.tCondition(i)) Then
     b = True
     Exit For
    End If
   Next x1
  Else
   'invalid
   Debug.Assert False
  End If
 Case &H1003& 'tileTypeContains [POLYHEDRON EVENT ONLY]
  If t.nEventType And &H1000000 Then
   For x1 = 1 To t.nTileTypeCount
    j = t.nTileTypes(x1)
    If j > 0 Then
     If CheckStringMatchesCondition(m_tTileType(j).sID, tEvent.tCondition(i)) Then
      b = True
      Exit For
     End If
    End If
   Next x1
  Else
   'invalid
   Debug.Assert False
  End If
 Case &H1004& 'target [POLYHEDRON EVENT ONLY]
  If t.nEventType And &H1000000 Then
   For j = 0 To tEvent.tCondition(i).nStringValueCount - 1
    If FindPosition(tEvent.tCondition(i).sStringValue(j), p.p) Then
     If t.p.nMapDataIndex = p.p.nMapDataIndex Then
      If t.p.x = p.p.x Then
       If t.p.y = p.p.y Then
        If t.p.z = p.p.z Then
         b = True
         Exit For
        End If
       End If
      End If
     End If
    End If
   Next j
   If tEvent.tCondition(i).nCompareType And 1& Then b = Not b
  Else
   'invalid
   Debug.Assert False
  End If
 Case &H1005& 'targetSize [POLYHEDRON EVENT ONLY]
  If t.nEventType And &H1000000 Then
   p.p = t.p
   p.nFirstEdgeIndex = t.nFirstEdgeIndex
   p.nGroundFaceIndex = t.nGroundFaceIndex
   p.nGroundEdgeIndex = t.nGroundEdgeIndex
   m_objPoly(t.nPolyhedronIndex).GetCurrentSizeEx p, x2, y2
   For j = 0 To tEvent.tCondition(i).nStringValueCount - 1
    s = Replace(tEvent.tCondition(i).sStringValue(j), "x", ",")
    s = Replace(s, "X", ",")
    s = Replace(s, "*", ",")
    y1 = InStr(1, s, ",")
    If y1 > 0 Then
     x1 = Val(Left(s, y1 - 1))
     y1 = Val(Mid(s, y1 + 1))
    Else
     x1 = Val(s)
     y1 = 1
    End If
    '///
    If x1 = x2 And y1 = y2 Then
     b = True
     Exit For
    End If
   Next j
   If tEvent.tCondition(i).nCompareType And 1& Then b = Not b
  Else
   'invalid
   Debug.Assert False
  End If
 Case Else
  Debug.Assert False
  Exit Sub
 End Select
 If Not b Then Exit Sub
Next i
'///dispatch event
For i = 1 To tEvent.nEventCount
 DispatchTileEvent t, tEvent.tEvent(i)
Next i
End Sub

Friend Sub DispatchMapEvent(ByRef tEvent As typeMapDataEvent)
Dim n As Long
Dim i As Long
If tEvent.nEventType And &H1000000 Then
 '///new: polyhedron event
 n = tEvent.nPolyhedronIndex
 If n <= 0 Or n > m_tLevel.nPolyhedronCount Then Exit Sub
 For i = 1 To m_tLevel.tPolyhedron(n).nEventCount
  CheckMapEventMatchesTileEvent tEvent, m_tLevel.tPolyhedron(n).tEvent(i)
 Next i
Else
 '///
 n = GetMapDataIndirect(tEvent.p)
 If n < 0 Then Exit Sub
 '///check tile type's event
 If n > 0 Then
  For i = 1 To m_tTileType(n).nEventCount
   CheckMapEventMatchesTileEvent tEvent, m_tTileType(n).tEvent(i)
  Next i
 End If
 '///check custom event
 n = m_tLevel.tMapData(tEvent.p.nMapDataIndex).nPropertyArray(tEvent.p.x, tEvent.p.y, tEvent.p.z)
 If n > 0 And n <= m_tLevel.tMapData(tEvent.p.nMapDataIndex).nPropertyCount Then
  For i = 1 To m_tLevel.tMapData(tEvent.p.nMapDataIndex).tProperties(n).nEventCount
   CheckMapEventMatchesTileEvent tEvent, m_tLevel.tMapData(tEvent.p.nMapDataIndex).tProperties(n).tEvent(i)
  Next i
 End If
End If
End Sub

Friend Sub ProcessMapEvents()
Dim i As Long
Dim tEvent As typeMapDataEvent
'///
For i = 1 To 16384 'max iteration
 If m_nEventStart >= m_nEventEnd Then
  m_nEventStart = 0
  m_nEventEnd = 0
  Exit For
 End If
 tEvent = m_tEvent(m_nEventStart)
 m_nEventStart = m_nEventStart + 1
 DispatchMapEvent tEvent
Next i
Debug.Assert i <= 16384
'///???
If m_bPolyhedronDirty Then
 For i = 1 To m_tLevel.nPolyhedronCount
  '????????
  If m_tPolyInst(i).nFlags And &H100& Then
   If m_tPolyInst(i).nAnimType = 0 Then
    m_objPoly(i).CheckPolyhedronStateAndResponse
   End If
  End If
 Next i
 '???
 ProcessPolyhedronMerge
End If
'///
m_bPolyhedronDirty = False
End Sub

Friend Sub AddMapEvent(ByRef tEvent As typeMapDataEvent)
If m_nEventEnd >= m_nEventMax Then
 m_nEventMax = m_nEventMax + 256&
 ReDim Preserve m_tEvent(m_nEventMax - 1)
End If
m_tEvent(m_nEventEnd) = tEvent
m_nEventEnd = m_nEventEnd + 1
End Sub

'will change the contents of tEvent.p
Friend Sub AddMapEventFromPositionString(ByRef tEvent As typeMapDataEvent, ByVal s As String)
Dim s1 As String
Dim idx As Long, i As Long, j As Long, k As Long
'///
i = InStr(1, s, "(")
If i > 0 Then '<id>"("<subscript>")"
 s1 = Mid(s, i + 1)
 s = Left(s, i - 1)
Else
 i = InStr(1, s, ".")
 If i > 0 Then '<id>.<tag>
  s1 = Mid(s, i + 1)
  s = Left(s, i - 1)
  i = -1
 End If
End If
'///
If i <> 0 Then
 'get id
 idx = Val(s)
 If idx <= 0 Or idx > m_tLevel.nMapDataCount Then
  idx = FindMapData(s)
  If idx = 0 Then Exit Sub
 End If
 tEvent.p.nMapDataIndex = idx
 tEvent.p.x = 0
 tEvent.p.y = 0
 tEvent.p.z = 0
 'get subscript
 If i > 0 Then '<id>"("<subscript>")"
  tEvent.p.x = Val(s1) 'FIXME: no sanity check :-3
  i = InStr(1, s1, ",")
  If i > 0 Then
   tEvent.p.y = Val(Mid(s1, i + 1))
   i = InStr(i + 1, s1, ",")
   If i > 0 Then
    tEvent.p.z = Val(Mid(s1, i + 1))
   End If
  End If
  AddMapEvent tEvent
 Else '<id>.<tag>
  For k = 0 To m_tLevel.tMapData(idx).nSize(2) - 1
   tEvent.p.z = k
   For j = 0 To m_tLevel.tMapData(idx).nSize(1) - 1
    tEvent.p.y = j
    For i = 0 To m_tLevel.tMapData(idx).nSize(0) - 1
     If m_tLevel.tMapData(idx).sTagArray(i, j, k) = s1 Then
      tEvent.p.x = i
      AddMapEvent tEvent
     End If
    Next i
   Next j
  Next k
 End If
ElseIf s = "this" Then
 AddMapEvent tEvent
ElseIf s = vbNullString Or s = "all" Then 'all
 For idx = 1 To m_tLevel.nMapDataCount
  tEvent.p.nMapDataIndex = idx
  For k = 0 To m_tLevel.tMapData(idx).nSize(2) - 1
   tEvent.p.z = k
   For j = 0 To m_tLevel.tMapData(idx).nSize(1) - 1
    tEvent.p.y = j
    For i = 0 To m_tLevel.tMapData(idx).nSize(0) - 1
     tEvent.p.x = i
     AddMapEvent tEvent
    Next i
   Next j
  Next k
 Next idx
Else '<tag>
 For idx = 1 To m_tLevel.nMapDataCount
  tEvent.p.nMapDataIndex = idx
  For k = 0 To m_tLevel.tMapData(idx).nSize(2) - 1
   tEvent.p.z = k
   For j = 0 To m_tLevel.tMapData(idx).nSize(1) - 1
    tEvent.p.y = j
    For i = 0 To m_tLevel.tMapData(idx).nSize(0) - 1
     If m_tLevel.tMapData(idx).sTagArray(i, j, k) = s Then
      tEvent.p.x = i
      AddMapEvent tEvent
     End If
    Next i
   Next j
  Next k
 Next idx
End If
'///
End Sub

Friend Sub ProcessPolyhedronMerge()
Dim idx As Long
Dim i As Long, j As Long, k As Long, m As Long
Dim x1 As Long, y1 As Long, z1 As Long
Dim x2 As Long, y2 As Long, z2 As Long
Dim p1 As typePolyhedronPosition, p2 As typePolyhedronPosition
Dim b As Boolean
'TODO:adjacency support
'TODO:non-cuboid polyhedron merge
For idx = 1 To m_tLevel.nPolyMergeCount
 m = m_tLevel.tPolyMerge(idx).nSrcCount
 Select Case m
 Case 2
  i = FindPolyhedron(m_tLevel.tPolyMerge(idx).sSrcID(0))
  If i > 0 Then
   If (m_tPolyInst(i).nFlags And &H100&) <> 0 And m_tPolyInst(i).nAnimType = 0 Then
    j = FindPolyhedron(m_tLevel.tPolyMerge(idx).sSrcID(1))
    If j > 0 Then
     If (m_tPolyInst(j).nFlags And &H100&) <> 0 And m_tPolyInst(j).nAnimType = 0 Then
      '///
      p1 = m_objPoly(i).Position
      p2 = m_objPoly(j).Position
      If p1.p.nMapDataIndex = p2.p.nMapDataIndex Then
       m_objPoly(i).GetCurrentSize x1, y1, z1
       m_objPoly(j).GetCurrentSize x2, y2, z2
       '///
       b = False
       If p1.p.x = p2.p.x Then
        If p1.p.y = p2.p.y Then
         If x1 = x2 And y1 = y2 Then
          If p1.p.z + z1 = p2.p.z Then
           z1 = z1 + z2
           b = True
          ElseIf p2.p.z + z2 = p1.p.z Then
           z1 = z1 + z2
           p1 = p2
           b = True
          End If
         End If
        ElseIf p1.p.z = p2.p.z Then
         If x1 = x2 And z1 = z2 Then
          If p1.p.y + y1 = p2.p.y Then
           y1 = y1 + y2
           b = True
          ElseIf p2.p.y + y2 = p1.p.y Then
           y1 = y1 + y2
           p1 = p2
           b = True
          End If
         End If
        End If
       ElseIf p1.p.y = p2.p.y And p1.p.z = p2.p.z Then
        If y1 = y2 And z1 = z2 Then
         If p1.p.x + x1 = p2.p.x Then
          x1 = x1 + x2
          b = True
         ElseIf p2.p.x + x2 = p1.p.x Then
          x1 = x1 + x2
          p1 = p2
          b = True
         End If
        End If
       End If
       '///??? may be buggy
       If b Then
        k = FindPolyhedron(m_tLevel.tPolyMerge(idx).sDestID)
        If k > 0 Then
         m_objPoly(k).GetSize x2, y2, z2
         If x1 = x2 Then
          If y1 = y2 And z1 = z2 Then
           p1.nFirstEdgeIndex = 0
           p1.nGroundFaceIndex = 0
          ElseIf y1 = z2 And z1 = y2 Then
           p1.nFirstEdgeIndex = 0
           p1.nGroundFaceIndex = 2
          Else
           b = False
          End If
         ElseIf x1 = y2 Then
          If y1 = x2 And z1 = z2 Then
           p1.nFirstEdgeIndex = 1
           p1.nGroundFaceIndex = 0
          ElseIf y1 = z2 And z1 = x2 Then
           p1.nFirstEdgeIndex = 1
           p1.nGroundFaceIndex = 3
          Else
           b = False
          End If
         ElseIf x1 = z2 Then
          If y1 = x2 And z1 = y2 Then
           p1.nFirstEdgeIndex = 1
           p1.nGroundFaceIndex = 2
          ElseIf y1 = y2 And z1 = x2 Then
           p1.nFirstEdgeIndex = 0
           p1.nGroundFaceIndex = 3
          Else
           b = False
          End If
         Else
          b = False
         End If
         If b Then 'finally, it merged
          m_nUndoDirtyFlags = m_nUndoDirtyFlags Or 2&
          '///
          m_tPolyInst(i).nFlags = m_tPolyInst(i).nFlags And Not &H100&
          m_tPolyInst(j).nFlags = m_tPolyInst(j).nFlags And Not &H100&
          If m_tPolyInst(k).nFlags And &H100& Then '??? err???
           Debug.Assert False
           m_objPoly(k).SendEvent EventTypeOnLeave
          Else
           m_tPolyInst(k).nFlags = m_tPolyInst(k).nFlags Or &H100&
          End If
          m_objPoly(k).Position = p1
          m_nCurrentPolyhedron = k
          m_bPolyhedronDirty = True
          '///
          'objLogger.AddMessage "Polyhedron merged" 'debug
         End If
        End If
       End If
      End If
     End If
    End If
   End If
  End If
 Case Else
  'currently unsupported. TODO:
 End Select
Next idx
End Sub
