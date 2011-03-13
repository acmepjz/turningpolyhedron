#include once "Clipboard.bi"
#include once "crt/string.bi"

Declare Function _ToUTF8(s As String) As String
Declare Function _ToUCS2(s As String) As String

Dim Shared Clipboard as _class_Clipboard

#ifdef __FB_WIN32__

Declare Function OpenClipboard Lib "user32" Alias "OpenClipboard" (ByVal hwnd As Long) As Long
Declare Function EmptyClipboard Lib "user32" Alias "EmptyClipboard" () As Long
Declare Function CloseClipboard Lib "user32" Alias "CloseClipboard" () As Long
Declare Function GetClipboardData Lib "user32" Alias "GetClipboardData" (ByVal wFormat As Long) As Long
Declare Function GlobalSize Lib "kernel32" Alias "GlobalSize" (ByVal hMem As Long) As Long
Declare Function GlobalLock Lib "kernel32" Alias "GlobalLock" (ByVal hMem As Long) As Any ptr
Declare Function GlobalUnlock Lib "kernel32" Alias "GlobalUnlock" (ByVal hMem As Long) As Long
Declare Function GlobalAlloc Lib "kernel32" Alias "GlobalAlloc" (ByVal wFlags As Long, ByVal dwBytes As Long) As Long
Declare Function GlobalFree Lib "kernel32" Alias "GlobalFree" (ByVal hMem As Long) As Long
Declare Function SetClipboardData Lib "user32" Alias "SetClipboardData" (ByVal wFormat As Long, ByVal hMem As Long) As Long

Const GMEM_MOVEABLE As Long = &H2

#else

#include once "gtk/gtk.bi"

#define GDK_NONE 0

#endif

Sub _class_Clipboard.Clear()
#ifdef __FB_WIN32__
	OpenClipboard(0)
	EmptyClipboard()
	CloseClipboard()
#else
	dim as GtkClipboard ptr _clipboard=gtk_clipboard_get(GDK_NONE)
	gtk_clipboard_clear(_clipboard)
#endif
End Sub

Function _class_Clipboard.GetText() As String
#ifdef __FB_WIN32__
	dim as String s
	OpenClipboard(0)
	dim as long h=GetClipboardData(13) '13 'TODO:UCS2 --> UTF8
	if(h<>0) then
		dim as long m=GlobalSize(h)
		if(m>0) then
			s=String(m,!"\0")
			dim as any ptr lp=GlobalLock(h)
			memcpy(strptr(s),lp,m)
			GlobalUnlock(h)
		'	if(Format==13){
		'		int len=wcslen((wchar_t*)s._strptr);
		'		s=Left(s,len);
		'	}else{
				s=_ToUTF8(s)
				h=instr(1,s,!"\0")
				if h>0 then s=left(s,h-1)
		'	}
		end if
	end if
	CloseClipboard()
	return s
#else
	dim as GtkClipboard ptr _clipboard=gtk_clipboard_get(GDK_NONE)
	dim as gchar ptr lp=gtk_clipboard_wait_for_text(_clipboard)
	if(lp=NULL) then return ""
	dim as String s
	dim as long m=strlen(lp)
	if(m>0) then
		s=Space(m)
		memcpy(strptr(s),lp,m)
	end if
	g_free(lp)
	return s
#endif
end function

Sub _class_Clipboard.SetText(ByRef _str as string)
#ifdef __FB_WIN32__
	OpenClipboard(0)
	EmptyClipboard()
	dim as long m=Len(_str)
	if(m>0) then
	    dim as string s=_ToUCS2(_str)
	    m=len(s)
		dim as long h=GlobalAlloc(GMEM_MOVEABLE,m+2)
		dim as any ptr lp=GlobalLock(h)
		memset(lp,0,m+2)
		memcpy(lp,strptr(s),m)
		GlobalUnlock(h)
		if(SetClipboardData(13,h)=0) then
			GlobalFree(h)
		end if
	end if
	CloseClipboard()
#else
	dim as GtkClipboard ptr _clipboard=gtk_clipboard_get(GDK_NONE)
	gtk_clipboard_set_text(_clipboard,strptr(_str),Len(_str))
	gtk_clipboard_store(_clipboard)
#endif
end sub
