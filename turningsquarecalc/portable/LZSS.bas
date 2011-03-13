'/////////////////////////////////FreeBasic src from VC6 Source code (Modified)/////////////////////////////////
'
'/**************************************************************
'    LZSS.C -- A Data Compression Program
'    (tab = 4 spaces)
'***************************************************************
'    4/6/1989 Haruhiko Okumura
'    Use, distribute, and modify this program freely.
'    Please send me your improved versions.
'        PC-VAN      SCIENCE
'        NIFTY-Serve PAF01022
'        CompuServe 74050, 1022
'**************************************************************/

#include once "main.bi"
#include once "LZSS.bi"

Private Const N As Long = 4096   '/* size of ring buffer */
Private Const F As Long = 18   '/* upper limit for match_length */
Private Const THRESHOLD As Long = 2   '/* encode string into position and length if match_length is greater than this */
Private Const NIL As Long = N   '/* index for root of binary search trees */

'struct abcd
'{
'    unsigned char* lp:
'    unsigned char* lpEnd:
'}:

dim shared as UByte text_buf(0 to N + F - 2)

dim shared as long lson(0 to N), rson(0 to N + 256), dad(0 to N)

Private Function _getc(ByRef ff As typeLZSSMemFile) As Long
    Dim ret As UByte
    If ff.lp > ff.lpEnd Then
        Return -1
    Else
        ret = *(ff.lp)
        ff.lp += 1
        Return ret
    End If
End Function

Private Sub _putc(ByVal i As Long, ByRef ff As typeLZSSMemFile)
    *(ff.lp) = i
    ff.lp += 1
End Sub

Private Sub InitTree()
    Dim i As Long

    '/* For i = 0 to N - 1, rson[i] and lson[i] will be the right and
    '   left children of node i.  These nodes need not be initialized.
    '   Also, dad[i] is the parent of node i.  These are initialized to
    '   NIL (= N), which stands for 'not used.'
    '   For i = 0 to 255, rson[N + i + 1] is the root of the tree
    '   for strings that begin with character i.  These are initialized
    '   to NIL.  Note there are 256 trees. */

    For i = N + 1 To N + 256
        rson(i) = NIL
    Next i
    For i = 0 To N - 1
        dad(i) = NIL
    Next i
End Sub

Private Sub InsertNode(ByVal r As Long, ByRef match_position As Long, ByRef match_length As Long)
    '/* Inserts string of length F, text_buf[r..r+F-1], into one of the
    '   trees (text_buf[r]'th tree) and returns the longest-match position
    '   and length via the global variables match_position and match_length.
    '   If match_length = F, then removes the old node in favor of the new
    '   one, because the old one will be deleted sooner.
    '   Note r plays double role, as tree node and position in buffer. */
    dim as long  i, p, cmp 
    dim key as ubyte ptr

    cmp = 1:  key = @text_buf(r):  p = N + 1 + key[0]
    rson(r) = NIL: lson(r) = NIL : match_length = 0
    Do
        If cmp >= 0 Then
            If rson(p) <> NIL Then
                p = rson(p)
            Else
                rson(p) = r
                dad(r) = p
                Return
            End If
        Else
            If lson(p) <> NIL Then
                p = lson(p)
            Else
                lson(p) = r
                dad(r) = p
                Return
            End If
        End If
        For i = 1 To F - 1
            cmp = key[i] - text_buf(p + i)
            If cmp <> 0 Then Exit For
        Next i
        If i > match_length Then
            match_position = p
            match_length = i
            If i >= F Then Exit Do
        End If
    Loop
    dad(r) = dad(p) : lson(r) = lson(p) : rson(r) = rson(p)
    dad(lson(p)) = r : dad(rson(p)) = r
    If rson(dad(p)) = p Then rson(dad(p)) = r _
    Else lson(dad(p)) = r
    dad(p) = NIL ':  /* remove p */
End Sub

Private Sub DeleteNode(ByVal p As Long)
    '/* deletes node p from tree */
    Dim q As Long

    If dad(p) = NIL Then Return '  /* not in tree */
    If rson(p) = NIL Then
        q = lson(p)
    ElseIf lson(p) = NIL Then
        q = rson(p)
    Else
        q = lson(p)
        If rson(q) <> NIL Then
            Do
                q = rson(q)
            Loop While rson(q) <> NIL
            rson(dad(q)) = lson(q) : dad(lson(q)) = dad(q)
            lson(q) = lson(p) : dad(lson(p)) = q
        End If
        rson(q) = rson(p) : dad(rson(p)) = q
    end if
    dad(q) = dad(p)
    If rson(dad(p)) = p Then rson(dad(p)) = q Else lson(dad(p)) = q
    dad(p) = NIL
End Sub

Public Sub CompressTest(ByRef infile As typeLZSSMemFile, ByRef outfile As typeLZSSMemFile)
    dim as ulong         textsize = 0,  codesize = 0 
    dim as long     match_position=0, match_length=0 

    dim as long  i, c, _len, r, s, last_match_length, code_buf_ptr
    dim as  byte  code_buf(17-1), mask

    InitTree() ':  /* initialize trees */
    code_buf(0) = 0 ':  /* code_buf[1..16] saves eight units of code, and
    '    code_buf[0] works as eight flags, "1" representing that the unit
    '    is an unencoded letter (1 byte), "0" a position-and-length pair
    '    (2 bytes).  Thus, eight units require at most 16 bytes of code. */
    code_buf_ptr = 1
    mask = 1
    s = 0
    r = N - F
    For i = s To r - 1
        text_buf(i) = 0 '  /* Clear the buffer with
        'any character that will appear often. */
    Next i

    _len = 0
    Do
        If _len >= F Then Exit Do
        c = _getc(infile)
        If c = -1 Then Exit Do
        text_buf(r + _len) = c  '/* Read F bytes into the last F bytes of
        'the buffer */
        _len += 1
    Loop
    textsize = _len
    If _len = 0 Then Return ':  '/* text of size zero */
    For i = 1 To F
        InsertNode(r - i, match_position, match_length)   '/* Insert the F strings,
        '        each of which begins with one or more 'space' characters.  Note
        '        the order in which these strings are inserted.  This way,
        '        degenerate trees will be less likely to occur. */
    Next i
    InsertNode(r, match_position, match_length) ':  /* Finally, insert the whole string just read.  The
    'global variables match_length and match_position are set. */
    Do
        If (match_length > _len) Then match_length = _len ':  /* match_length
        '            may be spuriously long near the end of text. */
        If (match_length <= THRESHOLD) Then
            match_length = 1 ':  /* Not long enough match.  Send one byte. */
            code_buf(0) or= mask ':  /* 'send one byte' flag */
            code_buf(code_buf_ptr) = text_buf(r) ':  /* Send uncoded. */
            code_buf_ptr += 1
        Else
            code_buf(code_buf_ptr) = cubyte(match_position)
            code_buf_ptr += 1
            code_buf(code_buf_ptr) = cubyte(((match_position shr 4) And &HF0) Or (match_length - (THRESHOLD + 1)))
            ':  /* Send position and
            'length pair. Note match_length > THRESHOLD. */
            code_buf_ptr += 1
        End If
        mask shl= 1
        if mask=0 then '/* Shift mask left one bit. */
            for  i = 0 to   code_buf_ptr-1 ' /* Send at most 8 units of */
                _putc(code_buf(i), outfile) '    /* code together */
            next i
            codesize += code_buf_ptr
            code_buf(0) = 0
            code_buf_ptr =1
            mask = 1
        end if
        last_match_length = match_length
        i=0
        do
            if i >= last_match_length then exit do
            c = _getc(infile) 
            if c=-1 then exit do  
            DeleteNode(s) ':        /* Delete old strings and */
            text_buf(s) = c ':    /* read new bytes */
            if (s < F - 1)  then text_buf(s + N) = c ':  /* If the position is
            '    near the end of buffer, extend the buffer to make
            '    string comparison easier. */
            s = (s + 1) and (N - 1):  r = (r + 1) and (N - 1):
            '    /* Since this is a ring buffer, increment the position
            '       modulo N. */
            InsertNode(r,match_position,match_length)': /* Register the string in text_buf[r..r+F-1] */
            i+=1
        loop
        textsize += i
        do while (i < last_match_length) '{   /* After the end of text, */
            i+=1
            DeleteNode(s) '                   ;/* no need to read, but */
            s = (s + 1) and (N - 1):  r = (r + 1) and (N - 1):
            _len=_len-1
            if _len<>0 then InsertNode(r,match_position,match_length) ':      '/* buffer may not be empty. */
        loop
    loop while (_len > 0) ':  /* until length of string to be processed is zero */
    If code_buf_ptr > 1 Then '     /* Send remaining code. */
        For i = 0 To code_buf_ptr - 1
            _putc(code_buf(i), outfile)
        Next i
        codesize += code_buf_ptr
    End If
End Sub

public sub DecompressTest(ByRef infile As typeLZSSMemFile, ByRef outfile As typeLZSSMemFile)

    dim as long  i, j, k, r, c
    dim as unsigned long  flags=0

    for  i = 0 to   N +F-2
     text_buf(i) = 0
    next i
    r = N - F:  flags = 0
    do
        flags shr= 1
        if ((flags and 256) = 0) then
            c = _getc(infile)
            if (c = -1) then exit do
            flags = c or &Hff00':     '/* uses higher byte cleverly */
        end if                           '/* to count eight */
        if  flags and 1 then
            c = _getc(infile)
            if (c = -1) then exit do
            _putc(c, outfile):  text_buf(r) = c:  r =(r+1) and (N - 1)
        else
            i = _getc(infile)
            if (i = -1) then exit do
            j = _getc(infile)
            if (j = -1) then exit do
            i or= ((j and &Hf0) shl 4):  j = (j and &H0f) + THRESHOLD
            for  k = 0 to j
                c = text_buf((i + k) and (N - 1))
                _putc(c, outfile):  text_buf(r) = c:  r =(r+1) and (N - 1)
            next k
        end if
    loop

End Sub

'/////////////////////////////////  End  of  source  code   /////////////////////////////////

Public Function CompressData(DataIn() As Byte, DataOut() As Byte) As Long
Dim m As Long
Dim f1 As typeLZSSMemFile, f2 As typeLZSSMemFile
dim i as long,j as long
 '///
 With f1
  i = LBound(DataIn)
  j = UBound(DataIn)
  .lp = VarPtr(DataIn(i))
  .lpEnd = VarPtr(DataIn(j))
  m = (j-i) * 1.2 + 65536
 End With
 ReDim DataOut(1 To m)
 f2.lp = VarPtr(DataOut(1))
 f2.lpEnd = VarPtr(DataOut(m))
 CompressTest f1,f2
 m = CLng(f2.lp) - CLng(@DataOut(1))
 ReDim Preserve DataOut(1 To m)
 CompressData = m
End Function

Public Function DecompressData(DataIn() As Byte, DataOut() As Byte, ByVal OriginalSize As Long) As Long
Dim m As Long
Dim f1 As typeLZSSMemFile, f2 As typeLZSSMemFile
dim i as long,j as long
 '///
 With f1
  i = LBound(DataIn)
  j = UBound(DataIn)
  .lp = VarPtr(DataIn(i))
  .lpEnd = VarPtr(DataIn(j))
 End With
 m = OriginalSize + 65536
 ReDim DataOut(1 To m)
 f2.lp = VarPtr(DataOut(1))
 f2.lpEnd = VarPtr(DataOut(m))
 DecompressTest f1,f2
 m = CLng(f2.lp) - CLng(@DataOut(1))
 ReDim Preserve DataOut(1 To m)
 DecompressData = m
End Function
