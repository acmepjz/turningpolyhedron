#include "UTF8-16.h"

u8string toUTF8(const u16string& src){
	u8string ret;
	size_t m=src.size();
	if(m>0){
		ret.reserve(m*3);

		U16STRING_FOR_EACH_CHARACTER_DO_BEGIN(src,i,m,c,'?');

		//encode UTF-8
		U8_ENCODE(c,ret.push_back);

		U16STRING_FOR_EACH_CHARACTER_DO_END();
	}
	return ret;
}

u16string toUTF16(const u8string& src){
	u16string ret;
	size_t m=src.size();
	if(m>0){
		ret.reserve(m);

		U8STRING_FOR_EACH_CHARACTER_DO_BEGIN(src,i,m,c,'?');

		//encode UTF-16
		U16_ENCODE(c,ret.push_back);

		U8STRING_FOR_EACH_CHARACTER_DO_END();
	}
	return ret;
}

int readUTF8(const char* src,int& c){
	c=(unsigned char)src[0];

	if(c<0x80){
		return 1;
	}else if(c<0xC0){
		return 0;
	}else if(c<0xE0){
		int c2=(unsigned char)src[1];
		if((c2&0xC0)!=0x80) return 0;

		c=((c & 0x1F)<<6) | (c2 & 0x3F);
		return 2;
	}else if(c<0xF0){
		int c2=(unsigned char)src[1];
		if((c2&0xC0)!=0x80) return 0;
		int c3=(unsigned char)src[2];
		if((c3&0xC0)!=0x80) return 0;

		c=((c & 0xF)<<12) | ((c2 & 0x3F)<<6) | (c3 & 0x3F);
		return 3;
	}else if(c<0xF8){
		int c2=(unsigned char)src[1];
		if((c2&0xC0)!=0x80) return 0;
		int c3=(unsigned char)src[2];
		if((c3&0xC0)!=0x80) return 0;
		int c4=(unsigned char)src[3];
		if((c4&0xC0)!=0x80) return 0;

		c=((c & 0x7)<<18) | ((c2 & 0x3F)<<12) | ((c3 & 0x3F)<<6) | (c4 & 0x3F);
		if(c>=0x110000) return 0;
		return 4;
	}else{
		return 0;
	}
}

int readUTF16(const unsigned short* src,int& c){
	c=(unsigned short)src[0];

	if(c<0xD800){
		return 1;
	}else if(c<0xDC00){
		//lead surrogate
		int c2=(unsigned short)src[1];
		if(c>=0xDC00 && c<0xE000){
			//trail surrogate
			c=0x10000 + (((c & 0x3FF)<<10) | (c2 & 0x3FF));
			return 2;
		}else{
			//invalid
			return 0;
		}
	}else if(c<0xE000){
		//invalid trail surrogate
		return 0;
	}else{
		return 1;
	}
}
