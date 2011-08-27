VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsProgressDialog"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Implements IFakeDXUIEvent

Private m_idxProgressForm As Long, m_idxProgress As Long
Private m_bCancel As Boolean

Friend Sub CreateAndShow(ByVal Caption As String)
HideAndDestroy
'///
m_bCancel = False
'///
With FakeDXUIControls(1).AddNewChildren(FakeCtl_Form, 0, 0, 400, 96, _
FFS_Moveable Or FFS_TitleBar, , False, , Caption)
 m_idxProgressForm = .Index
 Set .EventObject = Me
 '///
 m_idxProgress = .AddNewChildren(FakeCtl_ProgressBar, 8, -10, -80, 10, , , , , , , , , 0.5, 1, 0.5).Index
 .AddNewChildren FakeCtl_Button, -72, -12, -8, 12, FCS_TabStop Or FCS_CanGetFocus Or FBS_Cancel, , , , objText.GetText("Cancel"), , "cmdCancel", 1, 0.5, 1, 0.5
 '///
 .MoveToCenter
 .Show 1
End With
'///
FakeDXAppMainLoop , True
End Sub

Friend Sub HideAndDestroy()
If m_idxProgressForm Then
 FakeDXUIControls(m_idxProgressForm).Unload
 m_idxProgressForm = 0
 m_idxProgress = 0
End If
End Sub

Friend Property Get Cancel() As Boolean
Cancel = m_bCancel
End Property

Friend Property Let Cancel(ByVal b As Boolean)
m_bCancel = b
End Property

Friend Sub SetProgress(Optional ByVal nValue As Long, Optional ByVal nMax As Long, Optional ByVal sCaption As String)
If m_idxProgress Then
 If nMax > 0 Then FakeDXUIControls(m_idxProgress).Max = nMax
 FakeDXUIControls(m_idxProgress).Value = nValue
 FakeDXUIControls(m_idxProgress).Caption = sCaption
End If
End Sub

Private Sub Class_Terminate()
HideAndDestroy
End Sub

Private Function IFakeDXUIEvent_OnEvent(ByVal obj As clsFakeDXUI, ByVal nType As Long, ByVal nParam1 As Long, ByVal nParam2 As Long, ByVal nParam3 As Long) As Long
Select Case nType
Case FakeCtl_Event_Click
 Select Case obj.Name
 Case "cmdCancel"
  m_bCancel = True
 End Select
Case FakeCtl_Event_Unload
 m_bCancel = True
 m_idxProgressForm = 0
 m_idxProgress = 0
End Select
End Function
