#include "main.h"
#include "FileSystem.h"
#include "SimpleArrayVB6.h"
#include "clsBloxorz.h"
#include "clsTheFile.h"

#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <vector>

#include <SDL.h>
#include <SDL_ttf.h>
#include <SDL_image.h>

GNUGetText objText;

TTF_Font* m_objFont[3] = {};

SDL_Window *window = NULL;
SDL_Renderer *renderer = NULL;

SDL_Texture *bmG_Back = NULL, *bmG_Lv = NULL, *bmImg[5] = {};

int cmbMode_ListIndex;
std::vector<std::string> cmbMode_List;

int GameLayer0SX, GameLayer0SY;
std::vector<clsBloxorz> Lev;

struct _RECT {
	int Left, Top, Right, Bottom;
};

struct _POINTAPI {
	int x, y;
};

struct typeTheBitmap3 {
	int ImgIndex, x, y, w, h, dx, dy;
	typeTheBitmap3() : ImgIndex(-1), x(0), y(0), w(0), h(0), dx(0), dy(0) {}
	typeTheBitmap3(int _index, int _x, int _y, int _w, int _h, int _dx, int _dy) :
		ImgIndex(_index), x(_x), y(_y), w(_w), h(_h), dx(_dx), dy(_dy)
	{
	}
};

struct typeTheBitmap2 : public typeTheBitmap3 {
	int ow, oh;
	typeTheBitmap2() : typeTheBitmap3(), ow(0), oh(0) {}
	typeTheBitmap2(int _index, int _x, int _y, int _w, int _h, int _dx, int _dy, int _ow, int _oh) :
		typeTheBitmap3(_index, _x, _y, _w, _h, _dx, _dy), ow(_ow), oh(_oh)
	{
	}
};

typedef std::vector<typeTheBitmap3> typeTheBitmapArray;

FixedArray1D<typeTheBitmap2, 9, 524> bmps;

/*
'1-4=up move
'5-8=h move
'9-12=v move
'13-16=single move
'29=start
'30=end
'31-60=shadow
*/
FixedArray1D<typeTheBitmapArray, 1, 100> Anis;

const int Ani_Layer0 = 61;
const int Ani_Misc = 99;

/////'         *          '/////
/////' *        x=10,y=16 '/////
/////'          *         '/////
/////'  *x=32,y=-5        '/////

Array2D<unsigned char, 1, 1> GameD;

/*
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
'13=play-slipping animation
*/
int GameStatus = 0;

int GameLev;
int GameW, GameH;
int GameX, GameY, GameS, GameX2, GameY2;
int GameFS;

int GameLvStartTime, GameLvStep, GameLvRetry;

std::string GameDemoS;
int GameDemoPos;
bool GameDemoBegin;

const int GameMenuItemCount = 10;
FixedArray1D<std::string, 1, GameMenuItemCount> GameMenuCaption;

bool GameIsRndMap;
clsBloxorz LevTemp; // extremely stupid!!!
Array1D<int, 1> nFitness;

void _FillRect(SDL_Texture* hdc, const _RECT& rect, int color) {
	SDL_Rect r;
	r.x = rect.Left;
	r.y = rect.Top;
	r.w = rect.Right - rect.Left;
	r.h = rect.Bottom - rect.Top;
	SDL_SetRenderTarget(renderer, hdc);
	SDL_SetRenderDrawColor(renderer, color, color >> 8, color >> 16, 255);
	SDL_RenderFillRect(renderer, &r);
}

void _FrameRect(SDL_Texture* hdc, const _RECT& rect, int color) {
	SDL_Rect r;
	r.x = rect.Left;
	r.y = rect.Top;
	r.w = rect.Right - rect.Left;
	r.h = rect.Bottom - rect.Top;
	SDL_SetRenderTarget(renderer, hdc);
	SDL_SetRenderDrawColor(renderer, color, color >> 8, color >> 16, 255);
	SDL_RenderDrawRect(renderer, &r);
}

void _Cls(SDL_Texture* hdc) {
	SDL_SetRenderTarget(renderer, hdc);
	SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
	SDL_RenderClear(renderer);
}

void PaintPicture(SDL_Texture* objSrc, SDL_Texture* objDest, int nDestLeft = 0, int nDestTop = 0, int nWidth = -1, int nHeight = -1, int nSrcLeft = 0, int nSrcTop = 0) {
	if (nWidth < 0 || nHeight < 0) {
		int w = 0, h = 0;
		SDL_QueryTexture(objSrc, NULL, NULL, &w, &h);
		if (nWidth < 0) nWidth = w;
		if (nHeight < 0) nHeight = h;
	}
	SDL_Rect r1 = { nSrcLeft, nSrcTop, nWidth, nHeight };
	SDL_Rect r2 = { nDestLeft, nDestTop, nWidth, nHeight };
	SDL_SetRenderTarget(renderer, objDest);
	SDL_SetTextureBlendMode(objSrc, SDL_BLENDMODE_NONE);
	SDL_RenderCopy(renderer, objSrc, &r1, &r2);
}

int DoEvents() {
	SDL_Event event;
	while (SDL_PollEvent(&event)) {
		if (event.type == SDL_QUIT) {
			GameStatus = -2;
			return 0;
		}
	}
	return 1;
}

inline bool _PtInRect(const _RECT& r, int x, int y) {
	return x >= r.Left && y >= r.Top && x < r.Right && y < r.Bottom;
}

void AlphaPaintPicture(SDL_Texture* objSrc, SDL_Texture* objDest, int nDestLeft = 0, int nDestTop = 0, int nWidth = -1, int nHeight = -1, int nSrcLeft = 0, int nSrcTop = 0, int nAlpha = 255) {
	if (nWidth < 0 || nHeight < 0) {
		int w = 0, h = 0;
		SDL_QueryTexture(objSrc, NULL, NULL, &w, &h);
		if (nWidth < 0) nWidth = w;
		if (nHeight < 0) nHeight = h;
	}
	SDL_Rect r1 = { nSrcLeft, nSrcTop, nWidth, nHeight };
	SDL_Rect r2 = { nDestLeft, nDestTop, nWidth, nHeight };
	SDL_SetRenderTarget(renderer, objDest);
	SDL_SetTextureBlendMode(objSrc, SDL_BLENDMODE_BLEND);
	SDL_SetTextureAlphaMod(objSrc, nAlpha);
	SDL_RenderCopy(renderer, objSrc, &r1, &r2);
}

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

/*
'TODO:multiline support
'TODO:clip
'TODO:cache
*/
void DrawTextB(SDL_Texture* hdc, const std::string& s, TTF_Font* fnt, int _Left, int _Top, int _Width, int _Height, int Style, int Color) {
	if (s.empty()) return;

	SDL_Surface *objTemp;
	SDL_Color fg = { Color, Color >> 8, Color >> 16, 255 };

	if (Style & _DT_SINGLELINE) {
		objTemp = TTF_RenderUTF8_Blended(fnt, s.c_str(), fg);
		if (objTemp == NULL) {
			printf("Error: TTF_RenderUTF8_Blended failed!\n");
			return;
		}
	} else {
		objTemp = TTF_RenderUTF8_Blended_Wrapped(fnt, s.c_str(), fg, (Style & _DT_WORDBREAK) ? _Width : 65536);
		if (objTemp == NULL) {
			printf("Error: TTF_RenderUTF8_Blended_Wrapped failed!\n");
			return;
		}
	}

	if (Style & _DT_CENTER) {
		_Left += (_Width - objTemp->w) / 2;
	} else if (Style & _DT_RIGHT) {
		_Left += (_Width - objTemp->w);
	}

	if (Style & _DT_VCENTER) {
		_Top += (_Height - objTemp->h) / 2;
	} else if (Style & _DT_BOTTOM) {
		_Top += (_Height - objTemp->h);
	}

	SDL_Rect r = { _Left, _Top, objTemp->w, objTemp->h };

	SDL_Texture *t = SDL_CreateTextureFromSurface(renderer, objTemp);
	SDL_SetRenderTarget(renderer, hdc);
	SDL_RenderCopy(renderer, t, NULL, &r);
	SDL_FreeSurface(objTemp);
	SDL_DestroyTexture(t);
}

SDL_Texture* _LoadPictureFromFile(const char* _FileName, const char*_MaskFile = NULL) {
	SDL_Surface *bm = IMG_Load(_FileName);
	SDL_Texture *ret = NULL;

	if (_MaskFile) {
		SDL_Surface *bmMask = IMG_Load(_MaskFile);

		assert(bm->w == bmMask->w && bm->h == bmMask->h);

		SDL_Surface *tmp = SDL_ConvertSurfaceFormat(bm, SDL_PIXELFORMAT_ARGB8888, 0);
		std::swap(bm, tmp);
		SDL_FreeSurface(tmp);
		tmp = SDL_ConvertSurfaceFormat(bmMask, SDL_PIXELFORMAT_ARGB8888, 0);
		std::swap(bmMask, tmp);
		SDL_FreeSurface(tmp);

		SDL_LockSurface(bm);
		SDL_LockSurface(bmMask);

		Uint32* d1 = (Uint32*)bm->pixels;
		Uint32* d2 = (Uint32*)bmMask->pixels;

		for (int i = 0, m = bm->w*bm->h; i < m; i++) {
			d1[i] = (d1[i] & 0xFFFFFF00) | ((d2[i] >> 8) & 0xFF);
		}

		SDL_UnlockSurface(bm);
		SDL_UnlockSurface(bmMask);

		SDL_FreeSurface(bmMask);
	}

	ret = SDL_CreateTextureFromSurface(renderer, bm);
	SDL_FreeSurface(bm);
	return ret;
}

void pLoadBitmapData(const std::vector<char> b, int Index) {
	u8file *f = SDL_RWFromConstMem(&(b[0]), b.size());

	int m = SDL_ReadLE32(f);
	for (int i = 0; i < m; i++) {
		int j = SDL_ReadLE32(f);
		bmps(j).ImgIndex = Index;
		bmps(j).x = SDL_ReadLE32(f);
		bmps(j).y = SDL_ReadLE32(f);
		bmps(j).w = SDL_ReadLE32(f);
		bmps(j).h = SDL_ReadLE32(f);
		bmps(j).dx = SDL_ReadLE32(f);
		bmps(j).dy = SDL_ReadLE32(f);
		bmps(j).ow = SDL_ReadLE32(f);
		bmps(j).oh = SDL_ReadLE32(f);
	}

	u8fclose(f);
}

inline void pTheBitmapConvert(const typeTheBitmap2& bm, typeTheBitmap3& ret, int NewX = 0, int NewY = 0) {
	ret.ImgIndex = bm.ImgIndex;
	ret.x = bm.x; ret.y = bm.y; ret.w = bm.w; ret.h = bm.h;
	ret.dx = NewX - bm.dx;
	ret.dy = NewY = bm.dy;
}

struct typeInitBoxAnimation {
	int Index, Count, Offset, NewX, NewY;
	bool IsReverse;
};

void pInitBoxAnimation(const typeInitBoxAnimation& d) {
	typeTheBitmapArray &ani = Anis(d.Index);
	ani.resize(d.Count + 1);

	if (d.IsReverse) {
		pTheBitmapConvert(bmps(1 + d.Offset), ani[1], d.NewX, d.NewY);
		for (int i = 2; i <= d.Count; i++) {
			pTheBitmapConvert(bmps(i + d.Offset), ani[d.Count + 2 - i], d.NewX, d.NewY);
		}
	} else {
		for (int i = 1; i <= d.Count; i++) {
			pTheBitmapConvert(bmps(i + d.Offset), ani[i], d.NewX, d.NewY);
		}
	}
}

/*
'i0(0) block.jpg
'i0(1) block_mask.gif
'i0(2) shadow.jpg
'i0(3) shadow_mask.gif
'i0(4) edit.gif
'i0(5) block2.jpg
'i0(6) block2_mask.gif
'i0(7) back.jpg
*/
void pInitBitmap() {
	bmImg[0] = _LoadPictureFromFile("data/block.jpg", "data/block_mask.png");
	bmImg[1] = _LoadPictureFromFile("data/shadow.jpg", "data/shadow_mask.png");
	bmImg[2] = _LoadPictureFromFile("data/edit.png", NULL);
	bmImg[3] = _LoadPictureFromFile("data/block2.jpg", "data/block2_mask.png");
	bmImg[4] = _LoadPictureFromFile("data/back.jpg", NULL);

	// load bitmap data
	{
		clsTheFile obj;
		obj.LoadFile("data/data.dat", NULL, true);
		pLoadBitmapData(obj.nodes[0].nodes[0], 0);
		pLoadBitmapData(obj.nodes[0].nodes[1], 1);
	}

	// load bitmap array

	// layer 0
	{
		typeTheBitmapArray ani = Anis(Ani_Layer0);
		ani.resize(12);

		pTheBitmapConvert(bmps(108), ani[1], 4, 8); // block
		pTheBitmapConvert(bmps(119), ani[2], 4, 8); // soft
		pTheBitmapConvert(bmps(120), ani[3], 4, 8); // heavy
		pTheBitmapConvert(bmps(130), ani[4], 4, 10); // transport
		pTheBitmapConvert(bmps(131), ani[5], 4, 8); // thin

		ani[7] = typeTheBitmap3(3, 44, 28, 44, 28, 0, 5); // bridge on
		pTheBitmapConvert(bmps(121), ani[8], 5, 11); // end
		ani[9] = typeTheBitmap3(3, 0, 0, 44, 28, 0, 5); // ice
		ani[10] = typeTheBitmap3(3, 0, 28, 44, 28, 0, 5); // pyramid
		ani[11] = ani[1]; // stone TODO:layer 1
	}

	// box animation
	typeInitBoxAnimation animations[] =
	{
		{ 1, 10, 366, 80, 98 },
		{ 2, 10, 386, 80, 98 },
		{ 4, 10, 376, 80, 98 },
		{ 5, 9, 10, 80, 98 },
		{ 6, 10, 448, 80, 98 },
		{ 7, 9, 19, 80, 98 },
		{ 8, 10, 438, 80, 98 },
		{ 9, 10, 406, 70, 82 },
		{ 10, 10, 426, 70, 82 },
		{ 11, 10, 396, 70, 82 },
		{ 12, 10, 416, 70, 82 },
		{ 13, 10, 316, 80, 98 },
		{ 14, 9, 336, 80, 98 },
		{ 15, 9, 307, 80, 98 },
		{ 16, 10, 326, 80, 98 },
		{ 29, 12, 504, 80, 98 },
		{ 30, 8, 516, 80, 98 },
		{ 31, 10, 141, 80, 98 },
		{ 32, 10, 161, 80, 98 },
		{ 33, 9, 131, 80, 98 },
		{ 34, 10, 151, 80, 98 },
		{ 35, 9, 221, 80, 98 },
		{ 36, 10, 241, 80, 98 },
		{ 37, 9, 211, 80, 98 },
		{ 38, 10, 231, 37, 98 },
		{ 39, 10, 181, 70, 82 },
		{ 40, 10, 201, 70, 82 },
		{ 41, 10, 171, 70, 82 },
		{ 42, 10, 191, 70, 82 },
		{ 43, 10, 275, 80, 98 },
		{ 44, 9, 295, 80, 98 },
		{ 45, 9, 265, 80, 98 },
		{ 46, 10, 285, 80, 98 },
		{ 59, 12, 253, 80, 98 },
		{ 71, 9, 35, 80, 98, true },
		{ 72, 9, 35, 80, 98 },
		{ 73, 9, 459, 80, 98 },
		{ 74, 9, 459, 80, 98, true },
		{ 75, 9, 494, 80, 98, true },
		{ 76, 9, 494, 80, 98 },
		{ 77, 9, 485, 80, 98 },
		{ 78, 9, 485, 80, 98, true },
		{ 79, 9, 467, 70, 82 },
		{ 80, 9, 467, 70, 82, true },
		{ 81, 9, 476, 70, 82, true },
		{ 82, 9, 476, 70, 82 },
		{ 83, 9, 356, 80, 98 },
		{ 84, 9, 356, 80, 98, true },
		{ 85, 9, 347, 80, 98 },
		{ 86, 9, 347, 80, 98, true },
		{ -1 },
	};
	for (int i = 0; animations[i].Index > 0; i++) {
		pInitBoxAnimation(animations[i]);
	}
	{
		typeTheBitmapArray ani = Anis(3);
		ani.resize(10);
		for (int i = 1; i <= 7; i++) {
			pTheBitmapConvert(bmps(i + 28), ani[i], 80, 98);
		}
		for (int i = 8; i <= 9; i++) {
			pTheBitmapConvert(bmps(i + 1), ani[i], 80, 98);
		}
	}

	// misc
	{
		typeTheBitmapArray ani = Anis(3);
		ani.resize(21);
		ani[1] = typeTheBitmap3(3, 88, 0, 44, 28, 0, 5); // bridge off
		ani[2] = typeTheBitmap3(3, 44, 0, 44, 28, 0, 5); // bridge on
		ani[3] = typeTheBitmap3(0, bmps(307).x, bmps(307).y, bmps(307).w / 2, bmps(307).h, bmps(307).w / 2, bmps(307).h / 2); // "["
		ani[4] = typeTheBitmap3(0, bmps(307).x + bmps(307).w / 2, bmps(307).y, bmps(307).w / 2, bmps(307).h, 0, bmps(307).h / 2); // "["
		pTheBitmapConvert(bmps(504), ani[5], 80, 98); // blur box
		ani[6] = typeTheBitmap3(3, 228, 0, 44, 52, 0, 34); // box
	}
}

int main(int argc, char** argv) {
	initPaths();

	objText.LoadFileWithAutoLocale("locale/*.mo");

	SDL_SetHint(SDL_HINT_RENDER_VSYNC, "1");
	SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "linear");

	SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER);

	window = SDL_CreateWindow(_("Turning Square").c_str(), SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 640, 480, SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI);
	//window = SDL_CreateWindow(_("Turning Square").c_str(), SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 0, 0, SDL_WINDOW_FULLSCREEN_DESKTOP);
	renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC | SDL_RENDERER_TARGETTEXTURE);
	SDL_RenderSetLogicalSize(renderer, 640, 480);

	TTF_Init();
	IMG_Init(IMG_INIT_JPG | IMG_INIT_PNG);

#ifdef ANDROID
#define FONT_FILE_PREFIX "/system/fonts/"
#else
#define FONT_FILE_PREFIX "data/"
#endif

	m_objFont[0] = TTF_OpenFont(FONT_FILE_PREFIX "DroidSansFallback.ttf", 12);
	m_objFont[1] = TTF_OpenFont(FONT_FILE_PREFIX "DroidSansFallback.ttf", 36);
	m_objFont[2] = TTF_OpenFont(FONT_FILE_PREFIX "DroidSansFallback.ttf", 64);

	pInitBitmap();

	bmG_Back = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGB888, SDL_TEXTUREACCESS_TARGET, 640, 480);
	bmG_Lv = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGB888, SDL_TEXTUREACCESS_TARGET, 640, 480);

	cmbMode_List.push_back(_("Beginner"));
	cmbMode_List.push_back(_("Intermediate"));
	cmbMode_List.push_back(_("Advanced"));
	cmbMode_List.push_back(_("Zigzag"));
	cmbMode_List.push_back(_("Ice mode"));
	cmbMode_List.push_back(_("Fragile mode"));
	cmbMode_List.push_back(_("Zigzag with button"));
	cmbMode_ListIndex = 2;

	// run main loop
	int x, y;
	int i;
	int nPressed = 1;
	SDL_Event event;

	while (GameStatus > -2) {
		GameStatus = -1;

		if (nPressed) {
			PaintPicture(bmImg[4], bmG_Back);
			DrawTextB(bmG_Back, _("Turning Square"), m_objFont[2],
				0, 40, 640, 80, _DT_CENTER | _DT_VCENTER | _DT_SINGLELINE, 0x0080FF);

			DrawTextB(bmG_Back, _("Start game"), m_objFont[1],
				0, 200, 640, 60, _DT_CENTER | _DT_VCENTER | _DT_SINGLELINE, 0x0080FF);
			DrawTextB(bmG_Back, _("Game instructions"), m_objFont[1],
				0, 260, 640, 60, _DT_CENTER | _DT_VCENTER | _DT_SINGLELINE, 0x0080FF);
			DrawTextB(bmG_Back, _("Editor/Solver"), m_objFont[1],
				0, 320, 640, 60, _DT_CENTER | _DT_VCENTER | _DT_SINGLELINE, 0x0080FF);
			DrawTextB(bmG_Back, _("Exit game"), m_objFont[1],
				0, 380, 640, 60, _DT_CENTER | _DT_VCENTER | _DT_SINGLELINE, 0x0080FF);
		}

		// get messages
		nPressed = 0;
		while (SDL_PollEvent(&event)) {
			switch (event.type) {
			case SDL_QUIT:
				GameStatus = -2;
				break;
			case SDL_MOUSEBUTTONDOWN:
				if (event.button.button == SDL_BUTTON_LEFT) nPressed = 10;
				break;
			}
		}
		if (GameStatus <= -2) break;

		// test only
		PaintPicture(bmG_Back, NULL);

		SDL_GetMouseState(&x, &y);

		if (x >= 40 && x < 600 && y >= 200 && y < 440) {
			i = (y - 140) / 60;
			if (nPressed) nPressed = i;
			_RECT r = { 44, i * 60 + 144, 596, i * 60 + 196 };
			_FrameRect(NULL, r, 0x80FF);
		}

		Game_Paint();

		switch (nPressed) {
		case 1:
			break;
		case 2:
			break;
		case 3:
			break;
		case 4:
			GameStatus = -2;
			break;
		default:
			nPressed = 0;
		}

		SDL_Delay(30);
	}

	for (int i = 0, m = sizeof(bmImg) / sizeof(bmImg[0]); i < m; i++) {
		SDL_DestroyTexture(bmImg[i]);
	}
	SDL_DestroyTexture(bmG_Back);
	SDL_DestroyTexture(bmG_Lv);

	SDL_DestroyRenderer(renderer);
	SDL_DestroyWindow(window);

	for (int i = 0; i < 3; i++) TTF_CloseFont(m_objFont[i]);

	IMG_Quit();
	TTF_Quit();
	SDL_Quit();

#ifdef ANDROID
	exit(0);
#endif
	return 0;
}
