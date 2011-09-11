VERSION 5.00
Begin VB.Form frmMain 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Form1"
   ClientHeight    =   7200
   ClientLeft      =   45
   ClientTop       =   435
   ClientWidth     =   9600
   BeginProperty Font 
      Name            =   "Tahoma"
      Size            =   8.25
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   KeyPreview      =   -1  'True
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   ScaleHeight     =   480
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   640
   StartUpPosition =   3  '´°¿ÚÈ±Ê¡
End
Attribute VB_Name = "frmMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Declare Function GetCursorPos Lib "user32.dll" (ByRef lpPoint As POINTAPI) As Long
Private Declare Function ScreenToClient Lib "user32.dll" (ByVal hwnd As Long, ByRef lpPoint As POINTAPI) As Long
Private Type POINTAPI
    x As Long
    y As Long
End Type

Private Sub Form_Click()
Dim p As POINTAPI
GetCursorPos p
ScreenToClient Me.hwnd, p
If Not FakeDXAppEvent Is Nothing Then FakeDXAppEvent.OnEvent FakeDXAppEvent_Click, p.x, p.y, 1
End Sub

Private Sub Form_DblClick()
Dim p As POINTAPI
GetCursorPos p
ScreenToClient Me.hwnd, p
If FakeDXUIOnMouseEvent(1, 0, p.x, p.y, 4) Then Exit Sub
If Not FakeDXAppEvent Is Nothing Then FakeDXAppEvent.OnEvent FakeDXAppEvent_DblClick, p.x, p.y, 1
End Sub

Private Sub Form_KeyDown(KeyCode As Integer, Shift As Integer)
'///
If FakeDXUIOnKeyEvent(KeyCode, Shift, 1) Then Exit Sub
If Not FakeDXAppEvent Is Nothing Then FakeDXAppEvent.OnEvent FakeDXAppEvent_KeyDown, KeyCode, Shift, 0
'///debug only
'If KeyCode = vbKeyS And Shift = vbCtrlMask Then
'   D3DXSaveTextureToFileW CStr(App.Path) + "\test.bmp", D3DXIFF_BMP, objTexture, ByVal 0
'   D3DXSaveTextureToFileW CStr(App.Path) + "\testnormal.bmp", D3DXIFF_BMP, objNormalTexture, ByVal 0
'End If
End Sub

Private Sub Form_KeyPress(KeyAscii As Integer)
'///
If FakeDXUIOnKeyEvent(KeyAscii, 0, 0) Then Exit Sub
If Not FakeDXAppEvent Is Nothing Then FakeDXAppEvent.OnEvent FakeDXAppEvent_KeyPress, KeyAscii, 0, 0
'///
End Sub

Private Sub Form_KeyUp(KeyCode As Integer, Shift As Integer)
'///
If FakeDXUIOnKeyEvent(KeyCode, Shift, 2) Then Exit Sub
If Not FakeDXAppEvent Is Nothing Then FakeDXAppEvent.OnEvent FakeDXAppEvent_KeyUp, KeyCode, Shift, 0
'///
End Sub

Private Sub Form_Load()
FakeDXAppInit Me
FakeDXAppMainLoop
FakeDXAppDestroy
End Sub

Private Sub Form_MouseDown(Button As Integer, Shift As Integer, x As Single, y As Single)
'///
If FakeDXUIOnMouseEvent(Button, Shift, x, y, 1) Then Exit Sub
'///
FakeDXUISetCapture = -1
If Not FakeDXAppEvent Is Nothing Then FakeDXAppEvent.OnEvent FakeDXAppEvent_MouseDown, x, y, CLng(Button) Or (CLng(Shift) * &H10000)
'///
End Sub

Private Sub Form_MouseMove(Button As Integer, Shift As Integer, x As Single, y As Single)
'///
If FakeDXUIOnMouseEvent(Button, Shift, x, y, 0) Then Exit Sub
'///
If Not FakeDXAppEvent Is Nothing Then FakeDXAppEvent.OnEvent FakeDXAppEvent_MouseMove, x, y, CLng(Button) Or (CLng(Shift) * &H10000)
'///
End Sub

Private Sub Form_MouseUp(Button As Integer, Shift As Integer, x As Single, y As Single)
'///
If FakeDXUIOnMouseEvent(Button, Shift, x, y, 2) Then Exit Sub
'///
FakeDXUISetCapture = 0
If Not FakeDXAppEvent Is Nothing Then FakeDXAppEvent.OnEvent FakeDXAppEvent_MouseUp, x, y, CLng(Button) Or (CLng(Shift) * &H10000)
'///
End Sub

Private Sub Form_QueryUnload(Cancel As Integer, UnloadMode As Integer)
FakeDXAppUnSubclass
FakeDXAppRequestUnload = True
Cancel = &H1& And Not FakeDXAppCanUnload
End Sub
