Attribute VB_Name = "mdlRenderLandscape"
Option Explicit

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)

Public MyMini_Vertices() As typeVertex
Public MyMini_VertexCount As Long, MyMini_VertexMax As Long

Public MyMini_Indices() As Long
Public MyMini_IndexCount As Long, MyMini_IndexMax As Long

Public MyMini_FanCount As Long, MyMini_Vertex0 As Long, MyMini_Vertex1 As Long

Public MyMini_Scale As D3DVECTOR
Public MyMini_Offset As D3DVECTOR

'////////new:fog
Public MyMini_FogVertices() As typeVertex_XYZ_Diffuse
Public MyMini_FogVertexCount As Long, MyMini_FogVertexMax As Long

Public MyMini_FogIndices() As Long
Public MyMini_FogIndexCount As Long, MyMini_FogIndexMax As Long

Public MyMini_FogPrismState As Long

Public MyMini_FogEnabled As Boolean
'////////

Public MyMiniErr_NoIndexBuffer As Boolean

Public Sub MyMiniCallback_ErrorHandler(ByVal lpstrFile As Long, ByVal nLine As Long, ByVal nFatal As Long)
Dim s As String, i As Long
s = Space(1024)
CopyMemory ByVal s, ByVal lpstrFile, 1024
i = InStr(1, s, vbNullChar)
If i > 0 Then s = Left(s, i - 1)
MsgBox "libmini error at " + s + " line " + CStr(nLine), vbCritical, objText.GetText("Fatal Error")
End
End Sub

Public Sub MyMiniCallback_BeginFan()
MyMini_FanCount = 0
End Sub

Public Sub MyMiniCallback_FanVertex(ByVal i As Single, ByVal y As Single, ByVal j As Single)
If MyMiniErr_NoIndexBuffer Then
 If MyMini_FanCount >= 2 Then
  MyMini_IndexCount = MyMini_IndexCount + 3
  If MyMini_FanCount >= 3 Then
   MyMini_VertexCount = MyMini_VertexCount + 2
   '///
   If MyMini_VertexCount >= MyMini_VertexMax Then
    MyMini_VertexMax = MyMini_VertexMax + 4096&
    ReDim Preserve MyMini_Vertices(MyMini_VertexMax - 1)
   End If
   '///
   MyMini_Vertices(MyMini_VertexCount - 2) = MyMini_Vertices(MyMini_VertexCount - MyMini_FanCount * 3& + 4)
   MyMini_Vertices(MyMini_VertexCount - 1) = MyMini_Vertices(MyMini_VertexCount - 3)
   '///
  End If
 Else
  If MyMini_VertexCount >= MyMini_VertexMax Then
   MyMini_VertexMax = MyMini_VertexMax + 4096&
   ReDim Preserve MyMini_Vertices(MyMini_VertexMax - 1)
  End If
 End If
Else
 If MyMini_FanCount >= 2 Then
  MyMini_IndexCount = MyMini_IndexCount + 3
  If MyMini_IndexCount >= MyMini_IndexMax Then
   MyMini_IndexMax = MyMini_IndexMax + 4096&
   ReDim Preserve MyMini_Indices(MyMini_IndexMax - 1)
  End If
  MyMini_Indices(MyMini_IndexCount - 3) = MyMini_VertexCount - MyMini_FanCount
  MyMini_Indices(MyMini_IndexCount - 2) = MyMini_VertexCount - 1
  MyMini_Indices(MyMini_IndexCount - 1) = MyMini_VertexCount
 End If
 '///
 If MyMini_VertexCount >= MyMini_VertexMax Then
  MyMini_VertexMax = MyMini_VertexMax + 4096&
  ReDim Preserve MyMini_Vertices(MyMini_VertexMax - 1)
 End If
End If
'///
With MyMini_Vertices(MyMini_VertexCount)
 '///position
 .p.x = MyMini_Scale.x * i + MyMini_Offset.x
 .p.y = MyMini_Scale.y * j + MyMini_Offset.y
 .p.z = MyMini_Scale.z * y + MyMini_Offset.z
 '///normal (???)
 'Mini_GetNormalByCoordinates i, j, .n.x, .n.y 'doesn't work, always 0
 Mini_GetNormalByPosition .p.x, -.p.y, .n.x, .n.z, .n.y
 .n.y = -.n.y
 '.n.z = 1 '???
 '///
 'TODO:other
 .clr1 = -1
 .clr2 = -1
 '///!!!TEST ONLY!!!
' If MyMini_FanCount = 0 Then
'  .t.x = 0
'  .t.y = 0
' Else
'  .t.x = MyMini_FanCount And 1&
'  .t.y = 1
' End If
 .t.x = i / 256
 .t.y = 1 - j / 256
 '///
End With
'///
MyMini_FanCount = MyMini_FanCount + 1
MyMini_VertexCount = MyMini_VertexCount + 1
End Sub

Public Sub MyMiniCallback_PrismEdge(ByVal x As Single, ByVal y As Single, ByVal yf As Single, ByVal z As Single)
''completely unusable
'If Not MyMini_FogEnabled Then Exit Sub
''///add vertex
'If MyMini_FogVertexCount + 2 > MyMini_FogVertexMax Then
' MyMini_FogVertexMax = MyMini_FogVertexMax + 8192&
' ReDim Preserve MyMini_FogVertices(MyMini_FogVertexMax - 1)
'End If
'With MyMini_FogVertices(MyMini_FogVertexCount)
' .p.x = x
' .p.y = -z
' .p.z = y
' .clr1 = -1 'useless
'End With
'With MyMini_FogVertices(MyMini_FogVertexCount + 1)
' .p.x = x
' .p.y = -z
' .p.z = yf
' .clr1 = -1 'useless
'End With
'MyMini_FogVertexCount = MyMini_FogVertexCount + 2
''///add index
'MyMini_FogPrismState = MyMini_FogPrismState + 1
'If MyMini_FogPrismState >= 2 Then
' If MyMini_FogIndexCount + 18 > MyMini_FogIndexMax Then
'  MyMini_FogIndexMax = MyMini_FogIndexMax + 8192&
'  ReDim Preserve MyMini_FogIndices(MyMini_FogIndexMax - 1)
' End If
' '///
' MyMini_FogIndices(MyMini_FogIndexCount) = MyMini_FogVertexCount - 4
' MyMini_FogIndices(MyMini_FogIndexCount + 1) = MyMini_FogVertexCount - 2
' MyMini_FogIndices(MyMini_FogIndexCount + 2) = MyMini_FogVertexCount - 3
' MyMini_FogIndices(MyMini_FogIndexCount + 3) = MyMini_FogVertexCount - 1
' MyMini_FogIndices(MyMini_FogIndexCount + 4) = MyMini_FogVertexCount - 3
' MyMini_FogIndices(MyMini_FogIndexCount + 5) = MyMini_FogVertexCount - 2
' MyMini_FogIndexCount = MyMini_FogIndexCount + 6
' If MyMini_FogPrismState >= 3 Then
'  MyMini_FogIndices(MyMini_FogIndexCount) = MyMini_FogVertexCount - 2
'  MyMini_FogIndices(MyMini_FogIndexCount + 1) = MyMini_FogVertexCount - 6
'  MyMini_FogIndices(MyMini_FogIndexCount + 2) = MyMini_FogVertexCount - 1
'  MyMini_FogIndices(MyMini_FogIndexCount + 3) = MyMini_FogVertexCount - 5
'  MyMini_FogIndices(MyMini_FogIndexCount + 4) = MyMini_FogVertexCount - 1
'  MyMini_FogIndices(MyMini_FogIndexCount + 5) = MyMini_FogVertexCount - 6
'  MyMini_FogIndexCount = MyMini_FogIndexCount + 6
'  MyMini_FogIndices(MyMini_FogIndexCount) = MyMini_FogVertexCount - 5
'  MyMini_FogIndices(MyMini_FogIndexCount + 1) = MyMini_FogVertexCount - 3
'  MyMini_FogIndices(MyMini_FogIndexCount + 2) = MyMini_FogVertexCount - 1
'  MyMini_FogIndices(MyMini_FogIndexCount + 3) = MyMini_FogVertexCount - 2
'  MyMini_FogIndices(MyMini_FogIndexCount + 4) = MyMini_FogVertexCount - 4
'  MyMini_FogIndices(MyMini_FogIndexCount + 5) = MyMini_FogVertexCount - 6
'  MyMini_FogIndexCount = MyMini_FogIndexCount + 6
'  MyMini_FogPrismState = 0
' End If
'End If
End Sub

