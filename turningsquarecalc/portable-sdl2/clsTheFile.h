#pragma once

const char BOX_SIGNATURE[8] = { '\xD2', '\xA1', '\xB7', '\xBD', '\xBF', '\xE9', 'X', 'P' };
const char BOX_LEV0[4] = { 'L', 'E', 'V', '\0' };

#include <vector>
#include <string>

typedef std::vector<char> typeFileNode;

struct typeFileNodeArray {
	char name[4];
	std::vector<typeFileNode> nodes;
};

class clsTheFile {
public:
	bool LoadFile(const char* fn = NULL, const char* _signature = NULL, bool bSkipSignature = false);
	bool SaveFile(const char* fn = NULL, bool IsCompress = true);
	typeFileNodeArray* AddNodeArray(const char* name = NULL);
	typeFileNodeArray* FindNodeArray(const char* name);
	void SetSignature(const char* _signature);
private:
	char signature[8];
	std::string m_sFileName;
public:
	std::vector<typeFileNodeArray> nodes;
};
