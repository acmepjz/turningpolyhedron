VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsFakeDXUI"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Const m_nFontZoom As Single = 0.5

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)

Private m_nType As Long, m_nIndex As Long, m_nChildIndex As Long
Private m_sName As String
Private m_nStyle As Long
Private m_nState As Long

Private m_sCaption As String, m_sText As String, m_sGroupName As String
Private m_bEnabled As Boolean, m_bVisible As Boolean, m_bLocked As Boolean
Private m_nValue As Long
Private m_nScrollBars As ScrollBarConstants

Private m_tRectEx As typeFakeDXUIRectEx, m_tRectEx_Backup As typeFakeDXUIRectEx
Private m_tRect As typeFakeDXUIRect
Private m_bSizeDirty As Boolean

Private m_tClientToScreenOffset As typeFakeDXUIPoint
Private m_tRectScreen As typeFakeDXUIRect
Private m_tClientMargin As typeFakeDXUIRect

Private m_nClosing As Long
Private m_nAnimVal(31) As Integer
'0=window is active? (0-255)
'1-3=current(0-255-510)
'4-6=goal(0-255-510)
'7=current(0-255) (check3state)
'14=control is focus? (0-255)
'15=highlight(0-3-?)

Private m_tDragFirst As typeFakeDXUIPoint, m_tDragLast As typeFakeDXUIPoint

Private m_idxParent As Long
Private m_idxChildren() As Long '1-based
Private m_nChildrenCount As Long
Private m_idxFocus As Long 'focus control on form

'Private m_bMouseIn As Boolean

'////////scroll bar

Private m_tScrollBar(1) As typeFakeDXUIScrollBar

'////////text box

Private m_objTextBox As clsFakeDXUITextBox

Friend Property Get Focus() As Long
Focus = m_idxFocus
End Property

'internal use only
Friend Property Let Focus(ByVal n As Long)
m_idxFocus = n
End Property

Friend Property Get ScrollBars() As ScrollBarConstants
ScrollBars = m_nScrollBars
End Property

Friend Property Let ScrollBars(ByVal n As ScrollBarConstants)
If m_nScrollBars = n Then Exit Property
m_nScrollBars = n
m_bSizeDirty = True
'///
If Not m_objTextBox Is Nothing Then
 m_objTextBox.Wrap = (n And vbHorizontal) = 0 And m_objTextBox.MultiLine
End If
'TODO:
End Property

Friend Property Get MultiLine() As Boolean
If Not m_objTextBox Is Nothing Then MultiLine = m_objTextBox.MultiLine
End Property

Friend Property Let MultiLine(ByVal b As Boolean)
If Not m_objTextBox Is Nothing Then
 m_objTextBox.MultiLine = b
 m_objTextBox.Wrap = (m_nScrollBars And vbHorizontal) = 0 And b
 m_bSizeDirty = True
End If
End Property

Friend Property Get Min(Optional ByVal nIndex As Long) As Long
Min = m_tScrollBar(nIndex).nMin
End Property

Friend Property Let Min(Optional ByVal nIndex As Long, ByVal n As Long)
Select Case m_nType
Case 1, 3, 5, 6, 10
 With m_tScrollBar(nIndex)
  .nMin = n
  If .nValue < n Then
   .nValue = n
   .nReserved = 1
  End If
 End With
 'TODO:
End Select
End Property

Friend Property Get Max(Optional ByVal nIndex As Long) As Long
Max = m_tScrollBar(nIndex).nMax
End Property

Friend Property Let Max(Optional ByVal nIndex As Long, ByVal n As Long)
Select Case m_nType
Case 1, 3, 5, 6, 10
 With m_tScrollBar(nIndex)
  .nMax = n
  If .nValue > n Then
   .nValue = n
   .nReserved = 1
  End If
 End With
 'TODO:
End Select
End Property

Friend Property Get SmallChange(Optional ByVal nIndex As Long) As Long
SmallChange = m_tScrollBar(nIndex).nSmallChange
End Property

Friend Property Let SmallChange(Optional ByVal nIndex As Long, ByVal n As Long)
If n < 0 Then Exit Property
m_tScrollBar(nIndex).nSmallChange = n
'TODO:
End Property

Friend Property Get LargeChange(Optional ByVal nIndex As Long) As Long
LargeChange = m_tScrollBar(nIndex).nLargeChange
End Property

Friend Property Let LargeChange(Optional ByVal nIndex As Long, ByVal n As Long)
If n < 0 Then Exit Property
m_tScrollBar(nIndex).nLargeChange = n
'TODO:
End Property

Friend Property Get Orientation() As Long
Select Case m_nType
Case 5
 Orientation = m_tScrollBar(0).nOrientation
End Select
End Property

Friend Property Let Orientation(ByVal n As Long)
Select Case m_nType
Case 5
 m_tScrollBar(0).nOrientation = n
 'TODO:
End Select
End Property

Friend Property Get Value(Optional ByVal nIndex As Long) As Long
Select Case m_nType
Case 1, 3, 5, 6, 10
 Value = m_tScrollBar(nIndex).nValue
Case Else
 Value = m_nValue
End Select
End Property

Friend Property Let Value(Optional ByVal nIndex As Long, ByVal n As Long)
Dim i As Long, j As Long, k As Long
Select Case m_nType
Case 1, 3, 5, 6, 10
 With m_tScrollBar(nIndex)
  If n < .nMin Then n = .nMin Else If n > .nMax Then n = .nMax
  If .nValue <> n Then
   .nValue = n
   .nReserved = 1
  End If
 End With
 'TODO:
Case 4 'button
 m_nValue = n
 If n Then
  k = m_nStyle And 7&
  Select Case k
  Case 3, 4
   If m_idxParent > 0 And m_idxParent <= FakeDXUIControlCount Then
    With FakeDXUIControls(m_idxParent)
     For i = 1 To .ChildrenCount
      j = .Children(i)
      If j > 0 And j <= FakeDXUIControlCount And j <> m_nIndex Then
       With FakeDXUIControls(j)
        If .ControlType = 4 Then
         If (.Style And 7&) = k Then
          If .GroupName = m_sGroupName Then .Value = 0
         End If
        End If
       End With
      End If
     Next i
    End With
   End If
  End Select
 End If
End Select
End Property

Friend Property Get Name() As String
Name = m_sName
End Property

Friend Property Let Name(ByRef s As String)
m_sName = s
End Property

Friend Property Get Caption() As String
Caption = m_sCaption
End Property

Friend Property Let Caption(ByRef s As String)
m_sCaption = s
End Property

Friend Property Get Text() As String
If Not m_objTextBox Is Nothing Then
 Text = m_objTextBox.Text
Else
 Text = m_sText
End If
End Property

Friend Property Let Text(ByRef s As String)
If Not m_objTextBox Is Nothing Then
 m_objTextBox.Text = s
Else
 m_sText = s
End If
End Property

Friend Property Get GroupName() As String
GroupName = m_sGroupName
End Property

Friend Property Let GroupName(ByRef s As String)
m_sGroupName = s
End Property

Friend Property Get ChildrenCount() As Long
ChildrenCount = m_nChildrenCount
End Property

Friend Property Get Children(ByVal nIndex As Long) As Long
Children = m_idxChildren(nIndex)
End Property

Friend Sub BringToFront()
If m_idxParent > 0 And m_idxParent <= FakeDXUIControlCount Then
 FakeDXUIControls(m_idxParent).BringChildrenToFront m_nChildIndex
End If
End Sub

Friend Sub SendToBack()
If m_idxParent > 0 And m_idxParent <= FakeDXUIControlCount Then
 FakeDXUIControls(m_idxParent).SendChildrenToBack m_nChildIndex
End If
End Sub

Friend Sub BringChildrenToFront(ByVal nIndex As Long, Optional ByVal ByControlIndex As Boolean)
Dim i As Long, j As Long
If ByControlIndex Then
 For i = 1 To m_nChildrenCount
  If m_idxChildren(i) = nIndex Then Exit For
 Next i
Else
 i = nIndex
 nIndex = m_idxChildren(i)
End If
If i > 0 And i < m_nChildrenCount Then
 Do
  j = m_idxChildren(i + 1)
  m_idxChildren(i) = j
  FakeDXUIControls(j).ChildIndex = i
  i = i + 1
 Loop While i < m_nChildrenCount
 m_idxChildren(m_nChildrenCount) = nIndex
 FakeDXUIControls(nIndex).ChildIndex = m_nChildrenCount
End If
End Sub

Friend Sub SendChildrenToBack(ByVal nIndex As Long, Optional ByVal ByControlIndex As Boolean)
Dim i As Long, j As Long
If ByControlIndex Then
 For i = 1 To m_nChildrenCount
  If m_idxChildren(i) = nIndex Then Exit For
 Next i
Else
 i = nIndex
 nIndex = m_idxChildren(i)
End If
If i > 1 And i <= m_nChildrenCount Then
 Do
  j = m_idxChildren(i - 1)
  m_idxChildren(i) = j
  FakeDXUIControls(j).ChildIndex = i
  i = i - 1
 Loop While i > 1
 m_idxChildren(1) = nIndex
 FakeDXUIControls(nIndex).ChildIndex = 1
End If
End Sub

Friend Function AddNewChildren(ByVal nType As enumFakeDXUIControlType, ByVal nLeft As Single, ByVal nTop As Single, ByVal nRight As Single, ByVal nBottom As Single, Optional ByVal nStyle As enumFakeDXUIControlStyle, Optional ByVal bEnabled As Boolean = True, Optional ByVal bVisible As Boolean = True, Optional ByVal bLocked As Boolean = False, Optional ByVal sCaption As String, Optional ByVal sText As String, Optional ByVal sName As String, Optional ByVal nLeft2 As Single, Optional ByVal nTop2 As Single, Optional ByVal nRight2 As Single, Optional ByVal nBottom2 As Single, Optional ByVal nValue As Long, Optional ByVal sGroupName As String) As clsFakeDXUI
Dim i As Long
i = FakeDXUIGetEmptyControl
With FakeDXUIControls(i)
 .ControlType = nType
 .SetLeftEx nLeft, nLeft2
 .SetTopEx nTop, nTop2
 .SetRightEx nRight, nRight2
 .SetBottomEx nBottom, nBottom2
 .Style = nStyle
 .Enabled = bEnabled
 .Visible = bVisible
 .Locked = bLocked
 .Caption = sCaption
 .Text = sText
 .Name = sName
 .Value = nValue
 .GroupName = sGroupName
 '///
 .Parent = m_nIndex
End With
AddChildren i
Set AddNewChildren = FakeDXUIControls(i)
End Function

Friend Property Get ChildIndex() As Long
ChildIndex = m_nChildIndex
End Property

Friend Property Let ChildIndex(ByVal n As Long)
m_nChildIndex = n
End Property

Friend Sub AddChildren(ByVal nControlIndex As Long, Optional ByVal nIndex As Long)
Dim i As Long, j As Long
If nIndex <= 0 Or nIndex > m_nChildrenCount Then nIndex = m_nChildrenCount + 1
m_nChildrenCount = m_nChildrenCount + 1
ReDim Preserve m_idxChildren(1 To m_nChildrenCount)
For i = m_nChildrenCount To nIndex + 1 Step -1
 j = m_idxChildren(i - 1)
 m_idxChildren(i) = j
 FakeDXUIControls(j).ChildIndex = i
Next i
m_idxChildren(nIndex) = nControlIndex
FakeDXUIControls(nControlIndex).ChildIndex = nIndex
End Sub

Friend Sub RemoveChildren(ByVal nIndex As Long, Optional ByVal ByControlIndex As Boolean, Optional ByVal bDestroy As Boolean)
Dim i As Long, j As Long, k As Long
If ByControlIndex Then
 For i = 1 To m_nChildrenCount
  If m_idxChildren(i) = nIndex Then Exit For
 Next i
 If i > m_nChildrenCount Then Exit Sub
 k = nIndex
 nIndex = i
Else
 If nIndex <= 0 Or nIndex > m_nChildrenCount Then Exit Sub
 k = m_idxChildren(nIndex)
End If
'///
For i = nIndex To m_nChildrenCount - 1
 j = m_idxChildren(i + 1)
 m_idxChildren(i) = j
 FakeDXUIControls(j).ChildIndex = i
Next i
If m_nChildrenCount > 1 Then
 m_nChildrenCount = m_nChildrenCount - 1
 ReDim Preserve m_idxChildren(1 To m_nChildrenCount)
Else
 m_nChildrenCount = 0
 Erase m_idxChildren
End If
FakeDXUIControls(k).ChildIndex = 0
If bDestroy Then FakeDXUIControls(k).Destroy
End Sub

Friend Property Get Parent() As Long
Parent = m_idxParent
End Property

Friend Property Let Parent(ByVal n As Long)
m_idxParent = n
m_bSizeDirty = True
End Property

Friend Property Get Index() As Long
Index = m_nIndex
End Property

'internal use only
Friend Property Let Index(ByVal n As Long)
m_nIndex = n
End Property

Friend Property Get Style() As enumFakeDXUIControlStyle
Style = m_nStyle
End Property

Friend Property Let Style(ByVal n As enumFakeDXUIControlStyle)
m_nStyle = n
'TODO:
End Property

Friend Sub Minimize()
If (m_nState And 3&) <> 2& Then State = (m_nState And Not 3&) Or 2& _
Else State = m_nState And Not 3&
End Sub

Friend Sub Maximize()
If (m_nState And 3&) <> 1& Then State = (m_nState And Not 3&) Or 1& _
Else State = m_nState And Not 3&
End Sub

Friend Property Get State() As enumFakeDXUIControlState
State = m_nState
End Property

Friend Property Let State(ByVal n As enumFakeDXUIControlState)
Dim i As Long, iOld As Long
iOld = m_nState And 3&
i = n And 3&
m_nState = n
'///check windowstate
If i <> iOld Then
 Select Case i
 Case 0
  m_tRectEx = m_tRectEx_Backup
  m_bSizeDirty = True
 Case 1 'maximized
  If iOld = 0 Then m_tRectEx_Backup = m_tRectEx
  With m_tRectEx
   .Left.a = 0
   .Left.b = 0
   .Top.a = 0
   .Top.b = 0
   .Right.a = 0
   .Right.b = 1
   .Bottom.a = 0
   .Bottom.b = 1
  End With
  m_bSizeDirty = True
 Case 2 'minimized
  If iOld = 0 Then m_tRectEx_Backup = m_tRectEx _
  Else m_tRectEx = m_tRectEx_Backup
  With m_tRectEx
   .Bottom = .Top
   .Bottom.a = .Bottom.a + 24
  End With
  m_bSizeDirty = True
 End Select
End If
'///
'TODO:
End Property

Friend Property Get Enabled() As Boolean
Enabled = m_bEnabled
End Property

Friend Property Let Enabled(ByVal b As Boolean)
m_bEnabled = b
Select Case m_nType
Case 5
 m_tScrollBar(0).bEnabled = b
End Select
End Property

Friend Property Get ScrollBarEnabled(Optional ByVal nIndex As Long) As Boolean
ScrollBarEnabled = m_tScrollBar(nIndex).bEnabled
End Property

Friend Property Let ScrollBarEnabled(Optional ByVal nIndex As Long, ByVal b As Boolean)
m_tScrollBar(nIndex).bEnabled = b
End Property

Friend Property Get Visible() As Boolean
Visible = m_bVisible
End Property

Friend Property Let Visible(ByVal b As Boolean)
m_bVisible = b
If Not b Then Erase m_nAnimVal '??
End Property

Friend Property Get Locked() As Boolean
Locked = m_bLocked
End Property

Friend Property Let Locked(ByVal b As Boolean)
m_bLocked = b
End Property

Friend Property Get ControlType() As enumFakeDXUIControlType
ControlType = m_nType
End Property

Friend Property Let ControlType(ByVal n As enumFakeDXUIControlType)
If m_nType = n Then Exit Property
m_nType = n
m_bSizeDirty = True
'///
Set m_objTextBox = Nothing
Select Case n
Case 5
 m_tScrollBar(0).bEnabled = m_bEnabled
Case 7
 Set m_objTextBox = New clsFakeDXUITextBox
 m_objTextBox.FontZoom = m_nFontZoom
End Select
'///TODO:
End Property

Friend Sub Unload()
m_nClosing = 1
'///TODO:
End Sub

Friend Sub Destroy()
Dim t As typeFakeDXUIRect
Dim t1 As typeFakeDXUIRectEx
Dim i As Long
If m_nType < 0 Then Exit Sub
'///
m_nType = -1
m_tRect = t
m_tRectEx = t1
m_tRectEx_Backup = t1
m_tClientMargin = t
m_bSizeDirty = False
m_bEnabled = True
m_bVisible = True
m_bLocked = False
m_sName = ""
m_nStyle = 0
m_nState = 0
m_sCaption = ""
m_sText = ""
m_nValue = 0
m_nClosing = 0
m_nScrollBars = 0
m_idxFocus = 0
Set m_objTextBox = Nothing
Erase m_nAnimVal
Erase m_tScrollBar
With m_tScrollBar(0)
 .nSmallChange = 1
 .nLargeChange = 1
 .bEnabled = True
End With
With m_tScrollBar(1)
 .nSmallChange = 1
 .nLargeChange = 1
 .bEnabled = True
 .nOrientation = 1
End With
'///
If FakeDXUIActiveWindow = m_nIndex Then FakeDXUIActiveWindow = 0
If FakeDXUIFocus = m_nIndex Then FakeDXUIFocus = 0
If FakeDXUISetCapture = m_nIndex Then FakeDXUISetCapture = 0
'///
If m_idxParent > 0 And m_idxParent <= FakeDXUIControlCount Then
 FakeDXUIControls(m_idxParent).RemoveChildren m_nChildIndex
End If
'///
m_idxParent = 0
For i = 1 To m_nChildrenCount
 FakeDXUIControls(m_idxChildren(i)).ChildIndex = 0
 FakeDXUIControls(m_idxChildren(i)).Destroy
Next i
Erase m_idxChildren
m_nChildrenCount = 0
m_nChildIndex = 0
'///
'///
'TODO:etc.
End Sub

Private Sub pRenderWindowButtonHighlight(ByVal nIndex1 As Long, ByVal nIndex2 As Long, ByVal nLeft As Single, ByVal nTop As Single, Optional ByVal nOpacity As Single = 1)
Dim j As Long, k As Long
    j = m_nAnimVal(nIndex1)
    k = m_nAnimVal(nIndex2)
    If j < k Then j = j + 51 Else _
    If j > k Then j = j - 51
    m_nAnimVal(nIndex1) = j
    If j <= 0 Then
    ElseIf j <= 255 Then
     j = j * nOpacity
     j = ((j And &H7F&) * &H1000000) Or ((j > &H7F&) And &H80000000)
     FakeDXGDIStretchBltColored nLeft, nTop, nLeft + 16, nTop + 16, 232, 24, 248, 40, 512, j Or &HFFFFFF
    ElseIf j < 510 Then
     k = nOpacity * 255
     k = ((k And &H7F&) * &H1000000) Or ((k > &H7F&) And &H80000000)
     FakeDXGDIStretchBltBlended nLeft, nTop, nLeft + 16, nTop + 16, 256, 24, 272, 40, 512, 232, 24, j - 255, k Or &HFFFFFF
    Else
     k = nOpacity * 255
     k = ((k And &H7F&) * &H1000000) Or ((k > &H7F&) And &H80000000)
     FakeDXGDIStretchBltColored nLeft, nTop, nLeft + 16, nTop + 16, 256, 24, 272, 40, 512, k Or &HFFFFFF
    End If
End Sub

Private Sub pRenderScrollBars(ByVal nLeft As Single, ByVal nTop As Single, ByVal nRight As Single, ByVal nBottom As Single, Optional ByVal nOpacity As Single = 1, Optional ByVal bDrawResizeGripper As Boolean, Optional ByVal bRaiseEvent As Boolean, Optional ByVal bEnabled As Boolean = True)
Dim i As Long, b As Boolean
nLeft = nLeft + m_tClientMargin.Left
nTop = nTop + m_tClientMargin.Top
nRight = nRight - m_tClientMargin.Right
nBottom = nBottom - m_tClientMargin.Bottom
If m_nScrollBars And vbHorizontal Then
 With m_tScrollBar(0).tRect
  .Left = nLeft
  .Top = nBottom
  .Right = nRight
  .Bottom = nBottom + 16
 End With
 FakeDXUIRenderScrollBar m_tScrollBar(0), nOpacity, bEnabled
 If m_tScrollBar(0).nReserved Then
  m_tScrollBar(0).nReserved = 0
  b = True
 End If
End If
If m_nScrollBars And vbVertical Then
 With m_tScrollBar(1).tRect
  .Left = nRight
  .Top = nTop
  .Right = nRight + 16
  .Bottom = nBottom
 End With
 FakeDXUIRenderScrollBar m_tScrollBar(1), nOpacity, bEnabled
 If m_tScrollBar(1).nReserved Then
  m_tScrollBar(1).nReserved = 0
  b = True
 End If
 '///
 If b And bRaiseEvent Then FakeDXUIPostMessage FakeCtl_Msg_ScrollChange, m_nIndex
 '///
 If m_nScrollBars = vbBoth And bDrawResizeGripper Then
  i = nOpacity * 255
  i = ((i And &H7F&) * &H1000000) Or ((i > &H7F&) And &H80000000) Or &HFFFFFF
  FakeDXGDIStretchBltColored nRight, nBottom, nRight + 16, nBottom + 16, 96, 384, 112, 400, 512, i
 End If
End If
End Sub

Private Sub pRenderFocusRect(ByVal nLeft As Single, ByVal nTop As Single, ByVal nRight As Single, ByVal nBottom As Single, Optional ByVal nOpacity As Single = 1)
Dim i As Long
i = m_nAnimVal(14)
If FakeDXUIFocus = m_nIndex Then
 If i < 255 Then i = i + 51
Else
 If i > 0 Then i = i - 51
End If
m_nAnimVal(14) = i
If i > 0 Then
 i = i * nOpacity
 i = ((i And &H7F&) * &H1000000) Or ((i > &H7F&) And &H80000000) Or &HFFFFFF
 FakeDXGDIStretchBltExColored nLeft, nTop, nRight, nBottom, 8, 328, 40, 360, 4, 4, 4, 4, 512, i
End If
End Sub

'TODO:forecolor,etc.
Friend Sub Render(Optional ByVal nParentClientLeft As Single, Optional ByVal nParentClientTop As Single, Optional ByVal nOpacity As Single = 1, Optional ByVal bEnabled As Boolean = True)
Dim i As Long, j As Long, jj As Long, k As Long, kk As Long
Dim nLeft As Single, nTop As Single
Dim nRight As Single, nBottom As Single
Dim w As Single, h As Single
Dim f As Single
Dim r0 As D3DRECT, r As D3DRECT
Dim bNoChild As Boolean
'////////
bEnabled = bEnabled And m_bEnabled
'////////adjust window opacity???
If m_nType = 1 Then
 nOpacity = nOpacity * 1.2
 If nOpacity > 1 Then nOpacity = 1
End If
'////////
If m_nClosing Then
 nOpacity = nOpacity * (1 - m_nClosing * 0.2)
 m_nClosing = m_nClosing + 1
 If m_nClosing > 5 Then
  Destroy
  Exit Sub
 End If
End If
'////////
If m_nType < 0 Or Not m_bVisible Then Exit Sub
'If m_bSizeDirty Then RefreshSize
RefreshSize True
'////////
nLeft = nParentClientLeft + m_tRect.Left
nTop = nParentClientTop + m_tRect.Top
nRight = nParentClientLeft + m_tRect.Right
nBottom = nParentClientTop + m_tRect.Bottom
'TODO:caption,etc.
Select Case m_nType
Case 1 'form
 '///
 i = m_nAnimVal(0)
 If FakeDXUIActiveWindow = m_nIndex Then
  If i < 255 Then i = i + 51
 Else
  If i > 0 Then i = i - 51
 End If
 m_nAnimVal(0) = i
 'ignore nOpacity (?)
 f = 0.2 - i / 2550
 k = nOpacity * 255
 k = ((k And &H7F&) * &H1000000) Or ((k > &H7F&) And &H80000000) Or &HFFFFFF
 '///
 If m_nStyle And 32& Then 'titlebar
  If m_nState And 1& Then 'maximized
   If i <= 0 Then
    FakeDXGDIStretchBltExColored nLeft, nTop, nRight, nBottom, 144, 8, 176, 92, 0, 24, 0, 0, 512, k
   ElseIf i < 255 Then
    FakeDXGDIStretchBltExBlended nLeft, nTop, nRight, nBottom, 32, 8, 64, 92, 0, 24, 0, 0, 512, 144, 8, i, k
   Else
    FakeDXGDIStretchBltExColored nLeft, nTop, nRight, nBottom, 32, 8, 64, 92, 0, 24, 0, 0, 512, k
   End If
  ElseIf m_nState And 2& Then 'minimized
   If i <= 0 Then
    FakeDXGDIStretchBltExColored nLeft - 8, nTop - 8, nRight + 16, nBottom + 12, 112, 240, 224, 284, 16, 16, 24, 24, 512, k
   ElseIf i < 255 Then
    FakeDXGDIStretchBltExBlended nLeft - 8, nTop - 8, nRight + 16, nBottom + 12, 0, 240, 112, 284, 16, 16, 24, 24, 512, 112, 240, i, k
   Else
    FakeDXGDIStretchBltExColored nLeft - 8, nTop - 8, nRight + 16, nBottom + 12, 0, 240, 112, 284, 16, 16, 24, 24, 512, k
   End If
   bNoChild = True
  Else
   If i <= 0 Then
    FakeDXGDIStretchBltExColored nLeft - 8, nTop - 8, nRight + 16, nBottom + 16, 112, 0, 224, 112, 16, 40, 24, 24, 512, k
   ElseIf i < 255 Then
    FakeDXGDIStretchBltExBlended nLeft - 8, nTop - 8, nRight + 16, nBottom + 16, 0, 0, 112, 112, 16, 40, 24, 24, 512, 112, 0, i, k
   Else
    FakeDXGDIStretchBltExColored nLeft - 8, nTop - 8, nRight + 16, nBottom + 16, 0, 0, 112, 112, 16, 40, 24, 24, 512, k
   End If
  End If
  i = (255 - 510 * f) * nOpacity
  j = i
  j = ((j And &H7F&) * &H1000000) Or ((j > &H7F&) And &H80000000)
  FakeDXGDIDrawText FakeDXUIDefaultFont, m_sCaption, nLeft + 4, nTop, nRight - nLeft - 8, 24, m_nFontZoom, DT_VCENTER Or DT_SINGLELINE, j Or &HFFFFFF, , j, , , , , True
  '///buttons
  If m_nStyle And &H1C& Then
   '///close button
   If m_nStyle And &H10& Then
    pRenderWindowButtonHighlight 1, 4, nRight - 20, nTop + 4, nOpacity
    'TODO:etc.
   End If
   j = i
   If (m_nStyle And &H10&) = 0 Then j = j \ 2
   j = ((j And &H7F&) * &H1000000) Or ((j > &H7F&) And &H80000000)
   FakeDXGDIStretchBltColored nRight - 20, nTop + 4, nRight - 4, nTop + 20, 272, 0, 288, 16, 512, j Or &HFFFFFF
   If m_nStyle And &HC& Then
    '///maximize button
    If m_nStyle And &H8& Then
     pRenderWindowButtonHighlight 2, 5, nRight - 36, nTop + 4, nOpacity
     'TODO:etc.
    End If
    j = i
    If (m_nStyle And &H8&) = 0 Then j = j \ 2
    If m_nState And 1& Then k = 256 Else k = 240
    j = ((j And &H7F&) * &H1000000) Or ((j > &H7F&) And &H80000000)
    FakeDXGDIStretchBltColored nRight - 36, nTop + 4, nRight - 20, nTop + 20, k, 0, k + 16, 16, 512, j Or &HFFFFFF
    '///minimize button
    If m_nStyle And &H4& Then
     pRenderWindowButtonHighlight 3, 6, nRight - 52, nTop + 4, nOpacity
     'TODO:etc.
    End If
    j = i
    If (m_nStyle And &H4&) = 0 Then j = j \ 2
    If m_nState And 2& Then k = 256 Else k = 224
    j = ((j And &H7F&) * &H1000000) Or ((j > &H7F&) And &H80000000)
    FakeDXGDIStretchBltColored nRight - 52, nTop + 4, nRight - 36, nTop + 20, k, 0, k + 16, 16, 512, j Or &HFFFFFF
   End If
  End If
 Else
  If m_nStyle And 1& Then
   j = 112
  Else
   j = 176
   f = f * 2
  End If
  If i <= 0 Then
   FakeDXGDIStretchBltExColored nLeft - 8, nTop - 8, nRight + 16, nBottom + 16, 112, j, 224, j + 64, 16, 16, 24, 24, 512, k
  ElseIf i < 255 Then
   FakeDXGDIStretchBltExBlended nLeft - 8, nTop - 8, nRight + 16, nBottom + 16, 0, j, 112, j + 64, 16, 16, 24, 24, 512, 112, j, i, k
  Else
   FakeDXGDIStretchBltExColored nLeft - 8, nTop - 8, nRight + 16, nBottom + 16, 0, j, 112, j + 64, 16, 16, 24, 24, 512, k
  End If
 End If
 nOpacity = (1 - f) * nOpacity
 '///new:scrollbar
 If Not bNoChild Then
  pRenderScrollBars nLeft, nTop, nRight, nBottom, nOpacity, (m_nState And 3&) = 0 And (m_nStyle And 1&) <> 0, True, bEnabled
 End If
Case 2 'label
 i = 255 * nOpacity
 i = ((i And &H7F&) * &H1000000) Or ((i > &H7F&) And &H80000000)
 FakeDXGDIDrawText FakeDXUIDefaultFont, m_sCaption, nLeft, nTop, nRight - nLeft, nBottom - nTop, m_nFontZoom, , i, , , , , , , True
Case 3 'frame
 i = 255 * nOpacity
 i = ((i And &H7F&) * &H1000000) Or ((i > &H7F&) And &H80000000)
 FakeDXGDIStretchBltColored nLeft - 4, nTop + 4, nLeft + 8, nTop + 12, 4, 284, 16, 292, 512, i Or &HFFFFFF
 FakeDXGDIStretchBltColored nRight - 4, nTop + 4, nRight + 4, nTop + 12, 36, 284, 44, 292, 512, i Or &HFFFFFF
 '///draw text
 FakeDXGDIDrawText FakeDXUIDefaultFont, m_sCaption, nLeft + 10, nTop - 4, nRight - nLeft, 24, m_nFontZoom, DT_VCENTER Or DT_SINGLELINE Or DT_CALCRECT, _
 i Or (&H666666 And Not bEnabled), , , , , , , True, w, h
 FakeDXGDIStretchBltColored nLeft + w + 12, nTop + 4, nRight - 4, nTop + 12, 16, 284, 32, 292, 512, i Or &HFFFFFF
 '///
 FakeDXGDIStretchBltExColored nLeft - 4, nTop + 12, nRight + 4, nBottom + 4, 4, 292, 44, 324, 8, 0, 8, 8, 512, i Or &HFFFFFF
 '///new:scrollbar
 pRenderScrollBars nLeft, nTop, nRight, nBottom, nOpacity, , True, bEnabled
Case 4 'button
 i = 255 * nOpacity
 i = ((i And &H7F&) * &H1000000) Or ((i > &H7F&) And &H80000000)
 kk = m_nStyle And 15&
 Select Case kk
 Case 1, 2, 3, 4 'checkbox and optionbutton
  f = (nTop + nBottom) / 2
  If kk > 2 Then kk = 64 Else kk = 0
  If bEnabled Then
   '///base
   FakeDXGDIStretchBltColored nLeft, f - 8, nLeft + 16, f + 8, kk, 368, kk + 16, 384, 512, i Or &HFFFFFF
   '///highlight and pressed
   j = m_nAnimVal(1)
   k = m_nAnimVal(4)
   If j < k Then j = j + 51 Else _
   If j > k Then j = j - 51
   m_nAnimVal(1) = j
   jj = m_nAnimVal(2)
   k = m_nAnimVal(5)
   If jj < k Then jj = jj + 51 Else _
   If jj > k Then jj = jj - 51
   m_nAnimVal(2) = jj
   If j > 0 Then
    j = j * nOpacity
    j = ((j And &H7F&) * &H1000000) Or ((j > &H7F&) And &H80000000) Or &HFFFFFF
    FakeDXGDIStretchBltBlended nLeft, f - 8, nLeft + 16, f + 8, kk + 16, 368, kk + 32, 384, 512, kk + 32, 368, 255 - jj, j
   End If
   '///checked
   j = m_nAnimVal(3)
   k = (m_nValue = 1) And 255&
   If j < k Then j = j + 51 Else _
   If j > k Then j = j - 51
   m_nAnimVal(3) = j
   jj = m_nAnimVal(7)
   k = (m_nValue = 2) And 255&
   If jj < k Then jj = jj + 51 Else _
   If jj > k Then jj = jj - 51
   m_nAnimVal(7) = jj
   If j > 0 Then
    j = j * nOpacity
    j = ((j And &H7F&) * &H1000000) Or ((j > &H7F&) And &H80000000) Or &HFFFFFF
    FakeDXGDIStretchBltColored nLeft, f - 8, nLeft + 16, f + 8, kk, 384, kk + 16, 400, 512, j
   End If
   If jj > 0 And kk = 0 Then
    j = jj * nOpacity
    j = ((j And &H7F&) * &H1000000) Or ((j > &H7F&) And &H80000000) Or &HFFFFFF
    FakeDXGDIStretchBltColored nLeft, f - 8, nLeft + 16, f + 8, 32, 384, 48, 400, 512, j
   End If
   '///focus
   pRenderFocusRect nLeft + 16, nTop, nRight, nBottom, nOpacity
   '///caption
   FakeDXGDIDrawText FakeDXUIDefaultFont, m_sCaption, nLeft + 16, nTop, nRight - nLeft - 16, nBottom - nTop, m_nFontZoom, DT_VCENTER Or DT_SINGLELINE, _
   i, , , , , , , True
  Else
   FakeDXGDIStretchBltColored nLeft, f - 8, nLeft + 16, f + 8, kk + 48, 368, kk + 64, 384, 512, i Or &HFFFFFF
   Select Case m_nValue
   Case 1
    FakeDXGDIStretchBltColored nLeft, f - 8, nLeft + 16, f + 8, kk + 16, 384, kk + 32, 400, 512, i Or &HFFFFFF
   Case 2
    FakeDXGDIStretchBltColored nLeft, f - 8, nLeft + 16, f + 8, 48, 384, 64, 400, 512, i Or &HFFFFFF
   End Select
   '///caption
   FakeDXGDIDrawText FakeDXUIDefaultFont, m_sCaption, nLeft + 16, nTop, nRight - nLeft - 16, nBottom - nTop, m_nFontZoom, DT_VCENTER Or DT_SINGLELINE, _
   i Or &H666666, , , , , , , True
  End If
 Case Else 'button
  If bEnabled Then
   '///base
   j = m_nAnimVal(3)
   k = (m_nValue <> 0) And 255&
   If j < k Then j = j + 51 Else _
   If j > k Then j = j - 51
   m_nAnimVal(3) = j
   kk = 284 + (((m_nStyle And 16&) <> 0) And 40&)
   FakeDXGDIStretchBltExBlended nLeft - 4, nTop - 4, nRight + 4, nBottom + 4, 44, kk, 84, kk + 40, 8, 8, 8, 8, 512, 124, 284, 255 - j, i Or &HFFFFFF
   '///highlight and pressed
   j = m_nAnimVal(1)
   k = m_nAnimVal(4)
   If j < k Then j = j + 51 Else _
   If j > k Then j = j - 51
   m_nAnimVal(1) = j
   jj = m_nAnimVal(2)
   k = (k And m_nValue <> 0) Or m_nAnimVal(5)
   If jj < k Then jj = jj + 51 Else _
   If jj > k Then jj = jj - 51
   m_nAnimVal(2) = jj
   If j > 0 Then
    j = j * nOpacity
    j = ((j And &H7F&) * &H1000000) Or ((j > &H7F&) And &H80000000) Or &HFFFFFF
    FakeDXGDIStretchBltExBlended nLeft - 4, nTop - 4, nRight + 4, nBottom + 4, 84, 284, 124, 324, 8, 8, 8, 8, 512, 164, 284, 255 - jj, j
   End If
   '///focus
   pRenderFocusRect nLeft, nTop, nRight, nBottom, nOpacity
   '///caption
   FakeDXGDIDrawText FakeDXUIDefaultFont, m_sCaption, nLeft, nTop, nRight - nLeft, nBottom - nTop, m_nFontZoom, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, i, , , , , , , True
  Else
   FakeDXGDIStretchBltExColored nLeft - 4, nTop - 4, nRight + 4, nBottom + 4, 84, 324, 124, 364, 8, 8, 8, 8, 512, i Or &HFFFFFF
   FakeDXGDIDrawText FakeDXUIDefaultFont, m_sCaption, nLeft, nTop, nRight - nLeft, nBottom - nTop, m_nFontZoom, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, _
   i Or &H666666, , , , , , , True
  End If
 End Select
Case 5 'scrollbar
 With m_tScrollBar(0).tRect
  .Left = nLeft
  .Top = nTop
  .Right = nRight
  .Bottom = nBottom
 End With
 FakeDXUIRenderScrollBar m_tScrollBar(0), nOpacity, bEnabled
 If m_tScrollBar(0).nReserved Then
  m_tScrollBar(0).nReserved = 0
  FakeDXUIPostMessage FakeCtl_Msg_ScrollChange, m_nIndex
 End If
Case 6 'picturebox
 i = 255 * nOpacity
 i = ((i And &H7F&) * &H1000000) Or ((i > &H7F&) And &H80000000) Or &HFFFFFF
 kk = 164 - (bEnabled And 40&)
 FakeDXGDIStretchBltExColored nLeft - 4, nTop - 4, nRight + 4, nBottom + 4, kk, 324, kk + 40, 364, 8, 8, 8, 8, 512, i
 '///scrollbar
 pRenderScrollBars nLeft, nTop, nRight, nBottom, nOpacity, , True, bEnabled
Case 7 'textbox
 '////////border
 i = 255 * nOpacity
 i = ((i And &H7F&) * &H1000000) Or ((i > &H7F&) And &H80000000) Or &HFFFFFF
 kk = 164 - (bEnabled And 40&)
 FakeDXGDIStretchBltExColored nLeft - 4, nTop - 4, nRight + 4, nBottom + 4, kk, 324, kk + 40, 364, 8, 8, 8, 8, 512, i
 '////////scrollbar and text
 r.X1 = nLeft + m_tClientMargin.Left
 r.Y1 = nTop + m_tClientMargin.Top
 r.X2 = nRight - m_tClientMargin.Right
 r.Y2 = nBottom - m_tClientMargin.Bottom
 If m_objTextBox.MultiLine Then pRenderScrollBars nLeft, nTop, nRight, nBottom, nOpacity, , , bEnabled
 i = r.X2 - r.X1
 j = r.Y2 - r.Y1
 If i > 4 And j > 4 Then 'size limit ??? TODO:
  m_objTextBox.Width = i
  m_objTextBox.Height = j
  m_objTextBox.CalcLineDataIfSizeChanged
  '///
  With m_tScrollBar(0)
   .nSmallChange = 32
   .nLargeChange = i / m_nFontZoom
   .nMax = m_objTextBox.TextWidth - .nLargeChange
   If .nMax > 0 Then
    .bEnabled = True
   Else
    .bEnabled = False
    .nMax = 0
   End If
   If .nValue < .nMin Then .nValue = .nMin Else If .nValue > .nMax Then .nValue = .nMax
   m_objTextBox.ScrollValue(0) = .nValue
  End With
  With m_tScrollBar(1)
   .nSmallChange = 32
   .nLargeChange = j / m_nFontZoom
   .nMax = m_objTextBox.TextHeight - .nLargeChange
   If .nMax > 0 Then
    .bEnabled = True
   Else
    .bEnabled = False
    .nMax = 0
   End If
   If .nValue < .nMin Then .nValue = .nMin Else If .nValue > .nMax Then .nValue = .nMax
   m_objTextBox.ScrollValue(1) = .nValue
  End With
  '///
  d3dd9.GetScissorRect r0
  If r.X1 < r0.X1 Then r.X1 = r0.X1
  If r.Y1 < r0.Y1 Then r.Y1 = r0.Y1
  If r.X2 > r0.X2 Then r.X2 = r0.X2
  If r.Y2 > r0.Y2 Then r.Y2 = r0.Y2
  d3dd9.SetScissorRect r
  m_objTextBox.Render nLeft + m_tClientMargin.Left, nTop + m_tClientMargin.Top, nOpacity, bEnabled, FakeDXUIFocus = m_nIndex
  '///
  With m_tScrollBar(0)
   .nValue = m_objTextBox.ScrollValue(0)
   If .nValue < .nMin Then .nValue = .nMin Else If .nValue > .nMax Then .nValue = .nMax
  End With
  With m_tScrollBar(1)
   .nValue = m_objTextBox.ScrollValue(1)
   If .nValue < .nMin Then .nValue = .nMin Else If .nValue > .nMax Then .nValue = .nMax
  End With
  '///
  d3dd9.SetScissorRect r0
 End If
Case Else
 'TODO:
End Select
'////////
If m_nChildrenCount > 0 And Not bNoChild Then
 '///new:clip rect
 d3dd9.GetScissorRect r0
 r.X1 = nLeft
 r.Y1 = nTop
 r.X2 = nRight
 r.Y2 = nBottom
 If r.X1 < r0.X1 Then r.X1 = r0.X1
 If r.Y1 < r0.Y1 Then r.Y1 = r0.Y1
 If r.X2 > r0.X2 Then r.X2 = r0.X2
 If r.Y2 > r0.Y2 Then r.Y2 = r0.Y2
 d3dd9.SetScissorRect r
 '///
 nLeft = nLeft + m_tClientMargin.Left
 nTop = nTop + m_tClientMargin.Top
 '///
 For i = 1 To m_nChildrenCount
  With FakeDXUIControls(m_idxChildren(i))
   If (.Style And FCS_TopMost) = 0 Then .Render nLeft, nTop, nOpacity, bEnabled
  End With
 Next i
 For i = 1 To m_nChildrenCount
  With FakeDXUIControls(m_idxChildren(i))
   If .Style And FCS_TopMost Then .Render nLeft, nTop, nOpacity, bEnabled
  End With
 Next i
 '///
 d3dd9.SetScissorRect r0
End If
End Sub

Friend Sub RefreshSize(Optional ByVal bForce As Boolean)
Dim w As Single, h As Single
Dim p As typeFakeDXUIPoint
Dim t As typeFakeDXUIRect
Dim b As Boolean
If m_bSizeDirty Or bForce Then
 m_bSizeDirty = False
 If m_idxParent > 0 Then
  With FakeDXUIControls(m_idxParent)
   w = .ScaleWidth
   h = .ScaleHeight
   p = .ClientToScreenOffset
  End With
 End If
 FakeDXUICalcRect m_tRectEx, m_tRect, w, h
 '///non-client area size
 Select Case m_nType
 Case 1 'window
  If (m_nState And 3&) = 0 Then
   t.Left = 4
   t.Top = 4
   t.Right = 4
   t.Bottom = 4
  End If
  If m_nStyle And 32& Then t.Top = 24
  If m_nScrollBars And vbHorizontal Then t.Bottom = t.Bottom + 16
  If m_nScrollBars And vbVertical Then t.Right = t.Right + 16
 Case 3 'frame
  t.Left = 4
  t.Top = 16
  t.Right = 4
  t.Bottom = 4
  If m_nScrollBars And vbHorizontal Then t.Bottom = t.Bottom + 16
  If m_nScrollBars And vbVertical Then t.Right = t.Right + 16
 Case 6, 7 'picturebox,textbox
  t.Left = 4
  t.Top = 4
  t.Right = 4
  t.Bottom = 4
  If m_objTextBox Is Nothing Then b = True Else b = m_objTextBox.MultiLine
  If b Then
   If m_nScrollBars And vbHorizontal Then t.Bottom = t.Bottom + 16
   If m_nScrollBars And vbVertical Then t.Right = t.Right + 16
  End If
 End Select
 '///
 m_tClientMargin = t
 With m_tClientToScreenOffset
  .x = p.x + m_tRect.Left + t.Left
  .y = p.y + m_tRect.Top + t.Top
 End With
 With m_tRectScreen
  .Left = p.x + m_tRect.Left
  .Top = p.y + m_tRect.Top
  .Right = p.x + m_tRect.Right
  .Bottom = p.y + m_tRect.Bottom
 End With
End If
End Sub

Friend Property Get ClientToScreenOffset() As typeFakeDXUIPoint
If m_bSizeDirty Then RefreshSize
ClientToScreenOffset = m_tClientToScreenOffset
End Property

Friend Property Get Left() As Single
If m_bSizeDirty Then RefreshSize
Left = m_tRect.Left
End Property

Friend Property Get Top() As Single
If m_bSizeDirty Then RefreshSize
Top = m_tRect.Top
End Property

Friend Property Get Right() As Single
If m_bSizeDirty Then RefreshSize
Right = m_tRect.Right
End Property

Friend Property Get Bottom() As Single
If m_bSizeDirty Then RefreshSize
Bottom = m_tRect.Bottom
End Property

Friend Property Get Width() As Single
If m_bSizeDirty Then RefreshSize
Width = m_tRect.Right - m_tRect.Left
End Property

Friend Property Get Height() As Single
If m_bSizeDirty Then RefreshSize
Height = m_tRect.Bottom - m_tRect.Top
End Property

Friend Property Get ScaleLeft() As Single
If m_bSizeDirty Then RefreshSize
ScaleLeft = m_tRect.Left + m_tClientMargin.Left
End Property

Friend Property Get ScaleTop() As Single
If m_bSizeDirty Then RefreshSize
ScaleTop = m_tRect.Top + m_tClientMargin.Top
End Property

Friend Property Get ScaleRight() As Single
If m_bSizeDirty Then RefreshSize
ScaleRight = m_tRect.Right - m_tClientMargin.Right
End Property

Friend Property Get ScaleBottom() As Single
If m_bSizeDirty Then RefreshSize
ScaleBottom = m_tRect.Bottom - m_tClientMargin.Bottom
End Property

Friend Property Get ScaleWidth() As Single
If m_bSizeDirty Then RefreshSize
ScaleWidth = m_tRect.Right - m_tRect.Left - m_tClientMargin.Left - m_tClientMargin.Right
End Property

Friend Property Get ScaleHeight() As Single
If m_bSizeDirty Then RefreshSize
ScaleHeight = m_tRect.Bottom - m_tRect.Top - m_tClientMargin.Top - m_tClientMargin.Bottom
End Property

Friend Property Get LeftEx() As typeFakeDXUIPosition
LeftEx = m_tRectEx.Left
End Property

Friend Property Let LeftEx(p As typeFakeDXUIPosition)
m_tRectEx.Left = p
m_bSizeDirty = True
End Property

Friend Sub GetLeftEx(ByRef a As Single, ByRef b As Single)
a = m_tRectEx.Left.a
b = m_tRectEx.Left.b
End Sub

Friend Sub SetLeftEx(ByVal a As Single, ByVal b As Single)
m_tRectEx.Left.a = a
m_tRectEx.Left.b = b
m_bSizeDirty = True
End Sub

Friend Property Get TopEx() As typeFakeDXUIPosition
TopEx = m_tRectEx.Top
End Property

Friend Property Let TopEx(p As typeFakeDXUIPosition)
m_tRectEx.Top = p
m_bSizeDirty = True
End Property

Friend Sub GetTopEx(ByRef a As Single, ByRef b As Single)
a = m_tRectEx.Top.a
b = m_tRectEx.Top.b
End Sub

Friend Sub SetTopEx(ByVal a As Single, ByVal b As Single)
m_tRectEx.Top.a = a
m_tRectEx.Top.b = b
m_bSizeDirty = True
End Sub

Friend Property Get RightEx() As typeFakeDXUIPosition
RightEx = m_tRectEx.Right
End Property

Friend Property Let RightEx(p As typeFakeDXUIPosition)
m_tRectEx.Right = p
m_bSizeDirty = True
End Property

Friend Sub GetRightEx(ByRef a As Single, ByRef b As Single)
a = m_tRectEx.Right.a
b = m_tRectEx.Right.b
End Sub

Friend Sub SetRightEx(ByVal a As Single, ByVal b As Single)
m_tRectEx.Right.a = a
m_tRectEx.Right.b = b
m_bSizeDirty = True
End Sub

Friend Property Get BottomEx() As typeFakeDXUIPosition
BottomEx = m_tRectEx.Bottom
End Property

Friend Property Let BottomEx(p As typeFakeDXUIPosition)
m_tRectEx.Bottom = p
m_bSizeDirty = True
End Property

Friend Sub GetBottomEx(ByRef a As Single, ByRef b As Single)
a = m_tRectEx.Bottom.a
b = m_tRectEx.Bottom.b
End Sub

Friend Sub SetBottomEx(ByVal a As Single, ByVal b As Single)
m_tRectEx.Bottom.a = a
m_tRectEx.Bottom.b = b
m_bSizeDirty = True
End Sub

Friend Property Get Rectangle() As typeFakeDXUIRect
If m_bSizeDirty Then RefreshSize
Rectangle = m_tRect
End Property

Friend Property Get RectangleEx() As typeFakeDXUIRectEx
RectangleEx = m_tRectEx
End Property

Friend Property Let RectangleEx(p As typeFakeDXUIRectEx)
m_tRectEx = p
m_bSizeDirty = True
End Property

Private Sub Class_Initialize()
m_nType = -1
m_bEnabled = True
m_bVisible = True
With m_tScrollBar(0)
 .nSmallChange = 1
 .nLargeChange = 1
 .bEnabled = True
End With
With m_tScrollBar(1)
 .nSmallChange = 1
 .nLargeChange = 1
 .bEnabled = True
 .nOrientation = 1
End With
End Sub

Private Sub Class_Terminate()
Destroy
End Sub

Friend Sub BeforeMouseEvent()
'm_bMouseIn = False
'///
'Select Case m_nType
'Case 1, 4
 m_nAnimVal(4) = 0
 m_nAnimVal(5) = 0
 m_nAnimVal(6) = 0
 With m_tScrollBar(0)
  .nAnimVal(11) = 0
  .nAnimVal(12) = 0
  .nAnimVal(13) = 0
  .nAnimVal(14) = 0
  .nAnimVal(15) = 0
 End With
 With m_tScrollBar(1)
  .nAnimVal(11) = 0
  .nAnimVal(12) = 0
  .nAnimVal(13) = 0
  .nAnimVal(14) = 0
  .nAnimVal(15) = 0
 End With
'End Select
'///
'TODO:
End Sub

Friend Sub AfterMouseEvent()
'TODO:
End Sub

Private Function pButtonHighlight_1(ByVal nIndex As Long, ByVal Button As Long, ByVal nEventType As Long, Optional ByRef bPressed As Boolean) As Long
Dim i As Long
i = 255
bPressed = False
If Button And 1& Then
 If nEventType = 1 Then
  m_nAnimVal(15) = nIndex
  i = 510
 ElseIf nEventType = 2 Then
  bPressed = m_nAnimVal(15) = nIndex
 ElseIf nEventType = 0 Then
  If m_nAnimVal(15) = nIndex Then i = 510 Else i = 0
 End If
End If
pButtonHighlight_1 = i
End Function

Private Sub pSetFocus()
If m_nStyle And &H1000000 Then FakeDXUIFocus = m_nIndex
End Sub

Private Sub pButtonClick()
Dim i As Long
i = m_nStyle And 7&
Select Case i
Case 1 'checkbox
 m_nValue = (m_nValue = 0) And 1&
Case 2 '3state
 m_nValue = m_nValue + 1
 If m_nValue > 2 Then m_nValue = 0
Case 3, 4 'option and optionnullable
 If m_nValue = 0 Then
  Value = 1
 ElseIf i = 4 Then
  m_nValue = 0
 End If
Case Else
 m_nValue = 0
End Select
FakeDXUIPostMessage FakeCtl_Msg_Click, m_nIndex
End Sub

Friend Function OnMouseEvent(ByVal Button As Long, ByVal Shift As Long, ByVal x As Single, ByVal y As Single, ByVal nEventType As Long, Optional ByVal bChildrenProcessed As Boolean) As Boolean
Dim i As Long
Dim b As Boolean, b1 As Boolean
Dim w As Single, h As Single, f As Single
Dim bInControl As Boolean
'///
Dim bNoChild As Boolean
'///
If m_nType < 0 Or Not m_bVisible Or Not m_bEnabled Or m_nClosing > 0 Then Exit Function
If m_bSizeDirty Then RefreshSize
'////////
bInControl = x >= m_tRectScreen.Left And x < m_tRectScreen.Right And y >= m_tRectScreen.Top And y < m_tRectScreen.Bottom And Not bChildrenProcessed
'////////before
Select Case m_nType
Case 1 'form
 '///new:scrollbar
 If m_nAnimVal(15) = 0 Or FakeDXUISetCapture <> m_nIndex Then
  If m_nScrollBars And vbHorizontal Then
   b = b Or FakeDXUIOnScrollBarMouseEvent(Button, Shift, x, y, nEventType, m_tScrollBar(0))
  End If
  If m_nScrollBars And vbVertical Then
   b = b Or FakeDXUIOnScrollBarMouseEvent(Button, Shift, x, y, nEventType, m_tScrollBar(1))
  End If
  b1 = b '???
 End If
 '///
 If bInControl Then
  If nEventType = 1 Then
   m_nAnimVal(15) = 0 '???
   '///change active window and focus
   If FakeDXUIActiveWindow <> m_nIndex Then
    If FakeDXUIActiveWindow > 0 And FakeDXUIActiveWindow <= FakeDXUIControlCount Then
     FakeDXUIControls(FakeDXUIActiveWindow).Focus = FakeDXUIFocus
    End If
    FakeDXUIActiveWindow = m_nIndex
    FakeDXUIFocus = m_idxFocus
   End If
   '///
   FakeDXUIPostMessage FakeCtl_Msg_ZOrder, m_nIndex, 0
  End If
  '///window button
  If m_nStyle And 32& Then
   If y >= m_tRectScreen.Top + 4 And y < m_tRectScreen.Top + 20 Then
    If m_nStyle And 16& Then
     If x >= m_tRectScreen.Right - 20 And x < m_tRectScreen.Right - 4 Then
      m_nAnimVal(4) = pButtonHighlight_1(1, Button, nEventType, b)
      If b Then FakeDXUIPostMessage FakeCtl_Msg_Close, m_nIndex
      If m_nAnimVal(4) Then b1 = True '???
     End If
    End If
    If m_nStyle And 8& Then
     If x >= m_tRectScreen.Right - 36 And x < m_tRectScreen.Right - 20 Then
      m_nAnimVal(5) = pButtonHighlight_1(2, Button, nEventType, b)
      If b Then FakeDXUIPostMessage FakeCtl_Msg_Size, m_nIndex, 1
      If m_nAnimVal(5) Then b1 = True '???
     End If
    End If
    If m_nStyle And 4& Then
     If x >= m_tRectScreen.Right - 52 And x < m_tRectScreen.Right - 36 Then
      m_nAnimVal(6) = pButtonHighlight_1(3, Button, nEventType, b)
      If b Then FakeDXUIPostMessage FakeCtl_Msg_Size, m_nIndex, 2
      If m_nAnimVal(6) Then b1 = True '???
     End If
    End If
   End If
  End If
  '///
  'TODO:
  '///
  If nEventType = 2 And (Button And 1&) <> 0 Then m_nAnimVal(15) = 0
  '///
  b = True
 End If
 If m_nState And 2& Then bNoChild = True
Case 3 'frame
 '///focus(?)
 If bInControl And nEventType = 1 Then pSetFocus
 '///scrollbar
 If m_nScrollBars And vbHorizontal Then
  b = b Or FakeDXUIOnScrollBarMouseEvent(Button, Shift, x, y, nEventType, m_tScrollBar(0))
 End If
 If m_nScrollBars And vbVertical Then
  b = b Or FakeDXUIOnScrollBarMouseEvent(Button, Shift, x, y, nEventType, m_tScrollBar(1))
 End If
Case 4 'button
 If bInControl Then
  If nEventType = 1 Then pSetFocus
  i = pButtonHighlight_1(1, Button, nEventType, b)
  If i > 255 Then
   m_nAnimVal(4) = 255
   m_nAnimVal(5) = 255
  Else
   m_nAnimVal(4) = i
   m_nAnimVal(5) = 0
  End If
  If b Then pButtonClick
  b = True
 End If
Case 5 'scrollbar
 If bInControl And nEventType = 1 Then pSetFocus
 b = FakeDXUIOnScrollBarMouseEvent(Button, Shift, x, y, nEventType, m_tScrollBar(0))
Case 6 'picturebox
 If bInControl Then
  If nEventType = 1 Then pSetFocus
  b = True
 End If
 '///scrollbar
 If m_nScrollBars And vbHorizontal Then
  b = b Or FakeDXUIOnScrollBarMouseEvent(Button, Shift, x, y, nEventType, m_tScrollBar(0))
 End If
 If m_nScrollBars And vbVertical Then
  b = b Or FakeDXUIOnScrollBarMouseEvent(Button, Shift, x, y, nEventType, m_tScrollBar(1))
 End If
Case 7 'textbox
 If bInControl And nEventType = 1 Then pSetFocus
 '///scrollbar
 If m_objTextBox.MultiLine Then
  If m_nScrollBars And vbHorizontal Then
   b = b Or FakeDXUIOnScrollBarMouseEvent(Button, Shift, x, y, nEventType, m_tScrollBar(0))
  End If
  If m_nScrollBars And vbVertical Then
   b = b Or FakeDXUIOnScrollBarMouseEvent(Button, Shift, x, y, nEventType, m_tScrollBar(1))
  End If
 End If
 '///
 'TODO:
 '///
Case Else
 'TODO:
End Select
'////////
If bInControl And Not bNoChild And FakeDXUISetCapture <> m_nIndex Then '?
 For i = m_nChildrenCount To 1 Step -1
  If bChildrenProcessed Then Exit For '???
  With FakeDXUIControls(m_idxChildren(i))
   If .Style And FCS_TopMost Then
    If .OnMouseEvent(Button, Shift, x, y, nEventType, bChildrenProcessed) Then
     bChildrenProcessed = True
    End If
   End If
  End With
 Next i
 For i = m_nChildrenCount To 1 Step -1
  If bChildrenProcessed Then Exit For '???
  With FakeDXUIControls(m_idxChildren(i))
   If (.Style And FCS_TopMost) = 0 Then
    If .OnMouseEvent(Button, Shift, x, y, nEventType, bChildrenProcessed) Then
     bChildrenProcessed = True
    End If
   End If
  End With
 Next i
End If
'////////after
'///
If Not bChildrenProcessed And Not b1 Then
 Select Case m_nType
 Case 1 'form
  If bInControl Then
   '///resize window
   If (m_nState And 3&) = 0 Then
    If m_nStyle And 1& Then
     If (Button And 1&) = 0 Or nEventType = 1 Then
      If m_nAnimVal(15) < 0 Then m_nAnimVal(15) = 0
      If x >= m_tRectScreen.Left And x < m_tRectScreen.Left + 8 Then
       If y >= m_tRectScreen.Top And y < m_tRectScreen.Top + 8 Then
        m_nAnimVal(15) = -1
        FakeDXUIMousePointer = vbSizeNWSE
       ElseIf y >= m_tRectScreen.Top + 8 And y < m_tRectScreen.Bottom - 8 Then
        m_nAnimVal(15) = -2
        FakeDXUIMousePointer = vbSizeWE
       ElseIf y >= m_tRectScreen.Bottom - 8 And y < m_tRectScreen.Bottom Then
        m_nAnimVal(15) = -3
        FakeDXUIMousePointer = vbSizeNESW
       End If
      ElseIf x >= m_tRectScreen.Left + 8 And x < m_tRectScreen.Right - 8 Then
       If y >= m_tRectScreen.Top And y < m_tRectScreen.Top + 8 Then
        m_nAnimVal(15) = -4
        FakeDXUIMousePointer = vbSizeNS
       ElseIf y >= m_tRectScreen.Bottom - 8 And y < m_tRectScreen.Bottom Then
        m_nAnimVal(15) = -6
        FakeDXUIMousePointer = vbSizeNS
       End If
      ElseIf x >= m_tRectScreen.Right - 8 And x < m_tRectScreen.Right Then
       If y >= m_tRectScreen.Top And y < m_tRectScreen.Top + 8 Then
        m_nAnimVal(15) = -7
        FakeDXUIMousePointer = vbSizeNESW
       ElseIf y >= m_tRectScreen.Top + 8 And y < m_tRectScreen.Bottom - 8 Then
        m_nAnimVal(15) = -8
        FakeDXUIMousePointer = vbSizeWE
       ElseIf y >= m_tRectScreen.Bottom - 8 And y < m_tRectScreen.Bottom Then
        m_nAnimVal(15) = -9
        FakeDXUIMousePointer = vbSizeNWSE
       End If
      End If
      '///new:resize gripper
      If m_nScrollBars = vbBoth Then
       If x >= m_tRectScreen.Right - m_tClientMargin.Right And y >= m_tRectScreen.Bottom - m_tClientMargin.Bottom And _
       x < m_tRectScreen.Right And y < m_tRectScreen.Bottom Then
        m_nAnimVal(15) = -9
        FakeDXUIMousePointer = vbSizeNWSE
       End If
      End If
      '///
     End If
    End If
   End If
   '///move window
   If m_nStyle And 3& Then
    If (Button And 1&) = 0 Or nEventType = 1 Then
     If m_nAnimVal(15) = 0 Then
      If x >= m_tRectScreen.Left And x < m_tRectScreen.Right Then
       If m_nStyle And 32& Then
        If y >= m_tRectScreen.Top And y < m_tRectScreen.Top + 24 Then
         If m_nState And 1& Then m_nAnimVal(15) = -105 Else m_nAnimVal(15) = -5
        End If
       Else
        If y >= m_tRectScreen.Top And y < m_tRectScreen.Bottom Then
         m_nAnimVal(15) = -5
        End If
       End If
      End If
     End If
    End If
   End If
   '///
  End If
 Case Else
  'TODO:
 End Select
End If
'////////standard drag
b1 = False
If Button = 1 And Not bChildrenProcessed Then
 Select Case m_nType
 Case -1, 0, 2, 3
 Case Else
  If nEventType = 1 And bInControl Then
   FakeDXUISetCapture = m_nIndex
   With m_tDragLast
    .x = x
    .y = y
   End With
   m_tDragFirst = m_tDragLast
   b1 = True
  ElseIf nEventType = 2 Then
   FakeDXUISetCapture = 0
  ElseIf nEventType = 4 And bInControl Then
   '///double click event
   i = m_nAnimVal(15)
   Select Case i
   Case -5, -105
    If m_nStyle And 32& Then
     If m_nState And 2& Then
      If m_nStyle And 4& Then FakeDXUIPostMessage FakeCtl_Msg_Size, m_nIndex, 2
     Else
      If m_nStyle And 8& Then FakeDXUIPostMessage FakeCtl_Msg_Size, m_nIndex, 1
     End If
    End If
   End Select
   '///
  ElseIf nEventType = 0 And (bInControl Or FakeDXUISetCapture = m_nIndex) Then
   b1 = True
   '///
   If m_nAnimVal(15) < 0 Then
    m_bSizeDirty = True
    '///new:check moved control is in parent's client area ( ??? TODO:flags )
    If m_idxParent > 0 Then
     With FakeDXUIControls(m_idxParent)
      w = .ScaleWidth
      h = .ScaleHeight
     End With
    End If
    '///
    i = m_nAnimVal(15)
    Select Case i
    Case -1, -2, -3, -5
     m_tRectEx.Left.a = m_tRectEx.Left.a + x - m_tDragLast.x
     If i <> -5 Then
      RefreshSize True
      If m_tRect.Left < 0 Then f = -m_tRect.Left _
      Else If m_tRect.Left > m_tRect.Right - 8 Then f = m_tRect.Right - 8 - m_tRect.Left Else f = 0
      m_tRectEx.Left.a = m_tRectEx.Left.a + f
      m_tRect.Left = m_tRect.Left + f
      x = x + f
     End If
    End Select
    Select Case i
    Case -1, -4, -5, -7
     m_tRectEx.Top.a = m_tRectEx.Top.a + y - m_tDragLast.y
     If i <> -5 Then
      RefreshSize True
      If m_tRect.Top < 0 Then f = -m_tRect.Top _
      Else If m_tRect.Top > m_tRect.Bottom - 8 Then f = m_tRect.Bottom - 8 - m_tRect.Top Else f = 0
      m_tRectEx.Top.a = m_tRectEx.Top.a + f
      m_tRect.Top = m_tRect.Top + f
      y = y + f
     End If
    End Select
    Select Case i
    Case -5, -7, -8, -9
     m_tRectEx.Right.a = m_tRectEx.Right.a + x - m_tDragLast.x
     If i <> -5 Then
      RefreshSize True
      If m_tRect.Right > w Then f = w - m_tRect.Right _
      Else If m_tRect.Right < m_tRect.Left + 8 Then f = m_tRect.Left + 8 - m_tRect.Right Else f = 0
      m_tRectEx.Right.a = m_tRectEx.Right.a + f
      m_tRect.Right = m_tRect.Right + f
      x = x + f
     End If
    End Select
    Select Case i
    Case -3, -5, -6, -9
     m_tRectEx.Bottom.a = m_tRectEx.Bottom.a + y - m_tDragLast.y
     If i <> -5 Then
      RefreshSize True
      If m_tRect.Bottom > h Then f = h - m_tRect.Bottom _
      Else If m_tRect.Bottom < m_tRect.Top + 8 Then f = m_tRect.Top + 8 - m_tRect.Bottom Else f = 0
      m_tRectEx.Bottom.a = m_tRectEx.Bottom.a + f
      m_tRect.Bottom = m_tRect.Bottom + f
      y = y + f
     End If
    End Select
    If i = -5 Then
     RefreshSize True
     If m_tRect.Left < 0 Then f = -m_tRect.Left _
     Else If m_tRect.Right > w Then f = w - m_tRect.Right Else f = 0
     m_tRectEx.Left.a = m_tRectEx.Left.a + f
     m_tRectEx.Right.a = m_tRectEx.Right.a + f
     m_tRect.Left = m_tRect.Left + f
     m_tRect.Right = m_tRect.Right + f
     x = x + f
     If m_tRect.Top < 0 Then f = -m_tRect.Top _
     Else If m_tRect.Bottom > h Then f = h - m_tRect.Bottom Else f = 0
     m_tRectEx.Top.a = m_tRectEx.Top.a + f
     m_tRectEx.Bottom.a = m_tRectEx.Bottom.a + f
     m_tRect.Top = m_tRect.Top + f
     m_tRect.Bottom = m_tRect.Bottom + f
     y = y + f
    End If
   End If
   '///
   With m_tDragLast
    .x = x
    .y = y
   End With
  End If
  '///
  If b1 Then
   Select Case m_nAnimVal(15)
   Case -1, -9
    FakeDXUIMousePointer = vbSizeNWSE
   Case -2, -8
    FakeDXUIMousePointer = vbSizeWE
   Case -3, -7
    FakeDXUIMousePointer = vbSizeNESW
   Case -4, -6
    FakeDXUIMousePointer = vbSizeNS
   Case -5
    FakeDXUIMousePointer = vbSizeAll
   End Select
  End If
 End Select
End If
'TODO:
'////////
OnMouseEvent = b Or b1 Or bChildrenProcessed
End Function

Friend Function OnKeyEvent(ByVal KeyCode As Long, ByVal Shift As Long, ByVal nEventType As Long) As Boolean
Dim i As Long
Dim b As Boolean
'///
If m_nType < 0 Or Not m_bVisible Or Not m_bEnabled Or m_nClosing > 0 Then Exit Function
'///
'TODO:
'///
Select Case nEventType
Case 1 'down
 Select Case m_nType
 Case 4 'button
  If KeyCode = vbKeyReturn Or KeyCode = vbKeySpace Then pButtonClick
 End Select
Case 101, 102 'default,cancel
 If m_nType = 4 Then
  b = (nEventType = 101 And (m_nStyle And 16&) <> 0) Or (nEventType = 102 And (m_nStyle And 32&) <> 0)
 End If
 '///
 If b Then
  FakeDXUIPostMessage FakeCtl_Msg_Click, m_nIndex
 Else
  For i = m_nChildrenCount To 1 Step -1
   If FakeDXUIControls(m_idxChildren(i)).OnKeyEvent(KeyCode, Shift, nEventType) Then
    b = True
    Exit For
   End If
  Next i
 End If
Case Else
End Select
'///
OnKeyEvent = b
End Function

Friend Function OnMouseWheel(ByVal nDelta As Long, ByVal Shift As Long) As Boolean
Dim idx As Long
Dim i As Long
Dim b As Boolean
'///
If m_nType < 0 Or Not m_bVisible Or Not m_bEnabled Or m_nClosing > 0 Then Exit Function
'///
'TODO:
'///
idx = -1
Select Case m_nType
Case 1, 3, 6, 7, 8, 10
 If (m_nScrollBars And vbVertical) <> 0 And (Shift And vbShiftMask) = 0 Then
  idx = 1
 ElseIf m_nScrollBars And vbHorizontal Then
  idx = 0
 End If
Case 5
 idx = 0
End Select
'///
If idx >= 0 Then
 With m_tScrollBar(idx)
  If .bEnabled Then
   i = .nValue - nDelta * .nSmallChange * 4&
   If i < .nMin Then i = .nMin Else If i > .nMax Then i = .nMax
   If .nValue <> i Then
    .nValue = i
    .nReserved = 1
   End If
  End If
 End With
 b = True
End If
'///
OnMouseWheel = b
End Function
