#pragma once

#include "clsBloxorz.h"
#include "SimpleArrayVB6.h"
#include "typeTextBox.h"
#include <SDL_render.h>
#include <string>

class clsBloxorzGame {
public:
	clsBloxorzGame();
	~clsBloxorzGame();

	void Game_DrawLayer1(SDL_Texture *hdc, bool DrawBox = true, bool DrawBoxShadow = false, int Index = 0, int Index2 = 0, int BoxDeltaY = 0, int BoxAlpha = 255, bool WithLayer0 = false, int BoxDeltaX = 0, bool NoZDepth = false);
	void Game_LoadLevel(const char* fn);
	void Game_Loop();
	void Game_Init();

	static void Game_Instruction_Redraw();
	static void Game_Instruction_Loop();
	static int Game_Menu_Loop();
private:
	void Game_SelectLevel();
	void Game_SelectLevelFile();
	void Game_InitBack();
	void RedrawLevelName();
	void RedrawBack();
	void RedrawBackAndLayer0(bool forceLayer0 = false);
private:
	int GameLayer0SX, GameLayer0SY;

	Array1D<clsBloxorz, 1> Lev;
	std::string LevFileName, Me_Tag;

	Array2D<unsigned char, 1, 1> GameD;

	/*
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
	int GameStatus;

	int GameLev;
	int GameW, GameH;
	int GameX, GameY, GameS, GameX2, GameY2;
	int GameFS;

	int GameLvStartTime, GameLvStep, GameLvRetry;

	std::string GameDemoS;
	int GameDemoPos;
	bool GameDemoBegin;

	bool GameIsRndMap;
	std::string RndMapSeed;
};
