Attribute VB_Name = "mdlLZMA_DLL"
Option Explicit

'////////////////////////////////
'This file is public domain.
'LZMA library, by Igor Pavlov, is public domain.
'////////////////////////////////

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)

'LzmaCompress
'------------
'
'outPropsSize -
'     In:  the pointer to the size of outProps buffer; *outPropsSize = LZMA_PROPS_SIZE = 5.
'     Out: the pointer to the size of written properties in outProps buffer; *outPropsSize = LZMA_PROPS_SIZE = 5.
'
'  LZMA Encoder will use defult values for any parameter, if it is
'  -1  for any from: level, loc, lp, pb, fb, numThreads
'   0  for dictSize
'
'level - compression level: 0 <= level <= 9;
'
'  level dictSize algo  fb
'    0:    16 KB   0    32
'    1:    64 KB   0    32
'    2:   256 KB   0    32
'    3:     1 MB   0    32
'    4:     4 MB   0    32
'    5:    16 MB   1    32
'    6:    32 MB   1    32
'    7+:   64 MB   1    64
'
'  The default value for "level" is 5.
'
'  algo = 0 means fast method
'  algo = 1 means normal method
'
'dictSize - The dictionary size in bytes. The maximum value is
'        128 MB = (1 << 27) bytes for 32-bit version
'          1 GB = (1 << 30) bytes for 64-bit version
'     The default value is 16 MB = (1 << 24) bytes.
'     It 's recommended to use the dictionary that is larger than 4 KB and
'     that can be calculated as (1 << N) or (3 << N) sizes.
'
'lc - The number of literal context bits (high bits of previous literal).
'     It can be in the range from 0 to 8. The default value is 3.
'     Sometimes lc=4 gives the gain for big files.
'
'lp - The number of literal pos bits (low bits of current position for literals).
'     It can be in the range from 0 to 4. The default value is 0.
'     The lp switch is intended for periodical data when the period is equal to 2^lp.
'     For example, for 32-bit (4 bytes) periodical data you can use lp=2. Often it's
'     better to set lc=0, if you change lp switch.
'
'pb - The number of pos bits (low bits of current position).
'     It can be in the range from 0 to 4. The default value is 2.
'     The pb switch is intended for periodical data when the period is equal 2^pb.
'
'fb - Word size (the number of fast bytes).
'     It can be in the range from 5 to 273. The default value is 32.
'     Usually, a big number gives a little bit better compression ratio and
'     slower compression process.
'
'numThreads - The number of thereads. 1 or 2. The default value is 2.
'     Fast mode (algo = 0) can use only 1 thread.
'
'Out:
'  destLen  - processed output size
'Returns:
'  SZ_OK -OK
'  SZ_ERROR_MEM        - Memory allocation error
'  SZ_ERROR_PARAM      - Incorrect paramater
'  SZ_ERROR_OUTPUT_EOF - output buffer overflow
'  SZ_ERROR_THREAD     - errors in multithreading functions (only for Mt version)
'
'MY_STDAPI LzmaCompress(unsigned char *dest, size_t *destLen, const unsigned char *src, size_t srcLen,
'  unsigned char *outProps, size_t *outPropsSize, /* *outPropsSize must be = 5 */
'  int level,      /* 0 <= level <= 9, default = 5 */
'  unsigned dictSize,  /* use (1 << N) or (3 << N). 4 KB < dictSize <= 128 MB default = (1 << 24) */
'  int lc,        /* 0 <= lc <= 8, default = 3  */
'  int lp,        /* 0 <= lp <= 4, default = 0  */
'  int pb,        /* 0 <= pb <= 4, default = 2  */
'  int fb,        /* 5 <= fb <= 273, default = 32 */
'  int numThreads /* 1 or 2, default = 2 */
'  );

Public Declare Function LzmaCompress Lib "LZMA.dll" (ByRef dest As Any, ByRef destLen As Long, ByRef src As Any, ByVal srcLen As Long, _
ByRef outProps As typeLZMApropsEncoded, ByRef outPropsSize As Long, _
Optional ByVal level As Long = -1, _
Optional ByVal dictSize As Long = 0, _
Optional ByVal lc As Long = -1, _
Optional ByVal lp As Long = -1, _
Optional ByVal pb As Long = -1, _
Optional ByVal fb As Long = -1, _
Optional ByVal numThreads As Long = -1) As enumSRes

'LzmaUncompress
'--------------
'In:
'  dest     - output data
'  destLen  - output data size
'  src      - input data
'  srcLen   - input data size
'Out:
'  destLen  - processed output size
'  srcLen   - processed input size
'Returns:
'  SZ_OK -OK
'  SZ_ERROR_DATA        - Data error
'  SZ_ERROR_MEM         - Memory allocation error
'  SZ_ERROR_UNSUPPORTED - Unsupported properties
'  SZ_ERROR_INPUT_EOF   - it needs more bytes in input buffer (src)
'
'MY_STDAPI LzmaUncompress(unsigned char *dest, size_t *destLen, const unsigned char *src, SizeT *srcLen,
'  const unsigned char *props, size_t propsSize);

Public Declare Function LzmaUncompress Lib "LZMA.dll" (ByRef dest As Any, ByRef destLen As Long, ByRef src As Any, ByRef srcLen As Long, _
ByRef props As typeLZMApropsEncoded, ByVal propsSize As Long) As enumSRes

Public Enum enumSRes
 SZ_OK = 0
 SZ_ERROR_DATA
 SZ_ERROR_MEM
 SZ_ERROR_CRC
 SZ_ERROR_UNSUPPORTED
 SZ_ERROR_PARAM
 SZ_ERROR_INPUT_EOF
 SZ_ERROR_OUTPUT_EOF
 SZ_ERROR_READ
 SZ_ERROR_WRITE
 SZ_ERROR_PROGRESS
 SZ_ERROR_FAIL
 SZ_ERROR_THREAD
 SZ_ERROR_ARCHIVE = 16
 SZ_ERROR_NO_ARCHIVE = 17
End Enum

'LZMA compressed file format
'---------------------------
'Offset Size Description
'  0     1   Special LZMA properties (lc,lp, pb in encoded form)
'  1     4   Dictionary size (little endian)
'  5     8   Uncompressed size (little endian). -1 means unknown size
' 13         Compressed Data

Public Type typeLZMApropsEncoded
 Flags As Byte 'pb*45+lp*9+lc
 'dictionay size:no dword align!!!
 dictSize0 As Byte
 dictSize1 As Byte
 dictSize2 As Byte
 dictSize3 As Byte
End Type

Public Function LZMACompress_Simple(TheData() As Byte, TheDataOut() As Byte, ByRef nSize As Long, Optional ByVal nLevel As Long = -1) As Boolean
Dim lps As Long, m As Long
On Error Resume Next
Err.Clear
lps = LBound(TheData)
m = UBound(TheData) - lps + 1
lps = VarPtr(TheData(lps))
On Error GoTo 0
If Err.Number <> 0 Or m <= 0 Then lps = 0
'/////
LZMACompress_Simple = LZMACompress_Simple2(lps, m, TheDataOut, nSize, nLevel)
End Function

Public Function LZMACompress_Simple2(ByVal lpData As Long, ByVal nOldSize As Long, TheDataOut() As Byte, ByRef nSize As Long, Optional ByVal nLevel As Long = -1) As Boolean
Dim p As typeLZMApropsEncoded
Dim ret As Long
If lpData = 0 Or nOldSize <= 0 Then
 nSize = 0
 Erase TheDataOut
 LZMACompress_Simple2 = True
 Exit Function
End If
'/////
nSize = nOldSize + nOldSize \ 16 + 4096&
ReDim TheDataOut(nSize + 4)
ret = LzmaCompress(TheDataOut(5), nSize, ByVal lpData, nOldSize, p, 5, nLevel)
nSize = nSize + 5
ReDim Preserve TheDataOut(nSize - 1)
CopyMemory TheDataOut(0), p, 5
LZMACompress_Simple2 = ret = 0
End Function

Public Function LZMADecompress_Simple(TheData() As Byte, TheDataOut() As Byte, ByVal nSize As Long) As Boolean
Dim lps As Long, m As Long
On Error Resume Next
Err.Clear
lps = LBound(TheData)
m = UBound(TheData) - lps + 1
lps = VarPtr(TheData(lps))
On Error GoTo 0
If Err.Number <> 0 Or m <= 5 Or nSize <= 0 Then lps = 0
'/////
LZMADecompress_Simple = LZMADecompress_Simple2(lps, m, TheDataOut, nSize)
End Function

Public Function LZMADecompress_Simple2(ByVal lpData As Long, ByVal nOldSize As Long, TheDataOut() As Byte, ByVal nSize As Long) As Boolean
Dim p As typeLZMApropsEncoded
Dim ret As Long
If lpData = 0 Or nOldSize <= 5 Or nSize <= 0 Then
 Erase TheDataOut
 LZMADecompress_Simple2 = True
 Exit Function
End If
'/////
CopyMemory p, ByVal lpData, 5
nOldSize = nOldSize - 5
ReDim TheDataOut(nSize - 1)
ret = LzmaUncompress(TheDataOut(0), nSize, ByVal (lpData + 5), nOldSize, p, 5)
LZMADecompress_Simple2 = ret = 0
End Function

