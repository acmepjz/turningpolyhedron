VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsLZSS"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)
Private Declare Function CallWindowProc Lib "user32.dll" Alias "CallWindowProcA" (ByVal lpPrevWndFunc As Long, ByVal hwnd As Long, ByVal msg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long

Private Type abcd
 lp As Long
 lpEnd As Long
End Type

Private Type dcba
 lptext_buf As Long
 lplson As Long
 lprson As Long
 lpdad As Long
End Type

Private buf(65535) As Byte, ff As dcba

#Const UseResource = True
#If UseResource Then
 Private Const ResourceId = 102
#End If

Private a(1356) As Byte
'/////////////////////////////////VC6 Source code (Modified)/////////////////////////////////
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
'
'#define N        4096   /* size of ring buffer */
'#define F          18   /* upper limit for match_length */
'#define THRESHOLD   2   /* encode string into position and length
'                           if match_length is greater than this */
'#define NIL         N   /* index for root of binary search trees */
'
'struct abcd
'{
'    unsigned char* lp;
'    unsigned char* lpEnd;
'};
'
'struct dcba
'{
'    unsigned char* text_buf;
'    int* lson;
'    int* rson;
'    int* dad;
'};
'
'int __forceinline _getc(abcd* f)
'{
'    if(f->lp > f->lpEnd){
'        return EOF;
'    }else{
'        return *(f->lp++);
'    }
'}
'
'void __forceinline _putc(unsigned int i,abcd* f)
'{
'     *(f->lp++)=i;
'}
'
'void __forceinline InitTree(int *rson,int *dad)  /* initialize trees */
'{
'    int  i;
'
'    /* For i = 0 to N - 1, rson[i] and lson[i] will be the right and
'       left children of node i.  These nodes need not be initialized.
'       Also, dad[i] is the parent of node i.  These are initialized to
'       NIL (= N), which stands for 'not used.'
'       For i = 0 to 255, rson[N + i + 1] is the root of the tree
'       for strings that begin with character i.  These are initialized
'       to NIL.  Note there are 256 trees. */
'
'    for (i = N + 1; i <= N + 256; i++) rson[i] = NIL;
'    for (i = 0; i < N; i++) dad[i] = NIL;
'}
'
'void inline InsertNode(int r,unsigned char *text_buf,int *lson,int *rson,int *dad,int *match_position,int *match_length)
'    /* Inserts string of length F, text_buf[r..r+F-1], into one of the
'       trees (text_buf[r]'th tree) and returns the longest-match position
'       and length via the global variables match_position and match_length.
'       If match_length = F, then removes the old node in favor of the new
'       one, because the old one will be deleted sooner.
'       Note r plays double role, as tree node and position in buffer. */
'{
'    int  i, p, cmp;
'    unsigned char  *key;
'
'    cmp = 1;  key = &text_buf[r];  p = N + 1 + key[0];
'    rson[r] = lson[r] = NIL;  *match_length = 0;
'    for ( ; ; ) {
'        if (cmp >= 0) {
'            if (rson[p] != NIL) p = rson[p];
'            else {  rson[p] = r;  dad[r] = p;  return;  }
'        } else {
'            if (lson[p] != NIL) p = lson[p];
'            else {  lson[p] = r;  dad[r] = p;  return;  }
'        }
'        for (i = 1; i < F; i++)
'            if ((cmp = key[i] - text_buf[p + i]) != 0)  break;
'        if (i > *match_length) {
'            *match_position = p;
'            if ((*match_length = i) >= F)  break;
'        }
'    }
'    dad[r] = dad[p];  lson[r] = lson[p];  rson[r] = rson[p];
'    dad[lson[p]] = r;  dad[rson[p]] = r;
'    if (rson[dad[p]] == p) rson[dad[p]] = r;
'    else                   lson[dad[p]] = r;
'    dad[p] = NIL;  /* remove p */
'}
'
'void inline DeleteNode(int p,int *lson,int *rson,int *dad)  /* deletes node p from tree */
'{
'    int  q;
'
'    if (dad[p] == NIL) return;  /* not in tree */
'    if (rson[p] == NIL) q = lson[p];
'    else if (lson[p] == NIL) q = rson[p];
'    else {
'        q = lson[p];
'        if (rson[q] != NIL) {
'            do {  q = rson[q];  } while (rson[q] != NIL);
'            rson[dad[q]] = lson[q];  dad[lson[q]] = dad[q];
'            lson[q] = lson[p];  dad[lson[p]] = q;
'        }
'        rson[q] = rson[p];  dad[rson[p]] = q;
'    }
'    dad[q] = dad[p];
'    if (rson[dad[p]] == p) rson[dad[p]] = q;  else lson[dad[p]] = q;
'    dad[p] = NIL;
'}
'
'void WINAPI CompressTest(abcd* infile,abcd* outfile,dcba* buf,int Reserved)
'{
'    unsigned long int
'        textsize = 0,   /* text size counter */
'        codesize = 0;   /* code size counter */
'    unsigned char *text_buf=buf->text_buf;  /* ring buffer of size N,
'            with extra F-1 bytes to facilitate string comparison */
'    int     match_position=0, match_length=0,  /* of longest match.  These are
'            set by the InsertNode() procedure. */
'        *lson=buf->lson, *rson=buf->rson, *dad=buf->dad;  /* left & right children &
'            parents -- These constitute binary search trees. */
'
'    int  i, c, len, r, s, last_match_length, code_buf_ptr;
'    unsigned char  code_buf[17], mask;
'
'    InitTree(rson,dad);  /* initialize trees */
'    code_buf[0] = 0;  /* code_buf[1..16] saves eight units of code, and
'        code_buf[0] works as eight flags, "1" representing that the unit
'        is an unencoded letter (1 byte), "0" a position-and-length pair
'        (2 bytes).  Thus, eight units require at most 16 bytes of code. */
'    code_buf_ptr = mask = 1;
'    s = 0;  r = N - F;
'    for (i = s; i < r; i++) text_buf[i] = '\0';  /* Clear the buffer with
'        any character that will appear often. */
'    for (len = 0; len < F && (c = _getc(infile)) != EOF; len++)
'        text_buf[r + len] = c;  /* Read F bytes into the last F bytes of
'            the buffer */
'    if ((textsize = len) == 0) return;  /* text of size zero */
'    for (i = 1; i <= F; i++) InsertNode(r - i,text_buf,lson,rson,dad,&match_position,&match_length);  /* Insert the F strings,
'        each of which begins with one or more 'space' characters.  Note
'        the order in which these strings are inserted.  This way,
'        degenerate trees will be less likely to occur. */
'    InsertNode(r,text_buf,lson,rson,dad,&match_position,&match_length);  /* Finally, insert the whole string just read.  The
'        global variables match_length and match_position are set. */
'    do {
'        if (match_length > len) match_length = len;  /* match_length
'            may be spuriously long near the end of text. */
'        if (match_length <= THRESHOLD) {
'            match_length = 1;  /* Not long enough match.  Send one byte. */
'            code_buf[0] |= mask;  /* 'send one byte' flag */
'            code_buf[code_buf_ptr++] = text_buf[r];  /* Send uncoded. */
'        } else {
'            code_buf[code_buf_ptr++] = (unsigned char) match_position;
'            code_buf[code_buf_ptr++] = (unsigned char)
'                (((match_position >> 4) & 0xf0)
'              | (match_length - (THRESHOLD + 1)));  /* Send position and
'                    length pair. Note match_length > THRESHOLD. */
'        }
'        if ((mask <<= 1) == 0) {  /* Shift mask left one bit. */
'            for (i = 0; i < code_buf_ptr; i++)  /* Send at most 8 units of */
'                _putc(code_buf[i], outfile);     /* code together */
'            codesize += code_buf_ptr;
'            code_buf[0] = 0;  code_buf_ptr = mask = 1;
'        }
'        last_match_length = match_length;
'        for (i = 0; i < last_match_length &&
'                (c = _getc(infile)) != EOF; i++) {
'            DeleteNode(s,lson,rson,dad);        /* Delete old strings and */
'            text_buf[s] = c;    /* read new bytes */
'            if (s < F - 1) text_buf[s + N] = c;  /* If the position is
'                near the end of buffer, extend the buffer to make
'                string comparison easier. */
'            s = (s + 1) & (N - 1);  r = (r + 1) & (N - 1);
'                /* Since this is a ring buffer, increment the position
'                   modulo N. */
'            InsertNode(r,text_buf,lson,rson,dad,&match_position,&match_length); /* Register the string in text_buf[r..r+F-1] */
'        }
'        textsize += i;
'        while (i++ < last_match_length) {   /* After the end of text, */
'            DeleteNode(s,lson,rson,dad);                    /* no need to read, but */
'            s = (s + 1) & (N - 1);  r = (r + 1) & (N - 1);
'            if (--len) InsertNode(r,text_buf,lson,rson,dad,&match_position,&match_length);      /* buffer may not be empty. */
'        }
'    } while (len > 0);  /* until length of string to be processed is zero */
'    if (code_buf_ptr > 1) {     /* Send remaining code. */
'        for (i = 0; i < code_buf_ptr; i++) _putc(code_buf[i], outfile);
'        codesize += code_buf_ptr;
'    }
'}
'
'void WINAPI DecompressTest(abcd* infile,abcd* outfile,dcba* buf,int Reserved)
'{
'    unsigned long int
'        textsize = 0,   /* text size counter */
'        codesize = 0;   /* code size counter */
'    unsigned char *text_buf=buf->text_buf;  /* ring buffer of size N,
'            with extra F-1 bytes to facilitate string comparison */
'    int     match_position=0, match_length=0,  /* of longest match.  These are
'            set by the InsertNode() procedure. */
'        *lson=buf->lson, *rson=buf->rson, *dad=buf->dad;  /* left & right children &
'            parents -- These constitute binary search trees. */
'
'    int  i, j, k, r, c;
'    unsigned int  flags;
'
'    for (i = 0; i < N - F; i++) text_buf[i] = '\0';
'    r = N - F;  flags = 0;
'    for ( ; ; ) {
'        if (((flags >>= 1) & 256) == 0) {
'            if ((c = _getc(infile)) == EOF) break;
'            flags = c | 0xff00;     /* uses higher byte cleverly */
'        }                           /* to count eight */
'        if (flags & 1) {
'            if ((c = _getc(infile)) == EOF) break;
'            _putc(c, outfile);  text_buf[r++] = c;  r &= (N - 1);
'        } else {
'            if ((i = _getc(infile)) == EOF) break;
'            if ((j = _getc(infile)) == EOF) break;
'            i |= ((j & 0xf0) << 4);  j = (j & 0x0f) + THRESHOLD;
'            for (k = 0; k <= j; k++) {
'                c = text_buf[(i + k) & (N - 1)];
'                _putc(c, outfile);  text_buf[r++] = c;  r &= (N - 1);
'            }
'        }
'    }
'
'}
'/////////////////////////////////  End  of  source  code   /////////////////////////////////

Private Sub Class_Initialize()
#If UseResource Then

Dim b() As Byte
b = LoadResData(ResourceId, "CUSTOM")
CopyMemory a(0), b(0), 1357&

#Else

'VC6 -> asm !!
pSetASM 0, "558BEC83EC488B45105356578B308B48048B58088B400C33D2894DE88945F02055B88DBB04400000B900010000B8001000008955E48955F88955D4F3AB8B7DF08BC8F3ABB9FB03000033C08BFEC6451301F3ABC745FC010000008955DCC745ECEE0F00008955F466AB8B7D088B073B4704771E0FB6084083F9FF890774138B45F4FF45F4837DF4"
pSetASM 135, "12888C30EE0F00007CD88B45F43BC28945D00F84D5010000BFED0F00008D45F8508D45E450FF75F053FF75E85657E8C101000083C41C4F81FFDC0F00007DDE8D45F8508D45E450FF75F053FF75E85668EE0F0000E89B01000083C41C8B45F43945F87E038945F8837DF8027F1F8A45138B4DFC0845B88B45ECFF45FCC745F8010000008A043088"
pSetASM 270, "440DB8EB208B7DFC8B45E48A4DF888443DB880E903C1F80424F0470AC188443DB847897DFCD06513752F33FF397DFC7E138B450C8A543DB88B088811FF00473B7DFC7CED8B45FCC64513010145D48065B800C745FC010000008B4DF88365E00085C9894DD87E788B7D088B073B4704776E0FB6104083FAFF8955CC89077460FF75F08B7DDC53FF"
pSetASM 405, "75E857E8DB0100008A45CC83C41083FF118804377D07888437001000008B4DEC47B8FF0F000023F84123C88D45F8508D45E450897DDCFF75F0894DEC53FF75E85651E89F0000008B4DD883C41CFF45E08B45E03B45D87C888B45E00145D08BD0403BD17D502BC841894DD8FF75F08B7DDC53FF75E857E8680100008B4DEC83C41047B8FF0F0000"
pSetASM 540, "23F84123C8FF4DF4897DDC894DEC74198D45F8508D45E450FF75F053FF75E85651E83900000083C41CFF4DD875B6837DF4000F8F8FFEFFFF837DFC017E1A33C9394DFC7E138B450C8A5C0DB88B10881AFF00413B4DFC7CED5F5E5BC9C21000558BEC83EC0C8B55088B450C8B4D1053568BF2578D3C02C1E6020FB60703CEBB00100000894DF805"
pSetASM 675, "0110000089198B4D1403CEC745FC01000000894DF489198B4D20832100837DFC008B5D147D038B5D108B0C8381F9001000000F848F0000006A018BC159894D088B5D0C03D80FB61C0B0FB60C392BCB894DFC8B4D0875094183F912894D087CE08B5D203B0B7EB68B5D1C83F91289038B5D20890B7CA78B4D188B1C818D3C81891C0E8B75108B5D"
pSetASM 810, "F88B348689338B75148B5DF48B348689338B75108B34868914B18B75148B1C868914998B0FC1E10203F1390675048916EB068B4510891401C70700100000EB098B4D1889148389040E5F5E5BC9C3558BEC51518B45088B4D145356578BF8C1E702BE0010000039340F8D1C0F895DF80F84970000008B55108D04178945108B008945FC3BC68B45"
pSetASM 945, "0C75058B0407EB5E03C78945148B003BC675058B45FCEB4E8B3C823BFE74378BC78B3C823BFE75F78B5D0C8B3C818B1C83891CBA8B7D0C8B1C818B3C87891CB98B7D148B5D0C8B3F893C838B7D148B5DF88B3F8904B98B7D108B3F893C828B7D108B3F8904B98B3B893C818B0B8B7D08C1E10203D1393A75048902EB068B550C89041189335F5E"
pSetASM 1080, "5BC9C3558BEC51518B45105356578B18B9FB03000033C08BFBF3AB836510008B550866AB8B450C895DFCBEEE0F0000D16D10F645110175238B0A3B4A040F87CB0000000FB6394183FFFF890A0F84BC00000081CF00FF0000897D10F6451001742F8B3A3B7A040F87A20000000FB60F4783F9FF894D0C893A0F84900000008B38880FFF00880C1E"
pSetASM 1215, "4681E6FF0F0000EB9F8B0A3B4A0477770FB6398D590183FFFF891A746A3B5A0477650FB60B4383F9FF891A745A8BD983E10F81E3F00000006A00C1E3040BFB8B5DFC83C102897D08894DF859894D0C0F8853FFFFFFEB038B7D0803CF8B3881E1FF0F00000FB60C19880FFF00880C1E8B4D0C4681E6FF0F0000413B4DF8894D0C7ED5E921FFFFFF5F5E5BC9C21000"

#End If
End Sub

Private Sub pSetASM(ByVal n As Long, ByVal s As String)
Dim i As Long
For i = 1 To Len(s) \ 2
 a(n + i - 1) = Val("&H" + Mid(s, i + i - 1, 2))
Next i
End Sub

Public Function CompressData(DataIn() As Byte, DataOut() As Byte) As Long
Dim m As Long
Dim f1 As abcd, f2 As abcd
 'init buffer
 Erase buf
 m = VarPtr(buf(0))
 ff.lptext_buf = m
 ff.lplson = m + &H2000&
 ff.lprson = m + &H6800&
 ff.lpdad = m + &HB000&
 '///
 With f1
  .lp = LBound(DataIn)
  .lpEnd = UBound(DataIn)
  .lp = VarPtr(DataIn(.lp))
  .lpEnd = VarPtr(DataIn(.lpEnd))
  m = (.lpEnd - .lp) * 1.2 + 65536
 End With
 ReDim DataOut(1 To m)
 f2.lp = VarPtr(DataOut(1))
 f2.lpEnd = VarPtr(DataOut(m))
 CallWindowProc VarPtr(a(0)), VarPtr(f1), VarPtr(f2), VarPtr(ff), 0
 m = f2.lp - VarPtr(DataOut(1))
 ReDim Preserve DataOut(1 To m)
 CompressData = m
End Function

Public Function DecompressData(DataIn() As Byte, DataOut() As Byte, ByVal OriginalSize As Long) As Long
Dim m As Long
Dim f1 As abcd, f2 As abcd
 'init buffer
 Erase buf
 m = VarPtr(buf(0))
 ff.lptext_buf = m
 ff.lplson = m + &H2000&
 ff.lprson = m + &H6800&
 ff.lpdad = m + &HB000&
 '///
 With f1
  .lp = LBound(DataIn)
  .lpEnd = UBound(DataIn)
  .lp = VarPtr(DataIn(.lp))
  .lpEnd = VarPtr(DataIn(.lpEnd))
 End With
 m = OriginalSize + 65536
 ReDim DataOut(1 To m)
 f2.lp = VarPtr(DataOut(1))
 f2.lpEnd = VarPtr(DataOut(m))
 CallWindowProc VarPtr(a(1083)), VarPtr(f1), VarPtr(f2), VarPtr(ff), 0
 m = f2.lp - VarPtr(DataOut(1))
 ReDim Preserve DataOut(1 To m)
 DecompressData = m
End Function

