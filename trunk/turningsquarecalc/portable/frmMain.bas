#include once "main.bi"
#include once "frmMain.bi"
#include once "cCommonDialog.bi"
#include once "crt/stdlib.bi"
#include once "crt/string.bi"
#include "string.bi"

#ifdef __FB_WIN32__

Declare Function ShellExecute Lib "shell32" Alias "ShellExecuteA" (ByVal hwnd As Long, ByVal lpOperation As String, ByVal lpFile As String, ByVal lpParameters As String, ByVal lpDirectory As String, ByVal nShowCmd As Long) As Long

#endif

#define bmG video
#define Game_Paint SDL_Flip(video)
#define CreateSolidBrush(x) (x)
#define Me_Font m_objFont(0)
#define Label1_10_Font m_objFont(1)
#define GetTickCount SDL_GetTicks
#define i0_7_Picture bmImg(4)
Dim Shared As SDL_Surface ptr bmG_Back, bmG_Lv, bmEdit, bmImg(4)
Dim Shared As String Me_Tag
Dim Shared As Long cmbMode_ListIndex, cmbMode_ListCount
Dim Shared cmbMode_List(255) As String

Type typeTextBox
 _Text As String
 Tag As String
 Locked As Boolean
 'MultiLine As Boolean
 '///
 Left As Long
 Top As Long
 Width As Long
 Height As Long
 '///
 SelStart As Long
 SelLength As Long
 '///
 Declare Function DoEvents() As Long
 Declare Sub Move(ByVal _Left As Long = &H80000000,ByVal _Top As Long = &H80000000,ByVal _Width As Long = &H80000000,ByVal _Height As Long = &H80000000)
 Declare Sub Draw(ByVal bm As SDL_Surface ptr = NULL)
 Declare Property SelText() As String
 Declare Property SelText(s As String)
 Declare Property Text() As String
 Declare Property Text(s As String)
End Type

Const MultiLine As Boolean = True

Dim Shared As typeTextBox txtGame(5)

Dim Shared GetAsyncKeyState As UByte Ptr

Dim Shared m_fmtAlpha as SDL_PixelFormat = Type<SDL_PixelFormat>(NULL,32,4,0,0,0,0,16,8,0,24,&H00ff0000U,&H0000ff00U,&H000000ffU,&Hff000000U,0,255)

Dim Shared GameLayer0SX As Long, GameLayer0SY As Long

'Private WithEvents sEdit As cScrollBar 'TODO:

Dim Shared cd As cCommonDialog

Dim Shared objFile As clsTheFile

Dim Shared Lev() As clsBloxorz ptr
Dim Shared LevCount As Long

Dim Shared eSelect As Long, eSX As Long, eSY As Long
Dim Shared sSX As Long, sSY As Long, sSX2 As Long, sSY2 As Long

Type RECT
    Left As Long
    Top As Long
    Right As Long
    Bottom As Long
End Type

Type POINTAPI
    x As Long
    y As Long
End Type

Type typeTheBitmap2
 ImgIndex As Long
 x As Long
 y As Long
 w As Long
 h As Long
 dX As Long
 dy As Long
 ow As Long
 oh As Long
End Type

Type typeTheBitmap3
 ImgIndex As Long
 x As Long
 y As Long
 w As Long
 h As Long
 dX As Long
 dy As Long
End Type

Type typeTheBitmapArray
 Count As Long
 bm As typeTheBitmap3 ptr
End Type

Dim Shared bmps(9 To 524) As typeTheBitmap2

Dim Shared Anis() As typeTheBitmapArray
'1-4=up move
'5-8=h move
'9-12=v move
'13-16=single move
'29=start
'30=end
'31-60=shadow
Const Ani_Layer0 = 61
Const Ani_Misc = 99

'/////'         *          '/////
'/////' *        x=10,y=16 '/////
'/////'          *         '/////
'/////'  *x=32,y=-5        '/////

Dim Shared GameD() As Byte, GameStatus As Long, GameLev As Long
'-2=exit game
'-1=return to menu
'0=load current level
'1=show level
'2=block fall
'3=block fall 2 (thin block)
'4=complete
'
'9 =play-check the pos is valid
'10=play-wait for key press
'11=play-moving animation
'12=play-move over,check state
'13=play-sliping animation
Dim Shared GameW As Long, GameH As Long
Dim Shared GameX As Long, GameY As Long, GameS As Long, GameX2 As Long, GameY2 As Long
Dim Shared GameFS As Long
'Private GameClick As Boolean
Dim Shared GameLvStartTime As Long, GameLvStep As Long, GameLvRetry As Long
Dim Shared GameDemoS As String, GameDemoPos As Long, GameDemoBegin As Boolean

Dim Shared GameMenuCaption() As String, GameMenuItemCount As Long

'Implements IBloxorzCallBack

'////////random map
'Implements ISort

Dim Shared GameIsRndMap As Boolean
Dim Shared LevTemp As clsBloxorz 'extremely stupid!!!
Dim Shared objRnd As clsSimpleRnd
Dim Shared nFitness() As Long

Declare Sub Game_Loop()
Declare Sub pInitBitmap()
Declare Sub pInitBoxAnimation(ByVal Index As Long, ByVal Count As Long, ByVal Offset As Long, ByVal NewX As Long=0, ByVal NewY As Long=0, ByVal IsReverse As Boolean=False)
Declare Sub pTheBitmapConvert(bm As typeTheBitmap2, ret As typeTheBitmap3, ByVal NewX As Long=0, ByVal NewY As Long=0)
Declare Sub pLoadBitmapData(b() As Byte, ByVal Index As Long)
Declare Sub pGameDrawLayer0(ByVal hdc As SDL_Surface ptr, d() As Byte, ByVal datw As Long, ByVal dath As Long, ByVal StartX As Long, ByVal StartY As Long)
Declare Sub pGameDrawBox(ByVal hdc As SDL_Surface ptr, ByVal Index As Long, ByVal Index2 As Long, ByVal x As Long, ByVal y As Long, ByVal Alpha As Long = 255)
Declare Sub pTheBitmapDraw3(ByVal hdc As SDL_Surface ptr, ByVal Index As Long, ByVal Index2 As Long, ByVal x As Long, ByVal y As Long, ByVal Alpha As Long = 255)
Declare Sub pTheBitmapDraw2(ByVal hdc As SDL_Surface ptr, ByVal Index As Long, ByVal x As Long, ByVal y As Long, ByVal Alpha As Long = 255)
Declare Sub Game_DrawLayer1(ByVal hdc As SDL_Surface ptr, ByVal DrawBox As Boolean = True, ByVal DrawBoxShadow As Boolean = False, ByVal Index As Long = 0, ByVal Index2 As Long = 0, ByVal BoxDeltaY As Long = 0, ByVal BoxAlpha As Long = 255, ByVal WithLayer0 As Boolean = False, ByVal BoxDeltaX As Long = 0, ByVal NoZDepth As Boolean = False)
Declare Sub Game_Instruction_Loop()
Declare Sub Game_Init()
Declare Sub Game_LoadLevel(ByRef fn As String)
Declare Sub Game_InitMenu()
Declare Sub Game_InitBack()
Declare Function Game_Menu_Loop() As Long
Declare Function Game_TextBox_Loop() As Long
Declare sub MyCallback(ByVal nNodeNow As Long, ByVal nNodeCount As Long, bAbort As Boolean)
Declare Function Game_RndMap_Loop() As Long
Declare Sub Game_RndMap_Run()
Declare Function pRandomMap(ByVal objRet As clsBloxorz ptr, ByVal w As Long = 15, ByVal h As Long = 10, ByVal objInit As clsBloxorz ptr = NULL, ByVal PoolSize As Long = 200, ByVal nTime As Long = 30, ByVal nMode As Long = 1) As Long

Dim Shared objCallback As IBloxorzCallback

'================================================================
'stupid code

Type _typeAlphaBlendTemp
  objSrc as SDL_Surface ptr
  r as SDL_Rect
  nAlpha as long
End Type

Type _typeCacheObject
  nLastTime as ULong
  obj as SDL_Surface ptr
End Type

Const _AlphaBlendCacheCount As Long=256

'cache
Dim Shared _tAlphaBlend1(_AlphaBlendCacheCount-1) As _typeAlphaBlendTemp
Dim Shared _tAlphaBlend2(_AlphaBlendCacheCount-1) As _typeCacheObject
Dim Shared _tAlphaBlendT As ULong = 0

'================================================================

#ifdef __FB_WIN32__
#else

Function ShellExecute(ByVal hwnd As Long, lpOperation As String, lpFile As String, lpParameters As String, lpDirectory As String, ByVal nShowCmd As Long) As Long
'TODO:
Return 0
End Function

#endif


Sub FillRect(ByVal hdc As SDL_Surface ptr, ByRef lpRect As RECT, ByVal hBrush As Long)
dim r as SDL_Rect
r.x=lpRect.Left
r.y=lpRect.Top
r.w=lpRect.Right-lpRect.Left
r.h=lpRect.Bottom-lpRect.Top
SDL_FillRect(hdc,@r,SDL_MapRGB(hdc->format,hBrush and &HFF&,(hBrush and &HFF00&) shr 8,(hBrush and &HFF0000&) shr 16))
End Sub

Sub FrameRect(ByVal hdc As SDL_Surface ptr, ByRef lpRect As RECT, ByVal hBrush As Long)
rectangleColor hdc,lpRect.Left,lpRect.Top,lpRect.Right-1,lpRect.Bottom-1,&HFF& or ((hBrush and &HFF&) shl 24) or ((hBrush and &HFF00&) shl 8) or ((hBrush and &HFF0000&) shr 8)
End Sub

Sub _Cls(ByVal hdc As SDL_Surface ptr)
dim r as SDL_Rect
r.w=hdc->w
r.h=hdc->h
SDL_FillRect(hdc,@r,0)
End Sub

Sub PaintPicture(objSrc as SDL_Surface ptr,objDest as SDL_Surface ptr,byval nDestLeft as long=0,byval nDestTop as long=0,byval nWidth as long=-1,byval nHeight as long=-1,byval nSrcLeft as long=0,byval nSrcTop as long=0)
Dim As SDL_Rect r1,r2
If (nWidth < 0) Then nWidth = objSrc->w
If (nHeight < 0) Then nHeight = objSrc->h
with r1
 .x=nSrcLeft
 .y=nSrcTop
 .w=nWidth
 .h=nHeight
end with 
with r2
 .x=nDestLeft
 .y=nDestTop
end with
'if objSrc->flags and SDL_SRCALPHA then SDL_SetAlpha(objSrc,SDL_SRCALPHA,255)
SDL_BlitSurface objSrc,@r1,objDest,@r2
End Sub

Function DoEvents() As Long
dim event as SDL_Event
'///get messages
Do While SDL_PollEvent(@event)
 Select Case event.type
 Case SDL_QUIT_
  GameStatus = -2
  Return 0
 End Select
Loop
Return 1
End Function

Function PtInRect(ByRef r as RECT,ByVal x as long,byval y as long) As Long
return x>=r.left andalso y>=r.top andalso x<r.right andalso y<r.bottom
end function

Sub _AlphaBlend(objSrc as SDL_Surface ptr,lprSrc as SDL_Rect ptr,objDest as SDL_Surface ptr,lprDest as SDL_Rect ptr,byval nAlpha as long)
dim t as _typeAlphaBlendTemp
dim i as long,j as long,k as long,t0 as ULong=-1,_nAlpha as ULong
'///IMPORTANT: clip rect
if CShort(lprSrc->x)<0 then
 lprSrc->w += CShort(lprSrc->x)
 lprDest->x -= CShort(lprSrc->x)
 lprSrc->x = 0
end if
if CShort(lprSrc->y)<0 then
 lprSrc->h += CShort(lprSrc->y)
 lprDest->y -= CShort(lprSrc->y)
 lprSrc->y = 0
end if
if CShort(lprSrc->x)+CShort(lprSrc->w) > CShort(objSrc->w) then lprSrc->w = CShort(objSrc->w) - CShort(lprSrc->x)
if CShort(lprSrc->y)+CShort(lprSrc->h) > CShort(objSrc->h) then lprSrc->h = CShort(objSrc->h) - CShort(lprSrc->y)
if CShort(lprSrc->w) <= 0 orelse CShort(lprSrc->h) <= 0 then exit sub
'///
t.objSrc = objSrc
t.r = *lprSrc
t.nAlpha = nAlpha
_tAlphaBlendT += 1
for i=0 to _AlphaBlendCacheCount-1
 if memcmp(@_tAlphaBlend1(i),@t,sizeof(t))=0 then
  'print "find";i
  exit for
 elseif _tAlphaBlend2(i).nLastTime<t0 then
  j=i
  t0=_tAlphaBlend2(i).nLastTime
 end if
next i
'///create new bitmap (ugly code)
if i>=_AlphaBlendCacheCount then
 i=j
 'print "create";i,lprSrc->x,lprSrc->y,lprSrc->w,lprSrc->h,objSrc->w,objSrc->h,nAlpha
 '///
 with _tAlphaBlend2(i)
  if .obj<>NULL then
   SDL_FreeSurface .obj
   .obj=NULL
  end if
  'SDL 1.2.14 bug -- crashes :(
  .obj=SDL_CreateRGBSurface(SDL_SWSURFACE or SDL_SRCALPHA, lprSrc->w, lprSrc->h, 32, &H00ff0000,&H0000ff00,&H000000ff,&Hff000000)
  '///
  _nAlpha=nAlpha*257
  SDL_LockSurface(objSrc)
  SDL_LockSurface(.obj)
  Dim As UByte ptr lp1,lp2,lp3
  lp1=.obj->pixels
  lp2=objSrc->pixels + CLng(lprSrc->y) * CLng(objSrc->pitch) + CLng(lprSrc->x) * 4&
  for j=1 to lprSrc->h
   lp3=lp2
   for k=1 to lprSrc->w
    lp1[0]=lp3[0]
    lp1[1]=lp3[1]
    lp1[2]=lp3[2]
    lp1[3]=((_nAlpha*lp3[3]) + (_nAlpha shr 1)) shr 16
    lp1+=4
    lp3+=4
   next k
   lp2+=CLng(objSrc->pitch)
  next j
  SDL_UnlockSurface(objSrc)
  SDL_UnlockSurface(.obj)
  '///
 end with
 '///
 _tAlphaBlend1(i)=t
end if
'///
_tAlphaBlend2(i).nLastTime=_tAlphaBlendT
lprSrc->x=0
lprSrc->y=0
SDL_BlitSurface _tAlphaBlend2(i).obj,lprSrc,objDest,lprDest
End Sub

'currently ignore UseAlphaChannel argument
Sub AlphaPaintPicture(objSrc as SDL_Surface ptr,objDest as SDL_Surface ptr,byval nDestLeft as long=0,byval nDestTop as long=0,byval nWidth as long=-1,byval nHeight as long=-1,byval nSrcLeft as long=0,byval nSrcTop as long=0,byval nAlpha as long=255,byval _UseAlphaChannel as boolean=False)
Dim As SDL_Rect r1,r2
dim nOldFlags as Long
if nAlpha <=0 then exit sub
If (nWidth < 0) Then nWidth = objSrc->w
If (nHeight < 0) Then nHeight = objSrc->h
if nWidth<=0 or nHeight<=0 then exit sub
with r1
 .x=nSrcLeft
 .y=nSrcTop
 .w=nWidth
 .h=nHeight
end with
with r2
 .x=nDestLeft
 .y=nDestTop
end with
if objSrc->format->Amask<>0 andalso nAlpha<255 then
 'unfortunately, SDL doesn't support per-pixel alpha with per-surface alpha, consider using AlphaBlend :-/
 _AlphaBlend objSrc,@r1,objDest,@r2,nAlpha
else
 nOldFlags=objSrc->flags and SDL_SRCALPHA
 SDL_SetAlpha(objSrc,SDL_SRCALPHA,nAlpha)
 SDL_BlitSurface objSrc,@r1,objDest,@r2
 SDL_SetAlpha(objSrc,nOldFlags,255)
end if
End Sub

'TODO:multiline support
'TODO:clip
'TODO:cache
Public Sub DrawTextB(ByVal hdc As SDL_Surface Ptr, ByRef s As String, ByVal fnt As TTF_Font Ptr, ByVal _Left As Long, ByVal _Top As Long, ByRef _Width As Long = 0, ByRef _Height As Long = 0, ByVal Style As Long = 0, ByVal ForeColor As Long = 0, ByVal BackColor As Long = 0, ByVal IsTrans As Boolean = False, ByVal HighQuality As Boolean = True)
Dim As SDL_Surface ptr objTemp
Dim As SDL_Color fg,bg
Dim As SDL_Rect r1,r2
Dim As Long w,h
if strptr(s)=0 then exit sub
*CPtr(Long Ptr,@fg) = ForeColor
*CPtr(Long Ptr,@bg) = BackColor
'////////////////
if Style and DT_SINGLELINE then
'////////////////
TTF_SizeUTF8(fnt,strptr(s),@w,@h)
if Style and DT_CALCRECT then
 _Width=w
 _Height=h
 Return
end if
if Style and DT_CENTER then
 _Left += (_Width-w) shr 1
elseif Style and DT_RIGHT then
 _Left += (_Width-w)
end if
if Style and DT_VCENTER then
 _Top += (_Height-h) shr 1
elseif Style and DT_BOTTOM then
 _Top += (_Height-h)
end if
'///
if IsTrans then
 if HighQuality then
  objTemp=TTF_RenderUTF8_Blended(fnt,strptr(s),fg)
 else
  objTemp=TTF_RenderUTF8_Solid(fnt,strptr(s),fg)
 end if
else
 objTemp=TTF_RenderUTF8_Shaded(fnt,strptr(s),fg,bg)
end if
r1.w=w
r1.h=h
r2.x=_Left
r2.y=_Top
SDL_BlitSurface objTemp,@r1,hdc,@r2
SDL_FreeSurface objTemp
'////////////////
Else
'////////////////multiline
Dim As Long hh = TTF_FontHeight(fnt), c, c1
Dim As String s1
Dim As UByte ptr lp1,lp2
if Style and DT_CALCRECT then _Height = 0
s1=Replace(Replace(s,!"\r\n",!"\n"),!"\r",!"\n")+String(32,!"\0")
lp1=strptr(s1)
Do
 lp2=lp1
 Do
  c1=lp2[0]
  if c1=0 orelse c1=10 then exit do
  if lp2>lp1 then
   c=lp2[1]
   lp2[1]=0
   TTF_SizeUTF8(fnt,lp1,@w,@h)
   lp2[1]=c
   if w>_Width then exit do
  end if
  'UTF-8
  if c1>=&HC0& andalso c1<&HE0& then
   lp2+=2
  elseif c1>=&HE0& andalso c1<&HF0& then
   lp2+=3
  else
   lp2+=1
  end if
 Loop
 c=lp2[0]
 if lp2>lp1 then
  lp2[0]=0
  '///
  TTF_SizeUTF8(fnt,lp1,@w,@h)
  if Style and DT_CALCRECT then
   _Height+=hh
  else
   if Style and DT_CENTER then
    r2.x=_Left + ((_Width-w) shr 1)
   elseif Style and DT_RIGHT then
    r2.x=_Left + (_Width-w)
   else
    r2.x=_Left
   end if
   '///
   if IsTrans then
    if HighQuality then
     objTemp=TTF_RenderUTF8_Blended(fnt,lp1,fg)
    else
     objTemp=TTF_RenderUTF8_Solid(fnt,lp1,fg)
    end if
   else
    objTemp=TTF_RenderUTF8_Shaded(fnt,lp1,fg,bg)
   end if
   r1.w=w
   r1.h=h
   r2.y=_Top
   SDL_BlitSurface objTemp,@r1,hdc,@r2
   SDL_FreeSurface objTemp
  end if
  '///
 elseif c=0 then
  exit do
 end if
 _Top += hh
 lp2[0]=c
 if c=10 then lp2+=1
 lp1=lp2
Loop
'////////////////
End If
End Sub

#define vbYesNo 4

#define vbOK 1
#define vbYes 6
#define vbNo 7

Function MsgBox(ByRef sPrompt As String = "",ByVal nButtons As Long = 0,ByRef sTitle As String = "") As Long
Dim nButtonCount As Long
Dim nButtonValue(7) As Long
Dim sButtonCaption(7) As String
Dim r As RECT
dim as long i,j,x,y
'///
Select Case nButtons And 7&
Case vbYesNo
 nButtonCount=2
 nButtonValue(0)=vbYes
 sButtonCaption(0)=objText.GetText("Yes")
 nButtonValue(1)=vbNo
 sButtonCaption(1)=objText.GetText("No")
Case Else
 'TODO:
 nButtonCount=1
 nButtonValue(0)=vbOK
 sButtonCaption(0)=objText.GetText("OK")
End Select
'///draw
r.Left=120
r.Top=120
r.Right=520
r.Bottom=360
FillRect bmG,r,vbBlack
FrameRect bmG,r,&H80FF&
'///
r.Left=324-40*nButtonCount
r.Top=320
r.Bottom=344
For i=0 to nButtonCount-1
 DrawTextB bmG,sButtonCaption(i),Me_Font,r.Left,r.Top,72,24,DT_CENTER or DT_VCENTER or DT_SINGLELINE, vbWhite,,True
 r.Left=r.Left+80
next i
DrawTextB bmG,sTitle,Me_Font,160,120,320,40,DT_CENTER or DT_VCENTER or DT_SINGLELINE, vbWhite,,True
DrawTextB bmG,sPrompt,Me_Font,160,160,320,160, , vbWhite,,True
'///
Do While GameStatus>=-2
 j=SDL_GetMouseState(@x,@y) and SDL_BUTTON(1)
 r.Left=324-40*nButtonCount
 r.Top=320
 r.Bottom=344
 For i=0 to nButtonCount-1
  r.right=r.left+72
  if ptinrect(r,x,y) then
   FrameRect bmG,r,&H80FF&
   If j then return nButtonValue(i)
  else
   FrameRect bmG,r,vbBlack
  end if
  r.Left=r.Left+80
 next i
 Game_Paint
 Sleep 20
 DoEvents
Loop
'///
Return 0
End Function

Function InputBox(ByRef sPrompt As String = "",ByRef sTitle As String = "",ByRef sDefault As String = "") As String
Dim nButtonCount As Long
Dim sButtonCaption(1) As String
Dim r As RECT
dim as long i,j,x,y
dim t as typeTextBox
'///
nButtonCount=2
sButtonCaption(0)=objText.GetText("OK")
sButtonCaption(1)=objText.GetText("Cancel")
'///draw
r.Left=120
r.Top=120
r.Right=520
r.Bottom=360
FillRect bmG,r,vbBlack
FrameRect bmG,r,&H80FF&
'///
r.Left=324-40*nButtonCount
r.Top=320
r.Bottom=344
For i=0 to nButtonCount-1
 DrawTextB bmG,sButtonCaption(i),Me_Font,r.Left,r.Top,72,24,DT_CENTER or DT_VCENTER or DT_SINGLELINE, vbWhite,,True
 r.Left=r.Left+80
next i
DrawTextB bmG,sTitle,Me_Font,160,120,320,40,DT_CENTER or DT_VCENTER or DT_SINGLELINE, vbWhite,,True
DrawTextB bmG,sPrompt,Me_Font,160,160,320,80, , vbWhite, ,True
t.move 160,240,320,64
t.text=sDefault
'///
Do While GameStatus>=-2
 j=SDL_GetMouseState(@x,@y) and SDL_BUTTON(1)
 r.Left=324-40*nButtonCount
 r.Top=320
 r.Bottom=344
 For i=0 to nButtonCount-1
  r.right=r.left+72
  if ptinrect(r,x,y) then
   FrameRect bmG,r,&H80FF&
   If j then
    if i=0 then return t.text else return ""
   end if
  else
   FrameRect bmG,r,vbBlack
  end if
  r.Left=r.Left+80
 next i
 t.Draw bmG
 Game_Paint
 Sleep 20
 t.DoEvents
Loop
'///
Return ""
End Function

Property typeTextBox.Text() As String
Return _ToUTF8(_Text)
End Property

Property typeTextBox.Text(s As String)
_Text=_ToUCS2(s)
End Property

Property typeTextBox.SelText() As String
dim m as long
m=Len(_Text) shr 1
if selstart>=0 andalso selstart<m then
 if sellength>0 andalso SelStart+SelLength<=m then return _ToUTF8(mid(_Text,selstart*2+1,sellength*2))
end if
return ""
End Property

Property typeTextBox.SelText(s As String)
dim m as long
dim s1 as string
m=Len(_Text) shr 1
if selstart>=0 andalso selstart<=m then
 s1=_ToUCS2(s)
 if sellength>0 andalso SelStart+SelLength<=m then
  _Text=Mid(_Text,1,selstart*2)+s1+Mid(_Text,SelStart*2+SelLength*2+1)
 else
  _Text=Mid(_Text,1,selstart*2)+s1+Mid(_Text,SelStart*2+1)
 end if
 selstart=selstart+(len(s1) shr 1)
 sellength=0
end if
End Property

Function typeTextBox.DoEvents() As Long
dim event as SDL_Event
dim x as long,y as long,m as long
dim s as string
'///get messages
Do While SDL_PollEvent(@event)
 Select Case event.type
 Case SDL_QUIT_
  GameStatus = -2
  Return 0
 Case SDL_KEYDOWN
  select case event.key.keysym.sym
  case SDLK_RETURN
   if locked=0 andalso MultiLine then
    seltext = !"\r\n"
   end if
  case SDLK_LEFT
    if selstart>0 then selstart=selstart-1
    sellength=0
  case SDLK_UP
   if MultiLine then
    selstart=selstart-(width shr 3)
    if selstart<0 then selstart=0
    sellength=0
   end if
  case SDLK_RIGHT
    if selstart<(len(_Text) shr 1) then selstart=selstart+1
    sellength=0
  case SDLK_DOWN
   if MultiLine then
    selstart=selstart+(width shr 3)
    m=len(_Text) shr 1
    if selstart>m then selstart=m
    sellength=0
   end if
  case SDLK_BACKSPACE
   if locked=0 then
    if selstart>0 andalso sellength=0 then
     selstart=selstart-1
     sellength=1
    end if
    seltext=""
   end if 
  case SDLK_DELETE
   if locked=0 then
    m=len(_text) shr 1
    if selstart<m andalso sellength=0 then
     sellength=1
    end if
    seltext=""
   end if 
  case else
   if event.key.keysym.sym=SDLK_X andalso (event.key.keysym.mod_ and KMOD_CTRL) then
    if locked=0 then
     s=seltext
     if s<>"" then
      clipboard.settext s
      seltext=""
     end if 
    end if 
   elseif event.key.keysym.sym=SDLK_C andalso (event.key.keysym.mod_ and KMOD_CTRL) then
     s=seltext
     if s<>"" then clipboard.settext s
   elseif event.key.keysym.sym=SDLK_V andalso (event.key.keysym.mod_ and KMOD_CTRL) then
    if locked=0 then
     s=clipboard.gettext
     if s<>"" then seltext=s
    end if
   elseif event.key.keysym.sym=SDLK_A andalso (event.key.keysym.mod_ and KMOD_CTRL) then
    selstart=0
    sellength=len(_text) shr 1
   elseif locked=0 then
    x=event.key.keysym.sym
    if x>=32 and x<=127 then
     seltext=chr(x)
    end if
   end if
  end select
 Case SDL_MOUSEBUTTONDOWN
  x=CLng(event.button.x)-left
  y=CLng(event.button.y)-top
  if x>=0 and x<width and y>=0 and y<height then
   x = (x+4) shr 3
   if multiline then x += (y shr 4) * (width shr 3)
   m=len(_text) shr 1
   if x<0 then x=0 else if x>m then x=m
   selstart=x
   sellength=0
  end if
 Case SDL_MOUSEBUTTONUP
  'TODO:
 End Select
Loop
Return 1
End Function

Sub typeTextBox.Move(ByVal _Left As Long = &H80000000,ByVal _Top As Long = &H80000000,ByVal _Width As Long = &H80000000,ByVal _Height As Long = &H80000000)
if _left<>&H80000000 then left=_left
if _top<>&H80000000 then top=_top
if _width<>&H80000000 then width=_width
if _height<>&H80000000 then height=_height
End Sub

Sub typeTextBox.Draw(ByVal bm As SDL_Surface ptr = NULL)
dim r as rect
dim i as long,j as long,k as long,m as long
dim mi as long,mj as long
dim s as string
if bm=NULL then bm=bmG
r.left=left
r.top=top
r.right=left+width
r.bottom=top+height
fillrect bm,r,vbBlack
framerect bm,r,&H80FF&
'///
mi=width shr 3
if multiline then mj=height shr 4
if mj<=0 then mj=1
'///
m=len(_text)
'///
for j=0 to mj-1
 for i=0 to mi-1
  if k>=m then exit for,for
  s=_ToUTF8(mid(_text,k*2+1,2))
  DrawTextB bm,s,Me_Font,left+(i shl 3),top+(j shl 4),8,16,DT_SINGLELINE,vbWhite,&H80FF&,k<selstart or k>=selstart+sellength
  k+=1
  if k=selstart then vlineColor bm,left+8+(i shl 3),top+2+(j shl 4),top+13+(j shl 4),&HFF8000FF
 next i
next j
'///
End Sub

'================================================================

Sub Game_Loop()
Dim i As Long, j As Long, k As Long, m As Long
Dim w As Long, h As Long
Dim x As Long, y As Long, x2 As Long, y2 As Long
Dim d() As Byte, dL() As Long, dSng() As Single
Dim bEnsureReDraw As Boolean, nBridgeChangeCount As Long
Dim idx As Long, idx2 As Long, nAnimationIndex As Long
Dim kx As Long, ky As Long, kt As Long
'Dim bmTemp As New cDIBSection
Dim p As POINTAPI, r As RECT, IsMouseIn As Boolean, IsMouseIn2 As Boolean, IsSliping As Boolean
Dim s As String, sSolution As String, t As Long ' time!
':-/
Dim QIE As Long, QIE_O As Long
Do
 Select Case GameStatus
 Case 0 '///////////////////////////////////////////////////////load level
  'init layer0 size
  With *Lev(GameLev)
   GameW = .Width
   GameH = .Height
  End With
  w = GameW * 32 + GameH * 10
  h = GameW * 5 + GameH * 16 + 16
  GameLayer0SX = (640 - w) \ 2
  GameLayer0SY = (480 - h) \ 2 + GameW * 5 + 8
  'init
  GameLvRetry = -1
  GameLvStartTime = 0
  GameDemoPos = 0
  GameDemoBegin = False
  'level name animation
  _Cls bmG_Lv
  If GameIsRndMap Then
   DrawTextB bmG_Lv, objText.GetText("Random Level"), Label1_10_Font, 0, 0, 640, 480, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
  Else
   DrawTextB bmG_Lv, Replace(objText.GetText("Level %d"), "%d", CStr(GameLev)), Label1_10_Font, 0, 0, 640, 480, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
  End If
  For i = 0 To 255 Step 17
   _Cls bmG
   AlphaPaintPicture bmG_Lv, bmG, 0, 200, 640, 80, 0, 200, i, False
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next i
  For i = 1 To 50
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next i
  For i = 255 To 0 Step -17
   _Cls bmG
   AlphaPaintPicture bmG_Lv, bmG, 0, 200, 640, 80, 0, 200, i, False
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next i
  GameStatus = 1
 Case 1 '///////////////////////////////////////////////////////start level
  'init level
  With *Lev(GameLev)
   ReDim GameD( 1 To GameH,1 To GameW)
   For i = 1 To GameW
    For j = 1 To GameH
     GameD(j,i) = .Data(i, j)
    Next j
   Next i
   GameX = .StartX
   GameY = .StartY
   GameS = 0
   GameFS = 0
   IsSliping = False
  End With
  'init
  nBridgeChangeCount = 0
  kt = 0
  If Not GameDemoBegin Then GameLvRetry = GameLvRetry + 1
  GameLvStep = 0
  sSolution = ""
  GameDemoPos = IIf(GameDemoBegin, 1, 0)
  GameDemoBegin = False
  QIE = 0
  QIE_O = 0
  'init back
  Game_InitBack
  'animate
  ReDim dL(1 To GameH * 2, 1 To GameW)
  For i = 1 To GameW
   For j = 1 To GameH
    dL(j,i) = Int(16 * Rnd)
    dL(j + GameH,i) = -1
   Next j
  Next i
  For i = 0 To 255 Step 51
   _Cls bmG
   AlphaPaintPicture bmG_Back, bmG, 0, 0, 640, 480, 0, 0, i, False
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next i
  For k = 0 To 36
   PaintPicture bmG_Back, bmG
   x = GameLayer0SX + GameW * 32
   y = GameLayer0SY - GameW * 5
   For i = GameW To 1 Step -1
    x = x - 32
    y = y + 5
    x2 = x
    y2 = y
    For j = 1 To GameH
     If dL( j,i) >= 0 And k >= dL( j,i) Then
      dL( j,i) = -32
      dL( j + GameH,i) = 400
     End If
     If dL( j + GameH,i) >= 0 Then
      pTheBitmapDraw3 bmG, Ani_Layer0, GameD( j,i), x2, y2 + dL( j + GameH,i), -dL( j,i)
      If GameD( j,i) = 11 Then
       pTheBitmapDraw3 bmG, Ani_Misc, 6, x2, y2 + dL( j + GameH,i), -dL( j,i)
      End If
      dL( j + GameH,i) = (dL( j + GameH,i) * 3) \ 4
      dL( j,i) = dL( j,i) - 16
      If dL( j,i) < -255 Then dL( j,i) = -255
     End If
     x2 = x2 + 10
     y2 = y2 + 16
    Next j
   Next i
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next k
  'init array
  ReDim dL( 1 To GameH,1 To GameW)
  'draw layer0
  PaintPicture bmG_Back, bmG_Lv
  pGameDrawLayer0 bmG_Lv, GameD(), GameW, GameH, GameLayer0SX, GameLayer0SY
  'box falls
  For j = -600 To 0 Step 50
   PaintPicture bmG_Lv, bmG
   Game_DrawLayer1 bmG, , , Ani_Misc, 5, j
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next j
  For i = 1 To Anis(29).Count
   PaintPicture bmG_Lv, bmG
   Game_DrawLayer1 bmG, , True, 29, i
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next i
  'init time
  t = 0
  If GameLvStartTime = 0 Then GameLvStartTime = GetTickCount
  'end
  GameStatus = 9
 Case 2 '///////////////////////////////////////////////////////block fall
  'TODO:block fall
  Select Case GameFS
  Case 1: x2 = -2: y2 = -4 'up
  Case 2: x2 = 2: y2 = 4 'down
  Case 3: x2 = -5: y2 = 1 'left
  Case 4: x2 = 5: y2 = -1 'right
  Case Else 'may be block 2 fall
   x2 = 0
   y2 = 0
   GameFS = 1
  End Select
  idx = 70 + 4 * GameS + GameFS
  idx2 = 1
  w = 0
  h = 1
  x = 0
  For i = 1 To 30
   w = w + h + y2
   h = h + 1
   x = x + x2
   idx2 = 1 + (idx2 Mod 9)
   PaintPicture bmG_Back, bmG
   Game_DrawLayer1 bmG, , False, idx, idx2, w, , True, x
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next i
  'fall animation
  ReDim dL( 1 To GameH * 2,1 To GameW)
  For i = 1 To GameW
   For j = 1 To GameH
    dL( j,i) = Int(15 * Rnd)
   Next j
  Next i
  For k = 0 To 30
   PaintPicture bmG_Back, bmG
   x = GameLayer0SX + GameW * 32
   y = GameLayer0SY - GameW * 5
   For i = GameW To 1 Step -1
    x = x - 32
    y = y + 5
    x2 = x
    y2 = y
    For j = 1 To GameH
     If dL( j,i) >= 0 And k >= dL( j,i) Then
      dL( j,i) = -2
     End If
     If dL( j + GameH,i) < 510 Then
      pTheBitmapDraw3 bmG, Ani_Layer0, GameD( j,i), x2, y2 + dL( j + GameH,i), 255 - dL( j + GameH,i) \ 2
      If GameD( j,i) = 11 Then
       pTheBitmapDraw3 bmG, Ani_Misc, 6, x2, y2 + dL( j + GameH,i), 255 - dL( j + GameH,i) \ 2
      End If
      If dL( j,i) < 0 Then
       dL( j + GameH,i) = dL( j + GameH,i) - dL( j,i)
       dL( j,i) = dL( j,i) - 2
      End If
     End If
     x2 = x2 + 10
     y2 = y2 + 16
    Next j
   Next i
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next k
  For i = 255 To 0 Step -51
   _Cls bmG
   AlphaPaintPicture bmG_Back, bmG, 0, 0, 640, 480, 0, 0, i, False
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next i
  'end
  GameStatus = 1 'restart
 Case 3 '///////////////////////////////////////////////////////block fall 2
  ReDim dL( 1 To GameH * 2,1 To GameW)
  For i = 1 To GameW
   For j = 1 To GameH
    dL( j,i) = 20 + Int(15 * Rnd)
   Next j
  Next i
  dL( GameY,GameX) = -2
  w = 0
  h = 0
  For k = 0 To 50
   PaintPicture bmG_Back, bmG
   x = GameLayer0SX + GameW * 32
   y = GameLayer0SY - GameW * 5
   For i = GameW To 1 Step -1
    x = x - 32
    y = y + 5
    x2 = x
    y2 = y
    For j = 1 To GameH
     If dL( j,i) >= 0 And k >= dL( j,i) Then
      dL( j,i) = -2
     End If
     If dL( j + GameH,i) < 510 Then
      pTheBitmapDraw3 bmG, Ani_Layer0, GameD( j,i), x2, y2 + dL( j + GameH,i), 255 - dL( j + GameH,i) \ 2
      If GameD( j,i) = 11 Then
       pTheBitmapDraw3 bmG, Ani_Misc, 6, x2, y2 + dL( j + GameH,i), 255 - dL( j + GameH,i) \ 2
      End If
      If dL( j,i) < 0 Then
       dL( j + GameH,i) = dL( j + GameH,i) - dL( j,i)
       dL( j,i) = dL( j,i) - 2
      End If
     End If
     If w < 510 And i = GameX And j = GameY Then
      w = w + h
      h = h + 1
      pTheBitmapDraw3 bmG, 1, 1, x2, y2 + w
     End If
     x2 = x2 + 10
     y2 = y2 + 16
    Next j
   Next i
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next k
  For i = 255 To 0 Step -51
   _Cls bmG
   AlphaPaintPicture bmG_Back, bmG, 0, 0, 640, 480, 0, 0, i, False
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next i
  'end
  GameStatus = 1 'restart
 Case 4 '///////////////////////////////////////////////////////win
  'block animation
  For i = 1 To Anis(30).Count
   PaintPicture bmG_Lv, bmG
   Game_DrawLayer1 bmG, , , 30, i
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next i
  'animation
  ReDim dSng(1 To GameW, 1 To GameH * 3)
  ReDim dL( 1 To GameH,1 To GameW)
  w = GameLayer0SX + (GameX - 1) * 32 + (GameY - 1) * 10
  h = GameLayer0SY - (GameX - 1) * 5 + (GameY - 1) * 16
  x = GameLayer0SX + GameW * 32
  y = GameLayer0SY - GameW * 5
  For i = GameW To 1 Step -1
   x = x - 32
   y = y + 5
   x2 = x
   y2 = y
   For j = 1 To GameH
    dSng(i, j) = x2
    dSng(i, j + GameH) = y2
    dL( j,i) = Int(4 * Rnd)
    dSng(i, j + GameH * 2) = 5 / (10 + dL( j,i)) / (10 + Sqr((x2 - w) * (x2 - w) + (y2 - h) * (y2 - h)))
    x2 = x2 + 10
    y2 = y2 + 16
   Next j
  Next i
  For k = 0 To 51
   PaintPicture bmG_Back, bmG
   For i = GameW To 1 Step -1
    For j = 1 To GameH
     kx = dL( j,i)
     m = 255 - (5 + kx) * k
     If m > 0 Then
      x = dSng(i, j)
      y = dSng(i, j + GameH)
      dSng(i, j) = dSng(i, j) - (y - h) * dSng(i, j + GameH * 2) * k
      dSng(i, j + GameH) = dSng(i, j + GameH) + (x - w) * dSng(i, j + GameH * 2) * k
      x2 = dSng(i, j)
      y2 = dSng(i, j + GameH)
      pTheBitmapDraw3 bmG, Ani_Layer0, GameD( j,i), x2, y2, m
      If GameD( j,i) = 11 Then
       pTheBitmapDraw3 bmG, Ani_Misc, 6, x2, y2, m
      End If
     End If
    Next j
   Next i
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next k
  'clear up
  Erase dSng, dL
  For i = 255 To 0 Step -51
   _Cls bmG
   AlphaPaintPicture bmG_Back, bmG, 0, 0, 640, 480, 0, 0, i, False
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next i
  'end
  If GameDemoPos = 0 Then
   If GameIsRndMap Then
    txtGame(4).Text = objRnd.RndSeed
    _Cls bmG_Back '??
    Game_RndMap_Run
   Else
    GameLev = GameLev + 1
    If GameLev > LevCount Then GameLev = LevCount
   End If
   GameStatus = 0 'next level
  Else 'just demo only
   GameLvRetry = GameLvRetry - 1
   GameStatus = 1
  End If
 Case 9, 10, 11, 12, 13, 14, 15 '///////////////////////////////////////////////////////.....
  'calc index
  idx = GameS * 4 + 1
  idx2 = 1
  Select Case GameStatus
  Case 9 'check state valid
   Select Case Lev(GameLev)->BloxorzCheckIsValidState(GameD(), GameX, GameY, GameS, GameX2, GameY2)
   Case 0 'fall
    GameStatus = 2 'TODO:animation?
    'block2 fall?
    m = 0
    If GameS = 3 Then
     If GameX2 > 0 And GameY2 > 0 And GameX2 <= GameW And GameY2 <= GameW Then
      i = GameD( GameY2,GameX2)
      If i = 0 Or i = 6 Then m = 1
     Else
      m = 1
     End If
    End If
    If m Then
     x = GameX
     y = GameY
     GameX = GameX2
     GameY = GameY2
     GameX2 = x
     GameY2 = y
     GameFS = 0
    End If
   Case 1 'valid
    If GameD( GameY,GameX) = 8 And GameS = 0 Then GameStatus = 4 Else GameStatus = 10
   Case 2 'thin
    GameStatus = 3
   Case Else 'unknown
    MsgBox objText.GetText("Unknown error!")
    GameStatus = -1
   End Select
   bEnsureReDraw = True
  Case 10 'press key?
   y = 0
   If GameDemoPos > 0 And kt < 32 Then 'don't press space too frequently
    If GameDemoPos > Len(GameDemoS) Then
     y = 99
    Else
     Select Case Mid(GameDemoS, GameDemoPos, 1)
     Case "u" ', ChrW(8593), LCase(objText.GetText("U"))
      y = 1
     Case "d" ', ChrW(8595), LCase(objText.GetText("D"))
      y = 2
     Case "l" ', ChrW(8592), LCase(objText.GetText("L"))
      y = 3
     Case "r" ', ChrW(8594), LCase(objText.GetText("R"))
      y = 4
     Case " ", "s", "_" ', ChrW(9671), ChrW(9633), LCase(objText.GetText("S"))
      y = 5
     Case !"\r", !"\n", ",", ";"
      y = 99
     End Select
     GameDemoPos = GameDemoPos + 1
    End If
    If y = 99 Then 'end
     GameDemoPos = 0
     y = 0
    End If
   End If
   If (SDL_GetAppState And SDL_APPINPUTFOCUS) <> 0 OrElse y > 0 Then
    GetAsyncKeyState = SDL_GetKeyState(NULL)
    If GetAsyncKeyState[SDLK_R] Then 'restart?
     GameStatus = 1
    ElseIf GetAsyncKeyState[SDLK_PageUp] AndAlso GameLev < LevCount Then 'next level (prev?)
     GameIsRndMap = False
     GameLev = GameLev + 1
     GameStatus = 0
    ElseIf GetAsyncKeyState[SDLK_PageDown] AndAlso GameLev > 1 Then 'prev level (next?)
     GameIsRndMap = False
     GameLev = GameLev - 1
     GameStatus = 0
    End If
    If GameStatus <= 1 Then
     'animation
     For i = 255 To 0 Step -51
      _Cls bmG
      AlphaPaintPicture bmG_Back, bmG, 0, 0, 640, 480, 0, 0, i, False
      Game_Paint
      Sleep 10
      DoEvents
      If GameStatus < 0 Then Exit Sub
     Next i
    ElseIf (GetAsyncKeyState[SDLK_Space] AndAlso GameDemoPos = 0) OrElse y = 5 Then
     GetAsyncKeyState[SDLK_Space] = 0 '???
     If GameS = 3 Then
      'record step
      sSolution = sSolution + "S" 'objText.GetText("S") '"¡ó"
      'swap block
      x = GameX
      y = GameY
      GameX = GameX2
      GameY = GameY2
      GameX2 = x
      GameY2 = y
      'animation
      kx = GameLayer0SX + (GameX - 1) * 32 + (GameY - 1) * 10 + 21
      ky = GameLayer0SY - (GameX - 1) * 5 + (GameY - 1) * 16 - 10
      kt = 40
     End If
    Else
     If (GetAsyncKeyState[SDLK_Up]) AndAlso GameDemoPos = 0 Then
      y = 1
     ElseIf (GetAsyncKeyState[SDLK_Down]) AndAlso GameDemoPos = 0 Then
      y = 2
     ElseIf (GetAsyncKeyState[SDLK_Left]) AndAlso GameDemoPos = 0 Then
      y = 3
     ElseIf (GetAsyncKeyState[SDLK_Right]) AndAlso GameDemoPos = 0 Then
      y = 4
     End If
     If y > 0 Then
      If Lev(GameLev)->BloxorzCheckIsMovable(GameD(), GameX, GameY, GameS, y, QIE) Then
       GameFS = y
       GameStatus = 11
       'init animation
       If QIE_O Then
        nAnimationIndex = IIf(QIE > 0, 1, 1) '6?
       Else
        nAnimationIndex = 2
       End If
       'calc step
       GameLvStep = GameLvStep + 1
       'record step
       Select Case y
       Case 1:      s = "U" 'objText.GetText("U") '"¡ü"
       Case 2:      s = "D" 'objText.GetText("D") '"¡ý"
       Case 3:      s = "L" 'objText.GetText("L") '"¡û"
       Case 4:      s = "R" 'objText.GetText("R") '"¡ú"
       End Select
       sSolution = sSolution + s
      End If
     End If
    End If
   End If
  Case 11 'moving animation
   'TODO:block???
   idx = GameS * 4 + GameFS
   idx2 = nAnimationIndex
   nAnimationIndex = nAnimationIndex + 1
   i = Anis(idx).Count
   If QIE Then i = 7 ':-/
   If nAnimationIndex >= i Then GameStatus = 12
   bEnsureReDraw = True
  Case 13 'sliping animation
   'TODO:block???
   idx = GameS * 4 + GameFS
   idx2 = 1
   nAnimationIndex = nAnimationIndex + 1
   If nAnimationIndex >= 7 Then GameStatus = 12
   'calc delta
   Select Case GameFS
   Case 1: x2 = -10: y2 = -16 'up
   Case 2: x2 = 10: y2 = 16   'down
   Case 3: x2 = -32: y2 = 5   'left
   Case 4: x2 = 32: y2 = -5   'right
   End Select
   x2 = (x2 * nAnimationIndex) \ 8
   y2 = (y2 * nAnimationIndex) \ 8
   bEnsureReDraw = True
  Case 12 'check moved state
   QIE_O = QIE ':-/
   Select Case QIE
   Case 1: x2 = 20: y2 = 32 'up
   Case 2: x2 = -10: y2 = -16    'down
   Case 3: x2 = 64: y2 = -10   'left
   Case 4: x2 = -32: y2 = 5    'right
   Case Else: x2 = 0: y2 = 0
   End Select
   'calc new pos
   If IsSliping Then
    Select Case GameFS
    Case 1: GameY = GameY - 1 'up
    Case 2: GameY = GameY + 1 'down
    Case 3: GameX = GameX - 1 'left
    Case 4: GameX = GameX + 1 'right
    End Select
   Else
    Select Case GameFS
    Case 1 'up
     If GameS = 0 Then GameY = GameY - 2 Else GameY = GameY - 1
     If GameS = 0 Or GameS = 2 Then GameS = 2 - GameS
    Case 2 'down
     If GameS = 2 Then GameY = GameY + 2 Else GameY = GameY + 1
     If GameS = 0 Or GameS = 2 Then GameS = 2 - GameS
    Case 3 'left
     If GameS = 0 Then GameX = GameX - 2 Else GameX = GameX - 1
     If GameS < 2 Then GameS = 1 - GameS
    Case 4 'right
     If GameS = 1 Then GameX = GameX + 2 Else GameX = GameX + 1
     If GameS < 2 Then GameS = 1 - GameS
    End Select
   End If
   'update index
   idx = GameS * 4 + 1
   'check
   Select Case Lev(GameLev)->BloxorzCheckIsValidState(GameD(), GameX, GameY, GameS, GameX2, GameY2)
   Case 0 'fall
    GameStatus = 2 'TODO:animation?
   Case 1 'valid
    GameStatus = 9
    'press button
    nBridgeChangeCount = Lev(GameLev)->BloxorzCheckPressButton(GameD(), GameX, GameY, GameS, VarPtr(dL(1, 1)), 115, 215)
    If nBridgeChangeCount > 0 Then
     PaintPicture bmG_Back, bmG_Lv
     pGameDrawLayer0 bmG_Lv, GameD(), GameW, GameH, GameLayer0SX, GameLayer0SY
    End If
    'trans (teleport)
    If GameS = 0 And GameD( GameY,GameX) = 4 Then
     'TODO:more animation
     'animation
     For i = 255 To 0 Step -17
      PaintPicture bmG_Lv, bmG
      Game_DrawLayer1 bmG, , True, 1, 1, , i
      Game_Paint
      Sleep 10
      DoEvents
      If GameStatus < 0 Then Exit Sub
     Next i
     x = GameX
     y = GameY
     Lev(GameLev)->GetTransportPosition x, y, GameX, GameY, GameX2, GameY2
     '///add check code
     If GameX < 1 Or GameX2 < 1 Or GameY < 1 Or GameY2 < 1 _
     Or GameX > GameW Or GameX2 > GameW Or GameY > GameH Or GameY2 > GameH Then
      MsgBox objText.GetText("Map error!")
      GameStatus = -1
      Exit Sub
     End If
     '///new mode:check two box get together?
     GameS = 3
     If GameX = GameX2 Then
      If GameY + 1 = GameY2 Then
       GameS = 2
      ElseIf GameY - 1 = GameY2 Then
       GameY = GameY2
       GameS = 2
      ElseIf GameY = GameY2 Then 'new mode
       GameS = 0 '???
      End If
     ElseIf GameY = GameY2 Then
      If GameX + 1 = GameX2 Then
       GameS = 1
      ElseIf GameX - 1 = GameX2 Then
       GameX = GameX2
       GameS = 1
      End If
     End If
     '///
     idx = 13 'update index '???
     GameFS = 0 'clear last move to prevent ice
     'animation
     kx = GameLayer0SX + (GameX - 1) * 32 + (GameY - 1) * 10 + 21
     ky = GameLayer0SY - (GameX - 1) * 5 + (GameY - 1) * 16 - 10
     kt = 24
     If GameS = 1 Then 'h
      kx = kx + 16
      ky = ky - 2
     ElseIf GameS = 2 Then 'v
      kx = kx + 5
      ky = ky + 8
     End If
     For i = 0 To 15
      PaintPicture bmG_Lv, bmG
      Game_DrawLayer1 bmG, , True, GameS * 4& + 1, 1, , i * 17
      pTheBitmapDraw3 bmG, Ani_Misc, 3, kx - 40 + i, ky, i * 17
      pTheBitmapDraw3 bmG, Ani_Misc, 4, kx + 40 - i, ky, i * 17
      Game_Paint
      Sleep 10
      DoEvents
      If GameStatus < 0 Then Exit Sub
     Next i
    End If
    IsSliping = False
    i = Lev(GameLev)->BloxorzCheckBlockSlip(GameD(), GameX, GameY, GameS, GameFS, GameX2, GameY2)
    If i > 0 Then 'ice
     GameFS = i
     GameStatus = 13
     IsSliping = True
     nAnimationIndex = 0
    ElseIf GameS = 0 And GameD( GameY,GameX) = 10 And GameFS > 0 Then    'pyramid
     'check movable
     If Lev(GameLev)->BloxorzCheckIsMovable(GameD(), GameX, GameY, GameS, GameFS) Then
      GameStatus = 11
      nAnimationIndex = 1
     End If
    Else
     'erase direction
     GameFS = 0
     'two box get together?
     If GameS = 3 Then
      If GameX = GameX2 Then
       If GameY + 1 = GameY2 Then
        GameS = 2
       ElseIf GameY - 1 = GameY2 Then
        GameY = GameY2
        GameS = 2
       ElseIf GameY = GameY2 Then 'err!!
        MsgBox objText.GetText("Map error!")
        GameStatus = -1
       End If
      ElseIf GameY = GameY2 Then
       If GameX + 1 = GameX2 Then
        GameS = 1
       ElseIf GameX - 1 = GameX2 Then
        GameX = GameX2
        GameS = 1
       End If
      End If
     End If
    End If
    'update index
    idx = GameS * 4 + 1
    'If True Then
    ' GameStatus = 9
    'End If
   Case 2 'thin
    GameStatus = 3
   Case Else 'unknown
    MsgBox objText.GetText("Unknown error!")
    GameStatus = -1
   End Select
   bEnsureReDraw = True
  End Select
  If nBridgeChangeCount > 0 Then bEnsureReDraw = True
  If kt > 0 Then bEnsureReDraw = True
  'draw menu?
  SDL_GetMouseState @p.x,@p.y
  r.Left = 600
  r.Top = 8
  r.Right = 632
  r.Bottom = 24
  If CBool(PtInRect(r, p.x, p.y)) Xor IsMouseIn Then
   IsMouseIn = Not IsMouseIn
   bEnsureReDraw = True
  End If
  'copyBtn?
  If GameIsRndMap Then
   r.Left = 380
   r.Right = r.Left + 48
   If CBool(PtInRect(r, p.x, p.y)) Xor IsMouseIn2 Then
    IsMouseIn2 = Not IsMouseIn2
    bEnsureReDraw = True
   End If
  End If
  'check time
  i = GetTickCount - GameLvStartTime
  If i >= t * 1000 Then
   t = i \ 1000
   bEnsureReDraw = True
  End If
  'redraw?
  If bEnsureReDraw And GameStatus > 1 Then '???
   PaintPicture bmG_Lv, bmG
   'draw text (ZDepth????)
   s = Format(t Mod 60, "00")
   i = t \ 60
   s = Format(i \ 60, "00") + ":" + Format(i Mod 60, "00") + ":" + s
   DrawTextB bmG, CStr(GameLvStep), Me_Font, 64, 24, 72, 16, DT_VCENTER Or DT_SINGLELINE, vbBlack, , True
   DrawTextB bmG, s, Me_Font, 64, 40, 72, 16, DT_VCENTER Or DT_SINGLELINE, vbBlack, , True
   DrawTextB bmG, CStr(GameLvRetry), Me_Font, 64, 56, 72, 16, DT_VCENTER Or DT_SINGLELINE, vbBlack, , True
   'draw bridge status change --- some unknown bug in FreeBasic compiler :-3
   nBridgeChangeCount = 0
   For i = 1 To GameW
    For j = 1 To GameH
     m = dL( j,i)
     Select Case m
     Case 100 To 115 'off
      pTheBitmapDraw3 bmG, Ani_Misc, 1, _
      GameLayer0SX + (i - 1) * 32 + (j - 1) * 10, _
      GameLayer0SY + 0 - ((i - 1) * 5) + ((j - 1) * 16), (m - 100) * 17
      dL( j,i) = m - 1
      nBridgeChangeCount = nBridgeChangeCount + 1
     Case 200 To 215 'on
      pTheBitmapDraw3 bmG, Ani_Misc, 2, _
      GameLayer0SX + (i - 1) * 32 + (j - 1) * 10, _
      GameLayer0SY + 0 - ((i - 1) * 5) + ((j - 1) * 16), (m - 200) * 17
      dL( j,i) = m - 1
      nBridgeChangeCount = nBridgeChangeCount + 1
     Case Else
      dL( j,i) = 0
     End Select
    Next j
   Next i
   'layer 1
   If IsSliping Then 'slip?
    Game_DrawLayer1 bmG, , True, idx, idx2, y2, , , x2, True
   ElseIf QIE_O > 0 And GameFS = 0 Then ':-/
    Game_DrawLayer1 bmG, , True, QIE_O, 8, y2, , , x2, True
   ElseIf QIE_O > 0 And (QIE_O > 2 Xor GameFS > 2) Then ':-/
    Select Case GameFS
    Case 1 'up
     Game_DrawLayer1 bmG, , True, QIE_O, 8, y2 - (16 * nAnimationIndex) \ 8, _
     , , x2 - (10 * nAnimationIndex) \ 8, True
    Case 2 'down
     Game_DrawLayer1 bmG, , True, QIE_O, 8, y2 + (16 * nAnimationIndex) \ 8, _
     , , x2 + (10 * nAnimationIndex) \ 8, True
    Case 3 'left
     Game_DrawLayer1 bmG, , True, QIE_O, 8, y2 + (5 * nAnimationIndex) \ 8, _
     , , x2 - (32 * nAnimationIndex) \ 8, True
    Case 4 'right
     Game_DrawLayer1 bmG, , True, QIE_O, 8, y2 - (5 * nAnimationIndex) \ 8, _
     , , x2 + (32 * nAnimationIndex) \ 8, True
    End Select
   Else
    Game_DrawLayer1 bmG, , True, idx, idx2
   End If
   'draw []
   Select Case kt
   Case 1 To 16
    pTheBitmapDraw3 bmG, Ani_Misc, 3, kx - 24, ky, 17 * (kt - 1)
    pTheBitmapDraw3 bmG, Ani_Misc, 4, kx + 24, ky, 17 * (kt - 1)
    kt = kt - 1
   Case 17 To 24
    pTheBitmapDraw3 bmG, Ani_Misc, 3, kx - 24, ky
    pTheBitmapDraw3 bmG, Ani_Misc, 4, kx + 24, ky
    kt = kt - 1
   Case 25 To 40
    pTheBitmapDraw3 bmG, Ani_Misc, 3, kx - kt, ky, 17 * (40 - kt)
    pTheBitmapDraw3 bmG, Ani_Misc, 4, kx + kt, ky, 17 * (40 - kt)
    kt = kt - 1
   End Select
   'draw menu
   If IsMouseIn Or IsMouseIn2 Then
    x = CreateSolidBrush(vbBlack)
    If IsMouseIn Then
     r.Left = 600
     r.Right = 632
    Else
     r.Left = 380
     r.Right = r.Left + 48
    End If
    FrameRect bmG, r, x
   End If
   Game_Paint
   bEnsureReDraw = False
  End If
  Sleep 10
  DoEvents
  'copy seed?
  'bad news: the same seed can generate different map each time :(
  'so copy level data instead
  If IsMouseIn2 AndAlso GameIsRndMap Then
   If SDL_GetMouseState(NULL, NULL) And SDL_BUTTON(1) Then
    'With Clipboard
    ' .Clear
    ' .SetText txtGame(0).Tag
    'End With
    Lev(GameLev)->CopyToClipboard
    IsMouseIn2 = False
   End If
  End If
  'menu
  GetAsyncKeyState = SDL_GetKeyState(NULL)
  If (IsMouseIn AndAlso (SDL_GetMouseState(NULL, NULL) And SDL_BUTTON(1)) <> 0) OrElse GetAsyncKeyState[SDLK_Escape] Then
   j = GetTickCount
   'GameClick = False
   PaintPicture bmG, bmG_Back
   i = Game_Menu_Loop
   Select Case i
   Case 1 'return
    Game_InitBack
   Case 2 'restart
    'animation
    For i = 255 To 0 Step -51
     _Cls bmG
     AlphaPaintPicture bmG_Back, bmG, 0, 0, 640, 480, 0, 0, i, False
     Game_Paint
     Sleep 10
     DoEvents
     If GameStatus < 0 Then Exit Sub
    Next i
    'over
    GameStatus = 1
   Case 3 'select level
    s = InputBox(Replace(objText.GetText("Level: (Max=%d)"), "%d", CStr(LevCount)), , CStr(GameLev))
    i = Val(s)
    If i > 0 AndAlso i <= LevCount AndAlso (i <> GameLev OrElse GameIsRndMap) Then 'valid
     'exit random mode
     If GameIsRndMap Then
      Lev(GameLev)->Clone @LevTemp
      GameIsRndMap = False
     End If
     GameLev = i
     'animation
     For i = 255 To 0 Step -51
      _Cls bmG
      AlphaPaintPicture bmG_Back, bmG, 0, 0, 640, 480, 0, 0, i, False
      Game_Paint
      Sleep 10
      DoEvents
      If GameStatus < 0 Then Exit Sub
     Next i
     'over
     GameStatus = 0
    Else
     Game_InitBack
    End If
   Case 4 'open file
    s = ""
    If cd.VBGetOpenFileName(s, , , , , True, objText.GetText("Turning Square level pack|*.box"), , App.Path) Then
     'exit random mode
     GameIsRndMap = False
     Game_LoadLevel s
     'animation
     For i = 255 To 0 Step -51
      _Cls bmG
      AlphaPaintPicture bmG_Back, bmG, 0, 0, 640, 480, 0, 0, i, False
      Game_Paint
      Sleep 10
      DoEvents
      If GameStatus < 0 Then Exit Sub
     Next i
     'over
     GameStatus = 0
    Else
     Game_InitBack
    End If
   Case 5 'new!!! random map
    'TODO:
    i = Game_RndMap_Loop
    Select Case i
    Case 1
     'animation
     For i = 255 To 0 Step -51
      _Cls bmG
      AlphaPaintPicture bmG_Back, bmG, 0, 0, 640, 480, 0, 0, i, False
      Game_Paint
      Sleep 10
      DoEvents
      If GameStatus < 0 Then Exit Sub
     Next i
     'over
     GameStatus = 0
    End Select
    Game_InitBack
   Case 6 'input solution
    txtGame(0).Text = sSolution
    txtGame(0).Locked = False
    i = Game_TextBox_Loop
    Select Case i
    Case 1
     'animation
     For i = 255 To 0 Step -51
      _Cls bmG
      AlphaPaintPicture bmG_Back, bmG, 0, 0, 640, 480, 0, 0, i, False
      Game_Paint
      Sleep 10
      DoEvents
      If GameStatus < 0 Then Exit Sub
     Next i
     'over
     GameStatus = 1
     GameDemoS = LCase(txtGame(0).Text)
     GameDemoBegin = True
    End Select
    Game_InitBack
   Case 7 'solve it
    objCallback.SolveItCallBack=ProcPtr(MyCallback)
    If Lev(GameLev)->SolveIt(@objCallback) Then
     m = Lev(GameLev)->SolveItGetSolutionNodeIndex
     If m > 0 Then
      GameDemoS = Lev(GameLev)->SolveItGetSolution(m)
      's = Replace(GameDemoS, "u", objText.GetText("U")) '"¡ü"
      's = Replace(s, "d", objText.GetText("D")) '"¡ý"
      's = Replace(s, "l", objText.GetText("L")) '"¡û"
      's = Replace(s, "r", objText.GetText("R")) '"¡ú"
      's = Replace(s, "s", objText.GetText("S")) '"¡ó"
      s = GameDemoS
      txtGame(0).Text = s + !"\r\n" + objText.GetText("Moves:") + CStr(Lev(GameLev)->SolveItGetDistance(m))
      txtGame(0).Locked = True
      i = Game_TextBox_Loop
      Select Case i
      Case 1
       'animation
       For i = 255 To 0 Step -51
        _Cls bmG
        AlphaPaintPicture bmG_Back, bmG, 0, 0, 640, 480, 0, 0, i, False
        Game_Paint
        Sleep 10
        DoEvents
        If GameStatus < 0 Then Exit Sub
       Next i
       'over
       GameStatus = 1
       GameDemoBegin = True
      End Select
      Game_InitBack
     Else
      MsgBox objText.GetText("No solution!")
     End If
    Else
     MsgBox objText.GetText("Error!")
    End If
    Lev(GameLev)->SolveItClear 'the missing code!
    Game_InitBack
   Case 8 'instruction
    'animation
    For i = 255 To 0 Step -51
     _Cls bmG
     AlphaPaintPicture bmG_Back, bmG, 0, 0, 640, 480, 0, 0, i, False
     Game_Paint
     Sleep 10
     DoEvents
     If GameStatus < 0 Then Exit Sub
    Next i
    Game_Instruction_Loop
    'animation
    For i = 0 To 255 Step 51
     _Cls bmG
     AlphaPaintPicture bmG_Back, bmG, 0, 0, 640, 480, 0, 0, i, False
     Game_Paint
     Sleep 10
     DoEvents
     If GameStatus < 0 Then Exit Sub
    Next i
    'over
    Game_InitBack
   Case GameMenuItemCount - 1
    GameStatus = -1
   Case GameMenuItemCount
    GameStatus = -2
   End Select
   GameLvStartTime = GameLvStartTime + (GetTickCount - j)
   'GameClick = False
   bEnsureReDraw = True
  End If
  'exit??
  If GameStatus < 0 Then Exit Sub
 Case Else 'err?
  Sleep 10
  DoEvents
  If GameStatus < 0 Then Exit Sub
 End Select
Loop
End Sub

Sub Form_Load()
'////////original code TODO:
'pShowPanel 0
'p0(1).Move 0, 0, 640, 480
'p0(3).Height = 472
'Set sEdit = New cScrollBar
'With sEdit
' .Create pEdit.hwnd
' .Visible(efsHorizontal) = True
' .Visible(efsVertical) = True
' .Enabled(efsHorizontal) = False
' .Enabled(efsVertical) = False
' .SmallChange(efsHorizontal) = 10
' .SmallChange(efsVertical) = 10
'End With
pInitBitmap
bmG_Back=SDL_CreateRGBSurface(SDL_HWSURFACE, 640, 480, 32, &H00ff0000,&H0000ff00,&H000000ff,0)
bmG_Lv=SDL_CreateRGBSurface(SDL_HWSURFACE, 640, 480, 32, &H00ff0000,&H0000ff00,&H000000ff,0)
'With cmbBehavior
' .AddItem objText.GetText("Close")
' .AddItem objText.GetText("Open")
' .AddItem objText.GetText("Toggle")
'End With
cmbMode_List(0) = objText.GetText("Beginner")
cmbMode_List(1) = objText.GetText("Intermediate")
cmbMode_List(2) = objText.GetText("Advanced")
cmbMode_List(3) = objText.GetText("Zigzag")
cmbMode_List(4) = objText.GetText("Ice mode")
cmbMode_List(5) = objText.GetText("Fragile mode")
cmbMode_List(6) = objText.GetText("Zigzag with button")
cmbMode_ListCount = 7
cmbMode_ListIndex = 2
'pEditSelect
''///
'cmdEdit(17).Caption = objText.GetText("&Close")
'cmdEdit(16).Caption = objText.GetText("&Generate")
'chk1(0).Caption = objText.GetText("Use current level as template")
'chk1(1).Caption = objText.GetText("Sort random levels by moves")
'Frame1(2).Caption = objText.GetText("Random map")
'Label1(16).Caption = objText.GetText("Mode")
'Label1(17).Caption = objText.GetText("Seed")
'Label1(18).Caption = objText.GetText("Iterations")
'Label1(21).Caption = objText.GetText("Level count")
'cmdEdit(14).Caption = objText.GetText("&Solution")
'optSt(3).Caption = objText.GetText("Single")
'optSt(2).Caption = objText.GetText("Vertical")
'optSt(1).Caption = objText.GetText("Horizontal")
'optSt(0).Caption = objText.GetText("Up")
'cmdEdit(13).Caption = objText.GetText("&Close")
'cmdEdit(18).Caption = objText.GetText("Random Map(Beta)")
'chkPos(3).Caption = objText.GetText("Set")
'chkPos(2).Caption = objText.GetText("Set")
'chkPos(1).Caption = objText.GetText("Set")
'chkPos(0).Caption = objText.GetText("Set")
'cmdEdit(15).Caption = objText.GetText("&Clear")
'cmdEdit(12).Caption = objText.GetText("Solve...")
'cmdEdit(11).Caption = objText.GetText("Clear")
'optMode(1).Caption = objText.GetText("Select")
'optMode(0).Caption = objText.GetText("Edit")
'Label1(2).Caption = objText.GetText("Pos2")
'Label1(1).Caption = objText.GetText("Pos1")
'Label1(0).Caption = objText.GetText("Button number")
'Frame1(0).Caption = objText.GetText("Properties")
'Label1(5).Caption = objText.GetText("No properties.")
'cmdEdit(6).Caption = objText.GetText("&Resize")
'cmdEdit(5).Caption = objText.GetText("&Delete")
'cmdEdit(4).Caption = objText.GetText("&Add")
'cmdEdit(3).Caption = objText.GetText("&Quit")
'cmdEdit(2).Caption = objText.GetText("&Save")
'cmdEdit(1).Caption = objText.GetText("&Open")
'cmdEdit(0).Caption = objText.GetText("&New")
'Frame1(1).Caption = objText.GetText("Buttons")
'Label1(9).Caption = objText.GetText("Behavior")
'Label1(7).Caption = objText.GetText("Pos")
'Label1(6).Caption = objText.GetText("No.")
'Label1(12).Caption = objText.GetText("Start pos")
'Label1(11).Caption = objText.GetText("Solving...")
'Label1(10).Caption = objText.GetText("Solving...")
'mnuLv(0).Caption = objText.GetText("&Copy Level") + vbTab + "Ctrl+C"
'mnuLv(1).Caption = objText.GetText("&Paste Level") + vbTab + "Ctrl+V"
'mnuLv(3).Caption = objText.GetText("Rotate 90 C&W")
'mnuLv(4).Caption = objText.GetText("Rotate 90 &CCW")
'mnuLv(5).Caption = objText.GetText("&Rotate 180")
'mnuLv(7).Caption = objText.GetText("Flip &Horizontally")
'mnuLv(8).Caption = objText.GetText("Flip &Vertically")
''///
'////////run main loop
'TODO:
dim event as SDL_Event
dim x as long,y as long
dim i as long
dim nPressed as long = 1

Do Until GameStatus <= -2
 GameStatus = -1
 '///
 If nPressed Then
  PaintPicture(bmImg(4),bmG_Back)
  DrawTextB(bmG_Back,objText.GetText("Turning Square"),m_objFont(2),0,40,640,80,DT_CENTER or DT_VCENTER or DT_SINGLELINE,&H80FF&,,True)
  '//
  DrawTextB(bmG_Back,objText.GetText("Start game"),m_objFont(1),0,200,640,60,DT_CENTER or DT_VCENTER or DT_SINGLELINE,&H80FF&,,True)
  DrawTextB(bmG_Back,objText.GetText("Game instructions"),m_objFont(1),0,260,640,60,DT_CENTER or DT_VCENTER or DT_SINGLELINE,&H80FF&,,True) 
  DrawTextB(bmG_Back,objText.GetText("Editor/Solver"),m_objFont(1),0,320,640,60,DT_CENTER or DT_VCENTER or DT_SINGLELINE,&H80FF&,,True) 
  DrawTextB(bmG_Back,objText.GetText("Exit game"),m_objFont(1),0,380,640,60,DT_CENTER or DT_VCENTER or DT_SINGLELINE,&H80FF&,,True)
 End If
 '///get messages
 nPressed = 0
 Do While SDL_PollEvent(@event)
  Select Case event.type
  Case SDL_QUIT_
   GameStatus = -2
   Exit Do
  case SDL_MOUSEBUTTONDOWN
   if event.button.button = SDL_BUTTON_LEFT then nPressed = 10
  End Select
 Loop
 If GameStatus <= -2 Then Exit Do
 '///test only
 PaintPicture(bmG_Back,video)
 '//
 SDL_GetMouseState(@x,@y)
 if x>=40 and x<600 then
  if y>=200 and y<440 then
   i=(y-140)\60
   if nPressed then nPressed=i
   rectangleColor video,44,i*60+144,596,i*60+196,&HFF8000FF
  end if 
 end if
 '//
 Game_Paint
 '///
 Select Case nPressed
 Case 1
  Game_Init
 Case 2
  GameStatus = 0
  Game_Instruction_Loop
 Case 3
  'TODO:
 Case 4
  Exit Do
 Case Else
  nPressed = 0
 End Select
 '///
 Sleep 30
Loop

'////////over, free resource

For i=LBound(Anis) To UBound(Anis)
 Deallocate Anis(i).bm
 Anis(i).bm=NULL
Next i

'TODO:free other

End Sub

Function _LoadPictureFromFile(ByRef _FileName As String,ByRef _MaskFile As String="") As SDL_Surface ptr
dim as SDL_Surface ptr bm,bmMask,bm_1,bmMask_1
dim i as long
dim as UByte ptr lp1,lp2
'///
bm=IMG_Load(strptr(_FileName))
if bm=NULL then abort
if _MaskFile="" then return bm
bmMask=IMG_Load(strptr(_MaskFile))
if bmMask=NULL then abort
'///
bm_1=SDL_ConvertSurface(bm,@m_fmtAlpha,SDL_SWSURFACE or SDL_SRCALPHA)
if bm_1=NULL then abort
bmMask_1=SDL_ConvertSurface(bmMask,@m_fmtAlpha,SDL_SWSURFACE)
if bmMask_1=NULL then abort
SDL_FreeSurface bm
SDL_FreeSurface bmMask
'///
SDL_LockSurface bm_1
SDL_LockSurface bmMask_1
'///
lp1=bm_1->pixels+3
lp2=bmMask_1->pixels
for i=1 to bm_1->w*bm_1->h
 *lp1=*lp2
 lp1+=4
 lp2+=4
next i
'///
SDL_UnlockSurface bm_1
SDL_UnlockSurface bmMask_1
SDL_FreeSurface bmMask_1
'///
Return bm_1
End Function

'i0(0) block.jpg
'i0(1) block_mask.gif
'i0(2) shadow.jpg
'i0(3) shadow_mask.gif
'i0(4) edit.gif
'i0(5) block2.jpg
'i0(6) block2_mask.gif
'i0(7) back.jpg
Sub pInitBitmap()
Dim b() As Byte, b2() As Byte
Dim i As Long, m As Long
'bmG.Create 640, 480
'//////////////////load block
bmImg(0) = _LoadPictureFromFile(App.Path+"data/block.jpg",App.Path+"data/block_mask.png")
'//////////////////load shadow
bmImg(1) = _LoadPictureFromFile(App.Path+"data/shadow.jpg",App.Path+"data/shadow_mask.png")
'//////////////////load edit
bmImg(2) = _LoadPictureFromFile(App.Path+"data/edit.png")
'//////////////////load block2
bmImg(3) = _LoadPictureFromFile(App.Path+"data/block2.jpg",App.Path+"data/block2_mask.png")
'//////////////////new: load back
bmImg(4) = _LoadPictureFromFile(App.Path+"data/back.jpg")
'//////////////////load bitmap data
For i = LBound(bmps) To UBound(bmps)
 bmps(i).ImgIndex = -1
Next i
With objFile
 if .LoadFile(App.Path+"data/data.dat",NULL,True)=0 then abort
 .GetNodeData 1, 1, b()
 pLoadBitmapData b(), 0
 .GetNodeData 1, 2, b()
 pLoadBitmapData b(), 1
 .Clear
End With
'//////////////////load bitmap array
ReDim Anis(1 To 100)
'layer 0
With Anis(Ani_Layer0)
 .bm=callocate(12,sizeof(typeTheBitmap3))
 .bm[0].ImgIndex = -1 'empty
 pTheBitmapConvert bmps(108), .bm[1], 4, 8 'block
 pTheBitmapConvert bmps(119), .bm[2], 4, 8 'soft
 pTheBitmapConvert bmps(120), .bm[3], 4, 8 'heavy
 pTheBitmapConvert bmps(130), .bm[4], 4, 10 'transport
 pTheBitmapConvert bmps(131), .bm[5], 4, 8 'thin
 .bm[6] = .bm[0] 'bridge off
 With .bm[7] 'bridge on
  .ImgIndex = 3
  .x = 44
  .y = 28
  .w = 44
  .h = 28
  .dX = 0
  .dy = 5
 End With
 pTheBitmapConvert bmps(121), .bm[8], 5, 11 'end
 With .bm[9] 'ice
  .ImgIndex = 3
  .x = 0
  .y = 0
  .w = 44
  .h = 28
  .dX = 0
  .dy = 5
 End With
 With .bm[10] 'pyramid
  .ImgIndex = 3
  .x = 0
  .y = 28
  .w = 44
  .h = 28
  .dX = 0
  .dy = 5
 End With
 .bm[11] = .bm[1] 'stone TODO:layer 1
End With
'///////////////////////////////////////////////////////box animation
'state=up,direction=up
pInitBoxAnimation 1, 10, 366, 80, 98
'state=up,direction=down
pInitBoxAnimation 2, 10, 386, 80, 98
'state=up,direction=left
With Anis(3)
 .Count = 9
 .bm=callocate(.Count+1,sizeof(typeTheBitmap3))
 For i = 1 To 7
  pTheBitmapConvert bmps(i + 28), .bm[i], 80, 98
 Next i
 For i = 8 To 9
  pTheBitmapConvert bmps(i + 1), .bm[i], 80, 98
 Next i
End With
'state=up,direction=right
pInitBoxAnimation 4, 10, 376, 80, 98
'state=h,direction=up
pInitBoxAnimation 5, 9, 10, 80, 98
'state=h,direction=down
pInitBoxAnimation 6, 10, 448, 80, 98 'count=11?
'state=h,direction=left
pInitBoxAnimation 7, 9, 19, 80, 98
'state=h,direction=right
pInitBoxAnimation 8, 10, 438, 80, 98
'state=v,direction=up
pInitBoxAnimation 9, 10, 406, 70, 82
'state=v,direction=down
pInitBoxAnimation 10, 10, 426, 70, 82
'state=v,direction=left
pInitBoxAnimation 11, 10, 396, 70, 82
'state=v,direction=right
pInitBoxAnimation 12, 10, 416, 70, 82
'state=single,direction=up
pInitBoxAnimation 13, 10, 316, 80, 98
'state=single,direction=down
pInitBoxAnimation 14, 9, 336, 80, 98
'state=single,direction=left
pInitBoxAnimation 15, 9, 307, 80, 98
'state=single,direction=right
pInitBoxAnimation 16, 10, 326, 80, 98
'start
pInitBoxAnimation 29, 12, 504, 80, 98
'end
pInitBoxAnimation 30, 8, 516, 80, 98
'///////////////////////////////////////////////////////box shadow animation
'state=up,direction=up
pInitBoxAnimation 31, 10, 141, 80, 98
'state=up,direction=down
pInitBoxAnimation 32, 10, 161, 80, 98
'state=up,direction=left
pInitBoxAnimation 33, 9, 131, 80, 98
'state=up,direction=right
pInitBoxAnimation 34, 10, 151, 80, 98
'state=h,direction=up
pInitBoxAnimation 35, 9, 221, 80, 98
'state=h,direction=down
pInitBoxAnimation 36, 10, 241, 80, 98
'state=h,direction=left
pInitBoxAnimation 37, 9, 211, 80, 98
'state=h,direction=right
pInitBoxAnimation 38, 10, 231, 37, 98 '?
'state=v,direction=up
pInitBoxAnimation 39, 10, 181, 70, 82
'state=v,direction=down
pInitBoxAnimation 40, 10, 201, 70, 82
'state=v,direction=left
pInitBoxAnimation 41, 10, 171, 70, 82
'state=v,direction=right
pInitBoxAnimation 42, 10, 191, 70, 82
'state=single,direction=up
pInitBoxAnimation 43, 10, 275, 80, 98
'state=single,direction=down
pInitBoxAnimation 44, 9, 295, 80, 98
'state=single,direction=left
pInitBoxAnimation 45, 9, 265, 80, 98
'state=single,direction=right
pInitBoxAnimation 46, 10, 285, 80, 98
'start
pInitBoxAnimation 59, 12, 253, 80, 98
'///////////////////////////////////////////////////////fall animation
'state=up,dir=up
pInitBoxAnimation 71, 9, 35, 80, 98, True
'state=up,dir=down
pInitBoxAnimation 72, 9, 35, 80, 98
'state=up,dir=left
pInitBoxAnimation 73, 9, 459, 80, 98
'state=up,dir=right
pInitBoxAnimation 74, 9, 459, 80, 98, True
'state=h,dir=up
pInitBoxAnimation 75, 9, 494, 80, 98, True
'state=h,dir=down
pInitBoxAnimation 76, 9, 494, 80, 98
'state=h,dir=left
pInitBoxAnimation 77, 9, 485, 80, 98
'state=h,dir=right
pInitBoxAnimation 78, 9, 485, 80, 98, True
'state=v,dir=up
pInitBoxAnimation 79, 9, 467, 70, 82
'state=v,dir=down
pInitBoxAnimation 80, 9, 467, 70, 82, True
'state=v,dir=left
pInitBoxAnimation 81, 9, 476, 70, 82, True
'state=v,dir=right
pInitBoxAnimation 82, 9, 476, 70, 82
'state=single,dir=up
pInitBoxAnimation 83, 9, 356, 80, 98
'state=single,dir=down
pInitBoxAnimation 84, 9, 356, 80, 98, True
'state=single,dir=left
pInitBoxAnimation 85, 9, 347, 80, 98
'state=single,dir=right
pInitBoxAnimation 86, 9, 347, 80, 98, True
'misc
With Anis(Ani_Misc)
 .bm=callocate(21,sizeof(typeTheBitmap3))
 With .bm[1] 'bridge off
  .ImgIndex = 3
  .x = 88
  .y = 0
  .w = 44
  .h = 28
  .dX = 0
  .dy = 5
 End With
 With .bm[2] 'bridge on
  .ImgIndex = 3
  .x = 44
  .y = 0
  .w = 44
  .h = 28
  .dX = 0
  .dy = 5
 End With
 With .bm[3] '"["
  .ImgIndex = 0
  .w = bmps(307).w \ 2
  .h = bmps(307).h
  .x = bmps(307).x
  .y = bmps(307).y
  .dX = .w
  .dy = .h \ 2
 End With
 With .bm[4] '"]"
  .ImgIndex = 0
  .w = bmps(307).w \ 2
  .h = bmps(307).h
  .x = bmps(307).x + .w
  .y = bmps(307).y
  .dX = 0
  .dy = .h \ 2
 End With
 pTheBitmapConvert bmps(504), .bm[5], 80, 98 'blur box
 With .bm[6] 'box
  .ImgIndex = 3
  .x = 228
  .y = 0
  .w = 44
  .h = 52 '53?
  .dX = 0
  .dy = 34
 End With
End With
'//////////////////
End Sub

Sub pInitBoxAnimation(ByVal Index As Long, ByVal Count As Long, ByVal Offset As Long, ByVal NewX As Long=0, ByVal NewY As Long=0, ByVal IsReverse As Boolean=False)
Dim i As Long
With Anis(Index)
 .Count = Count
 .bm=callocate(Count+1,sizeof(typeTheBitmap3))
 If IsReverse Then
  pTheBitmapConvert bmps(1 + Offset), .bm[1], NewX, NewY
  For i = 2 To Count
   pTheBitmapConvert bmps(i + Offset), .bm[Count + 2 - i], NewX, NewY
  Next i
 Else
  For i = 1 To Count
   pTheBitmapConvert bmps(i + Offset), .bm[i], NewX, NewY
  Next i
 End If
End With
End Sub

Sub pTheBitmapConvert(bm As typeTheBitmap2, ret As typeTheBitmap3, ByVal NewX As Long=0, ByVal NewY As Long=0)
With ret
 .ImgIndex = bm.ImgIndex
 .x = bm.x
 .y = bm.y
 .w = bm.w
 .h = bm.h
 .dX = NewX - bm.dX
 .dy = NewY - bm.dy
End With
End Sub

Sub pLoadBitmapData(b() As Byte, ByVal Index As Long)
Dim i As Long, j As Long, m As Long
Dim lp As Byte ptr
lp = @b(LBound(b))
memcpy @m, lp, 4&
lp = lp + 4
For i = 1 To m
 memcpy @j, lp, 4
 lp = lp + 4
 With bmps(j)
  .ImgIndex = Index
  memcpy @.x, lp, 32&


  lp = lp + 32
 End With
Next i
End Sub

Sub Game_DrawLayer1(ByVal hdc As SDL_Surface ptr, ByVal DrawBox As Boolean = True, ByVal DrawBoxShadow As Boolean = False, ByVal Index As Long = 0, ByVal Index2 As Long = 0, ByVal BoxDeltaY As Long = 0, ByVal BoxAlpha As Long = 255, ByVal WithLayer0 As Boolean = False, ByVal BoxDeltaX As Long = 0, ByVal NoZDepth As Boolean = False)
Dim i As Long, j As Long
Dim x As Long, y As Long, x2 As Long, y2 As Long, dy As Long
Dim FS As Long '1=for j,i 2=for i,j
Dim bx As Boolean
dy = BoxDeltaY
If NoZDepth Then BoxDeltaY = 0
'determine draw direction
Select Case GameFS
Case 0, 1, 2, 3, 4 '???
 Select Case GameS
 Case 0, 1, 3
  FS = 1
 Case 2
  FS = 2
 End Select
Case 1, 2 ', 5, 6 'up
 FS = 2
Case 3, 4 ', 7, 8
 FS = 1
End Select
bx = BoxDeltaY >= 0 And BoxDeltaY <= 32
'draw box first?
If DrawBox And (BoxDeltaY > 32 Or GameX > GameW Or GameY < 1) Then
 x = GameLayer0SX + (GameX - 1) * 32 + (GameY - 1) * 10 + BoxDeltaX
 y = GameLayer0SY - (GameX - 1) * 5 + (GameY - 1) * 16 + dy
 If DrawBoxShadow Then
  pGameDrawBox hdc, Index, Index2, x, y, BoxAlpha
 Else
  pTheBitmapDraw3 hdc, Index, Index2, x, y, BoxAlpha
 End If
End If
'draw
Select Case FS
Case 1
 x = GameLayer0SX + GameW * 32
 y = GameLayer0SY - GameW * 5
 For j = 1 To GameH
  x2 = x
  y2 = y
  For i = GameW To 1 Step -1
   x2 = x2 - 32
   y2 = y2 + 5
   If WithLayer0 Then pTheBitmapDraw3 hdc, Ani_Layer0, GameD( j,i), x2, y2
   Select Case GameD( j,i)
   Case 11
    pTheBitmapDraw3 hdc, Ani_Misc, 6, x2, y2
   End Select
   'draw box?
   If DrawBox And GameX = i And GameY = j And bx Then
    If DrawBoxShadow Then
     pGameDrawBox hdc, Index, Index2, x2 + BoxDeltaX, y2 + dy, BoxAlpha
    Else
     pTheBitmapDraw3 hdc, Index, Index2, x2 + BoxDeltaX, y2 + dy, BoxAlpha
    End If
   End If
   'draw box 2?
   If DrawBox And GameX2 = i And GameY2 = j And GameS = 3 Then
    If DrawBoxShadow Then
     pGameDrawBox hdc, 13, 1, x2, y2, BoxAlpha
    Else
     pTheBitmapDraw3 hdc, 13, 1, x2, y2, BoxAlpha
    End If
   End If
  Next i
  x = x + 10
  y = y + 16
 Next j
Case 2
 x = GameLayer0SX + GameW * 32
 y = GameLayer0SY - GameW * 5
 For i = GameW To 1 Step -1
  x = x - 32
  y = y + 5
  x2 = x
  y2 = y
  For j = 1 To GameH
   If WithLayer0 Then pTheBitmapDraw3 hdc, Ani_Layer0, GameD( j,i), x2, y2
   Select Case GameD( j,i)
   Case 11
    pTheBitmapDraw3 hdc, Ani_Misc, 6, x2, y2
   End Select
   'draw box?
   If DrawBox And GameX = i And GameY = j And bx Then
    If DrawBoxShadow Then
     pGameDrawBox hdc, Index, Index2, x2 + BoxDeltaX, y2 + dy, BoxAlpha
    Else
     pTheBitmapDraw3 hdc, Index, Index2, x2 + BoxDeltaX, y2 + dy, BoxAlpha
    End If
   End If
   'draw box 2?
   If DrawBox And GameX2 = i And GameY2 = j And GameS = 3 Then
    If DrawBoxShadow Then
     pGameDrawBox hdc, 13, 1, x2, y2, BoxAlpha
    Else
     pTheBitmapDraw3 hdc, 13, 1, x2, y2, BoxAlpha
    End If
   End If
   x2 = x2 + 10
   y2 = y2 + 16
  Next j
 Next i
End Select
'draw box last?
If DrawBox And (BoxDeltaY < 0 Or GameX < 1 Or GameY > GameH) Then
 x = GameLayer0SX + (GameX - 1) * 32 + (GameY - 1) * 10 + BoxDeltaX
 y = GameLayer0SY - (GameX - 1) * 5 + (GameY - 1) * 16 + dy
 If DrawBoxShadow Then
  pGameDrawBox hdc, Index, Index2, x, y, BoxAlpha
 Else
  pTheBitmapDraw3 hdc, Index, Index2, x, y, BoxAlpha
 End If
End If
End Sub

Sub pTheBitmapDraw2(ByVal hdc As SDL_Surface ptr, ByVal Index As Long, ByVal x As Long, ByVal y As Long, ByVal Alpha As Long = 255)
With bmps(Index)
 If .ImgIndex >= 0 Then
  AlphaPaintPicture bmImg(.ImgIndex), hdc, x - .dX, y - .dy, .w, .h, .x, .y, Alpha, True
 End If
End With
End Sub

Sub pTheBitmapDraw3(ByVal hdc As SDL_Surface ptr, ByVal Index As Long, ByVal Index2 As Long, ByVal x As Long, ByVal y As Long, ByVal Alpha As Long = 255)
With Anis(Index).bm[Index2]
 If .ImgIndex >= 0 Then
  AlphaPaintPicture bmImg(.ImgIndex), hdc, x - .dX, y - .dy, .w, .h, .x, .y, Alpha, True
 End If
End With
End Sub

Sub pGameDrawBox(ByVal hdc As SDL_Surface ptr, ByVal Index As Long, ByVal Index2 As Long, ByVal x As Long, ByVal y As Long, ByVal Alpha As Long = 255)
With Anis(Index + 30)
 If Index2 <= .Count Then
  With .bm[Index2]
   If .ImgIndex >= 0 Then
    AlphaPaintPicture bmImg(.ImgIndex), hdc, x - .dX, y - .dy, .w, .h, .x, .y, Alpha \ 2, True
   End If
  End With
 End If
End With
With Anis(Index).bm[Index2]
 If .ImgIndex >= 0 Then
  AlphaPaintPicture bmImg(.ImgIndex), hdc, x - .dX, y - .dy, .w, .h, .x, .y, Alpha, True
 End If
End With
End Sub

Sub pGameDrawLayer0(ByVal hdc As SDL_Surface ptr, d() As Byte, ByVal datw As Long, ByVal dath As Long, ByVal StartX As Long, ByVal StartY As Long)
Dim i As Long, j As Long, x As Long, y As Long
StartX = StartX + datw * 32
StartY = StartY - datw * 5
For i = datw To 1 Step -1
 StartX = StartX - 32
 StartY = StartY + 5
 x = StartX
 y = StartY
 For j = 1 To dath
  pTheBitmapDraw3 hdc, Ani_Layer0, d(j,i), x, y
  x = x + 10
  y = y + 16
 Next j
Next i
End Sub

Private Sub Game_Instruction_Loop()
Const sSource1 As String = "http://code.google.com/p/turningpolyhedron/"
Const Label1_15_Caption As String = "http://www.miniclip.com/games/bloxorz/en/"
Dim i As Long, j As Long, p As POINTAPI, r As RECT
Dim x As Long, y As Long, x2 As Long, y2 As Long
Dim hbr As Long
Dim b1 As Boolean, bc1 As Boolean, b2 As Boolean
Dim b1a As Boolean, bc1a As Boolean
Dim b1b As Boolean, bc1b As Boolean
Dim s As String, s1 As String
'init
hbr = CreateSolidBrush(&H80FF&)
_Cls(bmG)
Game_Paint
'draw
PaintPicture bmImg(4),bmG_Back
'////////////////////////////////////////////'map 1
x = 572
y = 32
For j = 1 To 3
 x2 = x
 y2 = y
 For i = 6 To 1 Step -1
  If i = 5 And j = 2 Then
   pTheBitmapDraw3 bmG_Back, Ani_Layer0, 8, x2, y2
  Else
   pTheBitmapDraw3 bmG_Back, Ani_Layer0, 1, x2, y2
  End If
  x2 = x2 - 32
  y2 = y2 + 5
 Next i
 x = x + 10
 y = y + 16
Next j
pGameDrawBox bmG_Back, 1, 1, 454, 68
'////////////////////////////////////////////'map 2
x = 572
y = 128
For j = 1 To 3
 x2 = x
 y2 = y
 For i = 6 To 1 Step -1
  If i = 3 Or i = 4 Then
   If j = 2 Then pTheBitmapDraw3 bmG_Back, Ani_Layer0, 7, x2, y2
  ElseIf i = 1 And j = 1 Then
   pTheBitmapDraw3 bmG_Back, Ani_Layer0, 2, x2, y2
  ElseIf i = 6 And j = 1 Then
   pTheBitmapDraw3 bmG_Back, Ani_Layer0, 3, x2, y2
  Else
   pTheBitmapDraw3 bmG_Back, Ani_Layer0, 1, x2, y2
  End If
  x2 = x2 - 32
  y2 = y2 + 5
 Next i
 x = x + 10
 y = y + 16
Next j
'////////////////////////////////////////////'map 3
x = 572
y = 224
For j = 1 To 3
 x2 = x
 y2 = y
 For i = 6 To 1 Step -1
  If i = 3 Or i = 4 Then
   pTheBitmapDraw3 bmG_Back, Ani_Layer0, 5, x2, y2
  ElseIf i = 5 And j = 2 Then
   pTheBitmapDraw3 bmG_Back, Ani_Layer0, 4, x2, y2
  Else
   pTheBitmapDraw3 bmG_Back, Ani_Layer0, 1, x2, y2
  End If
  x2 = x2 - 32
  y2 = y2 + 5
 Next i
 x = x + 10
 y = y + 16
Next j
pGameDrawBox bmG_Back, 13, 1, 444, 244
pGameDrawBox bmG_Back, 13, 1, 432, 281
'////////////////////////////////////////////'map 4
x = 572
y = 320
For j = 1 To 3
 x2 = x
 y2 = y
 For i = 6 To 1 Step -1
  If i = 4 And j = 3 Then
   pTheBitmapDraw3 bmG_Back, Ani_Layer0, 10, x2, y2
  ElseIf (i < 3 And j < 3) Or i > 4 Then
   pTheBitmapDraw3 bmG_Back, Ani_Layer0, 1, x2, y2
  Else
   pTheBitmapDraw3 bmG_Back, Ani_Layer0, 9, x2, y2
  End If
  If (i < 3 And j < 3) Or (i = 6 And j = 2) Then
   pTheBitmapDraw3 bmG_Back, Ani_Misc, 6, x2, y2
  End If
  x2 = x2 - 32
  y2 = y2 + 5
 Next i
 x = x + 10
 y = y + 16
Next j
pTheBitmapDraw3 bmG_Back, 4, 7, 523, 345
'////////////////////////////////////////////
'////////
With objText
 s = Space(8) + .GetText("Turning Square is a clone and enhancement to popular game Bloxorz. The aim of the game is to get the block to fall into the square hole at the end of each level. There are 33 levels in default level pack, and many levels in other level pack. You can make your own levels using level editor, or explore completely new levels using random level generator.")
 s = s + !"\n" + Space(8) + .GetText("To move the block around the world, use the UP DOWN LEFT and RIGHT arrow keys. Be careful not to fall off the edges - the level will be restarted.")
 s = s + !"\n" + Space(8) + .GetText("Bridges and switches are located in many levels. The switches are activated when they are pressed down by the block. You don't need to stay resting on the switch to keep bridges open. There are two types of switches: 'Heavy' X-shaped ones and 'Soft' round ones. Soft switches are activated when any part of your block presses it. Hard switches require much more pressure, so your block must be standing on its end to activate it. When activated, each switch may behave differently. Some will toggle the bridge state each time it is used. Some will only ever make certain bridges open, and activating it again will not make it close. Green or red colored squares will flash to indicate which bridges are being operated.")
 s = s + !"\n" + Space(8) + .GetText("Orange tiles are more fragile than the rest of the land. If your block stands up vertically on an orange tile, the tile will give way and your block will fall.")
 s = s + !"\n" + Space(8) + .GetText("The tile shaped like two brackets will teleports your block to different locations, splitting it into two smaller blocks at the same time. These can be controlled individually by pressing the SPACE BAR and will rejoin into a normal block when both are placed next to each other. Small blocks can still operate soft switches, but they're too small to activate heavy switches. Also small blocks can't go through the exit hole - only a complete block can finish the level.")
 s = s + !"\n" + Space(8) + .GetText("There are some new tiles in Turning Square: pyramid, ice and wall. Your block is unstable when standing on the pyramid, so it will lie down immediately unless there is a wall next to your block. When the block is completely on the ice, it will slip until get off the ice or hit the wall. As an obstacle, your block can't pass through the wall, but it can recline on the wall and move around.")
 s = s + .GetText("(ANIMATION IS BROKEN)")
End With
 DrawTextB bmG_Back, s, m_objFont(0), 8, 8, 400, 400, DT_EXPANDTABS Or DT_WORDBREAK, vbWhite, , True
 s = Replace(objText.GetText("VB6 version, author: "),"VB6","FreeBasic") + "acme_pjz"
 DrawTextB bmG_Back, s, m_objFont(0), 8, 408, 320, 16, DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
 s = objText.GetText("Source code:")
 DrawTextB bmG_Back, s, m_objFont(0), 8, 424, 256, 16, DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
 s = objText.GetText("Original version:")
 DrawTextB bmG_Back, s, m_objFont(0), 8, 456, 96, 16, DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
 DrawTextB bmG_Back, objText.GetText("OK"), m_objFont(0), 568, 456, 64, 16, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
 '///
 DrawTextB bmG_Back, Label1_15_Caption, m_objFont(0), 100, 456, 220, 16, DT_VCENTER Or DT_SINGLELINE, &HFF8000, , True
 DrawTextB bmG_Back, sSource1, m_objFont(0), 100, 424, 230, 16, DT_VCENTER Or DT_SINGLELINE, &HFF8000, , True
'animation
For i = 0 To 255 Step 51
 _Cls(bmG)
 AlphaPaintPicture bmG_Back, bmG, 0, 0, 640, 480, 0, 0, i, False
 Game_Paint
 Sleep 10
 DoEvents
 If GameStatus < 0 Then Exit Sub
Next i
'loop
Do
 PaintPicture bmG_Back, bmG
 'get cursor pos
 i=SDL_GetMouseState(@p.x,@p.y) and SDL_BUTTON(1)
 'init button
 r.Left = 100
 r.Right = 340
 'mouse in button1a?
 r.Top = 424
 r.Bottom = 440
 b1a = PtInRect(r, p.x, p.y)
 If b1a Then
  DrawTextB bmG, sSource1, m_objFont(0), 100, 424, 256, 16, DT_VCENTER Or DT_SINGLELINE, &H80FF&, , True
 Else
  bc1a = False
 End If
 'mouse in button1b?
 'r.Top = 440
 'r.Bottom = 456
 'b1b = PtInRect(r, p.x, p.y)
 'If b1b Then
 ' DrawTextB bmG, sSource2, m_objFont(0), 100, 440, 256, 16, DT_VCENTER Or DT_SINGLELINE, &H80FF&, , True
 'Else
 ' bc1b = False
 'End If
 'mouse in button1?
 r.Top = 456
 r.Bottom = 472
 b1 = PtInRect(r, p.x, p.y)
 If b1 Then
  DrawTextB bmG, Label1_15_Caption, m_objFont(0), 100, 456, 256, 16, DT_VCENTER Or DT_SINGLELINE, &H80FF&, , True
 Else
  bc1 = False
 End If
 'mouse in button2?
 r.Left = 568
 r.Right = 632
 b2 = PtInRect(r, p.x, p.y)
 If b2 Then FrameRect bmG, r, hbr
 Game_Paint
 Sleep 20
 DoEvents
 'click button1?
 If b1<>0 And bc1=0 Then
  If i Then
   bc1 = True
   ShellExecute 0, "open", Label1_15_Caption, "", "", 5
  End If
 End If
 If b1a<>0 And bc1a=0 Then
  If i Then
   bc1a = True
   ShellExecute 0, "open", sSource1, "", "", 5
  End If
 End If
 'If b1b And Not bc1b Then
 ' If GetAsyncKeyState(1) And &H8000 Then
 '  bc1b = True
 '  ShellExecute 0, "open", sSource2, "", "", 5
 ' End If
 'End If
 'click exit button?
 If b2 Then
  If i Then Exit Do
 End If
 If GameStatus < 0 Then
  Exit Sub
 End If
Loop
'animation
For i = 255 To 0 Step -51
 _Cls bmG
 AlphaPaintPicture bmG_Back, bmG, 0, 0, 640, 480, 0, 0, i, False
 Game_Paint
 Sleep 10
 DoEvents
 If GameStatus < 0 Then Exit Sub
Next i
End Sub

Sub Game_Init()
dim i as long
'///load level
GameIsRndMap = False
Game_LoadLevel App.Path + "data/Default.box"
'///init data
GameStatus = 0
'GameClick = False
Game_InitMenu
'///enter loop
Game_Loop
'///
For i=1 to LevCount
 Delete Lev(i)
next i
Erase Lev
LevCount = 0
'///
objFile.Clear
'MsgBox "Exit!"
End Sub

Sub Game_LoadLevel(ByRef fn As String)
Dim i As Long, j As Long, k As Long, m As Long
Dim b As Boolean
fn = Replace(fn, vbNullChar, "")
#ifdef __FB_WIN32__
fn = Replace(fn, "/", "\")
#else
fn = Replace(fn, "\", "/")
#endif
If objFile.LoadFile(fn, strptr(TheSignature), True) Then
 k = objFile.FindNodeArray(strptr(!"LEV\0"))
 If k <> 0 Then
  For i=1 to LevCount
   Delete Lev(i)
  next i
  Erase Lev
  LevCount = 0
  m = objFile.NodeCount(k)
  If m > 0 Then
   LevCount = m
   ReDim Lev(1 To m)
   For i = 1 To m
    Lev(i) = New clsBloxorz
    Lev(i)->LoadLevel i, @objFile
   Next i
   b = True
  End If
 End If
End If
If b Then
 Me_Tag = Replace(objText.GetText(" of %d ("), "%d", CStr(LevCount)) + Mid(fn, InStrRev(fn, "\") + 1) + ")"
Else
 Me_Tag = ""
 MsgBox objText.GetText("Wrong level!")
 ReDim Lev(1 To 1)
 LevCount = 1
 Lev(1) = New clsBloxorz
 With *Lev(1)
  .Create 15, 10
  For i = 1 To 15
   For j = 1 To 10
    .SetData i, j, 1
   Next j
  Next i
 End With
End If
GameLev = 1
End Sub

Sub Game_InitMenu()
GameMenuItemCount = 10
ReDim GameMenuCaption(1 To GameMenuItemCount)
GameMenuCaption(1) = objText.GetText("Return to game")
GameMenuCaption(2) = objText.GetText("Restart")
GameMenuCaption(3) = objText.GetText("Pick a level")
GameMenuCaption(4) = objText.GetText("Open level file")
GameMenuCaption(5) = objText.GetText("Random level")
GameMenuCaption(6) = objText.GetText("Input solution")
GameMenuCaption(7) = objText.GetText("Auto solver")
GameMenuCaption(8) = objText.GetText("Game instructions")
GameMenuCaption(9) = objText.GetText("Main menu")
GameMenuCaption(10) = objText.GetText("Exit game")
End Sub

Sub Game_InitBack()
  PaintPicture i0_7_Picture, bmG_Back
  'draw text
  If GameIsRndMap Then
   DrawTextB bmG_Back, objText.GetText("Random Level") + txtGame(4).Tag, Me_Font, 8, 8, 480, 16, DT_VCENTER Or DT_SINGLELINE, vbBlack, , True
   'bad news: the same seed can generate different map each time :(
   'DrawTextB bmG_Back, objText.GetText("Seed:") + txtGame(0).Tag, Me_Font, 256, 8, 480, 16, DT_VCENTER Or DT_SINGLELINE, vbBlack, , True
   'button
   AlphaPaintPicture bmImg(3), bmG_Back, 384, 9, 16, 16, 96, 32, , True
   DrawTextB bmG_Back, objText.GetText("Copy"), Me_Font, 400, 8, 48, 16, DT_VCENTER Or DT_SINGLELINE, vbBlack, , True
  Else
   DrawTextB bmG_Back, Replace(objText.GetText("Level %d"), "%d", CStr(GameLev)) + Me_Tag, Me_Font, 8, 8, 480, 16, DT_VCENTER Or DT_SINGLELINE, vbBlack, , True
  End If
  DrawTextB bmG_Back, objText.GetText("Moves"), Me_Font, 8, 24, 72, 16, DT_VCENTER Or DT_SINGLELINE, vbBlack, , True
  DrawTextB bmG_Back, objText.GetText("Time used"), Me_Font, 8, 40, 72, 16, DT_VCENTER Or DT_SINGLELINE, vbBlack, , True
  DrawTextB bmG_Back, objText.GetText("Retries"), Me_Font, 8, 56, 72, 16, DT_VCENTER Or DT_SINGLELINE, vbBlack, , True
  DrawTextB bmG_Back, objText.GetText("Menu"), Me_Font, 600, 8, 32, 16, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbBlack, , True
End Sub

Function Game_Menu_Loop() As Long
Dim i As Long, j As Long
Dim x As Long, y As Long
Dim w As Long, h As Long
Dim r As RECT, hbr As Long, hbr2 As Long
Dim p As POINTAPI
'init
w = 128
h = GameMenuItemCount * 20 + 12
r.Left = 320 - w \ 2
r.Right = r.Left + w
hbr = CreateSolidBrush(vbBlack)
hbr2 = CreateSolidBrush(&H80FF&)
'show menu
x = h \ 2
y = 5
For i = 1 To 16
 r.Top = 240 - y
 r.Bottom = 240 + y
 PaintPicture bmG_Back, bmG
 FillRect bmG, r, hbr
 FrameRect bmG, r, hbr2
 Game_Paint
 Sleep 10
 DoEvents
 If GameStatus < 0 Then
  Exit Function
 End If
 y = x - ((x - y) * 3) \ 4
Next i
'show text
r.Top = 240 - h \ 2
r.Bottom = r.Top + h
For i = 1 To 17 + (GameMenuItemCount - 1)
 y = r.Top + 8
 PaintPicture bmG_Back, bmG
 FillRect bmG, r, hbr
 FrameRect bmG, r, hbr2
 For j = 1 To GameMenuItemCount
  x = &HF0F0F * (i - (j - 1))
  If x > 0 Then
   If x > &HFFFFFF Then x = &HFFFFFF
   DrawTextB bmG, GameMenuCaption(j), Me_Font, r.Left, y, w, 16, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, x, , True
  End If
  y = y + 20
 Next j
 Game_Paint
 Sleep 10
 DoEvents
 If GameStatus < 0 Then
  Exit Function
 End If
Next i
'menu loop
i = 0
r.Left = r.Left + 8
r.Right = r.Right - 8
y = 240 - h \ 2 + 8
Do
 SDL_GetMouseState @p.x,@p.y
 'hit test
 If p.x >= r.Left And p.x < r.Right Then
  If p.y >= y And p.y < 240 + h \ 2 - 8 Then
   j = p.y - y
   If j Mod 20 < 16 Then
    j = 1 + j \ 20
   Else
    j = 0
   End If
  Else
   j = 0
  End If
 Else
  j = 0
 End If
 If i <> j Then
  'erase old
  If i > 0 Then
   r.Top = y + (i - 1) * 20
   r.Bottom = r.Top + 16
   FrameRect bmG, r, hbr
  End If
  i = j
  'draw new
  If i > 0 Then
   r.Top = y + (i - 1) * 20
   r.Bottom = r.Top + 16
   FrameRect bmG, r, hbr2
  End If
  Game_Paint
 End If
 Sleep 20
 DoEvents
 If GameStatus < 0 Then
  Exit Function
 End If
 If (SDL_GetMouseState(NULL, NULL) And SDL_BUTTON(1)) AndAlso i > 0 Then
  Game_Menu_Loop = i
  Select Case i 'animation?
  Case 1
   r.Left = r.Left - 8
   r.Right = r.Right + 8
   'hide text
   r.Top = 240 - h \ 2
   r.Bottom = r.Top + h
   For i = 1 To 17 + (GameMenuItemCount - 1)
    y = r.Top + 8
    PaintPicture bmG_Back, bmG
    FillRect bmG, r, hbr
    FrameRect bmG, r, hbr2
    For j = 1 To GameMenuItemCount
     x = &HF0F0F * (j - i + 16)
     If x > 0 Then
      If x > &HFFFFFF Then x = &HFFFFFF
      DrawTextB bmG, GameMenuCaption(j), Me_Font, r.Left, y, w, 16, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, x, , True
     End If
     y = y + 20
    Next j
    Game_Paint
    Sleep 10
    DoEvents
    If GameStatus < 0 Then
     Game_Menu_Loop = 0
     Exit Function
    End If
   Next i
   'hide menu
   y = h \ 2
   For i = 1 To 16
    r.Top = 240 - y
    r.Bottom = 240 + y
    PaintPicture bmG_Back, bmG
    FillRect bmG, r, hbr
    FrameRect bmG, r, hbr2
    Game_Paint
    Sleep 10
    DoEvents
    If GameStatus < 0 Then
     Game_Menu_Loop = 0
     Exit Function
    End If
    y = (y * 3) \ 4
   Next i
  End Select
  Exit Do
 End If
Loop
End Function

Function Game_TextBox_Loop() As Long
Dim i As Long, j As Long, p As POINTAPI
Dim w As Long, h As Long
Dim r As RECT, hbr As Long, hbr2 As Long
Dim b1 As Boolean, b2 As Boolean
Dim bo1 As Boolean, bo2 As Boolean
dim nButton as long
'init
w = 320
h = 256
r.Left = 320 - w \ 2
r.Right = r.Left + w
r.Top = 240 - h \ 2
r.Bottom = r.Top + h
hbr = CreateSolidBrush(vbBlack)
hbr2 = CreateSolidBrush(&H80FF&)
'show
PaintPicture bmG_Back, bmG
FillRect bmG, r, hbr
FrameRect bmG, r, hbr2
DrawTextB bmG, objText.GetText("Demo"), Me_Font, r.Left + 8, r.Bottom - 24, 64, 16, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
DrawTextB bmG, objText.GetText("Cancel"), Me_Font, r.Right - 72, r.Bottom - 24, 64, 16, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
Game_Paint
txtGame(0).Move r.Left + 8, r.Top + 8, w - 16, h - 40
'init button
r.Bottom = r.Bottom - 8
r.Top = r.Bottom - 16
Do
 'get cursor pos
 nButton = SDL_GetMouseState(@p.x,@p.y) and SDL_BUTTON(1)
 'mouse in button1?
 r.Left = 320 - w \ 2 + 8
 r.Right = r.Left + 64
 b1 = PtInRect(r, p.x, p.y)
 If b1 Xor bo1 Then
  bo1 = b1
  FrameRect bmG, r, IIf(b1, hbr2, hbr)
 End If
 'mouse in button2?
 r.Left = r.Left + w - 80
 r.Right = r.Left + 64
 b2 = PtInRect(r, p.x, p.y)
 If b2 Xor bo2 Then
  bo2 = b2
  FrameRect bmG, r, IIf(b2, hbr2, hbr)
 End If
 txtGame(0).Draw
 Game_Paint
 Sleep 30
 txtGame(0).DoEvents
 'click button1?
 If b1 Then
  If nButton Then
   Game_TextBox_Loop = 1
   Exit Do
  End If
 End If
 'click button2?
 If b2 Then
  If nButton Then
   Game_TextBox_Loop = 0
   Exit Do
  End If
 End If
 If GameStatus < 0 Then Exit Do
Loop
'clear up
End Function

sub MyCallback(ByVal nNodeNow As Long, ByVal nNodeCount As Long, bAbort As Boolean)
Dim i As Long, j As Long
Dim w As Long, h As Long
Dim r As RECT, hbr As Long, hbr2 As Long
'If p0(1).Visible Then 'game!
 'draw
 w = 320
 h = 48
 r.Left = 320 - w \ 2
 r.Right = r.Left + w
 r.Top = 240 - h \ 2
 r.Bottom = r.Top + h
 hbr = CreateSolidBrush(vbBlack)
 hbr2 = CreateSolidBrush(&H80FF&)
 PaintPicture bmG_Back, bmG
 FillRect bmG, r, hbr
 FrameRect bmG, r, hbr2
 r.Right = r.Left + (nNodeNow * w) \ nNodeCount
 FillRect bmG, r, hbr2
 DrawTextB bmG, objText.GetText("Solving..."), Label1_10_Font, r.Left, r.Top, w, h, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
 Game_Paint
 If GameStatus < 0 Then bAbort = True
'Else 'edit!
' With p0(5)
'  .Width = (nNodeNow * 320&) \ nNodeCount
'  .Visible = True
' End With
'End If
DoEvents
end sub

'random map
Private Sub Game_RndMap_Run()
Dim s As String
Dim xx As clsBloxorz ptr = New clsBloxorz
Dim i As Long
s = txtGame(4).Text
i = cmbMode_ListIndex + 1
Do
 objRnd._Randomize s
 If pRandomMap(xx, , , , , , i) Then Exit Do 'TODO:time? map size?
 If GameStatus < 0 Then Exit Sub
 s = objRnd.RndSeed
Loop
Lev(GameLev)->Clone xx
Delete xx
txtGame(0).Tag = CStr(i) + objRnd.ValidateRndSeed(s)
txtGame(4).Tag = "(" + cmbMode_List(i-1) + ")"
End Sub

'new!!!
Private Function Game_RndMap_Loop() As Long
Dim i As Long, j As Long, k As Long, p As POINTAPI
Dim w As Long, h As Long
Dim r As RECT, r2 As RECT, r3 As RECT
Dim hbr As Long, hbr2 As Long, hbr3 As Long
Dim b1 As Boolean, b2 As Boolean
Dim nButton As Long
'calc width and height
w = 256
h = 80
j = cmbMode_ListCount
i = 32 + j * 16&
If i > h Then h = i
'init
r.Left = 320 - w \ 2
r.Right = r.Left + w
r.Top = 240 - h \ 2
r.Bottom = r.Top + h
hbr = CreateSolidBrush(vbBlack)
hbr2 = CreateSolidBrush(&H80FF&)
hbr3 = CreateSolidBrush(&H4080&)
'show
PaintPicture bmG_Back, bmG
FillRect bmG, r, hbr
FrameRect bmG, r, hbr2
r2.Left = r.Left + 144
r2.Top = r.Top + 32
r2.Right = r.Left + 240
r2.Bottom = r.Top + 48
FrameRect bmG, r2, hbr2
DrawTextB bmG, objText.GetText("Generate"), Me_Font, r.Left + 144, r.Bottom - 24, 48, 16, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
DrawTextB bmG, objText.GetText("Cancel"), Me_Font, r.Left + 200, r.Bottom - 24, 48, 16, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
DrawTextB bmG, objText.GetText("Random map mode:"), Me_Font, r.Left + 8, r.Top + 8, 128, 16, DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
DrawTextB bmG, objText.GetText("Seed:"), Me_Font, r.Left + 144, r.Top + 8, 128, 16, DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
Game_Paint
With txtGame(4)
 .Move r.Left + 144, r.Top + 32, 96, 16
 .Text = objRnd.RndSeed
End With
Do 'refresh continously :-3
 'get cursor pos
 nButton = SDL_GetMouseState(@p.x,@p.y) and SDL_BUTTON(1)
 r2.Top = r.Bottom - 24
 r2.Bottom = r2.Top + 16
 'mouse in button1?
 r2.Left = r.Left + 144
 r2.Right = r2.Left + 48
 b1 = PtInRect(r2, p.x, p.y)
 FrameRect bmG, r2, IIf(b1, hbr2, hbr)
 'mouse in button2?
 r2.Left = r.Left + 200
 r2.Right = r2.Left + 48
 b2 = PtInRect(r2, p.x, p.y)
 FrameRect bmG, r2, IIf(b2, hbr2, hbr)
 'listbox control :-3
 r2.Left = r.Left + 8
 r2.Top = r.Top + 24
 r2.Right = r2.Left + 128
 r2.Bottom = r2.Top + j * 16&
 FillRect bmG, r2, hbr
 k = -1
 For i = 0 To j - 1
  r3.Left = r2.Left
  r3.Top = r2.Top + i * 16&
  r3.Right = r2.Right
  r3.Bottom = r3.Top + 16&
  If i = cmbMode_ListIndex Then FillRect bmG, r3, hbr3
  DrawTextB bmG, cmbMode_List(i), Me_Font, r2.Left, r3.Top, 128, 16, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
  If PtInRect(r3, p.x, p.y) Then
   r3.Left = r3.Left + 2
   r3.Top = r3.Top + 1
   r3.Right = r3.Right - 2
   r3.Bottom = r3.Bottom - 1
   FrameRect bmG, r3, hbr2
   If nButton Then k = i
  End If
 Next i
 'FrameRect bmG, r2, hbr2
 If k >= 0 Then cmbMode_ListIndex = k
 'over
 txtGame(4).Draw
 Game_Paint
 Sleep 50
 txtGame(4).DoEvents
 'click button1?
 If b1 Then
  If nButton Then
   'get arguments
   i = Val(txtGame(4).Text)
   If i > 0 And i <= cmbMode_ListCount Then cmbMode_ListIndex = i - 1
   'enter random mode
   If Not GameIsRndMap Then
    LevTemp.Clone Lev(GameLev)
    GameIsRndMap = True
   End If
   'start random
   Game_RndMap_Run
   Game_RndMap_Loop = 1
   Exit Do
  End If
 End If
 'click button2?
 If b2 Then
  If nButton Then
   Game_RndMap_Loop = 0
   Exit Do
  End If
 End If
 If GameStatus < 0 Then Exit Do
Loop
End Function

Function ISort_Compare cdecl(byval elem1 as any ptr, byval elem2 as any ptr) as integer
dim Index1 As Long = *CPtr(Long Ptr,elem1)
dim Index2 As Long = *CPtr(Long Ptr,elem2)
index1 = nFitness(Index1)
index2 = nFitness(Index2)
if index1<index2 then return 1 else if index1>index2 then return -1 else return 0
End Function

Sub Game_RndMap_Progress(ByVal nNodeNow As Long, ByVal nNodeCount As Long)
Dim i As Long, j As Long
Dim w As Long, h As Long
Dim r As RECT, hbr As Long, hbr2 As Long
w = 320
h = 48
r.Left = 320 - w \ 2
r.Right = r.Left + w
r.Top = 240 - h \ 2
r.Bottom = r.Top + h
hbr = CreateSolidBrush(vbBlack)
hbr2 = CreateSolidBrush(&H80FF&)
PaintPicture bmG_Back, bmG
FillRect bmG, r, hbr
FrameRect bmG, r, hbr2
r.Right = r.Left + (nNodeNow * w) \ nNodeCount
FillRect bmG, r, hbr2
DrawTextB bmG, objText.GetText("Generating..."), Label1_10_Font, r.Left, r.Top, w, h, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
Game_Paint
DoEvents
End Sub

'stupidly, we use genetic algorithm again ... :-3
Function pRandomMap(ByVal objRet As clsBloxorz ptr, ByVal w As Long = 15, ByVal h As Long = 10, ByVal objInit As clsBloxorz ptr = NULL, ByVal PoolSize As Long = 200, ByVal nTime As Long = 30, ByVal nMode As Long = 1) As Long
Dim Pool() As clsBloxorz ptr
Dim idx() As Long 'right level
Dim idx2() As Long 'wrong level (??)
Dim idxSol() As Long 'solution index
Dim d() As Byte
Dim i As Long, j As Long, k As Long
Dim x As Long, y As Long
Dim sx As Long, sy As Long
Dim m As Long, ma As Long, mb As Long 'all count,right count,wrong count :-3
Dim t As Long
Dim ttt As Long 'time
dim s as string
'init array
ReDim Pool(1 To PoolSize)
ReDim nFitness(1 To PoolSize)
ReDim idx(1 To PoolSize)
ReDim idx2(1 To PoolSize)
ReDim idxSol(1 To PoolSize)
'///
For i=1 to PoolSize
 Pool(i)=New clsBloxorz
next i
'///
m = 1
'init state
If objInit<>NULL Then
 With *Pool(1)
  .Clone objInit
  w = .Width
  h = .Height
  sx = .StartX
  sy = .StartY
  'determine start
  If sx < 1 Or sx > w Or sy < 1 Or sy > h Then 'stupid!!!
   sx = 1 + Int(w * objRnd._Rnd / 4)
   sy = 1 + Int(h * objRnd._Rnd)
   .StartX = sx
   .StartY = sy
  End If
  .SetData sx, sy, 1
  'determine end point
  If .GetSpecifiedObjectCount(8) = 0 Then 'stupid!!!
   x = w - Int(w * objRnd._Rnd / 4)
   y = 1 + Int(h * objRnd._Rnd)
   .SetData x, y,8
  End If
 End With
Else
 With *Pool(1)
  .Create w, h
  'create a random map which is stupid
  For i = 1 To w
   For j = 1 To h
    '///
    Select Case nMode
    Case 4, 7 'zigzag
     x = 1
     If j = (h + 1) \ 3 Then
      If i <= (w + w) \ 3 Then x = 0
     ElseIf j = (h + h + 2) \ 3 Then
      If i > w \ 3 Then x = 0
     End If
     If x Then
      x = 1 + Int(1.6 * objRnd._Rnd)
      If x = 2 Then x = 5
     End If
    Case 5 'ice mode
     x = Int(5 * objRnd._Rnd)
     If x >= 2 Then x = 9
    Case 6 'fragile mode
     x = Int(5 * objRnd._Rnd)
     If x >= 2 Then x = 5
    Case Else
     x = Int(3 * objRnd._Rnd)
     If x = 2 Then If nMode = 1 Then x = 1 Else x = 5
    End Select
    '///
    .SetData i, j,x
   Next j
  Next i
  '///determine start
  Select Case nMode
  Case 4 'zigzag
   sx = 1 + Int(w * objRnd._Rnd / 4)
   sy = 1 + Int(h * objRnd._Rnd / 4)
  Case 7 'zigzag+button
   sx = w \ 2 + Int(w * objRnd._Rnd / 4)
   sy = 1 + Int(h * objRnd._Rnd / 4)
  Case Else
   sx = 1 + Int(w * objRnd._Rnd / 4)
   sy = 1 + Int(h * objRnd._Rnd)
  End Select
  .SetData sx, sy,1
  .StartX = sx
  .StartY = sy
  '///determine end point
  Select Case nMode
  Case 4 'zigzag
   x = w - Int(w * objRnd._Rnd / 4)
   y = h - Int(h * objRnd._Rnd / 4)
  Case 7 'zigzag+button
   x = 1 + Int(w * objRnd._Rnd / 4)
   y = 1 + Int(h * objRnd._Rnd / 4)
   If x >= sx - 1 And x > 1 Then x = x - 1
   .AddSwitch
   If x > 1 Then
    .SetData x - 1, y,6
    .AddSwitchBridge 1, x - 1, y, 2
   End If
   If y > 1 Then
    .SetData x, y - 1,6
    .AddSwitchBridge 1, x, y - 1, 2
   End If
   If x < w Then
    .SetData x + 1, y,6
    .AddSwitchBridge 1, x + 1, y, 2
   End If
   If y < h Then
    .SetData x, y + 1,6
    .AddSwitchBridge 1, x, y + 1, 2
   End If
  Case Else
   x = w - Int(w * objRnd._Rnd / 4)
   y = 1 + Int(h * objRnd._Rnd)
  End Select
  .SetData x, y,8
  '///just add some button
  Select Case nMode
  Case 7 'zigzag+button
   x = w - Int(w * objRnd._Rnd / 4)
   y = h - Int(h * objRnd._Rnd / 4)
   .SetData x, y,2 + Int(2 * objRnd._Rnd)
   .SetData2 x, y,1
  Case 3 'difficult
   i = 0
   Do Until objRnd._Rnd < 0.5
    x = 1 + Int(w * objRnd._Rnd)
    y = 1 + Int(h * objRnd._Rnd)
    If x <> sx Or y <> sy Then
     Select Case .Data(x, y)
     Case 2, 3, 6, 7, 8
     Case Else
      .SetData x, y,2 + Int(2 * objRnd._Rnd)
      i = i + 1
      .SetData2 x, y,i
      .AddSwitch
      'just add some bridge
      Do
       x = 1 + Int(w * objRnd._Rnd)
       y = 1 + Int(h * objRnd._Rnd)
       If x <> sx Or y <> sy Then
        Select Case .Data(x, y)
        Case 2, 3, 8
        Case Else
         .SetData x, y,6 + Int(2 * objRnd._Rnd)
         .AddSwitchBridge i, x, y, Int(3 * objRnd._Rnd)
        End Select
       End If
      Loop Until objRnd._Rnd < 0.5
     End Select
    End If
   Loop
  End Select
 End With
End If
ReDim d(1 To h, 1 To w)
'start
ttt = 1
Do
 'calc fitness
 ma = 0
 mb = 0
 For k = 1 To m
  With *Pool(k)
   If .SolveIt Then
    j = .SolveItGetSolutionNodeIndex
    If j = 0 Then i = 0 Else i = .SolveItGetDistance(j)
   Else 'failed!!!
    abort
   End If
   If i = 0 Or i = &H7FFFFFFF Then
    mb = mb + 1
    idx2(mb) = k
    nFitness(k) = &HC0000000 + .SolveItGetNodeUsed
   Else
    ma = ma + 1
    idx(ma) = k
    nFitness(k) = i
    idxSol(k) = j
   End If
  End With
  'abort?
  If GameStatus < 0 Then Exit Function
 Next k
 'sort it
 If ma > 0 Then qsort @idx(1),ma,sizeof(Long),ProcPtr(ISort_Compare)
 If mb > 0 Then qsort @idx2(1),mb,sizeof(Long),ProcPtr(ISort_Compare)
 'over?
 'show progress
  Game_RndMap_Progress ttt, nTime
  DoEvents
 If ttt >= nTime Then Exit Do
 ttt = ttt + 1
 'reproduction count=1 ???? TODO:crossover ????
 'mutation
 For k = 1 To ma
  'get new pos
  If m < PoolSize Then
   m = m + 1
   j = m
  Else
   If ma <= k Then Exit For
   j = idx(ma)
   ma = ma - 1
  End If
  Pool(j)->Clone Pool(idx(k))
  With *Pool(idx(k))
   s = .SolveItGetSolution(idxSol(idx(k)), VarPtr(d(1, 1)))
   t = 0
   Do
    x = 1 + Int(w * objRnd._Rnd)
    y = 1 + Int(h * objRnd._Rnd)
    If x <> sx And y <> sy And d(y, x) = 1 Then
     Select Case .Data(x, y)
     Case 1, 5
      '///change this point is OK
      Select Case nMode
      Case 1
       i = 0
      Case 2
       i = Int(2 * objRnd._Rnd)
       If i = 1 Then i = 5
      Case 5 'ice mode
       i = Int(4 * objRnd._Rnd)
       If i > 0 Then i = i - 1
       i = i + 9
      Case 6 'fragile mode
       i = Int(3 * objRnd._Rnd)
       If i = 1 Then i = 5 Else If i = 2 Then i = 10
      Case Else
       i = Int(4 * objRnd._Rnd)
       If i = 1 Then i = 5 Else If i >= 2 Then i = i + 7
      End Select
      .SetData x, y,i
      '///
      If objRnd._Rnd < 0.5 Then Exit Do
     End Select
    End If
    t = t + 1
   Loop Until t > 200
  End With
 Next k
 'mutation2
 For k = 1 To mb
  'get new pos
  If m < PoolSize Then
   m = m + 1
   j = m
  Else
   If mb < k Then Exit For
   j = idx2(mb)
   mb = mb - 1
  End If
  With *Pool(idx2(k)) 'flood-fill check
   .SolveItGetCanMoveArea d()
   'expand von-neumann
   For x = 1 To w
    For y = 1 To h
     If d(y, x) = 1 Then
      If x > 1 Then If d(y, x - 1) = 0 Then d(y, x - 1) = 2
      If x < w Then If d(y, x + 1) = 0 Then d(y, x + 1) = 2
      If y > 1 Then If d(y - 1, x) = 0 Then d(y - 1, x) = 2
      If y < h Then If d(y + 1, x) = 0 Then d(y + 1, x) = 2
     End If
    Next y
   Next x
'   '(x2??)
'   For x = 1 To w
'    For y = 1 To h
'     If d(x, y) = 2 Then
'      If x > 1 Then If d(x - 1, y) = 0 Then d(x - 1, y) = 3
'      If x < w Then If d(x + 1, y) = 0 Then d(x + 1, y) = 3
'      If y > 1 Then If d(x, y - 1) = 0 Then d(x, y - 1) = 3
'      If y < h Then If d(x, y + 1) = 0 Then d(x, y + 1) = 3
'     End If
'    Next y
'   Next x
   'random select
   t = 0
   Do
    x = 1 + Int(w * objRnd._Rnd)
    y = 1 + Int(h * objRnd._Rnd)
    If x <> sx And y <> sy And d(y, x) > 1 Then 'd(x,y)>1 '???
     Select Case .Data(x, y)
     Case 0, 5, 9, 10, 11
      '///change this point is OK
      .SetData x, y,1
      '///
      If objRnd._Rnd < 0.2 Then Exit Do
     End Select
    End If
    t = t + 1
   Loop Until t > 200
  End With
  'reproduce
  If mb < k Then Exit For
  Pool(j)->Clone Pool(idx2(k))
  'even more random
  With *Pool(j)
   For i = 1 To 20
    x = 1 + Int(w * objRnd._Rnd)
    y = 1 + Int(h * objRnd._Rnd)
    If x <> sx And y <> sy Then
     Select Case .Data(x, y)
     Case 0, 5 ', 9 , 10, 11
      '///change this point is OK
      .SetData x, y,1
      '///
     End Select
    End If
   Next i
  End With
 Next k
Loop
'output result
If ma > 0 Then
 k = idx(1)
 With *Pool(k)
  '///delete unused!?!?
  s = .SolveItGetSolution(idxSol(k), VarPtr(d(1, 1)))
  'expand von-neumann neighbors
  For x = 1 To w
   For y = 1 To h
    If d(y, x) = 1 Then
     If x > 1 Then If d(y, x - 1) = 0 Then d(y, x - 1) = 2
     If x < w Then If d(y, x + 1) = 0 Then d(y, x + 1) = 2
     If y > 1 Then If d(y - 1, x) = 0 Then d(y - 1, x) = 2
     If y < h Then If d(y + 1, x) = 0 Then d(y + 1, x) = 2
    End If
   Next y
  Next x
  'expand transport area and button
  For i = 1 To w
   For j = 1 To h
    x = .Data(i, j)
    Select Case x
    Case 4
     .GetTransportPosition i, j, x, y, sx, sy
     If x >= 1 And y >= 1 And x <= w And y <= h Then d(y, x) = 1
     If sx >= 1 And sy >= 1 And sx <= w And sy <= h Then d(sy, sx) = 1
    Case 2, 3, 6, 7
     d(j, i) = 1
    End Select
   Next j
  Next i
  'delete
  For i = 1 To w
   For j = 1 To h
    If d(j, i) = 0 Then
     Select Case .Data(i, j)
     Case 2, 3, 4, 8
     Case Else
      .SetData i, j,0
     End Select
    End If
   Next j
  Next i
  '///
 End With
 objRet->Clone Pool(k)
 pRandomMap = nFitness(k)
End If
'///
For i=1 to PoolSize
 Delete Pool(i)
next i
Erase Pool
End Function

