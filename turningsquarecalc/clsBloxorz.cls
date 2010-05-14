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
Private Declare Sub FillMemory Lib "kernel32.dll" Alias "RtlFillMemory" (ByRef Destination As Any, ByVal Length As Long, ByVal Fill As Byte)
Private Declare Function GetTickCount Lib "kernel32.dll" () As Long

Private Const TheSignature = "Ò¡·½¿éXP"

Private Type typeBridge
 X As Long
 Y As Long
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
 X As Integer
 Y As Integer
End Type

Private Type typeSolveItSwitchIdPos
 Count As Long
 AllPosCount As Long
 AllPosDelta As Long
 p() As typeSolveItPos
End Type

Private Type typeSolveItNode
 Index As Long
 BinarySearchTreeLSon As Long
 BinarySearchTreeRSon As Long
 m As Long
 k As Long
 k2 As Long
 Distance As Long
 PathPrevNode As Long
 PathPrevEdge As Long
End Type

Private Type typeNextPos
 m As Long
 k As Long
 k2 As Long
End Type

Public Enum enumBloxorzStateValid
 BState_Fall = 0
 BState_Valid = 1
 BState_Thin = 2
 BState_UnknownError = 99
End Enum

#Const SolveItRecordMovedArea = True

Private SwitchMap() As Byte, SwitchMapPosId() As Long, SwitchMapIdPos() As typeSolveItSwitchIdPos, SwitchStatusCount As Long, IsTrans As Boolean
Private GTheoryNode() As typeSolveItNode
Private GTheoryNodeMax As Long, GTheoryNodeUsed As Long, SolveItTime As Long
#If SolveItRecordMovedArea Then
Private SolveItMovedArea() As Byte
#End If

'stupid
Public Function ToString() As String
Dim s As String, s1 As String
Dim i As Long, j As Long
s = CStr(datw) + "," + CStr(dath) + vbCrLf _
+ CStr(swc) + vbCrLf + CStr(StartX) + "," + CStr(StartY) + vbCrLf
'///
For j = 1 To dath
 s1 = ""
 For i = 1 To datw
  s1 = s1 + CStr(dat(i, j)) + ","
 Next i
 s = s + s1 + vbCrLf
Next j
'///
For j = 1 To dath
 s1 = ""
 For i = 1 To datw
  s1 = s1 + CStr(dat2(i, j)) + ","
 Next i
 s = s + s1 + vbCrLf
Next j
'///
For i = 1 To swc
 s = s + CStr(sws(i).bc) + vbCrLf
 For j = 1 To sws(i).bc
  s = s + CStr(sws(i).bs(i).X) + "," + CStr(sws(i).bs(i).Y) + "," + CStr(sws(i).bs(i).Behavior) + vbCrLf
 Next j
Next i
'///
ToString = s
End Function

'stupid
Public Function FromString(ByRef sString As String) As Boolean
On Error GoTo a
Dim v As Variant, m As Long
Dim s As String
Dim i As Long, j As Long, k As Long
Dim i1 As Long, i2 As Long, i3 As Long
'///
Destroy
v = Split(Replace(Replace(sString, vbCr, ","), vbLf, ","), ",")
m = UBound(v)
For i = 0 To m
 s = Trim(v(i))
 If s <> "" Then
  Select Case i1
  Case 0
   datw = Val(s): i1 = i1 + 1
  Case 1
   dath = Val(s): i1 = i1 + 1
  Case 2
   swc = Val(s): i1 = i1 + 1
  Case 3
   StartX = Val(s): i1 = i1 + 1
  Case 4
   StartY = Val(s): i1 = i1 + 1
   If Not (0 < StartX And StartX <= datw And datw <= 255 And _
   0 < StartY And StartY <= dath And dath <= 255 And swc >= 0) Then Err.Raise 5
   ReDim dat(1 To datw, 1 To dath)
   ReDim dat2(1 To datw, 1 To dath)
   If swc > 0 Then ReDim sws(1 To swc)
   i2 = 1
   i3 = 1
  Case 5 'dat
   dat(i2, i3) = Val(s)
   i2 = i2 + 1
   If i2 > datw Then
    i2 = 1
    i3 = i3 + 1
    If i3 > dath Then
     i1 = i1 + 1
     i3 = 1
    End If
   End If
  Case 6 'dat2
   dat2(i2, i3) = Val(s)
   i2 = i2 + 1
   If i2 > datw Then
    i2 = 1
    i3 = i3 + 1
    If i3 > dath Then
     i1 = i1 + 1
     i3 = 0 '!!!
    End If
   End If
  Case Else 'switch
   k = i1 - 6
   If k > 0 And k <= swc Then
    j = Val(s)
    If i3 = 0 Then
     sws(k).bc = j
     If j > 0 Then ReDim sws(k).bs(1 To j)
     i3 = i3 + 1
    Else
     Select Case i2
     Case 1: sws(k).bs(i3).X = j
     Case 2: sws(k).bs(i3).Y = j
     Case 3: sws(k).bs(i3).Behavior = j
     End Select
     i2 = i2 + 1
     If i2 > 3 Then
      i2 = 1
      i3 = i3 + 1
     End If
    End If
    If i3 > sws(k).bc Then
     i1 = i1 + 1
     i3 = 0
    End If
   End If
  End Select
 End If
Next i
FromString = i1 > 4
a:
End Function

Public Sub CopyToClipboard()
On Error Resume Next
Clipboard.Clear
Clipboard.SetText ToString
End Sub

Public Function PasteFromClipboard()
On Error GoTo a
PasteFromClipboard = FromString(Clipboard.GetText)
a:
End Function

Public Sub Clone(objSrc As clsBloxorz)
Destroy
datw = objSrc.Width
dath = objSrc.Height
swc = objSrc.SwitchCount
StartX = objSrc.StartX
StartY = objSrc.StartY
objSrc.fClone dat, dat2, sws
End Sub

Friend Sub fClone(dat_() As Byte, dat2_() As Long, sws_() As typeSwitch)
dat_ = dat '???
dat2_ = dat2 '???
sws_ = sws '???
End Sub

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

Public Property Get Data(ByVal X As Long, ByVal Y As Long) As Long
Data = dat(X, Y)
End Property

Public Property Let Data(ByVal X As Long, ByVal Y As Long, ByVal n As Long)
dat(X, Y) = n
End Property

Public Property Get Data2(ByVal X As Long, ByVal Y As Long) As Long
Data2 = dat2(X, Y)
End Property

Public Property Let Data2(ByVal X As Long, ByVal Y As Long, ByVal n As Long)
dat2(X, Y) = n
End Property

Public Sub GetTransportPosition(ByVal X As Long, ByVal Y As Long, ByRef x1 As Long, ByRef y1 As Long, ByRef x2 As Long, ByRef y2 As Long)
Dim n As Long
x1 = 0
y1 = 0
x2 = 0
y2 = 0
n = VarPtr(dat2(X, Y))
CopyMemory x1, ByVal n, 1&
CopyMemory y1, ByVal (n + 1), 1&
CopyMemory x2, ByVal (n + 2), 1&
CopyMemory y2, ByVal (n + 3), 1&
End Sub

Public Sub SetTransportPosition(ByVal X As Long, ByVal Y As Long, ByVal x1 As Long, ByVal y1 As Long, ByVal x2 As Long, ByVal y2 As Long)
Dim n As Long
n = VarPtr(dat2(X, Y))
CopyMemory ByVal n, x1, 1&
CopyMemory ByVal (n + 1), y1, 1&
CopyMemory ByVal (n + 2), x2, 1&
CopyMemory ByVal (n + 3), y2, 1&
End Sub

'add a stupid function
Public Function GetSpecifiedObjectCount(ByVal i1 As Long, Optional ByVal i2 As Long, Optional ByVal x1 As Long, Optional ByVal y1 As Long, Optional ByVal x2 As Long, Optional ByVal y2 As Long) As Long
Dim i As Long, j As Long, k As Long
If x1 < 1 Or x1 > datw Then x1 = 1
If y1 < 1 Or y1 > dath Then y1 = 1
If x2 < x1 Or x2 > datw Then x2 = datw
If y2 < y1 Or y2 > dath Then y2 = dath
If i2 < i1 Then i2 = i1
For i = x1 To x2
 For j = y1 To y2
  If dat(i, j) >= i1 And dat(i, j) <= i2 Then k = k + 1
 Next j
Next i
GetSpecifiedObjectCount = k
End Function

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

Public Sub AddSwitchBridge(ByVal Index As Long, Optional ByVal X As Long, Optional ByVal Y As Long, Optional ByVal Behavior As Long)
With sws(Index)
 .bc = .bc + 1
 ReDim Preserve .bs(1 To .bc)
 With .bs(.bc)
  .X = X
  .Y = Y
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
SwitchBridgeX = sws(Index).bs(i).X
End Property

Public Property Let SwitchBridgeX(ByVal Index As Long, ByVal i As Long, ByVal n As Long)
sws(Index).bs(i).X = n
End Property

Public Property Get SwitchBridgeY(ByVal Index As Long, ByVal i As Long) As Long
SwitchBridgeY = sws(Index).bs(i).Y
End Property

Public Property Let SwitchBridgeY(ByVal Index As Long, ByVal i As Long, ByVal n As Long)
sws(Index).bs(i).Y = n
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
       If .bs(k).X = sws(j).bs(l).X Then
        If .bs(k).Y = sws(j).bs(l).Y Then
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
'unused. See old file for source code.
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

Public Function SolveIt(Optional objProgress As IBloxorzCallBack) As Boolean
Dim SwitchTransTable() As Long, d() As Byte
Dim nd As typeSolveItNode
Dim i As Long, j As Long, jj As Long, k As Long, m As Long
Dim X As Long, Y As Long, t As Long, bAbort As Boolean
If StartX <= 0 Or StartY <= 0 Or StartX > datw Or StartY > dath Then Exit Function
t = GetTickCount
'///////////////////////////////////////////////////Step 1:determine switch
'init
ReDim SwitchMap(1 To datw, 1 To dath, 1 To 1)
ReDim SwitchMapPosId(1 To datw, 1 To dath, 1 To 1)
ReDim SwitchMapIdPos(1 To 1)
#If SolveItRecordMovedArea Then
ReDim SolveItMovedArea(1 To datw, 1 To dath)
#End If
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
      If .X > 0 And .Y > 0 And .X <= datw And .Y <= dath Then
       Select Case .Behavior
       Case 0 'off
        d(.X, .Y) = 6
       Case 1 'on
        d(.X, .Y) = 7
       Case 2 'toggle
        d(.X, .Y) = 13 - d(.X, .Y) 'err?
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
'///////////////////////////////////////////////////New Step 3:start BFS with binary search tree
If k = 0 Then Exit Function
GTheoryNodeMax = k
'new method!
GTheoryNodeUsed = 0
Erase GTheoryNode
pSolveItResizeNodeArray
'init node
i = SwitchMapPosId(StartX, StartY, 1)
If i = 0 Then Exit Function
If IsTrans Then
 j = (i * (i + 1)) \ 2
 k = i
Else
 j = i
 k = 0
End If
With GTheoryNode(1)
 .Index = j
 .m = 1
 .k = i
 .k2 = k
End With
'init data
Dim lps As Long, lpe As Long, ret As typeNextPos
lps = 1
lpe = 1
If IsTrans Then
 Do Until lps > lpe
  With GTheoryNode(lps)
   X = .Distance + 1
   jj = pSolveItCheckNodeState(.m, .k, 3, .k2)
   #If SolveItRecordMovedArea Then
   With SwitchMapIdPos(.m).p(.k)
    SolveItMovedArea(.X, .Y) = 1
   End With
   If .k2 <> .k Then
    With SwitchMapIdPos(.m).p(.k2)
     SolveItMovedArea(.X, .Y) = 1
    End With
   End If
   #End If
   Select Case jj
   Case 0, 1, 2 'up,h,v
    k = .k
    If jj = 1 Then
     If SwitchMapIdPos(.m).p(.k).X > SwitchMapIdPos(.m).p(.k2).X Then k = .k2
    ElseIf jj = 2 Then
     If SwitchMapIdPos(.m).p(.k).Y > SwitchMapIdPos(.m).p(.k2).Y Then k = .k2
    End If
    For i = 1 To 4
     j = pSolveItCalcNext(SwitchTransTable, .m, k, jj, i, ret)
     If j > 0 Then
      m = pSolveItBinarySearchTreeFindNode(j, lpe)
      If m > lpe Then
       lpe = m
       With GTheoryNode(lpe)
        .Index = j
        .m = ret.m
        .k = ret.k
        .k2 = ret.k2
        .PathPrevEdge = i
        .PathPrevNode = lps
        .Distance = X
       End With
      End If
     End If
    Next i
   Case 3 'single
    For i = 1 To 4
     j = pSolveItCalcNextSingle(SwitchTransTable, .m, .k, .k2, i, ret)
     If j > 0 Then
      m = pSolveItBinarySearchTreeFindNode(j, lpe)
      If m > lpe Then
       lpe = m
       With GTheoryNode(lpe)
        .Index = j
        .m = ret.m
        .k = ret.k
        .k2 = ret.k2
        .PathPrevEdge = i
        .PathPrevNode = lps
        .Distance = X
       End With
      End If
     End If
     j = pSolveItCalcNextSingle(SwitchTransTable, .m, .k2, .k, i, ret)
     If j > 0 Then
      m = pSolveItBinarySearchTreeFindNode(j, lpe)
      If m > lpe Then
       lpe = m
       With GTheoryNode(lpe)
        .Index = j
        .m = ret.m
        .k = ret.k
        .k2 = ret.k2
        .PathPrevEdge = i + 4
        .PathPrevNode = lps
        .Distance = X
       End With
      End If
     End If
    Next i
   End Select
  End With
  lps = lps + 1
  If lpe > GTheoryNodeUsed - 16 Then pSolveItResizeNodeArray
  If (lps And &HFF&) = 0 Then
   If Not objProgress Is Nothing Then
    bAbort = False
    objProgress.SolveItCallBack lps, GTheoryNodeMax, bAbort
    If bAbort Then Exit Do
   End If
  End If
 Loop
Else
 Do Until lps > lpe
  With GTheoryNode(lps)
   X = .Distance + 1
   jj = pSolveItCheckNodeState(.m, .k, .k2)
   #If SolveItRecordMovedArea Then
   With SwitchMapIdPos(.m).p(.k)
    SolveItMovedArea(.X, .Y) = 1
    If jj = 1 Then 'h
     SolveItMovedArea(.X + 1, .Y) = 1
    ElseIf jj = 2 Then 'v
     SolveItMovedArea(.X, .Y + 1) = 1
    End If
   End With
   #End If
   Select Case jj
   Case 0, 1, 2
    For i = 1 To 4
     j = pSolveItCalcNext(SwitchTransTable, .m, .k, .k2, i, ret)
     If j > 0 Then
      m = pSolveItBinarySearchTreeFindNode(j, lpe)
      If m > lpe Then
       lpe = m
       With GTheoryNode(lpe)
        .Index = j
        .m = ret.m
        .k = ret.k
        .k2 = ret.k2
        .PathPrevEdge = i
        .PathPrevNode = lps
        .Distance = X
       End With
      End If
     End If
    Next i
   End Select
  End With
  lps = lps + 1
  If lpe > GTheoryNodeUsed - 16 Then pSolveItResizeNodeArray
  If (lps And &HFF&) = 0 Then
   If Not objProgress Is Nothing Then
    bAbort = False
    objProgress.SolveItCallBack lps, GTheoryNodeMax, bAbort
    If bAbort Then Exit Do
   End If
  End If
 Loop
End If
ReDim Preserve GTheoryNode(1 To lpe)
GTheoryNodeUsed = lpe
'///////////////////////////////////////////////////
SolveItTime = GetTickCount - t
SolveIt = True
End Function

Public Sub SolveItGetCanMoveArea(d() As Byte)
#If SolveItRecordMovedArea Then
On Error GoTo a
Dim i As Long
i = UBound(SolveItMovedArea) 'dummy function
If i = datw Then 'dummy check
 CopyMemory d(1, 1), SolveItMovedArea(1, 1), datw * dath
 Exit Sub
End If
a:
#End If
FillMemory d(1, 1), datw * dath, 1
End Sub

Private Sub pSolveItResizeNodeArray()
GTheoryNodeUsed = GTheoryNodeUsed + 10000
If GTheoryNodeUsed > GTheoryNodeMax Then GTheoryNodeUsed = GTheoryNodeMax
ReDim Preserve GTheoryNode(1 To GTheoryNodeUsed)
End Sub

Private Sub pSolveItShowProgress(ByVal m As Long, Optional objProgress As PictureBox)
If Not objProgress Is Nothing Then
   With objProgress
    .Width = (m * 320&) \ GTheoryNodeMax
    .Visible = True
   End With
End If
DoEvents
End Sub

Private Function pSolveItBinarySearchTreeFindNode(ByVal Index As Long, Optional ByVal Count As Long) As Long
Dim i As Long, j As Long, k As Long
i = 1
Do
 j = Index - GTheoryNode(i).Index
 If j = 0 Then 'found!
  pSolveItBinarySearchTreeFindNode = i
  Exit Function
 ElseIf j > 0 Then
  k = GTheoryNode(i).BinarySearchTreeRSon
  If k = 0 Then 'not found
   If Count > 0 Then
    k = Count + 1
    GTheoryNode(i).BinarySearchTreeRSon = k
    pSolveItBinarySearchTreeFindNode = k
   End If
   Exit Function
  End If
 Else
  k = GTheoryNode(i).BinarySearchTreeLSon
  If k = 0 Then 'not found
   If Count > 0 Then
    k = Count + 1
    GTheoryNode(i).BinarySearchTreeLSon = k
    pSolveItBinarySearchTreeFindNode = k
   End If
   Exit Function
  End If
 End If
 i = k
Loop
End Function

Private Function pSolveItCheckNodeState(ByVal m As Long, ByVal k As Long, ByVal State As Long, Optional ByVal k2 As Long) As Long
Dim X As Long, Y As Long, x2 As Long, y2 As Long
pSolveItCheckNodeState = -1 'invalid
With SwitchMapIdPos(m)
 If k > 0 And k <= .Count Then
  Select Case State
  Case 3 'single?
   If k2 > 0 And k2 <= .Count Then
    If k = k2 Then 'up
     Select Case SwitchMap(.p(k).X, .p(k).Y, m)
     Case 1, 2, 3, 7, 9, 10  '?
      pSolveItCheckNodeState = 0
     End Select
    Else
     X = .p(k).X
     Y = .p(k).Y
     x2 = .p(k2).X
     y2 = .p(k2).Y
     If Y = y2 And (X - x2 = 1 Or x2 - X = 1) Then 'h
      If X > x2 Then X = x2
      If X <= datw - 1 Then
       If Not (SwitchMap(X, Y, m) = 11 And SwitchMap(X + 1, Y, m) = 11) Then
        pSolveItCheckNodeState = 1
       End If
      End If
     ElseIf X = x2 And (Y - y2 = 1 Or y2 - Y = 1) Then 'v
      If Y > y2 Then Y = y2
      If Y <= dath - 1 Then
       If Not (SwitchMap(X, Y, m) = 11 And SwitchMap(X, Y + 1, m) = 11) Then
        pSolveItCheckNodeState = 2
       End If
      End If
     Else 'single
      If Not (SwitchMap(X, Y, m) = 11 Or SwitchMap(x2, y2, m) = 11) Then
       pSolveItCheckNodeState = 3
      End If
     End If
    End If
   End If
  Case 0 'up
   Select Case SwitchMap(.p(k).X, .p(k).Y, m)
   Case 1, 2, 3, 7, 9, 10  '?
    pSolveItCheckNodeState = 0
   End Select
  Case 1 'h
   X = .p(k).X
   Y = .p(k).Y
   If X <= datw - 1 Then
    If SwitchMapPosId(X + 1, Y, m) > 0 And Not (SwitchMap(X, Y, m) = 11 And SwitchMap(X + 1, Y, m) = 11) Then
     pSolveItCheckNodeState = 1
    End If
   End If
  Case 2 'v
   X = .p(k).X
   Y = .p(k).Y
   If Y <= dath - 1 Then
    If SwitchMapPosId(X, Y + 1, m) > 0 And Not (SwitchMap(X, Y, m) = 11 And SwitchMap(X, Y + 1, m) = 11) Then
     pSolveItCheckNodeState = 2
    End If
   End If
  End Select
 End If
End With
End Function

Private Function pSolveItCalcNext(SwitchTransTable() As Long, ByVal m As Long, ByVal k As Long, ByVal State As Long, ByVal FS As Long, ret As typeNextPos) As Long
Dim i As Long, j As Long, jj As Long, PJJ As Long
Dim X As Long, Y As Long
With SwitchMapIdPos(m).p(k)
 Select Case State
 Case 0 '/////////////up
  Select Case FS
  'X -> X
  '     X
  Case 1, 2 'up/down
   X = .X
   Y = 0
   If FS = 1 Then 'up
     If .Y > 2 Then
      If SwitchMap(.X, .Y - 1, m) = 9 And SwitchMap(.X, .Y - 2, m) = 9 Then 'ice
       For Y = .Y - 2 To 1 Step -1
        Select Case SwitchMap(.X, Y, m)
        Case 9 'ice
        Case 11
         Y = Y + 1
         Exit For
        Case Else
         Exit For
        End Select
       Next Y
      Else
       Y = .Y - 2
      End If
     End If
   Else 'down
     If .Y <= dath - 2 Then
      If SwitchMap(.X, .Y + 1, m) = 9 And SwitchMap(.X, .Y + 2, m) = 9 Then 'ice
       For Y = .Y + 2 To dath
        Select Case SwitchMap(.X, Y, m)
        Case 9 'ice
        Case 11
         Y = Y - 2
         Exit For
        Case Else
         Y = Y - 1
         Exit For
        End Select
       Next Y
      Else
       Y = .Y + 1
      End If
     End If
   End If
      If Y > 0 And Y <= dath - 1 Then
       If FS = 1 Then 'ERR!
        i = SwitchMap(X, Y + 1, m)
        j = SwitchMap(X, Y, m)
       Else
        i = SwitchMap(X, Y, m)
        j = SwitchMap(X, Y + 1, m)
       End If
       Select Case i
       Case 1, 2, 3, 4, 5, 7, 8, 9, 10
        Select Case j
        Case 1, 2, 3, 4, 5, 7, 8, 9, 10, 11
         'press button
         i = m
         If SwitchMap(X, Y, m) = 2 Then
          j = dat2(X, Y)
          If j > 0 And j <= swc Then
           i = SwitchTransTable(j, i)
          End If
         End If
         If SwitchMap(X, Y + 1, m) = 2 Then
          j = dat2(X, Y + 1)
          If j > 0 And j <= swc Then
           i = SwitchTransTable(j, i)
          End If
         End If
         j = SwitchMapPosId(X, Y, i)
         jj = SwitchMapPosId(X, Y + 1, i)
         If j > 0 And jj > 0 Then
          ret.m = i
          If IsTrans Then
           ret.k = j
           ret.k2 = jj
           j = SwitchMapIdPos(i).AllPosDelta + pSolveItPosToInt(j, jj)
          Else
           ret.k = j
           ret.k2 = 2
           j = SwitchMapIdPos(i).AllPosDelta + SwitchMapIdPos(i).Count * 2 + j
          End If
          pSolveItCalcNext = j
         End If
        End Select
       End Select
      End If
  'X -> XX
  Case 3, 4    'left/right
   X = 0
   Y = .Y
   If FS = 3 Then 'left
     If .X > 2 Then
      If SwitchMap(.X - 1, .Y, m) = 9 And SwitchMap(.X - 2, .Y, m) = 9 Then 'ice
       For X = .X - 2 To 1 Step -1
        Select Case SwitchMap(X, .Y, m)
        Case 9 'ice
        Case 11
         X = X + 1
         Exit For
        Case Else
         Exit For
        End Select
       Next X
      Else
       X = .X - 2
      End If
     End If
   Else 'right
     If .X <= datw - 2 Then
      If SwitchMap(.X + 1, .Y, m) = 9 And SwitchMap(.X + 2, .Y, m) = 9 Then 'ice
       For X = .X + 2 To datw
        Select Case SwitchMap(X, .Y, m)
        Case 9 'ice
        Case 11
         X = X - 2
         Exit For
        Case Else
         X = X - 1
         Exit For
        End Select
       Next X
      Else
       X = .X + 1
      End If
     End If
   End If
      If X > 0 And X <= datw - 1 Then
       If FS = 3 Then 'ERR!
        i = SwitchMap(X + 1, Y, m)
        j = SwitchMap(X, Y, m)
       Else
        i = SwitchMap(X, Y, m)
        j = SwitchMap(X + 1, Y, m)
       End If
       Select Case i
       Case 1, 2, 3, 4, 5, 7, 8, 9, 10
        Select Case j
        Case 1, 2, 3, 4, 5, 7, 8, 9, 10, 11
         'press button
         i = m
         If SwitchMap(X, Y, m) = 2 Then
          j = dat2(X, Y)
          If j > 0 And j <= swc Then
           i = SwitchTransTable(j, i)
          End If
         End If
         If SwitchMap(X + 1, Y, m) = 2 Then
          j = dat2(X + 1, Y)
          If j > 0 And j <= swc Then
           i = SwitchTransTable(j, i)
          End If
         End If
         j = SwitchMapPosId(X, Y, i)
         jj = SwitchMapPosId(X + 1, Y, i)
         If j > 0 And jj > 0 Then
          ret.m = i
          If IsTrans Then
           ret.k = j
           ret.k2 = jj
           j = SwitchMapIdPos(i).AllPosDelta + pSolveItPosToInt(j, jj)
          Else
           ret.k = j
           ret.k2 = 1
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
   X = .X
   Y = 0
   If FS = 1 Then 'up
      If .Y > 1 Then
       If SwitchMap(.X, .Y - 1, m) = 9 And SwitchMap(.X + 1, .Y - 1, m) = 9 Then 'ice
        For Y = .Y - 1 To 1 Step -1
         If SwitchMap(.X, Y, m) = 9 And SwitchMap(.X + 1, Y, m) = 9 Then
         ElseIf SwitchMap(.X, Y, m) = 11 Or SwitchMap(.X + 1, Y, m) = 11 Then
          Y = Y + 1
          Exit For
         Else
          Exit For
         End If
        Next Y
       Else
        Y = .Y - 1
       End If
      End If
   Else 'down
      If .Y < dath Then
       If SwitchMap(.X, .Y + 1, m) = 9 And SwitchMap(.X + 1, .Y + 1, m) = 9 Then 'ice
        For Y = .Y + 1 To dath
         If SwitchMap(.X, Y, m) = 9 And SwitchMap(.X + 1, Y, m) = 9 Then
         ElseIf SwitchMap(.X, Y, m) = 11 Or SwitchMap(.X + 1, Y, m) = 11 Then
          Y = Y - 1
          Exit For
         Else
          Exit For
         End If
        Next Y
       Else
        Y = .Y + 1
       End If
      End If
   End If
       If Y > 0 And Y <= dath Then
        j = SwitchMap(X + 1, Y, m)
        If j <> 0 And j <> 6 And (j <> 11 Or SwitchMap(.X + 1, .Y, m) = 11) Then
         j = SwitchMap(X, Y, m)
         If j <> 0 And j <> 6 And (j <> 11 Or SwitchMap(.X, .Y, m) = 11) Then
          'press button
          i = m
          If j = 2 Then
           j = dat2(X, Y)
           If j > 0 And j <= swc Then
            i = SwitchTransTable(j, i)
           End If
          End If
          If SwitchMap(X + 1, Y, m) = 2 Then
           j = dat2(X + 1, Y)
           If j > 0 And j <= swc Then
            i = SwitchTransTable(j, i)
           End If
          End If
          j = SwitchMapPosId(X, Y, i)
          jj = SwitchMapPosId(X + 1, Y, i)
          If j > 0 And jj > 0 Then
           ret.m = i
           If IsTrans Then
            ret.k = j
            ret.k2 = jj
            j = SwitchMapIdPos(i).AllPosDelta + pSolveItPosToInt(j, jj)
           Else
            ret.k = j
            ret.k2 = 1
            j = SwitchMapIdPos(i).AllPosDelta + SwitchMapIdPos(i).Count + j
           End If
           pSolveItCalcNext = j
          End If
         End If
        End If
       End If
  'XX -> X
  Case 3, 4     'left/right
   X = 0
   Y = .Y
   If FS = 3 Then 'left
      If .X > 1 Then
       If SwitchMap(.X, .Y, m) = 11 Then 'block
       ElseIf SwitchMap(.X - 1, .Y, m) = 9 Then 'ice
        For X = .X - 1 To 1 Step -1
         Select Case SwitchMap(X, .Y, m)
         Case 9
         Case 11
          X = X + 1
          Exit For
         Case Else
          Exit For
         End Select
        Next X
       Else
        X = .X - 1
       End If
      End If
   Else 'right
      If .X <= datw - 2 Then
       If SwitchMap(.X + 1, .Y, m) = 11 Then 'block
       ElseIf SwitchMap(.X + 2, .Y, m) = 9 Then 'ice
        For X = .X + 2 To datw
         Select Case SwitchMap(X, .Y, m)
         Case 9
         Case 11
          X = X - 1
          Exit For
         Case Else
          Exit For
         End Select
        Next X
       Else
        X = .X + 2
       End If
      End If
   End If
       If X > 0 And X <= datw Then
        j = SwitchMap(X, Y, m)
        Select Case j
        Case 1, 2, 3, 7, 8, 9
         'press button
         i = m
         If j = 2 Or j = 3 Then
          j = dat2(X, Y)
          If j > 0 And j <= swc Then
           i = SwitchTransTable(j, i)
          End If
         End If
         j = SwitchMapPosId(X, Y, i)
         If j > 0 Then
          ret.m = i
          If IsTrans Then
           ret.k = j
           ret.k2 = j
           j = SwitchMapIdPos(i).AllPosDelta + (j * (j + 1)) \ 2
          Else
           ret.k = j
           ret.k2 = 0
           j = SwitchMapIdPos(i).AllPosDelta + j
          End If
          pSolveItCalcNext = j
         End If
        Case 4 'trans
         GetTransportPosition X, Y, i, j, jj, PJJ
         j = SwitchMapPosId(i, j, m)
         jj = SwitchMapPosId(jj, PJJ, m)
         If j > 0 And jj > 0 Then
          ret.m = m
          If IsTrans Then
           ret.k = j
           ret.k2 = jj
           j = SwitchMapIdPos(m).AllPosDelta + pSolveItPosToInt(j, jj)
          Else
           Debug.Assert False 'err!!
          End If
          pSolveItCalcNext = j
         End If
        Case 10 'pyramid
         j = SwitchMapPosId(X, Y, m)
         'hit block?
         If FS = 3 Then 'left
          If X > 2 Then
           If SwitchMap(X - 1, Y, m) = 11 Then
            ret.m = m
            If IsTrans Then
             ret.k = j
             ret.k2 = j
             j = SwitchMapIdPos(m).AllPosDelta + (j * (j + 1)) \ 2
            Else
             ret.k = j
             ret.k2 = 0
             j = SwitchMapIdPos(m).AllPosDelta + j
            End If
            pSolveItCalcNext = j
           Else
            pSolveItCalcNext = pSolveItCalcNext(SwitchTransTable, m, j, 0, FS, ret)
           End If
          End If
         Else 'right
          If X <= datw - 2 Then
           If SwitchMap(X + 1, Y, m) = 11 Then
            ret.m = m
            If IsTrans Then
             ret.k = j
             ret.k2 = j
             j = SwitchMapIdPos(m).AllPosDelta + (j * (j + 1)) \ 2
            Else
             ret.k = j
             ret.k2 = 0
             j = SwitchMapIdPos(m).AllPosDelta + j
            End If
            pSolveItCalcNext = j
           Else
            pSolveItCalcNext = pSolveItCalcNext(SwitchTransTable, m, j, 0, FS, ret)
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
   X = .X
   Y = 0
   If FS = 1 Then 'up
      If .Y > 1 Then
       If SwitchMap(.X, .Y, m) = 11 Then 'block
       ElseIf SwitchMap(.X, .Y - 1, m) = 9 Then 'ice
        For Y = .Y - 1 To 1 Step -1
         Select Case SwitchMap(.X, Y, m)
         Case 9
         Case 11
          Y = Y + 1
          Exit For
         Case Else
          Exit For
         End Select
        Next Y
       Else
        Y = .Y - 1
       End If
      End If
   Else 'down
      If .Y <= dath - 2 Then
       If SwitchMap(.X, .Y + 1, m) = 11 Then 'block
       ElseIf SwitchMap(.X, .Y + 2, m) = 9 Then 'ice
        For Y = .Y + 2 To dath
         Select Case SwitchMap(.X, Y, m)
         Case 9
         Case 11
          Y = Y - 1
          Exit For
         Case Else
          Exit For
         End Select
        Next Y
       Else
        Y = .Y + 2
       End If
      End If
   End If
       If Y > 0 And Y <= dath Then
        j = SwitchMap(X, Y, m)
        Select Case j
        Case 1, 2, 3, 7, 8, 9
         'press button
         i = m
         If j = 2 Or j = 3 Then
          j = dat2(X, Y)
          If j > 0 And j <= swc Then
           i = SwitchTransTable(j, i)
          End If
         End If
         j = SwitchMapPosId(X, Y, i)
         If j > 0 Then
          ret.m = i
          If IsTrans Then
           ret.k = j
           ret.k2 = j
           j = SwitchMapIdPos(i).AllPosDelta + (j * (j + 1)) \ 2
          Else
           ret.k = j
           ret.k2 = 0
           j = SwitchMapIdPos(i).AllPosDelta + j
          End If
          pSolveItCalcNext = j
         End If
        Case 4 'trans
         GetTransportPosition X, Y, i, j, jj, PJJ
         j = SwitchMapPosId(i, j, m)
         jj = SwitchMapPosId(jj, PJJ, m)
         If j > 0 And jj > 0 Then
          ret.m = m
          If IsTrans Then
           ret.k = j
           ret.k2 = jj
           j = SwitchMapIdPos(m).AllPosDelta + pSolveItPosToInt(j, jj)
          Else
           Debug.Assert False 'err!!
          End If
          pSolveItCalcNext = j
         End If
        Case 10 'pyramid
         j = SwitchMapPosId(X, Y, m)
         'hit block?
         If FS = 1 Then 'up
          If Y > 2 Then
           If SwitchMap(X, Y - 1, m) = 11 Then
            ret.m = m
            If IsTrans Then
             ret.k = j
             ret.k2 = j
             j = SwitchMapIdPos(m).AllPosDelta + (j * (j + 1)) \ 2
            Else
             ret.k = j
             ret.k2 = 0
             j = SwitchMapIdPos(m).AllPosDelta + j
            End If
            pSolveItCalcNext = j
           Else
            pSolveItCalcNext = pSolveItCalcNext(SwitchTransTable, m, j, 0, FS, ret)
           End If
          End If
         Else 'down
          If Y <= dath - 2 Then
           If SwitchMap(X, Y + 1, m) = 11 Then
            ret.m = m
            If IsTrans Then
             ret.k = j
             ret.k2 = j
             j = SwitchMapIdPos(m).AllPosDelta + (j * (j + 1)) \ 2
            Else
             ret.k = j
             ret.k2 = 0
             j = SwitchMapIdPos(m).AllPosDelta + j
            End If
            pSolveItCalcNext = j
           Else
            pSolveItCalcNext = pSolveItCalcNext(SwitchTransTable, m, j, 0, FS, ret)
           End If
          End If
         End If
        End Select
       End If
  'X -> X
  'X    X
  Case 3, 4   'left/right
   X = 0
   Y = .Y
   If FS = 3 Then 'left
      If .X > 1 Then
       If SwitchMap(.X - 1, .Y, m) = 9 And SwitchMap(.X - 1, .Y + 1, m) = 9 Then 'ice
        For X = .X - 1 To 1 Step -1
         If SwitchMap(X, .Y, m) = 9 And SwitchMap(X, .Y + 1, m) = 9 Then
         ElseIf SwitchMap(X, .Y, m) = 11 Or SwitchMap(X, .Y + 1, m) = 11 Then
          X = X + 1
          Exit For
         Else
          Exit For
         End If
        Next X
       Else
        X = .X - 1
       End If
      End If
   Else 'right
      If .X < datw Then
       If SwitchMap(.X + 1, .Y, m) = 9 And SwitchMap(.X + 1, .Y + 1, m) = 9 Then 'ice
        For X = .X + 1 To datw
         If SwitchMap(X, .Y, m) = 9 And SwitchMap(X, .Y + 1, m) = 9 Then
         ElseIf SwitchMap(X, .Y, m) = 11 Or SwitchMap(X, .Y + 1, m) = 11 Then
          X = X - 1
          Exit For
         Else
          Exit For
         End If
        Next X
       Else
        X = .X + 1
       End If
      End If
   End If
       If X > 0 And X <= datw Then
        j = SwitchMap(X, Y + 1, m)
        If j <> 0 And j <> 6 And (j <> 11 Or SwitchMap(.X, .Y + 1, m) = 11) Then
         j = SwitchMap(X, Y, m)
         If j <> 0 And j <> 6 And (j <> 11 Or SwitchMap(.X, .Y, m) = 11) Then
          'press button
          i = m
          If j = 2 Then
           j = dat2(X, Y)
           If j > 0 And j <= swc Then
            i = SwitchTransTable(j, i)
           End If
          End If
          If SwitchMap(X, Y + 1, m) = 2 Then
           j = dat2(X, Y + 1)
           If j > 0 And j <= swc Then
            i = SwitchTransTable(j, i)
           End If
          End If
          j = SwitchMapPosId(X, Y, i)
          jj = SwitchMapPosId(X, Y + 1, i)
          If j > 0 And jj > 0 Then
           ret.m = i
           If IsTrans Then
            ret.k = j
            ret.k2 = jj
            j = SwitchMapIdPos(i).AllPosDelta + pSolveItPosToInt(j, jj)
           Else
            ret.k = j
            ret.k2 = 2
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

Private Function pSolveItCalcNextSingle(SwitchTransTable() As Long, ByVal m As Long, ByVal k As Long, ByVal k2 As Long, ByVal FS As Long, ret As typeNextPos) As Long
Dim i As Long, j As Long, jj As Long
Dim X As Long, Y As Long, x2 As Long, y2 As Long
'IsTrans must be true!
With SwitchMapIdPos(m)
 x2 = .p(k2).X
 y2 = .p(k2).Y
 With .p(k)
  Select Case FS
  Case 1 'up
      If .Y > 1 Then
       X = .X
       If SwitchMap(.X, .Y - 1, m) = 9 Then 'ice
        For Y = .Y - 1 To 1 Step -1
         If x2 = X And y2 = Y Then 'hit another block
          Y = Y + 1
          Exit For
         End If
         Select Case SwitchMap(X, Y, m)
         Case 9
         Case 11
          Y = Y + 1
          Exit For
         Case Else
          Exit For
         End Select
        Next Y
       Else
        Y = .Y - 1
       End If
      End If
  Case 2 'down
      If .Y < dath Then
       X = .X
       If SwitchMap(.X, .Y + 1, m) = 9 Then 'ice
        For Y = .Y + 1 To dath
         If x2 = X And y2 = Y Then 'hit another block
          Y = Y - 1
          Exit For
         End If
         Select Case SwitchMap(X, Y, m)
         Case 9
         Case 11
          Y = Y - 1
          Exit For
         Case Else
          Exit For
         End Select
        Next Y
       Else
        Y = .Y + 1
       End If
      End If
  Case 3 'left
      If .X > 1 Then
       Y = .Y
       If SwitchMap(.X - 1, .Y, m) = 9 Then 'ice
        For X = .X - 1 To 1 Step -1
         If x2 = X And y2 = Y Then 'hit another block
          X = X + 1
          Exit For
         End If
         Select Case SwitchMap(X, Y, m)
         Case 9
         Case 11
          X = X + 1
          Exit For
         Case Else
          Exit For
         End Select
        Next X
       Else
        X = .X - 1
       End If
      End If
  Case 4 'right
      If .X < datw Then
       Y = .Y
       If SwitchMap(.X + 1, .Y, m) = 9 Then 'ice
        For X = .X + 1 To datw
         If x2 = X And y2 = Y Then 'hit another block
          X = X - 1
          Exit For
         End If
         Select Case SwitchMap(X, Y, m)
         Case 9
         Case 11
          X = X - 1
          Exit For
         Case Else
          Exit For
         End Select
        Next X
       Else
        X = .X + 1
       End If
      End If
  End Select
       If X > 0 And Y > 0 And X <= datw And Y <= dath Then
        Select Case SwitchMap(X, Y, m)
        Case 1, 2, 3, 4, 5, 7, 8, 9, 10
         'press button
         i = m
         If SwitchMap(X, Y, m) = 2 Then
          j = dat2(X, Y)
          If j > 0 And j <= swc Then
           i = SwitchTransTable(j, i)
          End If
         End If
         j = SwitchMapPosId(X, Y, i)
         jj = SwitchMapPosId(x2, y2, i)
         If j > 0 And jj > 0 Then
          With ret
           .m = i
           .k = j
           .k2 = jj
          End With
          j = SwitchMapIdPos(i).AllPosDelta + pSolveItPosToInt(j, jj)
          pSolveItCalcNextSingle = j
         End If
        End Select
       End If
 End With
End With
End Function

Public Sub SolveItClear()
Erase SwitchMap
Erase SwitchMapPosId
Erase SwitchMapIdPos
Erase GTheoryNode
SwitchStatusCount = 0
GTheoryNodeMax = 0
End Sub

Private Function pSolveItPosToInt(ByVal p1 As Long, ByVal p2 As Long) As Long
If p1 > p2 Then
 pSolveItPosToInt = (p1 * (p1 - 1)) \ 2 + p2
Else
 pSolveItPosToInt = (p2 * (p2 - 1)) \ 2 + p1
End If
End Function

'Private Sub pSolveItIntToPos(ByVal n As Long, p1 As Long, p2 As Long) 'unused
'p2 = Round(Sqr(n + n))
'p1 = n - (p2 * (p2 - 1)) \ 2
'End Sub

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
     .X = i
     .Y = j
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

Public Function SolveItIsTrans() As Boolean
SolveItIsTrans = IsTrans
End Function

Public Function SolveItGetNodeUsed() As Long
SolveItGetNodeUsed = GTheoryNodeUsed
End Function

Public Function SolveItGetNodeMax() As Long
SolveItGetNodeMax = GTheoryNodeMax
End Function

Public Function SolveItGetTimeUsed() As Long
SolveItGetTimeUsed = SolveItTime
End Function

Public Function SolveItGetSwitchStatusCount() As Long
SolveItGetSwitchStatusCount = SwitchStatusCount
End Function

Public Sub SolveItGetSwitchStatus(ByVal Index As Long, d() As Byte)
ReDim d(1 To datw, 1 To dath)
CopyMemory d(1, 1), SwitchMap(1, 1, Index), datw * dath
End Sub

Public Function SolveItGetDistance(ByVal Index As Long) As Long
Dim i As Long
i = pSolveItBinarySearchTreeFindNode(Index)
If i > 0 Then
 SolveItGetDistance = GTheoryNode(i).Distance
Else
 SolveItGetDistance = &H7FFFFFFF
End If
End Function

Public Function SolveItGetSolution(ByVal Index As Long, Optional ByVal lpMovedArea As Long) As String
Dim s As String, ss As String
Dim i As Long, j As Long, k As Long, m As Long
Dim X As Long, Y As Long, x2 As Long, y2 As Long
Dim xo As Long, yo As Long, xo2 As Long, yo2 As Long
Dim jj As Long
Dim IsL As Boolean, IsLo As Boolean
Dim MOV As Long, MOVo As Long
Dim d() As Byte, nds() As Long
ReDim d(1 To datw, 1 To dath)
i = pSolveItBinarySearchTreeFindNode(Index)
If i = 0 Then Exit Function
m = GTheoryNode(i).Distance
If m = 0 Or m = &H7FFFFFFF Then Exit Function
ReDim nds(1 To m)
For k = m To 1 Step -1
 nds(k) = i
 j = GTheoryNode(i).PathPrevEdge
 If j = 0 Then Debug.Assert False 'Exit Do
 s = CStr(j) + s
 i = GTheoryNode(i).PathPrevNode
Next k
If IsTrans Then '??????????????????????????????
 xo = StartX
 yo = StartY
 xo2 = StartX
 yo2 = StartY
 d(xo, yo) = 1
 IsLo = True
 MOVo = 0
 For k = 1 To m
  j = Val(Mid(s, k, 1))
  i = nds(k)
  With GTheoryNode(i)
   'determine status index
   jj = .m
   'get pos
   Y = .k
   y2 = .k2
  End With
  With SwitchMapIdPos(jj)
   X = .p(Y).X
   Y = .p(Y).Y
   x2 = .p(y2).X
   y2 = .p(y2).Y
  End With
  'which is moved?
  j = 1 + (j - 1) Mod 4
  IsL = (X - x2) * (X - x2) + (Y - y2) * (Y - y2) <= 1
  If IsLo Then
   If IsL Then 'ice??
    MOV = 0
    If j <= 2 Then
     If xo = X Then
      pSolveItCalcMovedArea d, xo, yo, X, Y, j
      pSolveItCalcMovedArea d, xo2, yo2, x2, y2, j
     ElseIf xo = x2 Then
      pSolveItCalcMovedArea d, xo, yo, x2, y2, j
      pSolveItCalcMovedArea d, xo2, yo2, X, Y, j
     Else
      Debug.Assert False
     End If
    Else
     If yo = Y Then
      pSolveItCalcMovedArea d, xo, yo, X, Y, j
      pSolveItCalcMovedArea d, xo2, yo2, x2, y2, j
     ElseIf yo = y2 Then
      pSolveItCalcMovedArea d, xo, yo, x2, y2, j
      pSolveItCalcMovedArea d, xo2, yo2, X, Y, j
     Else
      Debug.Assert False
     End If
    End If
    xo = X
    yo = Y
    xo2 = x2
    yo2 = y2
   Else 'enter trans
    MOV = 1
    Select Case j 'ice??
    Case 1 'up
     X = xo
     For Y = IIf(yo < yo2, yo, yo2) - 1 To 1 Step -1
      d(X, Y) = 1
      If dat(X, Y) = 4 Then Exit For
     Next Y
    Case 2 'down
     X = xo
     For Y = IIf(yo < yo2, yo, yo2) + 2 To dath
      d(X, Y) = 1
      If dat(X, Y) = 4 Then Exit For
     Next Y
    Case 3 'left
     Y = yo
     For X = IIf(xo < xo2, xo, xo2) - 1 To 1 Step -1
      d(X, Y) = 1
      If dat(X, Y) = 4 Then Exit For
     Next X
    Case 4 'right
     Y = yo
     For X = IIf(xo < xo2, xo, xo2) + 2 To datw
      d(X, Y) = 1
      If dat(X, Y) = 4 Then Exit For
     Next X
    End Select
    GetTransportPosition X, Y, X, Y, x2, y2
    xo = X
    yo = Y
    xo2 = x2
    yo2 = y2
   End If
  Else
   If xo = X And yo = Y Then
    MOV = 2
    pSolveItCalcMovedArea d, xo2, yo2, x2, y2, j
    xo2 = x2
    yo2 = y2
   ElseIf xo = x2 And yo = y2 Then
    MOV = 2
    pSolveItCalcMovedArea d, xo2, yo2, X, Y, j
    xo2 = X
    yo2 = Y
   ElseIf xo2 = X And yo2 = Y Then
    MOV = 1
    pSolveItCalcMovedArea d, xo, yo, x2, y2, j
    xo = x2
    yo = y2
   ElseIf xo2 = x2 And yo2 = y2 Then
    MOV = 1
    pSolveItCalcMovedArea d, xo, yo, X, Y, j
    xo = X
    yo = Y
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
  d(X, Y) = 1
  d(x2, y2) = 1
  'next
  MOVo = MOV
  IsLo = IsL
 Next k
 s = ss
ElseIf lpMovedArea <> 0 Then
 xo = StartX
 yo = StartY
 d(xo, yo) = 1
 For k = 1 To m
  j = Val(Mid(s, k, 1))
  i = nds(k)
  With GTheoryNode(i)
   'determine status index
   jj = .m
   'get pos
   x2 = .k
   y2 = .k2
  End With
  With SwitchMapIdPos(jj).p(x2)
   X = .X
   Y = .Y
  End With
  'moved area
  d(X, Y) = 1
  Select Case y2
  Case 0 'up
   pSolveItCalcMovedArea d, xo, yo, X, Y, j
  Case 1 'h
   pSolveItCalcMovedArea d, xo, yo, X, Y, j
   If j = 3 Then
    pSolveItCalcMovedArea d, xo, yo, X + 1, Y, j
   Else
    pSolveItCalcMovedArea d, xo + 1, yo, X + 1, Y, j
   End If
  Case 2 'v
   pSolveItCalcMovedArea d, xo, yo, X, Y, j
   If j = 1 Then
    pSolveItCalcMovedArea d, xo, yo, X, Y + 1, j
   Else
    pSolveItCalcMovedArea d, xo, yo + 1, X, Y + 1, j
   End If
  Case 3 'ERR!
   Debug.Assert False
  End Select
  'next
  xo = X
  yo = Y
 Next k
End If
If lpMovedArea <> 0 Then CopyMemory ByVal lpMovedArea, d(1, 1), datw * dath
s = Replace(s, "1", "u")
s = Replace(s, "2", "d")
s = Replace(s, "3", "l")
s = Replace(s, "4", "r")
SolveItGetSolution = s
End Function

Private Sub pSolveItCalcMovedArea(d() As Byte, ByVal xo As Long, ByVal yo As Long, ByVal X As Long, ByVal Y As Long, ByVal FS As Long)
Dim k As Long
   Select Case FS
   Case 1 'up
    For k = yo To Y Step -1
     d(X, k) = 1
    Next k
   Case 2 'down
    For k = yo To Y
     d(X, k) = 1
    Next k
   Case 3 'left
    For k = xo To X Step -1
     d(k, Y) = 1
    Next k
   Case 4 'right
    For k = xo To X
     d(k, Y) = 1
    Next k
   End Select
End Sub

Public Function SolveItGetSolutionNodeIndex(Optional SolX As Long, Optional SolY As Long, Optional SolSwitchStatus As Long) As Long
Dim i As Long, j As Long, k As Long, n As Long, m As Long
Dim X As Long, Y As Long
   m = &H7FFFFFFF
   For X = 1 To datw
    For Y = 1 To dath
     If dat(X, Y) = 8 Then
      For i = 1 To SwitchStatusCount
       j = SolveItGetNodeIndex(i, 0, X, Y)
       k = pSolveItBinarySearchTreeFindNode(j)
       If k > 0 Then
        k = GTheoryNode(k).Distance
        If k < m Then
         m = k
         n = j
         SolX = X
         SolY = Y
         SolSwitchStatus = i
        End If
       End If
      Next i
     End If
    Next Y
   Next X
   SolveItGetSolutionNodeIndex = n
End Function

Public Function SolveItGetNodeIndex(ByVal m As Long, ByVal State As Long, ByVal X As Long, ByVal Y As Long, Optional ByVal x2 As Long, Optional ByVal y2 As Long) As Long
Dim j As Long, jj As Long
With SwitchMapIdPos(m)
 If IsTrans Then
  Select Case State
  Case 0
   j = SwitchMapPosId(X, Y, m)
   If j > 0 Then
    SolveItGetNodeIndex = .AllPosDelta + (j * (j + 1)) \ 2
   End If
  Case 1
   If X < datw Then
    j = SwitchMapPosId(X, Y, m)
    jj = SwitchMapPosId(X + 1, Y, m)
    If j > 0 And jj > 0 Then
     SolveItGetNodeIndex = .AllPosDelta + pSolveItPosToInt(j, jj)
    End If
   End If
  Case 2
   If Y < dath Then
    j = SwitchMapPosId(X, Y, m)
    jj = SwitchMapPosId(X, Y + 1, m)
    If j > 0 And jj > 0 Then
     SolveItGetNodeIndex = .AllPosDelta + pSolveItPosToInt(j, jj)
    End If
   End If
  Case 3
   j = SwitchMapPosId(X, Y, m)
   jj = SwitchMapPosId(x2, y2, m)
   If j > 0 And jj > 0 Then
    SolveItGetNodeIndex = .AllPosDelta + pSolveItPosToInt(j, jj)
   End If
  End Select
 Else
  Select Case State
  Case 0
   j = SwitchMapPosId(X, Y, m)
   If j > 0 Then
    SolveItGetNodeIndex = .AllPosDelta + j
   End If
  Case 1
   j = SwitchMapPosId(X, Y, m)
   If j > 0 Then
    SolveItGetNodeIndex = .AllPosDelta + .Count + j
   End If
  Case 2
   j = SwitchMapPosId(X, Y, m)
   If j > 0 Then
    SolveItGetNodeIndex = .AllPosDelta + .Count * 2 + j
   End If
  End Select
 End If
End With
End Function

Public Function BloxorzCheckIsValidState(d() As Byte, ByVal X As Long, ByVal Y As Long, ByVal GameS As Long, Optional ByVal x2 As Long, Optional ByVal y2 As Long) As enumBloxorzStateValid
Select Case GameS
Case 0 'up
 If X > 0 And Y > 0 And X <= datw And Y <= dath Then
  Select Case d(X, Y)
  Case 11 'block
   'ERR!!
   BloxorzCheckIsValidState = 99
  Case 0, 6
   BloxorzCheckIsValidState = 0
  Case 5
   BloxorzCheckIsValidState = 2
  Case Else
   BloxorzCheckIsValidState = 1
  End Select
 End If
Case 1 'h
 If X > 0 And Y > 0 And X < datw And Y <= dath Then
  If d(X, Y) = 11 And d(X + 1, Y) = 11 Then
   'ERR!
   BloxorzCheckIsValidState = 99
  ElseIf d(X, Y) = 0 Or d(X, Y) = 6 Or d(X + 1, Y) = 0 Or d(X + 1, Y) = 6 Then
   BloxorzCheckIsValidState = 0
  Else
   BloxorzCheckIsValidState = 1
  End If
 End If
Case 2 'v
 If X > 0 And Y > 0 And X <= datw And Y < dath Then
  If d(X, Y) = 11 And d(X, Y + 1) = 11 Then
   'ERR!
   BloxorzCheckIsValidState = 99
  ElseIf d(X, Y) = 0 Or d(X, Y) = 6 Or d(X, Y + 1) = 0 Or d(X, Y + 1) = 6 Then
   BloxorzCheckIsValidState = 0
  Else
   BloxorzCheckIsValidState = 1
  End If
 End If
Case 3 'single
 If X > 0 And Y > 0 And X <= datw And Y <= dath Then
  If x2 > 0 And y2 > 0 And x2 <= datw And y2 <= dath Then
   If d(X, Y) = 11 Or d(x2, y2) = 11 Then
    'ERR!
    BloxorzCheckIsValidState = 99
   ElseIf d(X, Y) = 0 Or d(X, Y) = 6 Or d(x2, y2) = 0 Or d(x2, y2) = 6 Then
    BloxorzCheckIsValidState = 0
   Else
    BloxorzCheckIsValidState = 1
   End If
  End If
 Else
 End If
End Select
End Function

Public Function BloxorzCheckIsMovable(d() As Byte, ByVal X As Long, ByVal Y As Long, ByVal GameS As Long, ByVal FS As Long, Optional QIE As Long) As Boolean
BloxorzCheckIsMovable = True
QIE = 0
Select Case GameS
Case 0, 3 'up/single
 Select Case FS
 Case 1 'up
  If Y > 1 Then
   If d(X, Y - 1) = 11 Then BloxorzCheckIsMovable = False
   If GameS = 0 And Y > 2 Then If d(X, Y - 2) = 11 Then QIE = 1
  End If
 Case 2 'down
  If Y < dath Then
   If d(X, Y + 1) = 11 Then BloxorzCheckIsMovable = False
   If GameS = 0 And Y < dath - 1 Then If d(X, Y + 2) = 11 Then QIE = 2
  End If
 Case 3 'left
  If X > 1 Then
   If d(X - 1, Y) = 11 Then BloxorzCheckIsMovable = False
   If GameS = 0 And X > 2 Then If d(X - 2, Y) = 11 Then QIE = 3
  End If
 Case 4 'right
  If X < datw Then
   If d(X + 1, Y) = 11 Then BloxorzCheckIsMovable = False
   If GameS = 0 And X < datw - 1 Then If d(X + 2, Y) = 11 Then QIE = 4
  End If
 End Select
Case 1 'h
 Select Case FS
 Case 1 'up
  If Y > 1 Then
   If d(X, Y - 1) = 11 Then If d(X, Y) <> 11 Then BloxorzCheckIsMovable = False Else QIE = 3 'left block?
   If d(X + 1, Y - 1) = 11 Then If d(X + 1, Y) <> 11 Then BloxorzCheckIsMovable = False Else QIE = 4 'right block?
  End If
 Case 2 'down
  If Y < dath Then
   If d(X, Y + 1) = 11 Then If d(X, Y) <> 11 Then BloxorzCheckIsMovable = False Else QIE = 3 'left block?
   If d(X + 1, Y + 1) = 11 Then If d(X + 1, Y) <> 11 Then BloxorzCheckIsMovable = False Else QIE = 4 'right block?
  End If
 Case 3 'left
  If X > 1 Then If d(X - 1, Y) = 11 Then BloxorzCheckIsMovable = False
  If d(X, Y) = 11 Then BloxorzCheckIsMovable = False
 Case 4 'right
  If X < datw - 1 Then If d(X + 2, Y) = 11 Then BloxorzCheckIsMovable = False
  If d(X + 1, Y) = 11 Then BloxorzCheckIsMovable = False
 End Select
Case 2 'v
 Select Case FS
 Case 1 'up
  If Y > 1 Then If d(X, Y - 1) = 11 Then BloxorzCheckIsMovable = False
  If d(X, Y) = 11 Then BloxorzCheckIsMovable = False
 Case 2 'down
  If Y < dath - 1 Then If d(X, Y + 2) = 11 Then BloxorzCheckIsMovable = False
  If d(X, Y + 1) = 11 Then BloxorzCheckIsMovable = False
 Case 3 'left
  If X > 1 Then
   If d(X - 1, Y) = 11 Then If d(X, Y) <> 11 Then BloxorzCheckIsMovable = False Else QIE = 1 'up block?
   If d(X - 1, Y + 1) = 11 Then If d(X, Y + 1) <> 11 Then BloxorzCheckIsMovable = False Else QIE = 2 'down block?
  End If
 Case 4 'right
  If X < datw Then
   If d(X + 1, Y) = 11 Then If d(X, Y) <> 11 Then BloxorzCheckIsMovable = False Else QIE = 1 'up block?
   If d(X + 1, Y + 1) = 11 Then If d(X, Y + 1) <> 11 Then BloxorzCheckIsMovable = False Else QIE = 2 'down block?
  End If
 End Select
End Select
End Function

Public Function BloxorzCheckBlockSlip(d() As Byte, ByVal X As Long, ByVal Y As Long, ByVal GameS As Long, ByVal FS As Long, Optional ByVal x2 As Long, Optional ByVal y2 As Long) As Long
'TODO:new block?
Select Case GameS
Case 0, 3 'up/single
 'hit block?
 Select Case FS
 Case 1 'up
  If Y > 1 Then
   If dat(X, Y - 1) = 11 Then Exit Function
   If GameS = 3 And X = x2 And Y - 1 = y2 Then Exit Function
  End If
 Case 2 'down
  If Y < dath Then
   If dat(X, Y + 1) = 11 Then Exit Function
   If GameS = 3 And X = x2 And Y + 1 = y2 Then Exit Function
  End If
 Case 3 'left
  If X > 1 Then
   If dat(X - 1, Y) = 11 Then Exit Function
   If GameS = 3 And Y = y2 And X - 1 = x2 Then Exit Function
  End If
 Case 4 'right
  If X < datw Then
   If dat(X + 1, Y) = 11 Then Exit Function
   If GameS = 3 And Y = y2 And X + 1 = x2 Then Exit Function
  End If
 End Select
 Select Case d(X, Y)
 Case 9 'ice
  BloxorzCheckBlockSlip = FS
 End Select
Case 1 'h
 'hit block?
 Select Case FS
 Case 1 'up
  If Y > 1 Then
   If dat(X, Y - 1) = 11 Or dat(X + 1, Y - 1) = 11 Then Exit Function
  End If
 Case 2 'down
  If Y < dath Then
   If dat(X, Y + 1) = 11 Or dat(X + 1, Y + 1) = 11 Then Exit Function
  End If
 Case 3 'left
  If X > 1 Then
   If dat(X - 1, Y) = 11 Then Exit Function
  End If
 Case 4 'right
  If X < datw - 1 Then
   If dat(X + 2, Y) = 11 Then Exit Function
  End If
 End Select
 If d(X, Y) = 9 And d(X + 1, Y) = 9 Then 'ice
  BloxorzCheckBlockSlip = FS
 End If
Case 2 'v
 'hit block?
 Select Case FS
 Case 1 'up
  If Y > 1 Then
   If dat(X, Y - 1) = 11 Then Exit Function
  End If
 Case 2 'down
  If Y < dath - 1 Then
   If dat(X, Y + 2) = 11 Then Exit Function
  End If
 Case 3 'left
  If X > 1 Then
   If dat(X - 1, Y) = 11 Or dat(X - 1, Y + 1) = 11 Then Exit Function
  End If
 Case 4 'right
  If X < datw Then
   If dat(X + 1, Y) = 11 Or dat(X + 1, Y + 1) = 11 Then Exit Function
  End If
 End Select
 If d(X, Y) = 9 And d(X, Y + 1) = 9 Then 'ice
  BloxorzCheckBlockSlip = FS
 End If
End Select
End Function

Public Function BloxorzCheckPressButton(d() As Byte, ByVal X As Long, ByVal Y As Long, ByVal GameS As Long, Optional ByVal lpBridgeChangeArray As Long, Optional ByVal BridgeOff As Long, Optional ByVal BridgeOn As Long) As Long
Dim i As Long, j As Long, k As Long
Dim btns(1 To 2) As Long
Dim d2() As Long
If lpBridgeChangeArray <> 0 Then
 ReDim d2(1 To datw, 1 To dath)
End If
Select Case GameS
Case 0, 3 'up/single
 i = d(X, Y)
 If i = 2 Or (i = 3 And GameS = 0) Then btns(1) = dat2(X, Y)
Case 1 'h
 If d(X, Y) = 2 Then btns(1) = dat2(X, Y)
 If d(X + 1, Y) = 2 Then btns(2) = dat2(X + 1, Y)
Case 2 'v
 If d(X, Y) = 2 Then btns(1) = dat2(X, Y)
 If d(X, Y + 1) = 2 Then btns(2) = dat2(X, Y + 1)
End Select
For i = 1 To 2
 k = btns(i)
 If k > 0 And k <= swc Then
  With sws(k)
   For j = 1 To .bc
    With .bs(j)
     If .X > 0 And .Y > 0 And .X <= datw And .Y <= dath Then
      Select Case d(.X, .Y)
      Case 6, 7
       Select Case .Behavior
       Case 0 'off
        d(.X, .Y) = 6
       Case 1 'on
        d(.X, .Y) = 7
       Case 2 'toggle
        d(.X, .Y) = 13 - d(.X, .Y)
       End Select
       If lpBridgeChangeArray <> 0 Then If d(.X, .Y) = 6 Then d2(.X, .Y) = BridgeOff Else d2(.X, .Y) = BridgeOn
       BloxorzCheckPressButton = BloxorzCheckPressButton + 1
      End Select
     End If
    End With
   Next j
  End With
 End If
Next i
If lpBridgeChangeArray <> 0 Then CopyMemory ByVal lpBridgeChangeArray, d2(1, 1), 4& * datw * dath
End Function

