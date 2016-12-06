#include "clsTheFile.h"
#include "FileSystem.h"
#include "LZSS.h"
#include <SDL_endian.h>
#include <SDL_rwops.h>

static bool mycmp(const char* s1, const char* s2, int maxlen) {
	for (int i = 0; i < maxlen; i++) {
		if (s1[i] != s2[i]) return false;
		if (s1[i] == 0) return true;
	}
	return true;
}

static void mycpy(char* dst, const char* src, int maxlen) {
	for (int i = 0; i < maxlen; i++) {
		if ((dst[i] = src[i]) == 0) {
			while ((++i) < maxlen) dst[i] = 0;
			return;
		}
	}
}

bool clsTheFile::LoadFile(const char* fn, const char* _signature, bool bSkipSignature) {
	const char* fn1 = fn ? fn : (m_sFileName.empty() ? NULL : m_sFileName.c_str());
	if (fn1 == NULL) return false;

	u8file *f = u8fopen(fn1, "rb");
	if (f == NULL) return false;

	std::vector<char> data; //used only when it is compressed
	bool ret = false;

	char _sig[8];
	if (u8fread(_sig, 8, 1, f) == 1) {
		if (bSkipSignature || _signature == NULL || _signature[0] == 0 || mycmp(_sig, _signature, 8)) {
			int len = SDL_ReadLE32(f);
			if (len < 0) {
				// it is LZSS compressed
				int m = u8fseek2(f, 0, SEEK_END) - 12;
				u8fseek(f, 12, SEEK_SET);
					
				len = -len;
				data.resize(len);

				LZSS lzss;
				lzss.infile = f;
				lzss.outfile = SDL_RWFromMem(&(data[0]), len);
				lzss.Decode();

				u8fclose(f);
				f = lzss.outfile;
				u8fseek(f, 0, SEEK_SET);
			}

			// start to read actual data
			nodes.clear();
			ret = true;
			int nodeCount = SDL_ReadLE32(f);
			if (nodeCount > 0) {
				nodes.resize(nodeCount);
				for (int i = 0; i < nodeCount; i++) {
					if (u8fread(nodes[i].name, 4, 1, f) != 1) {
						ret = false;
						break;
					}
					int m = SDL_ReadLE32(f);
					if (m > 0) {
						nodes[i].nodes.resize(m);
						for (int j = 0; j < m; j++) {
							int m2 = SDL_ReadLE32(f);
							if (m2 > 0) {
								nodes[i].nodes[j].resize(m2);
								if (u8fread(&(nodes[i].nodes[j][0]), 1, m2, f) != m2) {
									ret = false;
									break;
								}
							}
						}
					}
				}
			}
		}
	}

	u8fclose(f);

	if (ret && fn) m_sFileName = fn;
	return ret;
}

bool clsTheFile::SaveFile(const char* fn, bool IsCompress) {
	const char* fn1 = fn ? fn : (m_sFileName.empty() ? NULL : m_sFileName.c_str());
	if (fn1 == NULL) return false;

	// generate actual data
	std::vector<char> data;
	int tmp = nodes.size();
	data.push_back(tmp); data.push_back(tmp >> 8); data.push_back(tmp >> 16); data.push_back(tmp >> 24);
	for (int i = 0, m = nodes.size(); i < m; i++) {
		data.insert(data.end(), nodes[i].name, nodes[i].name + 4);
		tmp = nodes[i].nodes.size();
		data.push_back(tmp); data.push_back(tmp >> 8); data.push_back(tmp >> 16); data.push_back(tmp >> 24);
		for (int j = 0, m2 = nodes[i].nodes.size(); j < m2; j++) {
			tmp = nodes[i].nodes[j].size();
			data.push_back(tmp); data.push_back(tmp >> 8); data.push_back(tmp >> 16); data.push_back(tmp >> 24);
			if (tmp > 0) {
				data.insert(data.end(), nodes[i].nodes[j].begin(), nodes[i].nodes[j].end());
			}
		}
	}

	int len = data.size();

	// save file
	u8file *f = u8fopen(fn1, "wb");
	if (f == NULL) return false;

	u8fwrite(signature, 8, 1, f);
	if (IsCompress) {
		u8file *f2 = SDL_RWFromConstMem(&(data[0]), len);
		len = -len;
		SDL_WriteLE32(f, len);

		LZSS lzss;
		lzss.infile = f2;
		lzss.outfile = f;
		lzss.Encode();

		u8fclose(f2);
	} else {
		SDL_WriteLE32(f, len);
		u8fwrite(&(data[0]), 1, len, f);
	}

	u8fclose(f);

	// over
	if (fn) m_sFileName = fn;
	return true;
}

typeFileNodeArray* clsTheFile::AddNodeArray(const char* name) {
	if (name == NULL) name = "";
	typeFileNodeArray node;
	mycpy(node.name, name, 4);
	nodes.push_back(node);
	return &(nodes[nodes.size() - 1]);
}

typeFileNodeArray* clsTheFile::FindNodeArray(const char* name) {
	for (int i = 0, m = nodes.size(); i < m; i++) {
		if (mycmp(nodes[i].name, name, 4)) {
			return &(nodes[i]);
		}
	}
	return NULL;
}

void clsTheFile::SetSignature(const char* _signature) {
	mycpy(signature, _signature, 8);
}
