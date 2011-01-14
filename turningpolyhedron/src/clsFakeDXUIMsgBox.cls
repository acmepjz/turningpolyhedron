VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsFakeDXUIMsgBox"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private m_idx As Long

Private m_nReturnValue As Long
Private m_bUnload As Boolean

Private m_nButtonCount As Long
Private m_sButtonCaption() As String
Private m_nButtonValue() As Long

Implements IFakeDXUIEvent
Implements IMainLoopCallback

Friend Property Get ReturnValue() As VbMsgBoxResult
ReturnValue = m_nReturnValue
End Property

Friend Sub ClearButtons()
m_nButtonCount = 0
Erase m_sButtonCaption
Erase m_nButtonValue
End Sub

Friend Sub AddButton(Optional ByVal s As String, Optional ByVal nValue As VbMsgBoxResult)
'///get default name
If s = "" Then
 Select Case nValue
 Case 1 'vbOK
  s = objText.GetText("OK")
 Case 2 'vbCancel
  s = objText.GetText("Cancel")
 Case 3 'vbAbort
  s = objText.GetText("Abort")
 Case 4 'vbRetry
  s = objText.GetText("Retry")
 Case 5 'vbIgnore
  s = objText.GetText("Ignore")
 Case 6 'vbYes
  s = objText.GetText("Yes")
 Case 7 'vbNo
  s = objText.GetText("No")
 End Select
End If
'///
m_nButtonCount = m_nButtonCount + 1
ReDim Preserve m_sButtonCaption(1 To m_nButtonCount)
ReDim Preserve m_nButtonValue(1 To m_nButtonCount)
m_sButtonCaption(m_nButtonCount) = s
m_nButtonValue(m_nButtonCount) = nValue
End Sub

Friend Sub AddDefaultButtons(ByVal Buttons As VbMsgBoxStyle)
Select Case Buttons And 15&
Case 0 'vbOKOnly
 AddButton , vbOK
Case 1 'vbOKCancel
 AddButton , vbOK
 AddButton , vbCancel
Case 2 'vbAbortRetryIgnore
 AddButton , vbAbort
 AddButton , vbRetry
 AddButton , vbIgnore
Case 3 'vbYesNoCancel
 AddButton , vbYes
 AddButton , vbNo
 AddButton , vbCancel
Case 4 'vbYesNo
 AddButton , vbYes
 AddButton , vbNo
Case 5 'vbRetryCancel
 AddButton , vbRetry
 AddButton , vbCancel
End Select
End Sub

'TODO:autosize,custom buttons,default button,icon,etc.
Friend Function MsgBox(Optional ByVal Prompt As String, Optional ByVal Buttons As VbMsgBoxStyle, Optional ByVal Title As String, Optional ByVal Default As VbMsgBoxResult) As VbMsgBoxResult
Dim w As Long, h As Long
Dim ww As Single, hh As Single
Dim i As Long, x As Long
Dim idx As Long
'///
If m_idx Then Exit Function
m_bUnload = False
m_nReturnValue = Default
'///
Select Case Buttons And 15&
Case 0 To 5
 ClearButtons
 AddDefaultButtons Buttons
End Select
'///calc size
w = m_nButtonCount * 64& - 8&
If w < 32& Then w = 32&
FakeDXGDIDrawText FakeDXUIDefaultFont, Prompt, 0, 0, w, , 0.5, DT_CALCRECT, 0, , , , , , , , ww, hh
If ww < w Then ww = w
'If ww > d3dpp.BackBufferWidth - 32 Then 'does not work
' FakeDXGDIDrawText FakeDXUIDefaultFont, Prompt, 0, 0, ww, hh, 0.5, DT_WORDBREAK Or DT_CALCRECT, 0, , , , , , , , ww, hh
' If ww < w Then ww = w
 If ww > d3dpp.BackBufferWidth - 32 Then ww = d3dpp.BackBufferWidth - 32
'End If
If hh > d3dpp.BackBufferHeight - 80 Then hh = d3dpp.BackBufferHeight - 80
w = CLng(ww) \ 2& + 12
h = CLng(hh) \ 2& + 38
'///
With FakeDXUIControls(1).AddNewChildren(FakeCtl_Form, -w, -h, _
w, h, FFS_CloseButton Or FFS_Moveable Or FFS_TitleBar, , False, , Title, , , 0.5, 0.5, 0.5, 0.5)
 m_idx = .Index
 Set .EventObject = Me
 '///
 .AddNewChildren FakeCtl_Label, 8, 8, -8, -8, FLS_WordWrap, , , , Prompt, , , , , 1, 1
 '///
 idx = (Buttons And &HFF00&) \ &H100& + 1
 x = 4& - m_nButtonCount * 32&
 For i = 1 To m_nButtonCount
  With .AddNewChildren(FakeCtl_Button, x, -32, x + 56, -8, FCS_TabStop Or FCS_CanGetFocus, , , , m_sButtonCaption(i), , "MsgBox", _
  0.5, 1, 0.5, 1, , CStr(m_nButtonValue(i)))
   If i = idx Then FakeDXUIPostMessage FakeCtl_Msg_SetFocus, .Index
  End With
  x = x + 64
 Next i
 '///
 .Show 1
End With
'///wait for single object
FakeDXAppMainLoop Me
''///fix a bug (?)
'FakeDXUIRemoveModalWindow m_idx
'///
MsgBox = m_nReturnValue
m_idx = 0
End Function

''should never run because there is a reference in FakeDXUIControls(m_idx).EventObject
'Private Sub Class_Terminate()
'If m_idx > 0 And m_idx <= FakeDXUIControlCount Then
' FakeDXUIControls(m_idx).Unload
' m_idx = 0
'End If
'End Sub

Private Sub IFakeDXUIEvent_Change(ByVal obj As clsFakeDXUI)
'
End Sub

Private Sub IFakeDXUIEvent_Click(ByVal obj As clsFakeDXUI)
Select Case obj.Name
Case "MsgBox"
 m_nReturnValue = Val(obj.GroupName)
 If m_idx > 0 And m_idx <= FakeDXUIControlCount Then
  FakeDXUIControls(m_idx).Unload
  m_bUnload = True
  m_idx = 0
 End If
End Select
End Sub

Private Sub IFakeDXUIEvent_Unload(ByVal obj As clsFakeDXUI, Cancel As Boolean)
m_bUnload = True
End Sub

Private Sub IMainLoopCallback_Callback(Cancel As Boolean)
Cancel = m_bUnload
End Sub
