VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsFakeDXUI_IME"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Const m_nFontZoom As Single = 0.5

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)
Private Declare Function lstrlen Lib "kernel32.dll" Alias "lstrlenA" (ByRef lpString As Any) As Long

Private Declare Function ImmGetContext Lib "imm32.dll" (ByVal hWnd As Long) As Long
Private Declare Function ImmReleaseContext Lib "imm32.dll" (ByVal hWnd As Long, ByVal himc As Long) As Long

Private Declare Function ImmGetCandidateList Lib "imm32.dll" Alias "ImmGetCandidateListA" (ByVal himc As Long, ByVal dwIndex As Long, ByRef lpCandidateList As Any, ByVal dwBufLen As Long) As Long
Private Declare Function ImmGetCandidateListCount Lib "imm32.dll" Alias "ImmGetCandidateListCountA" (ByVal himc As Long, ByRef lpdwListCount As Long) As Long
Private Declare Function ImmGetCandidateWindow Lib "imm32.dll" (ByVal himc As Long, ByVal dw As Long, ByRef lpCandidateForm As CANDIDATEFORM) As Long

Private Declare Function ImmGetCompositionString Lib "imm32.dll" Alias "ImmGetCompositionStringA" (ByVal himc As Long, ByVal dw As Long, ByRef lpv As Any, ByVal dw2 As Long) As Long
Private Declare Function ImmGetCompositionStringW Lib "imm32.dll" (ByVal himc As Long, ByVal dw As Long, ByRef lpv As Any, ByVal dw2 As Long) As Long
Private Const GCS_COMPSTR As Long = &H8
Private Const GCS_RESULTSTR As Long = &H800
Private Const GCS_COMPREADSTR As Long = &H1
Private Const GCS_RESULTREADSTR As Long = &H200
Private Const GCS_CURSORPOS As Long = &H80
Private Const GCS_DELTASTART As Long = &H100

Private Declare Function GetKeyboardLayout Lib "user32.dll" (ByVal dwLayout As Long) As Long
Private Declare Function GetKeyboardLayoutList Lib "user32.dll" (ByVal nBuff As Long, ByRef lpList As Any) As Long
Private Declare Function ActivateKeyboardLayout Lib "user32.dll" (ByVal HKL As Long, ByVal Flags As Long) As Long
Private Declare Function ImmIsIME Lib "imm32.dll" (ByVal HKL As Long) As Long
Private Declare Function ImmGetDescriptionW Lib "imm32.dll" (ByVal HKL As Long, ByRef lpsz As Any, ByVal uBufLen As Long) As Long
Private Declare Function ImmEscapeW Lib "imm32.dll" (ByVal HKL As Long, ByVal himc As Long, ByVal un As Long, ByRef lpv As Any) As Long
Private Const IME_ESC_IME_NAME As Long = &H1006

Private Declare Function ImmGetDefaultIMEWnd Lib "imm32.dll" (ByVal hWnd As Long) As Long
Private Declare Function SendMessage Lib "user32.dll" Alias "SendMessageA" (ByVal hWnd As Long, ByVal wMsg As Long, ByVal wParam As Long, ByRef lParam As Any) As Long
Private Const WM_IME_CONTROL As Long = &H283
Private Const IMC_CLOSESTATUSWINDOW As Long = &H21

Private Declare Function ImmGetConversionStatus Lib "imm32.dll" (ByVal himc As Long, ByRef lpdw As Long, ByRef lpdw2 As Long) As Long
Private Declare Function ImmSetConversionStatus Lib "imm32.dll" (ByVal himc As Long, ByVal dw1 As Long, ByVal dw2 As Long) As Long
Private Const IME_CMODE_FULLSHAPE As Long = &H8
Private Const IME_CMODE_SYMBOL As Long = &H400
Private Declare Function ImmSetOpenStatus Lib "imm32.dll" (ByVal himc As Long, ByVal b As Long) As Long

Private Declare Function GetTextExtentPoint32W Lib "Gdi32.dll" ( _
  ByVal hdc As Long, _
  ByRef lpString As Any, _
  ByVal c As Long, _
  ByRef lpSize As Any) As Long

Private Type POINTAPI
    x As Long
    y As Long
End Type

Private Type RECT
    Left As Long
    Top As Long
    Right As Long
    Bottom As Long
End Type

Private Type COMPOSITIONFORM
    dwStyle As Long
    ptCurrentPos As POINTAPI
    rcArea As RECT
End Type

Private Type CANDIDATEFORM
    dwIndex As Long
    dwStyle As Long
    ptCurrentPos As POINTAPI
    rcArea As RECT
End Type

Private Type CANDIDATELIST
  dwSize As Long
  dwStyle As Long
  dwCount As Long
  dwSelection As Long
  dwPageStart As Long
  dwPageSize As Long
  'dwOffset(8191) As Long
End Type

Private Type CANDIDATEINFO
 dwSize As Long
 dwCount As Long
 dwOffset(31) As Long
 dwPrivateSize As Long
 dwPrivateOffset As Long
End Type

Private Const IMN_OPENCANDIDATE As Long = &H5
Private Const IMN_CHANGECANDIDATE As Long = &H3
Private Const IMN_CLOSECANDIDATE As Long = &H4

Private Const IME_CHOTKEY_SHAPE_TOGGLE As Long = &H11
Private Const IME_CHOTKEY_SYMBOL_TOGGLE As Long = &H12
Private Const IME_THOTKEY_SHAPE_TOGGLE As Long = &H71
Private Const IME_THOTKEY_SYMBOL_TOGGLE As Long = &H72

Private m_hWnd As Long
Private m_bHasImm32 As Boolean

Private m_bIsIME As Boolean, m_sIMEName As String
Private m_sCandidateString As String
Private m_sCompositionString As String, m_nCompositionCaretPos As Long

Private m_nAnimVal(31) As Integer
'0=xx
'1-3=xx
'4-6=xx
'8=ime? (0-255)
'9=fullshape? (0-255)
'10=symbol? (0-255)
'11-13=xx
'16=CompositionString? (0-255)
'17=caret timer

Friend Property Get CandidateString() As String
CandidateString = m_sCandidateString
End Property

Friend Property Get CompositionString() As String
CompositionString = m_sCompositionString
End Property

Friend Property Get IMEName() As String
IMEName = m_sIMEName
End Property

Friend Property Get IsIME() As Boolean
IsIME = m_bIsIME
End Property

'ABC-OK ,M$PY-doesn't work
Friend Sub OnIMENotify(ByVal wParam As Long, ByVal lParam As Long)
Dim h As Long
Dim i As Long, j As Long, m As Long
Dim nBuffer() As Long
Dim s As String, s1 As String
Dim lp As Long
'///
If Not m_bHasImm32 Then Exit Sub
Select Case wParam
Case IMN_OPENCANDIDATE, IMN_CHANGECANDIDATE
 '///
 'CloseStatusWindow
 '///
 h = ImmGetContext(m_hWnd)
 If h = 0 Then
  m_sCandidateString = ""
  m_sCompositionString = ""
  Exit Sub
 End If
 ReDim nBuffer(65535)
 i = ImmGetCandidateList(h, 0, ByVal 0, 0)
 If i > 0 Then
  ImmGetCandidateList h, 0, nBuffer(0), 262144
  m = nBuffer(3) + nBuffer(5)
  If m > nBuffer(2) Then m = nBuffer(2)
  For i = nBuffer(3) To m - 1
   lp = VarPtr(nBuffer(0)) + nBuffer(6 + i)
   m = lstrlen(ByVal lp)
   If m > 0 Then
    s = LeftB(Space(m \ 2 + 1), m)
    CopyMemory ByVal StrPtr(s), ByVal lp, m
    s = StrConv(s, vbUnicode)
   Else
    s = ""
   End If
   j = j + 1
   s1 = s1 + CStr(j) + "." + s + " "
  Next i
 End If
 m_sCandidateString = s1
 '///
 ImmReleaseContext m_hWnd, h
Case IMN_CLOSECANDIDATE
 m_sCandidateString = ""
End Select
End Sub

Friend Sub CloseStatusWindow()
Dim h As Long
h = ImmGetDefaultIMEWnd(m_hWnd)
If h Then SendMessage h, WM_IME_CONTROL, IMC_CLOSESTATUSWINDOW, ByVal 0
End Sub

Friend Sub OnIMEComposition(ByVal wParam As Long, ByVal lParam As Long)
Dim h As Long, i As Long, m As Long
Dim s As String
If Not m_bHasImm32 Then Exit Sub
'///
'CloseStatusWindow
'///
h = ImmGetContext(m_hWnd)
If h Then
 '///
 s = Space(1024)
 m = ImmGetCompositionStringW(h, GCS_COMPSTR, ByVal StrPtr(s), 1024)
 If m Then
  s = Left(s, m)
  i = ImmGetCompositionStringW(h, GCS_CURSORPOS, ByVal 0, 0)
 Else
  s = ""
  i = -1
 End If
 '///
 m_sCompositionString = s
 If m_nCompositionCaretPos <> i Then
  m_nCompositionCaretPos = i
  m_nAnimVal(17) = 0
 End If
 '///
 ImmReleaseContext m_hWnd, h
End If
End Sub

Friend Sub OnInputLanguageChange()
On Error GoTo a
Dim h As Long, h2 As Long
Dim i As Long
Dim s As String
s = String(1024, vbNullChar)
h = GetKeyboardLayout(0)
m_bIsIME = ImmIsIME(h)
If m_bIsIME Then
 h2 = ImmGetContext(m_hWnd)
 If h2 Then
  If ImmEscapeW(h, h2, IME_ESC_IME_NAME, ByVal StrPtr(s)) Then
   i = InStr(1, s, vbNullChar) - 1
   If i > 0 Then s = Left(s, i) Else i = 0
  End If
  ImmReleaseContext m_hWnd, h2
 End If
 If i = 0 Then
  ImmGetDescriptionW h, ByVal StrPtr(s), 1024
  s = Left(s, InStr(1, s, vbNullChar) - 1)
 End If
 m_sIMEName = s
End If
'///
m_bHasImm32 = True
Exit Sub
a:
m_bHasImm32 = False
End Sub

Friend Sub Create(ByVal hWnd As Long)
m_hWnd = hWnd
OnInputLanguageChange
End Sub

Friend Sub Render(Optional ByVal nOpacity As Single = 1)
Dim h As Long
Dim i As Long, ii As Long, j As Long, jj As Long, k As Long
Dim m As Long
Dim p(1) As Long
'///
If Not m_bHasImm32 Then Exit Sub
'///
i = m_nAnimVal(8)
k = m_bIsIME And &HFF&
If i < k Then i = i + 51 Else _
If i > k Then i = i - 51
m_nAnimVal(8) = i
If i <= 0 Then Exit Sub
i = i * nOpacity
i = ((i And &H7F&) * &H1000000) Or ((i > &H7F&) And &H80000000)
'///back
FakeDXGDIStretchBltColored 0, d3dpp.BackBufferHeight - 28, d3dpp.BackBufferWidth, d3dpp.BackBufferHeight, 32, 176, 64, 204, 512, i Or &HFFFFFF
'///button
h = ImmGetContext(m_hWnd)
If h Then
 ImmGetConversionStatus h, ii, 0
 ImmReleaseContext m_hWnd, h
Else
 ii = 0
End If
j = m_nAnimVal(9)
k = ((ii And IME_CMODE_FULLSHAPE) <> 0) And &HFF&
If j < k Then j = j + 51 Else _
If j > k Then j = j - 51
m_nAnimVal(9) = j
jj = m_nAnimVal(10)
k = ((ii And IME_CMODE_SYMBOL) <> 0) And &HFF&
If jj < k Then jj = jj + 51 Else _
If jj > k Then jj = jj - 51
m_nAnimVal(10) = jj
pRenderButtonHighlight_1 1, 11, 4, d3dpp.BackBufferWidth - 50, d3dpp.BackBufferHeight - 18, nOpacity
pRenderButtonHighlight_1 2, 12, 5, d3dpp.BackBufferWidth - 34, d3dpp.BackBufferHeight - 18, nOpacity
pRenderButtonHighlight_1 3, 13, 6, d3dpp.BackBufferWidth - 18, d3dpp.BackBufferHeight - 18, nOpacity
FakeDXGDIStretchBltBlended d3dpp.BackBufferWidth - 50, d3dpp.BackBufferHeight - 18, d3dpp.BackBufferWidth - 34, d3dpp.BackBufferHeight - 2, 192, 368, 208, 384, 512, 208, 368, j, i Or &HFFFFFF
FakeDXGDIStretchBltBlended d3dpp.BackBufferWidth - 34, d3dpp.BackBufferHeight - 18, d3dpp.BackBufferWidth - 18, d3dpp.BackBufferHeight - 2, 192, 384, 208, 400, 512, 208, 384, jj, i Or &HFFFFFF
FakeDXGDIStretchBltColored d3dpp.BackBufferWidth - 18, d3dpp.BackBufferHeight - 18, d3dpp.BackBufferWidth - 2, d3dpp.BackBufferHeight - 2, 272, 0, 288, 16, 512, i Or &HFFFFFF
'///IME name
FakeDXGDIDrawText FakeDXUIDefaultFont, m_sIMEName, 0, d3dpp.BackBufferHeight - 18, d3dpp.BackBufferWidth - 56, 18, m_nFontZoom, DT_RIGHT, i, , , , , , , True
'///candidate
FakeDXGDIDrawText FakeDXUIDefaultFont, m_sCandidateString, 0, d3dpp.BackBufferHeight - 18, d3dpp.BackBufferWidth - 56, 18, m_nFontZoom, , i, , , , , , , True
'///composition string
m = Len(m_sCompositionString)
i = m_nAnimVal(16)
k = (m > 0) And &HFF&
If i < k Then i = i + 51 Else _
If i > k Then i = i - 51
m_nAnimVal(16) = i
If i <= 0 Then Exit Sub
j = i * nOpacity * 0.75
j = ((j And &H7F&) * &H1000000) Or ((j > &H7F&) And &H80000000)
FakeDXGDIStretchBltExColored -4, d3dpp.BackBufferHeight - 44, d3dpp.BackBufferWidth + 4, d3dpp.BackBufferHeight - 16, 124, 324, 164, 364, 8, 8, 8, 8, 512, j Or &HFFFFFF
j = i * nOpacity
j = ((j And &H7F&) * &H1000000) Or ((j > &H7F&) And &H80000000)
If m > 0 Then
 FakeDXGDIDrawText FakeDXUIDefaultFont, m_sCompositionString, 4, d3dpp.BackBufferHeight - 38, d3dpp.BackBufferWidth - 8, 18, m_nFontZoom, , j, , , , , , , True
End If
'///caret
If m_nCompositionCaretPos >= 0 Then
 k = (m_nAnimVal(17) + 1) And &H1F&
 m_nAnimVal(17) = k
 If k And &H10& Then
  k = k - 27
  If k < 0 Then k = 0
 Else
  k = 16 - k
  If k > 5 Then k = 5
 End If
 If k > 0 Then
  j = i * nOpacity * k / 5
  j = ((j And &H7F&) * &H1000000) Or ((j > &H7F&) And &H80000000)
  '///
  If m_nCompositionCaretPos > 0 Then
   i = m_nCompositionCaretPos
   If i > m Then i = m
   GetTextExtentPoint32W FakeDXUIDefaultFont.objFont.GetDC, ByVal StrPtr(m_sCompositionString), i, p(0)
  Else
   p(0) = 0
  End If
  '///draw
  p(0) = 4 + p(0) * m_nFontZoom
  FakeDXGDIFillRect p(0), d3dpp.BackBufferHeight - 38, p(0) + 2, d3dpp.BackBufferHeight - 22, j Or &HC409A
 End If
End If
End Sub

Friend Sub Destroy()
m_hWnd = 0
m_bIsIME = False
m_sIMEName = ""
m_bHasImm32 = False
Erase m_nAnimVal
End Sub

Friend Sub BeforeMouseEvent()
m_nAnimVal(4) = 0 'fullshape
m_nAnimVal(5) = 0 'symbol
m_nAnimVal(6) = 0 'close
End Sub

Private Function pButtonHighlight_1(ByVal nIndex As Long, ByVal Button As Long, ByVal nEventType As Long, Optional ByRef bPressed As Boolean) As Long
Dim i As Long
i = 1
bPressed = False
If Button And 1& Then
 If nEventType = 1 Then
  m_nAnimVal(0) = nIndex
  i = 2
 ElseIf nEventType = 2 Then
  bPressed = m_nAnimVal(0) = nIndex
 ElseIf nEventType = 0 Then
  If m_nAnimVal(0) = nIndex Then i = 2 Else i = 0
 End If
End If
pButtonHighlight_1 = i
End Function

Private Sub pRenderButtonHighlight_1(ByVal nIndex1 As Long, ByVal nIndex1_Pressed As Long, ByVal nIndex2 As Long, ByVal nLeft As Single, ByVal nTop As Single, Optional ByVal nOpacity As Single = 1)
Dim j As Long, jj As Long, k As Long, kk As Long
kk = m_nAnimVal(nIndex2)
j = m_nAnimVal(nIndex1)
k = (kk > 0) And 255&
If j < k Then j = j + 51 Else _
If j > k Then j = j - 51
m_nAnimVal(nIndex1) = j
jj = m_nAnimVal(nIndex1_Pressed)
k = (kk > 1) And 255&
If jj < k Then jj = jj + 51 Else _
If jj > k Then jj = jj - 51
m_nAnimVal(nIndex1_Pressed) = jj
If j > 0 Then
 j = j * nOpacity
 j = ((j And &H7F&) * &H1000000) Or ((j > &H7F&) And &H80000000) Or &HFFFFFF
 FakeDXGDIStretchBltBlended nLeft, nTop, nLeft + 16, nTop + 16, 256, 24, 272, 40, 512, 232, 24, jj, j
End If
End Sub

Friend Sub CloseIME()
Dim h() As Long, m As Long, i As Long
ReDim h(1023)
m = GetKeyboardLayoutList(1024, h(0))
For i = 0 To m - 1
 If ImmIsIME(h(i)) = 0 Then
  ActivateKeyboardLayout h(i), 0
  Exit Sub
 End If
Next i
End Sub

Friend Function OnMouseEvent(ByVal Button As Long, ByVal Shift As Long, ByVal x As Single, ByVal y As Single, ByVal nEventType As Long) As Boolean
Dim b As Boolean
Dim h As Long, i As Long, j As Long
'///
If Not (m_bHasImm32 And m_bIsIME) Then Exit Function
'///
If nEventType = 1 Then m_nAnimVal(0) = 0
If y >= d3dpp.BackBufferHeight - 18 And y < d3dpp.BackBufferHeight - 2 Then
 If x >= d3dpp.BackBufferWidth - 2 Then
 ElseIf x >= d3dpp.BackBufferWidth - 18 Then 'close
  m_nAnimVal(6) = pButtonHighlight_1(3, Button, nEventType, b)
  If b Then CloseIME
 ElseIf x >= d3dpp.BackBufferWidth - 34 Then 'symbol
  m_nAnimVal(5) = pButtonHighlight_1(2, Button, nEventType, b)
  If b Then
   h = ImmGetContext(m_hWnd)
   If h Then
    ImmGetConversionStatus h, i, j
    i = i Xor IME_CMODE_SYMBOL
    ImmSetConversionStatus h, i, j
    ImmReleaseContext m_hWnd, h
   End If
  End If
 ElseIf x >= d3dpp.BackBufferWidth - 50 Then 'fullshape
  m_nAnimVal(4) = pButtonHighlight_1(1, Button, nEventType, b)
  If b Then
   h = ImmGetContext(m_hWnd)
   If h Then
    ImmGetConversionStatus h, i, j
    i = i Xor IME_CMODE_FULLSHAPE
    ImmSetConversionStatus h, i, j
    ImmReleaseContext m_hWnd, h
   End If
  End If
 End If
End If
b = m_nAnimVal(0)
If nEventType = 2 Then m_nAnimVal(0) = 0
'///
'TODO:
'///
OnMouseEvent = b
End Function

Private Sub Class_Terminate()
Destroy
End Sub
