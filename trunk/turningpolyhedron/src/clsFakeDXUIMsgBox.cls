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

Private Declare Function MessageBeep Lib "user32.dll" (ByVal wType As Long) As Long
'Private Declare Function DrawTextW Lib "user32.dll" (ByVal hdc As Long, ByRef lpStr As Any, ByVal nCount As Long, ByRef lpRect As D3DRECT, ByVal wFormat As Long) As Long

Private m_idx As Long

Private m_nReturnValue As Long
Private m_bUnload As Boolean

Private m_nButtonCount As Long
Private m_sButtonCaption() As String
Private m_nButtonValue() As Long

Implements IFakeDXUIEvent

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

'new style:
'&H10000000=sizable
'&H20000000=no close
'&H40000000=no caption
'&H80000000=not moveable
'TODO:autosize,custom buttons,default button,icon,etc.
Friend Function MsgBox(Optional ByVal Prompt As String, Optional ByVal Buttons As VbMsgBoxStyle, Optional ByVal Title As String, Optional ByVal Default As VbMsgBoxResult) As VbMsgBoxResult
Dim w As Long, h As Long
Dim ww As Single, hh As Single
Dim ww1 As Single ', hh1 As Single
Dim i As Long, x As Long
Dim idx As Long
Dim ii As Long
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
'///
ii = Buttons And &H70&
If ii <= &H40& Then MessageBeep ii _
Else ii = 0
'///calc size
w = m_nButtonCount * 64& - 8&
If w < 32& Then w = 32&
'///debug
If Len(Prompt) > 0 Then _
Call FakeDXGDIDrawText(FakeDXUIDefaultFont, Prompt, 0, 0, d3dpp.BackBufferWidth - 64, 16, 0.5, DT_WORDBREAK Or DT_CALCRECT, 0, , , , , , , , ww, hh)
'Debug.Print ww, hh, hh1
''debug2
'Dim r As D3DRECT
'r.x2 = (d3dpp.BackBufferWidth - 32) * 2
'DrawTextW FakeDXUIDefaultFont.objFont.GetDC, ByVal StrPtr(Prompt), Len(Prompt), r, DT_WORDBREAK Or DT_CALCRECT
'Debug.Print r.x2 / 2, r.Y2 / 2
''///
ww = ww + 2
If ii > 0 Then
 ww = ww + 56
 If hh < 48 Then hh = 48
End If
'///
If Len(Title) > 0 Then _
FakeDXGDIDrawText FakeDXUIDefaultFont, Title, 0, 0, d3dpp.BackBufferWidth - 64, 16, 0.5, DT_CALCRECT Or DT_SINGLELINE, 0, , , , , , , , ww1
ww1 = ww1 + 10
If ww < ww1 Then ww = ww1
If ww < w Then ww = w
'If ww > d3dpp.BackBufferWidth - 32 Then 'does not work
' FakeDXGDIDrawText FakeDXUIDefaultFont, Prompt, 0, 0, ww, hh, 0.5, DT_WORDBREAK Or DT_CALCRECT, 0, , , , , , , , ww, hh
' If ww < w Then ww = w
 If ww > d3dpp.BackBufferWidth - 32 Then ww = d3dpp.BackBufferWidth - 32
'End If
If hh > d3dpp.BackBufferHeight - 80 Then hh = d3dpp.BackBufferHeight - 80
w = CLng(ww) \ 2& + 12
h = CLng(hh) \ 2& + 28 + (10 And (Buttons And &H40000000) = 0)
'///
With FakeDXUIControls(1).AddNewChildren(FakeCtl_Form, -w, -h, _
w, h, (FFS_CloseButton And (Buttons And &H20000000) = 0) _
Or (FFS_Moveable And (Buttons And &H80000000) = 0) _
Or (FFS_TitleBar And (Buttons And &H40000000) = 0) _
Or (FFS_Sizable And (Buttons And &H10000000) <> 0), , False, , Title, , , 0.5, 0.5, 0.5, 0.5)
 m_idx = .Index
 Set .EventObject = Me
 '///
 If ii > 0 Then .AddNewChildren FakeCtl_Label, 8, 8, 8, 8, ii
 .AddNewChildren FakeCtl_Label, 8 + ((ii > 0) And 56&), 8, -8, -8, FLS_WordWrap, , , , Prompt, , , , , 1, 1
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
FakeDXAppMainLoop VarPtr(m_bUnload)
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

Private Function IFakeDXUIEvent_OnEvent(ByVal obj As clsFakeDXUI, ByVal nType As Long, ByVal nParam1 As Long, ByVal nParam2 As Long, ByVal nParam3 As Long) As Long
Select Case nType
Case FakeCtl_Event_Click
 Select Case obj.Name
 Case "MsgBox"
  m_nReturnValue = Val(obj.GroupName)
  If m_idx > 0 And m_idx <= FakeDXUIControlCount Then
   FakeDXUIControls(m_idx).Unload
   m_bUnload = True
   m_idx = 0
  End If
 End Select
Case FakeCtl_Event_Unload
 m_bUnload = True
End Select
End Function

