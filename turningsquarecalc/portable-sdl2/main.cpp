#include "main.h"
#include "FileSystem.h"
#include "SimpleArrayVB6.h"
#include "clsBloxorz.h"
#include "clsBloxorzGame.h"
#include "clsTheFile.h"
#include "MyFormat.h"

#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <vector>
#include <map>

#include <SDL.h>
#include <SDL_ttf.h>
#include <SDL_image.h>

GNUGetText objText;

TTF_Font* m_objFont[3] = {};

SDL_Window *window = NULL;
SDL_Renderer *renderer = NULL;

// these two are render targets
SDL_Texture *bmG_Back = NULL; // usually contain background, level name, etc.
SDL_Texture *bmG_Lv = NULL; // usually contains background and layer 0

bool bRenderTargetDirty = false;

SDL_Texture *bmImg[5] = {};

int cmbMode_ListIndex;
std::vector<std::string> cmbMode_List;

struct typeTheBitmap3 {
	int ImgIndex, x, y, w, h, dx, dy;
	typeTheBitmap3() : ImgIndex(-1), x(0), y(0), w(0), h(0), dx(0), dy(0) {}
	typeTheBitmap3(int _index, int _x, int _y, int _w, int _h, int _dx, int _dy) :
		ImgIndex(_index), x(_x), y(_y), w(_w), h(_h), dx(_dx), dy(_dy)
	{
	}
};

struct typeTheBitmap2 : public typeTheBitmap3 {
	int ow; // unused?
	int oh; // unused?
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

/////'         *          '/////
/////' *        x=10,y=16 '/////
/////'          *         '/////
/////'  *x=32,y=-5        '/////

bool bRun = true;

std::map<std::string, std::string> objConfig;

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

void PaintPicture(SDL_Texture* objSrc, SDL_Texture* objDest, int nDestLeft, int nDestTop, int nWidth, int nHeight, int nSrcLeft, int nSrcTop) {
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
	SDL_SetTextureAlphaMod(objSrc, 255);
	SDL_RenderCopy(renderer, objSrc, &r1, &r2);
}

void WaitForNextFrame() {
	SDL_Delay(15);
}

int DoEvents() {
	SDL_Event event;
	while (SDL_PollEvent(&event)) {
		if (event.type == SDL_QUIT) bRun = false;
	}
	return bRun ? 1 : 0;
}

void AlphaPaintPicture(SDL_Texture* objSrc, SDL_Texture* objDest, int nDestLeft, int nDestTop, int nWidth, int nHeight, int nSrcLeft, int nSrcTop, int nAlpha) {
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

void NormalizeCursorPos(int &x, int &y) {
	int w, h;
	SDL_GetWindowSize(window, &w, &h);
	if (w * 3 > h * 4) {
		x = ((x - w / 2) * 480) / h + 320;
		y = (y * 480) / h;
	} else {
		x = (x * 640) / w;
		y = ((y - h / 2) * 640) / w + 240;
	}
}

// return normalized position
int _GetCursorPos(int *x, int *y) {
	int x1, y1;
	int ret = SDL_GetMouseState(&x1, &y1);
	if (x || y) {
		NormalizeCursorPos(x1, y1);
		if (x) *x = x1;
		if (y) *y = y1;
	}
	return ret;
}

/*
'TODO:multiline support
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
		objTemp = TTF_RenderUTF8_Blended_Wrapped(fnt, s.c_str(), fg, (Style & _DT_WORDBREAK) ? _Width : 1024);
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

SDL_Texture* _LoadPictureFromFile(const char* _FileName, const char* _MaskFile) {
	SDL_Surface *bm = IMG_Load(_FileName);
	if (bm == NULL) {
		printf("[LoadPictureFromFile] Fatal Error: Failed to load file '%s'\n", _FileName);
		exit(-1);
	}

	SDL_Texture *ret = NULL;

	if (_MaskFile) {
		SDL_Surface *bmMask = IMG_Load(_MaskFile);
		if (bmMask == NULL) {
			printf("[LoadPictureFromFile] Fatal Error: Failed to load file '%s'\n", _MaskFile);
			exit(-1);
		}

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
			d1[i] = (d1[i] & 0x00FFFFFF) | (d2[i] << 24);
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
	ret.dy = NewY - bm.dy;
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
		typeTheBitmapArray &ani = Anis(Ani_Layer0);
		ani.resize(12);

		pTheBitmapConvert(bmps(108), ani[clsBloxorz::GROUND], 4, 8); // block
		pTheBitmapConvert(bmps(119), ani[clsBloxorz::SOFT_BUTTON], 4, 8); // soft
		pTheBitmapConvert(bmps(120), ani[clsBloxorz::HARD_BUTTON], 4, 8); // heavy
		pTheBitmapConvert(bmps(130), ani[clsBloxorz::TELEPORTER], 4, 10); // transport
		pTheBitmapConvert(bmps(131), ani[clsBloxorz::THIN_GROUND], 4, 8); // thin

		ani[clsBloxorz::BRIDGE_ON] = typeTheBitmap3(3, 44, 28, 44, 28, 0, 5); // bridge on
		pTheBitmapConvert(bmps(121), ani[clsBloxorz::GOAL], 5, 11); // end
		ani[clsBloxorz::ICE] = typeTheBitmap3(3, 0, 0, 44, 28, 0, 5); // ice
		ani[clsBloxorz::PYRAMID] = typeTheBitmap3(3, 0, 28, 44, 28, 0, 5); // pyramid
		ani[clsBloxorz::WALL] = ani[clsBloxorz::GROUND]; // stone
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
	for (int i = 0; animations[i].Index >= 0; i++) {
		pInitBoxAnimation(animations[i]);
	}
	{
		typeTheBitmapArray &ani = Anis(3);
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
		typeTheBitmapArray &ani = Anis(Ani_Misc);
		ani.resize(21);
		ani[1] = typeTheBitmap3(3, 88, 0, 44, 28, 0, 5); // bridge off
		ani[2] = typeTheBitmap3(3, 44, 0, 44, 28, 0, 5); // bridge on
		ani[3] = typeTheBitmap3(0, bmps(307).x, bmps(307).y, bmps(307).w / 2, bmps(307).h, bmps(307).w / 2, bmps(307).h / 2); // "["
		ani[4] = typeTheBitmap3(0, bmps(307).x + bmps(307).w / 2, bmps(307).y, bmps(307).w / 2, bmps(307).h, 0, bmps(307).h / 2); // "["
		pTheBitmapConvert(bmps(504), ani[5], 80, 98); // blur box
		ani[6] = typeTheBitmap3(3, 228, 0, 44, 52, 0, 34); // box
	}
}

int GetAnimationCount(int Index) {
	return Anis(Index).size() - 1;
}

void pTheBitmapDraw2(SDL_Texture *hdc, int Index, int x, int y, int Alpha) {
	const typeTheBitmap2& d = bmps(Index);
	if (d.ImgIndex >= 0) {
		AlphaPaintPicture(bmImg[d.ImgIndex], hdc, x - d.dx, y - d.dy, d.w, d.h, d.x, d.y, Alpha);
	}
}

void pTheBitmapDraw3(SDL_Texture *hdc, int Index, int Index2, int x, int y, int Alpha) {
	const typeTheBitmap3& d = Anis(Index)[Index2];
	if (d.ImgIndex >= 0) {
		AlphaPaintPicture(bmImg[d.ImgIndex], hdc, x - d.dx, y - d.dy, d.w, d.h, d.x, d.y, Alpha);
	}
}

void pGameDrawBox(SDL_Texture* hdc, int Index, int Index2, int x, int y, int Alpha) {
	if (Index2 < (int)Anis(Index + 30).size()) {
		const typeTheBitmap3& d = Anis(Index + 30)[Index2];
		if (d.ImgIndex >= 0) {
			AlphaPaintPicture(bmImg[d.ImgIndex], hdc, x - d.dx, y - d.dy, d.w, d.h, d.x, d.y, Alpha / 2);
		}
	}
	if (Index2 < (int)Anis(Index).size()) {
		const typeTheBitmap3& d = Anis(Index)[Index2];
		if (d.ImgIndex >= 0) {
			AlphaPaintPicture(bmImg[d.ImgIndex], hdc, x - d.dx, y - d.dy, d.w, d.h, d.x, d.y, Alpha);
		}
	}
}

void pGameDrawLayer0(SDL_Texture *hdc, const Array2D<unsigned char, 1, 1>& d, int StartX, int StartY) {
	int i, j, x, y;
	const int datw = UBound(d, 1);
	const int dath = UBound(d, 2);
	StartX += datw * 32;
	StartY -= datw * 5;
	for (i = datw; i >= 1; i--) {
		StartX -= 32; StartY += 5; x = StartX; y = StartY;
		for (j = 1; j <= dath; j++) {
			pTheBitmapDraw3(hdc, Ani_Layer0, d(i, j), x, y);
			x += 10; y += 16;
		}
	}
}

void pGameDrawLayer1(SDL_Texture *hdc, const Array2D<unsigned char, 1, 1>& GameD, int GameX, int GameY, int GameX2, int GameY2, int GameLayer0SX, int GameLayer0SY, int GameS,
	bool DrawBox, bool DrawBoxShadow, int Index, int Index2, int BoxDeltaY, int BoxAlpha, bool WithLayer0, int BoxDeltaX, bool NoZDepth) {
	int i, j, x, y, x2, y2, dy, FS;
	bool bx;

	const int GameW = UBound(GameD, 1);
	const int GameH = UBound(GameD, 2);

	dy = BoxDeltaY;
	if (NoZDepth) BoxDeltaY = 0;

	// determine draw direction (???)
	FS = (GameS == GameS_Vertical) ? 2 : 1;
	bx = BoxDeltaY >= 0 && BoxDeltaY <= 32;

	// draw box first?
	if (DrawBox && (BoxDeltaY > 32 || GameX > GameW || GameY < 1)) {
		x = GameLayer0SX + (GameX - 1) * 32 + (GameY - 1) * 10 + BoxDeltaX;
		y = GameLayer0SY - (GameX - 1) * 5 + (GameY - 1) * 16 + dy;
		if (DrawBoxShadow) pGameDrawBox(hdc, Index, Index2, x, y, BoxAlpha);
		else pTheBitmapDraw3(hdc, Index, Index2, x, y, BoxAlpha);
	}

	// draw
	switch (FS) {
	case 1:
		x = GameLayer0SX + GameW * 32;
		y = GameLayer0SY - GameW * 5;
		for (j = 1; j <= GameH; j++) {
			x2 = x; y2 = y;
			for (i = GameW; i >= 1; i--) {
				x2 -= 32; y2 += 5;
				if (WithLayer0) pTheBitmapDraw3(hdc, Ani_Layer0, GameD(i, j), x2, y2);
				if (GameD(i, j) == clsBloxorz::WALL) pTheBitmapDraw3(hdc, Ani_Misc, 6, x2, y2);
				// draw box?
				if (DrawBox && bx && GameX == i && GameY == j) {
					if (DrawBoxShadow) pGameDrawBox(hdc, Index, Index2, x2 + BoxDeltaX, y2 + dy, BoxAlpha);
					else pTheBitmapDraw3(hdc, Index, Index2, x2 + BoxDeltaX, y2 + dy, BoxAlpha);
				}
				// draw box 2?
				if (DrawBox && GameS == GameS_Single && GameX2 == i && GameY2 == j) {
					if (DrawBoxShadow) pGameDrawBox(hdc, 13, 1, x2, y2, BoxAlpha);
					else pTheBitmapDraw3(hdc, 13, 1, x2, y2, BoxAlpha);
				}
			}
			x += 10; y += 16;
		}
		break;
	case 2:
		x = GameLayer0SX + GameW * 32;
		y = GameLayer0SY - GameW * 5;
		for (i = GameW; i >= 1; i--) {
			x -= 32; y += 5; x2 = x; y2 = y;
			for (j = 1; j <= GameH; j++) {
				if (WithLayer0) pTheBitmapDraw3(hdc, Ani_Layer0, GameD(i, j), x2, y2);
				if (GameD(i, j) == clsBloxorz::WALL) pTheBitmapDraw3(hdc, Ani_Misc, 6, x2, y2);
				// draw box?
				if (DrawBox && bx && GameX == i && GameY == j) {
					if (DrawBoxShadow) pGameDrawBox(hdc, Index, Index2, x2 + BoxDeltaX, y2 + dy, BoxAlpha);
					else pTheBitmapDraw3(hdc, Index, Index2, x2 + BoxDeltaX, y2 + dy, BoxAlpha);
				}
				// draw box 2?
				if (DrawBox && GameS == GameS_Single && GameX2 == i && GameY2 == j) {
					if (DrawBoxShadow) pGameDrawBox(hdc, 13, 1, x2, y2, BoxAlpha);
					else pTheBitmapDraw3(hdc, 13, 1, x2, y2, BoxAlpha);
				}
				x2 += 10; y2 += 16;
			}
		}
		break;
	}

	// draw box last?
	if (DrawBox && (BoxDeltaY < 0 || GameX < 1 || GameY > GameH)) {
		x = GameLayer0SX + (GameX - 1) * 32 + (GameY - 1) * 10 + BoxDeltaX;
		y = GameLayer0SY - (GameX - 1) * 5 + (GameY - 1) * 16 + dy;
		if (DrawBoxShadow) pGameDrawBox(hdc, Index, Index2, x, y, BoxAlpha);
		else pTheBitmapDraw3(hdc, Index, Index2, x, y, BoxAlpha);
	}
}

void OnAutoLoad() {
	// load config
	u8file *f = u8fopen((externalStoragePath + "/config.cfg").c_str(), "rb");
	if (!f) return;

	for (;;) {
		std::string s;
		if (u8fgets2(s, f) == NULL) break;

		std::string::size_type lp = s.find_first_of("\r\n");
		if (lp != std::string::npos) s = s.substr(0, lp);
		lp = s.find_first_of('=');
		if (lp != std::string::npos) {
			objConfig[s.substr(0, lp)] = s.substr(lp + 1);
		}
	}

	u8fclose(f);
}

void OnAutoSave() {
	// save config
	u8file *f = u8fopen((externalStoragePath + "/config.cfg").c_str(), "wb");
	if (!f) return;

	for (std::map<std::string, std::string>::const_iterator it = objConfig.begin(); it != objConfig.end(); ++it) {
		u8fputs2(it->first, f);
		u8fputc('=', f);
		u8fputs2(it->second, f);
		u8fputc('\n', f);
	}

	u8fclose(f);
}

std::string GetSetting(const std::string& name, const std::string& _default) {
	std::map<std::string, std::string>::const_iterator it = objConfig.find(name);
	if (it == objConfig.end()) return _default;
	else return it->second;
}

void SaveSetting(const std::string& name, const std::string& value) {
	objConfig[name] = value;
}

static int MyEventFilter(void *userdata, SDL_Event *evt){
	switch (evt->type){
	case SDL_QUIT:
		bRun = false;
		break;
	case SDL_APP_TERMINATING:
	case SDL_APP_WILLENTERBACKGROUND:
		OnAutoSave();
		break;
	case SDL_APP_LOWMEMORY:
		printf("[main] Fatal Error: Program received SDL_APP_LOWMEMORY! Program will abort\n");
		OnAutoSave();
		exit(-1);
		break;
	case SDL_WINDOWEVENT:
		switch (evt->window.event){
		case SDL_WINDOWEVENT_EXPOSED:
			break;
		case SDL_WINDOWEVENT_SIZE_CHANGED:
			break;
		}
		break;
	case SDL_KEYDOWN:
		// check Alt+F4 or Ctrl+Q exit event (for all platforms)
		if ((evt->key.keysym.scancode == SDL_SCANCODE_F4 && (evt->key.keysym.mod & KMOD_ALT) != 0)
			|| (evt->key.keysym.sym == SDLK_q && (evt->key.keysym.mod & KMOD_CTRL) != 0))
		{
			bRun = false;
		}
		break;
	case SDL_RENDER_TARGETS_RESET:
		bRenderTargetDirty = true;
		break;
	case SDL_RENDER_DEVICE_RESET:
		// FIXME: currently unsupported
		OnAutoSave();
		bRenderTargetDirty = true;
		// exit(-1);
		break;
	}

	return 1;
}

int main(int argc, char** argv) {
	srand(time(NULL));

	initPaths();

	objText.LoadFileWithAutoLocale("locale/*.mo");

	OnAutoLoad();

	SDL_SetHint(SDL_HINT_RENDER_VSYNC, "1");
	SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "linear");

	if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER) < 0) {
		printf("Fatal Error: Can't init SDL!\n");
		exit(-1);
	}

#ifdef ANDROID
	window = SDL_CreateWindow(_("Turning Square").c_str(), SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 0, 0, SDL_WINDOW_FULLSCREEN_DESKTOP);
#else
	window = SDL_CreateWindow(_("Turning Square").c_str(), SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 640, 480, SDL_WINDOW_RESIZABLE);
#endif
	if (window == NULL) {
		printf("Fatal Error: Can't create window!\n");
		exit(-1);
	}
	renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC | SDL_RENDERER_TARGETTEXTURE);
	if (renderer == NULL) {
		printf("Fatal Error: Can't create renderer!\n");
		exit(-1);
	}
	SDL_RenderSetLogicalSize(renderer, 640, 480);

	if (TTF_Init() < 0) {
		printf("Fatal Error: Can't init SDL_ttf!\n");
		exit(-1);
	}
	if (IMG_Init(IMG_INIT_JPG | IMG_INIT_PNG) < 0) {
		printf("Fatal Error: Can't init SDL_image!\n");
		exit(-1);
	}

#ifdef ANDROID
#define FONT_FILE_PREFIX "/system/fonts/"
#else
#define FONT_FILE_PREFIX "data/"
#endif

	const int fontSize[] = { 16, 36, 64 };

	for (int i = 0; i < sizeof(fontSize) / sizeof(fontSize[0]); i++) {
		m_objFont[i] = TTF_OpenFont(FONT_FILE_PREFIX "DroidSansFallback.ttf", fontSize[i]);
		if (m_objFont[i] == NULL) {
			printf("Fatal Error: Can't load font file!\n");
			exit(-1);
		}
	}

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

	SDL_SetEventFilter(MyEventFilter, NULL);

	// run main loop
	int x, y;
	int nPressed = 1;
	SDL_Event event;

	while (bRun) {
		if (nPressed || bRenderTargetDirty) {
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

			bRenderTargetDirty = false;
		}

		// get messages
		nPressed = 0;
		while (SDL_PollEvent(&event)) {
			switch (event.type) {
			case SDL_MOUSEBUTTONDOWN:
				if (event.button.button == SDL_BUTTON_LEFT) nPressed = 10;
				break;
			}
		}
		if (!bRun) break;

		// test only
		_Cls(NULL);
		PaintPicture(bmG_Back, NULL);

		_GetCursorPos(&x, &y);

		if (x >= 40 && x < 600 && y >= 200 && y < 440) {
			int i = (y - 140) / 60;
			if (nPressed) nPressed = i;
			_RECT r = { 44, i * 60 + 144, 596, i * 60 + 196 };
			_FrameRect(NULL, r, 0x0080FF);
		}

		Game_Paint();
		WaitForNextFrame();

		if (nPressed == 1) { // start game
			clsBloxorzGame objGame;
			objGame.Game_Init();
		} else if (nPressed == 2) { // instructions
			clsBloxorzGame::Game_Instruction_Loop();
		} else if (nPressed == 3) { // editor
			// TODO: editor
		} else if (nPressed == 4) { // exit
			bRun = false;
			break;
		} else {
			nPressed = 0;
		}
	}

	OnAutoSave();

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
