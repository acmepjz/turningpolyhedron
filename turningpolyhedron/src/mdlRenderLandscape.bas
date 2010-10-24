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
'///
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
 If MyMini_FanCount = 0 Then
  .t.x = 0
  .t.y = 0
 Else
  .t.x = MyMini_FanCount And 1&
  .t.y = 1
 End If
 '///
End With
'///
MyMini_FanCount = MyMini_FanCount + 1
MyMini_VertexCount = MyMini_VertexCount + 1
End Sub

Public Sub MyMiniCallback_PrismEdge(ByVal x As Single, ByVal y As Single, ByVal yf As Single, ByVal z As Single)
'TODO:
End Sub

