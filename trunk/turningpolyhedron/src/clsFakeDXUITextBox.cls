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

Private Const m_nLineHeight As Long = 32

Private Declare Function GetCharacterPlacementW Lib "Gdi32.dll" ( _
  ByVal hdc As Long, _
  ByRef lpString As Any, _
  ByVal nCount As Long, _
  ByVal nMaxExtent As Long, _
  ByRef lpResults As GCP_RESULTS, _
  ByVal dwFlags As Long) As Long

Private Declare Function GetTextExtentPoint32W Lib "Gdi32.dll" ( _
  ByVal hdc As Long, _
  ByRef lpString As Any, _
  ByVal c As Long, _
  ByRef lpSize As Any) As Long
Private Const GCP_MAXEXTENT As Long = &H100000

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

Private m_nFontZoom As Single
Private m_bMultiLine As Boolean
Private m_bWrap As Boolean
Private m_bLocked As Boolean

Private m_sLines() As String '0-based
Private m_tLineData() As typeFakeDXUITextBoxLineMetric '0-based
Private m_nLineMax As Long
Private m_nLineCount As Long

Private m_tCaret As typeFakeDXUITextBoxPos
Private m_tSelStart As typeFakeDXUITextBoxPos
Private m_nCaretTimer As Long '0-31
Private m_bInsertMode As Boolean

Private m_nWidth As Long, m_bSizeDirty As Boolean
Private m_nHeight As Long
Private m_nTextWidth As Long
Private m_nTextHeight As Long

Private m_nScrollValue(1) As Long, m_bScrollChanged As Boolean
Private m_bCapture As Boolean

Friend Property Get ScrollValue(Optional ByVal nIndex As Long) As Long
ScrollValue = m_nScrollValue(nIndex)
End Property

Friend Property Let ScrollValue(Optional ByVal nIndex As Long, ByVal n As Long)
m_nScrollValue(nIndex) = n
End Property

Friend Sub Clear()
Erase m_sLines, m_tLineData
m_nLineMax = 0
m_nLineCount = 0
m_tCaret.nRow = 0
m_tCaret.nPosition = 0
m_tSelStart.nRow = -1
m_bInsertMode = False
m_nTextWidth = 0
m_nTextHeight = 0
m_nScrollValue(0) = 0
m_nScrollValue(1) = 0
m_bScrollChanged = True
m_bCapture = False
End Sub

Friend Sub CalcLineDataIfSizeChanged(Optional ByVal bForce As Boolean)
If bForce Or m_bSizeDirty Then
 CalcLineData
 m_bSizeDirty = False
End If
End Sub

Friend Sub CalcLineData(Optional ByVal nStart As Long = -1, Optional ByVal nEnd As Long = -1)
Dim i As Long, m As Long
Dim lp As Long, lps As Long, w As Long
Dim hd As Long
Dim t As GCP_RESULTS
'///
If nStart < 0 Then
 nStart = 0
 nEnd = m_nLineCount - 1
ElseIf nEnd < 0 Then
 nEnd = nStart
End If
'///calc line width
hd = FakeDXUIDefaultFont.objFont.GetDC
w = m_nWidth / m_nFontZoom
For i = nStart To nEnd
 '///begin
 m = Len(m_sLines(i))
 If m > 0 Then
  lp = StrPtr(m_sLines(i))
  If m_bWrap Then
   '///
   With m_tLineData(i)
    .nLineWidth = m_nWidth
    .nLineHeight = 0
   End With
   '///
   t.lStructSize = Len(t)
   lps = 0
   Do
    t.nGlyphs = m - lps
    GetCharacterPlacementW hd, ByVal (lp + lps + lps), t.nGlyphs, w, t, GCP_MAXEXTENT
    If t.nMaxFit <= 0 Then t.nMaxFit = 1
    'add
    With m_tLineData(i)
     ReDim Preserve .nLineStart(.nLineHeight), .nLineLength(.nLineHeight) 'slow code
     .nLineStart(.nLineHeight) = lps
     .nLineLength(.nLineHeight) = t.nMaxFit
     .nLineHeight = .nLineHeight + 1
    End With
    'next
    lps = lps + t.nMaxFit
   Loop While lps < m
   '///
  Else
   GetTextExtentPoint32W hd, ByVal lp, m, m_tLineData(i).nLineWidth
   With m_tLineData(i)
    .nLineHeight = 1
    ReDim .nLineStart(0), .nLineLength(0)
    .nLineStart(0) = 0
    .nLineLength(0) = m
   End With
  End If
 Else
  With m_tLineData(i)
   .nLineWidth = 0
   .nLineHeight = 1
   ReDim .nLineStart(0), .nLineLength(0)
   .nLineStart(0) = 0
   .nLineLength(0) = m
  End With
 End If
 '///end
Next i
'///calc text width and height
m_nTextWidth = 0
m_nTextHeight = 0
For i = 0 To m_nLineCount - 1
 w = m_tLineData(i).nLineWidth
 If m_nTextWidth < w Then m_nTextWidth = w
 m_tLineData(i).nLineOffset = m_nTextHeight
 m_nTextHeight = m_nTextHeight + m_tLineData(i).nLineHeight
Next i
'///
m_nTextWidth = m_nTextWidth + 32 '??
m_nTextHeight = m_nTextHeight * m_nLineHeight
End Sub

Friend Property Get Text() As String
Text = Join(m_sLines, vbCrLf)
End Property

Friend Property Let Text(ByRef s As String)
If m_bMultiLine Then
 m_sLines = Split(s, vbCrLf)
 m_nLineMax = UBound(m_sLines) + 1
 If m_nLineMax <= 0 Then
  m_nLineMax = 1
  ReDim m_sLines(0)
 End If
 ReDim m_tLineData(m_nLineMax - 1)
 m_nLineCount = m_nLineMax
Else
 If m_nLineMax < 1 Then
  m_nLineMax = 1
  ReDim m_sLines(0), m_tLineData(0)
 End If
 m_nLineCount = 1
 m_sLines(0) = s
End If
'///
m_tCaret.nRow = 0
m_tCaret.nPosition = 0
m_tSelStart.nRow = -1
'///
CalcLineData
End Property

Friend Property Get SelText(Optional ByVal bInsertMode As Boolean) As String
Dim bSelection As Boolean
Dim tSelStart As typeFakeDXUITextBoxPos, tSelEnd As typeFakeDXUITextBoxPos
Dim i As Long, j As Long, k As Long
Dim s As String
'///
If m_tSelStart.nRow >= 0 Then
 If m_tSelStart.nRow < m_tCaret.nRow Then
  tSelStart = m_tSelStart
  tSelEnd = m_tCaret
  bSelection = True
 ElseIf m_tSelStart.nRow > m_tCaret.nRow Then
  tSelStart = m_tCaret
  tSelEnd = m_tSelStart
  bSelection = True
 ElseIf m_tSelStart.nPosition < m_tCaret.nPosition Then
  tSelStart = m_tSelStart
  tSelEnd = m_tCaret
  bSelection = True
 ElseIf m_tSelStart.nPosition > m_tCaret.nPosition Then
  tSelStart = m_tCaret
  tSelEnd = m_tSelStart
  bSelection = True
 End If
End If
'///
If bSelection Then
 For i = tSelStart.nRow To tSelEnd.nRow
  If i = tSelStart.nRow Then j = tSelStart.nPosition Else j = 0
  If i = tSelEnd.nRow Then k = tSelEnd.nPosition Else k = Len(m_sLines(i))
  s = s + Mid$(m_sLines(i), j + 1, k - j)
  If i < tSelEnd.nRow Then s = s + vbCrLf
 Next i
End If
SelText = s
End Property

Friend Property Let SelText(Optional ByVal bInsertMode As Boolean, ByVal s As String)
Dim s1() As String, m As Long, m0 As Long
Dim s2 As String
Dim bSelection As Boolean
Dim tSelStart As typeFakeDXUITextBoxPos, tSelEnd As typeFakeDXUITextBoxPos
Dim nNewCount As Long
Dim i As Long, j As Long, k As Long
If m_nLineCount > 0 Then
 '///calc SelText data
 If Not m_bMultiLine Then s = Replace(s, vbCrLf, "")
 s1 = Split(s, vbCrLf)
 m = UBound(s1) + 1
 If m <= 0 Then
  ReDim s1(0)
  m = 1
 End If
 '///calc selection pos
 If m_tSelStart.nRow >= 0 Then
  If m_tSelStart.nRow < m_tCaret.nRow Then
   tSelStart = m_tSelStart
   tSelEnd = m_tCaret
   bSelection = True
  ElseIf m_tSelStart.nRow > m_tCaret.nRow Then
   tSelStart = m_tCaret
   tSelEnd = m_tSelStart
   bSelection = True
  ElseIf m_tSelStart.nPosition < m_tCaret.nPosition Then
   tSelStart = m_tSelStart
   tSelEnd = m_tCaret
   bSelection = True
  ElseIf m_tSelStart.nPosition > m_tCaret.nPosition Then
   tSelStart = m_tCaret
   tSelEnd = m_tSelStart
   bSelection = True
  End If
 End If
 If Not bSelection Then
  tSelStart = m_tCaret
  tSelEnd = m_tCaret
 End If
 '///resize
 m0 = tSelEnd.nRow - tSelStart.nRow + 1
 nNewCount = m_nLineCount - m0 + m
 If nNewCount > m_nLineMax Then
  m_nLineMax = nNewCount + 16
  ReDim Preserve m_sLines(m_nLineMax - 1)
  ReDim Preserve m_tLineData(m_nLineMax - 1)
 End If
 '///backup old string
 s2 = m_sLines(tSelEnd.nRow)
 '///move data
 If nNewCount > m_nLineCount Then
  For i = m_nLineCount - 1 To tSelEnd.nRow + 1 Step -1
   m_sLines(i - m0 + m) = m_sLines(i)
   m_tLineData(i - m0 + m) = m_tLineData(i)
  Next i
 ElseIf nNewCount < m_nLineCount Then
  For i = tSelEnd.nRow + 1 To m_nLineCount - 1
   m_sLines(i - m0 + m) = m_sLines(i)
   m_tLineData(i - m0 + m) = m_tLineData(i)
  Next i
 End If
 '///merge SelText to string
 For i = 0 To m - 1
  If i = 0 Then
   If m > 1 Then
    m_sLines(tSelStart.nRow + i) = Left$(m_sLines(tSelStart.nRow + i), tSelStart.nPosition) + s1(i)
   ElseIf bInsertMode Then
    m_sLines(tSelStart.nRow + i) = Left$(m_sLines(tSelStart.nRow + i), tSelStart.nPosition) + s1(i) + Mid$(s2, tSelEnd.nPosition + Len(s1(i)) + 1)
   Else
    m_sLines(tSelStart.nRow + i) = Left$(m_sLines(tSelStart.nRow + i), tSelStart.nPosition) + s1(i) + Mid$(s2, tSelEnd.nPosition + 1)
   End If
  ElseIf i = m - 1 Then
   m_sLines(tSelStart.nRow + i) = s1(i) + Mid$(s2, tSelEnd.nPosition + 1)
  Else
   m_sLines(tSelStart.nRow + i) = s1(i)
  End If
 Next i
 m_nLineCount = nNewCount
 '///change caret pos and update width data
 If m > 1 Then m_tCaret.nPosition = 0 Else m_tCaret.nPosition = tSelStart.nPosition
 m_tCaret.nPosition = m_tCaret.nPosition + Len(s1(m - 1))
 m_tCaret.nRow = tSelStart.nRow + m - 1
 CalcLineData tSelStart.nRow, m_tCaret.nRow
 '///over
 ChangeCaretPos , , True
 m_nCaretTimer = 0
Else
 Text = s
 ChangeCaretPos m_nLineCount - 1, Len(m_sLines(m_nLineCount - 1)), True
End If
End Property

Friend Property Get MultiLine() As Boolean
MultiLine = m_bMultiLine
End Property

Friend Property Let MultiLine(ByVal b As Boolean)
If m_bMultiLine <> b Then
 m_bMultiLine = b
 Text = Text ':-3
End If
End Property

Friend Property Get Locked() As Boolean
Locked = m_bLocked
End Property

Friend Property Let Locked(ByVal b As Boolean)
m_bLocked = b
End Property

Friend Property Get ScrollChanged() As Boolean
ScrollChanged = m_bScrollChanged
End Property

Friend Property Let ScrollChanged(ByVal b As Boolean)
m_bScrollChanged = b
End Property

Friend Property Get InsertMode() As Boolean
InsertMode = m_bInsertMode
End Property

Friend Property Let InsertMode(ByVal b As Boolean)
m_bInsertMode = b
End Property

Friend Property Get Wrap() As Boolean
Wrap = m_bWrap
End Property

Friend Property Let Wrap(ByVal b As Boolean)
If m_bWrap <> b Then
 m_bWrap = b
 m_bSizeDirty = True
End If
End Property

Friend Property Get TextWidth() As Long
TextWidth = m_nTextWidth
End Property

Friend Property Get TextHeight() As Long
TextHeight = m_nTextHeight
End Property

Friend Property Get Width() As Long
Width = m_nWidth
End Property

Friend Property Let Width(ByVal n As Long)
If m_nWidth <> n Then
 m_nWidth = n
 If m_bWrap Then m_bSizeDirty = True
End If
End Property

Friend Property Get Height() As Long
Height = m_nHeight
End Property

Friend Property Let Height(ByVal n As Long)
'If m_nHeight <> n Then
' m_bHeightChanged = True
 m_nHeight = n
'End If
End Property

Friend Property Get FontZoom() As Single
FontZoom = m_nFontZoom
End Property

Friend Property Let FontZoom(ByVal f As Single)
m_nFontZoom = f
End Property

Friend Function OnKeyEvent(ByVal KeyCode As Long, ByVal Shift As Long, ByVal nEventType As Long) As Boolean
Dim i As Long
Dim s As String
'///
'TODO:other
'///
Select Case nEventType
Case 0 'keypress
 If KeyCode >= 0 And KeyCode < 32 Then 'control code
  Select Case KeyCode
  Case 1 'Ctrl+A
   If m_nLineCount > 0 Then
    With m_tSelStart
     .nRow = 0
     .nPosition = 0
    End With
    ChangeCaretPos m_nLineCount - 1, Len(m_sLines(m_nLineCount - 1)), True, True
   End If
  Case 24 'Ctrl+X
   If m_bLocked Then
    Beep
   ElseIf m_nLineCount > 0 And m_tSelStart.nRow >= 0 And (m_tSelStart.nRow <> m_tCaret.nRow Or m_tSelStart.nPosition <> m_tCaret.nPosition) Then
    Clipboard.Clear
    Clipboard.SetText SelText
    SelText = ""
   End If
  Case 3 'Ctrl+C
   If m_nLineCount > 0 And m_tSelStart.nRow >= 0 And (m_tSelStart.nRow <> m_tCaret.nRow Or m_tSelStart.nPosition <> m_tCaret.nPosition) Then
    Clipboard.Clear
    Clipboard.SetText SelText
   End If
  Case 22 'Ctrl+V
   If m_bLocked Then
    Beep
   Else
    s = Clipboard.GetText
    If s <> "" Then SelText = s
   End If
  Case 26 'Ctrl+Z
   'TODO:
  Case 8 'backspace
   If m_bLocked Then
    Beep
   ElseIf m_nLineCount > 0 Then
    If m_tSelStart.nRow >= 0 And (m_tSelStart.nRow <> m_tCaret.nRow Or m_tSelStart.nPosition <> m_tCaret.nPosition) Then
     SelText = ""
    ElseIf m_tCaret.nPosition > 0 Then
     With m_tCaret
      m_sLines(.nRow) = Left$(m_sLines(.nRow), .nPosition - 1) + Mid$(m_sLines(.nRow), .nPosition + 1)
      .nPosition = .nPosition - 1
     End With
     CalcLineData m_tCaret.nRow
     ChangeCaretPos , , True
     m_nCaretTimer = 0
    ElseIf m_tCaret.nRow > 0 Then
     With m_tCaret
      .nRow = .nRow - 1
      .nPosition = Len(m_sLines(.nRow))
      m_sLines(.nRow) = m_sLines(.nRow) + m_sLines(.nRow + 1)
      For i = .nRow + 1 To m_nLineCount - 2
       m_sLines(i) = m_sLines(i + 1)
       m_tLineData(i) = m_tLineData(i + 1)
      Next i
      m_nLineCount = m_nLineCount - 1
     End With
     CalcLineData m_tCaret.nRow
     ChangeCaretPos , , True
     m_nCaretTimer = 0
    End If
   End If
'  Case 9 'tab
'   If m_bLocked Then Beep Else SelText(m_bInsertMode) = vbTab '???
  Case 10, 13 'enter
   If m_bLocked Or Not m_bMultiLine Then Beep Else SelText = vbCrLf
  End Select
  KeyCode = 0
 End If
 If KeyCode Then
  If m_bLocked Then Beep Else SelText(m_bInsertMode) = Chr(KeyCode)
 End If
Case 1 'keydown
 If Shift And vbCtrlMask Then
  Select Case KeyCode
  Case vbKeyHome
   ChangeCaretPos 0, 0, True, Shift And vbShiftMask
  Case vbKeyEnd
   If m_nLineCount > 0 Then _
   ChangeCaretPos m_nLineCount - 1, Len(m_sLines(m_nLineCount - 1)), True, Shift And vbShiftMask
  End Select
 Else
  Select Case KeyCode
  Case vbKeyLeft
   ChangeCaretPosByDelta -1, True, Shift And vbShiftMask
  Case vbKeyRight
   ChangeCaretPosByDelta 1, True, Shift And vbShiftMask
  Case vbKeyUp
   If m_bMultiLine Then ChangeCaretPosFromPointDelta 0, -m_nLineHeight, True, Shift And vbShiftMask
  Case vbKeyDown
   If m_bMultiLine Then ChangeCaretPosFromPointDelta 0, m_nLineHeight, True, Shift And vbShiftMask
  Case vbKeyInsert
   m_bInsertMode = Not m_bInsertMode
  Case vbKeyDelete
   If m_bLocked Then
    Beep
   ElseIf m_nLineCount > 0 Then
    If m_tSelStart.nRow >= 0 And (m_tSelStart.nRow <> m_tCaret.nRow Or m_tSelStart.nPosition <> m_tCaret.nPosition) Then
     SelText = ""
    ElseIf m_tCaret.nPosition < Len(m_sLines(m_tCaret.nRow)) Then
     With m_tCaret
      m_sLines(.nRow) = Left$(m_sLines(.nRow), .nPosition) + Mid$(m_sLines(.nRow), .nPosition + 2)
     End With
     CalcLineData m_tCaret.nRow
     ChangeCaretPos , , True
     m_nCaretTimer = 0
    ElseIf m_tCaret.nRow < m_nLineCount - 1 Then
     With m_tCaret
      m_sLines(.nRow) = m_sLines(.nRow) + m_sLines(.nRow + 1)
      For i = .nRow + 1 To m_nLineCount - 2
       m_sLines(i) = m_sLines(i + 1)
       m_tLineData(i) = m_tLineData(i + 1)
      Next i
      m_nLineCount = m_nLineCount - 1
     End With
     CalcLineData m_tCaret.nRow
     ChangeCaretPos , , True
     m_nCaretTimer = 0
    End If
   End If
  Case vbKeyPageUp
   If m_bMultiLine Then
    i = m_nHeight / m_nFontZoom
    m_nScrollValue(1) = m_nScrollValue(1) - i
    m_bScrollChanged = True
    ChangeCaretPosFromPointDelta 0, -i, True, Shift And vbShiftMask
   End If
  Case vbKeyPageDown
   If m_bMultiLine Then
    i = m_nHeight / m_nFontZoom
    m_nScrollValue(1) = m_nScrollValue(1) + i
    m_bScrollChanged = True
    ChangeCaretPosFromPointDelta 0, i, True, Shift And vbShiftMask
   End If
  Case vbKeyHome
   If m_tCaret.nRow >= 0 And m_tCaret.nRow < m_nLineCount Then _
   ChangeCaretPos m_tCaret.nRow, 0, True, Shift And vbShiftMask
  Case vbKeyEnd
   If m_tCaret.nRow >= 0 And m_tCaret.nRow < m_nLineCount Then _
   ChangeCaretPos m_tCaret.nRow, Len(m_sLines(m_tCaret.nRow)), True, Shift And vbShiftMask
  End Select
 End If
End Select
'///
OnKeyEvent = True '?
End Function

Friend Function OnMouseEvent(ByVal Button As Long, ByVal Shift As Long, ByVal xClient As Single, ByVal yClient As Single, ByVal nEventType As Long) As Boolean
Dim bInControl As Boolean
bInControl = xClient >= 0 And xClient < m_nWidth And yClient >= 0 And yClient < m_nHeight
If Button = 1 Then
 Select Case nEventType
 Case 0 'mousemove
  If m_bCapture Then
   ChangeCaretPosFromPoint xClient / m_nFontZoom + m_nScrollValue(0), yClient / m_nFontZoom + m_nScrollValue(1), True, True
   FakeDXUIMousePointer = vbIbeam
  End If
 Case 1 'mousedown
  If bInControl Then
   ChangeCaretPosFromPoint xClient / m_nFontZoom + m_nScrollValue(0), yClient / m_nFontZoom + m_nScrollValue(1), True, Shift And vbShiftMask
   FakeDXUIMousePointer = vbIbeam
   m_bCapture = True
  End If
 Case 2
  m_bCapture = False
 End Select
Else
 If bInControl Then FakeDXUIMousePointer = vbIbeam
End If
End Function

Friend Sub Render(Optional ByVal nLeft As Single, Optional ByVal nTop As Single, Optional ByVal nOpacity As Single = 1, Optional ByVal bEnabled As Boolean = True, Optional ByVal bFocus As Boolean)
Dim mat As D3DMATRIX
Dim r As D3DRECT
Dim i As Long, ii As Long
Dim j As Long, jj As Long, jjj As Long
Dim k As Long, kk As Long
Dim m As Long
Dim lp As Long
Dim nStartLine As Long, nEndLine As Long
Dim clr As Long
Dim bSelection As Boolean
Dim tSelStart As typeFakeDXUITextBoxPos, tSelEnd As typeFakeDXUITextBoxPos
'///
'TODO:other
'///
If m_tSelStart.nRow >= 0 And bFocus Then
 If m_tSelStart.nRow < m_tCaret.nRow Then
  tSelStart = m_tSelStart
  tSelEnd = m_tCaret
  bSelection = True
 ElseIf m_tSelStart.nRow > m_tCaret.nRow Then
  tSelStart = m_tCaret
  tSelEnd = m_tSelStart
  bSelection = True
 ElseIf m_tSelStart.nPosition < m_tCaret.nPosition Then
  tSelStart = m_tSelStart
  tSelEnd = m_tCaret
  bSelection = True
 ElseIf m_tSelStart.nPosition > m_tCaret.nPosition Then
  tSelStart = m_tCaret
  tSelEnd = m_tSelStart
  bSelection = True
 End If
End If
'///
clr = nOpacity * 255
clr = ((clr And &H7F&) * &H1000000) Or ((clr > &H7F&) And &H80000000)
clr = clr Or (&H666666 And Not bEnabled)
'///
FakeDXUIDefaultFont.objSprite.Begin D3DXSPRITE_ALPHABLEND
mat.m11 = m_nFontZoom
mat.m22 = m_nFontZoom
mat.m33 = 1
mat.m41 = nLeft - m_nScrollValue(0) * m_nFontZoom
mat.m42 = nTop - m_nScrollValue(1) * m_nFontZoom
mat.m44 = 1
FakeDXUIDefaultFont.objSprite.SetTransform mat
'///
d3dd9.SetSamplerState 0, D3DSAMP_MIPMAPLODBIAS, SingleToLong(-0.5)
If m_nLineCount > 0 Then
 If m_bMultiLine Then
  '///text
  nStartLine = m_nScrollValue(1) \ m_nLineHeight
  nEndLine = nStartLine + CLng(m_nHeight / m_nFontZoom) \ m_nLineHeight + 1
  If m_bWrap Then
   '///perform a binary search
   i = 0
   k = m_nLineCount - 1
   Do
    j = (i + k) \ 2
    ii = m_tLineData(j).nLineOffset
    If nStartLine < ii Then
     k = j - 1
    ElseIf nStartLine >= ii + m_tLineData(j).nLineHeight Then
     i = j + 1
    Else
     i = ii
     Exit Do
    End If
    If i > k Then 'err!
     j = m_nLineCount
     Exit Do
    End If
   Loop
   '///
   For j = j To m_nLineCount - 1
    If i > nEndLine Then Exit For
    With m_tLineData(j)
     m = .nLineHeight
     ii = i + m
     If ii > nStartLine Then
      lp = StrPtr(m_sLines(j))
      k = nStartLine - i
      If k < 0 Then k = 0 Else i = nStartLine
      Do While k < m And i <= nEndLine
       r.Y1 = i * m_nLineHeight
       r.Y2 = r.Y1 + m_nLineHeight
       '///selection
       If bSelection Then
        If j >= tSelStart.nRow And j <= tSelEnd.nRow Then
         If j = tSelStart.nRow Then
          If .nLineStart(k) >= tSelStart.nPosition Then
           jj = 0
          ElseIf .nLineStart(k) + .nLineLength(k) <= tSelStart.nPosition And k < m - 1 Then
           jj = -1
          Else
           CalcCaretPos tSelStart.nRow, tSelStart.nPosition, jj
           jj = jj * m_nFontZoom
          End If
         Else
          jj = 0
         End If
         If j = tSelEnd.nRow Then
          If .nLineStart(k) >= tSelEnd.nPosition Then
           jj = -1
          ElseIf .nLineStart(k) + .nLineLength(k) <= tSelEnd.nPosition And k < m - 1 Then
           jjj = m_nWidth
          Else
           CalcCaretPos tSelEnd.nRow, tSelEnd.nPosition, jjj
           jjj = jjj * m_nFontZoom
          End If
         Else
          jjj = m_nWidth
         End If
         If jj >= 0 Then
          jj = nLeft + jj
          jjj = nLeft + jjj
          kk = nTop + (r.Y1 - m_nScrollValue(1)) * m_nFontZoom
          FakeDXGDIFillRect jj, kk, jjj, kk + m_nLineHeight * m_nFontZoom, clr Or &H5987D6
         End If
        End If
       End If
       '///text
       FakeDXUIDefaultFont.objFont.DrawTextW FakeDXUIDefaultFont.objSprite, ByVal (lp + .nLineStart(k) * 2&), .nLineLength(k), r, DT_VCENTER Or DT_SINGLELINE Or DT_NOCLIP, clr
       i = i + 1
       k = k + 1
      Loop
     End If
    End With
    i = ii
   Next j
  Else
   If nStartLine < 0 Then nStartLine = 0
   If nEndLine >= m_nLineCount Then nEndLine = m_nLineCount - 1
   For i = nStartLine To nEndLine
    r.Y1 = i * m_nLineHeight
    r.Y2 = r.Y1 + m_nLineHeight
    '///selection
    If bSelection Then
     If i >= tSelStart.nRow And i <= tSelEnd.nRow Then
      If i = tSelStart.nRow Then CalcCaretPos tSelStart.nRow, tSelStart.nPosition, jj _
      Else jj = 0
      If i = tSelEnd.nRow Then CalcCaretPos tSelEnd.nRow, tSelEnd.nPosition, jjj _
      Else jjj = m_tLineData(i).nLineWidth + 16
      jj = nLeft + (jj - m_nScrollValue(0)) * m_nFontZoom
      jjj = nLeft + (jjj - m_nScrollValue(0)) * m_nFontZoom
      kk = nTop + (r.Y1 - m_nScrollValue(1)) * m_nFontZoom
      FakeDXGDIFillRect jj, kk, jjj, kk + m_nLineHeight * m_nFontZoom, clr Or &H5987D6
     End If
    End If
    '///text
    FakeDXUIDefaultFont.objFont.DrawTextW FakeDXUIDefaultFont.objSprite, ByVal StrPtr(m_sLines(i)), -1, r, DT_VCENTER Or DT_SINGLELINE Or DT_NOCLIP, clr
   Next i
  End If
 Else
  If m_nLineCount > 0 Then
   r.Y2 = m_nHeight / m_nFontZoom
   '///selection
   If bSelection Then
    CalcCaretPos tSelStart.nRow, tSelStart.nPosition, jj
    CalcCaretPos tSelEnd.nRow, tSelEnd.nPosition, jjj
    '///
    jj = nLeft + (jj - m_nScrollValue(0)) * m_nFontZoom
    jjj = nLeft + (jjj - m_nScrollValue(0)) * m_nFontZoom
    kk = nTop + m_nHeight \ 2 - (m_nLineHeight \ 2) * m_nFontZoom
    FakeDXGDIFillRect jj, kk, jjj, kk + m_nLineHeight * m_nFontZoom, clr Or &H5987D6
   End If
   '///text
   FakeDXUIDefaultFont.objFont.DrawTextW FakeDXUIDefaultFont.objSprite, ByVal StrPtr(m_sLines(0)), -1, r, DT_VCENTER Or DT_SINGLELINE Or DT_NOCLIP, clr
  End If
 End If
End If
FakeDXUIDefaultFont.objSprite.End
'///caret
If bFocus Then
 i = (m_nCaretTimer + 1) And &H1F&
 m_nCaretTimer = i
 If i And &H10& Then
  i = i - 27
  If i < 0 Then i = 0
 Else
  i = 16 - i
  If i > 5 Then i = 5
 End If
 If i > 0 Then
  clr = (i * 51&) * nOpacity
  clr = ((clr And &H7F&) * &H1000000) Or ((clr > &H7F&) And &H80000000)
  '///
  CalcCaretPos , , j, jj, k
  '///draw
  j = nLeft + (j - m_nScrollValue(0)) * m_nFontZoom
  jj = nLeft + (jj - m_nScrollValue(0)) * m_nFontZoom
  k = nTop + (k - m_nScrollValue(1)) * m_nFontZoom
  FakeDXGDIFillRect j, k, jj, k + m_nLineHeight * m_nFontZoom, clr Or &HC409A '&H5987D6
 End If
Else
 m_nCaretTimer = 0
End If
'///
End Sub

Friend Sub CalcCaretPos(Optional ByVal nRow As Long = -1, Optional ByVal nPosition As Long = -1, Optional ByRef x As Long, Optional ByRef x2 As Long, Optional ByRef y As Long)
Dim t As GCP_RESULTS, h As Long
Dim nCaretPos() As Long
Dim nDistance() As Long
Dim iii As Long
Dim jjj As Long
Dim kk As Long, kkk As Long
Dim m As Long
Dim lp As Long
'///
If nRow < 0 Or nPosition < 0 Then
 nRow = m_tCaret.nRow
 nPosition = m_tCaret.nPosition
End If
'///
x = 0
If m_bInsertMode Then x2 = 16 Else x2 = 4
If m_bMultiLine Then y = 0 _
Else y = CLng(m_nHeight / m_nFontZoom / 2) - m_nLineHeight \ 2
'///
kk = 0
If nRow < 0 Or Not m_bMultiLine Then nRow = 0 _
Else If nRow >= m_nLineCount Then nRow = m_nLineCount - 1
m = Len(m_sLines(nRow))
If nPosition <= 0 Then nPosition = 0 Else If nPosition > m Then nPosition = m
If m_bMultiLine And m_bWrap Then
 If m > 0 Then
  '///search for sub-lines
  With m_tLineData(nRow)
   iii = 0
   kkk = .nLineHeight - 1
   Do
    kk = (iii + kkk) \ 2
    jjj = .nLineStart(kk)
    If nPosition < jjj Then
     kkk = kk - 1
    ElseIf nPosition >= jjj + .nLineLength(kk) Then
     iii = kk + 1
    Else
     Exit Do
    End If
    If iii > kkk Then
     kk = .nLineHeight - 1
     Exit Do
    End If
   Loop
   '///
   jjj = .nLineStart(kk)
   nPosition = nPosition - jjj
   lp = StrPtr(m_sLines(nRow)) + jjj * 2&
   m = .nLineLength(kk)
  End With
 End If
Else
 lp = StrPtr(m_sLines(nRow))
End If
'///
If m > 0 Then
 h = FakeDXUIDefaultFont.objFont.GetDC
 ReDim nCaretPos(m - 1)
 ReDim nDistance(m - 1)
 t.lStructSize = Len(t)
 t.lpDx = VarPtr(nDistance(0))
 t.lpCaretPos = VarPtr(nCaretPos(0))
 t.nGlyphs = m
 GetCharacterPlacementW h, ByVal lp, m, 0, t, 0
 If nPosition < m Then
  x = nCaretPos(nPosition)
  If m_bInsertMode Then x2 = x + nDistance(nPosition) Else x2 = x + 4
 Else
  x = nCaretPos(m - 1) + nDistance(m - 1)
  If m_bInsertMode Then x2 = x + 16 Else x2 = x + 4
 End If
 Erase nCaretPos
 Erase nDistance
End If
If m_bMultiLine Then y = (m_tLineData(nRow).nLineOffset + kk) * m_nLineHeight
End Sub

Friend Function ChangeCaretPosFromPoint(ByVal x As Long, ByVal y As Long, Optional ByVal bEnsureVisible As Boolean, Optional ByVal bSelection As Boolean) As Boolean
Dim t As GCP_RESULTS, h As Long
Dim nCaretPos() As Long
Dim nDistance() As Long
Dim nRow As Long
Dim nPosition As Long
Dim i As Long, ii As Long
Dim j As Long
Dim k As Long
Dim lp As Long, m As Long
'///
If y < 0 Then y = 0 Else _
If y >= m_nTextHeight Then y = m_nTextHeight - 1
'///
If m_nLineCount > 0 Then
 If m_bMultiLine Then
  y = y \ m_nLineHeight
  If m_bWrap Then
   '///binary search
   i = 0
   k = m_nLineCount - 1
   Do
    j = (i + k) \ 2
    ii = m_tLineData(j).nLineOffset
    If y < ii Then
     k = j - 1
    ElseIf y >= ii + m_tLineData(j).nLineHeight Then
     i = j + 1
    Else 'found
     y = y - ii
     nRow = j
     nPosition = m_tLineData(j).nLineStart(y)
     lp = StrPtr(m_sLines(nRow)) + nPosition * 2&
     m = m_tLineData(j).nLineLength(y)
     Exit Do
    End If
    If i > k Then Exit Do 'err!
   Loop
  Else
   If y >= 0 And y < m_nLineCount Then
    nRow = y
    lp = StrPtr(m_sLines(nRow))
    m = Len(m_sLines(nRow))
   End If
  End If
 Else
  lp = StrPtr(m_sLines(0))
  m = Len(m_sLines(0))
 End If
 '///
 If lp Then
  If m > 0 And x > 0 Then
   h = FakeDXUIDefaultFont.objFont.GetDC
   ReDim nCaretPos(m - 1)
   ReDim nDistance(m - 1)
   t.lStructSize = Len(t)
   t.lpDx = VarPtr(nDistance(0))
   t.lpCaretPos = VarPtr(nCaretPos(0))
   t.nGlyphs = m
   GetCharacterPlacementW h, ByVal lp, m, 0, t, 0
   '///binary search
   i = 0
   k = m - 1
   Do
    j = (i + k) \ 2
    ii = nCaretPos(j)
    If x < ii Then
     k = j - 1
    ElseIf x >= ii + nDistance(j) Then
     i = j + 1
    Else 'found
     nPosition = nPosition + j
     If x >= ii + nDistance(j) \ 2 Then nPosition = nPosition + 1
     Exit Do
    End If
    If i > k Then 'err!
     nPosition = nPosition + m
     Exit Do
    End If
   Loop
   '///
   Erase nCaretPos
   Erase nDistance
  End If
' ElseIf bValidPosOnly Then
'  Exit Function
 ElseIf y > 0 Then
  nRow = m_nLineCount - 1
  nPosition = Len(m_sLines(nRow))
 End If
End If
'///
ChangeCaretPosFromPoint = ChangeCaretPos(nRow, nPosition, bEnsureVisible, bSelection)
End Function

Friend Function ChangeCaretPosFromPointDelta(Optional ByVal nDeltaX As Long, Optional ByVal nDeltaY As Long, Optional ByVal bEnsureVisible As Boolean, Optional ByVal bSelection As Boolean) As Boolean
Dim x As Long, y As Long
CalcCaretPos , , x, , y
ChangeCaretPosFromPointDelta = ChangeCaretPosFromPoint(x + nDeltaX, y + nDeltaY + m_nLineHeight \ 2, bEnsureVisible, bSelection)
End Function

Friend Function ChangeCaretPosByDelta(Optional ByVal nDelta As Long, Optional ByVal bEnsureVisible As Boolean, Optional ByVal bSelection As Boolean) As Boolean
Dim nRow As Long
Dim nPosition As Long
Dim m As Long
nRow = m_tCaret.nRow
nPosition = m_tCaret.nPosition + nDelta
If nDelta > 0 Then
 Do While nRow >= 0 And nRow < m_nLineCount
  m = Len(m_sLines(nRow))
  If nPosition <= m Then Exit Do
  nPosition = nPosition - m - 1
  nRow = nRow + 1
 Loop
ElseIf nDelta < 0 Then
 Do While nPosition < 0 And nRow < m_nLineCount
  nRow = nRow - 1
  If nRow < 0 Then Exit Do
  nPosition = nPosition + Len(m_sLines(nRow)) + 1
 Loop
End If
If nRow < 0 Or m_nLineCount <= 0 Then
 nRow = 0
 nPosition = 0
ElseIf nRow >= m_nLineCount Then
 nRow = m_nLineCount - 1
 nPosition = Len(m_sLines(nRow))
End If
ChangeCaretPosByDelta = ChangeCaretPos(nRow, nPosition, bEnsureVisible, bSelection)
End Function

Friend Function ChangeCaretPos(Optional ByVal nRow As Long = -1, Optional ByVal nPosition As Long = -1, Optional ByVal bEnsureVisible As Boolean, Optional ByVal bSelection As Boolean) As Boolean
Dim i As Long, j As Long, k As Long
If nRow >= 0 And nRow < m_nLineCount And nPosition >= 0 Then
 If nPosition <= Len(m_sLines(nRow)) Then
  If m_tCaret.nRow <> nRow Or m_tCaret.nPosition <> nPosition Then
   m_tCaret.nRow = nRow
   m_tCaret.nPosition = nPosition
   m_nCaretTimer = 0 '???
   ChangeCaretPos = True
  End If
 End If
End If
'///selection (??)
If m_tSelStart.nRow < 0 Or Not bSelection Then m_tSelStart = m_tCaret
'///
If bEnsureVisible Then
 CalcCaretPos , , j, , k
 '///horizontal
 If Not (m_bMultiLine And m_bWrap) Then
  i = m_nWidth / m_nFontZoom
  If j < m_nScrollValue(0) Or j >= m_nScrollValue(0) + i Then
   j = j - i \ 2
   If j < 0 Then j = 0
   m_nScrollValue(0) = j
   m_bScrollChanged = True
  End If
 End If
 '///vertical
 If m_bMultiLine Then
  i = m_nHeight / m_nFontZoom - m_nLineHeight
  If k < m_nScrollValue(1) Then
   If k < 0 Then k = 0
   m_nScrollValue(1) = k
   m_bScrollChanged = True
  ElseIf k > m_nScrollValue(1) + i Then
   k = k - i
   If k < 0 Then k = 0
   m_nScrollValue(1) = k
   m_bScrollChanged = True
  End If
 End If
End If
End Function

Private Sub Class_Initialize()
m_tSelStart.nRow = -1
End Sub
