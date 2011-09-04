VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "frmAbout"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Declare Function ShellExecute Lib "shell32.dll" Alias "ShellExecuteA" (ByVal hwnd As Long, ByVal lpOperation As String, ByVal lpFile As String, ByVal lpParameters As String, ByVal lpDirectory As String, ByVal nShowCmd As Long) As Long

Private Const ProjectHomepage As String = "http://code.google.com/p/turningpolyhedron/"

Implements IFakeDXUIEvent

Private m_idxForm As Long, m_idxFormLicense As Long, m_idxLicense As Long
Private m_bLicenseLoaded As Boolean

Friend Sub Create()
If m_idxForm Then Exit Sub
With FakeDXUIControls(1)
 '///about
 With .AddNewChildren(FakeCtl_Form, 0, 0, 512, 360, _
 FFS_CloseButton Or FFS_Moveable Or FFS_TitleBar, , False, , _
 objText.GetText("About"))
  m_idxForm = .Index
  Set .EventObject = Me
  '///
  .AddNewChildren FakeCtl_Label, 8, 8, -8, -8, FLS_WordWrap, , , , _
  objText.GetText("Turning Polyhedron") + "   " + objText.GetText("version") + " " + FakeDXAppVersion + vbCrLf + vbCrLf + _
  Replace(App.LegalCopyright, "Copyright", objText.GetText("Copyright")) + vbCrLf + vbCrLf + _
  objText.GetText("This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.") + vbCrLf + vbCrLf + _
  objText.GetText("This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.") + vbCrLf + vbCrLf + _
  objText.GetText("You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>."), _
  , , , , 1, 1
  '///some buttons
  .AddNewChildren FakeCtl_Button, 8, -32, 160, -8, FCS_TabStop Or FCS_CanGetFocus, , , , _
  objText.GetText("View full license"), _
  , "cmdLicense", , 1, , 1
  .AddNewChildren FakeCtl_Button, 168, -32, 320, -8, FCS_TabStop Or FCS_CanGetFocus, , , , _
  objText.GetText("Visit project homepage"), _
  , "cmdHomepage", , 1, , 1, , , _
  objText.GetText("Visit project homepage") + " (" + ProjectHomepage + ")"
  .AddNewChildren FakeCtl_Button, -80, -32, -8, -8, FCS_TabStop Or FCS_CanGetFocus Or FBS_Default Or FBS_Cancel, , , , _
  objText.GetText("OK"), _
  , "cmdOK", 1, 1, 1, 1
 End With
 '///license
 With .AddNewChildren(FakeCtl_Form, 0, 0, 600, 400, _
 FFS_CloseButton Or FFS_MaxButton Or FFS_Moveable Or FFS_TitleBar Or FFS_Sizable, , False, , _
 objText.GetText("License"))
  m_idxFormLicense = .Index
  Set .EventObject = Me
  '///textbox
  With .AddNewChildren(FakeCtl_TextBox, 8, 8, -8, -40, FCS_CanGetFocus Or FCS_TabStop, , , True, , , , , , 1, 1)
   m_idxLicense = .Index
   .MultiLine = True
   .ScrollBars = vbBoth
  End With
  '///some buttons
  .AddNewChildren FakeCtl_Button, -40, -32, 40, -8, FCS_TabStop Or FCS_CanGetFocus Or FBS_Default Or FBS_Cancel, , , , _
  objText.GetText("OK"), _
  , "cmdOK2", 0.5, 1, 0.5, 1
 End With
End With
End Sub

Friend Sub Show()
Create
'///
With FakeDXUIControls(m_idxForm)
 .MoveToCenter
 .Show 1
End With
End Sub

Friend Sub ShowLicense()
Dim b() As Byte, s As String
Dim i As Long
'///
Create
'///
If Not m_bLicenseLoaded Then
 s = App.Path + "\COPYING"
 On Error Resume Next
 Err.Clear
 i = GetAttr(s)
 If Err.Number = 0 And (i And vbDirectory) = 0 Then
  Open s For Binary Access Read As #1
  i = LOF(1)
  If i > 0 Then
   ReDim b(i - 1)
   Get #1, 1, b
  End If
  Close
 Else
  i = 0
 End If
 On Error GoTo 0
 '///
 If i > 0 Then
  s = StrConv(b, vbUnicode)
  s = Replace(s, vbCrLf, vbLf)
  s = Replace(s, vbCr, vbLf)
  s = Replace(s, vbLf, vbCrLf)
  FakeDXUIControls(m_idxLicense).Text = s
  m_bLicenseLoaded = True
 Else
  With New clsFakeDXUIMsgBox
   .MsgBox objText.GetText("Can't load license file. Please see <http://www.gnu.org/licenses/>."), vbExclamation, objText.GetText("Error")
  End With
  Exit Sub
 End If
End If
'///
With FakeDXUIControls(m_idxFormLicense)
 .MoveToCenter
 .Show 1
End With
End Sub

Private Function IFakeDXUIEvent_OnEvent(ByVal obj As clsFakeDXUI, ByVal nType As Long, ByVal nParam1 As Long, ByVal nParam2 As Long, ByVal nParam3 As Long) As Long
Dim i As Long
'///
Select Case nType
Case FakeCtl_Event_Click
 Select Case obj.Name
 Case "cmdOK"
  i = m_idxForm
 Case "cmdOK2"
  i = m_idxFormLicense
 Case "cmdLicense"
  ShowLicense
 Case "cmdHomepage"
  ShellExecute d3dpp.hDeviceWindow, "open", ProjectHomepage, vbNullString, vbNullString, 5
 End Select
Case FakeCtl_Event_Unload
 i = obj.Index
 IFakeDXUIEvent_OnEvent = 1
End Select
'///
If i > 0 Then FakeDXUIControls(i).Hide
End Function
