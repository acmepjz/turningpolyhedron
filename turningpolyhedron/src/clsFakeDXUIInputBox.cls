VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsFakeDXUIInputBox"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private m_idx As Long
Private m_idxTextBox As Long

Private m_bCancel As Boolean, m_sValue As String
Private m_bUnload As Boolean

Implements IFakeDXUIEvent

Friend Property Get Cancel() As Boolean
Cancel = m_bCancel
End Property

Friend Property Get Value() As String
Value = m_sValue
End Property

Friend Function CurrentValue() As String
If m_idxTextBox > 0 And m_idxTextBox <= FakeDXUIControlCount Then
 CurrentValue = FakeDXUIControls(m_idxTextBox).Text
End If
End Function

Friend Function InputBox(Optional ByVal Prompt As String, Optional ByVal Title As String, Optional ByVal Default As String, Optional ByVal Locked As Boolean, Optional ByVal MultiLine As Boolean, Optional ByVal ScrollBars As ScrollBarConstants, Optional ByVal Flags As enumFakeDXUIControlStyle) As String
Dim w As Long, h As Long
'///
If m_idx > 0 Or m_idxTextBox > 0 Then Exit Function
m_bUnload = False
m_bCancel = True
m_sValue = vbNullString
'///
If MultiLine Then
 w = 200
 h = 128
Else
 w = 128
 h = 68
End If
'///
With FakeDXUIControls(1).AddNewChildren(FakeCtl_Form, -w, -h, w, h, _
FFS_CloseButton Or FFS_MaxButton Or FFS_Moveable Or FFS_Sizable Or FFS_TitleBar, , False, , Title, , , 0.5, 0.5, 0.5, 0.5)
 m_idx = .Index
 Set .EventObject = Me
 '///textbox
 With .AddNewChildren(FakeCtl_TextBox, 8, 72, -8, -8, FCS_TabStop Or FCS_CanGetFocus Or FTS_AutoSelect Or Flags, , , Locked, , Default, , , , 1, 1)
  .MultiLine = MultiLine
  .ScrollBars = ScrollBars
  m_idxTextBox = .Index
 End With
 '///other controls
 .AddNewChildren FakeCtl_Label, 8, 8, -8, -8, FLS_WordWrap, , , , Prompt, , , , , 1, 1
 If Locked Then
  .AddNewChildren FakeCtl_Button, -64, 8, -8, 32, FCS_TabStop Or FCS_CanGetFocus Or FBS_Default Or FBS_Cancel, , , , objText.GetText("Close"), , "cmdCancel", 1, , 1
 Else
  .AddNewChildren FakeCtl_Button, -64, 8, -8, 32, FCS_TabStop Or FCS_CanGetFocus Or FBS_Default, , , , objText.GetText("OK"), , "cmdOK", 1, , 1
  .AddNewChildren FakeCtl_Button, -64, 40, -8, 64, FCS_TabStop Or FCS_CanGetFocus Or FBS_Cancel, , , , objText.GetText("Cancel"), , "cmdCancel", 1, , 1
 End If
 '///
 .Show 1
End With
FakeDXUIPostMessage FakeCtl_Msg_SetFocus, m_idxTextBox
'///wait for single object
FakeDXAppMainLoop VarPtr(m_bUnload)
'///
InputBox = m_sValue
m_idx = 0
m_idxTextBox = 0
End Function

Private Sub IFakeDXUIEvent_Change(ByVal obj As clsFakeDXUI)
'
End Sub

Private Sub IFakeDXUIEvent_Click(ByVal obj As clsFakeDXUI)
Select Case obj.Name
Case "cmdOK"
 m_bCancel = False
 If m_idxTextBox > 0 And m_idxTextBox <= FakeDXUIControlCount Then
  m_sValue = FakeDXUIControls(m_idxTextBox).Text
 End If
Case "cmdCancel"
Case Else
 Exit Sub
End Select
If m_idx > 0 And m_idx <= FakeDXUIControlCount Then
 FakeDXUIControls(m_idx).Unload
 m_bUnload = True
 m_idx = 0
End If
End Sub

Private Sub IFakeDXUIEvent_DblClick(ByVal obj As clsFakeDXUI)
'
End Sub

Private Sub IFakeDXUIEvent_Unload(ByVal obj As clsFakeDXUI, Cancel As Boolean)
m_bUnload = True
End Sub
