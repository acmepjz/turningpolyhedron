#include "SimpleMenu.h"
#include "main.h"
#include "MyFormat.h"

#include <SDL.h>

SimpleMenu::SimpleMenu()
	: listIndex(-1)
	, itemWidth(192), itemHeight(32)
	, minColumn(1)
	, fontSize(0)
	, defaultButton(0x80000000), cancelButton(0x80000000), closeButton(0x80000000)
{
}

int SimpleMenu::MenuLoop() const {
	_RECT r0; // the whole window with border
	_RECT r1; // the items area
	_RECT otherButtons[5] = {}; // X, <<, <, >, >>

	const int itemCount = item.size();

	// window size without border
	int w = 0, h = 0;

	// check size of title
	if (!title.empty()) {
		TTF_SizeUTF8(m_objFont[1], title.c_str(), &w, &h);
		if (h < 40) h = 40;
	}
	
	// check size of close button
	if (closeButton != 0x80000000) {
		w += 80;
		if (h < 32) h = 32;
	}

	// check max columns and rows
	int columnCount = (640 - 8) / itemWidth;
	int rowCount = (480 - 8 - h) / itemHeight;
	int pageCount = 1;
	if (columnCount < minColumn) columnCount = minColumn;

	int itemPerPage = columnCount * rowCount;
	if (itemPerPage < itemCount) {
		// we need more pages
		rowCount--;
		itemPerPage = columnCount * rowCount;
		pageCount = (itemCount + itemPerPage - 1) / itemPerPage;
	} else {
		// make it look nicer
		columnCount = (itemCount + rowCount - 1) / rowCount;
		if (columnCount < minColumn) columnCount = minColumn;
		rowCount = (itemCount + columnCount - 1) / columnCount;
		itemPerPage = columnCount * rowCount;
	}

	// calculate actual item width
	int iw = itemWidth;
	if (itemWidth * columnCount < w) {
		iw = (w + columnCount - 1) / columnCount;
	}
	const int ih = itemHeight;

	// calculate actual window size
	w = iw * columnCount;
	h += ih * (rowCount + (pageCount > 1 ? 1 : 0));

	r0.Left = 320 - 4 - w / 2; r0.Right = r0.Left + w + 8;
	r0.Top = 240 - 4 - h / 2; r0.Bottom = r0.Top + h + 8;

	if (closeButton != 0x80000000) {
		otherButtons[0].Left = r0.Right - 36; otherButtons[0].Right = r0.Right - 4;
		otherButtons[0].Top = r0.Top + 4; otherButtons[0].Bottom = r0.Top + 36;
	}

	r1.Left = 320 - w / 2; r1.Right = r1.Left + w;
	r1.Bottom = r0.Bottom - 4; r1.Top = r1.Bottom - ih * rowCount;

	if (pageCount >= 2) {
		otherButtons[1].Left = r1.Left; otherButtons[1].Right = r1.Left + 32;
		otherButtons[1].Top = r1.Top - ih; otherButtons[1].Bottom = r1.Top;
		otherButtons[4].Left = r1.Right - 32; otherButtons[4].Right = r1.Right;
		otherButtons[4].Top = r1.Top - ih; otherButtons[4].Bottom = r1.Top;
		if (pageCount >= 3) {
			otherButtons[2].Left = r1.Left + 32; otherButtons[2].Right = r1.Left + 64;
			otherButtons[2].Top = r1.Top - ih; otherButtons[2].Bottom = r1.Top;
			otherButtons[3].Left = r1.Right - 64; otherButtons[3].Right = r1.Right - 32;
			otherButtons[3].Top = r1.Top - ih; otherButtons[3].Bottom = r1.Top;
		}
	}

	int currentPage = (listIndex >= 0 && listIndex < itemCount) ? listIndex / itemPerPage : 0;

	bRenderTargetDirty = true;
	while (bRun) {
		// get message
		int buttonHighlight = -1, buttonClicked = -1;
		bool clicked = false;
		SDL_Event event;
		while (SDL_PollEvent(&event)) {
			switch (event.type) {
			case SDL_MOUSEBUTTONDOWN:
				if (event.button.button == SDL_BUTTON_LEFT) {
					clicked = true;
				}
				break;
			case SDL_KEYDOWN:
				switch (event.key.keysym.scancode) {
				case SDL_SCANCODE_RETURN:
					if (defaultButton != 0x80000000) return defaultButton;
					break;
				case SDL_SCANCODE_ESCAPE:
				case SDL_SCANCODE_AC_BACK:
					if (cancelButton != 0x80000000) return cancelButton;
					break;
				case SDL_SCANCODE_HOME:
					buttonClicked = 1 - 100;
					break;
				case SDL_SCANCODE_PAGEUP:
					buttonClicked = 2 - 100;
					break;
				case SDL_SCANCODE_PAGEDOWN:
					buttonClicked = 3 - 100;
					break;
				case SDL_SCANCODE_END:
					buttonClicked = 4 - 100;
					break;
				}
				break;
			}
		}

		if (bRenderTargetDirty) {
			PaintPicture(bmG_Lv, bmG_Back);

			// background
			_FillRect(bmG_Back, r0, 0x000000);
			_FrameRect(bmG_Back, r0, 0x0080FF);

			// title
			if (!title.empty()) {
				DrawTextB(bmG_Back, title, m_objFont[1],
					r0.Left, r0.Top, r0.Right - r0.Left, 40,
					_DT_CENTER | _DT_VCENTER | _DT_SINGLELINE, 0xFFFFFF);
			}

			// close button
			if (closeButton != 0x80000000) {
				DrawTextB(bmG_Back, "\xE2\x9C\x95", m_objFont[1],
					r0.Right - 36, r0.Top + 4, 32, 32,
					_DT_CENTER | _DT_VCENTER | _DT_SINGLELINE, 0xFFFFFF);
			}

			// page up / page down
			if (pageCount >= 2) {
				DrawTextB(bmG_Back, str(MyFormat(_("Page %d of %d")) << (currentPage + 1) << pageCount), m_objFont[0],
					r1.Left, r1.Top - ih, r1.Right - r1.Left, ih,
					_DT_CENTER | _DT_VCENTER | _DT_SINGLELINE, 0xFFFFFF);
				DrawTextB(bmG_Back, "<<", m_objFont[0],
					r1.Left, r1.Top - ih, 32, ih,
					_DT_CENTER | _DT_VCENTER | _DT_SINGLELINE, 0xFFFFFF);
				DrawTextB(bmG_Back, ">>", m_objFont[0],
					r1.Right - 32, r1.Top - ih, 32, ih,
					_DT_CENTER | _DT_VCENTER | _DT_SINGLELINE, 0xFFFFFF);
				if (pageCount >= 3) {
					DrawTextB(bmG_Back, "<", m_objFont[0],
						r1.Left + 32, r1.Top - ih, 32, ih,
						_DT_CENTER | _DT_VCENTER | _DT_SINGLELINE, 0xFFFFFF);
					DrawTextB(bmG_Back, ">", m_objFont[0],
						r1.Right - 64, r1.Top - ih, 32, ih,
						_DT_CENTER | _DT_VCENTER | _DT_SINGLELINE, 0xFFFFFF);
				}
			}

			// text
			for (int x = 0; x < columnCount; x++) {
				for (int y = 0; y < rowCount; y++) {
					int j = currentPage * itemPerPage + x * rowCount + y;
					if (j < 0 || j >= itemCount) break;
					_RECT r; 
					r.Left = r1.Left + x*iw; r.Right = r.Left + iw;
					r.Top = r1.Top + y*ih; r.Bottom = r.Top + ih;
					if (j == listIndex) {
						_FillRect(bmG_Back, r, 0x004080);
					}
					DrawTextB(bmG_Back, item[j], m_objFont[fontSize],
						r.Left, r.Top, iw, ih,
						_DT_CENTER | _DT_VCENTER | _DT_SINGLELINE, 0xFFFFFF);
				}
			}

			bRenderTargetDirty = false;
		}

		// hit test
		int px, py;
		_GetCursorPos(&px, &py);
		if (_PtInRect(r1, px, py)) {
			buttonHighlight = ((px - r1.Left) / iw)*rowCount + (py - r1.Top) / ih;
			int i = currentPage * itemPerPage + buttonHighlight;
			if (i < 0 || i >= itemCount) buttonHighlight = -1;
		} else {
			for (int i = 0; i < 5; i++) {
				if (_PtInRect(otherButtons[i], px, py)) {
					buttonHighlight = i - 100;
					break;
				}
			}
		}

		// draw
		_Cls(NULL);
		PaintPicture(bmG_Back, NULL);
		if (buttonHighlight >= 0) {
			int x = buttonHighlight / rowCount, y = buttonHighlight % rowCount;
			_RECT r;
			r.Left = r1.Left + x*iw; r.Right = r.Left + iw;
			r.Top = r1.Top + y*ih; r.Bottom = r.Top + ih;
			_FrameRect(NULL, r, 0x0080FF);
		} else {
			int i = buttonHighlight + 100;
			if (i >= 0 && i < 5) _FrameRect(NULL, otherButtons[i], 0x0080FF);
		}

		Game_Paint();
		WaitForNextFrame();

		if (clicked && buttonClicked == -1) buttonClicked = buttonHighlight;

		if (buttonClicked != -1) {
			if (buttonClicked >= 0) return currentPage * itemPerPage + buttonClicked;
			switch (buttonClicked + 100) {
			case 0: // close
				return closeButton;
				break;
			case 1: // first page
				if (currentPage > 0) {
					currentPage = 0;
					bRenderTargetDirty = true;
				}
				break;
			case 2: // prev page
				if (currentPage > 0) {
					currentPage--;
					bRenderTargetDirty = true;
				}
				break;
			case 3: // next page
				if (currentPage < pageCount - 1) {
					currentPage++;
					bRenderTargetDirty = true;
				}
				break;
			case 4: // last page
				if (currentPage < pageCount - 1) {
					currentPage = pageCount - 1;
					bRenderTargetDirty = true;
				}
				break;
			}
		}
	}

	return -1;
}
