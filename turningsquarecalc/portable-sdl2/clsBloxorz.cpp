#include "clsBloxorz.h"
#include "clsTheFile.h"
#include "FileSystem.h"
#include <SDL_rwops.h>

#include <string.h>

#define PUSH32LE(data,number) { \
int tmp=(number); data.push_back(tmp); data.push_back(tmp>>8); data.push_back(tmp>>16); data.push_back(tmp>>24); \
}

void clsBloxorz::Create(int w, int h) {
	if (w > 0 && h > 0) {
		Destroy();
		datw = w;
		dath = h;
		_xx_dat.resize(w*h);
		_xx_dat2.resize(w*h);
	}
}

void clsBloxorz::Destroy() {
	datw = dath = 0;
	_xx_dat.clear();
	_xx_dat2.clear();
	ClearSwitch();
	SolveItClear();
}

void clsBloxorz::Clear() {
	if (datw > 0 && dath > 0) {
		int m = datw*dath;
		memset(&(_xx_dat[0]), 0, m);
		memset(&(_xx_dat2[0]), 0, m*sizeof(int));
		StartX = StartY = 1;
	}
	ClearSwitch();
	SolveItClear();
}

void clsBloxorz::ClearSwitch() {
	switches.clear();
	for (int i = 0, m = _xx_dat.size(); i < m; i++) {
		switch (_xx_dat[i]) {
		case SOFT_BUTTON:
		case HARD_BUTTON:
			_xx_dat2[i] = 0;
			break;
		}
	}
}

void clsBloxorz::SolveItClear() {
	_xx_SwitchMap.clear();
	_xx_SwitchMapPosId.clear();
	SwitchMapIdPos.clear();
	GTheoryNode.clear();
	GTheoryNodeMax = 0;
}

void clsBloxorz::LoadLevel(int lv, clsTheFile& d) {
	Destroy();

	typeFileNodeArray *array = d.FindNodeArray(BOX_LEV);
	if (array == NULL) return;
	lv--;
	if (lv < 0 || lv >= (int)array->nodes.size()) return;
	std::vector<char> &data = array->nodes[lv];
	if (data.empty()) return;

	u8file *f = SDL_RWFromConstMem(&(data[0]), data.size());
	datw = SDL_ReadLE32(f);
	dath = SDL_ReadLE32(f);
	StartX = SDL_ReadLE32(f);
	StartY = SDL_ReadLE32(f);
	if (datw > 0 && dath > 0) {
		int m = datw*dath;
		_xx_dat.resize(m);
		_xx_dat2.resize(m);
		u8fread(&(_xx_dat[0]), 1, m, f);
		for (int i = 0; i < m; i++) _xx_dat2[i] = SDL_ReadLE32(f);
	}

	int switchCount = SDL_ReadLE32(f);
	if (switchCount > 0) {
		switches.resize(switchCount);
		for (int i = 0; i < switchCount; i++) {
			int m = SDL_ReadLE32(f);
			if (m>0) switches[i].resize(m);
			for (int j = 0; j < m; j++) {
				switches[i][j].x = SDL_ReadLE32(f);
				switches[i][j].y = SDL_ReadLE32(f);
				switches[i][j].Behavior = SDL_ReadLE32(f);
			}
		}
	}

	u8fclose(f);
}

void clsBloxorz::SaveLevel(int lv, clsTheFile& d) {
	lv--;
	if (lv < 0) return;

	std::vector<char> b;

	PUSH32LE(b, datw);
	PUSH32LE(b, dath);
	PUSH32LE(b, StartX);
	PUSH32LE(b, StartY);

	if (datw > 0 && dath > 0) {
		int m = datw*dath;
		b.insert(b.end(), _xx_dat.begin(), _xx_dat.end());
		for (int i = 0; i < m; i++) {
			PUSH32LE(b, _xx_dat2[i]);
		}
	}

	int switchCount = switches.size();
	PUSH32LE(b, switchCount);
	for (int i = 0; i < switchCount; i++) {
		int m = switches[i].size();
		PUSH32LE(b, m);
		for (int j = 0; j < m; j++) {
			PUSH32LE(b, switches[i][j].x);
			PUSH32LE(b, switches[i][j].y);
			PUSH32LE(b, switches[i][j].Behavior);
		}
	}

	typeFileNodeArray *array = d.FindNodeArray(BOX_LEV);
	if (array == NULL) {
		array = d.AddNodeArray(BOX_LEV);
	}
	while ((int)array->nodes.size() <= lv) array->nodes.push_back(typeFileNode());
	std::swap(b, array->nodes[lv]);
}

int clsBloxorz::BloxorzCheckBlockSlip(const Array2D<unsigned char, 1, 1>& d, int x, int y, int GameS, int FS, int x2, int y2) const {
	// TODO: new block?
	switch (GameS) {
	case GameS_Upright: case GameS_Single:
		// hit block?
		switch (FS) {
		case GameFS_Up:
			if (y > 1) {
				if (dat(x, y - 1) == WALL) return 0;
				if (GameS == GameS_Single && x == x2 && y - 1 == y2) return 0;
			}
			break;
		case GameFS_Down:
			if (y < dath) {
				if (dat(x, y + 1) == WALL) return 0;
				if (GameS == GameS_Single && x == x2 && y + 1 == y2) return 0;
			}
			break;
		case GameFS_Left:
			if (x > 1) {
				if (dat(x - 1, y) == WALL) return 0;
				if (GameS == GameS_Single && y == y2 && x - 1 == x2) return 0;
			}
			break;
		case GameFS_Right:
			if (x < datw) {
				if (dat(x + 1, y) == WALL) return 0;
				if (GameS == GameS_Single && y == y2 && x + 1 == x2) return 0;
			}
			break;
		}
		if (d(x, y) == ICE) return FS;
		break;
	case GameS_Horizontal:
		// hit block?
		switch (FS) {
		case GameFS_Up:
			if (y > 1) {
				if (dat(x, y - 1) == WALL || dat(x + 1, y - 1) == WALL) return 0;
			}
			break;
		case GameFS_Down:
			if (y < dath) {
				if (dat(x, y + 1) == WALL || dat(x + 1, y + 1) == WALL) return 0;
			}
			break;
		case GameFS_Left:
			if (x > 1) {
				if (dat(x - 1, y) == WALL) return 0;
			}
			break;
		case GameFS_Right:
			if (x < datw - 1) {
				if (dat(x + 2, y) == WALL) return 0;
			}
			break;
		}
		if (d(x, y) == ICE && d(x + 1, y) == ICE) return FS;
		break;
	case GameS_Vertical:
		// hit block?
		switch (FS) {
		case GameFS_Up:
			if (y > 1) {
				if (dat(x, y - 1) == WALL) return 0;
			}
			break;
		case GameFS_Down:
			if (y < dath - 1) {
				if (dat(x, y + 2) == WALL) return 0;
			}
			break;
		case GameFS_Left:
			if (x > 1) {
				if (dat(x - 1, y) == WALL || dat(x - 1, y + 1) == WALL) return 0;
			}
			break;
		case GameFS_Right:
			if (x < datw) {
				if (dat(x + 1, y) == WALL || dat(x + 1, y + 1) == WALL) return 0;
			}
			break;
		}
		if (d(x, y) == ICE && d(x, y + 1) == ICE) return FS;
		break;
	}
	return 0;
}

int clsBloxorz::BloxorzCheckPressButton(Array2D<unsigned char, 1, 1>& d, int x, int y, int GameS, Array2D<int, 1, 1>* BridgeChangeArray, int BridgeOff, int BridgeOn) const {
	int i, j, k;
	int btns[2] = {};
	int ret = 0;

	if (BridgeChangeArray) BridgeChangeArray->fill(0);

	switch (GameS) {
	case GameS_Upright: case GameS_Single:
		i = d(x, y);
		if (i == SOFT_BUTTON || (i == HARD_BUTTON && GameS == GameS_Upright)) btns[0] = dat2(x, y);
		break;
	case GameS_Horizontal:
		if (d(x, y) == SOFT_BUTTON) btns[0] = dat2(x, y);
		if (d(x + 1, y) == SOFT_BUTTON) btns[1] = dat2(x + 1, y);
		break;
	case GameS_Vertical:
		if (d(x, y) == SOFT_BUTTON) btns[0] = dat2(x, y);
		if (d(x, y + 1) == SOFT_BUTTON) btns[1] = dat2(x, y + 1);
		break;
	}

	for (i = 0; i < 2; i++) {
		k = btns[i];
		if (k > 0 && k <= (int)switches.size()) {
			const typeSwitch& sw = switches[k - 1];
			for (j = 0; j < (int)sw.size(); j++) {
				const typeBridge& bs = sw[j];
				if (bs.x > 0 && bs.y > 0 && bs.x <= datw && bs.y <= dath) {
					switch (d(bs.x, bs.y)) {
					case BRIDGE_OFF: case BRIDGE_ON:
						switch (bs.Behavior) {
						case typeBridge::OFF:
							d(bs.x, bs.y) = BRIDGE_OFF;
							break;
						case typeBridge::ON:
							d(bs.x, bs.y) = BRIDGE_ON;
							break;
						case typeBridge::TOGGLE:
							d(bs.x, bs.y) = (d(bs.x, bs.y) == BRIDGE_OFF) ? BRIDGE_ON : BRIDGE_OFF;
							break;
						}
						if (BridgeChangeArray) {
							(*BridgeChangeArray)(bs.x, bs.y) = (d(bs.x, bs.y) == BRIDGE_OFF) ? BridgeOff : BridgeOn;
						}
						ret++;
						break;
					}
				}
			}
		}
	}

	return ret;
}

bool clsBloxorz::BloxorzCheckIsMovable(const Array2D<unsigned char, 1, 1>& d, int x, int y, int GameS, int FS, int* QIE) const {
	bool ret = true;
	if (QIE) *QIE = 0;

	switch (GameS) {
	case GameS_Upright: case GameS_Single:
		switch (FS) {
		case GameFS_Up:
			if (y > 1) {
				if (d(x, y - 1) == WALL) ret = false;
				if (QIE && GameS == GameS_Upright && y > 2 && d(x, y - 2) == WALL) *QIE = FS;
			}
			break;
		case GameFS_Down:
			if (y < dath) {
				if (d(x, y + 1) == WALL) ret = false;
				if (QIE && GameS == GameS_Upright && y < dath - 1 && d(x, y + 2) == WALL) *QIE = FS;
			}
			break;
		case GameFS_Left:
			if (x > 1) {
				if (d(x - 1, y) == WALL) ret = false;
				if (QIE && GameS == GameS_Upright && x > 2 && d(x - 2, y) == WALL) *QIE = FS;
			}
			break;
		case GameFS_Right:
			if (x < datw) {
				if (d(x + 1, y) == WALL) ret = false;
				if (QIE && GameS == GameS_Upright && x < datw - 1 && d(x + 2, y) == WALL) *QIE = FS;
			}
			break;
		}
		break;
	case GameS_Horizontal:
		switch (FS) {
		case GameFS_Up:
			if (y > 1) {
				if (d(x, y - 1) == WALL) {
					if (d(x, y) != WALL) ret = false; else if (QIE) *QIE = GameFS_Left; // left block?
				}
				if (d(x + 1, y - 1) == WALL) {
					if (d(x + 1, y) != WALL) ret = false; else if (QIE) *QIE = GameFS_Right; // right block?
				}
			}
			break;
		case GameFS_Down:
			if (y < dath) {
				if (d(x, y + 1) == WALL) {
					if (d(x, y) != WALL) ret = false; else if (QIE) *QIE = GameFS_Left; // left block?
				}
				if (d(x + 1, y + 1) == WALL) {
					if (d(x + 1, y) != WALL) ret = false; else if (QIE) *QIE = GameFS_Right; // right block?
				}
			}
			break;
		case GameFS_Left:
			if ((x > 1 && d(x - 1, y) == WALL) || d(x, y) == WALL) ret = false;
			break;
		case GameFS_Right:
			if ((x < datw - 1 && d(x + 2, y) == WALL) || d(x + 1, y) == WALL) ret = false;
			break;
		}
		break;
	case GameS_Vertical:
		switch (FS) {
		case GameFS_Up:
			if ((y > 1 && d(x, y - 1) == WALL) || d(x, y) == WALL) ret = false;
			break;
		case GameFS_Down:
			if ((y < dath - 1 && d(x, y + 2) == WALL) || d(x, y + 1) == WALL) ret = false;
			break;
		case GameFS_Left:
			if (x > 1) {
				if (d(x - 1, y) == WALL) {
					if (d(x, y) != WALL) ret = false; else if (QIE) *QIE = GameFS_Up; // up block?
				}
				if (d(x - 1, y + 1) == WALL) {
					if (d(x, y + 1) != WALL) ret = false; else if (QIE) *QIE = GameFS_Down; // down block?
				}
			}
			break;
		case GameFS_Right:
			if (x < datw) {
				if (d(x + 1, y) == WALL) {
					if (d(x, y) != WALL) ret = false; else if (QIE) *QIE = GameFS_Up; // up block?
				}
				if (d(x + 1, y + 1) == WALL) {
					if (d(x, y + 1) != WALL) ret = false; else if (QIE) *QIE = GameFS_Down; // down block?
				}
			}
			break;
		}
		break;
	}

	return ret;
}

enumBloxorzStateValid clsBloxorz::BloxorzCheckIsValidState(const Array2D<unsigned char, 1, 1>& d, int x, int y, int GameS, int x2, int y2) const {
	switch (GameS) {
	case GameS_Upright:
		if (x > 0 && y > 0 && x <= datw && y <= dath) {
			switch (d(x, y)) {
			case WALL:
				// ERR!!
				return BState_UnknownError;
			case EMPTY: case BRIDGE_OFF:
				return BState_Fall;
			case THIN_GROUND:
				return BState_Thin;
			default:
				return BState_Valid;
			}
		}
		break;
	case GameS_Horizontal:
		if (x > 0 && y > 0 && x < datw && y <= dath) {
			if (d(x, y) == WALL && d(x + 1, y) == WALL) {
				// ERR!!
				return BState_UnknownError;
			} else if (d(x, y) == EMPTY || d(x, y) == BRIDGE_OFF || d(x + 1, y) == EMPTY || d(x + 1, y) == BRIDGE_OFF) {
				return BState_Fall;
			} else {
				return BState_Valid;
			}
		}
		break;
	case GameS_Vertical:
		if (x > 0 && y > 0 && x <= datw && y < dath) {
			if (d(x, y) == WALL && d(x, y + 1) == WALL) {
				// ERR!!
				return BState_UnknownError;
			} else if (d(x, y) == EMPTY || d(x, y) == BRIDGE_OFF || d(x, y + 1) == EMPTY || d(x, y + 1) == BRIDGE_OFF) {
				return BState_Fall;
			} else {
				return BState_Valid;
			}
		}
		break;
	case GameS_Single:
		if (x > 0 && y > 0 && x <= datw && y <= dath && x2 > 0 && y2 > 0 && x2 <= datw && y2 <= dath) {
			if (d(x, y) == WALL || d(x2, y2) == WALL) {
				// ERR!!
				return BState_UnknownError;
			} else if (d(x, y) == EMPTY || d(x, y) == BRIDGE_OFF || d(x2, y2) == EMPTY || d(x2, y2) == BRIDGE_OFF) {
				return BState_Fall;
			} else {
				return BState_Valid;
			}
		}
		break;
	}

	return BState_Fall;
}
