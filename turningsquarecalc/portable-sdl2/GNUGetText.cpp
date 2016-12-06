//A simple and buggy implementation of GNU GetText

#include "GNUGetText.h"
#include "FileSystem.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <SDL_endian.h>
#include <SDL_platform.h>

#ifdef __WIN32__
#include <windows.h>
#endif

#ifdef ANDROID
#include <SDL_system.h>
#include <jni.h>
#endif

static bool GetSystemLocale0(char* buf,int size){
	char *s;

	s=getenv("LC_ALL");
	if(s && s[0]){
		strncpy(buf,s,size);
		return true;
	}

	s=getenv("LC_MESSAGES");
	if(s && s[0]){
		strncpy(buf,s,size);
		return true;
	}

	s=getenv("LANG");
	if(s && s[0]){
		strncpy(buf,s,size);
		return true;
	}

	s=getenv("LANGUAGE");
	if(s && s[0]){
		strncpy(buf,s,size);
		return true;
	}

#ifdef __WIN32__
	int i=GetLocaleInfoA(LOCALE_USER_DEFAULT,LOCALE_SISO639LANGNAME,buf,size);
	if(i>0 && i<size){
		int j=GetLocaleInfoA(LOCALE_USER_DEFAULT,LOCALE_SISO3166CTRYNAME,buf+i,size-i);
		if(j>0) buf[i-1]='_';

		return true;
	}
#endif

#ifdef ANDROID
	JNIEnv* env=(JNIEnv*)SDL_AndroidGetJNIEnv();

	env->PushLocalFrame(16);

	//call Locale.getDefault().toString()
	jclass cls=env->FindClass("java/util/Locale");
	jobject obj=env->CallStaticObjectMethod(cls,
		env->GetStaticMethodID(cls,"getDefault","()Ljava/util/Locale;")
		);
	jstring str=(jstring)env->CallObjectMethod(obj,
		env->GetMethodID(cls,"toString","()Ljava/lang/String;")
		);

	//get content of string
	const char* lp=env->GetStringUTFChars(str,NULL);
	strncpy(buf,lp,size);
	env->ReleaseStringUTFChars(str,lp);

	env->PopLocalFrame(NULL);

	return true;
#endif

	//shouldn't goes here
	printf("[GNUGetText] Error: GetSystemLocale() failed!\n");

	buf[0]=0;
	return false;
}

bool GNUGetText::GetSystemLocale(char* buf,int size){
	if(!GetSystemLocale0(buf,size)) return false;

#ifdef __IPHONEOS__
	// Copied from Anura engine: hack to make it work on iOS
	if(strcmp(buf,"zh-Hans")==0) strncpy(buf,"zh_CN",size);
	if(strcmp(buf,"zh-Hant")==0) strncpy(buf,"zh_TW",size);
#endif

	return true;
}

bool GNUGetText::LoadFileWithAutoLocale(const u8string& sFileName){
	size_t nReplaceIndex;
	if((nReplaceIndex=sFileName.find_first_of('*'))==u8string::npos){
		return LoadFile(sFileName);
	}

	char buf[256];
	GetSystemLocale(buf,sizeof(buf));

	int lps=0;

	for(;;){
		if(buf[lps]==0) break;

		int lpe=lps;

		while(buf[lpe]!=';' && buf[lpe]!=',' && buf[lpe]!=':' && buf[lpe]!=0) lpe++;
		bool bExit=(buf[lpe]==0);
		buf[lpe]=0;

		u8string str(buf+lps);
		u8string fn(sFileName);

		fn.replace(nReplaceIndex,1,str);
		if(LoadFile(fn)) return true;

		size_t i=str.find_first_of('.'); //e.g. en_US.ISO_8859-1
		if(i!=str.npos){
			fn=sFileName;
			fn.replace(nReplaceIndex,1,str.substr(0,i));
			if(LoadFile(fn)) return true;
		}

		i=str.find_first_of('@'); //e.g. sr@latin
		if(i!=str.npos){
			fn=sFileName;
			fn.replace(nReplaceIndex,1,str.substr(0,i));
			if(LoadFile(fn)) return true;
		}

		i=str.find_first_of('_'); //e.g. de_DE
		size_t i2=str.find_first_of('_',i+1); //e.g. no_NO_NB
		if(i2!=str.npos){
			fn=sFileName;
			fn.replace(nReplaceIndex,1,str.substr(0,i2));
			if(LoadFile(fn)) return true;
		}
		if(i!=str.npos){
			fn=sFileName;
			fn.replace(nReplaceIndex,1,str.substr(0,i));
			if(LoadFile(fn)) return true;
		}

		if(bExit) break;
		lps=lpe+1;
	}

	return false;
}

bool GNUGetText::LoadFile(const u8string& sFileName){
	u8file *f=u8fopen(sFileName.c_str(),"rb");
	if(f==NULL) return false;

	bool ret=false;

	int header[5];
	u8fread(header,20,1,f);
#if SDL_BYTEORDER==SDL_BIG_ENDIAN
	for(int i=0;i<5;i++) header[i]=SDL_SwapLE32(header[i]);
#endif

	if(header[0]==0x950412DE && header[1]==0){
		m_objString.clear();
		m_sCurrentLocale.clear();

		if(header[2]>0 && header[3]>0 && header[4]>0){
			std::vector<int> OriginalString,TranslatedString;
			OriginalString.resize(header[2]*2);
			TranslatedString.resize(header[2]*2);

			u8fseek(f,header[3],SEEK_SET);
			u8fread(&(OriginalString[0]),header[2]*8,1,f);
			u8fseek(f,header[4],SEEK_SET);
			u8fread(&(TranslatedString[0]),header[2]*8,1,f);

			for(int i=0;i<header[2];i++){
				u8string s1,s2;

				int length,offset;

				if((length=SDL_SwapLE32(OriginalString[i*2]))>0
					&& (offset=SDL_SwapLE32(OriginalString[i*2+1]))>0)
				{
					u8fseek(f,offset,SEEK_SET);
					s1.resize(length);
					u8fread(&(s1[0]),length,1,f);
				}

				if((length=SDL_SwapLE32(TranslatedString[i*2]))>0
					&& (offset=SDL_SwapLE32(TranslatedString[i*2+1]))>0)
				{
					u8fseek(f,offset,SEEK_SET);
					s2.resize(length);
					u8fread(&(s2[0]),length,1,f);
				}

				m_objString[s1]=s2;
			}
		}

		//update current locale
		m_sCurrentLocale=sFileName;
		u8string::size_type lps=m_sCurrentLocale.find_last_of("\\/");
		if(lps!=u8string::npos) m_sCurrentLocale=m_sCurrentLocale.substr(lps+1);
		lps=m_sCurrentLocale.find_last_of('.');
		if(lps!=u8string::npos) m_sCurrentLocale=m_sCurrentLocale.substr(0,lps);

		ret=true;
	}

	u8fclose(f);

	return ret;
}

void GNUGetText::Close(){
	m_objString.clear();
	m_sCurrentLocale.clear();
}

u8string GNUGetText::GetText(const u8string& s) const{
	if(s.empty()) return s;

	std::map<u8string,u8string>::const_iterator it=m_objString.find(s);

	if(it==m_objString.end()) return s;
	else return it->second;
}
