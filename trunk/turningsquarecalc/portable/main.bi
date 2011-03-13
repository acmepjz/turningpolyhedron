#pragma once

type Boolean as Short

#define True (-1)
#define False (0)

#define NULL 0
#define CStr(_s_) Trim(Str(_s_))
#define CBool(_s_) (IIf((_s_),-1,0))

declare function Replace(Source As String, ToReplace As String, ReplaceWith As String, Count As Long = -1) as string
declare sub Split(Expression as String,Delimiter as String,ret() as String)

type _App
  declare constructor
  declare function Path() as string
  declare function ExeName() as string
private:
  _Path as string
  _ExeName as string
end type

Extern App Alias "App" as _App

type clsSimpleRnd
private:
 x(1 To 10) As Double
public:
 Declare Sub _Randomize(ByRef s As String)
 Declare Function _Rnd() As Single
 Declare Function RndSeed() As String
 Declare Function ValidateRndSeed(ByRef s As String) As String
end type

#include once "clsTheFile.bi"
#include once "clsBloxorz.bi"
#include once "clsGNUGetText.bi"
#include once "Clipboard.bi"

Public Const TheSignature As String = !"\xD2\xA1\xB7\xBD\xBF\xE9XP"

Extern objText Alias "objText" as clsGNUGetText

#include once "SDL/SDL.bi"
#include once "SDL/SDL_image.bi"
#include once "SDL/SDL_ttf.bi"
#include once "SDL/SDL_gfx_primitives.bi"
#include once "SDL/SDL_gfx_framerate.bi"

Common Shared video As SDL_Surface ptr
Common Shared m_sFontFile As String
Extern m_objFont(3) Alias "m_objFont" As TTF_Font ptr

Enum DrawTextConstants
 DT_BOTTOM = &H8
 DT_CALCRECT = &H400
 DT_CENTER = &H1
 DT_EXPANDTABS = &H40
 DT_EXTERNALLEADING = &H200
 DT_INTERNAL = &H1000
 DT_LEFT = &H0
 DT_NOCLIP = &H100
 DT_NOPREFIX = &H800
 DT_RIGHT = &H2
 DT_SINGLELINE = &H20
 DT_TABSTOP = &H80
 DT_TOP = &H0
 DT_VCENTER = &H4
 DT_WORDBREAK = &H10
 'new
 DT_EDITCONTROL = &H2000&
 DT_END_ELLIPSIS = &H8000&
 DT_MODIFYSTRING = &H10000
 DT_PATH_ELLIPSIS = &H4000&
 DT_RTLREADING = &H20000
 DT_WORD_ELLIPSIS = &H40000
End Enum

Enum ColorConstants
 vbBlack = 0&
 vbBlue = &HFF0000&
 vbCyan = &HFFFF00&
 vbGreen = &HFF00&
 vbMagenta = &HFF00FF&
 vbRed = &HFF&
 vbYellow = &HFFFF&
 vbWhite = &HFFFFFF&
End Enum

#define vbNullChar !"\0"
#define vbCr !"\r"
#define vbLf !"\n"
#define vbCrLf !"\r\n"

Declare Function _ToUTF8(s As String) As String
Declare Function _ToUCS2(s As String) As String
