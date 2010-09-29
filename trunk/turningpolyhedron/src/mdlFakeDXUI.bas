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

Public FakeDXUI_IME As New clsFakeDXUI_IME

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

Public Type typeFakeDXUIScrollBar
 bEnabled As Boolean
 nOrientation As Byte '0-horizontal 1-vertical
 nReserved As Byte 'changed
 nMin As Long
 nMax As Long
 nValue As Long
 nSmallChange As Long
 nLargeChange As Long
 '///
 tRect As typeFakeDXUIRect
 fThumbStart As Single
 fThumbEnd As Single
 fValuePerPixel As Single
 nCriticalValue As Long 'when pressed=2 or 4
 fStartDragPos As Single
 '///a lot of animation variables :-3
 nAnimVal(31) As Byte
 '0=highlight(0-5)
 '1-10=current(0-255)
 '11-15=goal(0-2)
 '30=timer
 '31=captured(thumb) (2-xx 4-xx xxx ??)
 'etc. (?)
End Type

Public Type typeFakeDXUITextBoxLineMetric
 nLineWidth As Long
 '///auto wrap mode
 nLineOffset As Long
 nLineHeight As Long 'wrapped line count
 nLineStart() As Long '(0-based) start character index (0-based)
 nLineLength() As Long '(0-based) wrapped line length
End Type

Public Type typeFakeDXUITextBoxPos
 nRow As Long
 nPosition As Long
End Type

Public Enum enumFakeDXUIControlType
 FakeCtl_Unused = -1
 FakeCtl_None = 0
 FakeCtl_Form = 1
 FakeCtl_Label = 2
 FakeCtl_Frame = 3
 FakeCtl_Button = 4
 FakeCtl_ScrollBar = 5
 FakeCtl_PictureBox = 6
 FakeCtl_TextBox = 7
 FakeCtl_ListView = 8
 FakeCtl_ComboBox = 9
 FakeCtl_TabStrip = 10
End Enum

Public Enum enumFakeDXUIControlStyle
 '///general
 FCS_CanGetFocus = &H1000000
 FCS_TabStop = &H2000000
 FCS_TopMost = &H10000000
 '///form
 FFS_Sizable = 1
 FFS_Moveable = 2
 FFS_MinButton = 4
 FFS_MaxButton = 8
 FFS_CloseButton = 16
 FFS_TitleBar = 32
 '///button
 FBS_CheckBox = 1
 FBS_CheckBoxTristate = 2
 FBS_OptionButton = 3
 FBS_OptionNullable = 4
 FBS_Graphical = 8
 FBS_Default = 16
 FBS_Cancel = 32
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
 FakeCtl_Msg_Change = 65003 'param1=ctlindex
 FakeCtl_Msg_ScrollChange = 65004 'param1=ctlindex
End Enum

Public FakeDXUIMessageQueue() As typeFakeDXUIMessage
Public FakeDXUIMessageQueueHead As Long
Public FakeDXUIMessageQueueTail As Long
Public FakeDXUIMessageQueueMax As Long

'///NOTE: different from GDI coloes

Public Const d_Bar1 = &HD0E2FA
Public Const d_Bar2 = &H81A9E2
Public Const d_Hl1 = &HFDFCD0
Public Const d_Hl2 = &HFDDF9D
Public Const d_Checked1 = &HFADD7D
Public Const d_Checked2 = &HF5BC4E
Public Const d_Pressed1 = &HF88655
Public Const d_Pressed2 = &HD2370A

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
FakeDXUI_IME.Create frmMain.hwnd '?
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
Case FakeCtl_Msg_Change
 If Not FakeDXUIEvent Is Nothing Then FakeDXUIEvent.Change FakeDXUIControls(t.nParam1)
Case FakeCtl_Msg_ScrollChange
 Select Case FakeDXUIControls(t.nParam1).ControlType
 Case 1, 3, 5, 6, 10
  If Not FakeDXUIEvent Is Nothing Then FakeDXUIEvent.Change FakeDXUIControls(t.nParam1)
 End Select
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
  If Not b Then FakeDXUIControls(t.nParam1).Unload
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
   .Style = .Style Or FCS_TopMost
  End With
 Case -2
  With FakeDXUIControls(t.nParam1)
   .Style = .Style And Not FCS_TopMost
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
 FakeDXUI_IME.Destroy
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

'inefficient when drawing a lot of controls (50+)
Public Sub FakeDXUIRender()
Dim i As Long
Dim r As D3DRECT
If FakeDXUIControlCount > 0 Then
 d3dd9.SetTexture 0, FakeDXUITexture
 i = d3dd9.GetRenderState(D3DRS_ALPHABLENDENABLE)
 d3dd9.SetRenderState D3DRS_ALPHABLENDENABLE, 1
 d3dd9.SetRenderState D3DRS_SCISSORTESTENABLE, 1
 r.x2 = d3dpp.BackBufferWidth
 r.Y2 = d3dpp.BackBufferHeight
 d3dd9.SetScissorRect r
 '///
 FakeDXUIControls(1).Render
 FakeDXUI_IME.Render
 '///
 d3dd9.SetRenderState D3DRS_ALPHABLENDENABLE, i
 d3dd9.SetRenderState D3DRS_SCISSORTESTENABLE, 0
 '///???
 FakeDXUIDoEvents
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

Public Function FakeDXUIFindControl(ByVal sName As String, Optional ByVal nParent As Long) As Long
Dim i As Long
If nParent > 0 And nParent <= FakeDXUIControlCount Then
 'TODO:
Else
 For i = 1 To FakeDXUIControlCount
  If FakeDXUIControls(i).Name = sName Then
   FakeDXUIFindControl = i
   Exit Function
  End If
 Next i
End If
End Function

'////////

'0=move
'1=down
'2=up
'(3=click ?)
'4=dblclick

Public Function FakeDXUIOnMouseEvent(ByVal Button As Long, ByVal Shift As Long, ByVal x As Single, ByVal y As Single, ByVal nEventType As Long) As Boolean
Dim i As Long, b As Boolean
Dim obj As clsFakeDXUI
If FakeDXUIControlCount <= 0 Or FakeDXUISetCapture < 0 Then Exit Function
FakeDXUIMousePointer = 0
'///
If FakeDXUISetCapture > 0 And FakeDXUISetCapture <= FakeDXUIControlCount Then
 Set obj = FakeDXUIControls(FakeDXUISetCapture)
 If obj.ControlType < 0 Then Set obj = Nothing
End If
If obj Is Nothing Then Set obj = FakeDXUIControls(1)
'///???
If nEventType = 0 Then
 FakeDXUI_IME.BeforeMouseEvent
 For i = 1 To FakeDXUIControlCount
  FakeDXUIControls(i).BeforeMouseEvent
 Next i
End If
'///
b = FakeDXUI_IME.OnMouseEvent(Button, Shift, x, y, nEventType)
If Not b Then b = obj.OnMouseEvent(Button, Shift, x, y, nEventType)
FakeDXUIOnMouseEvent = b
'///???
frmMain.MousePointer = FakeDXUIMousePointer
'///
FakeDXUIDoEvents
End Function

'////////

'0=press
'1=down
'2=up
'(101=default)
'(102=cancel)

Public Function FakeDXUIOnKeyEvent(ByVal KeyCode As Long, ByVal Shift As Long, ByVal nEventType As Long) As Boolean
'Dim obj As clsFakeDXUI
If FakeDXUIControlCount <= 0 Then Exit Function
Do
 'TODO:hot key and key preview
 '////////////////before
 '///enter
 If KeyCode = vbKeyReturn And Shift = 0 And nEventType = 1 Then
  If FakeDXUIActiveWindow > 0 And FakeDXUIActiveWindow <= FakeDXUIControlCount Then
   If FakeDXUIControls(FakeDXUIActiveWindow).OnKeyEvent(0, 0, 101) Then
    FakeDXUIOnKeyEvent = True
    Exit Do
   End If
  End If
 '///esc
 ElseIf KeyCode = vbKeyEscape And Shift = 0 And nEventType = 1 Then
  If FakeDXUIActiveWindow > 0 And FakeDXUIActiveWindow <= FakeDXUIControlCount Then
   If FakeDXUIControls(FakeDXUIActiveWindow).OnKeyEvent(0, 0, 102) Then
    FakeDXUIOnKeyEvent = True
    Exit Do
   End If
  End If
 End If
 '///tab
 If KeyCode = vbKeyTab And Shift = 0 And nEventType = 1 Then
  FakeDXUIToNextFocus
  FakeDXUIOnKeyEvent = True
  Exit Do
 '///shift+tab
 ElseIf KeyCode = vbKeyTab And Shift = 1 And nEventType = 1 Then
  FakeDXUIToPrevFocus
  FakeDXUIOnKeyEvent = True
  Exit Do
 '///
 End If
 '////////////////process
 If FakeDXUIFocus > 0 And FakeDXUIFocus <= FakeDXUIControlCount Then
  If FakeDXUIControls(FakeDXUIFocus).OnKeyEvent(KeyCode, Shift, nEventType) Then
   FakeDXUIOnKeyEvent = True
   Exit Do
  End If
 End If
 '////////////////after
 '///
 'TODO:
 '///
Loop While False
'///
FakeDXUIDoEvents
End Function

'////////

'???
Public Function FakeDXUIOnMouseWheel(ByVal nDelta As Long, ByVal Shift As Long) As Boolean
If FakeDXUIControlCount <= 0 Then Exit Function
'///
Do
 If FakeDXUIFocus > 0 And FakeDXUIFocus <= FakeDXUIControlCount Then
  If FakeDXUIControls(FakeDXUIFocus).OnMouseWheel(nDelta, Shift) Then
   FakeDXUIOnMouseWheel = True
   Exit Do
  End If
 End If
 '///
 If FakeDXUIActiveWindow > 0 And FakeDXUIActiveWindow <= FakeDXUIControlCount Then
  If FakeDXUIControls(FakeDXUIActiveWindow).OnMouseWheel(nDelta, Shift) Then
   FakeDXUIOnMouseWheel = True
   Exit Do
  End If
 End If
Loop While False
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

Public Sub FakeDXUIScrollBarCalcPos(ByRef t As typeFakeDXUIScrollBar)
Dim f As Single, f2 As Single
Dim f1 As Single
If t.nValue < t.nMin Then t.nValue = t.nMin Else _
If t.nValue > t.nMax Then t.nValue = t.nMax
If t.nOrientation Then 'vertical
 f = t.tRect.Top + 16
 f2 = t.tRect.Bottom - 16 - f
Else 'horizontal
 f = t.tRect.Left + 16
 f2 = t.tRect.Right - 16 - f
End If
If f2 > 0 Then
 t.fValuePerPixel = (t.nMax - t.nMin + t.nLargeChange) / f2
 If t.fValuePerPixel > 0.0001 Then f1 = t.nLargeChange / t.fValuePerPixel
 If f1 < 4 And f2 > 4 Then
  t.fValuePerPixel = (t.nMax - t.nMin) / (f2 - 4)
  f1 = 4
 End If
 t.fThumbStart = f + (t.nValue - t.nMin) / t.fValuePerPixel
 t.fThumbEnd = t.fThumbStart + f1
Else
 t.fValuePerPixel = -1
 t.fThumbStart = f
 t.fThumbEnd = f - 1
End If
End Sub

Private Function pScrollBarButtonHighlight_1(ByRef t As typeFakeDXUIScrollBar, ByVal nIndex As Long, ByVal nRetIndex As Long, ByVal Button As Long, ByVal nEventType As Long, Optional ByRef bPressed As Boolean) As Long
Dim i As Long
i = 1
bPressed = False
If Button And 1& Then
 If nEventType = 1 Then
  t.nAnimVal(0) = nIndex
  bPressed = True
  i = 2
 ElseIf nEventType = 2 Then
  'bPressed = t.nAnimVal(0) = nIndex
 ElseIf nEventType = 0 Then
  If t.nAnimVal(0) = nIndex Then i = 2 Else i = 0
 End If
End If
t.nAnimVal(nRetIndex) = i
pScrollBarButtonHighlight_1 = i
End Function

Public Function FakeDXUIOnScrollBarMouseEvent(ByVal Button As Long, ByVal Shift As Long, ByVal x As Single, ByVal y As Single, ByVal nEventType As Long, ByRef t As typeFakeDXUIScrollBar) As Boolean
Dim bInControl_0 As Boolean, bInControl As Boolean
Dim b As Boolean
Dim f As Single, f1 As Single, f2 As Single
Dim i As Long
'///
'TODO:menu,etc.
'///
If Not t.bEnabled Then Exit Function
'///
If t.nOrientation Then 'vertical
 f = t.tRect.Top
 f1 = t.tRect.Bottom
 bInControl_0 = x >= t.tRect.Left And x < t.tRect.Right
 x = y
Else 'horizontal
 f = t.tRect.Left
 f1 = t.tRect.Right
 bInControl_0 = y >= t.tRect.Top And y < t.tRect.Bottom
End If
bInControl = bInControl_0 And x >= f And x < f1
'///highlight
If nEventType = 1 Then
 t.nAnimVal(0) = 0 '???
End If
If t.nAnimVal(0) = 3 And Button = 1 And nEventType = 0 And t.fValuePerPixel > 0 Then
 '///drag thumb TODO:
 t.nAnimVal(13) = 2
 t.nAnimVal(31) = 1
 '///
 i = t.nCriticalValue + (x - t.fStartDragPos) * t.fValuePerPixel
 If i < t.nMin Then i = t.nMin Else If i > t.nMax Then i = t.nMax
 If t.nValue <> i Then
  t.nValue = i
  t.nReserved = 1
 End If
 '///
 b = True
ElseIf bInControl_0 Then
 If t.fValuePerPixel > 0 Then f2 = f + 16 Else f2 = (f + f1) / 2
 If x < f Then
 ElseIf x < f2 Then '-smallchange
  pScrollBarButtonHighlight_1 t, 1, 11, Button, nEventType, b
  If b Then
   i = t.nValue - t.nSmallChange
   If i < t.nMin Then i = t.nMin
   If t.nValue <> i Then
    t.nValue = i
    t.nReserved = 1
   End If
   t.nAnimVal(30) = 8 'TODO:adjustable timer
  End If
  b = True
 Else
  If t.fValuePerPixel > 0 Then
   If x < t.fThumbStart Then '-largechange
    pScrollBarButtonHighlight_1 t, 2, 12, Button, nEventType, b
    If b Then
     i = t.nValue - t.nLargeChange
     If i < t.nMin Then i = t.nMin
     If t.nValue <> i Then
      t.nValue = i
      t.nReserved = 1
     End If
     t.nAnimVal(30) = 8 'TODO:adjustable timer
    End If
    If t.nAnimVal(12) Then t.nCriticalValue = t.nMin + (x - f - 16) * t.fValuePerPixel
    b = True
   ElseIf x < t.fThumbEnd Then 'start drag
    pScrollBarButtonHighlight_1 t, 3, 13, Button, nEventType, b
    If b Then
     t.nCriticalValue = t.nValue
     t.fStartDragPos = x
    End If
    b = True
   ElseIf x < f1 - 16 Then '+largechange
    pScrollBarButtonHighlight_1 t, 4, 14, Button, nEventType, b
    If b Then
     i = t.nValue + t.nLargeChange
     If i > t.nMax Then i = t.nMax
     If t.nValue <> i Then
      t.nValue = i
      t.nReserved = 1
     End If
     t.nAnimVal(30) = 8 'TODO:adjustable timer
    End If
    If t.nAnimVal(14) Then t.nCriticalValue = t.nMin - t.nLargeChange + (x - f - 16) * t.fValuePerPixel
    b = True
   End If
  End If
  If x < f1 And Not b Then '+smallchange
   pScrollBarButtonHighlight_1 t, 5, 15, Button, nEventType, b
   If b Then
    i = t.nValue + t.nSmallChange
    If i > t.nMax Then i = t.nMax
    If t.nValue <> i Then
     t.nValue = i
     t.nReserved = 1
    End If
    t.nAnimVal(30) = 8 'TODO:adjustable timer
   End If
   b = True
  End If
 End If
End If
If nEventType = 2 Then
 t.nAnimVal(0) = 0 '???
 t.nAnimVal(31) = 0
End If
'///
FakeDXUIOnScrollBarMouseEvent = b
End Function

Public Sub FakeDXUIRenderScrollBarButton(ByRef t As typeFakeDXUIScrollBar, ByVal nIndex As Long, ByVal nLeft As Single, ByVal nTop As Single, ByVal nRight As Single, ByVal nBottom As Single, Optional ByVal nOpacity As Single = 1, Optional ByVal bEnabled As Boolean = True)
Dim i As Long, j As Long, k As Long
i = nOpacity * 255
i = ((i And &H7F&) * &H1000000) Or ((i > &H7F&) And &H80000000) Or &HFFFFFF
bEnabled = bEnabled And t.bEnabled
'///
If nIndex And 1& Then 'button
 k = 416 + ((t.nOrientation <> 0) And 32&)
 If bEnabled Then
  FakeDXGDIStretchBltExColored nLeft, nTop, nRight, nBottom, 0, k, 32, k + 32, 4, 4, 4, 4, 512, i
  j = t.nAnimVal(nIndex + nIndex - 1)
  If j > 0 Then
   j = j * nOpacity
   j = ((j And &H7F&) * &H1000000) Or ((j > &H7F&) And &H80000000) Or &HFFFFFF
   FakeDXGDIStretchBltExBlended nLeft, nTop, nRight, nBottom, 32, k, 64, k + 32, 4, 4, 4, 4, 512, 64, k, 255 - t.nAnimVal(nIndex + nIndex), j
  End If
 Else
  FakeDXGDIStretchBltExColored nLeft, nTop, nRight, nBottom, 96, k, 128, k + 32, 4, 4, 4, 4, 512, i
 End If
 If nIndex <> 3 Then
  j = k - 288 + ((nIndex = 5) And 16&)
  k = 384 - (bEnabled And 16&)
  nLeft = (nLeft + nRight) / 2
  nTop = (nTop + nBottom) / 2
  FakeDXGDIStretchBltColored nLeft - 8, nTop - 8, nLeft + 8, nTop + 8, j, k, j + 16, k + 16, 512, i
 End If
Else 'scroll area
 If t.nOrientation Then 'vertical
  If bEnabled Then
   FakeDXGDIStretchBltExColored nLeft, nTop, nRight, nBottom, 144, 466, 176, 466, 1, 1, 1, 1, 512, i
   j = t.nAnimVal(nIndex + nIndex - 1)
   If j > 0 Then
    j = j * nOpacity
    j = ((j And &H7F&) * &H1000000) Or ((j > &H7F&) And &H80000000) Or &HFFFFFF
    FakeDXGDIStretchBltExBlended nLeft, nTop, nRight, nBottom, 144, 470, 176, 470, 1, 1, 1, 1, 512, 144, 474, 255 - t.nAnimVal(nIndex + nIndex), j
   End If
  Else
   FakeDXGDIStretchBltExColored nLeft, nTop, nRight, nBottom, 144, 478, 176, 478, 1, 1, 1, 1, 512, i
  End If
 Else 'horizontal
  If bEnabled Then
   FakeDXGDIStretchBltExColored nLeft, nTop, nRight, nBottom, 146, 416, 146, 448, 1, 1, 1, 1, 512, i
   j = t.nAnimVal(nIndex + nIndex - 1)
   If j > 0 Then
    j = j * nOpacity
    j = ((j And &H7F&) * &H1000000) Or ((j > &H7F&) And &H80000000) Or &HFFFFFF
    FakeDXGDIStretchBltExBlended nLeft, nTop, nRight, nBottom, 150, 416, 150, 448, 1, 1, 1, 1, 512, 154, 416, 255 - t.nAnimVal(nIndex + nIndex), j
   End If
  Else
   FakeDXGDIStretchBltExColored nLeft, nTop, nRight, nBottom, 158, 416, 158, 448, 1, 1, 1, 1, 512, i
  End If
 End If
End If
End Sub

Public Sub FakeDXUIRenderScrollBar(ByRef t As typeFakeDXUIScrollBar, Optional ByVal nOpacity As Single = 1, Optional ByVal bEnabled As Boolean = True)
Dim i As Long
Dim j As Long, k As Long
Dim jj As Long, kk As Long
Dim f As Single, f2 As Single
'///
FakeDXUIScrollBarCalcPos t
'///update animation variable
bEnabled = bEnabled And t.bEnabled
If bEnabled Then
 For i = 1 To 5
  j = t.nAnimVal(i + i - 1)
  jj = t.nAnimVal(i + i)
  k = t.nAnimVal(i + 10)
  kk = (k > 1) And 255&
  k = (k > 0) And 255&
  If j < k Then j = j + 51 Else If j > k Then j = j - 51
  If jj < kk Then jj = jj + 51 Else If jj > kk Then jj = jj - 51
  t.nAnimVal(i + i - 1) = j
  t.nAnimVal(i + i) = jj
 Next i
 '///timer event
 If t.nAnimVal(11) = 2 Then '-smallchange
  i = t.nAnimVal(30) - 1
  If i <= 0 Then
   i = t.nValue - t.nSmallChange
   If i < t.nMin Then i = t.nMin
   If t.nValue <> i Then
    t.nValue = i
    t.nReserved = 1
   End If
   i = 2 'TODO:adjustable timer
  End If
  t.nAnimVal(30) = i
 ElseIf t.nAnimVal(12) = 2 Then '-largechange
  i = t.nAnimVal(30) - 1
  If i <= 0 Then
   i = t.nValue
   If i < t.nCriticalValue Then
    t.nAnimVal(12) = 0
   Else
    i = i - t.nLargeChange
    If i < t.nMin Then i = t.nMin
    If t.nValue <> i Then
     t.nValue = i
     t.nReserved = 1
    End If
   End If
   i = 2 'TODO:adjustable timer
  End If
  t.nAnimVal(30) = i
 ElseIf t.nAnimVal(14) = 2 Then '+largechange
  i = t.nAnimVal(30) - 1
  If i <= 0 Then
   i = t.nValue
   If i > t.nCriticalValue Then
    t.nAnimVal(14) = 0
   Else
    i = i + t.nLargeChange
    If i > t.nMax Then i = t.nMax
    If t.nValue <> i Then
     t.nValue = i
     t.nReserved = 1
    End If
   End If
   i = 2 'TODO:adjustable timer
  End If
  t.nAnimVal(30) = i
 ElseIf t.nAnimVal(15) = 2 Then '+smallchange
  i = t.nAnimVal(30) - 1
  If i <= 0 Then
   i = t.nValue + t.nSmallChange
   If i > t.nMax Then i = t.nMax
   If t.nValue <> i Then
    t.nValue = i
    t.nReserved = 1
   End If
   i = 2 'TODO:adjustable timer
  End If
  t.nAnimVal(30) = i
 End If
Else
 For i = 1 To 10
  t.nAnimVal(i) = 0
 Next i
End If
'///draw
If t.nOrientation Then 'vertical
 If t.fValuePerPixel > 0 Then '5 buttons
  FakeDXUIRenderScrollBarButton t, 1, t.tRect.Left, t.tRect.Top, t.tRect.Right, t.tRect.Top + 16, nOpacity, bEnabled
  FakeDXUIRenderScrollBarButton t, 2, t.tRect.Left, t.tRect.Top + 16, t.tRect.Right, t.fThumbStart, nOpacity, bEnabled
  FakeDXUIRenderScrollBarButton t, 3, t.tRect.Left, t.fThumbStart, t.tRect.Right, t.fThumbEnd, nOpacity, bEnabled
  FakeDXUIRenderScrollBarButton t, 4, t.tRect.Left, t.fThumbEnd, t.tRect.Right, t.tRect.Bottom - 16, nOpacity, bEnabled
  FakeDXUIRenderScrollBarButton t, 5, t.tRect.Left, t.tRect.Bottom - 16, t.tRect.Right, t.tRect.Bottom, nOpacity, bEnabled
 Else '2 buttons
  f = (t.tRect.Top + t.tRect.Bottom) / 2
  FakeDXUIRenderScrollBarButton t, 1, t.tRect.Left, t.tRect.Top, t.tRect.Right, f, nOpacity, bEnabled
  FakeDXUIRenderScrollBarButton t, 5, t.tRect.Left, f, t.tRect.Right, t.tRect.Bottom, nOpacity, bEnabled
 End If
Else 'horizontal
 If t.fValuePerPixel > 0 Then '5 buttons
  FakeDXUIRenderScrollBarButton t, 1, t.tRect.Left, t.tRect.Top, t.tRect.Left + 16, t.tRect.Bottom, nOpacity, bEnabled
  FakeDXUIRenderScrollBarButton t, 2, t.tRect.Left + 16, t.tRect.Top, t.fThumbStart, t.tRect.Bottom, nOpacity, bEnabled
  FakeDXUIRenderScrollBarButton t, 3, t.fThumbStart, t.tRect.Top, t.fThumbEnd, t.tRect.Bottom, nOpacity, bEnabled
  FakeDXUIRenderScrollBarButton t, 4, t.fThumbEnd, t.tRect.Top, t.tRect.Right - 16, t.tRect.Bottom, nOpacity, bEnabled
  FakeDXUIRenderScrollBarButton t, 5, t.tRect.Right - 16, t.tRect.Top, t.tRect.Right, t.tRect.Bottom, nOpacity, bEnabled
 Else '2 buttons
  f = (t.tRect.Left + t.tRect.Right) / 2
  FakeDXUIRenderScrollBarButton t, 1, t.tRect.Left, t.tRect.Top, f, t.tRect.Bottom, nOpacity, bEnabled
  FakeDXUIRenderScrollBarButton t, 5, f, t.tRect.Top, t.tRect.Right, t.tRect.Bottom, nOpacity, bEnabled
 End If
End If
End Sub

Public Sub FakeDXUIToNextFocus()
Dim idx As Long, idxOld As Long
Dim i As Long, j As Long, k As Long, m As Long
i = FakeDXUIFocus
If i = 0 Then i = FakeDXUIActiveWindow
If i > 0 And i <= FakeDXUIControlCount Then
 idxOld = i
 Do
  idx = i
  i = 0
  With FakeDXUIControls(idx)
   If .Enabled And .Visible Then
    If (.Style And FCS_TabStop) <> 0 And idx <> FakeDXUIFocus Then
     i = -1
    Else
     If .ChildrenCount > 0 Then 'first children
      i = .Children(1)
      If FakeDXUIControls(i).ControlType = FakeCtl_Form Then i = 0
     End If
    End If
   End If
  End With
  If i = 0 Then
   Do
    If FakeDXUIControls(idx).ControlType = FakeCtl_Form Then
     i = idx
     Exit Do
    End If
    j = FakeDXUIControls(idx).Parent
    If j > 0 And j <= FakeDXUIControlCount Then
     k = FakeDXUIControls(idx).ChildIndex + 1
     m = FakeDXUIControls(j).ChildrenCount
     Do Until k > m Or i <> 0 'next sibling
      i = FakeDXUIControls(j).Children(k)
      If FakeDXUIControls(i).ControlType = FakeCtl_Form Then i = 0
      k = k + 1
     Loop
     If i = 0 Then idx = j 'parent
     If i Then Exit Do
    Else
     i = idx
     Exit Do
    End If
   Loop
  End If
 Loop Until i <= 0 Or i = idxOld
 If i < 0 Then FakeDXUIFocus = idx
End If
End Sub

Public Sub FakeDXUIToPrevFocus()
Dim idx As Long, idxOld As Long
Dim i As Long, j As Long, k As Long
i = FakeDXUIFocus
If i = 0 Then i = FakeDXUIActiveWindow
If i > 0 And i <= FakeDXUIControlCount Then
 idxOld = i
 Do
  idx = i
  i = 0
  With FakeDXUIControls(idx)
   If .Enabled And .Visible Then
    If (.Style And FCS_TabStop) <> 0 And idx <> FakeDXUIFocus Then i = -1
   End If
   j = .Parent
   If .ControlType = FakeCtl_Form Then j = 0
   k = .ChildIndex
  End With
  'last node of previous sibling
  If i = 0 Then
   If j > 0 And j <= FakeDXUIControlCount Then
    If k > 1 Then
     i = FakeDXUIControls(j).Children(k - 1)
    End If
   Else
    k = FakeDXUIControls(idx).ChildrenCount
    If k > 0 Then i = FakeDXUIControls(idx).Children(k)
   End If
   If i Then
    Do
     With FakeDXUIControls(i)
      k = .ChildrenCount
      If .Enabled And .Visible And .ControlType <> FakeCtl_Form And k > 0 Then j = .Children(k) Else j = -1
     End With
     If j > 0 Then i = j Else Exit Do
    Loop
   End If
  End If
  'parent
  If i = 0 Then i = j
 Loop Until i <= 0 Or i = idxOld
 If i < 0 Then FakeDXUIFocus = idx
End If
End Sub

