VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "ISort"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Public Function Compare(ByVal Index1 As Long, ByVal Index2 As Long, ByVal nUserData As Long) As Boolean
'implements
End Function

'most stupid algorithm
Friend Sub BubbleSort(idxArray() As Long, ByVal nStart As Long, ByVal nEnd As Long, obj As ISort, ByVal nUserData As Long)
Dim i As Long, j As Long
Dim idx1 As Long, idx2 As Long
For i = nEnd - 1 To nStart Step -1
 idx1 = idxArray(nStart)
 For j = nStart To i
  idx2 = idxArray(j + 1)
  If obj.Compare(idx1, idx2, nUserData) Then
   idxArray(j) = idx2
   idxArray(j + 1) = idx1
  Else
   idx1 = idx2
  End If
 Next j
Next i
End Sub

Friend Sub InsertSort(idxArray() As Long, ByVal nStart As Long, ByVal nEnd As Long, obj As ISort, ByVal nUserData As Long)
Dim i As Long, j As Long
Dim idx1 As Long, idx2 As Long
For i = nStart + 1 To nEnd
 idx2 = idxArray(i)
 For j = i To nStart + 1 Step -1
  idx1 = idxArray(j - 1)
  If Not obj.Compare(idx1, idx2, nUserData) Then Exit For
  idxArray(j) = idx1
 Next j
 If j < i Then idxArray(j) = idx2
Next i
End Sub

Private Sub pQuickSort(idxArray() As Long, ByVal nStart As Long, ByVal nEnd As Long, obj As ISort, ByVal nUserData As Long, ByVal nLimit As Long)
Dim i As Long, j As Long
Dim idx1 As Long, idx2 As Long, idx3 As Long
If nEnd - nStart < nLimit Then Exit Sub
If nEnd - nStart = 1 Then
 idx1 = idxArray(nStart)
 idx2 = idxArray(nEnd)
 If obj.Compare(idx1, idx2, nUserData) Then
  idxArray(nStart) = idx2
  idxArray(nEnd) = idx1
 End If
 Exit Sub
End If
'////////quicksort algorithm
'median3
i = (nStart + nEnd) \ 2
idx1 = idxArray(nStart)
idx2 = idxArray(i)
idx3 = idxArray(nEnd)
If obj.Compare(idx1, idx3, nUserData) Then
 If obj.Compare(idx1, idx2, nUserData) Then
  If obj.Compare(idx2, idx3, nUserData) Then
   idxArray(i) = idx1
   idx1 = idx2
  Else
   idxArray(nEnd) = idx1
   idx1 = idx3
  End If
 End If
Else
 If Not obj.Compare(idx1, idx2, nUserData) Then
  If obj.Compare(idx2, idx3, nUserData) Then
   idxArray(nEnd) = idx1
   idx1 = idx3
  Else
   idxArray(i) = idx1
   idx1 = idx2
  End If
 End If
End If
'compare
i = nStart + 1
j = nEnd
Do
 Do Until i > j
  idx2 = idxArray(i)
  If obj.Compare(idx2, idx1, nUserData) Then Exit Do
  i = i + 1
 Loop
 Do Until i > j
  idx3 = idxArray(j)
  If obj.Compare(idx1, idx3, nUserData) Then Exit Do
  j = j - 1
 Loop
 If i < j Then
  'swap
  idxArray(i) = idx3
  idxArray(j) = idx2
  i = i + 1
  j = j - 1
 End If
Loop Until i > j
Debug.Assert i = j + 1
'swap
If j > nStart Then idxArray(nStart) = idxArray(j)
idxArray(j) = idx1
'recursive
pQuickSort idxArray, nStart, j - 1, obj, nUserData, nLimit
pQuickSort idxArray, j + 1, nEnd, obj, nUserData, nLimit
'////////
End Sub

Friend Sub QuickSort(idxArray() As Long, ByVal nStart As Long, ByVal nEnd As Long, obj As ISort, ByVal nUserData As Long, Optional ByVal nLimit As Long = 8)
If nLimit < 1 Then nLimit = 1
pQuickSort idxArray, nStart, nEnd, obj, nUserData, nLimit
If nLimit > 1 Then InsertSort idxArray, nStart, nEnd, obj, nUserData
End Sub
