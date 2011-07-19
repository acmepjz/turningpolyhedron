VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsPolyhedron"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private m_tLogic As typePolyhedronLogic
Private m_tPos As typePolyhedronPosition

Friend Sub Destroy()
m_tLogic.nFaceCount = 0
Erase m_tLogic.tFace
'///
Dim t As typePolyhedronPosition
m_tPos = t
'///
End Sub

Friend Function CreateIndirect(ByRef tPoly As typeMapData_Polyhedron, ByRef tLevel As typeLevelData) As Boolean
'///get logic
If Not CreatePolyhedronLogic(m_tLogic, tPoly.nShape) Then Exit Function
'///get position
If Not ParsePolyhedronPosition(tPoly.sPos, m_tPos, tLevel) Then Exit Function
'///
CreateIndirect = True
End Function

Friend Function ParsePolyhedronPosition(ByVal s As String, ByRef tPos As typePolyhedronPosition, ByRef tLevel As typeLevelData) As Boolean
Dim v As Variant
Dim s1 As String
Dim i As Long, j As Long, k As Long, m As Long
Dim idx As Long
'///
v = Split(s, ":")
m = UBound(v)
If m < 0 Then
 Debug.Assert False
 Exit Function
End If
'///get position
s = v(0)
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
 For idx = 1 To tLevel.nMapDataCount
  If s = tLevel.tMapData(idx).sID Then Exit For
 Next idx
 If idx > tLevel.nMapDataCount Then
  Debug.Assert False
  Exit Function
 End If
End If
tPos.nMapDataIndex = idx
tPos.x = 0
tPos.y = 0
tPos.z = 0
If i > 0 Then
 tPos.x = Val(s1) 'FIXME: no sanity check :-3
 i = InStr(1, s1, ",")
 If i > 0 Then
  tPos.y = Val(Mid(s1, i + 1))
  i = InStr(i + 1, s1, ",")
  If i > 0 Then
   tPos.z = Val(Mid(s1, i + 1))
  End If
 End If
ElseIf i < 0 Then
 Do
  For k = 0 To tLevel.tMapData(idx).nSize(2) - 1
   For j = 0 To tLevel.tMapData(idx).nSize(1) - 1
    For i = 0 To tLevel.tMapData(idx).nSize(0) - 1
     If tLevel.tMapData(idx).sTagArray(i, j, k) = s1 Then
      tPos.x = i
      tPos.y = j
      tPos.z = k
      Exit Do
     End If
    Next i
   Next j
  Next k
  'err: not found
  Debug.Assert False
  Exit Function
 Loop While False
End If
'///get direction,etc.
i = 0
If m >= 1 Then
 s = v(1)
 Select Case s
 Case "up", "top", "back"
  i = 0
 Case "left"
  i = 1
 Case "down", "bottom", "front"
  i = 2
 Case "right"
  i = 3
 Case Else
  i = Val(s)
 End Select
End If
tPos.nFirstEdgeIndex = i
'///
i = 0
If m >= 2 Then
 s = v(2)
 Select Case s
 Case "bottom"
  i = 0
 Case "top"
  i = 1
 Case "front"
  i = 2
 Case "right"
  i = 3
 Case "back"
  i = 4
 Case "left"
  i = 5
 Case Else
  i = Val(s)
 End Select
End If
tPos.nGroundFaceIndex = i
'///
i = 0
If m >= 3 Then i = Val(v(3))
tPos.nGroundEdgeIndex = i
'///debug
'Debug.Print tPos.nMapDataIndex; tPos.x; tPos.y; tPos.z; tPos.nFirstEdgeIndex; tPos.nGroundFaceIndex; tPos.nGroundEdgeIndex
'///over
ParsePolyhedronPosition = True
End Function

Friend Function CreatePolyhedronLogic(ByRef tLogic As typePolyhedronLogic, ByVal nShape As Long) As Boolean
Dim i As Long, j As Long, k As Long
Dim m As Long, n As Long
Select Case nShape
Case &H111 To &HFFF
 i = (nShape And &HF00&) \ &H100&
 j = (nShape And &HF0&) \ &H10&
 k = nShape And &HF&
 '///debug
 'Debug.Print i; j; k
 '///
 tLogic.nFaceCount = 6
 ReDim tLogic.tFace(0 To 5)
 '///bottom
 CreatePolyhedronFaceLogic tLogic.tFace(0), 4, i, j, , &H3254&, &H1232&
 '///top
 CreatePolyhedronFaceLogic tLogic.tFace(1), 4, i, j, , &H5234&, &H1030&
 '///front
 CreatePolyhedronFaceLogic tLogic.tFace(2), 4, i, k, , &H5031&, &H2222&
 '///right
 CreatePolyhedronFaceLogic tLogic.tFace(3), 4, k, j, , &H1204&, &H1133&
 '///back
 CreatePolyhedronFaceLogic tLogic.tFace(4), 4, i, k, , &H3051&, 0
 '///left
 CreatePolyhedronFaceLogic tLogic.tFace(5), 4, k, j, , &H214&, &H1331&
Case Else
 'TODO:
 Debug.Assert False
 Exit Function
End Select
CreatePolyhedronLogic = True
End Function

'internal
Friend Sub CreatePolyhedronFaceLogic(ByRef tFace As typePolyhedronFaceLogic, ByVal nEdgeCount As Long, Optional ByVal nSize0 As Long, Optional ByVal nSize1 As Long, Optional ByVal nSize2 As Long, Optional ByVal nAdjacentFace As Long, Optional ByVal nAdjacentFaceEdge As Long)
Dim i As Long
tFace.nEdgeCount = nEdgeCount
tFace.nSize(0) = nSize0
tFace.nSize(1) = nSize1
tFace.nSize(2) = nSize2
For i = 0 To nEdgeCount - 1
 tFace.nAdjacentFace(i) = nAdjacentFace And &HF&
 tFace.nAdjacentFaceEdge(i) = nAdjacentFaceEdge And &HF&
 nAdjacentFace = nAdjacentFace \ &H10&
 nAdjacentFaceEdge = nAdjacentFaceEdge \ &H10&
Next i
End Sub

Friend Function CanChangeGroundEdgeIndex(ByVal nNewIndex As Long, ByVal objGameMgr As clsGameManager) As Boolean
'TODO:
'objGameMgr.GetAdjacentTile '...
'objGameMgr.HitTest '...
End Function
