Attribute VB_Name = "mGradientFill"
Option Explicit

' BlendOp:
Private Const AC_SRC_OVER = &H0
' AlphaFormat:
Private Const AC_SRC_ALPHA = &H1

Private Declare Function AlphaBlend Lib "msimg32.dll" ( _
  ByVal hdcDest As Long, _
  ByVal nXOriginDest As Long, _
  ByVal nYOriginDest As Long, _
  ByVal nWidthDest As Long, _
  ByVal nHeightDest As Long, _
  ByVal hdcSrc As Long, _
  ByVal nXOriginSrc As Long, _
  ByVal nYOriginSrc As Long, _
  ByVal nWidthSrc As Long, _
  ByVal nHeightSrc As Long, _
  ByVal lBlendFunction As Long _
) As Long

'Private Type TRIVERTEX
'   x As Long
'   y As Long
'   Red As Integer
'   Green As Integer
'   Blue As Integer
'   Alpha As Integer
'End Type
'Private Type GRADIENT_RECT
'    UpperLeft As Long
'    LowerRight As Long
'End Type
'Private Declare Function GradientFill Lib "msimg32" ( _
'   ByVal hdc As Long, _
'   pVertex As TRIVERTEX, _
'   ByVal dwNumVertex As Long, _
'   pMesh As GRADIENT_RECT, _
'   ByVal dwNumMesh As Long, _
'   ByVal dwMode As Long) As Long
'
'Private Declare Function OleTranslateColor Lib "OLEPRO32.DLL" (ByVal OLE_COLOR As Long, ByVal HPALETTE As Long, pccolorref As Long) As Long
'Public Const CLR_INVALID = -1
'Public Const CLR_NONE = CLR_INVALID
'
'Public Type RECT
'        Left As Long
'        Top As Long
'        Right As Long
'        Bottom As Long
'End Type
'
'Public Enum GradientFillStyle
' GRADIENT_FILL_RECT_H = 0
' GRADIENT_FILL_RECT_V = 1
' GRADIENT_FILL_TRIANGLE = &H2&
'End Enum
'
'Public Const d_Bar1 = &HFAE2D0
'Public Const d_Bar2 = &HE2A981
'Public Const d_Hl1 = &HD0FCFD
'Public Const d_Hl2 = &H9DDFFD
'Public Const d_Checked1 = &H7DDDFA
'Public Const d_Checked2 = &H4EBCF5
'Public Const d_Pressed1 = &H5586F8
'Public Const d_Pressed2 = &HA37D2
'Public Const d_Border = &H800000
'
'Public Const d_Text = vbBlack
'Public Const d_TextHl = vbBlack
'Public Const d_TextDis = &HCB8C6A

Private lfnt As New CLogFont

'Public Sub GradientFillRect( _
'      ByVal lHDC As Long, _
'      tR As RECT, _
'      ByVal oStartColor As OLE_COLOR, _
'      ByVal oEndColor As OLE_COLOR, _
'      ByVal eDir As GradientFillStyle _
'   )
'Dim hBrush As Long
'Dim lStartColor As Long
'Dim lEndColor As Long
'Dim lR As Long
'
'   ' Use GradientFill:
'   'If (HasGradientAndTransparency) Then
'      lStartColor = TranslateColor(oStartColor)
'      lEndColor = TranslateColor(oEndColor)
'
'      Dim tTV(0 To 1) As TRIVERTEX
'      Dim tGR As GRADIENT_RECT
'
'      setTriVertexColor tTV(0), lStartColor
'      tTV(0).x = tR.Left
'      tTV(0).y = tR.Top
'      setTriVertexColor tTV(1), lEndColor
'      tTV(1).x = tR.Right
'      tTV(1).y = tR.Bottom
'
'      tGR.UpperLeft = 0
'      tGR.LowerRight = 1
'
'      GradientFill lHDC, tTV(0), 2, tGR, 1, eDir
'
'   'Else
'   '   ' Fill with solid brush:
'   '   hBrush = CreateSolidBrush(TranslateColor(oEndColor))
'   '   FillRect lHDC, tR, hBrush
'   '   DeleteObject hBrush
'   'End If
'
'End Sub
'
'Private Sub setTriVertexColor(tTV As TRIVERTEX, lColor As Long)
'Dim lRed As Long
'Dim lGreen As Long
'Dim lBlue As Long
'   lRed = (lColor And &HFF&) * &H100&
'   lGreen = (lColor And &HFF00&)
'   lBlue = (lColor And &HFF0000) \ &H100&
'   setTriVertexColorComponent tTV.Red, lRed
'   setTriVertexColorComponent tTV.Green, lGreen
'   setTriVertexColorComponent tTV.Blue, lBlue
'End Sub
'
'Public Function TranslateColor(ByVal oClr As OLE_COLOR, _
'                        Optional hPal As Long = 0) As Long
'    ' Convert Automation color to Windows color
'    If OleTranslateColor(oClr, hPal, TranslateColor) Then
'        TranslateColor = CLR_INVALID
'    End If
'End Function
'
'Private Sub setTriVertexColorComponent(ByRef iColor As Integer, ByVal lComponent As Long)
'   If (lComponent And &H8000&) = &H8000& Then
'      iColor = (lComponent And &H7F00&)
'      iColor = iColor Or &H8000
'   Else
'      iColor = lComponent
'   End If
'End Sub

Public Function DrawTextB(ByVal hdc As Long, ByVal s As String, fnt As StdFont, ByVal Left As Long, ByVal Top As Long, Optional Width As Long, Optional Height As Long, Optional ByVal Style As DrawTextConstants, Optional ByVal ForeColor As Long, Optional ByVal BackColor As Long, Optional ByVal IsTrans As Boolean, Optional ByVal HighQuality As Boolean = True) As Long
lfnt.HighQuality = HighQuality
Set lfnt.LogFont = fnt
lfnt.Rotation = 0
lfnt.DrawTextXP hdc, s, Left, Top, Width, Height, Style, ForeColor, BackColor, IsTrans
End Function

Public Sub TextOutB(ByVal hdc As Long, ByVal x As Long, ByVal y As Long, ByVal s As String, fnt As StdFont, Optional ByVal ForeColor As Long, Optional ByVal BackColor As Long, Optional ByVal IsTrans As Boolean, Optional ByVal Angle As Long, Optional ByVal HighQuality As Boolean = True)
lfnt.HighQuality = HighQuality
Set lfnt.LogFont = fnt
lfnt.Rotation = Angle
lfnt.TextOutXP hdc, x, y, s, ForeColor, BackColor, IsTrans
End Sub

Public Function AlphaBlendA(ByVal hdc As Long, ByVal x As Long, ByVal y As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal hSrcDC As Long, ByVal xSrc As Long, ByVal ySrc As Long, Optional ByVal nSrcWidth As Long, Optional ByVal nSrcHeight As Long, Optional ByVal Alpha As Long = 255, Optional ByVal UseAlphaChannel As Boolean = True) As Long
Dim n As Long
n = Alpha * &H10000
If UseAlphaChannel Then n = n Or &H1000000
If nSrcWidth = 0 Then nSrcWidth = nWidth
If nSrcHeight = 0 Then nSrcHeight = nHeight
AlphaBlendA = AlphaBlend(hdc, x, y, nWidth, nHeight, hSrcDC, xSrc, ySrc, nSrcWidth, nSrcHeight, n)
End Function
