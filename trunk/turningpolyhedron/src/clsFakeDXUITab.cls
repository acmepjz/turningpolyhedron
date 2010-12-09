VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsFakeDXUITab"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'///FakeDXUITab - modified from TabHeader2

Private Type RECT
    Left As Long
    Top As Long
    Right As Long
    Bottom As Long
End Type

Private Type typeTab
 Caption As String
 Tag As String
 nFlags As Long
 '1-enabled
 '2-closable
 w As Long
End Type

Private bShowClose As Boolean

Private tabs() As typeTab, tabc As Long
Private tsld As Long, thl As Long, tleft As Long, pr As Boolean
Private thl2 As Boolean
Private t As Long

'left button and right button
Private btn1 As Boolean, btn2 As Boolean, bhl As Long
'btn1 is visible!!!
Private btn3 As Boolean 'close button

Private thl_old As Long, thl2_old As Boolean, bhl_old As Long

Private bTimerEnabled As Boolean, m_nWidth As Long, m_nHeight As Long
Private m_bEnabled As Boolean

Private m_bCapture As Boolean

Public Event TabClick(ByVal TabIndex As Long)
Public Event ContextMenu(ByVal TabIndex As Long)
Public Event TabClose(ByVal TabIndex As Long, ByRef Cancel As Boolean)

Friend Property Get Enabled() As Boolean
Enabled = m_bEnabled
End Property

Friend Property Let Enabled(ByVal b As Boolean)
m_bEnabled = b
End Property

Friend Property Get ShowCloseButtonOnTab() As Boolean
ShowCloseButtonOnTab = bShowClose
End Property

Friend Property Let ShowCloseButtonOnTab(ByVal b As Boolean)
If bShowClose <> b Then
 bShowClose = b
 RefreshSize
End If
End Property

Friend Sub OnMouseDown(ByVal Button As Long, ByVal Shift As Long, ByVal x As Long, ByVal y As Long)
If thl > 0 Or bhl > 0 Then
 '///
 thl_old = thl
 thl2_old = thl2
 bhl_old = bhl
 '///
 t = 8 'TODO:adjustable timer
 bTimerEnabled = bhl > 0
 pr = True
End If
End Sub

Friend Sub OnMouseMove(ByVal Button As Long, ByVal Shift As Long, ByVal x As Long, ByVal y As Long)
Dim i As Long, j As Long, xx As Long
Dim b As Boolean
'tab highlight?
xx = 16
i = tleft
Do
 If i > tabc Or i <= 0 Then Exit Do
 xx = xx + tabs(i).w
 If xx > m_nWidth - 16 Then Exit Do
 If x >= xx - tabs(i).w And x < xx And y >= 0 And y < m_nHeight Then
  j = i
  If (tabs(i).nFlags And 3&) = 3& And bShowClose Then
   If x >= xx - 15 And x < xx - 2 Then
    b = y >= m_nHeight \ 2 - 7 And y < m_nHeight \ 2 + 6
   End If
  End If
  Exit Do
 End If
 i = i + 1
Loop
If j > 0 Then
 If Button Then
  If thl_old <> j Or thl2_old <> b Then j = 0
 End If
 If thl <> j Or thl2 <> b Then
  thl = j
  thl2 = b
  bhl = 0
 End If
Else
 If x >= 0 And x < 16 And y >= 0 And y < 16 And btn1 And tleft > 1 Then
  j = 1
 ElseIf x >= m_nWidth - 16 And x < m_nWidth And y >= 0 And y < 16 And ((btn1 And btn2) Or btn3) Then
  If btn3 Then j = 3 Else j = 2
 ElseIf x >= m_nWidth - 32 And x < m_nWidth - 16 And y >= 0 And y < 16 And btn1 And btn2 And btn3 Then
  j = 2
 End If
 If Button Then
  If bhl_old <> j Then j = 0
 End If
 If thl > 0 Or bhl <> j Then
  thl = 0
  bhl = j
 End If
End If
''///capture (???)
'If x >= 0 And x < m_nWidth And y >= 0 And y <= m_nHeight Then
' m_bCapture = True
'Else
' If Button = 0 Then m_bCapture = False
'End If
End Sub

Friend Sub OnMouseUp(ByVal Button As Long, ByVal Shift As Long, ByVal x As Long, ByVal y As Long)
Dim b As Boolean
If pr Then
 pr = False
 bTimerEnabled = False
 If thl > 0 Then
  If tabs(thl).nFlags And 1& Then
   If Button = 1 Then
    If thl2 Then
     RaiseEvent TabClose(thl, b)
     If Not b Then RemoveTab thl
    Else
     tsld = thl
     RaiseEvent TabClick(tsld)
    End If
   ElseIf Button = 2 Then
    RaiseEvent ContextMenu(thl)
   End If
  End If
 ElseIf tsld > 0 And tsld <= tabc And bhl = 3 Then
  RaiseEvent TabClose(tsld, b)
  If Not b Then RemoveTab tsld
 End If
 thl = 0
 bhl = 0
End If
End Sub

Friend Sub RefreshSize()
Dim i As Long
For i = 1 To tabc
 CalcTabSize tabs(i)
Next i
End Sub

Friend Function AddTab(ByVal Caption As String, Optional ByVal Index As Long, Optional ByVal Enabled As Boolean = True, Optional ByVal Tag As String, Optional ByVal Closable As Boolean = False) As Long
Dim i As Long
tabc = tabc + 1
ReDim Preserve tabs(1 To tabc)
If Index = 0 Or Index >= tabc Then
 i = tabc
Else
 For i = tabc - 1 To Index Step -1
  tabs(i + 1) = tabs(i)
 Next i
 i = Index
End If
If tsld >= i Then tsld = tsld + 1
With tabs(i)
 .Caption = Caption
 .Tag = Tag
 .nFlags = (Enabled And 1&) Or (Closable And 2&)
End With
CalcTabSize tabs(i)
AddTab = i
End Function

Friend Sub RemoveTab(ByVal Index As Long)
Dim i As Long
If Index <= 0 Or Index > tabc Then Exit Sub
If tabc = 1 Then
 Erase tabs
 tabc = 0
 tsld = 0
Else
 If Index < tabc Then
  For i = Index To tabc - 1
   tabs(i) = tabs(i + 1)
  Next i
 End If
 i = tabc
 tabc = tabc - 1
 ReDim Preserve tabs(1 To tabc)
 If tsld = Index Then
  If tsld > tabc Then tsld = tabc
  RaiseEvent TabClick(tsld)
 ElseIf tsld > Index Then
  tsld = tsld - 1
 End If
End If
End Sub

Friend Property Get TabEnabled(ByVal Index As Long) As Boolean
TabEnabled = tabs(Index).nFlags And 1&
End Property

Friend Property Let TabEnabled(ByVal Index As Long, ByVal b As Boolean)
If (tabs(Index).nFlags Xor b) And 1& Then
 tabs(Index).nFlags = (tabs(Index).nFlags And Not 1&) Or (b And 1&)
End If
End Property

Friend Property Get TabClosable(ByVal Index As Long) As Boolean
TabClosable = tabs(Index).nFlags And 2&
End Property

Friend Property Let TabClosable(ByVal Index As Long, ByVal b As Boolean)
If (tabs(Index).nFlags Xor b) And 2& Then
 tabs(Index).nFlags = (tabs(Index).nFlags And Not 2&) Or (b And 2&)
 CalcTabSize tabs(Index)
End If
End Property

Friend Property Get TabCaption(ByVal Index As Long) As String
TabCaption = tabs(Index).Caption
End Property

Friend Property Let TabCaption(ByVal Index As Long, ByVal s As String)
If tabs(Index).Caption <> s Then
 tabs(Index).Caption = s
 CalcTabSize tabs(Index)
End If
End Property

Friend Property Get TabTag(ByVal Index As Long) As String
TabTag = tabs(Index).Tag
End Property

Friend Property Let TabTag(ByVal Index As Long, ByVal s As String)
tabs(Index).Tag = s
End Property

Private Sub CalcTabSize(d As typeTab)
Dim w As Single
FakeDXGDIDrawText FakeDXUIDefaultFont, d.Caption, 0, 0, , , 0.5, DT_SINGLELINE Or DT_CALCRECT, 0, , , , , , , , w
If (d.nFlags And 2&) <> 0 And bShowClose Then w = w + 14
d.w = w + 6
End Sub

Friend Property Get SelectedTab() As Long
SelectedTab = tsld
End Property

Friend Property Let SelectedTab(ByVal n As Long)
If n > 0 And n <= tabc And n <> tsld Then
 tsld = n
 RaiseEvent TabClick(tsld)
End If
End Property

Friend Sub BeforeMouseEvent()
thl = 0
bhl = 0
End Sub

Friend Property Get TabCount() As Long
TabCount = tabc
End Property

Friend Function OnMouseEvent(ByVal Button As Long, ByVal Shift As Long, ByVal xClient As Single, ByVal yClient As Single, ByVal nEventType As Long) As Boolean
Dim bInControl As Boolean
If Not m_bEnabled Then Exit Function
bInControl = xClient >= 0 And xClient < m_nWidth And yClient >= 0 And yClient < m_nHeight
Select Case nEventType
Case 0 'mousemove
 If (m_bCapture And Button = 1) Or (bInControl And Button <> 1) Then
  OnMouseMove Button, Shift, xClient, yClient
  OnMouseEvent = True
 End If
Case 1 'mousedown
 If bInControl Then
  OnMouseDown Button, Shift, xClient, yClient
  If Button = 1 Then m_bCapture = True
  OnMouseEvent = True
 End If
Case 2 'mouseup
 If (m_bCapture And Button = 1) Or (bInControl And Button <> 1) Then
  OnMouseUp Button, Shift, xClient, yClient
  If Button = 1 Then m_bCapture = False
  OnMouseEvent = True
 End If
End Select
End Function

Friend Sub Render(Optional ByVal nLeft As Single, Optional ByVal nTop As Single, Optional ByVal nOpacity As Single = 1)
Dim i As Long, x As Long
Dim r As RECT
Dim r2 As RECT
Dim clr0 As Long, clr As Long
'///OnTimer
If bTimerEnabled Then
 If (t And 7&) = 0 Then
  If btn1 And tleft > 1 And bhl = 1 Then tleft = tleft - 1
  If btn1 And btn2 And bhl = 2 Then tleft = tleft + 1
  If t = 0 Then t = 2 'TODO:adjustable timer
 End If
 t = t - 1
End If
'///
clr0 = nOpacity * 255
clr0 = ((clr0 And &H7F&) * &H1000000) Or ((clr0 > &H7F&) And &H80000000)
clr = clr0 Or &HFFFFFF
'///check btn1 and btn3
For i = 1 To tabc
 x = x + tabs(i).w
Next i
btn3 = False
If tsld > 0 And tsld <= tabc And Not bShowClose Then
 If (tabs(tsld).nFlags And 3&) = 3& Then
  btn3 = True
  x = x + 16
 End If
End If
btn1 = x > m_nWidth - 32
If Not btn1 Then tleft = 1
'///tab
x = 16
i = tleft
btn2 = False
Do
 If i > tabc Or i <= 0 Then Exit Do
 r.Left = x
 x = x + tabs(i).w
 r.Right = x + 1
 If x > m_nWidth - 16 Then
  x = x - tabs(i).w
  btn2 = True
  Exit Do
 End If
 r.Top = 0
 r.Bottom = m_nHeight
 'bg
 If thl = i And (tabs(i).nFlags And 1&) <> 0 And Not thl2 Then
  If pr Or tsld = i Then 'pressed
   FakeDXGDIStretchBltExColored nLeft + r.Left - 4, nTop + r.Top - 4, nLeft + r.Right + 4, nTop + r.Bottom, 164, 284, 204, 312, 8, 8, 8, 0, 512, clr
  Else 'highlight
   FakeDXGDIStretchBltExColored nLeft + r.Left - 4, nTop + r.Top - 4, nLeft + r.Right + 4, nTop + r.Bottom, 84, 284, 124, 312, 8, 8, 8, 0, 512, clr
  End If
 ElseIf tsld = i Then 'checked
  FakeDXGDIStretchBltExColored nLeft + r.Left - 4, nTop + r.Top - 4, nLeft + r.Right + 4, nTop + r.Bottom, 124, 284, 164, 312, 8, 8, 8, 0, 512, clr
 Else 'normal
  FakeDXGDIStretchBltExColored nLeft + r.Left - 4, nTop + r.Top - 4, nLeft + r.Right + 4, nTop + r.Bottom, 44, 284, 84, 312, 8, 8, 8, 0, 512, clr
 End If
 'text
 FakeDXGDIDrawText FakeDXUIDefaultFont, tabs(i).Caption, nLeft + r.Left + 2, nTop + r.Top, 0, m_nHeight, 0.5, DT_VCENTER Or DT_SINGLELINE Or DT_NOCLIP, clr0 Or (&H666666 And (tabs(i).nFlags And 1&) = 0), , , , , , , True
 'close button
 If (tabs(i).nFlags And 2&) <> 0 And bShowClose Then
  r2.Left = r.Right - 16
  r2.Top = r.Bottom \ 2 - 7
  r2.Right = r2.Left + 13
  r2.Bottom = r2.Top + 13
  If thl = i And (tabs(i).nFlags And 1&) <> 0 And thl2 Then
   If pr Then
    FakeDXGDIStretchBltColored nLeft + r2.Left, nTop + r2.Top, nLeft + r2.Right, nTop + r2.Bottom, 288, 48, 301, 61, 512, clr
   Else
    FakeDXGDIStretchBltColored nLeft + r2.Left, nTop + r2.Top, nLeft + r2.Right, nTop + r2.Bottom, 272, 48, 285, 61, 512, clr
   End If
  End If
  FakeDXGDIStretchBltColored nLeft + r2.Left, nTop + r2.Top, nLeft + r2.Right, nTop + r2.Bottom, 256, 48, 269, 61, 512, clr
 End If
 i = i + 1
Loop
'button
If btn1 Then 'left button
 If tleft > 1 Then
  If bhl = 1 Then
   If pr Then
    FakeDXGDIStretchBltColored nLeft, nTop, nLeft + 16, nTop + 16, 256, 24, 272, 40, 512, clr
   Else
    FakeDXGDIStretchBltColored nLeft, nTop, nLeft + 16, nTop + 16, 232, 24, 248, 40, 512, clr
   End If
  End If
  FakeDXGDIStretchBltColored nLeft, nTop, nLeft + 16, nTop + 16, 128, 368, 144, 384, 512, clr
 Else
  FakeDXGDIStretchBltColored nLeft, nTop, nLeft + 16, nTop + 16, 128, 384, 144, 400, 512, clr
 End If
 x = m_nWidth - 16
 If btn3 Then x = x - 16
 If btn2 Then 'right button
  If bhl = 2 Then
   If pr Then
    FakeDXGDIStretchBltColored nLeft + x, nTop, nLeft + x + 16, nTop + 16, 256, 24, 272, 40, 512, clr
   Else
    FakeDXGDIStretchBltColored nLeft + x, nTop, nLeft + x + 16, nTop + 16, 232, 24, 248, 40, 512, clr
   End If
  End If
  FakeDXGDIStretchBltColored nLeft + x, nTop, nLeft + x + 16, nTop + 16, 144, 368, 160, 384, 512, clr
 Else
  FakeDXGDIStretchBltColored nLeft + x, nTop, nLeft + x + 16, nTop + 16, 144, 384, 160, 400, 512, clr
 End If
End If
'close button
If btn3 Then
 x = m_nWidth - 16
 If bhl = 3 Then
  If pr Then
   FakeDXGDIStretchBltColored nLeft + x, nTop, nLeft + x + 16, nTop + 16, 256, 24, 272, 40, 512, clr
  Else
   FakeDXGDIStretchBltColored nLeft + x, nTop, nLeft + x + 16, nTop + 16, 232, 24, 248, 40, 512, clr
  End If
 End If
 FakeDXGDIStretchBltColored nLeft + x + 2, nTop + 2, nLeft + x + 15, nTop + 15, 256, 48, 269, 61, 512, clr
End If
'///
'over
End Sub

Friend Property Get Width() As Long
Width = m_nWidth
End Property

Friend Property Let Width(ByVal n As Long)
m_nWidth = n
End Property

Friend Property Get Height() As Long
Height = m_nHeight
End Property

Friend Property Let Height(ByVal n As Long)
m_nHeight = n
End Property

Private Sub Class_Initialize()
tleft = 1
m_bEnabled = True
End Sub
