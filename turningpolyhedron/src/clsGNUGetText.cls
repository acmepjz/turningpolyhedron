VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsGNUGetText"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'////////
'A simple and buggy (case insensitive) implementation of GNU GetText
'This file is public domain.
'////////

'The format of the generated MO files is best described by a picture, which appears below.
'
'The first two words serve the identification of the file. The magic number will always signal GNU MO files.
'The number is stored in the byte order of the generating machine,
'so the magic number really is two numbers: 0x950412de and 0xde120495.
'The second word describes the current revision of the file format. For now the revision is 0.
'This might change in future versions, and ensures that the readers of MO files can distinguish new formats from old ones,
'so that both can be handled correctly. The version is kept separate from the magic number,
'instead of using different magic numbers for different formats, mainly because /etc/magic is not updated often.
'It might be better to have magic separated from internal format version identification.
'
'Follow a number of pointers to later tables in the file, allowing for the extension of the prefix part of MO files
'without having to recompile programs reading them. This might become useful for later inserting a few flag bits,
'indication about the charset used, new tables, or other things.
'
'Then, at offset O and offset T in the picture, two tables of string descriptors can be found. In both tables,
'each string descriptor uses two 32 bits integers, one for the string length, another for the offset of the string
'in the MO file, counting in bytes from the start of the file. The first table contains descriptors for the original strings,
'and is sorted so the original strings are in increasing lexicographical order. The second table contains descriptors for the
'translated strings, and is parallel to the first table: to find the corresponding translation one has to access the array
'slot in the second array with the same index.
'
'Having the original strings sorted enables the use of simple binary search, for when the MO file does not contain an hashing table,
'or for when it is not practical to use the hashing table provided in the MO file. This also has another advantage,
'as the empty string in a PO file GNU gettext is usually translated into some system information attached to that particular MO file,
'and the empty string necessarily becomes the first in both the original and translated tables, making the system information very easy to find.
'
'The size S of the hash table can be zero. In this case, the hash table itself is not contained in the MO file.
'Some people might prefer this because a precomputed hashing table takes disk space, and does not win that much speed.
'The hash table contains indices to the sorted array of strings in the MO file. Conflict resolution is done by double hashing.
'The precise hashing algorithm used is fairly dependent on GNU gettext code, and is not documented here.
'
'As for the strings themselves, they follow the hash file, and each is terminated with a <NUL>, and this <NUL> is not counted
'in the length which appears in the string descriptor. The msgfmt program has an option selecting the alignment for MO file strings.
'With this option, each string is separately aligned so it starts at an offset which is a multiple of the alignment value.
'On some RISC machines, a correct alignment will speed things up.
'
'Contexts are stored by storing the concatenation of the context, a <EOT> byte, and the original string, instead of the original string.
'
'Plural forms are stored by letting the plural of the original string follow the singular of the original string,
'separated through a <NUL> byte. The length which appears in the string descriptor includes both. However,
'only the singular of the original string takes part in the hash table lookup. The plural variants of the
'translation are all stored consecutively, separated through a <NUL> byte. Here also, the length in the string descriptor
'includes all of them.
'
'Nothing prevents a MO file from having embedded <NUL>s in strings. However, the program interface currently used
'already presumes that strings are <NUL> terminated, so embedded <NUL>s are somewhat useless. But the MO file format
'is general enough so other interfaces would be later possible, if for example, we ever want to implement wide characters
'right in MO files, where <NUL> bytes may accidentally appear. (No, we don't want to have wide characters in MO files.
'They would make the file unnecessarily large, and the ¡®wchar_t¡¯ type being platform dependent, MO files would be platform
'dependent as well.)
'
'This particular issue has been strongly debated in the GNU gettext development forum, and it is expectable that MO file format
'will evolve or change over time. It is even possible that many formats may later be supported concurrently. But surely,
'we have to start somewhere, and the MO file format described here is a good start. Nothing is cast in concrete,
'and the format may later evolve fairly easily, so we should feel comfortable with the current approach.
'
'             byte
'                  +------------------------------------------+
'               0  | magic number = 0x950412de                |
'                  |                                          |
'               4  | file format revision = 0                 |
'                  |                                          |
'               8  | number of strings                        |  == N
'                  |                                          |
'              12  | offset of table with original strings    |  == O
'                  |                                          |
'              16  | offset of table with translation strings |  == T
'                  |                                          |
'              20  | size of hashing table                    |  == S
'                  |                                          |
'              24  | offset of hashing table                  |  == H
'                  |                                          |
'                  .                                          .
'                  .    (possibly more entries later)         .
'                  .                                          .
'                  |                                          |
'               O  | length & offset 0th string  ----------------.
'           O + 8  | length & offset 1st string  ------------------.
'                   ...                                    ...   | |
'     O + ((N-1)*8)| length & offset (N-1)th string           |  | |
'                  |                                          |  | |
'               T  | length & offset 0th translation  ---------------.
'           T + 8  | length & offset 1st translation  -----------------.
'                   ...                                    ...   | | | |
'     T + ((N-1)*8)| length & offset (N-1)th translation      |  | | | |
'                  |                                          |  | | | |
'               H  | start hash table                         |  | | | |
'                   ...                                    ...   | | | |
'       H + S * 4  | end hash table                           |  | | | |
'                  |                                          |  | | | |
'                  | NUL terminated 0th string  <----------------' | | |
'                  |                                          |    | | |
'                  | NUL terminated 1st string  <------------------' | |
'                  |                                          |      | |
'                   ...                                    ...       | |
'                  |                                          |      | |
'                  | NUL terminated 0th translation  <---------------' |
'                  |                                          |        |
'                  | NUL terminated 1st translation  <-----------------'
'                  |                                          |
'                   ...                                    ...
'                  |                                          |
'                  +------------------------------------------+

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)

Private objString As New Collection

Private Type typeMOFileHeader
 nMagic As Long
 nFileFormatRevision As Long
 nStringCount As Long
 lpOriginalString As Long
 lpTranslatedString As Long
 nHashTableSize As Long
 lpHashTable As Long
End Type

Private Type typeMOString
 nLength As Long
 nOffset As Long
End Type

'///

Private Declare Function GetLocaleInfo Lib "kernel32.dll" Alias "GetLocaleInfoA" (ByVal Locale As Long, ByVal LCType As Long, ByVal lpLCData As String, ByVal cchData As Long) As Long

Private Const LOCALE_SYSTEM_DEFAULT As Long = &H800&
Private Const LOCALE_USER_DEFAULT As Long = &H400&

Private Const LOCALE_SISO639LANGNAME As Long = &H59
Private Const LOCALE_SISO3166CTRYNAME As Long = &H5A

Friend Function GetText(ByRef s As String) As String
On Error Resume Next
Err.Clear
GetText = objString.Item(s)
If Err.Number Then GetText = s
Err.Clear 'add to fix some bugs
End Function

Friend Property Get StringCount() As Long
StringCount = objString.Count
End Property

Friend Property Get StringCollection() As Collection
Set StringCollection = objString
End Property

Friend Property Set StringCollection(ByVal obj As Collection)
Set objString = obj
End Property

Friend Sub Clear()
Set objString = New Collection
End Sub

Friend Function LoadFileWithLocale(ByRef sFileName As String, Optional ByVal Locale As Long) As Boolean
On Error Resume Next
Dim v As Variant, m As Long
Dim s1 As String, s2 As String
Dim i As Long, lps As Long
If Locale = 0 Then Locale = LOCALE_USER_DEFAULT
If Locale = LOCALE_USER_DEFAULT Or Locale = LOCALE_SYSTEM_DEFAULT Then
 '///new:check enviroment vairable
 s1 = Trim(Environ("LANG"))
 If s1 = "" Then s1 = Trim(Environ("LANGUAGE"))
End If
If s1 = "" Then
 s1 = String(1024, vbNullChar)
 GetLocaleInfo Locale, LOCALE_SISO639LANGNAME, s1, 1024&
 s1 = Left(s1, InStr(1, s1, vbNullChar) - 1)
 s2 = String(1024, vbNullChar)
 GetLocaleInfo Locale, LOCALE_SISO3166CTRYNAME, s2, 1024&
 s2 = Left(s2, InStr(1, s2, vbNullChar) - 1)
 If s2 <> "" Then s1 = s1 + "_" + s2
End If
v = Split(Replace(Replace(s1, ";", ":"), ",", ":"), ":")
m = UBound(v)
For i = 0 To m
 s1 = Trim(v(i))
 If s1 <> "" Then
  '///
  s2 = Replace(sFileName, "*", s1)
  Err.Clear
  If Dir(s2, vbReadOnly Or vbHidden Or vbSystem) <> "" Then
   If Err.Number = 0 Then
    If LoadFile(s2) Then
     LoadFileWithLocale = True
     Exit Function
    End If
   End If
  End If
  '///
  lps = InStr(1, s1, ".")
  If lps > 0 Then
   s2 = Left(s1, lps - 1)
   s2 = Replace(sFileName, "*", s2)
   Err.Clear
   If Dir(s2, vbReadOnly Or vbHidden Or vbSystem) <> "" Then
    If Err.Number = 0 Then
     If LoadFile(s2) Then
      LoadFileWithLocale = True
      Exit Function
     End If
    End If
   End If
  End If
  '///
  lps = InStr(1, s1, "@")
  If lps > 0 Then
   s2 = Left(s1, lps - 1)
   s2 = Replace(sFileName, "*", s2)
   Err.Clear
   If Dir(s2, vbReadOnly Or vbHidden Or vbSystem) <> "" Then
    If Err.Number = 0 Then
     If LoadFile(s2) Then
      LoadFileWithLocale = True
      Exit Function
     End If
    End If
   End If
  End If
  '///
  lps = InStr(1, s1, "_")
  If lps > 0 Then
   s2 = Left(s1, lps - 1)
   s2 = Replace(sFileName, "*", s2)
   Err.Clear
   If Dir(s2, vbReadOnly Or vbHidden Or vbSystem) <> "" Then
    If Err.Number = 0 Then
     If LoadFile(s2) Then
      LoadFileWithLocale = True
      Exit Function
     End If
    End If
   End If
  End If
 End If
Next i
End Function

Friend Function LoadFile(ByRef sFileName As String) As Boolean
On Error Resume Next
Dim i As Long
Dim b() As Byte, s1 As String, s2 As String
Dim t As typeMOFileHeader
Dim t1() As typeMOString, t2() As typeMOString
'///
Err.Clear
If Dir(sFileName, vbReadOnly Or vbHidden Or vbSystem) = "" Then Exit Function
If Err.Number Then Exit Function
Open sFileName For Binary As #1
If Err.Number = 0 Then
 Get #1, 1, t
 If t.nMagic = &H950412DE And t.nFileFormatRevision = 0 Then
  Set objString = New Collection
  If t.nStringCount > 0 Then
   ReDim t1(t.nStringCount - 1), t2(t.nStringCount - 1)
   Get #1, t.lpOriginalString + 1, t1
   Get #1, t.lpTranslatedString + 1, t2
   For i = 0 To t.nStringCount - 1
    '///original
    If t1(i).nLength > 0 Then
     ReDim b(t1(i).nLength - 1)
     Get #1, t1(i).nOffset + 1, b
     s1 = UTF8DecodeByteArray(b)
    Else
     s1 = ""
    End If
    '///translated
    If t2(i).nLength > 0 Then
     ReDim b(t2(i).nLength - 1)
     Get #1, t2(i).nOffset + 1, b
     s2 = UTF8DecodeByteArray(b)
    Else
     s2 = ""
    End If
    '///add
    objString.Add s2, s1
   Next i
  End If
  LoadFile = True
 End If
End If
Close
End Function

Private Function UTF8DecodeByteArray(ByRef iUtf() As Byte) As String
  Dim iUnicode() As Integer, n As Long, i As Long, strUnicode As String, lLen As Long
  Dim j As Long
  
  lLen = UBound(iUtf) + 1
  If lLen <= 0 Then Exit Function
  ReDim iUnicode(lLen - 1)
  
  On Error GoTo catch   ' catch index out of range errors caused by illegal utf sequences
  
  For n = 0 To lLen - 1
    If iUtf(n) > &HEF& Then
      GoTo catch
    ElseIf (iUtf(n) And &HF0&) = &HE0& Then   ' 3 byte seq.
      If (iUtf(n + 1) And &HC0&) <> &H80& Or (iUtf(n + 2) And &HC0&) <> &H80& Then GoTo catch
      j = (((iUtf(n) And &HF&) * &H1000&) Or ((iUtf(n + 1) And &H3F&) * &H40&) Or (iUtf(n + 2) And &H3F&))
      If j And &H8000& Then j = j Or &HFFFF0000
      iUnicode(i) = j
      i = i + 1
      n = n + 2
    ElseIf (iUtf(n) And &HE0&) = &HC0& Then   ' 2 byte seq.
      If (iUtf(n + 1) And &HC0&) <> &H80& Then GoTo catch
      iUnicode(i) = (((iUtf(n) And &H1F&) * &H40&) Or (iUtf(n + 1) And &H3F&))
      i = i + 1
      n = n + 1
    Else   ' 1 byte char
      iUnicode(i) = iUtf(n)
      i = i + 1
    End If
  Next
catch:
  If i > 0 Then
    strUnicode = Space$(i)
    CopyMemory ByVal StrPtr(strUnicode), iUnicode(0), i * 2
  End If
  UTF8DecodeByteArray = strUnicode
End Function
