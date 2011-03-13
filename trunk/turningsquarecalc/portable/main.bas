#include once "main.bi"
#include once "frmMain.bi"
#include once "crt/stdlib.bi"
#include once "crt/string.bi"

Dim Shared App as _App
Dim Shared objText as clsGNUGetText
Dim Shared m_objFont(3) As TTF_Font ptr

#ifdef __FB_WIN32__

Declare Function GetModuleFileName Lib "kernel32" Alias "GetModuleFileNameA" (ByVal hModule As Long, ByVal lpFileName As String, ByVal nSize As Long) As Long

Declare Function GetWindowsDirectory Lib "kernel32" Alias "GetWindowsDirectoryA" (ByVal lpBuffer As String, ByVal nSize As Long) As Long

Declare Function GetStockObject Lib "gdi32" Alias "GetStockObject" (ByVal nIndex As Long) As Long
Const DEFAULT_GUI_FONT As Long = 17

Declare Function GetObject Lib "gdi32" Alias "GetObjectA" (ByVal hObject As Long, ByVal nCount As Long, ByRef lpObject As Any) As Long
Type LOGFONT
    lfHeight As Long
    lfWidth As Long
    lfEscapement As Long
    lfOrientation As Long
    lfWeight As Long
    lfItalic As Byte
    lfUnderline As Byte
    lfStrikeOut As Byte
    lfCharSet As Byte
    lfOutPrecision As Byte
    lfClipPrecision As Byte
    lfQuality As Byte
    lfPitchAndFamily As Byte
    lfFaceName(31) As Byte
End Type

Declare Function RegOpenKeyEx Lib "advapi32" Alias "RegOpenKeyExA" (ByVal hKey As Long, ByVal lpSubKey As String, ByVal ulOptions As Long, ByVal samDesired As Long, ByRef phkResult As Long) As Long
Declare Function RegCloseKey Lib "advapi32" Alias "RegCloseKey" (ByVal hKey As Long) As Long
Declare Function RegEnumValue Lib "advapi32" Alias "RegEnumValueA" (ByVal hKey As Long, ByVal dwIndex As Long, ByVal lpValueName As String, ByRef lpcbValueName As Long, ByVal lpReserved As Long, ByRef lpType As Long, ByVal lpData As String, ByRef lpcbData As Long) As Long
Const HKEY_LOCAL_MACHINE As Long = &H80000002
Const KEY_READ As Long = &H20019

Const ERROR_MORE_DATA As Long = 234

#else

#undef True
#undef False

#include once "crt/unistd.bi"
#include once "gtk/gtk.bi"

Type FcFontSet
    As Long nfont, sfont
    As Any Ptr Ptr fonts
End Type

Declare Function FcPatternCreate cdecl Alias "FcPatternCreate" () As Any Ptr
Declare Sub FcPatternDestroy cdecl Alias "FcPatternDestroy" (Byval obj As Any Ptr)

Declare Function FcPatternAddString cdecl Alias "FcPatternAddString" (Byval obj As Any Ptr, Byval sObject As Any Ptr, Byval s As Any Ptr) As Long
Declare Function FcPatternGetString cdecl Alias "FcPatternGetString" (Byval obj As Any Ptr, Byval sObject As Any Ptr, _
  ByVal nIndex As Long, Byval s As Any Ptr Ptr) As Long

Declare Function FcConfigGetFonts cdecl Alias "FcConfigGetFonts" (ByVal _config As Any Ptr, ByVal _set As Long) As FcFontSet Ptr

Declare Function FcFontSetList cdecl Alias "FcFontSetList" (ByVal _config As Any Ptr, ByVal _sets As FcFontSet Ptr Ptr, _
  ByVal nsets As Long, ByVal _pattern As Any Ptr, ByVal object_set As Any Ptr) As Any Ptr
Declare Sub FcFontSetDestroy cdecl Alias "FcFontSetDestroy" (Byval obj As FcFontSet Ptr)
Declare Sub FcFontSetPrint cdecl Alias "FcFontSetPrint" (Byval _set As FcFontSet Ptr)

#endif

function Replace(Source As String, ToReplace As String, ReplaceWith As String, Count As Long = -1 ) as string
       
        Dim As Long x, p, m, m2
        dim s as string=Source
        m = Len(ToReplace)
        m2= Len(ReplaceWith)-1
        if m<=0 then return s
        If Count < 1 Then
                Do
                        x = Instr(x + 1, s,ToReplace)
                        If x <> 0 Then
                                s=left(s,x-1)+ReplaceWith+mid(s,x+m)
                                x += m2
                        Else
                                Exit Do
                        Endif
                Loop
        Else
                Do
                        x = Instr(x + 1, s,ToReplace)
                        If x <> 0 Then
                                s=left(s,x-1)+ReplaceWith+mid(s,x+m)
                                p += 1
                                x += m2
                        Else
                                Exit Do
                        Endif
                Loop Until p = Count
        Endif
        return s
        
End function

sub Split(Expression as String,Delimiter as String,ret() as String)
 dim as long i,iOld,m,n
 m=Len(Delimiter)
 Erase ret
 if m<=0 then exit sub
 if len(Expression)<=0 then exit sub
 iOld=1
 i=InStr(iOld,Expression,Delimiter)
 do until i=0
  redim preserve ret(0 to n)
  ret(n)=Mid(Expression,iOld,i-iOld)
  n+=1
  iOld=i+m
  i=InStr(iOld,Expression,Delimiter)
 loop
 redim preserve ret(0 to n)
 ret(n)=Mid(Expression,iOld)
end sub

constructor _App
 dim m as long
 _Path=Space(4096)
 #ifdef __FB_WIN32__
 m=GetModuleFileName(NULL,_Path,4096)
 #else
 m=readlink("/proc/self/exe",_Path,4096)
 #endif
 _Path=Left(_Path,m)
 #ifdef __FB_WIN32__
 _Path=Replace(_Path,"/","\")
 m=instrrev(_Path,"\")
 #else
 _Path=Replace(_Path,"\","/")
 m=instrrev(_Path,"/")
 #endif
 if m>0 then
  _ExeName=mid(_Path,m+1)
  _Path=left(_Path,m) 'note: with "\"
 end if
end constructor

function _App.Path() as string
return _Path
end function

function _App.ExeName() as string
return _ExeName
end function

Sub clsSimpleRnd._Randomize(ByRef s As String)
Dim i As Long, j As Long, k As Long
dim s1 as string
For i = 1 To 10
 x(i) = Abs(Sin(i))
Next i
i = 0
s1 = UCase(s)
For j = 1 To Len(s1)
 k = CLng(s1[j-1]) - 65
 If k >= 0 And k < 26 Then
  i = i + 1
  If i > 10 Then Exit For
  x(i) = x(i) + 0.03846 * k + 0.01234
  If x(i) > 1 Then x(i) = x(i) - 1
 End If
Next j
End Sub

Function clsSimpleRnd._Rnd() As Single
Dim i As Long, f As Single
Dim f2 As Single
f2 = 0.5
For i = 1 To 10
 x(i) = 4 * x(i) * (1 - x(i))
 If x(i) > 0.5 Then f = f + f2
 f2 = f2 * 0.5
Next i
Return f
End Function

Function clsSimpleRnd.RndSeed() As String
Dim i As Long, s As String
s=Space(10)
For i = 1 To 10
 s[i-1] = 65 + Int(26 * Rnd())
Next i
Return s
End Function

Function clsSimpleRnd.ValidateRndSeed(ByRef s As String) As String
Dim s1 as string, s2 As String
Dim i As Long, j As Long, k As Long
s1 = UCase(s)
For j = 1 To Len(s1)
 k = CLng(s1[j-1]) - 65
 If k >= 0 And k < 26 Then
  i = i + 1
  If i > 10 Then Exit For
  s2 = s2 + Chr(65 + k)
 End If
Next j
Return s2
End Function

Function _GetDefaultFont() As String
#ifdef __FB_WIN32__
Dim h As Long
Dim t As LOGFONT
Dim i As Long, j As Long, ret As Long
Dim s() As String, m As Long
Dim As String s0, s1, s2, s3
'///
h = GetStockObject(DEFAULT_GUI_FONT)
GetObject h, Len(t), t
s0 = String(32, vbNullChar)
memcpy(strptr(s0), @t.lfFaceName(0), 32&)
i = InStr(1, s0, vbNullChar)
If i > 0 Then s0 = Left(s0, i - 1)
'///
RegOpenKeyEx HKEY_LOCAL_MACHINE, "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts", 0, KEY_READ, h
i = 0
Do
 s1 = String(1024, vbNullChar)
 s2 = String(1024, vbNullChar)
 ret = RegEnumValue(h, i, s1, 1024, 0, 0, s2, 1024)
 If ret <> 0 And ret <> ERROR_MORE_DATA Then Exit Do
 '///
 ret = InStr(1, s1, vbNullChar)
 If ret > 0 Then s1 = Left(s1, ret - 1)
 ret = InStr(1, s2, vbNullChar)
 If ret > 0 Then s2 = Left(s2, ret - 1)
 '///
 ret = InStr(1, s1, "(")
 If ret > 0 Then s1 = Left(s1, ret - 1)
 Split(s1, "&", s())
 m = UBound(s)
 For j = 0 To m
  s1 = Trim(s(j))
  If s0 = s1 Then
   If InStr(1, s2, ":") = 0 Then
    s0 = String(1024, vbNullChar)
    GetWindowsDirectory s0, 1024
    ret = InStr(1, s0, vbNullChar)
    If ret > 0 Then s0 = Left(s0, ret - 1)
    s2 = s0 + "\Fonts\" + s2
   End If
   s3 = s2
   Exit Do
  End If
 Next j
 '///
 i = i + 1
Loop
RegCloseKey h
'///
if s3 = "" then
 'no any fonts!!! use built-in font
 objText.Clear()
 s2 = App.Path + "data\vera_sans.ttf"
end if
Return s3
#else
'///test
Dim _value As gchar ptr
Dim As Long m
Dim As String s,sLang,s2
g_object_get(G_OBJECT(gtk_settings_get_default()),strptr("gtk-font-name"),@_value,NULL)
m=strlen(_value)
s=Space(m)
memcpy(strptr(s),_value,m)
g_free(_value)
'///
m=instr(1,s," ")
if m>0 then s=left(s,m-1)
'///
sLang=objText.GetLangName()
m=instr(1,sLang,"_")
if m>0 then sLang=left(sLang,m-1)
m=instr(1,sLang,"@")
if m>0 then sLang=left(sLang,m-1)
m=instr(1,sLang,".")
if m>0 then sLang=left(sLang,m-1)
'///test2
Dim As FcFontSet Ptr _set,_set2
Dim As Any Ptr p
_set = FcConfigGetFonts(NULL,0)
if sLang<>"" then
 p=FcPatternCreate()
 FcPatternAddString p,strptr("fullname"),strptr(s)
 FcPatternAddString p,strptr("fontformat"),strptr("TrueType")
 FcPatternAddString p,strptr("lang"),strptr(sLang)
 _set2=FcFontSetList(NULL,@_set,1,p,NULL)
 FcPatternDestroy(p)
 if _set2->nfont > 0 then
  FcPatternGetString _set2->fonts[0],strptr("file"),0,@_value
  m=strlen(_value)
  s2=Space(m)
  memcpy(strptr(s2),_value,m)
 else
  FcFontSetDestroy(_set2)
  p=FcPatternCreate()
  FcPatternAddString p,strptr("fontformat"),strptr("TrueType")
  FcPatternAddString p,strptr("lang"),strptr(sLang)
  _set2=FcFontSetList(NULL,@_set,1,p,NULL)
  FcPatternDestroy(p)
  if _set2->nfont > 0 then
   FcPatternGetString _set2->fonts[0],strptr("file"),0,@_value
   m=strlen(_value)
   s2=Space(m)
   memcpy(strptr(s2),_value,m)
  else
   'no any fonts!!! use built-in font
   objText.Clear()
   s2 = App.Path + "data/vera_sans.ttf"
  end if
 end if
 '///
else
 p=FcPatternCreate()
 FcPatternAddString p,strptr("fullname"),strptr(s)
 FcPatternAddString p,strptr("fontformat"),strptr("TrueType")
 _set2=FcFontSetList(NULL,@_set,1,p,NULL)
 FcPatternDestroy(p)
 if _set2->nfont > 0 then
  FcPatternGetString _set2->fonts[0],strptr("file"),0,@_value
  m=strlen(_value)
  s2=Space(m)
  memcpy(strptr(s2),_value,m)
 else
  'no any fonts!!! use built-in font
  s2 = App.Path + "data/vera_sans.ttf"
 end if
end if
FcFontSetDestroy(_set2)
'//over
Return s2 '"/usr/share/fonts/truetype/wqy/wqy-microhei.ttc"
#endif
End Function

Function _ToUTF8(s As String) As String
Dim m as long
dim i as long,j as long,c as ulong
dim lp as ushort ptr
dim s1 as string
m=len(s)
if m<2 then return ""
s1=space(m+(m shr 1)+1)
lp=CPtr(ushort ptr,strptr(s))
for i=0 to (m\2)-1
    c=lp[i]
	if(c<&H80) then
		s1[j]=c
		j+=1
	elseif(c<&H800) then
		s1[j]=(&HC0 or (c shr 6))
		s1[j+1]=(&H80 or (c and &H3F))
		j+=2
	else
		s1[j]=(&HE0 or (c shr 12))
		s1[j+1]=(&h80 or ((c shr 6) and &H3F))
		s1[j+2]=(&h80 or (c and &H3F))
		j+=3
	end if
next i
return left(s1,j)
End Function

Function _ToUCS2(s As String) As String
Dim m as long
dim i as long,j as long,c1 as ulong
dim lp as ushort ptr
dim s1 as string
m=len(s)
if m<1 then return ""
s1=space((m shl 1)+4)
lp=CPtr(ushort ptr,strptr(s1))
do while i<m
    c1=s[i]
	if(c1>=&HF0) then
	    exit do
	elseif(c1>=&HE0) then
	    if i+2<m then
		lp[j]=(CLng(c1 and &HF&) shl 12) _
			or (CLng(s[i+1] and &H3F&) shl 6) _
			or CLng(s[i+2] and &H3F&)
		j+=1
		end if
		i+=3
	elseif(c1>=&HC0) then
	    if i+1<m then
		lp[j]=(CLng(c1 and &H1F&) shl 6) _
			or CLng(s[i+1] and &H3F&)
		j+=1
		end if
		i+=2
	else
		lp[j]=c1
		i+=1
		j+=1
	end if
loop
return left(s1,j shl 1)
End Function

'////////////////////////////////////////////////////////////////
' main
'////////////////////////////////////////////////////////////////

Randomize

'///init gettext

objText.LoadFileWithLocale(App.Path+"locale/*.mo",,-1)

'///init SDL

#ifdef __FB_WIN32__
#else

gtk_init(NULL,NULL)

#endif

if (SDL_Init(SDL_INIT_VIDEO or SDL_INIT_TIMER) < 0) then
 abort
end if

if TTF_Init<0 then
 abort
end if

'///load default font
m_sFontFile = _GetDefaultFont()
if m_sFontFile="" then
 abort
end if

'size=pixel (?)
m_objFont(0)=TTF_OpenFont(m_sFontFile,12)
m_objFont(1)=TTF_OpenFont(m_sFontFile,36)
m_objFont(2)=TTF_OpenFont(m_sFontFile,64)

video = SDL_SetVideoMode(640, 480, 32, SDL_HWSURFACE or SDL_DOUBLEBUF)
if video=NULL then
 SDL_Quit
 abort
end if

SDL_WM_SetCaption objText.GetText("Turning Square"),NULL
SDL_EnableKeyRepeat SDL_DEFAULT_REPEAT_DELAY,SDL_DEFAULT_REPEAT_INTERVAL

'///test only

Form_Load

'obj->LoadFile("Default.box")
'input "Input level ";lv
'objB->LoadLevel(lv,obj)
'objB->SolveIt()
'idx=objB->SolveItGetSolutionNodeIndex()
'print "Solution=";objB->SolveItGetSolution(idx)
'print "Step=";objB->SolveItGetDistance(idx)
'print "Time=";objB->SolveItGetTimeUsed();"ms"

'delete obj
'obj=NULL
'delete objB
'objB=NULL

'///over

TTF_Quit
SDL_Quit

end
