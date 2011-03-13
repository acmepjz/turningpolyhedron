#include once "main.bi"
#include once "LZSS.bi"
#include once "clsTheFile.bi"
#include once "crt/string.bi"
#include once "crt/stdio.bi"

Type typeFileNode
 Size As Long
 d As Byte ptr
End Type

Type typeFileNodeArray
 Name As Long
 Count As Long
 nd As typeFileNode ptr
End Type


Public function clsTheFile.FileName() As String
return m_sFileName
End function

Public function clsTheFile.NodeCount(ByVal Index As Long) As Long
return nds[Index-1].Count
End function

Public Sub clsTheFile.AddNode(ByVal Index As Long)
With nds[Index-1]
 .Count += 1
 .nd=Reallocate(.nd,.Count*sizeof(typeFileNode))
 memset(@(.nd[.Count-1]),0,sizeof(typeFileNode))
End With
End Sub

Public Sub clsTheFile.RemoveNode(ByVal Index As Long, ByVal Index2 As Long)
Dim i As Long
With nds[Index-1]
 if index2>0 and index2<=.Count then
  index2-=1
  deallocate .nd[i].d
  for i=index2 to .count-1
   .nd[i]=.nd[i+1]
  next i
  if .count<=1 then
   .count=0
   deallocate .nd
   .nd=NULL
  else
   .count-=1
   .nd=Reallocate(.nd,.Count*sizeof(typeFileNode))
  end if 
 end if
End With
End Sub

Public Sub clsTheFile.ClearNode(ByVal Index As Long)
dim i as long
With nds[Index-1]
 for i=0 to .count-1
  deallocate .nd[i].d
 next i
 .Count = 0
 deallocate .nd
 .nd=NULL
End With
End Sub

Public function clsTheFile.NodeSize(ByVal Index As Long, ByVal Index2 As Long) As Long
NodeSize = nds[Index-1].nd[Index2-1].Size
End function

Public sub clsTheFile.SetNodeSize(ByVal Index As Long, ByVal Index2 As Long, ByVal m As Long)
With nds[Index-1].nd[Index2-1]
 .Size = m
 deallocate .d
 .d=NULL
 If m > 0 Then .d=callocate(m)
End With
End sub

Public Sub clsTheFile.GetNodeData(ByVal Index As Long, ByVal Index2 As Long, b() As Byte)
Dim m As Long
With nds[Index-1].nd[Index2-1]
 m = .Size
 If m > 0 Then
  ReDim b(1 To m)
  memcpy @b(1), .d, m
 Else
  Erase b
 End If
End With
End Sub

Public Sub clsTheFile.SaveNodeDataToFile(ByVal Index As Long, ByVal Index2 As Long, fn As String)
dim as FILE ptr f
With nds[Index-1].nd[Index2-1]
 f=fopen(fn,"wb")
 if f<>NULL then
  if .size>0 then fwrite(.d,1,.size,f)
  fclose(f)
 end if
End With
End Sub

Public Sub clsTheFile.SetNodeData(ByVal Index As Long, ByVal Index2 As Long, b() As Byte)
Dim m As Long, l As Long
l = LBound(b)
m = UBound(b) - l + 1
If Err <> 0 Then m = 0
With nds[Index-1].nd[Index2-1]
 .Size = m
 deallocate .d
 .d=NULL
 If m > 0 Then
  .d=allocate(m)
  memcpy .d, @b(l), m
 End If
End With
End Sub

Public Sub clsTheFile.LoadNodeDataFromFile(ByVal Index As Long, ByVal Index2 As Long, fn As String)
dim as FILE ptr f
With nds[Index-1].nd[Index2-1]
 f=fopen(fn,"rb")
 if f<>NULL then
  fseek(f,0,SEEK_END)
  .size=ftell(f)
  fseek(f,0,SEEK_SET)
  deallocate .d
  .d=NULL
  If .Size > 0 Then
   .d=allocate(.size)
   fread(.d,1,.size,f)
  End If
  fclose(f)
 end if
End With
End Sub

Public Sub clsTheFile.GetNodeDataEx(ByVal Index As Long, ByVal Index2 As Long, ByVal lp As any ptr)
Dim m As Long
With nds[Index-1].nd[Index2-1]
 m = .Size
 If m > 0 Then
  memcpy lp, .d, m
 End If
End With
End Sub

Public Sub clsTheFile.SetNodeDataEx(ByVal Index As Long, ByVal Index2 As Long, ByVal m As Long, ByVal lp As any ptr)
With nds[Index-1].nd[Index2-1]
 .Size = m
 deallocate .d
 .d=NULL
 If m > 0 Then
  .d=allocate(m)
  memcpy .d, lp, m
 End If
End With
End Sub

Public Sub clsTheFile.ClearNodeData(ByVal Index As Long, ByVal Index2 As Long)
With nds[Index-1].nd[Index2-1]
 .Size = 0
 deallocate .d
 .d=NULL
End With
End Sub

Public Sub clsTheFile.EraseNodeData(ByVal Index As Long, ByVal Index2 As Long)
With nds[Index-1].nd[Index2-1]
 If .Size > 0 Then memset .d,0, .Size
End With
End Sub

Public function clsTheFile.NodeArrayCount() As Long
NodeArrayCount = ndc
End function

Public Sub clsTheFile.AddNodeArray(ByVal n As any ptr=NULL)
ndc += 1
nds=reallocate(nds,ndc*sizeof(typeFileNodeArray))
nds[ndc-1].Name = 0
if n<>NULL then nds[ndc-1].Name = *cast(long ptr,n)
nds[ndc-1].count=0
nds[ndc-1].nd=NULL
End Sub

Public Property clsTheFile.NodeArrayName(ByVal Index As Long) As String
Dim s As String
s=space(4)
memcpy strptr(s), @(nds[Index-1].Name), 4&
return s
End Property

Public Property clsTheFile.NodeArrayName(ByVal Index As Long, s As String)
dim lp as any pointer
lp=strptr(s)
if lp<>NULL then nds[Index-1].Name = *cast(long ptr,lp) else nds[Index-1].Name = 0
End Property

Public Property clsTheFile.NodeArrayNameValue(ByVal Index As Long) As Long
return nds[Index-1].Name
End Property

Public Property clsTheFile.NodeArrayNameValue(ByVal Index As Long, ByVal n As Long)
nds[Index-1].Name = n
End Property

Public Sub clsTheFile.SetNodeArrayName(ByVal Index As Long, ByVal lp As any ptr)
if lp<>NULL then nds[Index-1].Name = *cast(long ptr,lp) else nds[Index-1].Name = 0
End Sub

Public Function clsTheFile.FindNodeArray(ByVal lp As any ptr, ByVal Start As Long=1) As Long
Dim i As Long, n As Long
if lp<>NULL then n = *cast(long ptr,lp) else n = 0
For i = Start-1 To ndc-1
 If nds[i].Name = n Then return i+1
Next i
End Function

Public Sub clsTheFile.RemoveNodeArray(ByVal Index As Long)
Dim i As Long,j as long
if index>0 and index<=ndc then
 with nds[index-1]
  for i=0 to .count-1
   deallocate .nd[i].d
  next i
  deallocate .nd
 end with
 '///
 if ndc<=1 then
  ndc=0
  deallocate nds
  nds=NULL
 else
  ndc = ndc - 1
  For i = Index To ndc
   nds[i-1] = nds[i]
  Next i
  nds=reallocate(nds,ndc*sizeof(typeFileNodeArray))
 end if 
end if
End Sub

Public Property clsTheFile.Signature() As String
dim s as string
s=space(8)
memcpy strptr(s),@sig(0),8&
return s
End Property

Public Property clsTheFile.Signature( s As String)
dim s1 as string=s + !"\0\0\0\0\0\0\0\0"
memcpy @sig(0),strptr(s1),8&
End Property

Public Function clsTheFile.LoadFile( fn As String, ByVal _Signature As any ptr=NULL, ByVal bSkipSignature As Boolean=False) As Boolean
Dim i As Long, j As Long, m As Long, lp As Long
Dim b() As Byte,b2() as byte
dim f as FILE ptr
Clear
f=fopen(fn,"rb")
if f=NULL then exit function
'///
ReDim b(7)
fread(@b(0),1,8,f)
'///
If _Signature <> NULL And Not bSkipSignature Then
 If memcmp(_Signature, @b(0),8) Then 'err!
  erase sig
  fClose(f)
  Exit Function
 End If
End If
memcpy(@sig(0),@b(0),8)
'///
fread(@m,4,1,f)
If m < 0 Then
 j = -m
 fseek(f,0,SEEK_END)
 m=ftell(f)
 fseek(f,12,SEEK_SET)
 m -= 12
 ReDim b(1 To m)
 fread(@b(1),1,m,f)
 DecompressData b(), b2(), j
 pLoadData b2()
Else
 fseek(f,0,SEEK_END)
 m=ftell(f)
 fseek(f,8,SEEK_SET)
 m -= 8
 ReDim b(1 To m)
 fread(@b(1),1,m,f)
 pLoadData b()
End If
'///
fclose(f)
m_sFileName = fn
return True
End Function

Public Function clsTheFile.LoadData(d() As Byte, ByVal _Signature As any ptr=NULL) As Boolean
Dim i As Long, j As Long, m As Long, lp As Long
Dim b() As Byte, b2() As Byte
Clear
'///
lp = LBound(d)
ReDim b(7)
memcpy @b(0), @d(lp), 8&
If _Signature <> NULL Then
 If memcmp(_Signature, @b(0),8) Then 'err!
  erase sig
  Exit Function
 End If
End If
memcpy(@sig(0),@b(0),8)
'///
memcpy @m, @d(lp + 8), 4&
If m < 0 Then
 j = -m
 m = UBound(d) - lp + 1
 m = m - 12
 ReDim b(1 To m)
 memcpy @b(1), @d(lp + 12), m
 DecompressData b(), b2(), j
 pLoadData b2()
Else
 m = UBound(d) - lp + 1
 m = m - 8
 ReDim b(1 To m)
 memcpy @b(1), @d(lp + 8), m
 pLoadData b()
End If
LoadData = True
End Function

Private Sub clsTheFile.pLoadData(b() As Byte)
Dim i As Long, j As Long, m As Long, lp As Long
memcpy @ndc, @b(1), 4&
If ndc > 0 Then
 nds=callocate(ndc,sizeof(typeFileNodeArray))
 lp = 5
 For i = 0 To ndc-1
  With nds[i]
   memcpy @.Name, @b(lp), 4&
   memcpy @.Count, @b(lp + 4), 4&
   .nd=NULL
   lp = lp + 8
   If .Count > 0 Then
    .nd=callocate(.count,sizeof(typeFileNode))
    For j = 0 To .Count-1
     With .nd[j]
      memcpy @.Size, @b(lp), 4&
      .d=NULL
      If .Size > 0 Then
       .d=allocate(.size)
       memcpy .d, @b(lp + 4), .Size
      End If
      lp = lp + 4 + .Size
     End With
    Next j
   End If
  End With
 Next i
End If
End Sub

Public Function clsTheFile.SaveFile(byref fn As String = "", ByVal IsCompress As Boolean = True) As Boolean
Dim i As Long, j As Long, m As Long
Dim b() As Byte, b2() As Byte, s As String
dim f as file pointer
If fn = "" Then fn = m_sFileName
If fn = "" Then Exit Function
f=fopen(fn,"wb")
if f=NULL then exit function
fwrite(@sig(0),1,8,f)
m = pSaveData(b())
If IsCompress Then
 m = -m
 fwrite(@m,4,1,f)
 m = CompressData(b(), b2())
 fwrite(@b2(1),1,m,f)
Else
 fwrite(@b(1),1,m,f)
End If
fclose(f)
m_sFileName = fn
SaveFile = True
End Function

'Public Function clsTheFile.SaveData(d() As Byte, ByVal IsCompress As Boolean = True) As Long
'Dim i As Long, j As Long, m As Long
'Dim b() As Byte, b2() As Byte, s As String
'm = pSaveData(b())
'If IsCompress Then
' m = -m
' Put #1, 9, m
' m = cmp.CompressData(b(), b2())
' SaveData = m + 12
' ReDim d(1 To m + 12)
' memcpy @d(13), @b2(1), m
'Else
' SaveData = m + 8
' ReDim d(1 To m + 8)
' memcpy @d(9), @b(1), m
'End If
'memcpy @d(1), @sig(1), 8&
'End Function

Private Function clsTheFile.pSaveData(b() As Byte) As Long
Dim i As Long, j As Long, m As Long, lp As Long
'calc max
m = 4 + ndc * 8&
For i = 0 To ndc-1
 With nds[i]
  m = m + .Count * 4&
  For j = 0 To .Count-1
   m = m + .nd[j].Size
  Next j
 End With
Next i
pSaveData = m
ReDim b(1 To m)
'save
memcpy @b(1), @ndc, 4&
lp = 5
For i = 0 To ndc-1
 With nds[i]
  memcpy @b(lp), @.Name, 4& '8&
  memcpy @b(lp + 4), @.Count, 4&
  lp = lp + 8
  For j = 0 To .Count-1
   With .nd[j]
    memcpy @b(lp), @.Size, 4&
    If .Size > 0 Then
     memcpy @b(lp + 4), .d, .Size
    End If
    lp = lp + 4 + .Size
   End With
  Next j
 End With
Next i
End Function

Public Sub clsTheFile.Clear()
dim i as long,j as long
for i=0 to ndc-1
 for j=0 to nds[i].count-1
  deallocate nds[i].nd[j].d
 next j
 deallocate nds[i].nd
next i
deallocate nds
nds=NULL
ndc = 0
memset(@sig(0),0,8)
m_sFileName = ""
End Sub

Public Destructor clsTheFile()
Clear
End Destructor


