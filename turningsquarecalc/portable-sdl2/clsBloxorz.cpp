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
