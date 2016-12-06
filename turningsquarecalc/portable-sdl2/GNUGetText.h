#pragma once

//A simple and buggy implementation of GNU GetText

#include "UTF8-16.h"
#include <map>

class GNUGetText{
public:
	static bool GetSystemLocale(char* buf,int size);

	bool LoadFileWithAutoLocale(const u8string& sFileName);
	bool LoadFile(const u8string& sFileName);
	void Close();

	u8string GetText(const u8string& s) const;
public:
	std::map<u8string,u8string> m_objString;

	u8string m_sCurrentLocale;
};
