#pragma once

#include <string>

typedef std::string u8string;
typedef std::basic_string<unsigned short> u16string;

u8string toUTF8(const u16string& src);
u16string toUTF16(const u8string& src);

//read a Unicode codepoint from a UTF-8 string.
//return value: bytes read, 0 means error
//warning: no sanity check
int readUTF8(const char* src,int& c);

//read a Unicode codepoint from a UTF-16 string.
//return value: unsigned shorts read, 0 means error
//warning: no sanity check
int readUTF16(const unsigned short* src,int& c);

#define U8STRING_FOR_EACH_CHARACTER_DO_BEGIN(STR,I,M,CH,INVALID_CH) \
	for(size_t I=0;I<M;I++){ \
		int CH=(unsigned char)STR[I]; \
		if(CH<0x80){ \
		}else if(CH<0xC0){ \
			CH=INVALID_CH; \
		}else if(CH<0xE0){ \
			if(I+1>=M) CH=INVALID_CH; \
			else{ \
				int c2=(unsigned char)STR[I+1]; \
				if((c2&0xC0)!=0x80) CH=INVALID_CH; \
				else{ \
					CH=((CH & 0x1F)<<6) | (c2 & 0x3F); \
					I++; \
				} \
			} \
		}else if(CH<0xF0){ \
			if(I+2>=M) CH=INVALID_CH; \
			else{ \
				int c2=(unsigned char)STR[I+1]; \
				int c3=(unsigned char)STR[I+2]; \
				if((c2&0xC0)!=0x80 || (c3&0xC0)!=0x80) CH=INVALID_CH; \
				else{ \
					CH=((CH & 0xF)<<12) | ((c2 & 0x3F)<<6) | (c3 & 0x3F); \
					I+=2; \
				} \
			} \
		}else if(CH<0xF8){ \
			if(I+3>=M) CH=INVALID_CH; \
			else{ \
				int c2=(unsigned char)STR[I+1]; \
				int c3=(unsigned char)STR[I+2]; \
				int c4=(unsigned char)STR[I+3]; \
				if((c2&0xC0)!=0x80 || (c3&0xC0)!=0x80 || (c4&0xC0)!=0x80) CH=INVALID_CH; \
				else{ \
					CH=((CH & 0x7)<<18) | ((c2 & 0x3F)<<12) | ((c3 & 0x3F)<<6) | (c4 & 0x3F); \
					if(CH>=0x110000) CH=INVALID_CH; \
					else I+=3; \
				} \
			} \
		}else{ \
			CH=INVALID_CH; \
		}

#define U8STRING_FOR_EACH_CHARACTER_DO_END() }

#define U8_ENCODE(CH,OPERATION) \
	if(CH<0x80){ \
		OPERATION(CH); \
	}else if(CH<0x800){ \
		OPERATION(0xC0 | (CH>>6)); \
		OPERATION(0x80 | (CH & 0x3F)); \
	}else if(CH<0x10000){ \
		OPERATION(0xE0 | (CH>>12)); \
		OPERATION(0x80 | ((CH>>6) & 0x3F)); \
		OPERATION(0x80 | (CH & 0x3F)); \
	}else{ \
		OPERATION(0xF0 | (CH>>18)); \
		OPERATION(0x80 | ((CH>>12) & 0x3F)); \
		OPERATION(0x80 | ((CH>>6) & 0x3F)); \
		OPERATION(0x80 | (CH & 0x3F)); \
	}

#define U16STRING_FOR_EACH_CHARACTER_DO_BEGIN(STR,I,M,CH,INVALID_CH) \
	for(size_t I=0;I<M;I++){ \
		int CH=(unsigned short)(STR[I]); \
		if(CH<0xD800){ \
		}else if(CH<0xDC00){ \
			/* lead surrogate */ \
			I++; \
			if(I>=M) CH=INVALID_CH; \
			else{ \
				int c2=(unsigned short)STR[I]; \
				if(CH>=0xDC00 && CH<0xE000){ \
					/* trail surrogate */ \
					CH=0x10000 + (((CH & 0x3FF)<<10) | (c2 & 0x3FF)); \
				}else{ \
					/* invalid */ \
					CH=INVALID_CH; \
					I--; \
				} \
			} \
		}else if(CH<0xE000){ \
			/* invalid trail surrogate */ \
			CH=INVALID_CH; \
		}

#define U16STRING_FOR_EACH_CHARACTER_DO_END() }

#define U16_ENCODE(CH,OPERATION) \
	if(CH<0x10000){ \
		OPERATION(CH); \
	}else{ \
		OPERATION(0xD800 | ((CH-0x10000)>>10)); \
		OPERATION(0xDC00 | (CH & 0x3FF)); \
	}
