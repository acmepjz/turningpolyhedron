#include "clsBloxorzGame.h"
#include "clsTheFile.h"
#include "main.h"
#include "MyFormat.h"
#include "SimpleMenu.h"
#include "FileSystem.h"
#include <SDL.h>

#define GAME_PAINT_ETC() { \
	Game_Paint(); \
	WaitForNextFrame(); \
	DoEvents(); \
	if (GameStatus < 0 || !bRun) return; }

clsBloxorzGame::clsBloxorzGame() {

}

clsBloxorzGame::~clsBloxorzGame() {

}

void clsBloxorzGame::Game_DrawLayer1(SDL_Texture *hdc, bool DrawBox, bool DrawBoxShadow, int Index, int Index2, int BoxDeltaY, int BoxAlpha, bool WithLayer0, int BoxDeltaX, bool NoZDepth) {
	pGameDrawLayer1(hdc, GameD, GameX, GameY, GameX2, GameY2, GameLayer0SX, GameLayer0SY, GameS,
		DrawBox, DrawBoxShadow, Index, Index2, BoxDeltaY, BoxAlpha, WithLayer0, BoxDeltaX, NoZDepth);
}

void clsBloxorzGame::Game_LoadLevel(const char* fn) {
	bool b = false;

	clsTheFile objFile;

	if (objFile.LoadFile(fn, BOX_SIGNATURE, true)) {
		typeFileNodeArray *k = objFile.FindNodeArray(BOX_LEV);
		if (k) {
			int m = k->nodes.size();
			if (m > 0) {
				Lev.ReDim(m);
				for (int i = 1; i <= m; i++) {
					Lev(i).LoadLevel(i, objFile);
				}
				b = true;
			}
		}
	}

	GameIsRndMap = false;

	if (b) {
		std::string s = fn;
		std::string::size_type lpe = s.find_last_of("\\/");
		if (lpe != std::string::npos) s = s.substr(lpe + 1);
		LevFileName = fn;
		Me_Tag = " (" + s + ")";
	} else {
		printf("[Game_LoadLevel]: Failed to load level file '%s'\n", fn);

		LevFileName.clear();
		Me_Tag.clear();
		Lev.ReDim(1);
		Lev(1).Create(15, 10);

		std::vector<unsigned char> &d = Lev(1)._xx_dat;
		for (int i = 0, m = d.size(); i < m; i++) {
			d[i] = clsBloxorz::GROUND;
		}
	}

	GameLev = 1;
}

void clsBloxorzGame::Game_InitBack() {
	PaintPicture(bmImg[4], bmG_Back);

	// draw text
	if (GameIsRndMap) {
		if (Lev.UBound() > 1) {
			DrawTextB(bmG_Back, str(MyFormat(_("Random level %d of %d")) << GameLev << Lev.UBound()) + Me_Tag, m_objFont[0],
				8, 8, 480, 16, _DT_VCENTER | _DT_SINGLELINE, 0xFFFFFF);
		} else {
			DrawTextB(bmG_Back, _("Random level") + Me_Tag, m_objFont[0],
				8, 8, 480, 16, _DT_VCENTER | _DT_SINGLELINE, 0xFFFFFF);
		}
		DrawTextB(bmG_Back, str(MyFormat(_("Seed: %s")) << RndMapSeed), m_objFont[0],
			272, 8, 480, 16, _DT_VCENTER | _DT_SINGLELINE, 0xFFFFFF);
		// button
		AlphaPaintPicture(bmImg[3], bmG_Back, 480, 9, 16, 16, 96, 32);
		DrawTextB(bmG_Back, _("Copy"), m_objFont[0],
			496, 8, 48, 16, _DT_VCENTER | _DT_SINGLELINE, 0x0080FF);
	} else {
		DrawTextB(bmG_Back, str(MyFormat(_("Level %d of %d")) << GameLev << Lev.UBound()) + Me_Tag, m_objFont[0],
			8, 8, 480, 16, _DT_VCENTER | _DT_SINGLELINE, 0xFFFFFF);
	}
	DrawTextB(bmG_Back, _("Moves"), m_objFont[0],
		8, 24, 72, 16, _DT_VCENTER | _DT_SINGLELINE, 0xFFFFFF);
	DrawTextB(bmG_Back, _("Time used"), m_objFont[0],
		8, 40, 72, 16, _DT_VCENTER | _DT_SINGLELINE, 0xFFFFFF);
	DrawTextB(bmG_Back, _("Retries"), m_objFont[0],
		8, 56, 72, 16, _DT_VCENTER | _DT_SINGLELINE, 0xFFFFFF);
	DrawTextB(bmG_Back, _("Menu"), m_objFont[0],
		584, 8, 48, 16, _DT_CENTER | _DT_VCENTER | _DT_SINGLELINE, 0x0080FF);
}

void clsBloxorzGame::RedrawLevelName() {
	if (!bRenderTargetDirty) return;
	_Cls(bmG_Lv);
	std::string s;
	if (GameIsRndMap) {
		if (Lev.UBound() > 1) {
			s = str(MyFormat(_("Random Level %d")) << GameLev);
		} else {
			s = _("Random Level");
		}
	} else {
		s = str(MyFormat(_("Level %d")) << GameLev);
	}
	DrawTextB(bmG_Lv, s, m_objFont[1],
		0, 0, 640, 480, _DT_CENTER | _DT_VCENTER | _DT_SINGLELINE, 0xFFFFFF);
	bRenderTargetDirty = false;
}

void clsBloxorzGame::RedrawBack() {
	if (bRenderTargetDirty) Game_InitBack();
	bRenderTargetDirty = false;
}

void clsBloxorzGame::RedrawBackAndLayer0(bool forceLayer0) {
	if (bRenderTargetDirty) Game_InitBack();
	if (bRenderTargetDirty || forceLayer0) {
		PaintPicture(bmG_Back, bmG_Lv);
		pGameDrawLayer0(bmG_Lv, GameD, GameLayer0SX, GameLayer0SY);
	}
	bRenderTargetDirty = false;
}

void clsBloxorzGame::Game_Loop() {
	int i, j, k, m;
	int w, h;
	int x, y, x2, y2;
	Array2D<unsigned char, 1, 1> d;
	Array2D<int, 1, 1> dL;
	Array2D<float, 1, 1> dSng;
	bool bEnsureRedraw;
	int nBridgeChangeCount;
	int idx, idx2, nAnimationIndex;
	int kx, ky, kt;
	bool IsSlipping;
	std::string s, sSolution;
	int t;
	int QIE, QIE_0;

	bool isSpacePressed = false; // ad-hoc

	// buttons
	const _RECT buttons[2] = {
			{ 582, 6, 634, 26 }, // menu
			{ 474, 6, 538, 26 }, // copy
	};

	int buttonHighlight = -1, buttonClicked = -1;

	while (GameStatus >= 0 && bRun) {
		switch (GameStatus) {
		case 0: // load level
			// init layer0 size
			GameW = Lev(GameLev).Width();
			GameH = Lev(GameLev).Height();
			w = GameW * 32 + GameH * 10;
			h = GameW * 5 + GameH * 16 + 16;
			GameLayer0SX = (640 - w) / 2;
			GameLayer0SY = (480 - h) / 2 + GameW * 5 + 8;

			// init
			GameLvRetry = -1;
			GameLvStartTime = 0;
			GameDemoPos = 0;
			GameDemoBegin = false;

			// level name animation
			bRenderTargetDirty = true;
			for (i = 0; i <= 255; i += 17) {
				RedrawLevelName();
				_Cls(NULL);
				AlphaPaintPicture(bmG_Lv, NULL, 0, 0, 640, 480, 0, 0, i);
				GAME_PAINT_ETC();
			}
			for (i = 0; i < 32; i++) {
				RedrawLevelName();
				_Cls(NULL);
				PaintPicture(bmG_Lv, NULL);
				GAME_PAINT_ETC();
			}
			for (i = 255; i >= 0; i -= 17) {
				RedrawLevelName();
				_Cls(NULL);
				AlphaPaintPicture(bmG_Lv, NULL, 0, 0, 640, 480, 0, 0, i);
				GAME_PAINT_ETC();
			}

			// over
			GameStatus = 1;
			break;

		case 1: // start level
			// init level
			GameD.ReDim(GameW, GameH);
			memcpy(&(GameD.data[0]), &(Lev(GameLev)._xx_dat[0]), GameW*GameH);
			GameX = Lev(GameLev).StartX;
			GameY = Lev(GameLev).StartY;
			GameX2 = GameY2 = 0;
			GameS = GameFS = 0;
			IsSlipping = false;

			// init
			nBridgeChangeCount = 0;
			kt = 0;
			if (!GameDemoBegin) GameLvRetry++;
			GameLvStep = 0;
			sSolution.clear();
			GameDemoPos = GameDemoBegin ? 1 : 0;
			GameDemoBegin = false;
			QIE = QIE_0 = 0;

			// init back
			bRenderTargetDirty = true;

			// animate
			dL.ReDim(GameW, GameH * 2);
			for (j = 1; j <= GameH; j++) {
				for (i = 1; i <= GameW; i++) {
					dL(i, j) = rand() & 0xF;
					dL(i, j + GameH) = -1;
				}
			}
			for (i = 0; i <= 255; i += 51) {
				RedrawBack();
				_Cls(NULL);
				AlphaPaintPicture(bmG_Back, NULL, 0, 0, 640, 480, 0, 0, i);
				GAME_PAINT_ETC();
			}
			for (k = 0; k <= 36; k++) {
				RedrawBack();
				_Cls(NULL);
				PaintPicture(bmG_Back, NULL);
				x = GameLayer0SX + GameW * 32;
				y = GameLayer0SY - GameW * 5;
				for (i = GameW; i >= 1; i--) {
					x -= 32; y += 5; x2 = x; y2 = y;
					for (j = 1; j <= GameH; j++) {
						if (dL(i, j) >= 0 && k >= dL(i, j)) {
							dL(i, j) = -32;
							dL(i, j + GameH) = 400;
						}
						if (dL(i, j + GameH) >= 0) {
							pTheBitmapDraw3(NULL, Ani_Layer0, GameD(i, j), x2, y2 + dL(i, j + GameH), -dL(i, j));
							if (GameD(i, j) == clsBloxorz::WALL) {
								pTheBitmapDraw3(NULL, Ani_Misc, 6, x2, y2 + dL(i, j + GameH), -dL(i, j));
							}
							dL(i, j + GameH) = (dL(i, j + GameH) * 3) / 4;
							dL(i, j) -= 16;
							if (dL(i, j) < -255) dL(i, j) = -255;
						}
						x2 += 10; y2 += 16;
					}
				}
				GAME_PAINT_ETC();
			}

			// init array
			dL.ReDim(GameW, GameH);

			// draw layer0
			RedrawBackAndLayer0(true);

			// box falls
			for (j = -600; j <= 0; j += 50) {
				RedrawBackAndLayer0();
				_Cls(NULL);
				PaintPicture(bmG_Lv, NULL);
				Game_DrawLayer1(NULL, true, false, Ani_Misc, 5, j);
				GAME_PAINT_ETC();
			}
			m = GetAnimationCount(29);
			for (i = 1; i <= m; i++) {
				RedrawBackAndLayer0();
				_Cls(NULL);
				PaintPicture(bmG_Lv, NULL);
				Game_DrawLayer1(NULL, true, true, 29, i);
				GAME_PAINT_ETC();
			}

			// init time
			t = 0;
			if (GameLvStartTime == 0) GameLvStartTime = SDL_GetTicks();

			// end
			GameStatus = 9;
			break;

		case 2: // block fall
			switch (GameFS) {
			case GameFS_Up: x2 = -2; y2 = -4; break;
			case GameFS_Down: x2 = 2; y2 = 4; break;
			case GameFS_Left: x2 = -5; y2 = 1; break;
			case GameFS_Right: x2 = 5; y2 = -1; break;
			default: // may be block 2 fall
				x2 = y2 = 0; GameFS = GameFS_Up; break;
			}

			idx = 70 + 4 * GameS + GameFS;
			idx2 = 1; w = 0; h = 1; x = 0;
			for (i = 0; i <= 30; i++) {
				w += h + y2;
				h++;
				x += x2;
				idx2++; if (idx2 > 9) idx2 = 1;
				RedrawBack();
				_Cls(NULL);
				PaintPicture(bmG_Back, NULL);
				Game_DrawLayer1(NULL, true, false, idx, idx2, w, 255, true, x);
				GAME_PAINT_ETC();
			}

			// fall animation
			dL.ReDim(GameW, GameH * 2);
			for (j = 1; j <= GameH; j++) {
				for (i = 1; i <= GameW; i++) {
					dL(i, j) = rand() % 15;
				}
			}
			for (k = 0; k <= 30; k++) {
				RedrawBack();
				_Cls(NULL);
				PaintPicture(bmG_Back, NULL);
				x = GameLayer0SX + GameW * 32;
				y = GameLayer0SY - GameW * 5;
				for (i = GameW; i >= 1; i--) {
					x -= 32; y += 5; x2 = x; y2 = y;
					for (j = 1; j <= GameH; j++) {
						if (dL(i, j) >= 0 && k >= dL(i, j)) dL(i, j) = -2;
						if (dL(i, j + GameH) < 510) {
							pTheBitmapDraw3(NULL, Ani_Layer0, GameD(i, j), x2, y2 + dL(i, j + GameH), 255 - dL(i, j + GameH) / 2);
							if (GameD(i, j) == clsBloxorz::WALL) {
								pTheBitmapDraw3(NULL, Ani_Misc, 6, x2, y2 + dL(i, j + GameH), 255 - dL(i, j + GameH) / 2);
							}
							if (dL(i, j) < 0) {
								dL(i, j + GameH) -= dL(i, j);
								dL(i, j) -= 2;
							}
						}
						x2 += 10; y2 += 16;
					}
				}
				GAME_PAINT_ETC();
			}

			// fade out
			for (i = 255; i >= 0; i -= 51) {
				RedrawBack();
				_Cls(NULL);
				AlphaPaintPicture(bmG_Back, NULL, 0, 0, 640, 480, 0, 0, i);
				GAME_PAINT_ETC();
			}

			// end
			GameStatus = 1; // restart
			break;

		case 3: // block fall 2
			dL.ReDim(GameW, GameH * 2);
			for (j = 1; j <= GameH; j++) {
				for (i = 1; i <= GameW; i++) {
					dL(i, j) = 20 + (rand() % 15);
				}
			}
			dL(GameX, GameY) = -2;
			w = h = 0;
			for (k = 0; k <= 50; k++) {
				RedrawBack();
				_Cls(NULL);
				PaintPicture(bmG_Back, NULL);
				x = GameLayer0SX + GameW * 32;
				y = GameLayer0SY - GameW * 5;
				for (i = GameW; i >= 1; i--) {
					x -= 32; y += 5; x2 = x; y2 = y;
					for (j = 1; j <= GameH; j++) {
						if (dL(i, j) >= 0 && k >= dL(i, j)) dL(i, j) = -2;
						if (dL(i, j + GameH) < 510) {
							pTheBitmapDraw3(NULL, Ani_Layer0, GameD(i, j), x2, y2 + dL(i, j + GameH), 255 - dL(i, j + GameH) / 2);
							if (GameD(i, j) == clsBloxorz::WALL) {
								pTheBitmapDraw3(NULL, Ani_Misc, 6, x2, y2 + dL(i, j + GameH), 255 - dL(i, j + GameH) / 2);
							}
							if (dL(i, j) < 0) {
								dL(i, j + GameH) -= dL(i, j);
								dL(i, j) -= 2;
							}
						}
						if (w < 510 && i == GameX && j == GameY) {
							w += h; h++;
							pTheBitmapDraw3(NULL, 1, 1, x2, y2 + w);
						}
						x2 += 10; y2 += 16;
					}
				}
				GAME_PAINT_ETC();
			}

			// fade out
			for (i = 255; i >= 0; i -= 51) {
				RedrawBack();
				_Cls(NULL);
				AlphaPaintPicture(bmG_Back, NULL, 0, 0, 640, 480, 0, 0, i);
				GAME_PAINT_ETC();
			}

			// end
			GameStatus = 1; // restart
			break;

		case 4: // win
			// block animation
			m = GetAnimationCount(30);
			for (i = 1; i <= m; i++) {
				RedrawBackAndLayer0();
				_Cls(NULL);
				PaintPicture(bmG_Lv, NULL);
				Game_DrawLayer1(NULL, true, false, 30, i);
				GAME_PAINT_ETC();
			}

			// animation
			dSng.ReDim(GameW, GameH * 3);
			dL.ReDim(GameW, GameH);
			w = GameLayer0SX + (GameX - 1) * 32 + (GameY - 1) * 10;
			h = GameLayer0SY - (GameX - 1) * 5 + (GameY - 1) * 16;
			x = GameLayer0SX + GameW * 32;
			y = GameLayer0SY - GameW * 5;
			for (i = GameW; i >= 1; i--) {
				x -= 32; y += 5; x2 = x; y2 = y;
				for (j = 1; j <= GameH; j++) {
					dSng(i, j) = (float)x2;
					dSng(i, j + GameH) = (float)y2;
					dL(i, j) = rand() & 0x3;
					dSng(i, j + GameH * 2) = 5.0f / (10.0f + dL(i, j)) /
						(10.0f + SDL_sqrtf(float((x2 - w)*(x2 - w) + (y2 - h)*(y2 - h))));
					x2 += 10; y2 += 16;
				}
			}
			for (k = 0; k <= 51; k++) {
				RedrawBack();
				_Cls(NULL);
				PaintPicture(bmG_Back, NULL);
				for (i = GameW; i >= 1; i--) {
					for (j = 1; j <= GameH; j++) {
						kx = dL(i, j);
						m = 255 - (5 + kx)*k;
						if (m > 0) {
							float tmpx = dSng(i, j);
							float tmpy = dSng(i, j + GameH);
							float tmp = dSng(i, j + GameH * 2)*k;
							dSng(i, j) -= (tmpy - h)*tmp;
							dSng(i, j + GameH) += (tmpx - w)*tmp;
							tmpx = dSng(i, j);
							tmpy = dSng(i, j + GameH);
							if (tmpx > -1E+4f && tmpx < 1E+4f && tmpy > -1E+4f && tmpy < 1E+4f) {
								x2 = (int)tmpx; y2 = (int)tmpy;
								pTheBitmapDraw3(NULL, Ani_Layer0, GameD(i, j), x2, y2, m);
								if (GameD(i, j) == clsBloxorz::WALL) {
									pTheBitmapDraw3(NULL, Ani_Misc, 6, x2, y2, m);
								}
							}
						}
					}
				}
				GAME_PAINT_ETC();
			}

			// clear up
			dSng.clear(); dL.clear();

			// fade out
			for (i = 255; i >= 0; i -= 51) {
				RedrawBack();
				_Cls(NULL);
				AlphaPaintPicture(bmG_Back, NULL, 0, 0, 640, 480, 0, 0, i);
				GAME_PAINT_ETC();
			}

			// end
			if (GameDemoPos == 0) {
				GameLev++;
				if (GameLev > Lev.UBound()) {
					if (GameIsRndMap) {
						// TODO: next random map
					}
					GameLev = 1;
				}
				GameStatus = 0; // next level
			} else { // just demo only
				GameLvRetry--;
				GameStatus = 1;
			}
			break;

		case 9: case 10: case 11: case 12: case 13: // playing...
			// calc index
			idx = GameS * 4 + 1; idx2 = 1;
			switch (GameStatus) {
			case 9: // check state valid
				switch (Lev(GameLev).BloxorzCheckIsValidState(GameD, GameX, GameY, GameS, GameX2, GameY2)) {
				case BState_Fall:
					GameStatus = 2;

					// block2 fall?
					m = 0;
					if (GameS == GameS_Single) {
						if (GameX2 > 0 && GameY2 > 0 && GameX2 <= GameW && GameY2 <= GameH) {
							switch (GameD(GameX2, GameY2)) {
							case clsBloxorz::EMPTY:
							case clsBloxorz::BRIDGE_OFF:
								m = 1;
								break;
							}
						} else {
							m = 1;
						}
					}

					if (m) {
						std::swap(GameX, GameX2);
						std::swap(GameY, GameY2);
						GameFS = 0;
					}
					break;
				case BState_Valid:
					GameStatus = (GameD(GameX, GameY) == clsBloxorz::GOAL && GameS == GameS_Upright) ? 4 : 10;
					break;
				case BState_Thin:
					GameStatus = 3;
					break;
				default: // unknown
					printf("[Game_Loop] Error: BloxorzCheckIsValidState returns unknown result\n");
					GameStatus = -1;
					break;
				}
				bEnsureRedraw = true;
				break;
			case 10: // press key?
				y = 0;
				if (GameDemoPos > 0 && kt < 32) { // don't press space too frequently
					if (GameDemoPos >(int)GameDemoS.size()) {
						y = 99;
					} else {
						switch (GameDemoS[GameDemoPos - 1]) {
						case 'U': case 'u':
							y = 1; break;
						case 'D': case 'd':
							y = 2; break;
						case 'L': case 'l':
							y = 3; break;
						case 'R': case 'r':
							y = 4; break;
						case 'S': case 's': case ' ': case '_':
							y = 5; break;
						case '\r': case '\n': case ',': case ';':
							y = 99; break;
						}
						GameDemoPos++;
					}
					if (y == 99) GameDemoPos = y = 0; // end of demo
				}
				if (SDL_GetKeyboardFocus() == window || y > 0) {
					const Uint8* _ks = SDL_GetKeyboardState(NULL);
					if (!_ks[SDL_SCANCODE_SPACE]) isSpacePressed = false;
					if (_ks[SDL_SCANCODE_R]) { // restart
						GameStatus = 1;
					} else if (_ks[SDL_SCANCODE_PAGEDOWN] && GameLev < Lev.UBound()) {
						GameLev++;
						GameStatus = 0;
					} else if (_ks[SDL_SCANCODE_PAGEUP] && GameLev > 1) {
						GameLev--;
						GameStatus = 0;
					}
					if (GameStatus <= 1) {
						// fade out
						for (i = 255; i >= 0; i -= 51) {
							RedrawBackAndLayer0();
							_Cls(NULL);
							AlphaPaintPicture(bmG_Lv, NULL, 0, 0, 640, 480, 0, 0, i);
							GAME_PAINT_ETC();
						}
					} else if ((_ks[SDL_SCANCODE_SPACE] && !isSpacePressed && GameDemoPos == 0) || y == 5) {
						isSpacePressed = true;
						if (GameS == GameS_Single) {
							// record step
							sSolution.push_back('S');
							// swap block
							std::swap(GameX, GameX2);
							std::swap(GameY, GameY2);
							// animation
							kx = GameLayer0SX + (GameX - 1) * 32 + (GameY - 1) * 10 + 21;
							ky = GameLayer0SY - (GameX - 1) * 5 + (GameY - 1) * 16 - 10;
							kt = 40;
						}
					} else {
						if (_ks[SDL_SCANCODE_UP] && GameDemoPos == 0) y = 1;
						else if (_ks[SDL_SCANCODE_DOWN] && GameDemoPos == 0) y = 2;
						else if (_ks[SDL_SCANCODE_LEFT] && GameDemoPos == 0) y = 3;
						else if (_ks[SDL_SCANCODE_RIGHT] && GameDemoPos == 0) y = 4;
						if (y > 0 && Lev(GameLev).BloxorzCheckIsMovable(GameD, GameX, GameY, GameS, y, &QIE)) {
							GameFS = y;
							GameStatus = 11;
							// init animation
							nAnimationIndex = QIE_0 ? (QIE > 0 ? 1 : 1 /* 6? */) : 2;
							// calc step
							GameLvStep++;
							// record step
							switch (y) {
							case 1: sSolution.push_back('U'); break;
							case 2: sSolution.push_back('D'); break;
							case 3: sSolution.push_back('L'); break;
							case 4: sSolution.push_back('R'); break;
							}
						}
					}
				}
				break;
			case 11: // moving animation
				// block???
				idx = GameS * 4 + GameFS;
				idx2 = (nAnimationIndex++);
				i = QIE ? 7 : GetAnimationCount(idx);
				if (nAnimationIndex >= i) GameStatus = 12;
				bEnsureRedraw = true;
				break;
			case 13: // slipping animation
				// block???
				idx = GameS * 4 + GameFS;
				idx2 = 1;
				nAnimationIndex++;
				if (nAnimationIndex >= 7) GameStatus = 12;

				// calc delta
				switch (GameFS) {
				case GameFS_Up: x2 = -10; y2 = -16; break;
				case GameFS_Down: x2 = 10; y2 = 16; break;
				case GameFS_Left: x2 = -32; y2 = 5; break;
				case GameFS_Right: x2 = 32; y2 = -5; break;
				}
				x2 = (x2*nAnimationIndex) >> 3;
				y2 = (y2*nAnimationIndex) >> 3;
				bEnsureRedraw = true;
				break;
			case 12: // check moved state
				QIE_0 = QIE; // :-/
				switch (QIE) {
				case GameFS_Up: x2 = 20; y2 = 32; break;
				case GameFS_Down: x2 = -10; y2 = -16; break;
				case GameFS_Left: x2 = 64; y2 = -10; break;
				case GameFS_Right: x2 = -32; y2 = 5; break;
				default: x2 = y2 = 0; break;
				}

				// calc new pos
				if (IsSlipping) {
					switch (GameFS) {
					case GameFS_Up: GameY--; break;
					case GameFS_Down: GameY++; break;
					case GameFS_Left: GameX--; break;
					case GameFS_Right: GameX++; break;
					}
				} else {
					switch (GameFS) {
					case GameFS_Up:
						GameY -= (GameS == GameS_Upright) ? 2 : 1;
						GameS = (GameS == GameS_Upright) ? GameS_Vertical :
							(GameS == GameS_Vertical) ? GameS_Upright : GameS;
						break;
					case GameFS_Down:
						GameY += (GameS == GameS_Vertical) ? 2 : 1;
						GameS = (GameS == GameS_Upright) ? GameS_Vertical :
							(GameS == GameS_Vertical) ? GameS_Upright : GameS;
						break;
					case GameFS_Left:
						GameX -= (GameS == GameS_Upright) ? 2 : 1;
						GameS = (GameS == GameS_Upright) ? GameS_Horizontal :
							(GameS == GameS_Horizontal) ? GameS_Upright : GameS;
						break;
					case GameFS_Right:
						GameX += (GameS == GameS_Horizontal) ? 2 : 1;
						GameS = (GameS == GameS_Upright) ? GameS_Horizontal :
							(GameS == GameS_Horizontal) ? GameS_Upright : GameS;
						break;
					}
				}

				// update index
				idx = GameS * 4 + 1;

				// check
				switch (Lev(GameLev).BloxorzCheckIsValidState(GameD, GameX, GameY, GameS, GameX2, GameY2)) {
				case BState_Fall:
					GameStatus = 2;
					break;
				case BState_Valid:
					GameStatus = 9;

					// press button
					nBridgeChangeCount = Lev(GameLev).BloxorzCheckPressButton(GameD, GameX, GameY, GameS, &dL, 115, 215);
					if (nBridgeChangeCount > 0) {
						PaintPicture(bmG_Back, bmG_Lv);
						pGameDrawLayer0(bmG_Lv, GameD, GameLayer0SX, GameLayer0SY);
					}

					// teleport?
					if (GameS == GameS_Upright && GameD(GameX, GameY) == clsBloxorz::TELEPORTER) {
						// animation
						for (i = 255; i >= 0; i -= 51) {
							RedrawBackAndLayer0();
							PaintPicture(bmG_Lv, NULL);
							Game_DrawLayer1(NULL, true, false, 1, 1, 0, i);
							GAME_PAINT_ETC();
						}

						// get position
						Lev(GameLev).GetTeleportPosition(GameX, GameY, GameX, GameY, GameX2, GameY2);

						// add check code
						if (GameX < 1 || GameX2 < 1 || GameY < 1 || GameY2 < 1
							|| GameX > GameW || GameX2 > GameW || GameY > GameH || GameY2 > GameH) {
							printf("[Game_Loop] Error: Teleport position out of map range\n");
							GameStatus = -1;
							return;
						}

						// new mode: check two box get together?
						GameS = GameS_Single;
						if (GameX == GameX2) {
							if (GameY + 1 == GameY2) GameS = GameS_Vertical;
							if (GameY == GameY2) GameS = GameS_Upright; // new mode
							else if (GameY - 1 == GameY2) {
								GameY = GameY2; GameS = GameS_Vertical;
							}
						} else if (GameY == GameY2) {
							if (GameX + 1 == GameX2) GameS = GameS_Horizontal;
							else if (GameX - 1 == GameX2) {
								GameX = GameX2; GameS = GameS_Horizontal;
							}
						}

						idx = 13; // update index (???)
						GameFS = 0; // clear last move to prevent ice

						// animation
						kx = GameLayer0SX + (GameX - 1) * 32 + (GameY - 1) * 10 + 21;
						ky = GameLayer0SY - (GameX - 1) * 5 + (GameY - 1) * 16 - 10;
						kt = 24;

						if (GameS == GameS_Horizontal) {
							kx += 16; ky -= 2;
						} else if (GameS == GameS_Vertical) {
							kx += 5; ky += 8;
						}

						for (i = 0; i <= 15; i++) {
							RedrawBackAndLayer0();
							_Cls(NULL);
							PaintPicture(bmG_Lv, NULL);
							Game_DrawLayer1(NULL, true, true, GameS * 4 + 1, 1, 0, i * 17);
							pTheBitmapDraw3(NULL, Ani_Misc, 3, kx - 40 + i, ky, i * 17);
							pTheBitmapDraw3(NULL, Ani_Misc, 4, kx + 40 - i, ky, i * 17);
							GAME_PAINT_ETC();
						}
					}

					IsSlipping = false;
					i = Lev(GameLev).BloxorzCheckBlockSlip(GameD, GameX, GameY, GameS, GameFS, GameX2, GameY2);
					if (i > 0) { // ice
						GameFS = i;
						GameStatus = 13;
						IsSlipping = true;
						nAnimationIndex = 0;
					} else if (GameS == GameS_Upright && GameD(GameX, GameY) == clsBloxorz::PYRAMID && GameFS > 0) { //pyramid
						// check movable
						if (Lev(GameLev).BloxorzCheckIsMovable(GameD, GameX, GameY, GameS, GameFS)) {
							GameStatus = 11;
							nAnimationIndex = 1;
						}
					} else {
						// erase direction
						GameFS = 0;
						// two box get together?
						if (GameS == GameS_Single) {
							if (GameX == GameX2) {
								if (GameY + 1 == GameY2) GameS = GameS_Vertical;
								else if (GameY - 1 == GameY2) {
									GameY = GameY2; GameS = GameS_Vertical;
								} else if (GameY == GameY2) {
									printf("[Game_Loop] Bug: two small boxes are get together!\n");
									GameStatus = -1;
								}
							} else if (GameY == GameY2) {
								if (GameX + 1 == GameX2) GameS = GameS_Horizontal;
								else if (GameX - 1 == GameX2) {
									GameX = GameX2; GameS = GameS_Horizontal;
								}
							}
						}
					}
					// update index
					idx = GameS * 4 + 1;
					break;
				case BState_Thin:
					GameStatus = 3;
					break;
				default: // unknown
					printf("[Game_Loop] Error: BloxorzCheckIsValidState returns unknown result\n");
					GameStatus = -1;
					break;
				}
				bEnsureRedraw = true;
				break;
			}

			if (bRenderTargetDirty) bEnsureRedraw = true;
			if (nBridgeChangeCount > 0 || kt > 0) bEnsureRedraw = true;

			// check button highlight
			buttonClicked = -1;
			{
				const int buttonCount = GameIsRndMap ? 2 : 1;
				int newHighlight = -1;
				_GetCursorPos(&x, &y);
				for (int i = 0; i < buttonCount; i++) {
					if (_PtInRect(buttons[i], x, y)) {
						newHighlight = i;
						break;
					}
				}
				if (newHighlight != buttonHighlight) {
					buttonHighlight = newHighlight;
					bEnsureRedraw = true;
				}
			}

			// check time
			i = SDL_GetTicks() - GameLvStartTime;
			if (i >= t * 1000) {
				t = i / 1000;
				bEnsureRedraw = true;
			}

			// redraw?
			if (bEnsureRedraw && GameStatus > 1) {
				RedrawBackAndLayer0();
				_Cls(NULL);
				PaintPicture(bmG_Lv, NULL);

				// draw text
				DrawTextB(NULL, str(MyFormat("%d") << GameLvStep), m_objFont[0],
					96, 24, 72, 16, _DT_VCENTER | _DT_SINGLELINE, 0xFFFFFF);
				DrawTextB(NULL, str(MyFormat("%02d:%02d:%02d") << (t / 3600) << ((t / 60) % 60) << (t % 60)), m_objFont[0],
					96, 40, 72, 16, _DT_VCENTER | _DT_SINGLELINE, 0xFFFFFF);
				DrawTextB(NULL, str(MyFormat("%d") << GameLvRetry), m_objFont[0],
					96, 56, 72, 16, _DT_VCENTER | _DT_SINGLELINE, 0xFFFFFF);

				// draw bridges status change
				nBridgeChangeCount = 0;
				for (j = 1; j <= GameH; j++) {
					for (i = 1; i <= GameW; i++) {
						m = dL(i, j);
						if (m >= 100 && m <= 115) { // off
							pTheBitmapDraw3(NULL, Ani_Misc, 1,
								GameLayer0SX + (i - 1) * 32 + (j - 1) * 10,
								GameLayer0SY + 0 - ((i - 1) * 5) + ((j - 1) * 16), (m - 100) * 17);
							nBridgeChangeCount++;
							dL(i, j) = m - 1;
						} else if (m >= 200 && m <= 215) { // on
							pTheBitmapDraw3(NULL, Ani_Misc, 2,
								GameLayer0SX + (i - 1) * 32 + (j - 1) * 10,
								GameLayer0SY + 0 - ((i - 1) * 5) + ((j - 1) * 16), (m - 200) * 17);
							nBridgeChangeCount++;
							dL(i, j) = m - 1;
						} else {
							dL(i, j) = 0;
						}
					}
				}

				// layer 1
				if (IsSlipping) {
					Game_DrawLayer1(NULL, true, true, idx, idx2, y2, 255, false, x2, true);
				} else if (QIE_0 > 0 && GameFS == 0) { // :-/
					Game_DrawLayer1(NULL, true, true, QIE_0, 8, y2, 255, false, x2, true);
				} else if (QIE_0 > 0 && ((QIE_0 > 2) ^ (GameFS > 2))) { // :-/
					switch (GameFS) {
					case GameFS_Up:
						Game_DrawLayer1(NULL, true, true, QIE_0, 8,
							y2 - 2 * nAnimationIndex, 255, false,
							x2 - (10 * nAnimationIndex) / 8, true);
						break;
					case GameFS_Down:
						Game_DrawLayer1(NULL, true, true, QIE_0, 8,
							y2 + 2 * nAnimationIndex, 255, false,
							x2 + (10 * nAnimationIndex) / 8, true);
						break;
					case GameFS_Left:
						Game_DrawLayer1(NULL, true, true, QIE_0, 8,
							y2 + (5 * nAnimationIndex) / 8, 255, false,
							x2 - 4 * nAnimationIndex, true);
						break;
					case GameFS_Right:
						Game_DrawLayer1(NULL, true, true, QIE_0, 8,
							y2 - (5 * nAnimationIndex) / 8, 255, false,
							x2 + 4 * nAnimationIndex, true);
						break;
					}
				} else {
					Game_DrawLayer1(NULL, true, true, idx, idx2);
				}

				// draw []
				if (kt <= 0) {
				} else if (kt <= 16) {
					pTheBitmapDraw3(NULL, Ani_Misc, 3, kx - 24, ky, 17 * (kt - 1));
					pTheBitmapDraw3(NULL, Ani_Misc, 4, kx + 24, ky, 17 * (kt - 1));
					kt--;
				} else if (kt <= 24) {
					pTheBitmapDraw3(NULL, Ani_Misc, 3, kx - 24, ky);
					pTheBitmapDraw3(NULL, Ani_Misc, 4, kx + 24, ky);
					kt--;
				} else if (kt <= 40) {
					pTheBitmapDraw3(NULL, Ani_Misc, 3, kx - kt, ky, 17 * (40 - kt));
					pTheBitmapDraw3(NULL, Ani_Misc, 4, kx + kt, ky, 17 * (40 - kt));
					kt--;
				}

				// draw button highlight
				if (buttonHighlight >= 0) {
					_FrameRect(NULL, buttons[buttonHighlight], 0x0080FF);
				}

				Game_Paint();
				bEnsureRedraw = false;
			}

			WaitForNextFrame();

			// get message
			{
				SDL_Event event;
				while (SDL_PollEvent(&event)) {
					switch (event.type) {
					case SDL_MOUSEBUTTONDOWN:
						if (event.button.button == SDL_BUTTON_LEFT) {
							const int buttonCount = GameIsRndMap ? 2 : 1;
							for (int i = 0; i < buttonCount; i++) {
								if (_PtInRect(buttons[i], event.button.x, event.button.y)) {
									buttonClicked = i;
									break;
								}
							}
						}
						break;
					case SDL_KEYDOWN:
						switch (event.key.keysym.scancode) {
						case SDL_SCANCODE_ESCAPE:
						case SDL_SCANCODE_AC_BACK:
							buttonClicked = 0;
							break;
						}
						if (GameIsRndMap && event.key.keysym.sym == SDLK_c && (event.key.keysym.mod & KMOD_CTRL) != 0) {
							buttonClicked = 1;
						}
						break;
					}
				}
				if (GameStatus < 0 || !bRun) return;
			}

			// copy seed?
			if (GameIsRndMap && buttonClicked == 1) {
				SDL_SetClipboardText(RndMapSeed.c_str());
			}

			// menu
			if (buttonClicked == 0) {
				j = SDL_GetTicks();

				RedrawBackAndLayer0();
				i = Game_Menu_Loop();
				bRenderTargetDirty = true;

				switch (i) {
				case 2: // restart
					// fade out
					for (i = 255; i >= 0; i -= 51) {
						RedrawBackAndLayer0();
						_Cls(NULL);
						AlphaPaintPicture(bmG_Lv, NULL, 0, 0, 640, 480, 0, 0, i);
						GAME_PAINT_ETC();
					}
					// over
					GameStatus = 1;
					break;
				case 3: // select level
					Game_SelectLevel();
					break;
				case 4: // selct level file
					Game_SelectLevelFile();
					break;
				case 8: // instruction
					// fade out
					for (i = 255; i >= 0; i -= 51) {
						RedrawBackAndLayer0();
						_Cls(NULL);
						AlphaPaintPicture(bmG_Lv, NULL, 0, 0, 640, 480, 0, 0, i);
						GAME_PAINT_ETC();
					}
					// show instructions
					Game_Instruction_Loop();
					// fade in
					bRenderTargetDirty = true;
					for (i = 0; i <= 255; i += 51) {
						RedrawBackAndLayer0();
						_Cls(NULL);
						AlphaPaintPicture(bmG_Lv, NULL, 0, 0, 640, 480, 0, 0, i);
						GAME_PAINT_ETC();
					}
					break;
				case 9: // return to main menu
					GameStatus = -1; return;
					break;
				case 10: // exit game
					GameStatus = -1; bRun = false; return;
					break;
				default: // return
					break;
				}

				GameLvStartTime += SDL_GetTicks() - j;
				bRenderTargetDirty = true;
			}

			// exit??
			if (GameStatus < 0 || !bRun) return;
			break;

		default:
			printf("[Game_Loop] Bug: Unknown or unimplemented game status: %d\n", GameStatus);
			GameStatus = 0;
			break;
		}
	}
}

void clsBloxorzGame::Game_SelectLevel() {
	SimpleMenu menu;

	const int m = Lev.UBound();
	for (int i = 1; i <= m; i++) {
		menu.item.push_back(str(MyFormat("%d (%dx%d)") << i << Lev(i).Width() << Lev(i).Height()));
	}

	menu.listIndex = GameLev - 1;

	menu.title = _("Select Level");
	menu.closeButton = menu.cancelButton = -1;
	menu.itemWidth = 128;

	int ret = menu.MenuLoop() + 1;

	if (ret > 0 && ret <= m && ret != GameLev) {
		bRenderTargetDirty = true;

		// fade out
		for (int i = 255; i >= 0; i -= 51) {
			RedrawBackAndLayer0();
			_Cls(NULL);
			AlphaPaintPicture(bmG_Lv, NULL, 0, 0, 640, 480, 0, 0, i);
			GAME_PAINT_ETC();
		}

		// over
		GameLev = ret;
		GameStatus = 0;
	}
}

void clsBloxorzGame::Game_SelectLevelFile() {
	SimpleMenu menu;

	std::vector<std::string> files;

	// enum internal files
	{
		std::string fn = "data/";
		std::vector<std::string> f = enumAllFiles(fn, "box");
		for (int i = 0, m = f.size(); i < m; i++) {
			menu.item.push_back(f[i]);
			files.push_back(fn + f[i]);
		}
	}

	// enum external files
	{
		std::string fn = externalStoragePath + "/levels/";
		std::vector<std::string> f = enumAllFiles(fn, "box");
		for (int i = 0, m = f.size(); i < m; i++) {
			menu.item.push_back(_("User level: ") + f[i]);
			files.push_back(fn + f[i]);
		}
	}

	// check current file
	for (int i = 0, m = files.size(); i < m; i++) {
		if (files[i] == LevFileName) {
			menu.listIndex = i;
			break;
		}
	}

	menu.title = _("Select Level File");
	menu.closeButton = menu.cancelButton = -1;

	int ret = menu.MenuLoop();

	if (ret >= 0) {
		Game_LoadLevel(files[ret].c_str());

		bRenderTargetDirty = true;

		// fade out
		for (int i = 255; i >= 0; i -= 51) {
			RedrawBackAndLayer0();
			_Cls(NULL);
			AlphaPaintPicture(bmG_Lv, NULL, 0, 0, 640, 480, 0, 0, i);
			GAME_PAINT_ETC();
		}

		// over
		GameStatus = 0;
	}
}

const char URL1[] = "https://github.com/acmepjz/turningpolyhedron";
const char URL2[] = "http://www.miniclip.com/games/bloxorz/en/";

void clsBloxorzGame::Game_Instruction_Redraw() {
	int i, j;
	int x, y, x2, y2;

	// back
	PaintPicture(bmImg[4], bmG_Back);

	// map 1
	x = 572; y = 32;
	for (j = 1; j <= 3; j++) {
		x2 = x; y2 = y;
		for (i = 6; i >= 1; i--) {
			pTheBitmapDraw3(bmG_Back, Ani_Layer0,
				(i == 5 && j == 2) ? clsBloxorz::GOAL : clsBloxorz::GROUND, x2, y2);
			x2 -= 32; y2 += 5;
		}
		x += 10; y += 16;
	}
	pGameDrawBox(bmG_Back, 1, 1, 454, 68);

	// map 2
	x = 572; y = 128;
	for (j = 1; j <= 3; j++) {
		x2 = x; y2 = y;
		for (i = 6; i >= 1; i--) {
			pTheBitmapDraw3(bmG_Back, Ani_Layer0,
				(i == 3 || i == 4) ? ((j == 2) ? clsBloxorz::BRIDGE_ON : clsBloxorz::EMPTY) :
				(i == 1 && j == 1) ? clsBloxorz::SOFT_BUTTON :
				(i == 6 && j == 1) ? clsBloxorz::HARD_BUTTON : clsBloxorz::GROUND, x2, y2);
			x2 -= 32; y2 += 5;
		}
		x += 10; y += 16;
	}

	// map 3
	x = 572; y = 224;
	for (j = 1; j <= 3; j++) {
		x2 = x; y2 = y;
		for (i = 6; i >= 1; i--) {
			pTheBitmapDraw3(bmG_Back, Ani_Layer0,
				(i == 3 || i == 4) ? clsBloxorz::THIN_GROUND :
				(i == 5 && j == 2) ? clsBloxorz::TELEPORTER : clsBloxorz::GROUND, x2, y2);
			x2 -= 32; y2 += 5;
		}
		x += 10; y += 16;
	}
	pGameDrawBox(bmG_Back, 13, 1, 444, 244);
	pGameDrawBox(bmG_Back, 13, 1, 432, 281);

	// map 4
	x = 572; y = 320;
	for (j = 1; j <= 3; j++) {
		x2 = x; y2 = y;
		for (i = 6; i >= 1; i--) {
			pTheBitmapDraw3(bmG_Back, Ani_Layer0,
				(i == 4 && j == 3) ? clsBloxorz::PYRAMID :
				((i < 3 && j < 3) || i > 4) ? clsBloxorz::GROUND :
				clsBloxorz::ICE, x2, y2);
			if ((i < 3 && j < 3) || (i == 6 && j == 2)) {
				pTheBitmapDraw3(bmG_Back, Ani_Misc, 6, x2, y2);
			}
			x2 -= 32; y2 += 5;
		}
		x += 10; y += 16;
	}
	pTheBitmapDraw3(bmG_Back, 4, 7, 523, 345);

	// text
	std::string s;
	s = _("Turning Square is a clone and enhancement to popular game Bloxorz. The aim of the game is to get the block to fall into the square hole at the end of each level. There are 33 levels in default level pack, and many levels in other level pack. You can make your own levels using level editor, or explore completely new levels using random level generator.") + "\n\n";
	s += _("To move the block around the world, use the UP DOWN LEFT and RIGHT arrow keys. Be careful not to fall off the edges - the level will be restarted.") + "\n\n";
	s += _("Bridges and switches are located in many levels. The switches are activated when they are pressed down by the block. You don't need to stay resting on the switch to keep bridges open. There are two types of switches: 'Heavy' X-shaped ones and 'Soft' round ones. Soft switches are activated when any part of your block presses it. Hard switches require much more pressure, so your block must be standing on its end to activate it. When activated, each switch may behave differently. Some will toggle the bridge state each time it is used. Some will only ever make certain bridges open, and activating it again will not make it close. Green or red colored squares will flash to indicate which bridges are being operated.") + "\n\n";
	s += _("Orange tiles are more fragile than the rest of the land. If your block stands up vertically on an orange tile, the tile will give way and your block will fall.") + "\n\n";
	s += _("The tile shaped like two brackets will teleports your block to different locations, splitting it into two smaller blocks at the same time. These can be controlled individually by pressing the SPACE BAR and will rejoin into a normal block when both are placed next to each other. Small blocks can still operate soft switches, but they're too small to activate heavy switches. Also small blocks can't go through the exit hole - only a complete block can finish the level.") + "\n\n";
	s += _("There are some new tiles in Turning Square: pyramid, ice and wall. Your block is unstable when standing on the pyramid, so it will lie down immediately unless there is a wall next to your block. When the block is completely on the ice, it will slip until get off the ice or hit the wall. As an obstacle, your block can't pass through the wall, but it can recline on the wall and move around.");
	s += _("(ANIMATION IS BROKEN)");

	DrawTextB(bmG_Back, s, m_objFont[0],
		8, 8, 400, 400, _DT_WORDBREAK, 0xFFFFFF);
	s = str(MyFormat(_("%s version, author: %s")) << "VB6, FreeBasic (SDL), C++ (SDL2)" << "acme_pjz");
	DrawTextB(bmG_Back, s, m_objFont[0],
		8, 424, 320, 16, _DT_VCENTER | _DT_SINGLELINE, 0xFFFFFF);
	DrawTextB(bmG_Back, _("Source code:"), m_objFont[0],
		8, 440, 256, 16, _DT_VCENTER | _DT_SINGLELINE, 0xFFFFFF);
	DrawTextB(bmG_Back, _("Original version:"), m_objFont[0],
		8, 456, 256, 16, _DT_VCENTER | _DT_SINGLELINE, 0xFFFFFF);
	DrawTextB(bmG_Back, _("OK"), m_objFont[0],
		568, 456, 64, 16, _DT_CENTER | _DT_VCENTER | _DT_SINGLELINE, 0x0080FF);

	DrawTextB(bmG_Back, URL1, m_objFont[0],
		104, 440, 240, 16, _DT_VCENTER | _DT_SINGLELINE, 0x0080FF);
	DrawTextB(bmG_Back, URL2, m_objFont[0],
		104, 456, 240, 16, _DT_VCENTER | _DT_SINGLELINE, 0x0080FF);
}

void clsBloxorzGame::Game_Instruction_Loop() {
	bRenderTargetDirty = true;

	_Cls(NULL);
	Game_Paint();

	// animation
	for (int i = 51; i <= 255; i += 51) {
		if (bRenderTargetDirty) {
			Game_Instruction_Redraw();
			bRenderTargetDirty = false;
		}
		_Cls(NULL);
		AlphaPaintPicture(bmG_Back, NULL, 0, 0, 640, 480, 0, 0, i);
		Game_Paint();
		WaitForNextFrame();
		DoEvents();
		if (!bRun) return;
	}

	// buttons
	const _RECT buttons[] = {
			{ 100, 440, 420, 456 }, // URL1
			{ 100, 456, 420, 472 }, // URL2
			{ 568, 456, 632, 472 }, // OK
			{ -1 },
	};

	SDL_Event event;

	// loop
	for (;;) {
		if (bRenderTargetDirty) {
			Game_Instruction_Redraw();
			bRenderTargetDirty = false;
		}
		_Cls(NULL);
		PaintPicture(bmG_Back, NULL);

		int buttonHighlight = -1;
		int buttonClicked = -1;

		// get message
		while (SDL_PollEvent(&event)) {
			switch (event.type) {
			case SDL_MOUSEBUTTONDOWN:
				if (event.button.button == SDL_BUTTON_LEFT) {
					for (int i = 0; buttons[i].Left >= 0; i++) {
						if (_PtInRect(buttons[i], event.button.x, event.button.y)) {
							buttonClicked = i;
							break;
						}
					}
				}
				break;
			case SDL_KEYDOWN:
				switch (event.key.keysym.scancode) {
				case SDL_SCANCODE_RETURN:
				case SDL_SCANCODE_ESCAPE:
				case SDL_SCANCODE_AC_BACK:
					buttonClicked = 2;
					break;
				}
				break;
			}
		}
		if (!bRun) return;

		int x, y;
		_GetCursorPos(&x, &y);
		for (int i = 0; buttons[i].Left >= 0; i++) {
			if (_PtInRect(buttons[i], x, y)) {
				_FrameRect(NULL, buttons[i], 0x0080FF);
				buttonHighlight = i;
				break;
			}
		}

		Game_Paint();
		WaitForNextFrame();

		if (buttonClicked == 0) { // URL1
			// TODO: click URL1
		} else if (buttonClicked == 1) { // URL2
			// TODO: click URL2
		} else if (buttonClicked == 2) { // OK
			break;
		}
	}

	// animation
	for (int i = 255; i >= 0; i -= 51) {
		if (bRenderTargetDirty) {
			Game_Instruction_Redraw();
			bRenderTargetDirty = false;
		}
		_Cls(NULL);
		AlphaPaintPicture(bmG_Back, NULL, 0, 0, 640, 480, 0, 0, i);
		Game_Paint();
		WaitForNextFrame();
		DoEvents();
		if (!bRun) return;
	}
}

int clsBloxorzGame::Game_Menu_Loop() {
	SimpleMenu menu;

	menu.item.push_back(_("Return to game"));
	menu.item.push_back(_("Restart"));
	menu.item.push_back(_("Pick a level"));
	menu.item.push_back(_("Open level file"));
	menu.item.push_back(_("Random level"));
	menu.item.push_back(_("Input solution"));
	menu.item.push_back(_("Auto solver"));
	menu.item.push_back(_("Game instructions"));
	menu.item.push_back(_("Main menu"));
	menu.item.push_back(_("Exit game"));

	menu.cancelButton = 0;

	return menu.MenuLoop() + 1;
}

void clsBloxorzGame::Game_Init() {
	// load level
	Game_LoadLevel("data/Default.box");

	// init data
	GameStatus = 0;

	// enter loop
	Game_Loop();
}
