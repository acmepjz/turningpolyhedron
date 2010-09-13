Attribute VB_Name = "mdlFakeDXUI"
Option Explicit

Public FakeDXUIControls() As New clsFakeDXUI '1-based
Public FakeDXUIControlCount As Long

Public FakeDXUIEvent As IFakeDXUIEvent

Public FakeDXUIActiveWindow As Long
Public FakeDXUIFocus As Long
Public FakeDXUISetCapture As Long

Public FakeDXUITexture As Direct3DTexture9

Public FakeDXUIDefaultFont As typeFakeDXGDILogFont

Public FakeDXUIMousePointer As MousePointerConstants

Public Type typeFakeDXUIPosition 'a+b*w
 a As Single
 b As Single
End Type

Public Type typeFakeDXUIPoint
 x As Single
 y As Single
End Type

Public Type typeFakeDXUIPointEx
 x As typeFakeDXUIPosition
 y As typeFakeDXUIPosition
End Type

Public Type typeFakeDXUIRect
 Left As Single
 Top As Single
 Right As Single
 Bottom As Single
End Type

Public Type typeFakeDXUIRectEx
 Left As typeFakeDXUIPosition
 Top As typeFakeDXUIPosition
 Right As typeFakeDXUIPosition
 Bottom As typeFakeDXUIPosition
End Type

Public Type typeFakeDXUIMessage
 iMsg As Long
 nParam1 As Long
 nParam2 As Long
 nParam3 As Long
End Type

Public Enum enumFakeDXUIControlType
 FakeCtl_Unused = -1
 FakeCtl_None = 0
 FakeCtl_Form = 1
 FakeCtl_Label = 2
End Enum

Public Enum enumFakeDXUIControlStyle
 FakeCtl_Style_TabStop = &H1000000
 FakeCtl_Style_TopMost = &H10000000
 '///
 FakeCtl_Form_Sizable = 1
 FakeCtl_Form_Moveable = 2
 FakeCtl_Form_MinButton = 4
 FakeCtl_Form_MaxButton = 8
 FakeCtl_Form_CloseButton = 16
 FakeCtl_Form_TitleBar = 32
End Enum

Public Enum enumFakeDXUIControlState
 FakeCtl_State_Maximized = 1
 FakeCtl_State_Minimized = 2
End Enum

Public Enum enumFakeDXUIMessage
 FakeCtl_Msg_Size = 5 'param1=ctlindex param2=maximize(1) minimize(2)
 FakeCtl_Msg_Close = 16 'param1=ctlindex
 '///
 FakeCtl_Msg_ZOrder = 65001 'param1=ctlindex param2=HWND_TOP(0) HWND_BOTTOM(1) HWND_TOPMOST(-1) HWND_NOTOPMOST(-2)
 FakeCtl_Msg_Click = 65002 'param1=ctlindex
End Enum

Public FakeDXUIMessageQueue() As typeFakeDXUIMessage
Public FakeDXUIMessageQueueHead As Long
Public FakeDXUIMessageQueueTail As Long
Public FakeDXUIMessageQueueMax As Long

Public Sub FakeDXUICreate(ByVal nLeft As Single, ByVal nTop As Single, ByVal nRight As Single, ByVal nBottom As Single)
Dim t As D3DXIMAGE_INFO
'///
FakeDXUIDestroy
'///
ReDim FakeDXUIControls(1 To 1)
FakeDXUIControlCount = 1
With FakeDXUIControls(1)
 .Index = 1
 .ControlType = 0
 .SetLeftEx nLeft, 0
 .SetTopEx nTop, 0
 .SetRightEx nRight, 0
 .SetBottomEx nBottom, 0
End With
'///
'TODO:FakeDXUIDefaultFont
'///
ReDim FakeDXUIMessageQueue(255)
FakeDXUIMessageQueueMax = 256
'///
D3DXCreateTextureFromFileExW d3dd9, CStr(App.Path) + "\data\gfx\control1.png", D3DX_DEFAULT, D3DX_DEFAULT, 1, 0, D3DFMT_A8R8G8B8, D3DPOOL_MANAGED, D3DX_DEFAULT, D3DX_DEFAULT, 0, t, ByVal 0, FakeDXUITexture
End Sub

Public Sub FakeDXUIDispatchMessage(t As typeFakeDXUIMessage)
Dim b As Boolean
Select Case t.iMsg
Case FakeCtl_Msg_Click
 If Not FakeDXUIEvent Is Nothing Then FakeDXUIEvent.Click FakeDXUIControls(t.nParam1)
Case FakeCtl_Msg_Size
 Select Case t.nParam2
 Case 1
  FakeDXUIControls(t.nParam1).Maximize
 Case 2
  FakeDXUIControls(t.nParam1).Minimize
 End Select
Case FakeCtl_Msg_Close
 Select Case t.nParam2
 Case 0
  If Not FakeDXUIEvent Is Nothing Then FakeDXUIEvent.Unload FakeDXUIControls(t.nParam1), b
  If Not b Then FakeDXUIControls(t.nParam1).CloseWindow
 Case Else
  FakeDXUIControls(t.nParam1).Destroy
 End Select
Case FakeCtl_Msg_ZOrder
 Select Case t.nParam2
 Case 0
  FakeDXUIControls(t.nParam1).BringToFront
 Case 1
  FakeDXUIControls(t.nParam1).SendToBack
 Case -1
  With FakeDXUIControls(t.nParam1)
   .Style = .Style Or FakeCtl_Style_TopMost
  End With
 Case -2
  With FakeDXUIControls(t.nParam1)
   .Style = .Style And Not FakeCtl_Style_TopMost
  End With
 End Select
End Select
End Sub

Public Sub FakeDXUIPostMessage(ByVal iMsg As enumFakeDXUIMessage, Optional ByVal nParam1 As Long, Optional ByVal nParam2 As Long, Optional ByVal nParam3 As Long)
If FakeDXUIControlCount > 0 Then
 If FakeDXUIMessageQueueTail >= FakeDXUIMessageQueueMax Then
  FakeDXUIMessageQueueMax = FakeDXUIMessageQueueMax + 256
  ReDim Preserve FakeDXUIMessageQueue(FakeDXUIMessageQueueMax - 1)
 End If
 With FakeDXUIMessageQueue(FakeDXUIMessageQueueTail)
  .iMsg = iMsg
  .nParam1 = nParam1
  .nParam2 = nParam2
  .nParam3 = nParam3
 End With
 FakeDXUIMessageQueueTail = FakeDXUIMessageQueueTail + 1
End If
End Sub

Public Sub FakeDXUIDoEvents()
Dim t As typeFakeDXUIMessage
If FakeDXUIControlCount > 0 Then
 Do While FakeDXUIMessageQueueHead < FakeDXUIMessageQueueTail
  t = FakeDXUIMessageQueue(FakeDXUIMessageQueueHead)
  FakeDXUIDispatchMessage t
  FakeDXUIMessageQueueHead = FakeDXUIMessageQueueHead + 1
 Loop
 FakeDXUIMessageQueueHead = 0
 FakeDXUIMessageQueueTail = 0
End If
End Sub

Public Sub FakeDXUIDestroy()
If Not FakeDXUITexture Is Nothing Then
 Erase FakeDXUIControls
 FakeDXUIControlCount = 0
 FakeDXUIActiveWindow = 0
 FakeDXUIFocus = 0
 FakeDXUISetCapture = 0
 Set FakeDXUIDefaultFont.objFont = Nothing
 Set FakeDXUIDefaultFont.objSprite = Nothing
 Set FakeDXUIEvent = Nothing '?
 '///
 Erase FakeDXUIMessageQueue
 FakeDXUIMessageQueueHead = 0
 FakeDXUIMessageQueueTail = 0
 FakeDXUIMessageQueueMax = 0
 '///
 Set FakeDXUITexture = Nothing '?
 'TODO:
End If
End Sub

Public Sub FakeDXUIRender()
Dim i As Long
If FakeDXUIControlCount > 0 Then
 d3dd9.SetTexture 0, FakeDXUITexture
 i = d3dd9.GetRenderState(D3DRS_ALPHABLENDENABLE)
 d3dd9.SetRenderState D3DRS_ALPHABLENDENABLE, 1
 FakeDXUIControls(1).Render
 d3dd9.SetRenderState D3DRS_ALPHABLENDENABLE, i
End If
End Sub

Public Function FakeDXUIGetEmptyControl() As Long
Dim i As Long
If FakeDXUIControlCount > 0 Then
 For i = 1 To FakeDXUIControlCount
  If FakeDXUIControls(i).ControlType < 0 Then
   FakeDXUIGetEmptyControl = i
   Exit Function
  End If
 Next i
 FakeDXUIControlCount = FakeDXUIControlCount + 1
 ReDim Preserve FakeDXUIControls(1 To FakeDXUIControlCount)
 FakeDXUIControls(FakeDXUIControlCount).Index = FakeDXUIControlCount
 FakeDXUIGetEmptyControl = FakeDXUIControlCount
End If
End Function

'////////

'0=move
'1=down
'2=up
'(3=click ?)
'4=dblclick

Public Function FakeDXUIOnMouseEvent(ByVal Button As Long, ByVal Shift As Long, ByVal x As Single, ByVal y As Single, ByVal nEventType As Long) As Boolean
Dim i As Long
Dim obj As clsFakeDXUI
If FakeDXUIControlCount <= 0 Or FakeDXUISetCapture < 0 Then Exit Function
FakeDXUIMousePointer = 0
'///
If FakeDXUISetCapture > 0 And FakeDXUISetCapture <= FakeDXUIControlCount Then
 Set obj = FakeDXUIControls(FakeDXUISetCapture)
 If obj.ControlType < 0 Then Set obj = Nothing
End If
If obj Is Nothing Then Set obj = FakeDXUIControls(1)
'///
For i = 1 To FakeDXUIControlCount
 FakeDXUIControls(i).BeforeMouseEvent
Next i
FakeDXUIOnMouseEvent = obj.OnMouseEvent(Button, Shift, x, y, nEventType)
For i = 1 To FakeDXUIControlCount
 FakeDXUIControls(i).AfterMouseEvent
Next i
'///
FakeDXUIDoEvents
'///???
frmMain.MousePointer = FakeDXUIMousePointer
End Function

'////////

'0=press
'1=down
'2=up
Public Function FakeDXUIOnKeyEvent(ByVal KeyCode As Long, ByVal Shift As Long, ByVal nEventType As Long) As Boolean
Dim obj As clsFakeDXUI
If FakeDXUIControlCount <= 0 Then Exit Function
'TODO:hot key and key preview and tab,enter,esc process
'///
FakeDXUIDoEvents
End Function

'////////

Public Function FakeDXUIOnMouseWheel(ByVal nDelta As Long, ByVal Shift As Long) As Boolean
'TODO:
'///
FakeDXUIDoEvents
End Function

'////////

Public Sub FakeDXUICalcRect(t As typeFakeDXUIRectEx, ret As typeFakeDXUIRect, ByVal w As Single, ByVal h As Single)
ret.Left = t.Left.a + t.Left.b * w
ret.Top = t.Top.a + t.Top.b * h
ret.Right = t.Right.a + t.Right.b * w
ret.Bottom = t.Bottom.a + t.Bottom.b * h
End Sub

Public Sub FakeDXUICalcRect2(t As typeFakeDXUIRectEx, ret As typeFakeDXUIRect, tParent As typeFakeDXUIRect)
Dim w As Single, h As Single
w = tParent.Right - tParent.Left
h = tParent.Bottom - tParent.Top
ret.Left = t.Left.a + tParent.Left + t.Left.b * w
ret.Top = t.Top.a + tParent.Top + t.Top.b * h
ret.Right = t.Right.a + tParent.Left + t.Right.b * w
ret.Bottom = t.Bottom.a + tParent.Top + t.Bottom.b * h
End Sub

