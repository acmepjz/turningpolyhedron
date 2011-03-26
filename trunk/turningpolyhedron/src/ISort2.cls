VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "ISort2"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

#Const UseMSVCRT = 0

#If UseMSVCRT Then

'/***
'*qsort(base, num, wid, comp) - quicksort function for sorting arrays
'*
'*Purpose:
'*   quicksort the array of elements
'*   side effects:  sorts in place
'*   maximum array size is number of elements times size of elements,
'*   but is limited by the virtual address space of the processor
'*
'*Entry:
'*   char *base = pointer to base of array
'*   size_t num  = number of elements in the array
'*   size_t width = width in bytes of each array element
'*   int (*comp)() = pointer to function returning analog of strcmp for
'*           strings, but supplied by user for comparing the array elements.
'*           it accepts 2 pointers to elements.
'*           Returns neg if 1<2, 0 if 1=2, pos if 1>2.
'*
'*Exit:
'*   returns void
'*
'*Exceptions:
'*   Input parameters are validated. Refer to the validation section of the function.
'*
'*******************************************************************************/

Private Declare Function CallWindowProc Lib "user32.dll" Alias "CallWindowProcA" (ByVal lpPrevWndFunc As Long, ByVal hwnd As Long, ByVal msg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)
Private Declare Function LoadLibrary Lib "kernel32.dll" Alias "LoadLibraryA" (ByVal lpLibFileName As String) As Long
Private Declare Function FreeLibrary Lib "kernel32.dll" (ByVal hLibModule As Long) As Long
Private Declare Function GetProcAddress Lib "kernel32.dll" (ByVal hModule As Long, ByVal lpProcName As String) As Long

Private m_bCode(255) As Byte, m_hMod As Long, m_lpFunc As Long
Private m_lpObjPtr As Long, m_nUserData As Long

#End If

Public Function Compare(ByVal Index1 As Long, ByVal Index2 As Long, ByVal nUserData As Long) As Long
'default implementation (???)
If Index1 < Index2 Then Compare = -1 Else _
If Index1 > Index2 Then Compare = 1 Else Compare = 0
End Function

Friend Sub QuickSort(idxArray() As Long, ByVal nStart As Long, ByVal nEnd As Long, Optional ByVal obj As ISort2, Optional ByVal nUserData As Long, Optional ByVal nLimit As Long = 75)
'///check
If nEnd - nStart <= 0 Then Exit Sub
If obj Is Nothing Then Set obj = Me
'///
#If UseMSVCRT Then
If m_lpFunc Then
 m_lpObjPtr = ObjPtr(obj)
 m_nUserData = nUserData
 CallWindowProc VarPtr(m_bCode(0)), VarPtr(idxArray(nStart)), nEnd - nStart + 1, m_lpFunc, 0
 Exit Sub
End If
#Else
'////////////////////////////////TODO:translate qsort.c into VB
Dim i As Long, j As Long, k As Long 'temp
Dim nMid As Long '/* points to middle of subarray */
Dim lpStart As Long, lpEnd As Long '/* traveling pointers for partition step */
Dim nSize As Long '/* size of the sub-array */
Dim nStartStack(31) As Long, nEndStack(31) As Long, nStack As Long '/* stack for saving sub-array to be processed */
'/* this entry point is for pseudo-recursion calling: setting
'   lo and hi and jumping to here is like recursion, but stkptr is
'   preserved, locals aren't, so we preserve stuff on the stack */
Recurse:
'size = (hi - lo) / width + 1;        /* number of el's to sort */
nSize = nEnd - nStart + 1
'/* below a certain size, it is faster to use a O(n^2) sorting method */
If nSize <= nLimit Then
 'shortsort
 If nSize > 1 Then
  Do
   lpStart = nStart
   i = idxArray(lpStart)
   For lpEnd = nStart + 1 To nEnd
    j = idxArray(lpEnd)
    If obj.Compare(j, i, nUserData) > 0 Then lpStart = lpEnd: i = j
   Next lpEnd
   If lpStart < nEnd Then idxArray(lpStart) = idxArray(nEnd): idxArray(nEnd) = i
   nEnd = nEnd - 1
  Loop While nEnd > nStart
 End If
Else
'    /* First we pick a partitioning element.  The efficiency of the
'       algorithm demands that we find one that is approximately the median
'       of the values, but also that we select one fast.  We choose the
'       median of the first, middle, and last elements, to avoid bad
'       performance in the face of already sorted data, or data that is made
'       up of multiple sorted runs appended together.  Testing shows that a
'       median-of-three algorithm provides better performance than simply
'       picking the middle element for the latter case. */
'    mid = lo + (size / 2) * width;      /* find middle element */
    nMid = nStart + nSize \ 2
'
'    /* Sort the first, middle, last elements into order */
'    if (__COMPARE(context, lo, mid) > 0) swap(lo, mid, width);
    i = idxArray(nStart): j = idxArray(nMid)
    If obj.Compare(i, j, nUserData) > 0 Then idxArray(nStart) = j: idxArray(nMid) = i
'    if (__COMPARE(context, lo, hi) > 0) swap(lo, hi, width);
    i = idxArray(nStart): j = idxArray(nEnd)
    If obj.Compare(i, j, nUserData) > 0 Then idxArray(nStart) = j: idxArray(nEnd) = i
'    if (__COMPARE(context, mid, hi) > 0) swap(mid, hi, width);
    i = idxArray(nMid): j = idxArray(nEnd)
    If obj.Compare(i, j, nUserData) > 0 Then idxArray(nMid) = j: idxArray(nEnd) = i
'
'    /* We now wish to partition the array into three pieces, one consisting
'       of elements <= partition element, one of elements equal to the
'       partition element, and one of elements > than it.  This is done
'       below; comments indicate conditions established at every step. */
'
'    loguy = lo;
'    higuy = hi;
    lpStart = nStart
    lpEnd = nEnd
'
'    /* Note that higuy decreases and loguy increases on every iteration,
'       so loop must terminate. */
'    for (;;) {
    Do
'        /* lo <= loguy < hi, lo < higuy <= hi,
'           A[i] <= A[mid] for lo <= i <= loguy,
'           A[i] > A[mid] for higuy <= i < hi,
'           A[hi] >= A[mid] */
'
'        /* The doubled loop is to avoid calling comp(mid,mid), since some
'           existing comparison funcs don't work when passed the same
'           value for both pointers. */
        i = idxArray(nMid)
'        if (mid > loguy) {
'            do  {
'                loguy += width;
'            } while (loguy < mid && __COMPARE(context, loguy, mid) <= 0);
'        }
        If nMid > lpStart Then
         Do
          lpStart = lpStart + 1
          j = idxArray(lpStart)
          If lpStart >= nMid Then Exit Do
         Loop While obj.Compare(j, i, nUserData) <= 0
        End If
'        if (mid <= loguy) {
'            do  {
'                loguy += width;
'            } while (loguy <= hi && __COMPARE(context, loguy, mid) <= 0);
'        }
        If nMid <= lpStart Then
         Do
          lpStart = lpStart + 1
          If lpStart > nEnd Then Exit Do
          j = idxArray(lpStart)
         Loop While obj.Compare(j, i, nUserData) <= 0
        End If
'
'        /* lo < loguy <= hi+1, A[i] <= A[mid] for lo <= i < loguy,
'           either loguy > hi or A[loguy] > A[mid] */
'
'        do  {
'            higuy -= width;
'        } while (higuy > mid && __COMPARE(context, higuy, mid) > 0);
        Do
         lpEnd = lpEnd - 1
         k = idxArray(lpEnd)
         If lpEnd <= nMid Then Exit Do
        Loop While obj.Compare(k, i, nUserData) > 0
'
'        /* lo <= higuy < hi, A[i] > A[mid] for higuy < i < hi,
'           either higuy == lo or A[higuy] <= A[mid] */
'
'        if (higuy < loguy)
'            break;
        If lpEnd < lpStart Then Exit Do
'
'        /* if loguy > hi or higuy == lo, then we would have exited, so
'           A[loguy] > A[mid], A[higuy] <= A[mid],
'           loguy <= hi, higuy > lo */
'
'        swap(loguy, higuy, width);
        If lpEnd > lpStart Then idxArray(lpStart) = k: idxArray(lpEnd) = j
'
'        /* If the partition element was moved, follow it.  Only need
'           to check for mid == higuy, since before the swap,
'           A[loguy] > A[mid] implies loguy != mid. */
'
'        if (mid == higuy)
'            mid = loguy;
        If nMid = lpEnd Then nMid = lpStart
'
'        /* A[loguy] <= A[mid], A[higuy] > A[mid]; so condition at top
'           of loop is re-established */
'    }
    Loop
'
'    /*     A[i] <= A[mid] for lo <= i < loguy,
'           A[i] > A[mid] for higuy < i < hi,
'           A[hi] >= A[mid]
'           higuy < loguy
'       implying:
'           higuy == loguy-1
'           or higuy == hi - 1, loguy == hi + 1, A[hi] == A[mid] */
'
'    /* Find adjacent elements equal to the partition element.  The
'       doubled loop is to avoid calling comp(mid,mid), since some
'       existing comparison funcs don't work when passed the same value
'       for both pointers. */
'
'    higuy += width;
    lpEnd = lpEnd + 1
'    if (mid < higuy) {
'        do  {
'            higuy -= width;
'        } while (higuy > mid && __COMPARE(context, higuy, mid) == 0);
'    }
    i = idxArray(nMid)
    If nMid < lpEnd Then
     Do
      lpEnd = lpEnd - 1
      If lpEnd <= nMid Then Exit Do
     Loop While obj.Compare(idxArray(lpEnd), i, nUserData) = 0
    End If
'    if (mid >= higuy) {
'        do  {
'            higuy -= width;
'        } while (higuy > lo && __COMPARE(context, higuy, mid) == 0);
'    }
    If nMid >= lpEnd Then
     Do
      lpEnd = lpEnd - 1
      If lpEnd <= nStart Then Exit Do
     Loop While obj.Compare(idxArray(lpEnd), i, nUserData) = 0
    End If
'
'    /* OK, now we have the following:
'          higuy < loguy
'          lo <= higuy <= hi
'          A[i]  <= A[mid] for lo <= i <= higuy
'          A[i]  == A[mid] for higuy < i < loguy
'          A[i]  >  A[mid] for loguy <= i < hi
'          A[hi] >= A[mid] */
'
'    /* We've finished the partition, now we want to sort the subarrays
'       [lo, higuy] and [loguy, hi].
'       We do the smaller one first to minimize stack usage.
'       We only sort arrays of length 2 or more.*/
'
'    if ( higuy - lo >= hi - loguy ) {
    If lpEnd - nStart >= nEnd - lpStart Then
'        if (lo < higuy) {
'            lostk[stkptr] = lo;
'            histk[stkptr] = higuy;
'            ++stkptr;
'        }                           /* save big recursion for later */
        If nStart < lpEnd Then
         nStartStack(nStack) = nStart
         nEndStack(nStack) = lpEnd
         nStack = nStack + 1
        End If
'        if (loguy < hi) {
'            lo = loguy;
'            goto recurse;           /* do small recursion */
'        }
        If lpStart < nEnd Then
         nStart = lpStart
         GoTo Recurse
        End If
'    }
    Else
'    else {
'        if (loguy < hi) {
'            lostk[stkptr] = loguy;
'            histk[stkptr] = hi;
'            ++stkptr;               /* save big recursion for later */
'        }
        If lpStart < nEnd Then
         nStartStack(nStack) = lpStart
         nEndStack(nStack) = nEnd
         nStack = nStack + 1
        End If
'
'        if (lo < higuy) {
'            hi = higuy;
'            goto recurse;           /* do small recursion */
'        }
        If nStart < lpEnd Then
         nEnd = lpEnd
         GoTo Recurse
        End If
'    }
    End If
End If
'/* We have sorted the array, except for any pending sorts on the stack.
'   Check if there are any, and do them. */
nStack = nStack - 1
If nStack >= 0 Then
 nStart = nStartStack(nStack)
 nEnd = nEndStack(nStack)
 GoTo Recurse '/* pop subarray from stack */
End If
'else
'    return;                 /* all subarrays done */
'////////////////////////////////
#End If
End Sub

#If UseMSVCRT Then

Private Sub Class_Initialize()
Dim s As String
'///
m_hMod = LoadLibrary("msvcrt.dll")
m_lpFunc = GetProcAddress(m_hMod, "qsort")
'///
s = "89 E0 E8 00 00 00 00 83 04 24 15 6A 04 FF 70 08" + _
"FF 70 04 FF 50 0C 83 C4 10 C2 10 00 6A 00 89 E0" + _
"8B 15 ObjPtr 50 FF 35 UserData 8B 48 0C" + _
"8B 40 08 FF 31 FF 30 8B 0A 52 FF 51 1C 58 C3"
s = Replace(s, "ObjPtr", ReverseHex(VarPtr(m_lpObjPtr)))
s = Replace(s, "UserData", ReverseHex(VarPtr(m_nUserData)))
CodeFromString s, m_bCode
End Sub

Private Sub Class_Terminate()
FreeLibrary m_hMod
End Sub

Private Sub CodeFromString(ByVal s As String, ByRef b() As Byte)
Dim m As Long, i As Long
s = Replace(s, " ", "")
s = Replace(s, ",", "")
m = Len(s) \ 2
For i = 0 To m - 1
 b(i) = Val("&H" + Mid(s, i + i + 1, 2))
Next i
End Sub

Private Function ReverseHex(ByVal n As Long) As String
Dim s As String
s = Right("00000000" + Hex(n), 8)
ReverseHex = Mid(s, 7, 2) + Mid(s, 5, 2) + Mid(s, 3, 2) + Mid(s, 1, 2)
End Function

#End If

Friend Sub HeapSort(idxArray() As Long, ByVal nStart As Long, ByVal nEnd As Long, Optional ByVal obj As ISort2, Optional ByVal nUserData As Long)
Dim i As Long, j As Long
Dim nCurrent As Long, nParent As Long, nCurrent2 As Long
Dim nTemp As Long
'///check
If nEnd - nStart <= 0 Then Exit Sub
If obj Is Nothing Then Set obj = Me
'///
nStart = nStart - 1
nEnd = nEnd - nStart
'build max heap
For i = 2 To nEnd
 nTemp = idxArray(nStart + i)
 nCurrent = i
 Do While nCurrent > 1
  nParent = nCurrent \ 2&
  j = idxArray(nStart + nParent)
  If obj.Compare(nTemp, j, nUserData) > 0 Then idxArray(nStart + nCurrent) = j _
  Else Exit Do
  nCurrent = nParent
 Loop
 If nCurrent < i Then idxArray(nStart + nCurrent) = nTemp
Next i
'sort
For i = nEnd To 2 Step -1
 nTemp = idxArray(nStart + i)
 idxArray(nStart + i) = idxArray(nStart + 1)
 nParent = 1
 Do
  nCurrent = nParent + nParent
  If nCurrent >= i Then Exit Do
  nCurrent2 = nCurrent + 1
  j = idxArray(nStart + nCurrent)
  If nCurrent2 >= i Then
   If obj.Compare(j, nTemp, nUserData) > 0 Then
    idxArray(nStart + nParent) = j
    nParent = nCurrent
   End If
   Exit Do
  ElseIf obj.Compare(j, idxArray(nStart + nCurrent2), nUserData) > 0 Then
   If obj.Compare(j, nTemp, nUserData) > 0 Then
    idxArray(nStart + nParent) = j
    nParent = nCurrent
   Else
    Exit Do
   End If
  Else
   j = idxArray(nStart + nCurrent2)
   If obj.Compare(j, nTemp, nUserData) > 0 Then
    idxArray(nStart + nParent) = j
    nParent = nCurrent2
   Else
    Exit Do
   End If
  End If
 Loop
 idxArray(nStart + nParent) = nTemp
Next i
End Sub

'the only stable sort algorithm :)
Friend Sub MergeSort(idxArray() As Long, ByVal nStart As Long, ByVal nEnd As Long, Optional ByVal obj As ISort2, Optional ByVal nUserData As Long)
Dim i As Long, j As Long, k As Long, m As Long
Dim n As Long, n2 As Long
Dim lpArray0 As Long, lpArray1 As Long, lpArray1_0 As Long, lpArrayAux As Long
Dim aux() As Long
'///
If obj Is Nothing Then Set obj = Me
'///
nEnd = nEnd - nStart + 1
If nEnd <= 1 Then
 Exit Sub
ElseIf nEnd = 2 Then
 j = idxArray(nStart)
 k = idxArray(nStart + 1)
 If obj.Compare(j, k, nUserData) > 0 Then
  idxArray(nStart) = k
  idxArray(nStart + 1) = j
 End If
 Exit Sub
End If
'//calc additional size
i = 1
Do
 If nEnd - i <= i Then
  m = nEnd - i
  Exit Do
 End If
 i = i + i
Loop
If m < i Then m = i
ReDim aux(m - 1)
'//
For i = 0 To nEnd - 2 Step 2
 j = idxArray(nStart + i)
 k = idxArray(nStart + i + 1)
 If obj.Compare(j, k, nUserData) > 0 Then
  idxArray(nStart + i) = k
  idxArray(nStart + i + 1) = j
 End If
Next i
'//
n = 2
Do While n < nEnd
 For i = 0 To nEnd - n - 1 Step n + n
  n2 = nEnd - i - n
  If n2 > n Then n2 = n
  lpArray1_0 = nStart + i
  lpArray1 = lpArray1_0 + n - 1
  lpArrayAux = n2 - 1
  lpArray0 = lpArray1 + n2
  '//copy second half
  For j = 0 To n2 - 1
   aux(j) = idxArray(lpArray1 + 1 + j)
  Next j
  '//merge
  Do While lpArray1 >= lpArray1_0 And lpArrayAux >= 0
   j = idxArray(lpArray1)
   k = aux(lpArrayAux)
   If obj.Compare(j, k, nUserData) > 0 Then
    idxArray(lpArray0) = j
    lpArray1 = lpArray1 - 1
   Else
    idxArray(lpArray0) = k
    lpArrayAux = lpArrayAux - 1
   End If
   lpArray0 = lpArray0 - 1
  Loop
  '//
  Do While lpArray1 >= lpArray1_0
   idxArray(lpArray0) = idxArray(lpArray1)
   lpArray0 = lpArray0 - 1
   lpArray1 = lpArray1 - 1
  Loop
  Do While lpArrayAux >= 0
   idxArray(lpArray0) = aux(lpArrayAux)
   lpArray0 = lpArray0 - 1
   lpArrayAux = lpArrayAux - 1
  Loop
 Next i
 n = n + n
Loop
'//over
End Sub

