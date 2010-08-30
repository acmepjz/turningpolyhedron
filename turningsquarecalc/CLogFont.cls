VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "CLogFont"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

' Logical Font
Private Const LF_FACESIZE = 32
Private Const LF_FULLFACESIZE = 64

Private Const CLIP_DEFAULT_PRECIS = 0
Private Const CLIP_CHARACTER_PRECIS = 1
Private Const CLIP_STROKE_PRECIS = 2
Private Const CLIP_MASK = &HF
Private Const CLIP_LH_ANGLES = 16
Private Const CLIP_TT_ALWAYS = 32
Private Const CLIP_EMBEDDED = 128

Private Const DEFAULT_QUALITY = 0
Private Const DRAFT_QUALITY = 1
Private Const PROOF_QUALITY = 2
Private Const NONANTIALIASED_QUALITY = 3 ' Don't smooth font edges even if system is set to smooth font edges
Private Const ANTIALIASED_QUALITY = 4 ' Ensure font edges are smoothed if system is set to smooth font edges
Private Const CLEARTYPE_QUALITY = 5

Private Const DEFAULT_PITCH = 0
Private Const FIXED_PITCH = 1
Private Const VARIABLE_PITCH = 2

Private Const ANSI_CHARSET = 0
Private Const DEFAULT_CHARSET = 1
Private Const SYMBOL_CHARSET = 2
Private Const SHIFTJIS_CHARSET = 128
Private Const HANGEUL_CHARSET = 129
Private Const CHINESEBIG5_CHARSET = 136
Private Const OEM_CHARSET = 255

' Font Families
'
Private Const FF_DONTCARE = 0    '  Don't care or don't know.
Private Const FF_ROMAN = 16      '  Variable stroke width, serifed.

' Times Roman, Century Schoolbook, etc.
Private Const FF_SWISS = 32      '  Variable stroke width, sans-serifed.

' Helvetica, Swiss, etc.
Private Const FF_MODERN = 48     '  Constant stroke width, serifed or sans-serifed.

' Pica, Elite, Courier, etc.
Private Const FF_SCRIPT = 64     '  Cursive, etc.
Private Const FF_DECORATIVE = 80 '  Old English, etc.

' Font Weights
Private Const FW_DONTCARE = 0
Private Const FW_THIN = 100
Private Const FW_EXTRALIGHT = 200
Private Const FW_LIGHT = 300
Private Const FW_NORMAL = 400
Private Const FW_MEDIUM = 500
Private Const FW_SEMIBOLD = 600
Private Const FW_BOLD = 700
Private Const FW_EXTRABOLD = 800
Private Const FW_HEAVY = 900

Private Const FW_ULTRALIGHT = FW_EXTRALIGHT
Private Const FW_REGULAR = FW_NORMAL
Private Const FW_DEMIBOLD = FW_SEMIBOLD
Private Const FW_ULTRABOLD = FW_EXTRABOLD
Private Const FW_BLACK = FW_HEAVY

Private Const OUT_DEFAULT_PRECIS = 0
Private Const OUT_STRING_PRECIS = 1
Private Const OUT_CHARACTER_PRECIS = 2
Private Const OUT_STROKE_PRECIS = 3
Private Const OUT_TT_PRECIS = 4
Private Const OUT_DEVICE_PRECIS = 5
Private Const OUT_RASTER_PRECIS = 6
Private Const OUT_TT_ONLY_PRECIS = 7
Private Const OUT_OUTLINE_PRECIS = 8

Private Type LogFont
   lfHeight As Long
   lfWidth As Long
   lfEscapement As Long
   lfOrientation As Long
   lfWeight As Long
   lfItalic As Byte
   lfUnderline As Byte
   lfStrikeOut As Byte
   lfCharSet As Byte
   lfOutPrecision As Byte
   lfClipPrecision As Byte
   lfQuality As Byte
   lfPitchAndFamily As Byte
   lfFaceName As String * LF_FACESIZE
End Type

Private Declare Function GetVersion Lib "kernel32.dll" () As Long

Private Declare Function CreateFontIndirect Lib "gdi32" Alias "CreateFontIndirectA" (lpLogFont As LogFont) As Long
Private Declare Function DeleteObject Lib "gdi32" (ByVal hObject As Long) As Long
Private Declare Function GetDeviceCaps Lib "gdi32" (ByVal hDC As Long, ByVal nIndex As Long) As Long

Private Const LOGPIXELSY = 90        '  Logical pixels/inch in Y

Private Declare Function GetDesktopWindow Lib "user32" () As Long
Private Declare Function GetDC Lib "user32" (ByVal hwnd As Long) As Long
Private Declare Function ReleaseDC Lib "user32" (ByVal hwnd As Long, ByVal hDC As Long) As Long

Private Declare Function SetBkMode Lib "gdi32.dll" (ByVal hDC As Long, ByVal nBkMode As Long) As Long
Private Declare Function SetBkColor Lib "gdi32.dll" (ByVal hDC As Long, ByVal crColor As Long) As Long
Private Declare Function SetTextColor Lib "gdi32.dll" (ByVal hDC As Long, ByVal crColor As Long) As Long
Private Declare Function DrawText Lib "user32.dll" Alias "DrawTextA" (ByVal hDC As Long, ByVal lpStr As String, ByVal nCount As Long, ByRef lpRect As RECT, ByVal wFormat As Long) As Long
Private Declare Function DrawTextW Lib "user32.dll" (ByVal hDC As Long, ByRef lpStr As Any, ByVal nCount As Long, ByRef lpRect As RECT, ByVal wFormat As Long) As Long
Private Declare Function TextOut Lib "gdi32.dll" Alias "TextOutA" (ByVal hDC As Long, ByVal x As Long, ByVal y As Long, ByVal lpString As String, ByVal nCount As Long) As Long
Private Declare Function TextOutW Lib "gdi32.dll" (ByVal hDC As Long, ByVal x As Long, ByVal y As Long, ByRef lpString As Any, ByVal nCount As Long) As Long
Private Declare Function SelectObject Lib "gdi32.dll" (ByVal hDC As Long, ByVal hObject As Long) As Long

Private Declare Function DrawTextEx Lib "user32.dll" Alias "DrawTextExA" (ByVal hDC As Long, ByVal lpStr As String, ByVal nCount As Long, ByRef lpRect As RECT, ByVal wFormat As Long, ByRef lpDrawTextParams As DRAWTEXTPARAMS) As Long
Private Declare Function DrawTextExW Lib "user32.dll" (ByVal hDC As Long, ByRef lpStr As Any, ByVal nCount As Long, ByRef lpRect As RECT, ByVal wFormat As Long, ByRef lpDrawTextParams As DRAWTEXTPARAMS) As Long

Private Type DRAWTEXTPARAMS
  cbSize As Long
  iTabLength As Long
  iLeftMargin As Long
  iRightMargin As Long
  uiLengthDrawn As Long
End Type

'??
Private Declare Function LenA Lib "kernel32.dll" Alias "lstrlenA" (ByVal lpString As String) As Long

Private Type RECT
    Left As Long
    Top As Long
    Right As Long
    Bottom As Long
End Type

Public Enum DrawTextConstants
 DT_BOTTOM = &H8
 DT_CALCRECT = &H400
 DT_CENTER = &H1
 DT_EXPANDTABS = &H40
 DT_EXTERNALLEADING = &H200
 DT_INTERNAL = &H1000
 DT_LEFT = &H0
 DT_NOCLIP = &H100
 DT_NOPREFIX = &H800
 DT_RIGHT = &H2
 DT_SINGLELINE = &H20
 DT_TABSTOP = &H80
 DT_TOP = &H0
 DT_VCENTER = &H4
 DT_WORDBREAK = &H10
 'new
 DT_EDITCONTROL = &H2000&
 DT_END_ELLIPSIS = &H8000&
 DT_MODIFYSTRING = &H10000
 DT_PATH_ELLIPSIS = &H4000&
 DT_RTLREADING = &H20000
 DT_WORD_ELLIPSIS = &H40000
End Enum

Private Const TRANSPARENT = 1
Private Const OPAQUE = 2

Private m_Font As StdFont
Private m_hFont As Long
Private m_Rotation As Single

Private IsXP As Boolean, IsNT As Boolean

Private hq As Boolean

Private Sub pGetWindowsVersion()
Dim lR As Long
Dim lMajor As Long
Dim lMinor As Long
   lR = GetVersion
   lMinor = (lR And &HFF00&) \ &H100
   lMajor = (lR And &HFF)
   If (lMajor > 5) Then
      IsXP = True
      'IsVista = True ':-/
   ElseIf (lMajor = 5) And (lMinor >= 1) Then
      IsXP = True
   End If
   IsNT = ((lR And &H80000000) = 0)
   'Is2000OrAbove = IsNT And lMajor >= 5
   '?????
End Sub

Private Sub Class_Initialize()
pGetWindowsVersion
End Sub

Private Sub Class_Terminate()
   '
   ' Clean-up created objects!!!
   '
   If m_hFont Then
      Call DeleteObject(m_hFont)
      Set m_Font = Nothing
   End If
End Sub

Public Property Get HighQuality() As Boolean
HighQuality = hq
End Property

Public Property Let HighQuality(ByVal b As Boolean)
hq = b
End Property

Public Property Set LogFont(ByVal NewFont As StdFont)
   If m_hFont Then
      Call DeleteObject(m_hFont)
      m_hFont = 0
   End If
   
   If NewFont Is Nothing Then
      Set m_Font = Nothing
   Else
      '
      ' Stash a copy of the passed object,
      ' to avoid a new reference to it.
      '
      Set m_Font = New StdFont
      With m_Font
         .Bold = NewFont.Bold
         .Charset = NewFont.Charset
         .Italic = NewFont.Italic
         .Name = NewFont.Name
         .Size = NewFont.Size
         .Strikethrough = NewFont.Strikethrough
         .Underline = NewFont.Underline
         .Weight = NewFont.Weight
      End With
      m_hFont = CreateLogFont(hq)
   End If
End Property

Public Property Get LogFont() As StdFont
   Set LogFont = m_Font
End Property

Public Property Let Rotation(ByVal NewVal As Single)
   If NewVal <> m_Rotation Then
      m_Rotation = NewVal
      If m_hFont Then
         Call DeleteObject(m_hFont)
         m_hFont = 0
      End If
      If Not (m_Font Is Nothing) Then
         m_hFont = CreateLogFont(True)
      End If
   End If
End Property

Public Property Get Rotation() As Single
   Rotation = m_Rotation
End Property

Public Property Get Handle() As Long
   Handle = m_hFont
End Property

Private Function CreateLogFont(ByVal HighQuality As Boolean) As Long
   Dim lF As LogFont
   Dim hwnd As Long
   Dim hDC As Long
   
   hwnd = GetDesktopWindow
   hDC = GetDC(hwnd)
   
   With lF
      '
      ' All but two properties are very straight-forward,
      ' even with rotation, and map directly.
      '
      .lfHeight = -(m_Font.Size * GetDeviceCaps(hDC, LOGPIXELSY)) / 72
      .lfWidth = 0
      .lfEscapement = m_Rotation * 10
      .lfOrientation = .lfEscapement
      .lfWeight = m_Font.Weight
      .lfItalic = m_Font.Italic
      .lfUnderline = m_Font.Underline
      .lfStrikeOut = m_Font.Strikethrough
      .lfClipPrecision = CLIP_DEFAULT_PRECIS
      If HighQuality Then
         If (IsXP) Then
            .lfQuality = CLEARTYPE_QUALITY
         Else
            .lfQuality = ANTIALIASED_QUALITY
         End If
      Else
         .lfQuality = PROOF_QUALITY
      End If
      .lfPitchAndFamily = DEFAULT_PITCH Or FF_DONTCARE
      .lfFaceName = m_Font.Name & vbNullChar
      '
      ' OEM fonts can't rotate, and we must force
      ' substitution with something ANSI.
      '
      .lfCharSet = m_Font.Charset
      If .lfCharSet = OEM_CHARSET Then
         If (m_Rotation Mod 360) <> 0 Then
            .lfCharSet = ANSI_CHARSET
         End If
      End If
      '
      ' Only TrueType fonts can rotate, so we must
      ' specify TT-only if angle is not zero.
      '
      If (m_Rotation Mod 360) <> 0 Then
         .lfOutPrecision = OUT_TT_ONLY_PRECIS
      Else
         .lfOutPrecision = OUT_DEFAULT_PRECIS
      End If
      '///new:fix the bug in wine (don't need)
      '.lfCharSet = DEFAULT_CHARSET
      '///
   End With
   
   CreateLogFont = CreateFontIndirect(lF)
   Call ReleaseDC(hwnd, hDC)
End Function

Public Function DrawTextXP(ByVal hDC As Long, ByVal s As String, ByVal Left As Long, ByVal Top As Long, Optional Width As Long, Optional Height As Long, Optional ByVal Style As DrawTextConstants, Optional ByVal ForeColor As Long, Optional ByVal BackColor As Long, Optional ByVal IsTrans As Boolean) As Long
On Error Resume Next
Dim r As RECT, h As Long
If (Style And DT_CALCRECT) = 0 Then
 If IsTrans Then
  SetBkMode hDC, TRANSPARENT
 Else
  SetBkMode hDC, OPAQUE '?
  SetBkColor hDC, BackColor
 End If
 SetTextColor hDC, ForeColor
 r.Left = Left
 r.Top = Top
 r.Right = Width + Left
 r.Bottom = Height + Top
End If
h = SelectObject(hDC, m_hFont)
'DrawTextXP = DrawText(hdc, s, LenA(s), r, Style)
DrawTextXP = DrawTextW(hDC, ByVal StrPtr(s), Len(s), r, Style)
SelectObject hDC, h
If Style And DT_CALCRECT Then
 Width = r.Right - r.Left
 Height = r.Bottom - r.Top
End If
End Function

Public Function DrawTextVista(ByVal hDC As Long, ByVal s As String, ByVal Left As Long, ByVal Top As Long, Optional Width As Long, Optional Height As Long, Optional ByVal Style As DrawTextConstants, Optional ByVal ForeColor As Long, Optional ByVal BackColor As Long, Optional ByVal IsTrans As Boolean, Optional ByVal nTabLength As Long, Optional ByVal nLeftMargin As Long, Optional ByVal nRightMargin As Long, Optional ByRef nLengthDrawn As Long) As Long
On Error Resume Next
Dim r As RECT, h As Long
Dim t As DRAWTEXTPARAMS
If (Style And DT_CALCRECT) = 0 Then
 If IsTrans Then
  SetBkMode hDC, TRANSPARENT
 Else
  SetBkMode hDC, OPAQUE '?
  SetBkColor hDC, BackColor
 End If
 SetTextColor hDC, ForeColor
 r.Left = Left
 r.Top = Top
 r.Right = Width + Left
 r.Bottom = Height + Top
End If
t.cbSize = 20&
t.iTabLength = nTabLength
t.iLeftMargin = nLeftMargin
t.iRightMargin = nRightMargin
'///
h = SelectObject(hDC, m_hFont)
DrawTextVista = DrawTextExW(hDC, ByVal StrPtr(s), Len(s), r, Style, t)
SelectObject hDC, h
'///
nLengthDrawn = t.uiLengthDrawn
If Style And DT_CALCRECT Then
 Width = r.Right - r.Left
 Height = r.Bottom - r.Top
End If
End Function

Public Sub TextOutXP(ByVal hDC As Long, ByVal x As Long, ByVal y As Long, ByVal s As String, Optional ByVal ForeColor As Long, Optional ByVal BackColor As Long, Optional ByVal IsTrans As Boolean)
Dim h As Long
If IsTrans Then
 SetBkMode hDC, TRANSPARENT
Else
 SetBkMode hDC, OPAQUE '?
 SetBkColor hDC, BackColor
End If
h = SelectObject(hDC, m_hFont)
SetTextColor hDC, ForeColor
'TextOut hdc, x, y, s, LenA(s)
TextOutW hDC, x, y, ByVal StrPtr(s), Len(s)
SelectObject hDC, h
End Sub
