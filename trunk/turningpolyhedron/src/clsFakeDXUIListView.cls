VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsFakeDXUIListView"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'///FakeDXUIListView - modified from FakeListView ver2

Private Declare Function GetTextExtentPoint32W Lib "gdi32.dll" ( _
  ByVal hdc As Long, _
  ByRef lpString As Any, _
  ByVal c As Long, _
  ByRef lpSize As Any) As Long

Private Type RECT
    Left As Long
    Top As Long
    Right As Long
    Bottom As Long
End Type

Implements ISort2

Private m_bHeader As Boolean
Private m_bGrid As Boolean
Private m_nItemHeight As Long
Private m_nMinSize As Long
Private m_bRowMode As Boolean
Private m_bMultiSelect As Boolean

Private Type typeFakeColumnHeader
 sCaption As String
 nDataType As Long
 nFlags As Long
 nWidth As Long '0=right one or min size
 '///internal
 nLeft As Long
 '///FakeDXUI new
 bAnimVal1 As Byte
 bAnimVal2 As Byte
 bAnimVal3 As Byte
 bAnimVal4 As Byte
End Type

Public Enum enumFakeColumnDataType
 efctString = 0
 efctNumber = 1
 efctCheck = 2
 efctStringCaseInsensitive = 3
 efctCheck3State = 4
End Enum

Public Enum enumFakeColumnFlags
 efcfSizable = 1&
 efcfSortable = 2&
 efcfOwnerDraw = 4&
 efcfHidden = 8&
 efcfSortWithItemData = 16&
 efcfAlignRight = 32&
 efcfAlignCenter = 64&
 efcfEditable = 128&
End Enum

Private Type typeFakeListViewItem
 sValue As String
 nItemData As Long
 nFlags As Byte '???
 '1-selected
 '///FakeDXUI new
 bAnimVal1 As Byte
 bAnimVal2 As Byte
 bAnimVal3 As Byte
End Type

Private m_nColumns As Long, m_nRows As Long
Private m_nRowMax As Long, m_nRowStep As Long 'buffer mode
Private m_tHdr() As typeFakeColumnHeader
Private m_sData() As typeFakeListViewItem
Private m_nSortIndex As Long
'1-&hffffff index
'&h1000000 - descending?

Private m_nHlColumn As Long, m_nHlRow As Long
Private m_nHlColumn_Old As Long, m_nHlRow_Old As Long
Private m_nLastLeft As Long, m_nLastTop As Long, m_nLastWidth As Long '???
Private m_bPressed As Boolean

Private m_nSelColumn As Long, m_nSelRow As Long

Private m_bSizing As Boolean, m_nSizeIndex As Long, m_nSizeX As Long

Private m_bLocked As Boolean

'virtual mode ??? test only
Private m_bVirtual As Boolean

Private m_objVirtualSort As ISort2, m_nVirtualSortUserData As Long, m_nVirtualIndex() As Long

Public Event Change(ByVal nRow As Long, ByVal nColumn As Long, ByRef sCaption As String)
Public Event Click(ByVal nRow As Long, ByVal nColumn As Long)
Public Event DblClick(ByVal nRow As Long, ByVal nColumn As Long)
Public Event MouseMove(ByVal Button As MouseButtonConstants, ByVal Shift As ShiftConstants, ByVal x As Long, ByVal y As Long, ByVal nLeft As Long, ByVal nTop As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal nRow As Long, ByVal nColumn As Long, ByRef bRedraw As Boolean)
Public Event MouseDown(ByVal Button As MouseButtonConstants, ByVal Shift As ShiftConstants, ByVal x As Long, ByVal y As Long, ByVal nLeft As Long, ByVal nTop As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal nRow As Long, ByVal nColumn As Long)
Public Event MouseUp(ByVal Button As MouseButtonConstants, ByVal Shift As ShiftConstants, ByVal x As Long, ByVal y As Long, ByVal nLeft As Long, ByVal nTop As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal nRow As Long, ByVal nColumn As Long)
Public Event OwnerDraw(ByVal hdc As Long, ByVal x As Long, ByVal y As Long, ByVal nLeft As Long, ByVal nTop As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal nRow As Long, ByVal nColumn As Long, ByVal bPressed As Boolean, ByRef sCaption As String, ByVal nItemData As Long, ByRef bDoDefault As Boolean)
Public Event BeginEdit(ByVal nLeft As Long, ByVal nTop As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal nRow As Long, ByVal nColumn As Long, ByRef bCancel As Boolean) 'bCancel?
'TODO:EndEdit

Public Event KeyDown(ByVal KeyCode As KeyCodeConstants, ByVal Shift As ShiftConstants)
Public Event KeyUp(ByVal KeyCode As KeyCodeConstants, ByVal Shift As ShiftConstants)

'virtual mode event

Public Event VirtualModeGetValue(ByVal nRow As Long, ByVal nColumn As Long, ByRef sValue As String)
Public Event VirtualModeGetItemData(ByVal nRow As Long, ByVal nColumn As Long, ByRef nItemData As Long)
Public Event VirtualModeGetFlags(ByVal nRow As Long, ByVal nColumn As Long, ByRef nFlags As Long) '???
Public Event VirtualModeSetValue(ByVal nRow As Long, ByVal nColumn As Long, ByVal sValue As String) '???
Public Event VirtualModeSetItemData(ByVal nRow As Long, ByVal nColumn As Long, ByVal nItemData As Long) '???
Public Event VirtualModeSetFlags(ByVal nRow As Long, ByVal nColumn As Long, ByVal nFlags As Long) '???

'////////FakeDXUI new

Private m_nWidth As Long, m_nHeight As Long
Private m_nTotalWidth As Long, m_nTotalHeight As Long
Private m_bEnabled As Boolean

Private m_nScrollValue(1) As Long, m_bScrollChanged As Boolean
Private m_nSmallChange(1) As Long
Private m_bCapture As Boolean

Friend Property Get ScrollChanged() As Boolean
ScrollChanged = m_bScrollChanged
End Property

Friend Property Let ScrollChanged(ByVal b As Boolean)
m_bScrollChanged = b
End Property

Friend Property Get ScrollValue(Optional ByVal nIndex As Long) As Long
ScrollValue = m_nScrollValue(nIndex)
End Property

Friend Property Let ScrollValue(Optional ByVal nIndex As Long, ByVal n As Long)
m_nScrollValue(nIndex) = n
End Property

Friend Property Get SmallChange(Optional ByVal nIndex As Long) As Long
SmallChange = m_nSmallChange(nIndex)
End Property

Friend Property Let SmallChange(Optional ByVal nIndex As Long, ByVal n As Long)
m_nSmallChange(nIndex) = n
End Property

Friend Property Get Width() As Long
Width = m_nWidth
End Property

Friend Property Let Width(ByVal n As Long)
m_nWidth = n
End Property

Friend Property Get Height() As Long
Height = m_nHeight
End Property

Friend Property Let Height(ByVal n As Long)
m_nHeight = n
End Property

Friend Property Get TotalWidth() As Long
TotalWidth = m_nTotalWidth
End Property

Friend Property Get TotalHeight() As Long
TotalHeight = m_nTotalHeight
End Property

Friend Property Get VirtualMode() As Boolean
VirtualMode = m_bVirtual
End Property

Friend Property Let VirtualMode(ByVal b As Boolean)
m_bVirtual = b
End Property

Friend Property Get VirtualSortObject() As ISort2
Set VirtualSortObject = m_objVirtualSort
End Property

Friend Property Get VirtualSortUserData() As Long
VirtualSortUserData = m_nVirtualSortUserData
End Property

Friend Sub SetVirtualSortObject(ByVal obj As ISort2, ByVal nUserData As Long)
Dim i As Long
If m_bVirtual Then
 If obj Is Nothing Then
  Erase m_nVirtualIndex
 ElseIf m_objVirtualSort Is Nothing And m_nRows > 0 Then
  ReDim m_nVirtualIndex(1 To m_nRows)
  For i = 1 To m_nRows
   m_nVirtualIndex(i) = i
  Next i
 End If
 Set m_objVirtualSort = obj
 m_nVirtualSortUserData = nUserData
End If
End Sub

Friend Function VirtualIndex(Optional ByVal nRow As Long = -1) As Long
If nRow < 0 Then nRow = m_nSelRow
If nRow > 0 And nRow <= m_nRows Then
 If m_bVirtual And Not m_objVirtualSort Is Nothing Then
  VirtualIndex = m_nVirtualIndex(nRow)
 Else
  VirtualIndex = nRow
 End If
End If
End Function

Friend Sub EnsureVisible(Optional ByVal nRow As Long, Optional ByVal nColumn As Long)
Dim m As Long, i As Long
If nRow = 0 Then nRow = m_nSelRow
If nRow > 0 And nRow <= m_nRows Then
 nRow = nRow - 1
 m = m_nHeight - m_nItemHeight
 If m_bHeader Then m = m - m_nItemHeight
 i = nRow * m_nItemHeight - m_nScrollValue(1)
 If i < 0 Or i > m Then
  m_nScrollValue(1) = nRow * m_nItemHeight - m \ 2
  m_bScrollChanged = True
 End If
End If
If nColumn > 0 And nColumn <= m_nColumns Then
 'TODO:
End If
End Sub

Private Sub pDrawArrow(ByVal x As Long, ByVal y As Long, ByVal nOpacity As Single, ByVal bEnabled As Boolean, ByVal bDescending As Boolean)
Dim i As Long, j As Long, k As Long
i = nOpacity * 255
i = ((i And &H7F&) * &H1000000) Or ((i > &H7F&) And &H80000000) Or &HFFFFFF
j = 160 + (bDescending And 16&)
k = 384 - (bEnabled And 16&)
FakeDXGDIStretchBltColored x - 8, y - 8, x + 8, y + 8, j, k, j + 16, k + 16, 512, i
End Sub

'TODO:enabled and animation
Private Sub pDrawCheck(ByVal nOpacity As Single, ByVal x As Long, ByVal y As Long, ByVal nValue As Long, ByVal nState As Long)
Dim i As Long, j As Long
i = nOpacity * 255
i = ((i And &H7F&) * &H1000000) Or ((i > &H7F&) And &H80000000) Or &HFFFFFF
FakeDXGDIStretchBltColored x, y, x + 16, y + 16, 0, 368, 16, 384, 512, i
If nState Then
 i = nOpacity * ((nState And &HF&) * 51&)
 i = ((i And &H7F&) * &H1000000) Or ((i > &H7F&) And &H80000000) Or &HFFFFFF
 FakeDXGDIStretchBltBlended x, y, x + 16, y + 16, 32, 368, 48, 384, 512, 16, 368, (nState \ &H10&) * 51&, i
End If
j = nValue And &HF&
If j > 0 Then
 i = nOpacity * (j * 51&)
 i = ((i And &H7F&) * &H1000000) Or ((i > &H7F&) And &H80000000) Or &HFFFFFF
 FakeDXGDIStretchBltColored x, y, x + 16, y + 16, 0, 384, 16, 400, 512, i
End If
j = nValue \ &H10&
If j > 0 Then
 i = nOpacity * (j * 51&)
 i = ((i And &H7F&) * &H1000000) Or ((i > &H7F&) And &H80000000) Or &HFFFFFF
 FakeDXGDIStretchBltColored x, y, x + 16, y + 16, 32, 384, 48, 400, 512, i
End If
End Sub

Friend Property Get FullRowSelect() As Boolean
FullRowSelect = m_bRowMode
End Property

'TODO:selection
Friend Property Let FullRowSelect(ByVal b As Boolean)
m_bRowMode = b
End Property

Friend Property Get MultiSelect() As Boolean
MultiSelect = m_bMultiSelect
End Property

'TODO:selection
Friend Property Let MultiSelect(ByVal b As Boolean)
m_bMultiSelect = b
End Property

Friend Sub ClearAll()
m_nColumns = 0
m_nRows = 0
m_nSelColumn = 0
m_nSelRow = 0
Erase m_tHdr, m_sData, m_nVirtualIndex
Refresh
End Sub

Friend Sub Clear()
m_nRows = 0
m_nSelColumn = 0
m_nSelRow = 0
If m_nRowMax = 0 Then Erase m_sData
Erase m_nVirtualIndex
Refresh
End Sub

Friend Property Get ColumnCount() As Long
ColumnCount = m_nColumns
End Property

Friend Property Get RowCount() As Long
RowCount = m_nRows
End Property

Friend Property Let RowCount(ByVal n As Long)
Dim i As Long
If m_bVirtual And m_nRows <> n And n >= 0 Then
 If n = 0 Then
  Erase m_nVirtualIndex
 ElseIf n < m_nRows Then
  ReDim m_nVirtualIndex(1 To n)
  For i = 1 To n
   m_nVirtualIndex(i) = i
  Next i
 ElseIf n > m_nRows Then
  ReDim Preserve m_nVirtualIndex(1 To n)
  For i = m_nRows + 1 To n
   m_nVirtualIndex(i) = i
  Next i
 End If
 m_nRows = n
 Refresh
End If
End Property

Friend Sub GetRowBufferInfo(ByRef nSize As Long, ByRef nStep As Long)
If m_bVirtual Then Exit Sub
nSize = m_nRowMax
nStep = m_nRowStep
End Sub

Friend Sub SetRowBufferInfo(ByVal nSize As Long, ByVal nStep As Long)
If m_bVirtual Then Exit Sub
If nSize <= m_nRows And nSize > 0 Then nSize = m_nRows
If nStep <= 1 Then nStep = 1
m_nRowMax = nSize
m_nRowStep = nStep
If nSize > m_nRows And m_nColumns > 0 Then
 ReDim Preserve m_sData(1 To m_nColumns, 1 To nSize)
End If
End Sub

Friend Property Get ColumnCaption(ByVal nIndex As Long) As String
ColumnCaption = m_tHdr(nIndex).sCaption
End Property

Friend Property Let ColumnCaption(ByVal nIndex As Long, ByVal s As String)
m_tHdr(nIndex).sCaption = s
End Property

Friend Property Get ColumnDataType(ByVal nIndex As Long) As enumFakeColumnDataType
ColumnDataType = m_tHdr(nIndex).nDataType
End Property

Friend Property Let ColumnDataType(ByVal nIndex As Long, ByVal n As enumFakeColumnDataType)
m_tHdr(nIndex).nDataType = n
End Property

Friend Property Get ColumnFlags(ByVal nIndex As Long) As enumFakeColumnFlags
ColumnFlags = m_tHdr(nIndex).nFlags
End Property

Friend Property Let ColumnFlags(ByVal nIndex As Long, ByVal n As enumFakeColumnFlags)
m_tHdr(nIndex).nFlags = n
Refresh
End Property

Friend Property Get ColumnWidth(ByVal nIndex As Long) As Long
ColumnWidth = m_tHdr(nIndex).nWidth
End Property

Friend Property Let ColumnWidth(ByVal nIndex As Long, ByVal n As Long)
m_tHdr(nIndex).nWidth = n
Refresh
End Property

Friend Property Get List(ByVal nRow As Long, ByVal nColumn As Long) As String
If Not m_bVirtual Then List = m_sData(nColumn, nRow).sValue
End Property

Friend Property Let List(ByVal nRow As Long, ByVal nColumn As Long, ByVal s As String)
If Not m_bVirtual Then
 m_sData(nColumn, nRow).sValue = s
End If
End Property

Friend Property Get SelectedRow() As Long
SelectedRow = m_nSelRow
End Property

Friend Property Let SelectedRow(ByVal n As Long)
Dim i As Long, j As Long, jj As Long, k As Long
Dim m As Long
If n < 0 Or n > m_nRows Then n = 0
If n <> m_nSelRow Then
 m_nSelRow = n
 m = m_nColumns
 If m_bVirtual And m_bRowMode And m > 1 Then m = 1
 If n = 0 Then
  For i = 1 To m
   For j = 1 To m_nRows
    If m_bVirtual Then
     jj = j
     If Not m_objVirtualSort Is Nothing Then jj = m_nVirtualIndex(j)
     RaiseEvent VirtualModeSetFlags(jj, i, 0)
    Else
     With m_sData(i, j)
      .nFlags = .nFlags And &HFFFFFFFE
     End With
    End If
   Next j
  Next i
 ElseIf Not m_bMultiSelect Then
  If m_bRowMode Then
   For i = 1 To m
    For j = 1 To m_nRows
     k = ((j = n) And 1&)
     If m_bVirtual Then
      jj = j
      If Not m_objVirtualSort Is Nothing Then jj = m_nVirtualIndex(j)
      RaiseEvent VirtualModeSetFlags(jj, i, k)
     Else
      With m_sData(i, j)
       .nFlags = (.nFlags And &HFFFFFFFE) Or k
      End With
     End If
    Next j
   Next i
  ElseIf m_nSelColumn > 0 Then
   For i = 1 To m_nColumns
    For j = 1 To m_nRows
     k = ((i = m_nSelColumn And j = n) And 1&)
     If m_bVirtual Then
      jj = j
      If Not m_objVirtualSort Is Nothing Then jj = m_nVirtualIndex(j)
      RaiseEvent VirtualModeSetFlags(jj, i, k)
     Else
      With m_sData(i, j)
       .nFlags = (.nFlags And &HFFFFFFFE) Or k
      End With
     End If
    Next j
   Next i
  End If
 End If
End If
End Property

Friend Property Get SelectedColumn() As Long
SelectedColumn = m_nSelColumn
End Property

Friend Property Let SelectedColumn(ByVal n As Long)
Dim i As Long, j As Long, jj As Long, k As Long
If Not m_bRowMode Then
 If n < 0 Or n > m_nColumns Then n = 0
 If n <> m_nSelColumn Then
  m_nSelColumn = n
  If n = 0 Then
   For i = 1 To m_nColumns
    For j = 1 To m_nRows
     If m_bVirtual Then
      jj = j
      If Not m_objVirtualSort Is Nothing Then jj = m_nVirtualIndex(j)
      RaiseEvent VirtualModeSetFlags(jj, i, 0)
     Else
      With m_sData(i, j)
       .nFlags = .nFlags And &HFFFFFFFE
      End With
     End If
    Next j
   Next i
  ElseIf m_nSelRow > 0 And Not m_bMultiSelect Then
   For i = 1 To m_nColumns
    For j = 1 To m_nRows
     k = ((i = n And j = m_nSelRow) And 1&)
     If m_bVirtual Then
      jj = j
      If Not m_objVirtualSort Is Nothing Then jj = m_nVirtualIndex(j)
      RaiseEvent VirtualModeSetFlags(jj, i, k)
     Else
      With m_sData(i, j)
       .nFlags = (.nFlags And &HFFFFFFFE) Or k
      End With
     End If
    Next j
   Next i
  End If
 End If
End If
End Property

Friend Property Get ItemData(ByVal nRow As Long, ByVal nColumn As Long) As Long
If Not m_bVirtual Then ItemData = m_sData(nColumn, nRow).nItemData
End Property

Friend Property Let ItemData(ByVal nRow As Long, ByVal nColumn As Long, ByVal n As Long)
If Not m_bVirtual Then m_sData(nColumn, nRow).nItemData = n
End Property

Friend Function AddItem(ByVal sCaption As String, Optional ByVal nIndex As Long, Optional ByVal nItemData As Long, Optional ByRef vtSubItems As Variant) As Long
Dim i As Long, j As Long, k As Long, kk As Long
Dim t As typeFakeListViewItem
If m_nColumns <= 0 Or m_bVirtual Then Exit Function
If nIndex <= 0 Or nIndex > m_nRows Then nIndex = m_nRows + 1
'///
m_nRows = m_nRows + 1
If m_nRowMax > 0 Then
 If m_nRows > m_nRowMax Then
  m_nRowMax = m_nRowMax + m_nRowStep
  ReDim Preserve m_sData(1 To m_nColumns, 1 To m_nRowMax)
 End If
Else
 ReDim Preserve m_sData(1 To m_nColumns, 1 To m_nRows)
End If
For j = m_nRows To nIndex + 1 Step -1
 For i = 1 To m_nColumns
  m_sData(i, j) = m_sData(i, j - 1)
 Next i
Next j
'///
If m_nSelRow >= nIndex Then m_nSelRow = m_nSelRow + 1
'///
For i = 1 To m_nColumns
 m_sData(i, nIndex) = t
Next i
With m_sData(1, nIndex)
 .sValue = sCaption
 .nItemData = nItemData
End With
On Error Resume Next
k = VarType(vtSubItems)
If k And vbArray Then
 j = LBound(vtSubItems)
 kk = UBound(vtSubItems)
 For i = 2 To m_nColumns
  If j > kk Then Exit For
  k = VarType(vtSubItems(j))
  If k And vbArray Then
   k = UBound(vtSubItems(j))
   If k >= 0 Then
    m_sData(i, nIndex).sValue = CStr(vtSubItems(j)(0))
    If k >= 1 Then
     m_sData(i, nIndex).nItemData = Val(CStr(vtSubItems(j)(1)))
    End If
   End If
  ElseIf k <> vbError Then
   m_sData(i, nIndex).sValue = CStr(vtSubItems(j))
  End If
  j = j + 1
 Next i
ElseIf k <> vbError Then
 If m_nColumns >= 2 Then m_sData(2, nIndex).sValue = CStr(vtSubItems)
End If
On Error GoTo 0
'///
Refresh
'///
AddItem = nIndex
End Function

Friend Sub RemoveItem(ByVal nIndex As Long)
Dim i As Long, j As Long
If nIndex <= 0 Or nIndex > m_nRows Or m_bVirtual Then Exit Sub
'///
If m_nRows <= 1 Then
 Clear
 Exit Sub
End If
'///
For j = nIndex + 1 To m_nRows
 For i = 1 To m_nColumns
  m_sData(i, j - 1) = m_sData(i, j)
 Next i
Next j
m_nRows = m_nRows - 1
If m_nRowMax = 0 Then ReDim Preserve m_sData(1 To m_nColumns, 1 To m_nRows)
'///
If m_nSelRow > nIndex Then m_nSelRow = m_nSelRow - 1 Else If m_nSelRow = nIndex Then m_nSelRow = 0: m_nSelColumn = 0
'///
Refresh
End Sub

Friend Function AddColumn(ByVal sCaption As String, Optional ByVal nIndex As Long, Optional ByVal nDataType As enumFakeColumnDataType, Optional ByVal nFlags As enumFakeColumnFlags, Optional ByVal nWidth As Long) As Long
Dim i As Long, j As Long
Dim s() As typeFakeListViewItem
If nIndex <= 0 Or nIndex > m_nColumns Then nIndex = m_nColumns + 1
'///
m_nColumns = m_nColumns + 1
ReDim Preserve m_tHdr(1 To m_nColumns)
For i = m_nColumns To nIndex + 1 Step -1
 m_tHdr(i) = m_tHdr(i - 1)
Next i
With m_tHdr(nIndex)
 .sCaption = sCaption
 .nDataType = nDataType
 .nFlags = nFlags
 .nWidth = nWidth
End With
'///
i = m_nSortIndex And &HFFFFFF
If i >= nIndex Then m_nSortIndex = m_nSortIndex + 1
If m_nSelColumn >= nIndex Then m_nSelColumn = m_nSelColumn + 1
'///
If (m_nRows > 0 Or m_nRowMax > 0) And Not m_bVirtual Then
 i = m_nRows
 If i < m_nRowMax Then i = m_nRowMax
 ReDim s(1 To m_nColumns, 1 To i)
 For i = 1 To nIndex - 1
  For j = 1 To m_nRows
   s(i, j) = m_sData(i, j)
  Next j
 Next i
 For i = nIndex + 1 To m_nColumns
  For j = 1 To m_nRows
   s(i, j) = m_sData(i - 1, j)
  Next j
 Next i
 m_sData = s
End If
'///
Refresh
'///
AddColumn = nIndex
End Function

Friend Sub RemoveColumn(ByVal nIndex As Long)
Dim i As Long, j As Long
Dim s() As typeFakeListViewItem
If nIndex <= 0 Or nIndex > m_nColumns Then Exit Sub
'///
If m_nColumns <= 1 Then
 ClearAll
 Exit Sub
End If
For i = nIndex + 1 To m_nColumns
 m_tHdr(i - 1) = m_tHdr(i)
Next i
m_nColumns = m_nColumns - 1
ReDim Preserve m_tHdr(1 To m_nColumns)
'///
i = m_nSortIndex And &HFFFFFF
If i > nIndex Then m_nSortIndex = m_nSortIndex - 1 Else If i = nIndex Then m_nSortIndex = 0
If m_nSelColumn > nIndex Then
 m_nSelColumn = m_nSelColumn - 1
ElseIf m_nSelColumn = nIndex Then
 If m_bRowMode Then
  m_nSelColumn = m_nSelColumn - 1
 Else
  m_nSelColumn = 0
  m_nSelRow = 0
 End If
End If
'///
If (m_nRows > 0 Or m_nRowMax > 0) And Not m_bVirtual Then
 i = m_nRows
 If i < m_nRowMax Then i = m_nRowMax
 ReDim s(1 To m_nColumns, 1 To i)
 For i = 1 To nIndex - 1
  For j = 1 To m_nRows
   s(i, j) = m_sData(i, j)
  Next j
 Next i
 For i = nIndex + 1 To m_nColumns
  For j = 1 To m_nRows
   s(i - 1, j) = m_sData(i, j)
  Next j
 Next i
 m_sData = s
End If
'///
Refresh
End Sub

Friend Property Get RowHeight() As Long
RowHeight = m_nItemHeight
End Property

Friend Property Let RowHeight(ByVal n As Long)
If n > 0 And m_nItemHeight <> n Then
 m_nItemHeight = n
 m_nSmallChange(1) = n
 m_bScrollChanged = True
 Refresh
End If
End Property

Friend Property Get ColumnHeader() As Boolean
ColumnHeader = m_bHeader
End Property

Friend Property Let ColumnHeader(ByVal b As Boolean)
m_bHeader = b
Refresh
End Property

Friend Property Get GridLines() As Boolean
GridLines = m_bGrid
End Property

Friend Property Let GridLines(ByVal b As Boolean)
m_bGrid = b
End Property

Friend Sub Sort(Optional ByVal nSortColumn As Long = -1, Optional ByVal nSortDescending As VbTriState = vbUseDefault)
If nSortColumn < 0 Then nSortColumn = m_nSortIndex And &HFFFFFF
If nSortColumn < 0 Or nSortColumn > m_nColumns Then nSortColumn = 0
If nSortDescending = vbUseDefault Then nSortDescending = m_nSortIndex And &H1000000
nSortColumn = nSortColumn Or ((nSortDescending <> 0) And (nSortColumn <> 0) And &H1000000)
m_nSortIndex = nSortColumn
If nSortColumn Then pSort
End Sub

Private Sub pSort()
Dim i As Long, j As Long, k As Long, kk As Long
Dim s() As typeFakeListViewItem
Dim idx() As Long
If m_bVirtual And m_objVirtualSort Is Nothing Then Exit Sub
k = m_nSortIndex And &HFFFFFF
If m_nRows > 0 And k > 0 And k <= m_nColumns Then
 If m_bVirtual Then
  If m_nSelRow > 0 And m_nSelRow <= m_nRows Then m_nSelRow = m_nVirtualIndex(m_nSelRow) _
  Else m_nSelRow = 0
  With New ISort2
   .QuickSort m_nVirtualIndex, 1, m_nRows, m_objVirtualSort, k Or m_nVirtualSortUserData
  End With
  If m_nSortIndex And &H1000000 Then
   For i = 1 To m_nRows \ 2
    j = m_nVirtualIndex(i)
    k = m_nVirtualIndex(m_nRows + 1 - i)
    If j = m_nSelRow Then kk = m_nRows + 1 - i Else _
    If k = m_nSelRow Then kk = i
    m_nVirtualIndex(i) = k
    m_nVirtualIndex(m_nRows + 1 - i) = j
   Next i
   If kk = 0 And m_nSelRow > 0 Then kk = m_nRows \ 2 + 1
  Else
   For i = 1 To m_nRows
    If m_nVirtualIndex(i) = m_nSelRow Then
     kk = i
     Exit For
    End If
   Next i
  End If
  m_nSelRow = kk
 Else
  ReDim idx(1 To m_nRows)
  For i = 1 To m_nRows
   idx(i) = i
  Next i
  With New ISort2
   .QuickSort idx, 1, m_nRows, Me, k
  End With
  i = m_nRows
  If i < m_nRowMax Then i = m_nRowMax
  ReDim s(1 To m_nColumns, 1 To i)
  If m_nSortIndex And &H1000000 Then
   For i = 1 To m_nRows
    k = idx(m_nRows + 1 - i)
    If k = m_nSelRow Then kk = i
    For j = 1 To m_nColumns
     s(j, i) = m_sData(j, k)
    Next j
   Next i
  Else
   For i = 1 To m_nRows
    k = idx(i)
    If k = m_nSelRow Then kk = i
    For j = 1 To m_nColumns
     s(j, i) = m_sData(j, k)
    Next j
   Next i
  End If
  m_nSelRow = kk
  m_sData = s
 End If
End If
End Sub

Friend Property Get Enabled() As Boolean
Enabled = m_bEnabled
End Property

Friend Property Let Enabled(ByVal b As Boolean)
m_bEnabled = b
End Property

Private Function ISort2_Compare(ByVal Index1 As Long, ByVal Index2 As Long, ByVal nUserData As Long) As Long
On Error Resume Next
Dim i As Long, j As Long
Dim t As Double
With m_tHdr(nUserData)
 If .nFlags And 16& Then
  i = m_sData(nUserData, Index1).nItemData
  j = m_sData(nUserData, Index2).nItemData
  ISort2_Compare = (i < j) Or ((i > j) And 1&)
 Else
  Select Case .nDataType
  Case 0
   ISort2_Compare = StrComp(m_sData(nUserData, Index1).sValue, m_sData(nUserData, Index2).sValue, vbBinaryCompare)
  Case 3
   ISort2_Compare = StrComp(m_sData(nUserData, Index1).sValue, m_sData(nUserData, Index2).sValue, vbTextCompare)
  Case Else
   t = Val(m_sData(nUserData, Index1).sValue) - Val(m_sData(nUserData, Index2).sValue)
   ISort2_Compare = (t < 0) Or ((t > 0) And 1&)
  End Select
 End If
End With
End Function

'????????
Friend Sub BeforeMouseEvent()
m_nHlColumn = 0
m_nHlRow = 0
End Sub

Friend Sub OnMouseMove(ByVal Button As Long, ByVal Shift As Long, ByVal xCur As Long, ByVal yCur As Long)
Dim i As Long, j As Long
Dim b As Boolean
Dim x As Long, y As Long, w As Long
Dim ww As Long, hh As Long
'///
Dim xx As Long, yy As Long
'///sizing column header?
If m_bSizing Then
 If m_nSizeX <> xCur Then
  If m_nSizeIndex > 0 And m_nSizeIndex <= m_nColumns Then
   If (m_tHdr(m_nSizeIndex).nFlags And 1&) <> 0 And m_tHdr(m_nSizeIndex).nWidth > 0 Then
    w = m_tHdr(m_nSizeIndex).nWidth
    i = xCur - m_nSizeX
    If w + i < 16 Then i = 16 - w
    m_tHdr(m_nSizeIndex).nWidth = w + i
    m_nSizeX = m_nSizeX + i
    FakeDXUIMousePointer = vbSizeWE
    Refresh
   End If
  End If
 End If
 Exit Sub
End If
'///
ww = m_nWidth
hh = m_nHeight
'///list item hit test
x = m_nScrollValue(0)
For i = 1 To m_nColumns
 With m_tHdr(i)
  If (.nFlags And 8&) = 0 Then
   w = .nWidth
   If w = 0 Then
    If i = m_nColumns Then
     w = ww - .nLeft + x
    Else
     w = m_nMinSize
    End If
   End If
   j = .nLeft - x
   If xCur >= j And xCur < j + w Then
    y = m_nScrollValue(1)
    If m_bHeader Then
     '///header hit test
     If yCur >= 0 And yCur < m_nItemHeight Then
      xx = i
      If xCur < j + 3 Then 'left resize
       yy = -1
      ElseIf xCur > j + w - 3 Then 'right resize
       yy = -2
      End If
     Else
      y = y - m_nItemHeight
     End If
    End If
    If xx = 0 Then
     y = (y + m_nItemHeight + yCur) \ m_nItemHeight
     If y > 0 And y <= m_nRows Then
      xx = i
      yy = y
      'get top
      y = y * m_nItemHeight - m_nScrollValue(1)
      If Not m_bHeader Then y = y - m_nItemHeight
     End If
    End If
   End If
  End If
 End With
 If xx > 0 Then Exit For
Next i
'///header resize?
If yy < 0 Then
 If yy = -1 Then
  i = xx - 1
  Do While i > 0
   If (m_tHdr(i).nFlags And 8&) = 0 Then Exit Do
   i = i - 1
  Loop
 Else
  i = xx
 End If
 If i > 0 And i <= m_nColumns Then
  If (m_tHdr(i).nFlags And 1&) <> 0 And m_tHdr(i).nWidth > 0 Then
   'sizable
   m_nSizeIndex = i
   FakeDXUIMousePointer = vbSizeWE
  Else
   m_nSizeIndex = 0
   FakeDXUIMousePointer = vbDefault
  End If
 End If
 yy = 0
Else
 m_nSizeIndex = 0
 FakeDXUIMousePointer = vbDefault
End If
'///raise event
If xx > 0 And yy > 0 Then
 m_nLastLeft = j
 m_nLastTop = y
 m_nLastWidth = w
 RaiseEvent MouseMove(Button, Shift, xCur, yCur, j, y, w, m_nItemHeight, yy, xx, b)
Else
 RaiseEvent MouseMove(Button, Shift, xCur, yCur, 0, 0, 0, 0, 0, 0, b)
End If
'///
If (m_bPressed And (m_nHlColumn_Old <> xx Or m_nHlRow_Old <> yy)) Or (m_bLocked And yy > 0) Then
 xx = 0
 yy = 0
End If
'///
If m_nHlColumn <> xx Or m_nHlRow <> yy Or b Then
 m_nHlColumn = xx
 m_nHlRow = yy
 'TODO:raise event
 '///
 't1.Enabled = xx <> 0 '????????
End If
'///
End Sub

Friend Sub OnMouseUp(ByVal Button As Long, ByVal Shift As Long, ByVal xCur As Long, ByVal yCur As Long)
On Error Resume Next
Dim i As Long, j As Long, s As String
If m_bPressed Then
 m_bPressed = False
 'resize header
 If m_bSizing Then
  If m_nSizeIndex > 0 And m_nSizeIndex <= m_nColumns Then
   m_nSizeIndex = 0
  End If
  m_bSizing = False
  Refresh
  Exit Sub
 End If
 If m_nHlColumn > 0 Then
  '///TODO:header click event
  If m_nHlRow = 0 Then
   'header
   If m_tHdr(m_nHlColumn).nFlags And 2& Then
    'change sort state
    i = m_nSortIndex And &HFFFFFF
    If i = m_nHlColumn Then m_nSortIndex = m_nSortIndex Xor &H1000000 Else m_nSortIndex = m_nHlColumn
    'sort
    pSort
   End If
  Else
   RaiseEvent MouseUp(Button, Shift, xCur, yCur, m_nLastLeft, m_nLastTop, m_nLastWidth, m_nItemHeight, m_nHlRow, m_nHlColumn)
   '///
   Select Case m_tHdr(m_nHlColumn).nDataType
   Case 2 'check
    If m_bVirtual Then
     If m_objVirtualSort Is Nothing Then j = m_nHlRow Else _
     j = m_nVirtualIndex(m_nHlRow)
     RaiseEvent VirtualModeGetValue(j, m_nHlColumn, s)
     i = Val(s)
     i = (i = 0) And 1&
     s = CStr(i)
     RaiseEvent Change(m_nHlRow, m_nHlColumn, s)
     RaiseEvent VirtualModeSetValue(j, m_nHlColumn, s)
    Else
     i = Val(m_sData(m_nHlColumn, m_nHlRow).sValue)
     i = (i = 0) And 1&
     s = CStr(i)
     RaiseEvent Change(m_nHlRow, m_nHlColumn, s)
     m_sData(m_nHlColumn, m_nHlRow).sValue = s
    End If
   Case 4 '3-state
    If m_bVirtual Then
     If m_objVirtualSort Is Nothing Then j = m_nHlRow Else _
     j = m_nVirtualIndex(m_nHlRow)
     RaiseEvent VirtualModeGetValue(j, m_nHlColumn, s)
     i = Val(s)
     If i < 0 Or i > 1 Then i = 0 Else i = i + 1
     s = CStr(i)
     RaiseEvent Change(m_nHlRow, m_nHlColumn, s)
     RaiseEvent VirtualModeSetValue(j, m_nHlColumn, s)
    Else
     i = Val(m_sData(m_nHlColumn, m_nHlRow).sValue)
     If i < 0 Or i > 1 Then i = 0 Else i = i + 1
     s = CStr(i)
     RaiseEvent Change(m_nHlRow, m_nHlColumn, s)
     m_sData(m_nHlColumn, m_nHlRow).sValue = s
    End If
   End Select
  End If
  '///
 End If
End If
End Sub

Friend Sub OnMouseDown(ByVal Button As Long, ByVal Shift As Long, ByVal xCur As Long, ByVal yCur As Long)
Dim i As Long, j As Long, jj As Long
Dim m As Long, n As Long
Dim m2 As Long, n2 As Long
If Not m_bPressed Then
 m_bPressed = True
 'resize header
 If m_nSizeIndex > 0 And m_nSizeIndex <= m_nColumns Then
  m_nSizeX = xCur
  m_bSizing = True
  FakeDXUIMousePointer = vbSizeWE
  Exit Sub
 End If
 If m_nHlColumn > 0 Then
  If m_nHlRow > 0 Then
   'change selection (???????? order ????????)
   If m_bRowMode Then
    If (Shift And vbShiftMask) <> 0 And m_nSelRow > 0 And m_nSelRow <= m_nRows And m_bMultiSelect And Button = 1 Then
     If m_nHlRow < m_nSelRow Then
      m = m_nHlRow
      n = m_nSelRow
     Else
      m = m_nSelRow
      n = m_nHlRow
     End If
     If m_bVirtual Then
      For j = m To n
       jj = j
       If Not m_objVirtualSort Is Nothing Then jj = m_nVirtualIndex(j)
       RaiseEvent VirtualModeSetFlags(jj, 1, 1)
      Next j
     Else
      For i = 1 To m_nColumns
       For j = m To n
        With m_sData(i, j)
         .nFlags = .nFlags Or 1&
        End With
       Next j
      Next i
     End If
    ElseIf (Shift And vbCtrlMask) <> 0 And m_bMultiSelect And Button = 1 Then
     If m_bVirtual Then
      i = 0
      jj = m_nHlRow
      If Not m_objVirtualSort Is Nothing Then jj = m_nVirtualIndex(jj)
      RaiseEvent VirtualModeGetFlags(jj, 1, i)
      RaiseEvent VirtualModeSetFlags(jj, 1, i Xor 1&)
     Else
      For i = 1 To m_nColumns
       With m_sData(i, m_nHlRow)
        .nFlags = .nFlags Xor 1&
       End With
      Next i
     End If
     m_nSelColumn = m_nHlColumn
     m_nSelRow = m_nHlRow
     RaiseEvent Click(m_nSelRow, m_nSelColumn)
    ElseIf Not m_bMultiSelect Or Button = 1 Then '?
     If m_bVirtual Then
      For j = 1 To m_nRows
       jj = j
       If Not m_objVirtualSort Is Nothing Then jj = m_nVirtualIndex(j)
       RaiseEvent VirtualModeSetFlags(jj, 1, ((j = m_nHlRow) And 1&))
      Next j
     Else
      For i = 1 To m_nColumns
       For j = 1 To m_nRows
        With m_sData(i, j)
         .nFlags = (.nFlags And &HFFFFFFFE) Or ((j = m_nHlRow) And 1&)
        End With
       Next j
      Next i
     End If
     m_nSelColumn = m_nHlColumn
     m_nSelRow = m_nHlRow
     RaiseEvent Click(m_nSelRow, m_nSelColumn)
    End If
   Else
    If (Shift And vbShiftMask) <> 0 And m_nSelRow > 0 And m_nSelRow <= m_nRows _
    And m_nSelColumn > 0 And m_nSelColumn <= m_nColumns And m_bMultiSelect And Button = 1 Then
     If m_nHlRow < m_nSelRow Then
      m = m_nHlRow
      n = m_nSelRow
     Else
      m = m_nSelRow
      n = m_nHlRow
     End If
     If m_nHlColumn < m_nSelColumn Then
      m2 = m_nHlColumn
      n2 = m_nSelColumn
     Else
      m2 = m_nSelColumn
      n2 = m_nHlColumn
     End If
     For i = m2 To n2
      For j = m To n
       If m_bVirtual Then
        jj = j
        If Not m_objVirtualSort Is Nothing Then jj = m_nVirtualIndex(j)
        RaiseEvent VirtualModeSetFlags(jj, i, 1)
       Else
        With m_sData(i, j)
         .nFlags = .nFlags Or 1&
        End With
       End If
      Next j
     Next i
    ElseIf (Shift And vbCtrlMask) <> 0 And m_bMultiSelect And Button = 1 Then
     If m_bVirtual Then
      i = 0
      jj = m_nHlRow
      If Not m_objVirtualSort Is Nothing Then jj = m_nVirtualIndex(jj)
      RaiseEvent VirtualModeGetFlags(jj, m_nHlColumn, i)
      RaiseEvent VirtualModeSetFlags(jj, m_nHlColumn, i Xor 1&)
     Else
      With m_sData(m_nHlColumn, m_nHlRow)
       .nFlags = .nFlags Xor 1&
      End With
     End If
     m_nSelColumn = m_nHlColumn
     m_nSelRow = m_nHlRow
     RaiseEvent Click(m_nSelRow, m_nSelColumn)
    ElseIf Not m_bMultiSelect Or Button = 1 Then '?
     If m_bVirtual Then
      For i = 1 To m_nColumns
       For j = 1 To m_nRows
        jj = j
        If Not m_objVirtualSort Is Nothing Then jj = m_nVirtualIndex(j)
        RaiseEvent VirtualModeSetFlags(jj, i, ((i = m_nHlColumn And j = m_nHlRow) And 1&))
       Next j
      Next i
     Else
      For i = 1 To m_nColumns
       For j = 1 To m_nRows
        With m_sData(i, j)
         .nFlags = (.nFlags And &HFFFFFFFE) Or ((i = m_nHlColumn And j = m_nHlRow) And 1&)
        End With
       Next j
      Next i
     End If
     m_nSelColumn = m_nHlColumn
     m_nSelRow = m_nHlRow
     RaiseEvent Click(m_nSelRow, m_nSelColumn)
    End If
   End If
   'raise event
   RaiseEvent MouseDown(Button, Shift, xCur, yCur, m_nLastLeft, m_nLastTop, m_nLastWidth, m_nItemHeight, m_nHlRow, m_nHlColumn)
'   'TODO: editable?
'   If (Shift = 0 Or Not m_bMultiSelect) And m_nSelRow = m_nHlRow And m_nHlRow > 0 And m_nHlRow <= m_nRows And Button = 1 Then
'    If (m_nSelColumn = m_nHlColumn Or m_bRowMode) And m_nHlColumn > 0 And m_nHlColumn <= m_nColumns Then
'     If m_tHdr(m_nHlColumn).nFlags And 128& Then
'      '///
'      ScreenToClient hwnd, p ':-3
'      p.x = m_nLastLeft - p.x
'      p.y = m_nLastTop - p.y
'      ScreenToClient ContainerHwnd, p
'      'raise event
'      RaiseEvent BeginEdit(p.x, p.y, m_nLastWidth, m_nItemHeight, m_nHlRow, m_nHlColumn, False)
'      'TODO:etc.
'     End If
'    End If
'   End If
  End If
  '///
 End If
 m_nHlColumn_Old = m_nHlColumn
 m_nHlRow_Old = m_nHlRow
End If
End Sub

Friend Property Get Locked() As Boolean
Locked = m_bLocked
End Property

Friend Property Let Locked(ByVal b As Boolean)
If m_bLocked <> b Then
 m_bLocked = b
End If
End Property

Friend Property Get MinColumnSize() As Long
MinColumnSize = m_nMinSize
End Property

Friend Property Let MinColumnSize(ByVal n As Long)
m_nMinSize = n
Refresh
End Property

Private Sub Class_Initialize()
m_nItemHeight = 16&
'm_bHeader = True
m_nMinSize = 64&
'///
m_nRowMax = 0
m_nRowStep = 256&
'///
Refresh
'///
m_nSmallChange(0) = 16&
m_nSmallChange(1) = m_nItemHeight
m_bScrollChanged = True
End Sub

Friend Sub Refresh()
Dim i As Long, j As Long
Dim w As Long, h As Long
Dim ww As Long, hh As Long
'///
'For j = 1 To 2 '????????
 ww = m_nWidth
 hh = m_nHeight
 '///calc width
 w = 0
 For i = 1 To m_nColumns
  With m_tHdr(i)
   .nLeft = w
   If (.nFlags And 8&) = 0 Then
    If .nWidth = 0 Then
     If i = m_nColumns Then
      If w + m_nMinSize >= ww Then w = w + m_nMinSize Else w = ww - 1
     Else
      w = w + m_nMinSize
     End If
    Else
     w = w + .nWidth
    End If
   End If
  End With
 Next i
 '///calc height :-3
 h = m_nRows * m_nItemHeight
 '///??
 w = w + 1
 h = h + 1
 m_nTotalWidth = w
 m_nTotalHeight = h
 '/// TODO:
' i = (w > ww Xor sb1.Enabled(efsHorizontal)) Or (h > hh Xor sb1.Enabled(efsVertical))
' If w > ww Then
'  sb1.Enabled(efsHorizontal) = True
'  sb1.Max(efsHorizontal) = w - ww
'  sb1.LargeChange(efsHorizontal) = ww
' Else
'  sb1.Enabled(efsHorizontal) = False
'  sb1.Max(efsHorizontal) = 0
' End If
' If h > hh Then
'  sb1.Enabled(efsVertical) = True
'  sb1.Max(efsVertical) = h - hh
'  sb1.LargeChange(efsVertical) = hh
' Else
'  sb1.Enabled(efsVertical) = False
'  sb1.Max(efsVertical) = 0
' End If
' If i = 0 Then Exit For
'Next j
'///
End Sub

Friend Sub pDrawGridLine(Optional ByVal nLeft As Single, Optional ByVal nTop As Single, Optional ByVal nOpacity As Single = 1)
Dim i As Long, k As Long
Dim x As Long, xx As Long, y As Long, w As Long
'///
Dim f() As Single, m As Long, m2 As Long
'///
k = m_nScrollValue(1) \ m_nItemHeight
y = k * m_nItemHeight - m_nScrollValue(1)
Do
 If m + 8 >= m2 Then
  m2 = m2 + 1024&
  ReDim Preserve f(m2 - 1)
 End If
 f(m) = nLeft
 f(m + 1) = nTop + y
 f(m + 3) = 1
 f(m + 4) = nLeft + m_nWidth
 f(m + 5) = f(m + 1)
 f(m + 7) = 1
 m = m + 8
 y = y + m_nItemHeight
Loop Until y >= m_nHeight
x = m_nScrollValue(0)
xx = -1
For i = 1 To m_nColumns
 With m_tHdr(i)
  If (.nFlags And 8&) = 0 Then
   w = .nWidth
   If w = 0 Then
    If i = m_nColumns Then
     w = m_nWidth - .nLeft + x
    Else
     w = m_nMinSize
    End If
   End If
   If .nLeft < x + m_nWidth And .nLeft + w > x Then
    If m + 8 >= m2 Then
     m2 = m2 + 1024&
     ReDim Preserve f(m2 - 1)
    End If
    xx = nLeft + .nLeft - x
    f(m) = xx
    f(m + 1) = nTop
    f(m + 3) = 1
    f(m + 4) = xx
    f(m + 5) = nTop + m_nHeight
    f(m + 7) = 1
    m = m + 8
    xx = xx + w
   End If
  End If
 End With
Next i
'///
If xx >= 0 Then
 If m + 8 >= m2 Then
  m2 = m2 + 1024&
  ReDim Preserve f(m2 - 1)
 End If
 f(m) = xx
 f(m + 1) = nTop
 f(m + 3) = 1
 f(m + 4) = xx
 f(m + 5) = nTop + m_nHeight
 f(m + 7) = 1
 m = m + 8
End If
'///
If m > 0 Then
 i = nOpacity * 255
 i = ((i And &H7F&) * &H1000000) Or ((i > &H7F&) And &H80000000)
 d3dd9.SetTextureStageState 0, D3DTSS_COLOROP, D3DTOP_SELECTARG2
 d3dd9.SetTextureStageState 0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG2
 d3dd9.SetTextureStageState 0, D3DTSS_COLORARG2, D3DTA_CONSTANT
 d3dd9.SetTextureStageState 0, D3DTSS_ALPHAARG2, D3DTA_CONSTANT
 d3dd9.SetTextureStageState 0, D3DTSS_CONSTANT, i Or &H999999
 d3dd9.SetFVF D3DFVF_XYZRHW
 d3dd9.DrawPrimitiveUP D3DPT_LINELIST, m \ 8&, f(0), 16&
 d3dd9.SetTextureStageState 0, D3DTSS_COLOROP, D3DTOP_MODULATE
 d3dd9.SetTextureStageState 0, D3DTSS_ALPHAOP, D3DTOP_MODULATE
 d3dd9.SetTextureStageState 0, D3DTSS_COLORARG2, D3DTA_DIFFUSE
 d3dd9.SetTextureStageState 0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE
End If
'///
End Sub

Friend Sub Render(Optional ByVal nLeft As Single, Optional ByVal nTop As Single, Optional ByVal nOpacity As Single = 1)
On Error Resume Next
Dim i As Long, j As Long, jj As Long, k As Long
Dim kk As Long, kkk As Long, kkkk As Long, kkkkk As Long
Dim x As Long, y As Long, w As Long
Dim r As RECT
Dim clr As Long, clr0 As Long
Dim s As String, b As Boolean
Dim bHighlight As Boolean, bSelected As Boolean
Dim r2 As RECT, r3 As RECT
Dim f As Single
'///grid line
If m_bGrid Then pDrawGridLine nLeft, nTop, nOpacity
'///list item
clr0 = nOpacity * 255
clr0 = ((clr0 And &H7F&) * &H1000000) Or ((clr0 > &H7F&) And &H80000000)
clr = clr0 Or (&H666666 And Not m_bEnabled)
'///
k = m_nScrollValue(1) \ m_nItemHeight
x = m_nScrollValue(0)
r2.Left = &H80000000
r3.Left = &H80000000
For i = 1 To m_nColumns
 With m_tHdr(i)
  If (.nFlags And 8&) = 0 Then
   w = .nWidth
   If w = 0 Then
    If i = m_nColumns Then
     w = m_nWidth - .nLeft + x - 1 '???
     If w < m_nMinSize Then w = m_nMinSize '???
    Else
     w = m_nMinSize
    End If
   End If
   If .nLeft < x + m_nWidth And .nLeft + w > x Then
    y = k * m_nItemHeight - m_nScrollValue(1)
    If m_bHeader Then y = y + m_nItemHeight
    For j = k + 1 To m_nRows
     '////////draw item data
     If m_bVirtual Then
      If Not m_objVirtualSort Is Nothing Then jj = m_nVirtualIndex(j) Else jj = j
     End If
     '///highlight and selection
     If Not m_bLocked Then
      bHighlight = j = m_nHlRow And (m_bRowMode Or i = m_nHlColumn)
      bSelected = j = m_nSelRow And (m_bRowMode Or i = m_nSelColumn)
      'TODO:get flags
      If m_bVirtual Then
       kk = 0
       RaiseEvent VirtualModeGetFlags(jj, i, kk)
      Else
       kk = m_sData(i, j).nFlags
      End If
      'fill new:animation TODO:animation with virtual mode
      kkk = m_sData(i, j).bAnimVal1
      If bHighlight Then
       If (kkk And &HF&) < 5 Then kkk = kkk + 1
      Else
       If (kkk And &HF&) > 0 Then kkk = kkk - 1
      End If
      If (bSelected And Not m_bMultiSelect) Or (kk And 1&) <> 0 Then
       If kkk < &H50& Then kkk = kkk + &H10&
      Else
       If kkk >= &H10& Then kkk = kkk - &H10&
      End If
      m_sData(i, j).bAnimVal1 = kkk
      If kkk Then
       r.Left = .nLeft - x + nLeft
       r.Top = y + nTop
       r.Right = r.Left + w
       r.Bottom = r.Top + m_nItemHeight
       If m_bGrid Then r.Left = r.Left + 1: r.Top = r.Top + 1
       '///
       kkkk = (kkk And &HF&) * 51&
       If kkkk Then
        kkkkk = nOpacity * kkkk
        kkkkk = ((kkkkk And &H7F&) * &H1000000) Or ((kkkkk > &H7F&) And &H80000000) Or &HFFFFFF
        FakeDXGDIStretchBltColored r.Left, r.Top, r.Right, r.Bottom, 166, 416, 166, 448, 512, kkkkk
       End If
       '///
       kkk = (kkk \ &H10&) * 51&
       If kkk Then
        kkkkk = nOpacity * kkk
        kkkkk = ((kkkkk And &H7F&) * &H1000000) Or ((kkkkk > &H7F&) And &H80000000) Or &HFFFFFF
        FakeDXGDIStretchBltBlended r.Left, r.Top, r.Right, r.Bottom, 174, 416, 174, 448, 512, 170, 416, kkkk, kkkkk
       End If
      End If
      'save border data
      If bHighlight Then
       If m_bRowMode And m_nColumns > 1 Then
        If r2.Left = &H80000000 Then
         r2.Left = .nLeft - x
         r2.Top = y
         r2.Bottom = y + m_nItemHeight + 1
        End If
        r2.Right = .nLeft - x + w + 1
       Else
        r2.Left = .nLeft - x
        r2.Top = y
        r2.Right = r2.Left + w + 1
        r2.Bottom = r2.Top + m_nItemHeight + 1
       End If
      ElseIf bSelected Then '?
       If m_bRowMode And m_nColumns > 1 Then
        If r3.Left = &H80000000 Then
         r3.Left = .nLeft - x
         r3.Top = y
         r3.Bottom = y + m_nItemHeight + 1
        End If
        r3.Right = .nLeft - x + w + 1
       Else
        r3.Left = .nLeft - x
        r3.Top = y
        r3.Right = r3.Left + w + 1
        r3.Bottom = y + m_nItemHeight + 1
       End If
      End If
     End If
     '////////contents
     If m_bVirtual Then
      s = vbNullString
      RaiseEvent VirtualModeGetValue(jj, i, s)
     Else
      s = m_sData(i, j).sValue
     End If
     If .nFlags And 4& Then
      'ownerdraw
      b = False
      If m_bVirtual Then
       kk = 0
       RaiseEvent VirtualModeGetItemData(jj, i, kk)
      Else
       kk = m_sData(i, j).nItemData
      End If
      RaiseEvent OwnerDraw(0, 0, 0, .nLeft - x, y, w, m_nItemHeight, j, i, m_bPressed, s, kk, b)
     Else
      b = True
     End If
     If b Then
      Select Case .nDataType
      Case 2, 4
       'checkbox
       r.Right = Val(s)
       If r.Right < 0 Or r.Right > 2 Then r.Right = 2
       If i = m_nHlColumn And j = m_nHlRow Then
        If m_bPressed Then r.Bottom = 2 Else r.Bottom = 1
       Else
        r.Bottom = 0
       End If
       '///new:animation TODO:animation with virtual mode
       kkk = m_sData(i, j).bAnimVal2
       If r.Right = 1 Then
        If (kkk And &HF&) < 5 Then kkk = kkk + 1
       Else
        If (kkk And &HF&) > 0 Then kkk = kkk - 1
       End If
       If r.Right = 2 Then
        If kkk < &H50& Then kkk = kkk + &H10&
       Else
        If kkk >= &H10& Then kkk = kkk - &H10&
       End If
       r.Right = kkk
       m_sData(i, j).bAnimVal2 = kkk
       '///
       kkk = m_sData(i, j).bAnimVal3
       If r.Bottom > 0 Then
        If (kkk And &HF&) < 5 Then kkk = kkk + 1
       Else
        If (kkk And &HF&) > 0 Then kkk = kkk - 1
       End If
       If r.Bottom > 1 Then
        If kkk < &H50& Then kkk = kkk + &H10&
       Else
        If kkk >= &H10& Then kkk = kkk - &H10&
       End If
       r.Bottom = kkk
       m_sData(i, j).bAnimVal3 = kkk
       '///
       pDrawCheck nOpacity, nLeft + .nLeft - x + w \ 2 - 8, nTop + y + m_nItemHeight \ 2 - 8, r.Right, r.Bottom
      Case Else
       If .nFlags And 32& Then kk = DT_RIGHT Else If .nFlags And 64& Then kk = DT_CENTER Else kk = 0
       FakeDXGDIDrawText FakeDXUIDefaultFont, s, nLeft + .nLeft - x + 2, nTop + y, w - 4, m_nItemHeight, 0.5, DT_VCENTER Or DT_SINGLELINE Or kk, clr, , , , , , , True
      End Select
     End If
     '////////
     y = y + m_nItemHeight
     If y >= m_nHeight Then Exit For
    Next j
   End If
  End If
 End With
Next i
'///selection border
If r2.Left <> &H80000000 Then
 FakeDXGDIStretchBltExColored r2.Left + nLeft, r2.Top + nTop, r2.Right + nLeft, r2.Bottom + nTop, 232, 48, 248, 64, 4, 4, 4, 4, 512, clr0 Or &HFFFFFF
End If
If r3.Left <> &H80000000 Then
 FakeDXGDIStretchBltExColored r3.Left + nLeft, r3.Top + nTop, r3.Right + nLeft, r3.Bottom + nTop, 232, 48, 248, 64, 4, 4, 4, 4, 512, clr0 Or &HFFFFFF
End If
'///header
If m_bHeader Then
 r.Right = 0
 '///
 For i = 1 To m_nColumns
  With m_tHdr(i)
   If (.nFlags And 8&) = 0 Then
    w = .nWidth
    If w = 0 Then
     If i = m_nColumns Then
      w = m_nWidth - .nLeft + x - 1 '???
      If w < m_nMinSize Then w = m_nMinSize '???
     Else
      w = m_nMinSize
     End If
    End If
    If .nLeft < x + m_nWidth And .nLeft + w > x Then
     'draw header
     r.Left = nLeft + .nLeft - x
     r.Top = nTop
     r.Right = r.Left + w
     r.Bottom = nTop + m_nItemHeight
     FakeDXGDIStretchBltExColored r.Left, r.Top, r.Right, r.Bottom, 0, 420, 32, 448, 4, 0, 4, 4, 512, clr0 Or &HFFFFFF
     'highlight
     If m_nHlColumn = i And m_nHlRow = 0 Then
      If .bAnimVal1 < 255 Then .bAnimVal1 = .bAnimVal1 + 51
      If m_bPressed Then
       If .bAnimVal2 < 255 Then .bAnimVal2 = .bAnimVal2 + 51
      Else
       If .bAnimVal2 > 0 Then .bAnimVal2 = .bAnimVal2 - 51
      End If
     Else
      If .bAnimVal1 > 0 Then .bAnimVal1 = .bAnimVal1 - 51
      If .bAnimVal2 > 0 Then .bAnimVal2 = .bAnimVal2 - 51
     End If
     If .bAnimVal1 > 0 Then
      k = .bAnimVal1 * nOpacity
      k = ((k And &H7F&) * &H1000000) Or ((k > &H7F&) And &H80000000)
      FakeDXGDIStretchBltExBlended r.Left, r.Top, r.Right, r.Bottom, 64, 420, 96, 448, 4, 0, 4, 4, 512, 32, 420, .bAnimVal2, k Or &HFFFFFF
     End If
     'draw text and sort icon
     If .nFlags And 32& Then
      If i = (m_nSortIndex And &HFFFFFF) Then
       FakeDXGDIDrawText FakeDXUIDefaultFont, .sCaption, r.Left + 2, r.Top, w - 14, m_nItemHeight, 0.5, DT_VCENTER Or DT_SINGLELINE Or DT_RIGHT, clr, , , , , , , True
       pDrawArrow r.Left + w - 7, r.Top + m_nItemHeight \ 2, nOpacity, m_bEnabled, m_nSortIndex And &H1000000
      Else
       FakeDXGDIDrawText FakeDXUIDefaultFont, .sCaption, r.Left + 2, r.Top, w - 4, m_nItemHeight, 0.5, DT_VCENTER Or DT_SINGLELINE Or DT_RIGHT, clr, , , , , , , True
      End If
     ElseIf .nFlags And 64& Then
      If i = (m_nSortIndex And &HFFFFFF) Then
       GetTextExtentPoint32W FakeDXUIDefaultFont.objFont.GetDC, ByVal StrPtr(.sCaption), -1, r3
       r.Right = r3.Left \ 2
       If r.Right >= w - 14 Then r.Right = w - 14
       FakeDXGDIDrawText FakeDXUIDefaultFont, .sCaption, r.Left + 2, r.Top, w - 14, m_nItemHeight, DT_VCENTER Or DT_SINGLELINE Or DT_CENTER, clr, , , , , , , , True
       pDrawArrow r.Left + (w + r.Right) \ 2, r.Top + m_nItemHeight \ 2, nOpacity, m_bEnabled, m_nSortIndex And &H1000000
      Else
       FakeDXGDIDrawText FakeDXUIDefaultFont, .sCaption, r.Left + 2, r.Top, w - 4, m_nItemHeight, 0.5, DT_VCENTER Or DT_SINGLELINE Or DT_CENTER, clr, , , , , , , True
      End If
     Else
      If i = (m_nSortIndex And &HFFFFFF) Then
       FakeDXGDIDrawText FakeDXUIDefaultFont, .sCaption, r.Left + 2, r.Top, w - 4, m_nItemHeight, 0.5, DT_VCENTER Or DT_SINGLELINE Or DT_CALCRECT, clr, , , , , , , True, f
       If f > w - 14 Then f = w - 14
       pDrawArrow r.Left + f + 7, r.Top + m_nItemHeight \ 2, nOpacity, m_bEnabled, m_nSortIndex And &H1000000
      Else
       FakeDXGDIDrawText FakeDXUIDefaultFont, .sCaption, r.Left + 2, r.Top, w - 4, m_nItemHeight, 0.5, DT_VCENTER Or DT_SINGLELINE, clr, , , , , , , True
      End If
     End If
    End If
   End If
  End With
 Next i
 '///
 If r.Right < nLeft + m_nWidth Then
  r.Left = r.Right
  r.Top = nTop
  r.Right = nLeft + m_nWidth + 8
  r.Bottom = nTop + m_nItemHeight
  FakeDXGDIStretchBltExColored r.Left, r.Top, r.Right, r.Bottom, 0, 420, 32, 448, 4, 0, 4, 4, 512, clr0 Or &HFFFFFF
 End If
 '///
End If
End Sub

Friend Function OnKeyEvent(ByVal KeyCode As Long, ByVal Shift As Long, ByVal nEventType As Long) As Boolean
If Not m_bEnabled Then Exit Function
Select Case nEventType
Case 0 'keypress
Case 1 'keydown
 RaiseEvent KeyDown(KeyCode, Shift)
Case 2 'keyup
 RaiseEvent KeyUp(KeyCode, Shift)
End Select
OnKeyEvent = True
End Function

Friend Function OnMouseEvent(ByVal Button As Long, ByVal Shift As Long, ByVal xClient As Single, ByVal yClient As Single, ByVal nEventType As Long) As Boolean
Dim bInControl As Boolean
If Not m_bEnabled Then Exit Function
bInControl = xClient >= 0 And xClient < m_nWidth And yClient >= 0 And yClient < m_nHeight
Select Case nEventType
Case 0 'mousemove
 If (m_bCapture And Button = 1) Or (bInControl And Button <> 1) Then
  OnMouseMove Button, Shift, xClient, yClient
  OnMouseEvent = True
 End If
Case 1 'mousedown
 If bInControl Then
  OnMouseDown Button, Shift, xClient, yClient
  If Button = 1 Then m_bCapture = True
  OnMouseEvent = True
 End If
Case 2 'mouseup
 If (m_bCapture And Button = 1) Or (bInControl And Button <> 1) Then
  OnMouseUp Button, Shift, xClient, yClient
  If Button = 1 Then m_bCapture = False
  OnMouseEvent = True
 End If
Case 4 'dblclick
 If bInControl Then
  '///
  If m_nHlColumn > 0 And m_nHlColumn <= m_nColumns Then
   If m_nHlRow > 0 And m_nHlRow <= m_nRows Then
    RaiseEvent DblClick(m_nHlRow, m_nHlColumn)
   Else
    'header double click
    'TODO:
   End If
  End If
  '///
  OnMouseEvent = True
 End If
End Select
End Function
 
