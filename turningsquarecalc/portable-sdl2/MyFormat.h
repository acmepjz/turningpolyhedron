#pragma once

/*
a simple and fake formatter

supported format:
%(<num>$)?[+ -#0']*(<num>|[*])?([.](<num>|[*]))?[diufFeEgGaAxXoscp%]

"'" means thousand separator

*/

//TODO: support [*](<num>$)?

#include "UTF8-16.h"
#include <vector>

//for int*_t, etc. and SIZEOF_VOIDP
#include <SDL_stdinc.h>

namespace MyFormatFlags{
	const int HasPlus=1;
	const int HasSpace=2;
	const int HasMinus=4;
	const int Alternate=8;
	const int HasZero=16;
	const int HasThousandSeparator=32;
}

struct MyFormatPlaceholder{
	unsigned short Position; //0 means unspecified
	unsigned char Flags;
	char Type;
	int Width; //>0 or -1="*", -2=doesn't exist (-3=uninitialized)
	int Precision; //>=0 or -1="*", -2=doesn't exist (-3=uninitialized)

	int nStart;
};

class MyFormat{
public:
	MyFormat();
	MyFormat(const u8string& fmt);

	void append(int8_t n){append((int32_t)n,true);}
	void append(uint8_t n){append((int32_t)n,false);}
	void append(int16_t n){append((int32_t)n,true);}
	void append(uint16_t n){append((int32_t)n,false);}
	void append(int32_t n){append((int32_t)n,true);}
	void append(uint32_t n){append((int32_t)n,false);}
	void append(int64_t n){append((int64_t)n,true);}
	void append(uint64_t n){append((int64_t)n,false);}

	void append(int32_t n,bool bSigned);
	void append(int64_t n,bool bSigned);

	void append(double n);

	void append(const u8string& s);

	void append(const void* lp);

	void append(const char* lp);

	const u8string& str() const;
	const char* c_str() const{
		return str().c_str();
	}

	void appendFormat(const u8string& fmt);
	void clear();
	void restart();

	MyFormat& operator()(const u8string& fmt){
		appendFormat(fmt);
		return *this;
	}

	template<class T>
	MyFormat& operator<<(const T& t){
		append(t);
		return *this;
	}
private:
	u8string m_sFormat;
	mutable u8string m_sReturn;
	std::vector<MyFormatPlaceholder> m_Placeholder;
	std::vector<u8string> m_sFormattedString;
	int m_nIndex; //index of first unformatted string
	int m_nPosition; //position of input data, -1 means there is no input data specifies position
	MyFormatPlaceholder m_tCurrent;
	mutable bool m_bDirty;

	void appendByPosition(int index,int32_t n,bool bSigned);
	void appendByPosition(int index,int64_t n,bool bSigned);
	void appendByPosition(int index,double n);
	void appendByPosition(int index,const u8string& s);
	void appendByPosition(int index,const char* lp);
	void rawAppendByPosition(int index,const char* lp);

	template<class T,class UT>
	void appendIntegerByPosition(int index,T n,bool bSigned);
};

inline const u8string& str(const MyFormat& obj){
	return obj.str();
}

inline const char* c_str(const MyFormat& obj){
	return obj.c_str();
}
