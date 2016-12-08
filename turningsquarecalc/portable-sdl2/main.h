#pragma once

#include "GNUGetText.h"
#include <SDL_ttf.h>

extern GNUGetText objText;

#define _(X) (objText.GetText(X))

extern TTF_Font* m_objFont[3];
