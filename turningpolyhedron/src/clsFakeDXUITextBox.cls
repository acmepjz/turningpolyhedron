VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsFakeDXUITextBox"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Declare Function GetCharacterPlacementW Lib "Gdi32.dll" ( _
  ByVal hdc As Long, _
  ByRef lpString As Any, _
  ByVal nCount As Long, _
  ByVal nMaxExtent As Long, _
  ByRef lpResults As GCP_RESULTS, _
  ByVal dwFlags As Long) As Long

Private Type GCP_RESULTS
  lStructSize As Long
  lpOutString As Long
  lpOrder As Long
  lpDx As Long
  lpCaretPos As Long
  lpClass As Long
  lpGlyphs As Long
  nGlyphs As Long
  nMaxFit As Long
End Type


'Private Sub Command1_Click()
'Dim s As String
'Dim t As GCP_RESULTS
'Dim i As Long, h As Long
'Dim nCaretPos() As Long
'Dim nDistance() As Long
''///
'Set cFnt.LogFont = Picture1.Font
'cFnt.HighQuality = True
''///
's = "LKSCT??xyzwWwfj ZzZ@XwY#!|xd°¡°¢"
'Picture1.Cls
'Picture1.Print s
''///
'ReDim nCaretPos(1023)
'ReDim nDistance(1023)
't.lStructSize = Len(t)
't.lpDx = VarPtr(nDistance(0))
't.lpCaretPos = VarPtr(nCaretPos(0))
't.nGlyphs = 1024
''///
'h = SelectObject(Picture1.hdc, cFnt.Handle)
'i = GetCharacterPlacementW(Picture1.hdc, ByVal StrPtr(s), Len(s), 0, t, 0)
'SelectObject Picture1.hdc, h
''///
''///
''Debug.Print i And &HFFFF&, (i And &HFFFF0000) \ &H10000
'For i = 0 To t.nGlyphs - 1
' Picture1.Line (nCaretPos(i), 0)-Step(0, 16), vbRed
' Picture1.Line (nCaretPos(i) + nDistance(i), 14)-Step(0, 16), vbBlue
'Next i
''///
'
'End Sub

