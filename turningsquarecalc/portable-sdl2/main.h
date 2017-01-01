#pragma once

#include "GNUGetText.h"
#include "SimpleArrayVB6.h"
#include <SDL_video.h>
#include <SDL_render.h>
#include <SDL_ttf.h>
#include <string>

extern GNUGetText objText;

#define _(X) (objText.GetText(X))

extern TTF_Font* m_objFont[3];

extern SDL_Window *window;
extern SDL_Renderer *renderer;

// these two are render targets
extern SDL_Texture *bmG_Back; // usually contain background, level name, etc.
extern SDL_Texture *bmG_Lv; // usually contains background and layer 0

extern bool bRenderTargetDirty;

extern SDL_Texture *bmImg[5];

struct _RECT {
	int Left, Top, Right, Bottom;
};

struct _POINTAPI {
	int x, y;
};

const int Ani_Layer0 = 61;
const int Ani_Misc = 99;

extern bool bRun;

void _FillRect(SDL_Texture* hdc, const _RECT& rect, int color);
void _FrameRect(SDL_Texture* hdc, const _RECT& rect, int color);
void _Cls(SDL_Texture* hdc);
void PaintPicture(SDL_Texture* objSrc, SDL_Texture* objDest, int nDestLeft = 0, int nDestTop = 0, int nWidth = -1, int nHeight = -1, int nSrcLeft = 0, int nSrcTop = 0);
void WaitForNextFrame();
int DoEvents();

inline bool _PtInRect(const _RECT& r, int x, int y) {
	return x >= r.Left && y >= r.Top && x < r.Right && y < r.Bottom;
}

void AlphaPaintPicture(SDL_Texture* objSrc, SDL_Texture* objDest, int nDestLeft = 0, int nDestTop = 0, int nWidth = -1, int nHeight = -1, int nSrcLeft = 0, int nSrcTop = 0, int nAlpha = 255);

void NormalizeCursorPos(int &x, int &y);

// return normalized position
int _GetCursorPos(int *x, int *y);

inline void Game_Paint() {
	SDL_RenderPresent(renderer);
}

enum _DrawTextConstants {
	_DT_BOTTOM = 0x8,
	_DT_CENTER = 0x1,
	_DT_LEFT = 0x0,
	_DT_RIGHT = 0x2,
	_DT_SINGLELINE = 0x20,
	_DT_TOP = 0x0,
	_DT_VCENTER = 0x4,
	_DT_WORDBREAK = 0x10,
};

void DrawTextB(SDL_Texture* hdc, const std::string& s, TTF_Font* fnt, int _Left, int _Top, int _Width, int _Height, int Style, int Color);

SDL_Texture* _LoadPictureFromFile(const char* _FileName, const char* _MaskFile = NULL);

int GetAnimationCount(int Index);
void pTheBitmapDraw2(SDL_Texture *hdc, int Index, int x, int y, int Alpha = 255);
void pTheBitmapDraw3(SDL_Texture *hdc, int Index, int Index2, int x, int y, int Alpha = 255);
void pGameDrawBox(SDL_Texture* hdc, int Index, int Index2, int x, int y, int Alpha = 255);
void pGameDrawLayer0(SDL_Texture *hdc, const Array2D<unsigned char, 1, 1>& d, int StartX, int StartY);
void pGameDrawLayer1(SDL_Texture *hdc, const Array2D<unsigned char, 1, 1>& GameD, int GameX, int GameY, int GameX2, int GameY2, int GameLayer0SX, int GameLayer0SY, int GameS,
	bool DrawBox = true, bool DrawBoxShadow = false, int Index = 0, int Index2 = 0, int BoxDeltaY = 0, int BoxAlpha = 255, bool WithLayer0 = false, int BoxDeltaX = 0, bool NoZDepth = false);

std::string GetSetting(const std::string& name, const std::string& _default);
void SaveSetting(const std::string& name, const std::string& value);
