VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsBloxorz"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Declare Sub ZeroMemory Lib "kernel32.dll" Alias "RtlZeroMemory" (ByRef Destination As Any, ByVal Length As Long)
Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)
Private Declare Function GetTickCount Lib "kernel32.dll" () As Long

Private Const TheSignature = "Ò¡·½¿éXP"

Private Type typeBridge
 x As Long
 y As Long
 Behavior As Long
 '0=Off
 '1=0n
 '2=toggle
End Type

Private Type typeSwitch
 bc As Long
 bs() As typeBridge
End Type

Private dat() As Byte
'0=empty        =space
'1=block        =b
'2=soft         =s
'3=heavy        =h
'4=transport    =v
'5=thin         =f
'6=bridge off   =lr
'7=bridge on    =kq
'8=end          =e
'======new!!!======
'9=ice
'10=pyramid
'11=stone

Private dat2() As Long

Private sws() As typeSwitch, swc As Long

Private datw As Long, dath As Long '<=255 :-/

Public StartX As Long, StartY As Long
'Public NowX As Long, NowY As Long, NowState As Long '0=up,1=h,2=v,3=single
'Public NowX2 As Long, NowY2 As Long

Private Type typeSolveItPos
 x As Integer
 y As Integer
End Type

Private Type typeSolveItSwitchIdPos
 Count As Long
 AllPosCount As Long
 AllPosDelta As Long
 p() As typeSolveItPos
End Type

Private Type typeSolveItNode
 PrevNode As Long
 NextNode As Long
 Distance As Long
 PathPrevNode As Long
 Edges(1 To 8) As Long
End Type

Private SwitchMap() As Byte, SwitchMapPosId() As Long, SwitchMapIdPos() As typeSolveItSwitchIdPos, SwitchStatusCount As Long, IsTrans As Boolean
Private GTheoryNode() As typeSolveItNode, GTheoryNodeCount As Long

Public Property Get Width() As Long
Width = datw
End Property

Public Property Get Height() As Long
Height = dath
End Property

Public Sub Create(ByVal w As Long, ByVal h As Long)
If w > 0 And h > 0 Then
 Destroy
 datw = w
 dath = h
 ReDim dat(1 To w, 1 To h)
 ReDim dat2(1 To w, 1 To h)
End If
End Sub

Public Sub Clear()
Dim m As Long
If datw > 0 And dath > 0 Then
 m = datw * dath
 ZeroMemory dat(1, 1), m
 ZeroMemory dat2(1, 1), m
 StartX = 1
 StartY = 1
End If
ClearSwitch
SolveItClear
End Sub

Public Sub Destroy()
datw = 0
dath = 0
Erase dat, dat2
StartX = 1
StartY = 1
ClearSwitch
SolveItClear
End Sub

Public Property Get Data(ByVal x As Long, ByVal y As Long) As Long
Data = dat(x, y)
End Property

Public Property Let Data(ByVal x As Long, ByVal y As Long, ByVal n As Long)
dat(x, y) = n
End Property

Public Property Get Data2(ByVal x As Long, ByVal y As Long) As Long
Data2 = dat2(x, y)
End Property

Public Property Let Data2(ByVal x As Long, ByVal y As Long, ByVal n As Long)
dat2(x, y) = n
End Property

Public Sub GetTransportPosition(ByVal x As Long, ByVal y As Long, ByRef x1 As Long, ByRef y1 As Long, ByRef x2 As Long, ByRef y2 As Long)
Dim n As Long
x1 = 0
y1 = 0
x2 = 0
y2 = 0
n = VarPtr(dat2(x, y))
CopyMemory x1, ByVal n, 1&
CopyMemory y1, ByVal (n + 1), 1&
CopyMemory x2, ByVal (n + 2), 1&
CopyMemory y2, ByVal (n + 3), 1&
End Sub

Public Sub SetTransportPosition(ByVal x As Long, ByVal y As Long, ByVal x1 As Long, ByVal y1 As Long, ByVal x2 As Long, ByVal y2 As Long)
Dim n As Long
n = VarPtr(dat2(x, y))
CopyMemory ByVal n, x1, 1&
CopyMemory ByVal (n + 1), y1, 1&
CopyMemory ByVal (n + 2), x2, 1&
CopyMemory ByVal (n + 3), y2, 1&
End Sub

Public Property Get SwitchCount() As Long
SwitchCount = swc
End Property

Public Sub ClearSwitch()
Dim i As Long, j As Long
Erase sws
swc = 0
For i = 1 To datw
 For j = 1 To dath
  Select Case dat(i, j)
  Case 2, 3
   dat2(i, j) = 0
  End Select
 Next j
Next i
End Sub

Public Sub AddSwitch()
swc = swc + 1
ReDim Preserve sws(1 To swc)
End Sub

Public Sub RemoveSwitch(ByVal Index As Long)
Dim i As Long, j As Long
If swc <= 1 Then
 ClearSwitch
 Exit Sub
End If
swc = swc - 1
For i = Index To swc
 sws(i) = sws(i + 1)
Next i
ReDim Preserve sws(1 To swc)
For i = 1 To datw
 For j = 1 To dath
  Select Case dat(i, j)
  Case 2, 3
   If dat2(i, j) >= Index Then dat2(i, j) = dat2(i, j) - 1
  End Select
 Next j
Next i
End Sub

Public Property Get SwitchBridgeCount(ByVal Index As Long) As Long
SwitchBridgeCount = sws(Index).bc
End Property

Public Property Let SwitchBridgeCount(ByVal Index As Long, ByVal n As Long)
With sws(Index)
 .bc = n
 If n > 0 Then
  ReDim Preserve .bs(1 To .bc)
 Else
  Erase .bs
 End If
End With
End Property

Public Sub AddSwitchBridge(ByVal Index As Long, Optional ByVal x As Long, Optional ByVal y As Long, Optional ByVal Behavior As Long)
With sws(Index)
 .bc = .bc + 1
 ReDim Preserve .bs(1 To .bc)
 With .bs(.bc)
  .x = x
  .y = y
  .Behavior = Behavior
 End With
End With
End Sub

Public Sub ClearSwitchBridge(ByVal Index As Long)
With sws(Index)
 Erase .bs
 .bc = 0
End With
End Sub

Public Sub RemoveSwitchBridge(ByVal Index As Long, ByVal i As Long)
With sws(Index)
 If .bc <= 1 Then
  Erase .bs
  .bc = 0
 Else
  If i < .bc Then CopyMemory .bs(i), .bs(i + 1), 12& * (.bc - i)
  .bc = .bc - 1
  ReDim Preserve .bs(1 To .bc)
 End If
End With
End Sub

Public Property Get SwitchBridgeX(ByVal Index As Long, ByVal i As Long) As Long
SwitchBridgeX = sws(Index).bs(i).x
End Property

Public Property Let SwitchBridgeX(ByVal Index As Long, ByVal i As Long, ByVal n As Long)
sws(Index).bs(i).x = n
End Property

Public Property Get SwitchBridgeY(ByVal Index As Long, ByVal i As Long) As Long
SwitchBridgeY = sws(Index).bs(i).y
End Property

Public Property Let SwitchBridgeY(ByVal Index As Long, ByVal i As Long, ByVal n As Long)
sws(Index).bs(i).y = n
End Property

Public Property Get SwitchBridgeBehavior(ByVal Index As Long, ByVal i As Long) As Long
SwitchBridgeBehavior = sws(Index).bs(i).Behavior
End Property

Public Property Let SwitchBridgeBehavior(ByVal Index As Long, ByVal i As Long, ByVal n As Long)
sws(Index).bs(i).Behavior = n
End Property

Private Sub Class_Terminate()
Destroy
End Sub

Friend Sub fOptimizeSwitch()
Dim i As Long, j As Long, k As Long, l As Long
Dim d() As Byte, b As Boolean
i = 2
Do Until i > swc
 b = False
 With sws(i)
  For j = 1 To i - 1
   If .bc = sws(j).bc Then
    If .bc = 0 Then
     b = True
     Exit For
    End If
    ReDim d(1 To .bc)
    For k = 1 To .bc
     For l = 1 To .bc
      If d(l) = 0 Then
       If .bs(k).x = sws(j).bs(l).x Then
        If .bs(k).y = sws(j).bs(l).y Then
         If .bs(k).Behavior = sws(j).bs(l).Behavior Then
          d(l) = d(l) + 1
          Exit For
         End If
        End If
       End If
      End If
     Next l
    Next k
    b = True
    For k = 1 To .bc
     If d(k) <> 1 Then
      b = False
      Exit For
     End If
    Next k
    If b Then Exit For
   End If
  Next j
 End With
 If b Then
  swc = swc - 1
  For k = i To swc
   sws(k) = sws(k + 1)
  Next k
  ReDim Preserve sws(1 To swc)
  For k = 1 To datw
   For l = 1 To dath
    Select Case dat(k, l)
    Case 2, 3
     If dat2(k, l) = i Then
      dat2(k, l) = j
     ElseIf dat2(k, l) > i Then
      dat2(k, l) = dat2(k, l) - 1
     End If
    End Select
   Next l
  Next k
 Else
  i = i + 1
 End If
Loop
End Sub

Friend Sub fLoadText()
'Dim obj As New clsTheFile
'Dim s As String, s1 As String, b() As Byte
'Dim ss() As String
'Dim i As Long, j As Long, k As Long, m As Long
'Dim x1 As Long, y1 As Long, x2 As Long, y2 As Long
'Dim lps As Long, lpe As Long
'Dim lv As Long
'Dim levels  As Variant
'levels = Array("levelez", "levelpq", "levelji", "levelwe", "levelxx", "levelgg", "levelfr", "levelss", "levelre", "levelpp", "leveldw", "levelgt", "levelsb", "levelub", "levelht", "levelis", "leveltw", "levelsc", "levelpb", "leveltb", "levelmn", "levellh", "leveltt", "levelkn", "leveldd", "levelhg", "levelvh", "levelfm", "levelmp", "levelgv", "levelkc", "leveled", "levelol")
'Open CStr(App.Path) + "\mainmovie_frame15.as" For Binary As #1
'm = LOF(1)
'ReDim b(1 To m)
'Get #1, 1, b
'Close
's = StrConv(b, vbUnicode)
's = Replace(s, vbCrLf, vbCr)
's = Replace(s, vbLf, vbCr)
'ss = Split(s, vbCr)
'Erase b
'k = 0
'Do Until k >= UBound(ss)
' s = ss(k)
' If InStr(1, s, "[]") > 0 Then
'  lps = InStr(1, s, "=")
'  s1 = Trim(Left(s, lps - 1))
'  For lv = 0 To UBound(levels)
'   If StrComp(levels(lv), s1, vbTextCompare) = 0 Then Exit For
'  Next lv
'  If lv <= UBound(levels) Then
'   lv = lv + 1
'   Create 15, 10
'   For j = 1 To 10
'    s = ss(k + j)
'    lps = InStr(1, s, """")
'    For i = 1 To 15
'     Select Case LCase(Mid(s, lps + i, 1))
'     Case " "
'      m = 0
'     Case "b"
'      m = 1
'     Case "s"
'      m = 2
'     Case "h"
'      m = 3
'     Case "v"
'      m = 4
'     Case "f"
'      m = 5
'     Case "l", "r"
'      m = 6
'     Case "k", "q"
'      m = 7
'     Case "e"
'      m = 8
'     Case Else
'      Debug.Assert False
'     End Select
'     dat(i, j) = m
'    Next i
'   Next j
'   k = k + 11
'   'start
'   s = ss(k)
'   lps = InStr(1, s, "[")
'   s = Mid(s, lps + 1)
'   lps = InStr(1, s, ",")
'   StartX = 1 + Val(Left(s, lps - 1))
'   StartY = 1 + Val(Mid(s, lps + 1))
'   'button
'   s = ss(k + 1)
'   lps = 0
'   Do
'    lps = InStr(lps + 1, s, "swatch", vbTextCompare)
'    If lps = 0 Then Exit Do
'    lpe = InStr(lps, s, ":")
'    If lpe - lps = 9 Then
'     i = 1 + Val(Mid(s, lpe - 3, 2))
'     j = 1 + Val(Mid(s, lpe - 1, 1))
'    ElseIf lpe - lps = 8 Then
'     i = 1 + Val(Mid(s, lpe - 2, 1))
'     j = 1 + Val(Mid(s, lpe - 1, 1))
'    Else
'     Debug.Assert False
'    End If
'    AddSwitch
'    dat2(i, j) = swc
'    lpe = InStr(lps, s, "]]")
'    lps = InStr(lps, s, "[[")
'    Do
'     lps = InStr(lps + 1, s, "[")
'     If lps > lpe Or lps = 0 Then Exit Do
'     i = 1 + Val(Mid(s, lps + 1))
'     lps = InStr(lps + 1, s, ",")
'     j = 1 + Val(Mid(s, lps + 1))
'     lps = InStr(lps + 1, s, """")
'     Select Case LCase(Mid(s, lps + 1, 3))
'     Case "on""" 'on
'      m = 1
'     Case "off" 'off
'      m = 0
'     Case "ono" 'onoff
'      m = 2
'     Case Else
'      Debug.Assert False
'     End Select
'     AddSwitchBridge swc, i, j, m
'    Loop
'    lps = lpe
'   Loop
'   'trans
'   s = ss(k + 2)
'   lps = 0
'   Do
'    lps = InStr(lps + 1, s, "swatch", vbTextCompare)
'    If lps = 0 Then Exit Do
'    lpe = InStr(lps, s, ":")
'    If lpe - lps = 9 Then
'     i = 1 + Val(Mid(s, lpe - 3, 2))
'     j = 1 + Val(Mid(s, lpe - 1, 1))
'    ElseIf lpe - lps = 8 Then
'     i = 1 + Val(Mid(s, lpe - 2, 1))
'     j = 1 + Val(Mid(s, lpe - 1, 1))
'    Else
'     Debug.Assert False
'    End If
'    lpe = InStr(lps, s, "[")
'    x1 = 1 + Val(Mid(s, lpe + 1))
'    lpe = InStr(lpe + 1, s, ",")
'    y1 = 1 + Val(Mid(s, lpe + 1))
'    lpe = InStr(lpe + 1, s, ",")
'    x2 = 1 + Val(Mid(s, lpe + 1))
'    lpe = InStr(lpe + 1, s, ",")
'    y2 = 1 + Val(Mid(s, lpe + 1))
'    SetTransportPosition i, j, x1, y1, x2, y2
'    lps = lpe
'   Loop
'   'over
'   fOptimizeSwitch
'   SaveLevel lv, obj
'  End If
' End If
' k = k + 1
'Loop
'obj.Signature = TheSignature
'obj.SaveFile CStr(App.Path) + "/Default.box"
End Sub

Public Sub LoadLevel(ByVal lv As Long, d As clsTheFile)
Dim i As Long, lp As Long
Dim b() As Byte
Destroy
i = d.FindNodeArray("LEV")
If i = 0 Then Exit Sub
If d.NodeCount(i) < lv Then Exit Sub
If d.NodeSize(i, lv) = 0 Then Exit Sub
d.GetNodeData i, lv, b
lp = 1
CopyMemory datw, b(lp), 4&
lp = lp + 4
CopyMemory dath, b(lp), 4&
lp = lp + 4
CopyMemory StartX, b(lp), 4&
lp = lp + 4
CopyMemory StartY, b(lp), 4&
lp = lp + 4
If datw > 0 And dath > 0 Then
 ReDim dat(1 To datw, 1 To dath)
 ReDim dat2(1 To datw, 1 To dath)
 i = datw * dath
 CopyMemory dat(1, 1), b(lp), i
 lp = lp + i
 i = i * 4&
 CopyMemory dat2(1, 1), b(lp), i
 lp = lp + i
End If
CopyMemory swc, b(lp), 4&
lp = lp + 4
If swc > 0 Then
 ReDim sws(1 To swc)
 For i = 1 To swc
  With sws(i)
   CopyMemory .bc, b(lp), 4&
   lp = lp + 4
   If .bc > 0 Then
    ReDim .bs(1 To .bc)
    CopyMemory .bs(1), b(lp), .bc * 12&
    lp = lp + .bc * 12&
   End If
  End With
 Next i
End If
End Sub

Public Sub SaveLevel(ByVal lv As Long, d As clsTheFile)
Dim i As Long, m As Long, lp As Long
Dim b() As Byte
'calc max
m = 20 + datw * dath * 5& + swc * 4&
For i = 1 To swc
 m = m + sws(i).bc * 12&
Next i
'copy data
ReDim b(1 To m)
lp = 1
CopyMemory b(lp), datw, 4&
lp = lp + 4&
CopyMemory b(lp), dath, 4&
lp = lp + 4&
CopyMemory b(lp), StartX, 4&
lp = lp + 4&
CopyMemory b(lp), StartY, 4&
lp = lp + 4&
If datw > 0 And dath > 0 Then
 i = datw * dath
 CopyMemory b(lp), dat(1, 1), i
 lp = lp + i
 i = i * 4&
 CopyMemory b(lp), dat2(1, 1), i
 lp = lp + i
End If
CopyMemory b(lp), swc, 4&
lp = lp + 4
If swc > 0 Then
 For i = 1 To swc
  With sws(i)
   CopyMemory b(lp), .bc, 4&
   lp = lp + 4
   If .bc > 0 Then
    CopyMemory b(lp), .bs(1), .bc * 12&
    lp = lp + .bc * 12&
   End If
  End With
 Next i
End If
'save it
i = d.FindNodeArray("LEV")
If i = 0 Then
 d.AddNodeArray "LEV"
 i = d.NodeArrayCount
End If
Do Until d.NodeCount(i) >= lv
 d.AddNode i
Loop
d.SetNodeData i, lv, b
End Sub

Public Function SolveIt(Optional objProgress As PictureBox) As Boolean
Dim SwitchTransTable() As Long, d() As Byte
Dim nd As typeSolveItNode
Dim i As Long, j As Long, jj As Long, k As Long, m As Long
Dim x As Long, y As Long, t As Long
If StartX <= 0 Or StartY <= 0 Or StartX > datw Or StartY > dath Then Exit Function
'calc time
t = GetTickCount
'///////////////////////////////////////////////////Step 1:determine switch
'init
ReDim SwitchMap(1 To datw, 1 To dath, 1 To 1)
ReDim SwitchMapPosId(1 To datw, 1 To dath, 1 To 1)
ReDim SwitchMapIdPos(1 To 1)
SwitchStatusCount = 1
m = datw * dath
CopyMemory SwitchMap(1, 1, 1), dat(1, 1), m
If swc > 0 Then 'calc
 ReDim SwitchTransTable(1 To swc, 1 To 1)
 ReDim d(1 To datw, 1 To dath)
 i = 1
 Do Until i > SwitchStatusCount
  'calc pos
  pSolveItCalcPos i
  'press all button
  For j = 1 To swc
   CopyMemory d(1, 1), SwitchMap(1, 1, i), m
   With sws(j)
    For k = 1 To .bc
     With .bs(k)
      If .x > 0 And .y > 0 And .x <= datw And .y <= dath Then
       Select Case .Behavior
       Case 0 'off
        d(.x, .y) = 6
       Case 1 'on
        d(.x, .y) = 7
       Case 2 'toggle
        d(.x, .y) = 13 - d(.x, .y) 'err?
       End Select
      End If
     End With
    Next k
   End With
   'check the same
   For k = 1 To SwitchStatusCount
    If pSolveItCheckPrev(d, k) Then Exit For
   Next k
   If k > SwitchStatusCount Then
    k = SwitchStatusCount + 1
    SwitchStatusCount = k
    ReDim Preserve SwitchMap(1 To datw, 1 To dath, 1 To k)
    ReDim Preserve SwitchMapPosId(1 To datw, 1 To dath, 1 To k)
    ReDim Preserve SwitchMapIdPos(1 To k)
    ReDim Preserve SwitchTransTable(1 To swc, 1 To k)
    CopyMemory SwitchMap(1, 1, k), d(1, 1), m
   End If
   SwitchTransTable(j, i) = k
  Next j
  i = i + 1
 Loop
Else 'no switch
 pSolveItCalcPos 1
End If
'///////////////////////////////////////////////////
'Debug.Print "switch status count:"; SwitchStatusCount
'///////////////////////////////////////////////////Step 2:is trans?
IsTrans = False
For i = 1 To datw
 For j = 1 To dath
  If dat(i, j) = 4 Then
   IsTrans = True
   Exit For
  End If
 Next j
Next i
k = 0
For i = 1 To SwitchStatusCount
 With SwitchMapIdPos(i)
  If IsTrans Then
   .AllPosCount = (.Count * (.Count + 1)) \ 2
  Else
   .AllPosCount = .Count * 3
  End If
  .AllPosDelta = k
  k = k + .AllPosCount
 End With
Next i
'///////////////////////////////////////////////////
'Debug.Print "node count:"; k
'///////////////////////////////////////////////////Step 3:create node and edge
If k = 0 Then Exit Function
GTheoryNodeCount = k
ReDim GTheoryNode(1 To GTheoryNodeCount)
For m = 1 To SwitchStatusCount
 With SwitchMapIdPos(m)
  '//////////////////////////status=up
  For k = 1 To .Count
   Select Case SwitchMap(.p(k).x, .p(k).y, m)
   Case 1, 2, 3, 7, 9, 10 '?
    Erase nd.Edges
    For i = 1 To 4
     nd.Edges(i) = pSolveItCalcNext(SwitchTransTable, m, k, 0, i, IsTrans)
    Next i
    'save node
    If IsTrans Then
     GTheoryNode(.AllPosDelta + (k * (k + 1)) \ 2) = nd
    Else
     GTheoryNode(.AllPosDelta + k) = nd
    End If
   End Select
  Next k
  '//////////////////////////status=h
  For k = 1 To .Count
   If .p(k).x <= datw - 1 Then
    If SwitchMapPosId(.p(k).x + 1, .p(k).y, m) > 0 And Not (SwitchMap(.p(k).x, .p(k).y, m) = 11 And SwitchMap(.p(k).x + 1, .p(k).y, m) = 11) Then
     Erase nd.Edges
     For i = 1 To 4
      nd.Edges(i) = pSolveItCalcNext(SwitchTransTable, m, k, 1, i, IsTrans)
     Next i
     'save node
     If IsTrans Then
      GTheoryNode(.AllPosDelta + pSolveItPosToInt(k, SwitchMapPosId(.p(k).x + 1, .p(k).y, m))) = nd
     Else
      GTheoryNode(.AllPosDelta + .Count + k) = nd
     End If
    End If
   End If
  Next k
  '//////////////////////////status=v
  For k = 1 To .Count
   If .p(k).y <= dath - 1 Then
    If SwitchMapPosId(.p(k).x, .p(k).y + 1, m) > 0 And Not (SwitchMap(.p(k).x, .p(k).y, m) = 11 And SwitchMap(.p(k).x, .p(k).y + 1, m) = 11) Then
     Erase nd.Edges
     For i = 1 To 4
      nd.Edges(i) = pSolveItCalcNext(SwitchTransTable, m, k, 2, i, IsTrans)
     Next i
     'save node
     If IsTrans Then
      GTheoryNode(.AllPosDelta + pSolveItPosToInt(k, SwitchMapPosId(.p(k).x, .p(k).y + 1, m))) = nd
     Else
      GTheoryNode(.AllPosDelta + .Count * 2 + k) = nd
     End If
    End If
   End If
  Next k
  '//////////////////////////status=single
  If IsTrans Then
   For k = 1 To .Count - 1
    x = .p(k).x
    y = .p(k).y
    For jj = k + 1 To .Count
     i = .p(jj).x - x
     j = .p(jj).y - y
     If i * i + j * j > 1 Then
      Erase nd.Edges
      For i = 1 To 4
       nd.Edges(i) = pSolveItCalcNextSingle(SwitchTransTable, m, k, jj, i)
       nd.Edges(i + 4) = pSolveItCalcNextSingle(SwitchTransTable, m, jj, k, i)
      Next i
      GTheoryNode(.AllPosDelta + pSolveItPosToInt(k, jj)) = nd
     End If
    Next jj
   Next k
  End If
 End With
Next m
'///////////////////////////////////////////////////Step 4:Dijkstra algorithm
i = SwitchMapPosId(StartX, StartY, 1)
If i = 0 Then Exit Sub
If IsTrans Then i = (i * (i + 1)) \ 2
pSolveItDijkstra i, objProgress
'calc time
t = GetTickCount - t
MsgBox CStr(t) + "ms"
'///////////////////////////////////////////////////
SolveIt = True
End Function

Private Sub pSolveItDijkstra(ByVal StartNode As Long, Optional objProgress As PictureBox)
Dim i As Long, j As Long, k As Long, sm As Long
Dim t As Long, m As Long
Dim LinkedListFirst As Long
If StartNode < 1 Or StartNode > GTheoryNodeCount Then Exit Sub 'error!
'/////////////init linked list
LinkedListFirst = 1
GTheoryNode(1).PrevNode = 0
GTheoryNode(GTheoryNodeCount).NextNode = 0
For i = 1 To GTheoryNodeCount - 1
 GTheoryNode(i).NextNode = i + 1
 GTheoryNode(i + 1).PrevNode = i
Next i
pSolveItLinkedListRemoveItem StartNode, LinkedListFirst
'/////////////init distance
For i = 1 To GTheoryNodeCount
 GTheoryNode(i).Distance = &H7FFFFFFF
Next i
With GTheoryNode(StartNode)
 .Distance = 0
 sm = &H7FFFFFFF
 For i = 1 To 8
  j = .Edges(i)
  If j > 0 Then
   With GTheoryNode(j)
    .Distance = 1
    .PathPrevNode = StartNode
    sm = 1
    k = j
   End With
  End If
 Next i
End With
Do
 If sm = &H7FFFFFFF Then Exit Do
 pSolveItLinkedListRemoveItem k, LinkedListFirst
 If LinkedListFirst = 0 Then Exit Do
 With GTheoryNode(k)
  For i = 1 To 8
   j = .Edges(i)
   If j > 0 Then
    With GTheoryNode(j)
     If .NextNode <> -1 Then
      t = sm + 1
      If t < .Distance Then
       .Distance = t
       .PathPrevNode = k
      End If
     End If
    End With
   End If
  Next i
 End With
 sm = &H7FFFFFFF
 j = LinkedListFirst
 Do Until j = 0
  t = GTheoryNode(j).Distance
  If t < sm Then
   sm = t
   k = j
  End If
  j = GTheoryNode(j).NextNode
 Loop
 '////////////
 m = m + 1
 If (m And &HFF&) = 0 Then
  If Not objProgress Is Nothing Then
   With objProgress
    .Width = (m * 320&) \ GTheoryNodeCount
    .Visible = True
   End With
  End If
  DoEvents
 End If
Loop
End Sub

Private Sub pSolveItLinkedListRemoveItem(ByVal Index As Long, LinkedListFirst As Long)
Dim i As Long, j As Long
With GTheoryNode(Index)
 i = .NextNode
 j = .PrevNode
 .NextNode = -1
 .PrevNode = -1
End With
If i > 0 Then GTheoryNode(i).PrevNode = j
If j > 0 Then
 GTheoryNode(j).NextNode = i
Else
 LinkedListFirst = i
End If
End Sub

Private Function pSolveItCalcNext(SwitchTransTable() As Long, ByVal m As Long, ByVal k As Long, ByVal State As Long, ByVal FS As Long, ByVal IsTrans As Boolean) As Long
Dim i As Long, j As Long, jj As Long, PJJ As Long
Dim x As Long, y As Long
With SwitchMapIdPos(m).p(k)
 Select Case State
 Case 0 '/////////////up
  Select Case FS
  'X -> X
  '     X
  Case 1, 2 'up/down
   x = .x
   y = 0
   If FS = 1 Then 'up
     If .y > 2 Then
      If SwitchMap(.x, .y - 1, m) = 9 And SwitchMap(.x, .y - 2, m) = 9 Then 'ice
       For y = .y - 2 To 1 Step -1
        Select Case SwitchMap(.x, y, m)
        Case 9 'ice
        Case 11
         y = y + 1
         Exit For
        Case Else
         Exit For
        End Select
       Next y
      Else
       y = .y - 2
      End If
     End If
   Else 'down
     If .y <= dath - 2 Then
      If SwitchMap(.x, .y + 1, m) = 9 And SwitchMap(.x, .y + 2, m) = 9 Then 'ice
       For y = .y + 2 To dath
        Select Case SwitchMap(.x, y, m)
        Case 9 'ice
        Case 11
         y = y - 2
         Exit For
        Case Else
         y = y - 1
         Exit For
        End Select
       Next y
      Else
       y = .y + 1
      End If
     End If
   End If
      If y > 0 And y <= dath - 1 Then
       If FS = 1 Then 'ERR!
        i = SwitchMap(x, y + 1, m)
        j = SwitchMap(x, y, m)
       Else
        i = SwitchMap(x, y, m)
        j = SwitchMap(x, y + 1, m)
       End If
       Select Case i
       Case 1, 2, 3, 4, 5, 7, 8, 9, 10
        Select Case j
        Case 1, 2, 3, 4, 5, 7, 8, 9, 10, 11
         'press button
         i = m
         If SwitchMap(x, y, m) = 2 Then
          j = dat2(x, y)
          If j > 0 And j <= swc Then
           i = SwitchTransTable(j, i)
          End If
         End If
         If SwitchMap(x, y + 1, m) = 2 Then
          j = dat2(x, y + 1)
          If j > 0 And j <= swc Then
           i = SwitchTransTable(j, i)
          End If
         End If
         j = SwitchMapPosId(x, y, i)
         jj = SwitchMapPosId(x, y + 1, i)
         If j > 0 And jj > 0 Then
          If IsTrans Then
           j = SwitchMapIdPos(i).AllPosDelta + pSolveItPosToInt(j, jj)
          Else
           j = SwitchMapIdPos(i).AllPosDelta + SwitchMapIdPos(i).Count * 2 + j
          End If
          pSolveItCalcNext = j
         End If
        End Select
       End Select
      End If
  'X -> XX
  Case 3, 4    'left/right
   x = 0
   y = .y
   If FS = 3 Then 'left
     If .x > 2 Then
      If SwitchMap(.x - 1, .y, m) = 9 And SwitchMap(.x - 2, .y, m) = 9 Then 'ice
       For x = .x - 2 To 1 Step -1
        Select Case SwitchMap(x, .y, m)
        Case 9 'ice
        Case 11
         x = x + 1
         Exit For
        Case Else
         Exit For
        End Select
       Next x
      Else
       x = .x - 2
      End If
     End If
   Else 'right
     If .x <= datw - 2 Then
      If SwitchMap(.x + 1, .y, m) = 9 And SwitchMap(.x + 2, .y, m) = 9 Then 'ice
       For x = .x + 2 To datw
        Select Case SwitchMap(x, .y, m)
        Case 9 'ice
        Case 11
         x = x - 2
         Exit For
        Case Else
         x = x - 1
         Exit For
        End Select
       Next x
      Else
       x = .x + 1
      End If
     End If
   End If
      If x > 0 And x <= datw - 1 Then
       If FS = 3 Then 'ERR!
        i = SwitchMap(x + 1, y, m)
        j = SwitchMap(x, y, m)
       Else
        i = SwitchMap(x, y, m)
        j = SwitchMap(x + 1, y, m)
       End If
       Select Case i
       Case 1, 2, 3, 4, 5, 7, 8, 9, 10
        Select Case j
        Case 1, 2, 3, 4, 5, 7, 8, 9, 10, 11
         'press button
         i = m
         If SwitchMap(x, y, m) = 2 Then
          j = dat2(x, y)
          If j > 0 And j <= swc Then
           i = SwitchTransTable(j, i)
          End If
         End If
         If SwitchMap(x + 1, y, m) = 2 Then
          j = dat2(x + 1, y)
          If j > 0 And j <= swc Then
           i = SwitchTransTable(j, i)
          End If
         End If
         j = SwitchMapPosId(x, y, i)
         jj = SwitchMapPosId(x + 1, y, i)
         If j > 0 And jj > 0 Then
          If IsTrans Then
           j = SwitchMapIdPos(i).AllPosDelta + pSolveItPosToInt(j, jj)
          Else
           j = SwitchMapIdPos(i).AllPosDelta + SwitchMapIdPos(i).Count + j
          End If
          pSolveItCalcNext = j
         End If
        End Select
       End Select
      End If
  End Select
 Case 1 '/////////////h
  Select Case FS
  'XX -> XX
  Case 1, 2   'up/down
   x = .x
   y = 0
   If FS = 1 Then 'up
      If .y > 1 Then
       If SwitchMap(.x, .y - 1, m) = 9 And SwitchMap(.x + 1, .y - 1, m) = 9 Then 'ice
        For y = .y - 1 To 1 Step -1
         If SwitchMap(.x, y, m) = 9 And SwitchMap(.x + 1, y, m) = 9 Then
         ElseIf SwitchMap(.x, y, m) = 11 Or SwitchMap(.x + 1, y, m) = 11 Then
          y = y + 1
          Exit For
         Else
          Exit For
         End If
        Next y
       Else
        y = .y - 1
       End If
      End If
   Else 'down
      If .y < dath Then
       If SwitchMap(.x, .y + 1, m) = 9 And SwitchMap(.x + 1, .y + 1, m) = 9 Then 'ice
        For y = .y + 1 To dath
         If SwitchMap(.x, y, m) = 9 And SwitchMap(.x + 1, y, m) = 9 Then
         ElseIf SwitchMap(.x, y, m) = 11 Or SwitchMap(.x + 1, y, m) = 11 Then
          y = y - 1
          Exit For
         Else
          Exit For
         End If
        Next y
       Else
        y = .y + 1
       End If
      End If
   End If
       If y > 0 And y <= dath Then
        j = SwitchMap(x + 1, y, m)
        If j <> 0 And j <> 6 And (j <> 11 Or SwitchMap(.x + 1, .y, m) = 11) Then
         j = SwitchMap(x, y, m)
         If j <> 0 And j <> 6 And (j <> 11 Or SwitchMap(.x, .y, m) = 11) Then
          'press button
          i = m
          If j = 2 Then
           j = dat2(x, y)
           If j > 0 And j <= swc Then
            i = SwitchTransTable(j, i)
           End If
          End If
          If SwitchMap(x + 1, y, m) = 2 Then
           j = dat2(x + 1, y)
           If j > 0 And j <= swc Then
            i = SwitchTransTable(j, i)
           End If
          End If
          j = SwitchMapPosId(x, y, i)
          jj = SwitchMapPosId(x + 1, y, i)
          If j > 0 And jj > 0 Then
           If IsTrans Then
            j = SwitchMapIdPos(i).AllPosDelta + pSolveItPosToInt(j, jj)
           Else
            j = SwitchMapIdPos(i).AllPosDelta + SwitchMapIdPos(i).Count + j
           End If
           pSolveItCalcNext = j
          End If
         End If
        End If
       End If
  'XX -> X
  Case 3, 4     'left/right
   x = 0
   y = .y
   If FS = 3 Then 'left
      If .x > 1 Then
       If SwitchMap(.x, .y, m) = 11 Then 'block
       ElseIf SwitchMap(.x - 1, .y, m) = 9 Then 'ice
        For x = .x - 1 To 1 Step -1
         Select Case SwitchMap(x, .y, m)
         Case 9
         Case 11
          x = x + 1
          Exit For
         Case Else
          Exit For
         End Select
        Next x
       Else
        x = .x - 1
       End If
      End If
   Else 'right
      If .x <= datw - 2 Then
       If SwitchMap(.x + 1, .y, m) = 11 Then 'block
       ElseIf SwitchMap(.x + 2, .y, m) = 9 Then 'ice
        For x = .x + 2 To datw
         Select Case SwitchMap(x, .y, m)
         Case 9
         Case 11
          x = x - 1
          Exit For
         Case Else
          Exit For
         End Select
        Next x
       Else
        x = .x + 2
       End If
      End If
   End If
       If x > 0 And x <= datw Then
        j = SwitchMap(x, y, m)
        Select Case j
        Case 1, 2, 3, 7, 8, 9
         'press button
         i = m
         If j = 2 Or j = 3 Then
          j = dat2(x, y)
          If j > 0 And j <= swc Then
           i = SwitchTransTable(j, i)
          End If
         End If
         j = SwitchMapPosId(x, y, i)
         If j > 0 Then
          If IsTrans Then
           j = SwitchMapIdPos(i).AllPosDelta + (j * (j + 1)) \ 2
          Else
           j = SwitchMapIdPos(i).AllPosDelta + j
          End If
          pSolveItCalcNext = j
         End If
        Case 4 'trans
         GetTransportPosition x, y, i, j, jj, PJJ
         j = SwitchMapPosId(i, j, m)
         jj = SwitchMapPosId(jj, PJJ, m)
         If j > 0 And jj > 0 Then
          If IsTrans Then
           j = SwitchMapIdPos(m).AllPosDelta + pSolveItPosToInt(j, jj)
          Else
           Debug.Assert False 'err!!
          End If
          pSolveItCalcNext = j
         End If
        Case 10 'pyramid
         j = SwitchMapPosId(x, y, m)
         'hit block?
         If FS = 3 Then 'left
          If x > 2 Then
           If SwitchMap(x - 1, y, m) = 11 Then
            If IsTrans Then
             j = SwitchMapIdPos(m).AllPosDelta + (j * (j + 1)) \ 2
            Else
             j = SwitchMapIdPos(m).AllPosDelta + j
            End If
            pSolveItCalcNext = j
           Else
            pSolveItCalcNext = pSolveItCalcNext(SwitchTransTable, m, j, 0, FS, IsTrans)
           End If
          End If
         Else 'right
          If x <= datw - 2 Then
           If SwitchMap(x + 1, y, m) = 11 Then
            If IsTrans Then
             j = SwitchMapIdPos(m).AllPosDelta + (j * (j + 1)) \ 2
            Else
             j = SwitchMapIdPos(m).AllPosDelta + j
            End If
            pSolveItCalcNext = j
           Else
            pSolveItCalcNext = pSolveItCalcNext(SwitchTransTable, m, j, 0, FS, IsTrans)
           End If
          End If
         End If
        End Select
       End If
  End Select
 Case 2 '/////////////v
  Select Case FS
  'X -> X
  'X
  Case 1, 2   'up/down
   x = .x
   y = 0
   If FS = 1 Then 'up
      If .y > 1 Then
       If SwitchMap(.x, .y, m) = 11 Then 'block
       ElseIf SwitchMap(.x, .y - 1, m) = 9 Then 'ice
        For y = .y - 1 To 1 Step -1
         Select Case SwitchMap(.x, y, m)
         Case 9
         Case 11
          y = y + 1
          Exit For
         Case Else
          Exit For
         End Select
        Next y
       Else
        y = .y - 1
       End If
      End If
   Else 'down
      If .y <= dath - 2 Then
       If SwitchMap(.x, .y + 1, m) = 11 Then 'block
       ElseIf SwitchMap(.x, .y + 2, m) = 9 Then 'ice
        For y = .y + 2 To dath
         Select Case SwitchMap(.x, y, m)
         Case 9
         Case 11
          y = y - 1
          Exit For
         Case Else
          Exit For
         End Select
        Next y
       Else
        y = .y + 2
       End If
      End If
   End If
       If y > 0 And y <= dath Then
        j = SwitchMap(x, y, m)
        Select Case j
        Case 1, 2, 3, 7, 8, 9
         'press button
         i = m
         If j = 2 Or j = 3 Then
          j = dat2(x, y)
          If j > 0 And j <= swc Then
           i = SwitchTransTable(j, i)
          End If
         End If
         j = SwitchMapPosId(x, y, i)
         If j > 0 Then
          If IsTrans Then
           j = SwitchMapIdPos(i).AllPosDelta + (j * (j + 1)) \ 2
          Else
           j = SwitchMapIdPos(i).AllPosDelta + j
          End If
          pSolveItCalcNext = j
         End If
        Case 4 'trans
         GetTransportPosition x, y, i, j, jj, PJJ
         j = SwitchMapPosId(i, j, m)
         jj = SwitchMapPosId(jj, PJJ, m)
         If j > 0 And jj > 0 Then
          If IsTrans Then
           j = SwitchMapIdPos(m).AllPosDelta + pSolveItPosToInt(j, jj)
          Else
           Debug.Assert False 'err!!
          End If
          pSolveItCalcNext = j
         End If
        Case 10 'pyramid
         j = SwitchMapPosId(x, y, m)
         'hit block?
         If FS = 1 Then 'up
          If y > 2 Then
           If SwitchMap(x, y - 1, m) = 11 Then
            If IsTrans Then
             j = SwitchMapIdPos(m).AllPosDelta + (j * (j + 1)) \ 2
            Else
             j = SwitchMapIdPos(m).AllPosDelta + j
            End If
            pSolveItCalcNext = j
           Else
            pSolveItCalcNext = pSolveItCalcNext(SwitchTransTable, m, j, 0, FS, IsTrans)
           End If
          End If
         Else 'down
          If y <= dath - 2 Then
           If SwitchMap(x, y + 1, m) = 11 Then
            If IsTrans Then
             j = SwitchMapIdPos(m).AllPosDelta + (j * (j + 1)) \ 2
            Else
             j = SwitchMapIdPos(m).AllPosDelta + j
            End If
            pSolveItCalcNext = j
           Else
            pSolveItCalcNext = pSolveItCalcNext(SwitchTransTable, m, j, 0, FS, IsTrans)
           End If
          End If
         End If
        End Select
       End If
  'X -> X
  'X    X
  Case 3, 4   'left/right
   x = 0
   y = .y
   If FS = 3 Then 'left
      If .x > 1 Then
       If SwitchMap(.x - 1, .y, m) = 9 And SwitchMap(.x - 1, .y + 1, m) = 9 Then 'ice
        For x = .x - 1 To 1 Step -1
         If SwitchMap(x, .y, m) = 9 And SwitchMap(x, .y + 1, m) = 9 Then
         ElseIf SwitchMap(x, .y, m) = 11 Or SwitchMap(x, .y + 1, m) = 11 Then
          x = x + 1
          Exit For
         Else
          Exit For
         End If
        Next x
       Else
        x = .x - 1
       End If
      End If
   Else 'right
      If .x < datw Then
       If SwitchMap(.x + 1, .y, m) = 9 And SwitchMap(.x + 1, .y + 1, m) = 9 Then 'ice
        For x = .x + 1 To datw
         If SwitchMap(x, .y, m) = 9 And SwitchMap(x, .y + 1, m) = 9 Then
         ElseIf SwitchMap(x, .y, m) = 11 Or SwitchMap(x, .y + 1, m) = 11 Then
          x = x - 1
          Exit For
         Else
          Exit For
         End If
        Next x
       Else
        x = .x + 1
       End If
      End If
   End If
       If x > 0 And x <= datw Then
        j = SwitchMap(x, y + 1, m)
        If j <> 0 And j <> 6 And (j <> 11 Or SwitchMap(.x, .y + 1, m) = 11) Then
         j = SwitchMap(x, y, m)
         If j <> 0 And j <> 6 And (j <> 11 Or SwitchMap(.x, .y, m) = 11) Then
          'press button
          i = m
          If j = 2 Then
           j = dat2(x, y)
           If j > 0 And j <= swc Then
            i = SwitchTransTable(j, i)
           End If
          End If
          If SwitchMap(x, y + 1, m) = 2 Then
           j = dat2(x, y + 1)
           If j > 0 And j <= swc Then
            i = SwitchTransTable(j, i)
           End If
          End If
          j = SwitchMapPosId(x, y, i)
          jj = SwitchMapPosId(x, y + 1, i)
          If j > 0 And jj > 0 Then
           If IsTrans Then
            j = SwitchMapIdPos(i).AllPosDelta + pSolveItPosToInt(j, jj)
           Else
            j = SwitchMapIdPos(i).AllPosDelta + SwitchMapIdPos(i).Count * 2 + j
           End If
           pSolveItCalcNext = j
          End If
         End If
        End If
       End If
  End Select
 End Select
End With
End Function

Private Function pSolveItCalcNextSingle(SwitchTransTable() As Long, ByVal m As Long, ByVal k As Long, ByVal k2 As Long, ByVal FS As Long) As Long
Dim i As Long, j As Long, jj As Long
Dim x As Long, y As Long, x2 As Long, y2 As Long
'IsTrans must be true!
With SwitchMapIdPos(m)
 x2 = .p(k2).x
 y2 = .p(k2).y
 With .p(k)
  Select Case FS
  Case 1 'up
      If .y > 1 Then
       x = .x
       If SwitchMap(.x, .y - 1, m) = 9 Then 'ice
        For y = .y - 1 To 1 Step -1
         If x2 = x And y2 = y Then 'hit another block
          y = y + 1
          Exit For
         End If
         Select Case SwitchMap(x, y, m)
         Case 9
         Case 11
          y = y + 1
          Exit For
         Case Else
          Exit For
         End Select
        Next y
       Else
        y = .y - 1
       End If
      End If
  Case 2 'down
      If .y < dath Then
       x = .x
       If SwitchMap(.x, .y + 1, m) = 9 Then 'ice
        For y = .y + 1 To dath
         If x2 = x And y2 = y Then 'hit another block
          y = y - 1
          Exit For
         End If
         Select Case SwitchMap(x, y, m)
         Case 9
         Case 11
          y = y - 1
          Exit For
         Case Else
          Exit For
         End Select
        Next y
       Else
        y = .y + 1
       End If
      End If
  Case 3 'left
      If .x > 1 Then
       y = .y
       If SwitchMap(.x - 1, .y, m) = 9 Then 'ice
        For x = .x - 1 To 1 Step -1
         If x2 = x And y2 = y Then 'hit another block
          x = x + 1
          Exit For
         End If
         Select Case SwitchMap(x, y, m)
         Case 9
         Case 11
          x = x + 1
          Exit For
         Case Else
          Exit For
         End Select
        Next x
       Else
        x = .x - 1
       End If
      End If
  Case 4 'right
      If .x < datw Then
       y = .y
       If SwitchMap(.x + 1, .y, m) = 9 Then 'ice
        For x = .x + 1 To datw
         If x2 = x And y2 = y Then 'hit another block
          x = x - 1
          Exit For
         End If
         Select Case SwitchMap(x, y, m)
         Case 9
         Case 11
          x = x - 1
          Exit For
         Case Else
          Exit For
         End Select
        Next x
       Else
        x = .x + 1
       End If
      End If
  End Select
       If x > 0 And y > 0 And x <= datw And y <= dath Then
        Select Case SwitchMap(x, y, m)
        Case 1, 2, 3, 4, 5, 7, 8, 9, 10
         'press button
         i = m
         If SwitchMap(x, y, m) = 2 Then
          j = dat2(x, y)
          If j > 0 And j <= swc Then
           i = SwitchTransTable(j, i)
          End If
         End If
         j = SwitchMapPosId(x, y, i)
         jj = SwitchMapPosId(x2, y2, i)
         If j > 0 And jj > 0 Then
          j = SwitchMapIdPos(i).AllPosDelta + pSolveItPosToInt(j, jj)
          pSolveItCalcNextSingle = j
         End If
        End Select
       End If
 End With
End With
End Function

Public Sub SolveItClear()
'MsgBox 1
Erase SwitchMap
'MsgBox 2
Erase SwitchMapPosId
'MsgBox 3
Erase SwitchMapIdPos '???
'MsgBox 4
Erase GTheoryNode
'MsgBox 5
SwitchStatusCount = 0
GTheoryNodeCount = 0
End Sub

Private Function pSolveItPosToInt(ByVal p1 As Long, ByVal p2 As Long) As Long
If p1 > p2 Then
 pSolveItPosToInt = (p1 * (p1 - 1)) \ 2 + p2
Else
 pSolveItPosToInt = (p2 * (p2 - 1)) \ 2 + p1
End If
End Function

Private Sub pSolveItIntToPos(ByVal n As Long, p1 As Long, p2 As Long)
p2 = Round(Sqr(n + n))
p1 = n - (p2 * (p2 - 1)) \ 2
End Sub

Private Sub pSolveItCalcPos(ByVal n As Long)
Dim i As Long, j As Long
With SwitchMapIdPos(n)
 .Count = 0
 Erase .p
 For i = 1 To datw
  For j = 1 To dath
   Select Case SwitchMap(i, j, n)
   Case 0, 6
    SwitchMapPosId(i, j, n) = 0
   Case Else
    .Count = .Count + 1
    SwitchMapPosId(i, j, n) = .Count
    ReDim Preserve .p(1 To .Count)
    With .p(.Count)
     .x = i
     .y = j
    End With
   End Select
  Next j
 Next i
End With
End Sub

Private Function pSolveItCheckPrev(d() As Byte, ByVal n As Long) As Boolean
Dim i As Long, j As Long
For i = 1 To datw
 For j = 1 To dath
  If SwitchMap(i, j, n) <> d(i, j) Then Exit Function
 Next j
Next i
pSolveItCheckPrev = True
End Function

Public Function SolveItGetSwitchStatusCount() As Long
SolveItGetSwitchStatusCount = SwitchStatusCount
End Function

Public Sub SolveItGetSwitchStatus(ByVal Index As Long, d() As Byte)
ReDim d(1 To datw, 1 To dath)
CopyMemory d(1, 1), SwitchMap(1, 1, Index), datw * dath
End Sub

Public Function SolveItGetDistance(ByVal Index As Long) As Long
SolveItGetDistance = GTheoryNode(Index).Distance
End Function

Public Function SolveItGetSolution(ByVal Index As Long, Optional ByVal lpMovedArea As Long) As String
Dim s As String, ss As String
Dim i As Long, j As Long, k As Long, m As Long
Dim x As Long, y As Long, x2 As Long, y2 As Long
Dim xo As Long, yo As Long, xo2 As Long, yo2 As Long
Dim jj As Long
Dim IsL As Boolean, IsLo As Boolean
Dim MOV As Long, MOVo As Long
Dim d() As Byte
ReDim d(1 To datw, 1 To dath)
i = Index
Do
 j = GTheoryNode(i).PathPrevNode
 If j = 0 Then Exit Do
 With GTheoryNode(j)
  For k = 1 To 8
   If i = .Edges(k) Then
    s = CStr(k) + s
    Exit For
   End If
  Next k
 End With
 i = j
Loop
If IsTrans Then '??????????????????????????????
 m = Len(s)
 xo = StartX
 yo = StartY
 xo2 = StartX
 yo2 = StartY
 d(xo, yo) = 1
 IsLo = True
 MOVo = 0
 For k = 1 To m
  j = Val(Mid(s, k, 1))
  i = GTheoryNode(i).Edges(j)
  'determine status index
  For jj = 1 To SwitchStatusCount
   If i <= SwitchMapIdPos(jj).AllPosDelta + SwitchMapIdPos(jj).AllPosCount Then Exit For 'msvbvm60 error!!!
  Next jj
  'get pos
  With SwitchMapIdPos(jj)
   pSolveItIntToPos i - .AllPosDelta, y, y2
   x = .p(y).x
   y = .p(y).y
   x2 = .p(y2).x
   y2 = .p(y2).y
  End With
  'which is moved?
  j = 1 + (j - 1) Mod 4
  IsL = (x - x2) * (x - x2) + (y - y2) * (y - y2) <= 1
  If IsLo Then
   If IsL Then 'ice??
    MOV = 0
    If j <= 2 Then
     If xo = x Then
      pSolveItCalcMovedArea d, xo, yo, x, y, j
      pSolveItCalcMovedArea d, xo2, yo2, x2, y2, j
     ElseIf xo = x2 Then
      pSolveItCalcMovedArea d, xo, yo, x2, y2, j
      pSolveItCalcMovedArea d, xo2, yo2, x, y, j
     Else
      Debug.Assert False
     End If
    Else
     If yo = y Then
      pSolveItCalcMovedArea d, xo, yo, x, y, j
      pSolveItCalcMovedArea d, xo2, yo2, x2, y2, j
     ElseIf yo = y2 Then
      pSolveItCalcMovedArea d, xo, yo, x2, y2, j
      pSolveItCalcMovedArea d, xo2, yo2, x, y, j
     Else
      Debug.Assert False
     End If
    End If
    xo = x
    yo = y
    xo2 = x2
    yo2 = y2
   Else 'enter trans
    MOV = 1
    Select Case j 'ice??
    Case 1 'up
     x = xo
     For y = IIf(yo < yo2, yo, yo2) - 1 To 1 Step -1
      d(x, y) = 1
      If dat(x, y) = 4 Then Exit For
     Next y
    Case 2 'down
     x = xo
     For y = IIf(yo < yo2, yo, yo2) + 2 To dath
      d(x, y) = 1
      If dat(x, y) = 4 Then Exit For
     Next y
    Case 3 'left
     y = yo
     For x = IIf(xo < xo2, xo, xo2) - 1 To 1 Step -1
      d(x, y) = 1
      If dat(x, y) = 4 Then Exit For
     Next x
    Case 4 'right
     y = yo
     For x = IIf(xo < xo2, xo, xo2) + 2 To datw
      d(x, y) = 1
      If dat(x, y) = 4 Then Exit For
     Next x
    End Select
    GetTransportPosition x, y, x, y, x2, y2
    xo = x
    yo = y
    xo2 = x2
    yo2 = y2
   End If
  Else
   If xo = x And yo = y Then
    MOV = 2
    pSolveItCalcMovedArea d, xo2, yo2, x2, y2, j
    xo2 = x2
    yo2 = y2
   ElseIf xo = x2 And yo = y2 Then
    MOV = 2
    pSolveItCalcMovedArea d, xo2, yo2, x, y, j
    xo2 = x
    yo2 = y
   ElseIf xo2 = x And yo2 = y Then
    MOV = 1
    pSolveItCalcMovedArea d, xo, yo, x2, y2, j
    xo = x2
    yo = y2
   ElseIf xo2 = x2 And yo2 = y2 Then
    MOV = 1
    pSolveItCalcMovedArea d, xo, yo, x, y, j
    xo = x
    yo = y
   Else
    Debug.Assert False
   End If
  End If
  'need to press space bar?
  If MOV + MOVo = 3 Then
   ss = ss + "s"
  End If
  ss = ss + CStr(j)
  'moved area
  d(x, y) = 1
  d(x2, y2) = 1
  'next
  MOVo = MOV
  IsLo = IsL
 Next k
 s = ss
ElseIf lpMovedArea <> 0 Then
 m = Len(s)
 xo = StartX
 yo = StartY
 d(xo, yo) = 1
 For k = 1 To m
  j = Val(Mid(s, k, 1))
  i = GTheoryNode(i).Edges(j)
  'determine status index
  For jj = 1 To SwitchStatusCount
   If i <= SwitchMapIdPos(jj).AllPosDelta + SwitchMapIdPos(jj).AllPosCount Then Exit For 'msvbvm60 error!!!
  Next jj
  'get pos
  With SwitchMapIdPos(jj)
   x2 = i - .AllPosDelta
   y2 = (x2 - 1) \ .Count
   With .p(x2 - y2 * .Count)
    x = .x
    y = .y
   End With
  End With
  'moved area
  d(x, y) = 1
  Select Case y2
  Case 0 'up
   pSolveItCalcMovedArea d, xo, yo, x, y, j
  Case 1 'h
   pSolveItCalcMovedArea d, xo, yo, x, y, j
   If j = 3 Then
    pSolveItCalcMovedArea d, xo, yo, x + 1, y, j
   Else
    pSolveItCalcMovedArea d, xo + 1, yo, x + 1, y, j
   End If
  Case 2 'v
   pSolveItCalcMovedArea d, xo, yo, x, y, j
   If j = 1 Then
    pSolveItCalcMovedArea d, xo, yo, x, y + 1, j
   Else
    pSolveItCalcMovedArea d, xo, yo + 1, x, y + 1, j
   End If
  End Select
  'next
  xo = x
  yo = y
 Next k
End If
If lpMovedArea <> 0 Then CopyMemory ByVal lpMovedArea, d(1, 1), datw * dath
s = Replace(s, "1", "u")
s = Replace(s, "2", "d")
s = Replace(s, "3", "l")
s = Replace(s, "4", "r")
SolveItGetSolution = s
End Function

Private Sub pSolveItCalcMovedArea(d() As Byte, ByVal xo As Long, ByVal yo As Long, ByVal x As Long, ByVal y As Long, ByVal FS As Long)
Dim k As Long
   Select Case FS
   Case 1 'up
    For k = yo To y Step -1
     d(x, k) = 1
    Next k
   Case 2 'down
    For k = yo To y
     d(x, k) = 1
    Next k
   Case 3 'left
    For k = xo To x Step -1
     d(k, y) = 1
    Next k
   Case 4 'right
    For k = xo To x
     d(k, y) = 1
    Next k
   End Select
End Sub

Public Function SolveItGetNodeIndex(ByVal m As Long, ByVal State As Long, ByVal x As Long, ByVal y As Long, Optional ByVal x2 As Long, Optional ByVal y2 As Long) As Long
Dim j As Long, jj As Long
With SwitchMapIdPos(m)
 If IsTrans Then
  Select Case State
  Case 0
   j = SwitchMapPosId(x, y, m)
   If j > 0 Then
    SolveItGetNodeIndex = .AllPosDelta + (j * (j + 1)) \ 2
   End If
  Case 1
   If x < datw Then
    j = SwitchMapPosId(x, y, m)
    jj = SwitchMapPosId(x + 1, y, m)
    If j > 0 And jj > 0 Then
     SolveItGetNodeIndex = .AllPosDelta + pSolveItPosToInt(j, jj)
    End If
   End If
  Case 2
   If y < dath Then
    j = SwitchMapPosId(x, y, m)
    jj = SwitchMapPosId(x, y + 1, m)
    If j > 0 And jj > 0 Then
     SolveItGetNodeIndex = .AllPosDelta + pSolveItPosToInt(j, jj)
    End If
   End If
  Case 3
   j = SwitchMapPosId(x, y, m)
   jj = SwitchMapPosId(x2, y2, m)
   If j > 0 And jj > 0 Then
    SolveItGetNodeIndex = .AllPosDelta + pSolveItPosToInt(j, jj)
   End If
  End Select
 Else
  Select Case State
  Case 0
   j = SwitchMapPosId(x, y, m)
   If j > 0 Then
    SolveItGetNodeIndex = .AllPosDelta + j
   End If
  Case 1
   j = SwitchMapPosId(x, y, m)
   If j > 0 Then
    SolveItGetNodeIndex = .AllPosDelta + .Count + j
   End If
  Case 2
   j = SwitchMapPosId(x, y, m)
   If j > 0 Then
    SolveItGetNodeIndex = .AllPosDelta + .Count * 2 + j
   End If
  End Select
 End If
End With
End Function
