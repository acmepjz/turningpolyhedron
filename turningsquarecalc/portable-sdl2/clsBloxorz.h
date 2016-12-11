#pragma once

#include <vector>
#include "SimpleArrayVB6.h"

class clsTheFile;

enum enumGameS {
	GameS_Upright = 0,
	GameS_Horizontal = 1,
	GameS_Vertical = 2,
	GameS_Single = 3,
};

enum enumGameFS {
	GameFS_Up = 1,
	GameFS_Down = 2,
	GameFS_Left = 3,
	GameFS_Right = 4,
};

struct typeBridge {
	enum enumBridgeBehavior {
		OFF = 0,
		ON = 1,
		TOGGLE = 2,
	};
	int x, y;
	int Behavior;
};

typedef std::vector<typeBridge> typeSwitch;

struct typeSolveItPos {
	short x, y;
};

struct typeSolveItSwitchIdPos {
	int Count() const {
		return p.size();
	}
	int AllPosCount, AllPosDelta;
	std::vector<typeSolveItPos> p;
};

struct typeSolveItNode {
	int Index;
	int BinarySearchTreeLSon, BinarySearchTreeRSon;
	int m, k, k2;
	int Distance;
	int PathPrevNode, PathPrevEdge;
};

struct typeNextPos {
	int m, k, k2;
};

enum enumBloxorzStateValid {
	BState_Fall = 0,
	BState_Valid = 1,
	BState_Thin = 2,
	BState_UnknownError = 99,
};

class clsBloxorz {
public:
	enum enumBloxorzTileType {
		EMPTY = 0,
		GROUND = 1,
		SOFT_BUTTON = 2,
		HARD_BUTTON = 3,
		TELEPORTER = 4,
		THIN_GROUND = 5,
		BRIDGE_OFF = 6,
		BRIDGE_ON = 7,
		GOAL = 8,
		ICE = 9,
		PYRAMID = 10,
		WALL = 11,
	};
public:
	int Width() const {
		return datw;
	}
	int Height() const {
		return dath;
	}
	void Create(int w, int h);
	void Destroy();
	void Clear();
	void ClearSwitch();
	void SolveItClear();

	// NOTE: lv is 1-based
	void LoadLevel(int lv, clsTheFile& d);
	// NOTE: lv is 1-based
	void SaveLevel(int lv, clsTheFile& d);

	int BloxorzCheckBlockSlip(const Array2D<unsigned char, 1, 1>& d, int x, int y, int GameS, int FS, int x2 = 0, int y2 = 0) const;
	bool BloxorzCheckIsMovable(const Array2D<unsigned char, 1, 1>& d, int x, int y, int GameS, int FS, int* QIE = NULL) const;
	enumBloxorzStateValid BloxorzCheckIsValidState(const Array2D<unsigned char, 1, 1>& d, int x, int y, int GameS, int x2 = 0, int y2 = 0) const;
	int BloxorzCheckPressButton(Array2D<unsigned char, 1, 1>& d, int x, int y, int GameS, Array2D<int, 1, 1>* BridgeChangeArray = NULL, int BridgeOff = 0, int BridgeOn = 0) const;
	inline void GetTeleportPosition(int x, int y, int& x1, int& y1, int& x2, int& y2) const {
		int n = dat2(x, y);
		x1 = n & 0xFF;
		y1 = (n >> 8) & 0xFF;
		x2 = (n >> 16) & 0xFF;
		y2 = (n >> 24) & 0xFF;
	}
public:
	std::vector<unsigned char> _xx_dat;
	std::vector<int> _xx_dat2;
	std::vector<typeSwitch> switches;
private:
	int datw, dath;
public:
	int StartX, StartY;
private:
	std::vector<unsigned char> _xx_SwitchMap;
	std::vector<int> _xx_SwitchMapPosId;
	std::vector<typeSolveItSwitchIdPos> SwitchMapIdPos;
	int SwitchStatusCount() const {
		return SwitchMapIdPos.size();
	}
	bool IsTrans; // true if the block can be splitted to two pieces

	std::vector<typeSolveItNode> GTheoryNode;
	int GTheoryNodeMax; // max possible number of states
	int SolveItTime; // in millisecond
	std::vector<unsigned char> _xx_SolveItMovedArea;
public:
	int SolveItGetNodeMax() const {
		return GTheoryNodeMax;
	}
	int SolveItGetNodeUsed() const {
		return GTheoryNode.size();
	}
public:
	// NOTE: all of subscriptions are 1-based
	unsigned char dat(int _w_, int _h_) const {
		return _xx_dat[_ArrayBoundsCheckVB6_2D(_w_, 1, datw, _h_, 1, dath)];
	}
	// NOTE: all of subscriptions are 1-based
	unsigned char& dat(int _w_, int _h_) {
		return _xx_dat[_ArrayBoundsCheckVB6_2D(_w_, 1, datw, _h_, 1, dath)];
	}
	// NOTE: all of subscriptions are 1-based
	int dat2(int _w_, int _h_) const {
		return _xx_dat2[_ArrayBoundsCheckVB6_2D(_w_, 1, datw, _h_, 1, dath)];
	}
	// NOTE: all of subscriptions are 1-based
	int& dat2(int _w_, int _h_) {
		return _xx_dat2[_ArrayBoundsCheckVB6_2D(_w_, 1, datw, _h_, 1, dath)];
	}
	// NOTE: all of subscriptions are 1-based
	unsigned char SolveItMovedArea(int _w_, int _h_) const {
		return _xx_SolveItMovedArea[_ArrayBoundsCheckVB6_2D(_w_, 1, datw, _h_, 1, dath)];
	}
	// NOTE: all of subscriptions are 1-based
	unsigned char& SolveItMovedArea(int _w_, int _h_) {
		return _xx_SolveItMovedArea[_ArrayBoundsCheckVB6_2D(_w_, 1, datw, _h_, 1, dath)];
	}
private:
	// NOTE: all of subscriptions are 1-based
	unsigned char SwitchMap(int _w_, int _h_, int _index_) const {
		return _xx_SwitchMap[_ArrayBoundsCheckVB6_3D(_w_, 1, datw, _h_, 1, dath, _index_, 1, SwitchStatusCount())];
	}
	// NOTE: all of subscriptions are 1-based
	unsigned char& SwitchMap(int _w_, int _h_, int _index_) {
		return _xx_SwitchMap[_ArrayBoundsCheckVB6_3D(_w_, 1, datw, _h_, 1, dath, _index_, 1, SwitchStatusCount())];
	}
	// NOTE: all of subscriptions are 1-based
	int SwitchMapPosId(int _w_, int _h_, int _index_) const {
		return _xx_SwitchMapPosId[_ArrayBoundsCheckVB6_3D(_w_, 1, datw, _h_, 1, dath, _index_, 1, SwitchStatusCount())];
	}
	// NOTE: all of subscriptions are 1-based
	int& SwitchMapPosId(int _w_, int _h_, int _index_) {
		return _xx_SwitchMapPosId[_ArrayBoundsCheckVB6_3D(_w_, 1, datw, _h_, 1, dath, _index_, 1, SwitchStatusCount())];
	}
};