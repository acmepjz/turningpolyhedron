VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsFakeDXUILogger"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Const m_nTimeFadeInMax As Single = 500

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)
Private Declare Sub ZeroMemory Lib "kernel32.dll" Alias "RtlZeroMemory" (ByRef Destination As Any, ByVal Length As Long)

Private Type typeFakeDXUILoggerItem '32 bytes
 sCaption As String
 nColor As Long '0=unused
 nShadowColor As Long
 nReserved As Long
 '///
 nTime As Single
 nTimeFadeIn As Single
 '///
 fPos As Single
 fPos_1 As Single
End Type

Private m_tData() As typeFakeDXUILoggerItem '1-based
Private m_nCount As Long, m_nMax As Long

Private m_nFontZoom As Single
Private m_nItemHeight As Single
Private m_nAlign As Long
Private m_nDrawTextFlags As Long

Private m_bShadowColorEnabled As Boolean

Friend Property Get ShadowColorEnabled() As Boolean
ShadowColorEnabled = m_bShadowColorEnabled
End Property

Friend Property Let ShadowColorEnabled(ByVal b As Boolean)
m_bShadowColorEnabled = b
End Property

Friend Property Get DrawTextFlags() As D3DXDRAWTEXTFORMAT
DrawTextFlags = m_nDrawTextFlags
End Property

Friend Property Let DrawTextFlags(ByVal n As D3DXDRAWTEXTFORMAT)
m_nDrawTextFlags = n
End Property

Friend Sub CreateNew(Optional ByVal nFontZoom As Single = 0.5, Optional ByVal nItemHeight As Single = 16, Optional ByVal nAlign As AlignConstants, Optional ByVal nFlags As D3DXDRAWTEXTFORMAT)
Erase m_tData
m_nCount = 0
m_nMax = 0
'///
m_nFontZoom = nFontZoom
m_nItemHeight = nItemHeight
m_nAlign = nAlign
m_nDrawTextFlags = nFlags
End Sub

Friend Property Get FontZoom() As Single
FontZoom = m_nFontZoom
End Property

Friend Property Let FontZoom(ByVal f As Single)
m_nFontZoom = f
End Property

Friend Property Get ItemHeight() As Single
FontZoom = m_nItemHeight
End Property

Friend Property Let ItemHeight(ByVal f As Single)
m_nItemHeight = f
End Property

Friend Property Get Align() As AlignConstants
Align = m_nAlign
End Property

Friend Property Let Align(ByVal n As AlignConstants)
m_nAlign = n
End Property

'nIndex 1=first, ... other=append
Friend Sub AddMessage(ByRef s As String, Optional ByVal nIndex As Long, Optional ByVal nColor As Long = -1, Optional ByVal nShadowColor As Long, Optional ByVal nTime As Single = 10000, Optional ByVal bLogToFile As Boolean)
Dim lp As Long
Dim t As typeFakeDXUILoggerItem
'///
If nColor = 0 Then Exit Sub
'///
m_nCount = m_nCount + 1
If m_nCount > m_nMax Then
 m_nMax = m_nMax + 64&
 ReDim Preserve m_tData(1 To m_nMax)
End If
If nIndex <= 0 Or nIndex > m_nCount Then nIndex = m_nCount
'///dirty code
If nIndex < m_nCount Then
 lp = VarPtr(m_tData(1))
 m_tData(m_nCount) = t
 CopyMemory ByVal lp + nIndex * 32&, ByVal lp + (nIndex - 1) * 32&, (m_nCount - nIndex) * 32&
 ZeroMemory ByVal lp + (nIndex - 1) * 32&, 32&
End If
'///
m_tData(nIndex).sCaption = s
m_tData(nIndex).nColor = nColor
m_tData(nIndex).nShadowColor = nShadowColor
m_tData(nIndex).nTime = nTime
m_tData(nIndex).nTimeFadeIn = 0
If nIndex > 1 Then m_tData(nIndex).fPos_1 = m_tData(nIndex - 1).fPos_1 + m_nItemHeight _
Else m_tData(nIndex).fPos_1 = 0
'///
'TODO:log to file support
End Sub

Friend Sub Render(Optional ByVal nLeft As Single, Optional ByVal nTop As Single, Optional ByVal nRight As Single, Optional ByVal nBottom As Single, Optional ByVal nOpacity As Single = 1)
Dim i As Long, j As Long, k As Long, l As Long
Dim f As Single, f2 As Single
Dim b As Boolean
'///calc position
If m_nAlign = vbAlignBottom Then f2 = m_nItemHeight
f = objTiming.GetDelta
For i = 1 To m_nCount
 b = False
 If m_tData(i).nColor = 0 Then
  b = True
 Else
  m_tData(i).nTime = m_tData(i).nTime - f
  m_tData(i).nTimeFadeIn = m_tData(i).nTimeFadeIn + f
  b = m_tData(i).nTime < 0
 End If
 '///
 If b Then
  j = j + 1
 Else
  If j > 0 Then m_tData(i - j) = m_tData(i)
  m_tData(i - j).fPos = f2
  f2 = f2 + m_nItemHeight
 End If
Next i
m_nCount = m_nCount - j
'///move to new position and draw
If m_nCount > 0 Then
 FakeDXUIDefaultFont.objSprite.Begin D3DXSPRITE_ALPHABLEND
 '///
 For i = 1 To m_nCount
  m_tData(i).fPos_1 = m_tData(i).fPos + (m_tData(i).fPos_1 - m_tData(i).fPos) * 0.8
  '///
  f = m_tData(i).nTime
  f2 = m_tData(i).nTimeFadeIn
  If f > f2 Then f = f2
  f = f / m_nTimeFadeInMax
  '///
  j = m_tData(i).nColor
  k = m_tData(i).nShadowColor
  If f < 1 Then
   l = (((j And &HFF000000) \ &H1000000) And &HFF&) * f
   j = (j And &HFFFFFF) Or ((l And &H7F&) * &H1000000) Or ((l >= &H80&) And &H80000000)
   l = (((k And &HFF000000) \ &H1000000) And &HFF&) * f
   k = (k And &HFFFFFF) Or ((l And &H7F&) * &H1000000) Or ((l >= &H80&) And &H80000000)
  End If
  k = k And m_bShadowColorEnabled
  '///
  Select Case m_nAlign
  Case vbAlignBottom
   FakeDXGDIDrawText FakeDXUIDefaultFont, m_tData(i).sCaption, _
   nLeft, nBottom - m_tData(i).fPos_1, nRight - nLeft, m_nItemHeight, _
   m_nFontZoom, m_nDrawTextFlags, j, , k, , , , , , , , m_bShadowColorEnabled
  Case vbAlignLeft
   FakeDXGDIDrawText FakeDXUIDefaultFont, m_tData(i).sCaption, _
   nLeft + m_tData(i).fPos_1, nBottom, nBottom - nTop, m_nItemHeight, _
   m_nFontZoom, m_nDrawTextFlags, j, , k, , , , -1.570796!, , , , m_bShadowColorEnabled
  Case vbAlignRight
   FakeDXGDIDrawText FakeDXUIDefaultFont, m_tData(i).sCaption, _
   nRight - m_tData(i).fPos_1, nTop, nBottom - nTop, m_nItemHeight, _
   m_nFontZoom, m_nDrawTextFlags, j, , k, , , , 1.570796!, , , , m_bShadowColorEnabled
  Case Else 'vbAlignTop
   FakeDXGDIDrawText FakeDXUIDefaultFont, m_tData(i).sCaption, _
   nLeft, nTop + m_tData(i).fPos_1, nRight - nLeft, m_nItemHeight, _
   m_nFontZoom, m_nDrawTextFlags, j, , k, , , , , , , , m_bShadowColorEnabled
  End Select
 Next i
 '///
 FakeDXUIDefaultFont.objSprite.End
End If
End Sub
