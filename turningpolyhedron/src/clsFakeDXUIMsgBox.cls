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

Friend Sub AddButton(ByVal s As String, ByVal nValue As VbMsgBoxResult)
m_nButtonCount = m_nButtonCount + 1
ReDim Preserve m_sButtonCaption(1 To m_nButtonCount)
ReDim Preserve m_nButtonValue(1 To m_nButtonCount)
m_sButtonCaption(m_nButtonCount) = s
m_nButtonValue(m_nButtonCount) = nValue
End Sub

Friend Sub AddDefaultButtons(ByVal Buttons As VbMsgBoxStyle)
Select Case Buttons And 15&
Case 0 'vbOKOnly
 AddButton objText.GetText("OK"), vbOK
Case 1 'vbOKCancel
 AddButton objText.GetText("OK"), vbOK
 AddButton objText.GetText("Cancel"), vbCancel
Case 2 'vbAbortRetryIgnore
 AddButton objText.GetText("Abort"), vbAbort
 AddButton objText.GetText("Retry"), vbRetry
 AddButton objText.GetText("Ignore"), vbIgnore
Case 3 'vbYesNoCancel
 AddButton objText.GetText("Yes"), vbYes
 AddButton objText.GetText("No"), vbNo
 AddButton objText.GetText("Cancel"), vbCancel
Case 4 'vbYesNo
 AddButton objText.GetText("Yes"), vbYes
 AddButton objText.GetText("No"), vbNo
Case 5 'vbRetryCancel
 AddButton objText.GetText("Retry"), vbRetry
 AddButton objText.GetText("Cancel"), vbCancel
End Select
End Sub

'TODO:autosize,custom buttons,default button,icon,etc.
Friend Function MsgBox(Optional ByVal Prompt As String, Optional ByVal Buttons As VbMsgBoxStyle, Optional ByVal Title As String, Optional ByVal Default As VbMsgBoxResult) As VbMsgBoxResult
Dim i As Long, x As Long
'///
If m_idx Then Exit Function
m_bUnload = False
m_nReturnValue = Default
'///
With FakeDXUIControls(1).AddNewChildren(FakeCtl_Form, -200, -100, _
200, 100, FFS_CloseButton Or FFS_Moveable Or FFS_TitleBar, , False, , Title, , , 0.5, 0.5, 0.5, 0.5)
 m_idx = .Index
 Set .EventObject = Me
 '///
 .AddNewChildren FakeCtl_Label, 8, 8, -8, -8, , , , , Prompt, , , , , 1, 1
 '///
 Select Case Buttons And 15&
 Case 0 To 5
  ClearButtons
  AddDefaultButtons Buttons
 End Select
 '///
 x = 4& - m_nButtonCount * 32&
 For i = 1 To m_nButtonCount
  .AddNewChildren FakeCtl_Button, x, -32, x + 56, -8, FCS_TabStop Or FCS_CanGetFocus, , , , m_sButtonCaption(i), , "MsgBox", _
  0.5, 1, 0.5, 1, , CStr(m_nButtonValue(i))
  x = x + 64
 Next i
 '///
 .Show 1
End With
'///wait for single object
FakeDXAppMainLoop Me
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
