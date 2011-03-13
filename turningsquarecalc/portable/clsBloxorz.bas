#include once "main.bi"
#include once "clsTheFile.bi"
#include once "clsBloxorz.bi"
#include once "crt/string.bi"

Type typeBridge
 x As Long
 y As Long
 Behavior As Long
 '0=Off
 '1=0n
 '2=toggle
End Type

Type typeSwitch
 bc As Long
 bs As typeBridge ptr
End Type

Type typeSolveItPos
 x As Short
 y As Short
End Type

Type typeSolveItSwitchIdPos
 Count As Long
 AllPosCount As Long
 AllPosDelta As Long
 p As typeSolveItPos ptr
End Type

Type typeSolveItNode
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

Type typeNextPos
 m As Long
 k As Long
 k2 As Long
End Type

#define dat(_w_,_h_) _xx_dat[((_h_)-1)*datw+((_w_)-1)]
#define dat2(_w_,_h_) _xx_dat2[((_h_)-1)*datw+((_w_)-1)]
#define SwitchMap(_w_,_h_,_index_) _xx_SwitchMap[(((_index_)-1)*dath+((_h_)-1))*datw+((_w_)-1)]
#define SwitchMapPosId(_w_,_h_,_index_) _xx_SwitchMapPosId[(((_index_)-1)*dath+((_h_)-1))*datw+((_w_)-1)]
#define SolveItMovedArea(_w_,_h_) _xx_SolveItMovedArea[((_h_)-1)*datw+((_w_)-1)]

'3 = rotate 90 CW
'4 = rotate 90 CCW
'5 = rotate 180
'7 = flip horizontally
'8 = flip vertically
Public Sub clsBloxorz.TransformLevel(ByVal nOperateIndex As Long)
Dim d() As Byte, d2() As Long
Dim i As Long, j As Long
Dim ii As Long, jj As Long
Dim i1 As Long, j1 As Long
Dim i2 As Long, j2 As Long
If datw <= 0 Or dath <= 0 Then Exit Sub
Select Case nOperateIndex
Case 3, 4
 ReDim d(1 To datw, 1 To dath)
 ReDim d2(1 To datw, 1 To dath)
 For i = 1 To datw
  For j = 1 To dath
   If dat(i, j) = 4 Then 'trans
    GetTransportPosition i, j, i1, j1, i2, j2
    If nOperateIndex = 3 Then ii = dath + 1 - j1: jj = i1 _
    Else ii = j1: jj = datw + 1 - i1
    i1 = ii
    j1 = jj
    If nOperateIndex = 3 Then ii = dath + 1 - j2: jj = i2 _
    Else ii = j2: jj = datw + 1 - i2
    SetTransportPosition i, j, i1, j1, ii, jj
   End If
   If nOperateIndex = 3 Then ii = dath + 1 - j: jj = i _
   Else ii = j: jj = datw + 1 - i
   d(jj,ii) = dat(i, j)
   d2(jj,ii) = dat2(i, j)
  Next j
 Next i
 '///
 If nOperateIndex = 3 Then ii = dath + 1 - StartY: jj = StartX _
 Else ii = StartY: jj = datw + 1 - StartX
 StartX = ii
 StartY = jj
 For i = 0 To swc-1
  For j = 0 To sws[i].bc-1
   With sws[i].bs[j]
    If nOperateIndex = 3 Then ii = dath + 1 - .y: jj = .x _
    Else ii = .y: jj = datw + 1 - .x
    .x = ii
    .y = jj
   End With
  Next j
 Next i
 '///
 memcpy _xx_dat, @d(1,1),datw*dath
 memcpy _xx_dat2, @d2(1,1),datw*dath*sizeof(Long)
 i = datw
 datw = dath
 dath = i
Case 5, 7, 8
 ReDim d(1 To dath, 1 To datw)
 ReDim d2(1 To dath, 1 To datw)
 If nOperateIndex <> 8 Then 'flip horizontally
  For i = 1 To datw
   For j = 1 To dath
    If dat(i, j) = 4 Then 'trans
     GetTransportPosition i, j, i1, j1, i2, j2
     SetTransportPosition i, j, datw + 1 - i1, j1, datw + 1 - i2, j2
    End If
    ii = datw + 1 - i
    d(j,ii) = dat(i, j)
    d2(j,ii) = dat2(i, j)
   Next j
  Next i
  StartX = datw + 1 - StartX
  For i = 0 To swc-1
   For j = 0 To sws[i].bc-1
    With sws[i].bs[j]
     .x = datw + 1 - .x
    End With
   Next j
  Next i
  memcpy _xx_dat, @d(1,1),datw*dath
  memcpy _xx_dat2, @d2(1,1),datw*dath*sizeof(Long)
 End If
 If nOperateIndex <> 7 Then 'flip vertically
  For i = 1 To datw
   For j = 1 To dath
    If dat(i, j) = 4 Then 'trans
     GetTransportPosition i, j, i1, j1, i2, j2
     SetTransportPosition i, j, i1, dath + 1 - j1, i2, dath + 1 - j2
    End If
    jj = dath + 1 - j
    d(jj,i) = dat(i, j)
    d2(jj,i) = dat2(i, j)
   Next j
  Next i
  StartY = dath + 1 - StartY
  For i = 0 To swc-1
   For j = 0 To sws[i].bc-1
    With sws[i].bs[j]
     .y = dath + 1 - .y
    End With
   Next j
  Next i
  memcpy _xx_dat, @d(1,1),datw*dath
  memcpy _xx_dat2, @d2(1,1),datw*dath*sizeof(Long)
 End If
End Select
End Sub

''stupid
'Public Function clsBloxorz.ToString() As String
'Dim s As String, s1 As String
'Dim i As Long, j As Long
'If datw <= 0 Or dath <= 0 Then Exit Function
's = CStr(datw) + "," + CStr(dath) + vbCrLf _
'+ CStr(swc) + vbCrLf + CStr(StartX) + "," + CStr(StartY) + vbCrLf
''///
'For j = 1 To dath
' s1 = ""
' For i = 1 To datw
'  s1 = s1 + CStr(dat(i, j)) + ","
' Next i
' s = s + s1 + vbCrLf
'Next j
''///
'For j = 1 To dath
' s1 = ""
' For i = 1 To datw
'  s1 = s1 + CStr(dat2(i, j)) + ","
' Next i
' s = s + s1 + vbCrLf
'Next j
''///
'For i = 1 To swc
' s = s + CStr(sws(i).bc) + vbCrLf
' For j = 1 To sws(i).bc
'  s = s + CStr(sws(i).bs(j).x) + "," + CStr(sws(i).bs(j).y) + "," + CStr(sws(i).bs(j).Behavior) + vbCrLf
' Next j
'Next i
''///
'ToString = s
'End Function

''stupid
'Public Function clsBloxorz.FromString(ByRef sString As String) As Boolean
'On Error GoTo a
'Dim v As Variant, m As Long
'Dim s As String
'Dim i As Long, j As Long, k As Long
'Dim i1 As Long, i2 As Long, i3 As Long
''///
'Destroy
'v = Split(Replace(Replace(sString, vbCr, ","), vbLf, ","), ",")
'm = UBound(v)
'For i = 0 To m
' s = Trim(v(i))
' If s <> "" Then
'  Select Case i1
'  Case 0
'   datw = Val(s): i1 = i1 + 1
'  Case 1
'   dath = Val(s): i1 = i1 + 1
'  Case 2
'   swc = Val(s): i1 = i1 + 1
'  Case 3
'   StartX = Val(s): i1 = i1 + 1
'  Case 4
'   StartY = Val(s): i1 = i1 + 1
'   If Not (0 < StartX And StartX <= datw And datw <= 255 And _
'   0 < StartY And StartY <= dath And dath <= 255 And swc >= 0) Then Err.Raise 5
'   ReDim dat(1 To datw, 1 To dath)
'   ReDim dat2(1 To datw, 1 To dath)
'   If swc > 0 Then ReDim sws(1 To swc)
'   i2 = 1
'   i3 = 1
'  Case 5 'dat
'   dat(i2, i3) = Val(s)
'   i2 = i2 + 1
'   If i2 > datw Then
'    i2 = 1
'    i3 = i3 + 1
'    If i3 > dath Then
'     i1 = i1 + 1
'     i3 = 1
'    End If
'   End If
'  Case 6 'dat2
'   dat2(i2, i3) = Val(s)
'   i2 = i2 + 1
'   If i2 > datw Then
'    i2 = 1
'    i3 = i3 + 1
'    If i3 > dath Then
'     i1 = i1 + 1
'     i3 = 0 '!!!
'    End If
'   End If
'  Case Else 'switch
'   k = i1 - 6
'   If k > 0 And k <= swc Then
'    j = Val(s)
'    If i3 = 0 Then
'     sws(k).bc = j
'     If j > 0 Then ReDim sws(k).bs(1 To j)
'     i3 = i3 + 1
'    Else
'     Select Case i2
'     Case 1: sws(k).bs(i3).x = j
'     Case 2: sws(k).bs(i3).y = j
'     Case 3: sws(k).bs(i3).Behavior = j
'     End Select
'     i2 = i2 + 1
'     If i2 > 3 Then
'      i2 = 1
'      i3 = i3 + 1
'     End If
'    End If
'    If i3 > sws(k).bc Then
'     i1 = i1 + 1
'     i3 = 0
'    End If
'   End If
'  End Select
' End If
'Next i
'FromString = i1 > 4
'a:
'End Function

'Public Sub clsBloxorz.CopyToClipboard()
'On Error Resume Next
'Clipboard.Clear
'Clipboard.SetText ToString
'End Sub

'Public Function clsBloxorz.PasteFromClipboard()
'On Error GoTo a
'PasteFromClipboard = FromString(Clipboard.GetText)
'a:
'End Function

Public Sub clsBloxorz.Clone(byval objSrc As clsBloxorz ptr)
dim i as long
Destroy
datw = objSrc->Width
dath = objSrc->Height
swc = objSrc->SwitchCount
StartX = objSrc->StartX
StartY = objSrc->StartY
'objSrc.fClone dat, dat2, sws
if datw>0 and dath>0 then
 _xx_dat=allocate(datw*dath)
 _xx_dat2=allocate(datw*dath*4&)
 memcpy _xx_dat,objSrc->_xx_dat,datw*dath
 memcpy _xx_dat2,objSrc->_xx_dat2,datw*dath*4&
end if
if swc>0 then
 sws=callocate(swc,sizeof(typeSwitch))
 for i=0 to swc-1
  sws[i].bc=objSrc->sws[i].bc
  if sws[i].bc>0 then
   sws[i].bs=allocate(sws[i].bc*sizeof(typeBridge))
   memcpy sws[i].bs,objSrc->sws[i].bs,sws[i].bc*sizeof(typeBridge)
  end if
 next i
end if
End Sub

Public function clsBloxorz.Width() As Long
Width = datw
End function

Public function clsBloxorz.Height() As Long
Height = dath
End function

Public Sub clsBloxorz.Create(ByVal w As Long, ByVal h As Long)
If w > 0 And h > 0 Then
 Destroy
 datw = w
 dath = h
 _xx_dat=callocate(datw*dath)
 _xx_dat2=callocate(datw*dath*4&)
End If
End Sub

Public Sub clsBloxorz.Clear()
Dim m As Long
If datw > 0 And dath > 0 Then
 m = datw * dath
 memset _xx_dat,0, m
 memset _xx_dat2,0, m*4&
 StartX = 1
 StartY = 1
End If
ClearSwitch
SolveItClear
End Sub

Public Destructor clsBloxorz
Destroy
end Destructor

Public Sub clsBloxorz.Destroy()
datw = 0
dath = 0
deallocate _xx_dat
_xx_dat=NULL
deallocate _xx_dat2
_xx_dat2=NULL
StartX = 1
StartY = 1
ClearSwitch
SolveItClear
End Sub

Public function clsBloxorz.Data(ByVal x As Long, ByVal y As Long) As Long
Data = dat(x, y)
End function

Public sub clsBloxorz.SetData(ByVal x As Long, ByVal y As Long, ByVal n As Long)
dat(x, y) = n
End sub

Public function clsBloxorz.Data2(ByVal x As Long, ByVal y As Long) As Long
Data2 = dat2(x, y)
End function

Public sub clsBloxorz.SetData2(ByVal x As Long, ByVal y As Long, ByVal n As Long)
dat2(x, y) = n
End sub

Public Sub clsBloxorz.GetTransportPosition(ByVal x As Long, ByVal y As Long, ByRef x1 As Long, ByRef y1 As Long, ByRef x2 As Long, ByRef y2 As Long)
Dim n As ULong
n = dat2(x, y)
x1=n and &HFF&
y1=(n shr 8) and &HFF&
x2=(n shr 16) and &HFF&
y2=(n shr 24) and &HFF&
End Sub

Public Sub clsBloxorz.SetTransportPosition(ByVal x As Long, ByVal y As Long, ByVal x1 As Long, ByVal y1 As Long, ByVal x2 As Long, ByVal y2 As Long)
Dim n As ULong
n=(x1 and &HFF&) or ((y1 and &HFF&) shl 8) or ((x2 and &HFF&) shl 16) or ((y2 and &HFF&) shl 24)
dat2(x, y)=n
End Sub

'add a stupid function
Public Function clsBloxorz.GetSpecifiedObjectCount(ByVal i1 As Long, ByVal i2 As Long=0, ByVal x1 As Long=0, ByVal y1 As Long=0, ByVal x2 As Long=0, ByVal y2 As Long=0) As Long
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

Public Function clsBloxorz.SwitchCount() As Long
SwitchCount = swc
End Function

Public Sub clsBloxorz.ClearSwitch()
Dim i As Long, j As Long
'///
for i=0 to swc-1
 deallocate sws[i].bs
next i
deallocate sws
sws=NULL
swc = 0
'///
For i = 1 To datw
 For j = 1 To dath
  Select Case dat(i, j)
  Case 2, 3
   dat2(i, j) = 0
  End Select
 Next j
Next i
End Sub

Public Sub clsBloxorz.AddSwitch()
swc = swc + 1
sws=reallocate(sws,swc*sizeof(typeSwitch))
sws[swc-1].bc=0
sws[swc-1].bs=NULL
End Sub

Public Sub clsBloxorz.RemoveSwitch(ByVal Index As Long)
Dim i As Long, j As Long
if index<=0 or index>swc then exit sub
If swc <= 1 Then
 ClearSwitch
 Exit Sub
End If
'///
deallocate sws[index-1].bs
'///
swc = swc - 1
For i = Index To swc
 sws[i-1] = sws[i]
Next i
sws=reallocate(sws,swc*sizeof(typeSwitch))
For i = 1 To datw
 For j = 1 To dath
  Select Case dat(i, j)
  Case 2, 3
   If dat2(i, j) >= Index Then dat2(i, j) = dat2(i, j) - 1
  End Select
 Next j
Next i
End Sub

Public function clsBloxorz.SwitchBridgeCount(ByVal Index As Long) As Long
SwitchBridgeCount = sws[Index-1].bc
End Function

Public sub clsBloxorz.SetSwitchBridgeCount(ByVal Index As Long, ByVal n As Long)
dim nOld as long
With sws[Index-1]
 nOld=.bc
 .bc = n
 If n > 0 Then
  .bs=reallocate(.bs,.bc*sizeof(typeBridge))
  if n>nOld then memset @.bs[nOld],0,(n-nOld)*sizeof(typeBridge)
 Else
  deallocate .bs
  .bs=NULL
 End If
End With
End Sub

Public Sub clsBloxorz.AddSwitchBridge(ByVal Index As Long, ByVal x As Long=0, ByVal y As Long=0, ByVal Behavior As Long=0)
With sws[Index-1]
 .bc += 1
 .bs=reallocate(.bs,.bc*sizeof(typeBridge))
 With .bs[.bc-1]
  .x = x
  .y = y
  .Behavior = Behavior
 End With
End With
End Sub

Public Sub clsBloxorz.ClearSwitchBridge(ByVal Index As Long)
With sws[Index-1]
 deallocate .bs
 .bs=NULL
 .bc = 0
End With
End Sub

Public Sub clsBloxorz.RemoveSwitchBridge(ByVal Index As Long, ByVal i As Long)
With sws[Index-1]
 If .bc <= 1 Then
  deallocate .bs
  .bs=NULL
  .bc = 0
 Else
  If i < .bc Then memmove @.bs[i-1], @.bs[i], sizeof(typeBridge) * (.bc - i)
  .bc -= 1
  .bs=reallocate(.bs,.bc*sizeof(typeBridge))
 End If
End With
End Sub

Public Function clsBloxorz.SwitchBridgeX(ByVal Index As Long, ByVal i As Long) As Long
SwitchBridgeX = sws[Index-1].bs[i-1].x
End Function

Public Sub clsBloxorz.SetSwitchBridgeX(ByVal Index As Long, ByVal i As Long, ByVal n As Long)
sws[Index-1].bs[i-1].x = n
End Sub

Public Function clsBloxorz.SwitchBridgeY(ByVal Index As Long, ByVal i As Long) As Long
SwitchBridgeY = sws[Index-1].bs[i-1].y
End Function

Public Sub clsBloxorz.SetSwitchBridgeY(ByVal Index As Long, ByVal i As Long, ByVal n As Long)
sws[Index-1].bs[i-1].y = n
End Sub

Public Function clsBloxorz.SwitchBridgeBehavior(ByVal Index As Long, ByVal i As Long) As Long
SwitchBridgeBehavior = sws[Index-1].bs[i-1].Behavior
End Function

Public Sub clsBloxorz.SetSwitchBridgeBehavior(ByVal Index As Long, ByVal i As Long, ByVal n As Long)
sws[Index-1].bs[i-1].Behavior = n
End Sub

Sub clsBloxorz.fOptimizeSwitch()
Dim i As Long, j As Long, k As Long, l As Long
Dim d() As Byte, b As Boolean
i = 2
Do Until i > swc
 b = False
 With sws[i-1]
  For j = 1 To i - 1
   If .bc = sws[j-1].bc Then
    If .bc = 0 Then
     b = True
     Exit For
    End If
    ReDim d(1 To .bc)
    For k = 1 To .bc
     For l = 1 To .bc
      If d(l) = 0 Then
       If .bs[k-1].x = sws[j-1].bs[l-1].x Then
        If .bs[k-1].y = sws[j-1].bs[l-1].y Then
         If .bs[k-1].Behavior = sws[j-1].bs[l-1].Behavior Then
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
   sws[k-1] = sws[k]
  Next k
  sws=reallocate(sws,swc*sizeof(typeSwitch))
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

Public Sub clsBloxorz.LoadLevel(ByVal lv As Long,byval d As clsTheFile ptr)
Dim i As Long, lp As Byte ptr
Dim b() As Byte
Destroy
i = d->FindNodeArray(strptr(!"LEV\0"))
If i = 0 Then Exit Sub
If d->NodeCount(i) < lv Then Exit Sub
If d->NodeSize(i, lv) = 0 Then Exit Sub
d->GetNodeData i, lv, b()
lp = @b(1)
memcpy @datw, lp, 4&
lp = lp + 4
memcpy @dath, lp, 4&
lp = lp + 4
memcpy @StartX, lp, 4&
lp = lp + 4
memcpy @StartY, lp, 4&
lp = lp + 4
If datw > 0 And dath > 0 Then
 i = datw * dath
 _xx_dat=allocate(i)
 memcpy _xx_dat, lp, i
 lp = lp + i
 i = i * 4&
 _xx_dat2=allocate(i)
 memcpy _xx_dat2, lp, i
 lp = lp + i
End If
memcpy @swc, lp, 4&
lp = lp + 4
If swc > 0 Then
 sws=callocate(swc,sizeof(typeSwitch))
 For i = 1 To swc
  With sws[i-1]
   memcpy @.bc, lp, 4&
   lp = lp + 4
   If .bc > 0 Then
    .bs=callocate(.bc,sizeof(typeBridge))
    memcpy .bs, lp, .bc * sizeof(typeBridge)
    lp = lp + .bc * sizeof(typeBridge)
   End If
  End With
 Next i
End If
End Sub

Public Sub clsBloxorz.SaveLevel(ByVal lv As Long,byval d As clsTheFile ptr)
Dim i As Long, m As Long, lp As Byte ptr
Dim b() As Byte
'calc max
m = 20 + datw * dath * 5& + swc * 4&
For i = 1 To swc
 m = m + sws[i-1].bc * 12&
Next i
'copy data
ReDim b(1 To m)
lp = @b(1)
memcpy lp, @datw, 4&
lp = lp + 4&
memcpy lp, @dath, 4&
lp = lp + 4&
memcpy lp, @StartX, 4&
lp = lp + 4&
memcpy lp, @StartY, 4&
lp = lp + 4&
If datw > 0 And dath > 0 Then
 i = datw * dath
 memcpy lp, _xx_dat, i
 lp = lp + i
 i = i * 4&
 memcpy lp, _xx_dat2, i
 lp = lp + i
End If
memcpy lp, @swc, 4&
lp = lp + 4
If swc > 0 Then
 For i = 1 To swc
  With sws[i-1]
   memcpy lp, @.bc, 4&
   lp = lp + 4
   If .bc > 0 Then
    memcpy lp, .bs, .bc * sizeof(typeBridge)
    lp = lp + .bc * sizeof(typeBridge)
   End If
  End With
 Next i
End If
'save it
i = d->FindNodeArray(strptr(!"LEV\0"))
If i = 0 Then
 d->AddNodeArray strptr(!"LEV\0")
 i = d->NodeArrayCount
End If
Do Until d->NodeCount(i) >= lv
 d->AddNode i
Loop
d->SetNodeData i, lv, b()
End Sub

Public Function clsBloxorz.SolveIt(byval objProgress As IBloxorzCallBack ptr=NULL) As Boolean
Dim SwitchTransTable() As Long, d() As Byte
Dim nd As typeSolveItNode
Dim i As Long, j As Long, jj As Long, k As Long, m As Long
Dim x As Long, y As Long, t As Double, bAbort As Boolean
If StartX <= 0 Or StartY <= 0 Or StartX > datw Or StartY > dath Then Exit Function
t = Timer 'GetTickCount
'///////////////////////////////////////////////////Step 1:determine switch
m = datw * dath
'init
_xx_SwitchMap=reallocate(_xx_SwitchMap,m)
_xx_SwitchMapPosId=reallocate(_xx_SwitchMapPosId,m*4&)
'//
for i=0 to SwitchStatusCount-1
 deallocate SwitchMapIdPos[i].p
next i
deallocate SwitchMapIdPos
SwitchMapIdPos=callocate(1,sizeof(typeSolveItSwitchIdPos))
SwitchStatusCount = 1
'//
#If SolveItRecordMovedArea
_xx_SolveItMovedArea=reallocate(_xx_SolveItMovedArea,datw*dath)
#EndIf
memcpy _xx_SwitchMap, _xx_dat, m
If swc > 0 Then 'calc
 ReDim SwitchTransTable(1 To 1, 1 To swc)
 ReDim d(1 To dath, 1 To datw)
 i = 1
 Do Until i > SwitchStatusCount
  'calc pos
  pSolveItCalcPos i
  'press all button
  For j = 1 To swc
   memcpy @d(1, 1), _xx_SwitchMap+(i-1)*m, m
   With sws[j-1]
    For k = 1 To .bc
     With .bs[k-1]
      If .x > 0 And .y > 0 And .x <= datw And .y <= dath Then
       Select Case .Behavior
       Case 0 'off
        d(.y, .x) = 6
       Case 1 'on
        d(.y, .x) = 7
       Case 2 'toggle
        d(.y, .x) = 13 - d(.y, .x) 'err?
       End Select
      End If
     End With
    Next k
   End With
   'check the same
   For k = 1 To SwitchStatusCount
    if memcmp(@d(1,1),_xx_SwitchMap+(k-1)*m,m)=0 then exit for
   Next k
   If k > SwitchStatusCount Then
    k = SwitchStatusCount + 1
    SwitchStatusCount = k
    '///
    _xx_SwitchMap=reallocate(_xx_SwitchMap,m*k)
    _xx_SwitchMapPosId=reallocate(_xx_SwitchMapPosId,m*k*4&)
    SwitchMapIdPos=reallocate(SwitchMapIdPos,k*sizeof(typeSolveItSwitchIdPos))
    '///
    ReDim Preserve SwitchTransTable(1 To k, 1 To swc)
    '///
    memcpy _xx_SwitchMap+(k-1)*m, @d(1, 1), m
    memset @_xx_SwitchMapPosId[(k-1)*m],0,m*4&
    memset @SwitchMapIdPos[k-1],0,sizeof(typeSolveItSwitchIdPos)
   End If
   SwitchTransTable(i,j) = k
  Next j
  i = i + 1
 Loop
Else 'no switch
 pSolveItCalcPos 1
End If
'///////////////////////////////////////////////////
'Print "switch status count:"; SwitchStatusCount
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
 With SwitchMapIdPos[i-1]
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
'Print "node count:"; k
'///////////////////////////////////////////////////New Step 3:start BFS with binary search tree
If k = 0 Then Exit Function
GTheoryNodeMax = k
'new method!
GTheoryNodeUsed = 0
deallocate GTheoryNode
GTheoryNode=NULL
pSolveItResizeNodeArray
'init node
i = SwitchMapPosId(StartX,StartY,1)
If i = 0 Then Exit Function
If IsTrans Then
 j = (i * (i + 1)) \ 2
 k = i
Else
 j = i
 k = 0
End If
With GTheoryNode[0]
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
  With GTheoryNode[lps-1]
   x = .Distance + 1
   jj = pSolveItCheckNodeState(.m, .k, 3, .k2)
   #If SolveItRecordMovedArea
   With SwitchMapIdPos[.m-1].p[.k-1]
    SolveItMovedArea(.x, .y) = 1
   End With
   If .k2 <> .k Then
    With SwitchMapIdPos[.m-1].p[.k2-1]
     SolveItMovedArea(.x, .y) = 1
    End With
   End If
   #EndIf
   Select Case jj
   Case 0, 1, 2 'up,h,v
    k = .k
    If jj = 1 Then
     If SwitchMapIdPos[.m-1].p[.k-1].x > SwitchMapIdPos[.m-1].p[.k2-1].x Then k = .k2
    ElseIf jj = 2 Then
     If SwitchMapIdPos[.m-1].p[.k-1].y > SwitchMapIdPos[.m-1].p[.k2-1].y Then k = .k2
    End If
    For i = 1 To 4
     j = pSolveItCalcNext(SwitchTransTable(), .m, k, jj, i, @ret)
     If j > 0 Then
      m = pSolveItBinarySearchTreeFindNode(j, lpe)
      If m > lpe Then
       lpe = m
       With GTheoryNode[lpe-1]
        .Index = j
        .m = ret.m
        .k = ret.k
        .k2 = ret.k2
        .PathPrevEdge = i
        .PathPrevNode = lps
        .Distance = x
       End With
      End If
     End If
    Next i
   Case 3 'single
    For i = 1 To 4
     j = pSolveItCalcNextSingle(SwitchTransTable(), .m, .k, .k2, i, @ret)
     If j > 0 Then
      m = pSolveItBinarySearchTreeFindNode(j, lpe)
      If m > lpe Then
       lpe = m
       With GTheoryNode[lpe-1]
        .Index = j
        .m = ret.m
        .k = ret.k
        .k2 = ret.k2
        .PathPrevEdge = i
        .PathPrevNode = lps
        .Distance = x
       End With
      End If
     End If
     j = pSolveItCalcNextSingle(SwitchTransTable(), .m, .k2, .k, i, @ret)
     If j > 0 Then
      m = pSolveItBinarySearchTreeFindNode(j, lpe)
      If m > lpe Then
       lpe = m
       With GTheoryNode[lpe-1]
        .Index = j
        .m = ret.m
        .k = ret.k
        .k2 = ret.k2
        .PathPrevEdge = i + 4
        .PathPrevNode = lps
        .Distance = x
       End With
      End If
     End If
    Next i
   End Select
  End With
  lps = lps + 1
  If lpe > GTheoryNodeUsed - 16 Then pSolveItResizeNodeArray
  If (lps And &HFF&) = 0 Then
   If objProgress <> NULL Then
    bAbort = False
    objProgress->SolveItCallBack(lps, GTheoryNodeMax, bAbort)
    If bAbort Then Exit Do
   End If
  End If
 Loop
Else
 '///debug
 '#If IsDebug Then
 'Open CStr(App.Path) + "\solvelog.log" For Append As #44
 '#End If
 '///
 Do Until lps > lpe
  With GTheoryNode[lps-1]
   x = .Distance + 1
   jj = pSolveItCheckNodeState(.m, .k, .k2)
   #If SolveItRecordMovedArea
   With SwitchMapIdPos[.m-1].p[.k-1]
    SolveItMovedArea(.x, .y) = 1
    If jj = 1 Then 'h
     SolveItMovedArea(.x + 1, .y) = 1
    ElseIf jj = 2 Then 'v
     SolveItMovedArea(.x, .y + 1) = 1
    End If
   End With
   #EndIf
   Select Case jj
   Case 0, 1, 2
    For i = 1 To 4
     j = pSolveItCalcNext(SwitchTransTable(), .m, .k, .k2, i, @ret)
     '///debug
     '#If IsDebug Then
     'Print #44, "lps=" + CStr(lps) + _
     '",ox=" + CStr(SwitchMapIdPos[.m-1].p[.k-1].x) + _
     '",oy=" + CStr(SwitchMapIdPos[.m-1].p[.k-1].y) + _
     '",oFS=" + CStr(jj) + _
     '",i=" + CStr(i) + ",j=" + CStr(j);
     'If j > 0 Then
     ' Print #44, ",x=" + CStr(SwitchMapIdPos[ret.m-1].p[ret.k-1].x) + _
     ' ",y=" + CStr(SwitchMapIdPos[ret.m-1].p[ret.k-1].y)
     'Else
     ' Print #44,
     'End If
     '#End If
     '///
     If j > 0 Then
      m = pSolveItBinarySearchTreeFindNode(j, lpe)
      If m > lpe Then
       lpe = m
       With GTheoryNode[lpe-1]
        .Index = j
        .m = ret.m
        .k = ret.k
        .k2 = ret.k2
        .PathPrevEdge = i
        .PathPrevNode = lps
        .Distance = x
       End With
      End If
     End If
    Next i
   End Select
  End With
  lps = lps + 1
  If lpe > GTheoryNodeUsed - 16 Then pSolveItResizeNodeArray
  If (lps And &HFF&) = 0 Then
   If objProgress <>NULL Then
    bAbort = False
    objProgress->SolveItCallBack(lps, GTheoryNodeMax, bAbort)
    If bAbort Then Exit Do
   End If
  End If
 Loop
 '///debug
 '#If IsDebug Then
 'Close 44
 '#End If
 '///
End If
'ReDim Preserve GTheoryNode[1 To lpe-1]
GTheoryNodeUsed = lpe
'///////////////////////////////////////////////////
SolveItTime = (Timer - t)*1000
SolveIt = True
End Function

Public Sub clsBloxorz.SolveItGetCanMoveArea(d() As Byte)
#If SolveItRecordMovedArea
if _xx_SolveItMovedArea then
 memcpy @d(1, 1), _xx_SolveItMovedArea, datw * dath
 exit sub
End If
a:
#EndIf
memset @d(1, 1),1, datw * dath
End Sub

Private Sub clsBloxorz.pSolveItResizeNodeArray()
dim i as long
i=GTheoryNodeUsed
GTheoryNodeUsed += 16384
If GTheoryNodeUsed > GTheoryNodeMax Then GTheoryNodeUsed = GTheoryNodeMax
GTheoryNode=reallocate(GTheoryNode,GTheoryNodeUsed*sizeof(typeSolveItNode))
memset @GTheoryNode[i],0,(GTheoryNodeUsed-i)*sizeof(typeSolveItNode)
End Sub

Private Function clsBloxorz.pSolveItBinarySearchTreeFindNode(ByVal Index As Long, ByVal Count As Long=0) As Long
Dim i As Long, j As Long, k As Long
i = 1
Do
 j = Index - GTheoryNode[i-1].Index
 If j = 0 Then 'found!
  pSolveItBinarySearchTreeFindNode = i
  Exit Function
 ElseIf j > 0 Then
  k = GTheoryNode[i-1].BinarySearchTreeRSon
  If k = 0 Then 'not found
   If Count > 0 Then
    k = Count + 1
    GTheoryNode[i-1].BinarySearchTreeRSon = k
    pSolveItBinarySearchTreeFindNode = k
   End If
   Exit Function
  End If
 Else
  k = GTheoryNode[i-1].BinarySearchTreeLSon
  If k = 0 Then 'not found
   If Count > 0 Then
    k = Count + 1
    GTheoryNode[i-1].BinarySearchTreeLSon = k
    pSolveItBinarySearchTreeFindNode = k
   End If
   Exit Function
  End If
 End If
 i = k
Loop
End Function

Private Function clsBloxorz.pSolveItCheckNodeState(ByVal m As Long, ByVal k As Long, ByVal State As Long, ByVal k2 As Long=0) As Long
Dim x As Long, y As Long, x2 As Long, y2 As Long
pSolveItCheckNodeState = -1 'invalid
With SwitchMapIdPos[m-1]
 If k > 0 And k <= .Count Then
  Select Case State
  Case 3 'single?
   If k2 > 0 And k2 <= .Count Then
    If k = k2 Then 'up
     Select Case SwitchMap(.p[k-1].x, .p[k-1].y, m)
     Case 1, 2, 3, 7, 9, 10, 4 '4?
      pSolveItCheckNodeState = 0
     End Select
    Else
     x = .p[k-1].x
     y = .p[k-1].y
     x2 = .p[k2-1].x
     y2 = .p[k2-1].y
     If y = y2 And (x - x2 = 1 Or x2 - x = 1) Then 'h
      If x > x2 Then x = x2
      If x <= datw - 1 Then
       If Not (SwitchMap(x, y, m) = 11 And SwitchMap(x + 1, y, m) = 11) Then
        pSolveItCheckNodeState = 1
       End If
      End If
     ElseIf x = x2 And (y - y2 = 1 Or y2 - y = 1) Then 'v
      If y > y2 Then y = y2
      If y <= dath - 1 Then
       If Not (SwitchMap(x, y, m) = 11 And SwitchMap(x, y + 1, m) = 11) Then
        pSolveItCheckNodeState = 2
       End If
      End If
     Else 'single
      If Not (SwitchMap(x, y, m) = 11 Or SwitchMap(x2, y2, m) = 11) Then
       pSolveItCheckNodeState = 3
      End If
     End If
    End If
   End If
  Case 0 'up
   Select Case SwitchMap(.p[k-1].x, .p[k-1].y, m)
   Case 1, 2, 3, 7, 9, 10, 4 '4?
    pSolveItCheckNodeState = 0
   End Select
  Case 1 'h
   x = .p[k-1].x
   y = .p[k-1].y
   If x <= datw - 1 Then
    If SwitchMapPosId(x + 1, y, m) > 0 And Not (SwitchMap(x, y, m) = 11 And SwitchMap(x + 1, y, m) = 11) Then
     pSolveItCheckNodeState = 1
    End If
   End If
  Case 2 'v
   x = .p[k-1].x
   y = .p[k-1].y
   If y <= dath - 1 Then
    If SwitchMapPosId(x, y + 1, m) > 0 And Not (SwitchMap(x, y, m) = 11 And SwitchMap(x, y + 1, m) = 11) Then
     pSolveItCheckNodeState = 2
    End If
   End If
  End Select
 End If
End With
End Function

Private Function clsBloxorz.pSolveItCalcNext(SwitchTransTable() As Long, ByVal m As Long, ByVal k As Long, ByVal State As Long, ByVal FS As Long,byval ret As typeNextPos ptr) As Long
Dim i As Long, j As Long, jj As Long, PJJ As Long
Dim x As Long, y As Long
With SwitchMapIdPos[m-1].p[k-1]
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
           i = SwitchTransTable(i,j)
          End If
         End If
         If SwitchMap(x, y + 1, m) = 2 Then
          j = dat2(x, y + 1)
          If j > 0 And j <= swc Then
           i = SwitchTransTable(i,j)
          End If
         End If
         j = SwitchMapPosId(x, y, i)
         jj = SwitchMapPosId(x, y + 1, i)
         If j > 0 And jj > 0 Then
          ret->m = i
          If IsTrans Then
           ret->k = j
           ret->k2 = jj
           j = SwitchMapIdPos[i-1].AllPosDelta + pSolveItPosToInt(j, jj)
          Else
           ret->k = j
           ret->k2 = 2
           j = SwitchMapIdPos[i-1].AllPosDelta + SwitchMapIdPos[i-1].Count * 2 + j
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
           i = SwitchTransTable(i,j)
          End If
         End If
         If SwitchMap(x + 1, y, m) = 2 Then
          j = dat2(x + 1, y)
          If j > 0 And j <= swc Then
           i = SwitchTransTable(i,j)
          End If
         End If
         j = SwitchMapPosId(x, y, i)
         jj = SwitchMapPosId(x + 1, y, i)
         If j > 0 And jj > 0 Then
          ret->m = i
          If IsTrans Then
           ret->k = j
           ret->k2 = jj
           j = SwitchMapIdPos[i-1].AllPosDelta + pSolveItPosToInt(j, jj)
          Else
           ret->k = j
           ret->k2 = 1
           j = SwitchMapIdPos[i-1].AllPosDelta + SwitchMapIdPos[i-1].Count + j
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
            i = SwitchTransTable(i,j)
           End If
          End If
          If SwitchMap(x + 1, y, m) = 2 Then
           j = dat2(x + 1, y)
           If j > 0 And j <= swc Then
            i = SwitchTransTable(i,j)
           End If
          End If
          j = SwitchMapPosId(x, y, i)
          jj = SwitchMapPosId(x + 1, y, i)
          If j > 0 And jj > 0 Then
           ret->m = i
           If IsTrans Then
            ret->k = j
            ret->k2 = jj
            j = SwitchMapIdPos[i-1].AllPosDelta + pSolveItPosToInt(j, jj)
           Else
            ret->k = j
            ret->k2 = 1
            j = SwitchMapIdPos[i-1].AllPosDelta + SwitchMapIdPos[i-1].Count + j
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
           i = SwitchTransTable(i,j)
          End If
         End If
         j = SwitchMapPosId(x, y, i)
         If j > 0 Then
          ret->m = i
          If IsTrans Then
           ret->k = j
           ret->k2 = j
           j = SwitchMapIdPos[i-1].AllPosDelta + (j * (j + 1)) \ 2
          Else
           ret->k = j
           ret->k2 = 0
           j = SwitchMapIdPos[i-1].AllPosDelta + j
          End If
          pSolveItCalcNext = j
         End If
        Case 4 'trans
         GetTransportPosition x, y, i, j, jj, PJJ
         If i > 0 And i <= datw And j > 0 And j <= dath And _
         jj > 0 And jj <= datw And PJJ > 0 And PJJ <= dath Then
          j = SwitchMapPosId(i, j, m)
          jj = SwitchMapPosId(jj, PJJ, m)
          If j > 0 And jj > 0 Then
           ret->m = m
           If IsTrans Then
            ret->k = j
            ret->k2 = jj
            j = SwitchMapIdPos[m-1].AllPosDelta + pSolveItPosToInt(j, jj)
           Else
            Assert(False) 'err!!
           End If
           pSolveItCalcNext = j
          End If
         End If
        Case 10 'pyramid
         j = SwitchMapPosId(x, y, m)
         'hit block?
         If FS = 3 Then 'left
          If x > 1 Then 'fix the bug
           If SwitchMap(x - 1, y, m) = 11 Then
            ret->m = m
            If IsTrans Then
             ret->k = j
             ret->k2 = j
             j = SwitchMapIdPos[m-1].AllPosDelta + (j * (j + 1)) \ 2
            Else
             ret->k = j
             ret->k2 = 0
             j = SwitchMapIdPos[m-1].AllPosDelta + j
            End If
            pSolveItCalcNext = j
           ElseIf x > 2 Then
            pSolveItCalcNext = pSolveItCalcNext(SwitchTransTable(), m, j, 0, FS, ret)
           End If
          End If
         Else 'right
          If x <= datw - 1 Then 'fix the bug
           If SwitchMap(x + 1, y, m) = 11 Then
            ret->m = m
            If IsTrans Then
             ret->k = j
             ret->k2 = j
             j = SwitchMapIdPos[m-1].AllPosDelta + (j * (j + 1)) \ 2
            Else
             ret->k = j
             ret->k2 = 0
             j = SwitchMapIdPos[m-1].AllPosDelta + j
            End If
            pSolveItCalcNext = j
           ElseIf x <= datw - 2 Then
            pSolveItCalcNext = pSolveItCalcNext(SwitchTransTable(), m, j, 0, FS, ret)
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
           i = SwitchTransTable(i,j)
          End If
         End If
         j = SwitchMapPosId(x, y, i)
         If j > 0 Then
          ret->m = i
          If IsTrans Then
           ret->k = j
           ret->k2 = j
           j = SwitchMapIdPos[i-1].AllPosDelta + (j * (j + 1)) \ 2
          Else
           ret->k = j
           ret->k2 = 0
           j = SwitchMapIdPos[i-1].AllPosDelta + j
          End If
          pSolveItCalcNext = j
         End If
        Case 4 'trans
         GetTransportPosition x, y, i, j, jj, PJJ
         If i > 0 And i <= datw And j > 0 And j <= dath And _
         jj > 0 And jj <= datw And PJJ > 0 And PJJ <= dath Then
          j = SwitchMapPosId(i, j, m)
          jj = SwitchMapPosId(jj, PJJ, m)
          If j > 0 And jj > 0 Then
           ret->m = m
           If IsTrans Then
            ret->k = j
            ret->k2 = jj
            j = SwitchMapIdPos[m-1].AllPosDelta + pSolveItPosToInt(j, jj)
           Else
            Assert(False) 'err!!
           End If
           pSolveItCalcNext = j
          End If
         End If
        Case 10 'pyramid
         j = SwitchMapPosId(x, y, m)
         'hit block?
         If FS = 1 Then 'up
          If y > 1 Then 'fix the bug
           If SwitchMap(x, y - 1, m) = 11 Then
            ret->m = m
            If IsTrans Then
             ret->k = j
             ret->k2 = j
             j = SwitchMapIdPos[m-1].AllPosDelta + (j * (j + 1)) \ 2
            Else
             ret->k = j
             ret->k2 = 0
             j = SwitchMapIdPos[m-1].AllPosDelta + j
            End If
            pSolveItCalcNext = j
           ElseIf y > 2 Then
            pSolveItCalcNext = pSolveItCalcNext(SwitchTransTable(), m, j, 0, FS, ret)
           End If
          End If
         Else 'down
          If y <= dath - 1 Then 'dix the bug
           If SwitchMap(x, y + 1, m) = 11 Then
            ret->m = m
            If IsTrans Then
             ret->k = j
             ret->k2 = j
             j = SwitchMapIdPos[m-1].AllPosDelta + (j * (j + 1)) \ 2
            Else
             ret->k = j
             ret->k2 = 0
             j = SwitchMapIdPos[m-1].AllPosDelta + j
            End If
            pSolveItCalcNext = j
           ElseIf y <= dath - 2 Then
            pSolveItCalcNext = pSolveItCalcNext(SwitchTransTable(), m, j, 0, FS, ret)
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
            i = SwitchTransTable(i,j)
           End If
          End If
          If SwitchMap(x, y + 1, m) = 2 Then
           j = dat2(x, y + 1)
           If j > 0 And j <= swc Then
            i = SwitchTransTable(i,j)
           End If
          End If
          j = SwitchMapPosId(x, y, i)
          jj = SwitchMapPosId(x, y + 1, i)
          If j > 0 And jj > 0 Then
           ret->m = i
           If IsTrans Then
            ret->k = j
            ret->k2 = jj
            j = SwitchMapIdPos[i-1].AllPosDelta + pSolveItPosToInt(j, jj)
           Else
            ret->k = j
            ret->k2 = 2
            j = SwitchMapIdPos[i-1].AllPosDelta + SwitchMapIdPos[i-1].Count * 2 + j
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

Private Function clsBloxorz.pSolveItCalcNextSingle(SwitchTransTable() As Long, ByVal m As Long, ByVal k As Long, ByVal k2 As Long, ByVal FS As Long, byval ret As typeNextPos ptr) As Long
Dim i As Long, j As Long, jj As Long
Dim x As Long, y As Long, x2 As Long, y2 As Long
'IsTrans must be true!
With SwitchMapIdPos[m-1]
 x2 = .p[k2-1].x
 y2 = .p[k2-1].y
 With .p[k-1]
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
           i = SwitchTransTable(i,j)
          End If
         End If
         j = SwitchMapPosId(x, y, i)
         jj = SwitchMapPosId(x2, y2, i)
         If j > 0 And jj > 0 Then
          With *ret
           .m = i
           .k = j
           .k2 = jj
          End With
          j = SwitchMapIdPos[i-1].AllPosDelta + pSolveItPosToInt(j, jj)
          pSolveItCalcNextSingle = j
         End If
        End Select
       End If
 End With
End With
End Function

Public Sub clsBloxorz.SolveItClear()
dim i as long
'///
deallocate _xx_SwitchMap
_xx_SwitchMap=NULL
deallocate _xx_SwitchMapPosId
_xx_SwitchMapPosId=NULL
'///
for i=0 to SwitchStatusCount-1
 deallocate SwitchMapIdPos[i].p
next i
deallocate SwitchMapIdPos
SwitchMapIdPos=NULL
'///
deallocate GTheoryNode
GTheoryNode=NULL
'///
SwitchStatusCount = 0
GTheoryNodeMax = 0
End Sub

Private Function clsBloxorz.pSolveItPosToInt(ByVal p1 As Long, ByVal p2 As Long) As Long
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

Private Sub clsBloxorz.pSolveItCalcPos(ByVal n As Long)
Dim i As Long, j As Long
With SwitchMapIdPos[n-1]
 .Count = 0
 deallocate .p
 .p=NULL
 For i = 1 To datw
  For j = 1 To dath
   Select Case SwitchMap(i, j, n)
   Case 0, 6
    SwitchMapPosId(i, j, n) = 0
   Case Else
    .Count = .Count + 1
    SwitchMapPosId(i, j, n) = .Count
    .p=reallocate(.p,.Count*sizeof(typeSolveItPos))
    With .p[.Count-1]
     .x = i
     .y = j
    End With
   End Select
  Next j
 Next i
End With
End Sub

Public Function clsBloxorz.SolveItIsTrans() As Boolean
SolveItIsTrans = IsTrans
End Function

Public Function clsBloxorz.SolveItGetNodeUsed() As Long
SolveItGetNodeUsed = GTheoryNodeUsed
End Function

Public Function clsBloxorz.SolveItGetNodeMax() As Long
SolveItGetNodeMax = GTheoryNodeMax
End Function

Public Function clsBloxorz.SolveItGetTimeUsed() As Long
SolveItGetTimeUsed = SolveItTime
End Function

Public Function clsBloxorz.SolveItGetSwitchStatusCount() As Long
SolveItGetSwitchStatusCount = SwitchStatusCount
End Function

Public Sub clsBloxorz.SolveItGetSwitchStatus(ByVal Index As Long, d() As Byte)
dim m as long = datw * dath
ReDim d(1 To dath, 1 To datw)
memcpy @d(1, 1), _xx_SwitchMap+(Index-1)*m, m
End Sub

Public Function clsBloxorz.SolveItGetDistance(ByVal Index As Long) As Long
Dim i As Long
i = pSolveItBinarySearchTreeFindNode(Index)
If i > 0 Then
 SolveItGetDistance = GTheoryNode[i-1].Distance
Else
 SolveItGetDistance = &H7FFFFFFF
End If
End Function

Public Function clsBloxorz.SolveItGetSolution(ByVal Index As Long, ByVal lpMovedArea As any ptr=NULL) As String
Dim s As String, ss As String
Dim i As Long, j As Long, k As Long, m As Long
Dim x As Long, y As Long, x2 As Long, y2 As Long
Dim xo As Long, yo As Long, xo2 As Long, yo2 As Long
Dim jj As Long
Dim IsL As Boolean, IsLo As Boolean
Dim MOV As Long, MOVo As Long
Dim d() As Byte, nds() As Long
ReDim d(1 To dath, 1 To datw)
i = pSolveItBinarySearchTreeFindNode(Index)
If i = 0 Then Exit Function
m = GTheoryNode[i-1].Distance
If m = 0 Or m = &H7FFFFFFF Then Exit Function
ReDim nds(1 To m)
For k = m To 1 Step -1
 nds(k) = i
 j = GTheoryNode[i-1].PathPrevEdge
 If j = 0 Then
  Assert(False) 'Exit Do
 end if
 s = CStr(j) + s
 i = GTheoryNode[i-1].PathPrevNode
Next k
If IsTrans Then '??????????????????????????????
 xo = StartX
 yo = StartY
 xo2 = StartX
 yo2 = StartY
 d(yo,xo) = 1
 IsLo = True
 MOVo = 0
 For k = 1 To m
  j = Val(Mid(s, k, 1))
  i = nds(k)
  With GTheoryNode[i-1]
   'determine status index
   jj = .m
   'get pos
   y = .k
   y2 = .k2
  End With
  With SwitchMapIdPos[jj-1]
   x = .p[y-1].x
   y = .p[y-1].y
   x2 = .p[y2-1].x
   y2 = .p[y2-1].y
  End With
  'which is moved?
  j = 1 + ((j - 1) and 3&)
  IsL = (x - x2) * (x - x2) + (y - y2) * (y - y2) <= 1
  If IsLo Then
   If IsL Then 'ice??
    MOV = 0
    If j <= 2 Then
     If xo = x Then
      pSolveItCalcMovedArea d(), xo, yo, x, y, j
      pSolveItCalcMovedArea d(), xo2, yo2, x2, y2, j
     ElseIf xo = x2 Then
      pSolveItCalcMovedArea d(), xo, yo, x2, y2, j
      pSolveItCalcMovedArea d(), xo2, yo2, x, y, j
'     Else
'      Debug.Assert False
     End If
    Else
     If yo = y Then
      pSolveItCalcMovedArea d(), xo, yo, x, y, j
      pSolveItCalcMovedArea d(), xo2, yo2, x2, y2, j
     ElseIf yo = y2 Then
      pSolveItCalcMovedArea d(), xo, yo, x2, y2, j
      pSolveItCalcMovedArea d(), xo2, yo2, x, y, j
'     Else
'      Debug.Assert False
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
      d( y,x) = 1
      If dat(x, y) = 4 Then Exit For
     Next y
    Case 2 'down
     x = xo
     For y = IIf(yo < yo2, yo, yo2) + 2 To dath
      d( y,x) = 1
      If dat(x, y) = 4 Then Exit For
     Next y
    Case 3 'left
     y = yo
     For x = IIf(xo < xo2, xo, xo2) - 1 To 1 Step -1
      d( y,x) = 1
      If dat(x, y) = 4 Then Exit For
     Next x
    Case 4 'right
     y = yo
     For x = IIf(xo < xo2, xo, xo2) + 2 To datw
      d( y,x) = 1
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
    pSolveItCalcMovedArea d(), xo2, yo2, x2, y2, j
    xo2 = x2
    yo2 = y2
   ElseIf xo = x2 And yo = y2 Then
    MOV = 2
    pSolveItCalcMovedArea d(), xo2, yo2, x, y, j
    xo2 = x
    yo2 = y
   ElseIf xo2 = x And yo2 = y Then
    MOV = 1
    pSolveItCalcMovedArea d(), xo, yo, x2, y2, j
    xo = x2
    yo = y2
   ElseIf xo2 = x2 And yo2 = y2 Then
    MOV = 1
    pSolveItCalcMovedArea d(), xo, yo, x, y, j
    xo = x
    yo = y
   Else
    Assert(False)
   End If
  End If
  'need to press space bar?
  If MOV + MOVo = 3 Then
   ss = ss + "s"
  End If
  ss = ss + CStr(j)
  'moved area
  d( y,x) = 1
  d( y2,x2) = 1
  'next
  MOVo = MOV
  IsLo = IsL
 Next k
 s = ss
ElseIf lpMovedArea <> 0 Then
 xo = StartX
 yo = StartY
 d( yo,xo) = 1
 For k = 1 To m
  j = Val(Mid(s, k, 1))
  i = nds(k)
  With GTheoryNode[i-1]
   'determine status index
   jj = .m
   'get pos
   x2 = .k
   y2 = .k2
  End With
  With SwitchMapIdPos[jj-1].p[x2-1]
   x = .x
   y = .y
  End With
  'moved area
  d( y,x) = 1
  Select Case y2
  Case 0 'up
   pSolveItCalcMovedArea d(), xo, yo, x, y, j
  Case 1 'h
   pSolveItCalcMovedArea d(), xo, yo, x, y, j
   If j = 3 Then
    pSolveItCalcMovedArea d(), xo, yo, x + 1, y, j
   Else
    pSolveItCalcMovedArea d(), xo + 1, yo, x + 1, y, j
   End If
  Case 2 'v
   pSolveItCalcMovedArea d(), xo, yo, x, y, j
   If j = 1 Then
    pSolveItCalcMovedArea d(), xo, yo, x, y + 1, j
   Else
    pSolveItCalcMovedArea d(), xo, yo + 1, x, y + 1, j
   End If
  Case 3 'ERR!
   Assert(False)
  End Select
  'next
  xo = x
  yo = y
 Next k
End If
If lpMovedArea <> NULL Then memcpy lpMovedArea, @d(1, 1), datw * dath
'/// no Replace in stupid FreeBasic :@
's = Replace(s, "1", "u")
's = Replace(s, "2", "d")
's = Replace(s, "3", "l")
's = Replace(s, "4", "r")
'///
for i=0 to len(s)-1
 select case s[i]
 case &H31: s[i]=117
 case &H32: s[i]=100
 case &H33: s[i]=108
 case &H34: s[i]=114
 end select
next i
'///
SolveItGetSolution = s
End Function

Private Sub clsBloxorz.pSolveItCalcMovedArea(d() As Byte, ByVal xo As Long, ByVal yo As Long, ByVal x As Long, ByVal y As Long, ByVal FS As Long)
Dim k As Long
   Select Case FS
   Case 1 'up
    For k = yo To y Step -1
     d( k,x) = 1
    Next k
   Case 2 'down
    For k = yo To y
     d( k,x) = 1
    Next k
   Case 3 'left
    For k = xo To x Step -1
     d( y,k) = 1
    Next k
   Case 4 'right
    For k = xo To x
     d( y,k) = 1
    Next k
   End Select
End Sub

Public Function clsBloxorz.SolveItGetSolutionNodeIndex(byref SolX As Long=0, byref SolY As Long=0,byref SolSwitchStatus As Long=0) As Long
Dim i As Long, j As Long, k As Long, n As Long, m As Long
Dim x As Long, y As Long
   m = &H7FFFFFFF
   For x = 1 To datw
    For y = 1 To dath
     If dat(x, y) = 8 Then
      For i = 1 To SwitchStatusCount
       j = SolveItGetNodeIndex(i, 0, x, y)
       k = pSolveItBinarySearchTreeFindNode(j)
       If k > 0 Then
        k = GTheoryNode[k-1].Distance
        If k < m Then
         m = k
         n = j
         SolX = x
         SolY = y
         SolSwitchStatus = i
        End If
       End If
      Next i
     End If
    Next y
   Next x
   SolveItGetSolutionNodeIndex = n
End Function

Public Function clsBloxorz.SolveItGetNodeIndex(ByVal m As Long, ByVal State As Long, ByVal x As Long, ByVal y As Long, ByVal x2 As Long=0, ByVal y2 As Long=0) As Long
Dim j As Long, jj As Long
With SwitchMapIdPos[m-1]
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

Public Function clsBloxorz.BloxorzCheckIsValidState(d() As Byte, ByVal x As Long, ByVal y As Long, ByVal GameS As Long, ByVal x2 As Long=0, ByVal y2 As Long=0) As enumBloxorzStateValid
Select Case GameS
Case 0 'up
 If x > 0 And y > 0 And x <= datw And y <= dath Then
  Select Case d( y,x)
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
 If x > 0 And y > 0 And x < datw And y <= dath Then
  If d( y,x) = 11 And d( y,x + 1) = 11 Then
   'ERR!
   BloxorzCheckIsValidState = 99
  ElseIf d( y,x) = 0 Or d( y,x) = 6 Or d( y,x + 1) = 0 Or d( y,x + 1) = 6 Then
   BloxorzCheckIsValidState = 0
  Else
   BloxorzCheckIsValidState = 1
  End If
 End If
Case 2 'v
 If x > 0 And y > 0 And x <= datw And y < dath Then
  If d( y,x) = 11 And d( y + 1,x) = 11 Then
   'ERR!
   BloxorzCheckIsValidState = 99
  ElseIf d( y,x) = 0 Or d( y,x) = 6 Or d( y + 1,x) = 0 Or d( y + 1,x) = 6 Then
   BloxorzCheckIsValidState = 0
  Else
   BloxorzCheckIsValidState = 1
  End If
 End If
Case 3 'single
 If x > 0 And y > 0 And x <= datw And y <= dath Then
  If x2 > 0 And y2 > 0 And x2 <= datw And y2 <= dath Then
   If d( y,x) = 11 Or d( y2,x2) = 11 Then
    'ERR!
    BloxorzCheckIsValidState = 99
   ElseIf d( y,x) = 0 Or d( y,x) = 6 Or d( y2,x2) = 0 Or d( y2,x2) = 6 Then
    BloxorzCheckIsValidState = 0
   Else
    BloxorzCheckIsValidState = 1
   End If
  End If
 Else
 End If
End Select
End Function

Public Function clsBloxorz.BloxorzCheckIsMovable(d() As Byte, ByVal x As Long, ByVal y As Long, ByVal GameS As Long, ByVal FS As Long, byref QIE As Long=0) As Boolean
BloxorzCheckIsMovable = True
QIE = 0
Select Case GameS
Case 0, 3 'up/single
 Select Case FS
 Case 1 'up
  If y > 1 Then
   If d( y - 1,x) = 11 Then BloxorzCheckIsMovable = False
   If GameS = 0 And y > 2 Then If d( y - 2,x) = 11 Then QIE = 1
  End If
 Case 2 'down
  If y < dath Then
   If d( y + 1,x) = 11 Then BloxorzCheckIsMovable = False
   If GameS = 0 And y < dath - 1 Then If d( y + 2,x) = 11 Then QIE = 2
  End If
 Case 3 'left
  If x > 1 Then
   If d( y,x - 1) = 11 Then BloxorzCheckIsMovable = False
   If GameS = 0 And x > 2 Then If d( y,x - 2) = 11 Then QIE = 3
  End If
 Case 4 'right
  If x < datw Then
   If d( y,x + 1) = 11 Then BloxorzCheckIsMovable = False
   If GameS = 0 And x < datw - 1 Then If d( y,x + 2) = 11 Then QIE = 4
  End If
 End Select
Case 1 'h
 Select Case FS
 Case 1 'up
  If y > 1 Then
   If d( y - 1,x) = 11 Then If d( y,x) <> 11 Then BloxorzCheckIsMovable = False Else QIE = 3 'left block?
   If d( y - 1,x + 1) = 11 Then If d( y,x + 1) <> 11 Then BloxorzCheckIsMovable = False Else QIE = 4 'right block?
  End If
 Case 2 'down
  If y < dath Then
   If d( y + 1,x) = 11 Then If d( y,x) <> 11 Then BloxorzCheckIsMovable = False Else QIE = 3 'left block?
   If d( y + 1,x + 1) = 11 Then If d( y,x + 1) <> 11 Then BloxorzCheckIsMovable = False Else QIE = 4 'right block?
  End If
 Case 3 'left
  If x > 1 Then If d( y,x - 1) = 11 Then BloxorzCheckIsMovable = False
  If d( y,x) = 11 Then BloxorzCheckIsMovable = False
 Case 4 'right
  If x < datw - 1 Then If d( y,x + 2) = 11 Then BloxorzCheckIsMovable = False
  If d( y,x + 1) = 11 Then BloxorzCheckIsMovable = False
 End Select
Case 2 'v
 Select Case FS
 Case 1 'up
  If y > 1 Then If d( y - 1,x) = 11 Then BloxorzCheckIsMovable = False
  If d( y,x) = 11 Then BloxorzCheckIsMovable = False
 Case 2 'down
  If y < dath - 1 Then If d( y + 2,x) = 11 Then BloxorzCheckIsMovable = False
  If d( y + 1,x) = 11 Then BloxorzCheckIsMovable = False
 Case 3 'left
  If x > 1 Then
   If d( y,x - 1) = 11 Then If d( y,x) <> 11 Then BloxorzCheckIsMovable = False Else QIE = 1 'up block?
   If d( y + 1,x - 1) = 11 Then If d( y + 1,x) <> 11 Then BloxorzCheckIsMovable = False Else QIE = 2 'down block?
  End If
 Case 4 'right
  If x < datw Then
   If d( y,x + 1) = 11 Then If d( y,x) <> 11 Then BloxorzCheckIsMovable = False Else QIE = 1 'up block?
   If d( y + 1,x + 1) = 11 Then If d( y + 1,x) <> 11 Then BloxorzCheckIsMovable = False Else QIE = 2 'down block?
  End If
 End Select
End Select
End Function

Public Function clsBloxorz.BloxorzCheckBlockSlip(d() As Byte, ByVal x As Long, ByVal y As Long, ByVal GameS As Long, ByVal FS As Long, ByVal x2 As Long=0, ByVal y2 As Long=0) As Long
'TODO:new block?
Select Case GameS
Case 0, 3 'up/single
 'hit block?
 Select Case FS
 Case 1 'up
  If y > 1 Then
   If dat(x, y - 1) = 11 Then Exit Function
   If GameS = 3 And x = x2 And y - 1 = y2 Then Exit Function
  End If
 Case 2 'down
  If y < dath Then
   If dat(x, y + 1) = 11 Then Exit Function
   If GameS = 3 And x = x2 And y + 1 = y2 Then Exit Function
  End If
 Case 3 'left
  If x > 1 Then
   If dat(x - 1, y) = 11 Then Exit Function
   If GameS = 3 And y = y2 And x - 1 = x2 Then Exit Function
  End If
 Case 4 'right
  If x < datw Then
   If dat(x + 1, y) = 11 Then Exit Function
   If GameS = 3 And y = y2 And x + 1 = x2 Then Exit Function
  End If
 End Select
 Select Case d( y,x)
 Case 9 'ice
  BloxorzCheckBlockSlip = FS
 End Select
Case 1 'h
 'hit block?
 Select Case FS
 Case 1 'up
  If y > 1 Then
   If dat(x, y - 1) = 11 Or dat(x + 1, y - 1) = 11 Then Exit Function
  End If
 Case 2 'down
  If y < dath Then
   If dat(x, y + 1) = 11 Or dat(x + 1, y + 1) = 11 Then Exit Function
  End If
 Case 3 'left
  If x > 1 Then
   If dat(x - 1, y) = 11 Then Exit Function
  End If
 Case 4 'right
  If x < datw - 1 Then
   If dat(x + 2, y) = 11 Then Exit Function
  End If
 End Select
 If d( y,x) = 9 And d( y,x + 1) = 9 Then 'ice
  BloxorzCheckBlockSlip = FS
 End If
Case 2 'v
 'hit block?
 Select Case FS
 Case 1 'up
  If y > 1 Then
   If dat(x, y - 1) = 11 Then Exit Function
  End If
 Case 2 'down
  If y < dath - 1 Then
   If dat(x, y + 2) = 11 Then Exit Function
  End If
 Case 3 'left
  If x > 1 Then
   If dat(x - 1, y) = 11 Or dat(x - 1, y + 1) = 11 Then Exit Function
  End If
 Case 4 'right
  If x < datw Then
   If dat(x + 1, y) = 11 Or dat(x + 1, y + 1) = 11 Then Exit Function
  End If
 End Select
 If d( y,x) = 9 And d( y + 1,x) = 9 Then 'ice
  BloxorzCheckBlockSlip = FS
 End If
End Select
End Function

Public Function clsBloxorz.BloxorzCheckPressButton(d() As Byte, ByVal x As Long, ByVal y As Long, ByVal GameS As Long, ByVal lpBridgeChangeArray As any ptr=NULL, ByVal BridgeOff As Long=0, ByVal BridgeOn As Long=0) As Long
Dim i As Long, j As Long, k As Long
Dim btns(1 To 2) As Long
Dim d2() As Long
dim ret as long=0
If lpBridgeChangeArray <> NULL Then
 ReDim d2(1 To dath, 1 To datw)
End If
Select Case GameS
Case 0, 3 'up/single
 i = d( y,x)
 If i = 2 Or (i = 3 And GameS = 0) Then btns(1) = dat2(x, y)
Case 1 'h
 If d( y,x) = 2 Then btns(1) = dat2(x, y)
 If d( y,x + 1) = 2 Then btns(2) = dat2(x + 1, y)
Case 2 'v
 If d( y,x) = 2 Then btns(1) = dat2(x, y)
 If d( y + 1,x) = 2 Then btns(2) = dat2(x, y + 1)
End Select
For i = 1 To 2
 k = btns(i)
 If k > 0 And k <= swc Then
  With sws[k-1]
   For j = 1 To .bc
    With .bs[j-1]
     If .x > 0 And .y > 0 And .x <= datw And .y <= dath Then
      Select Case d( .y,.x)
      Case 6, 7
       Select Case .Behavior
       Case 0 'off
        d( .y,.x) = 6
       Case 1 'on
        d( .y,.x) = 7
       Case 2 'toggle
        d( .y,.x) = 13 - d( .y,.x)
       End Select
       If lpBridgeChangeArray <> 0 Then If d( .y,.x) = 6 Then d2( .y,.x) = BridgeOff Else d2( .y,.x) = BridgeOn
       ret += 1
      End Select
     End If
    End With
   Next j
  End With
 End If
Next i
If lpBridgeChangeArray <> NULL Then memcpy lpBridgeChangeArray, @d2(1, 1), 4& * datw * dath
return ret
End Function

'stupid
Function clsBloxorz.FromString(ByRef sString As String) As Boolean
Dim v() As String, m As Long
Dim s As String
Dim i As Long, j As Long, k As Long
Dim i1 As Long, i2 As Long, i3 As Long
'///
Destroy
Split(Replace(Replace(sString, vbCr, ","), vbLf, ","), ",", v())
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
   0 < StartY And StartY <= dath And dath <= 255 And swc >= 0) Then Return False
   _xx_dat=callocate(datw*dath)
   _xx_dat2=callocate(datw*dath,4&)
   If swc > 0 Then sws=callocate(swc,sizeof(typeSwitch))
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
     sws[k-1].bc = j
     If j > 0 Then sws[k-1].bs=callocate(j,sizeof(typeBridge))
     i3 = i3 + 1
    Else
     Select Case i2
     Case 1: sws[k-1].bs[i3-1].x = j
     Case 2: sws[k-1].bs[i3-1].y = j
     Case 3: sws[k-1].bs[i3-1].Behavior = j
     End Select
     i2 = i2 + 1
     If i2 > 3 Then
      i2 = 1
      i3 = i3 + 1
     End If
    End If
    If i3 > sws[k-1].bc Then
     i1 = i1 + 1
     i3 = 0
    End If
   End If
  End Select
 End If
Next i
Return i1 > 4
End Function

'stupid
Function clsBloxorz.ToString() As String
Dim s As String, s1 As String
Dim i As Long, j As Long
If datw <= 0 Or dath <= 0 Then Exit Function
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
 s = s + CStr(sws[i-1].bc) + vbCrLf
 For j = 1 To sws[i-1].bc
  s = s + CStr(sws[i-1].bs[j-1].x) + "," + CStr(sws[i-1].bs[j-1].y) + "," + CStr(sws[i-1].bs[j-1].Behavior) + vbCrLf
 Next j
Next i
'///
Return s
End Function

Sub clsBloxorz.CopyToClipboard()
Clipboard.Clear
Clipboard.SetText ToString
End Sub

Function clsBloxorz.PasteFromClipboard() As Boolean
Return FromString(Clipboard.GetText)
End Function
