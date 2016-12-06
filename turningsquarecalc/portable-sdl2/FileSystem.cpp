#include "FileSystem.h"
#include <SDL_platform.h>
#include <string.h>
#ifdef __WIN32__
#include <windows.h>
#if !defined(_WIN32_IE) || _WIN32_IE<0x0600
#undef _WIN32_IE
#define _WIN32_IE 0x0600
#endif
#if !defined(_WIN32_WINNT) || _WIN32_WINNT<0x0500
#undef _WIN32_WINNT
#define _WIN32_WINNT 0x0500
#endif
#include <shlobj.h>
#include <shlwapi.h>
#include <direct.h>
#ifdef _MSC_VER
#pragma comment(lib,"shlwapi.lib")
#endif
#else
#include <strings.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <dirent.h>
#endif

#include <SDL.h>

#define USE_SDL_RWOPS

u8string externalStoragePath;

char* u8fgets(char* buf, int count, u8file* file){
#ifdef USE_SDL_RWOPS
	for(int i=0;i<count-1;i++){
		if(u8fread(buf+i,1,1,file)==0){
			buf[i]=0;
			return (i>0)?buf:NULL;
		}
		if(buf[i]=='\n'){
			buf[i+1]=0;
			return buf;
		}
	}

	buf[count-1]=0;
	return buf;
#else
	return fgets(buf,count,(FILE*)file);
#endif
}

const char* u8fgets2(u8string& s,u8file* file){
	s.clear();

	if(file){
#ifdef USE_SDL_RWOPS
		char c;
		for(int i=0;;i++){
			if(u8fread(&c,1,1,file)==0) return (i>0)?s.c_str():NULL;
			s.push_back(c);
			if(c=='\n') return s.c_str();
		}
#else
		char buf[512];
		for(int i=0;;i++){
			if(fgets(buf,sizeof(buf),(FILE*)file)==NULL) return (i>0)?s.c_str():NULL;
			s.append(buf);
			if(!s.empty() && s[s.size()-1]=='\n') return s.c_str();
		}
#endif
	}

	return NULL;
}

size_t u8fputs2(const u8string& s,u8file* file){
	return u8fwrite(s.c_str(),1,s.size(),file);
}

u8file *u8fopen(const char* filename,const char* mode){
#ifdef USE_SDL_RWOPS
	return (u8file*)SDL_RWFromFile(filename,mode);
#else
#ifdef __WIN32__
	u16string filenameW=toUTF16(filename);
	u16string modeW=toUTF16(mode);
	return (u8file*)_wfopen((const wchar_t*)filenameW.c_str(),(const wchar_t*)modeW.c_str());
#else
	return (u8file*)fopen(filename,mode);
#endif
#endif
}

int u8fseek(u8file* file,long offset,int whence){
#ifdef USE_SDL_RWOPS
	if(file) return SDL_RWseek((SDL_RWops*)file,offset,whence)==-1?-1:0;
	return -1;
#else
	return fseek((FILE*)file,offset,whence);
#endif
}

long u8ftell(u8file* file){
#ifdef USE_SDL_RWOPS
	if(file) return (long)SDL_RWtell((SDL_RWops*)file);
	return -1;
#else
	return ftell((FILE*)file);
#endif
}

size_t u8fread(void* ptr,size_t size,size_t nmemb,u8file* file){
#ifdef USE_SDL_RWOPS
	if(file) return SDL_RWread((SDL_RWops*)file,ptr,size,nmemb);
	return 0;
#else
	return fread(ptr,size,nmemb,(FILE*)file);
#endif
}

size_t u8fwrite(const void* ptr,size_t size,size_t nmemb,u8file* file){
#ifdef USE_SDL_RWOPS
	if(file) return SDL_RWwrite((SDL_RWops*)file,ptr,size,nmemb);
	return 0;
#else
	return fwrite(ptr,size,nmemb,(FILE*)file);
#endif
}

int u8fclose(u8file* file){
#ifdef USE_SDL_RWOPS
	if(file) return SDL_RWclose((SDL_RWops*)file);
	return 0;
#else
	return fclose((FILE*)file);
#endif
}

std::vector<u8string> enumAllFiles(u8string path,const char* extension,bool containsPath){
	std::vector<u8string> v;
#ifdef __WIN32__
	WIN32_FIND_DATAW f;

	if(!path.empty()){
		char c=path[path.size()-1];
		if(c!='/' && c!='\\') path+="\\";
	}

	HANDLE h=NULL;
	{
		u8string s1=path;
		if(extension!=NULL && *extension){
			s1+="*.";
			s1+=extension;
		}else{
			s1+="*";
		}
		u16string s1b=toUTF16(s1);
		h=FindFirstFileW((LPCWSTR)s1b.c_str(),&f);
	}

	if(h==NULL || h==INVALID_HANDLE_VALUE) return v;

	do{
		if(!(f.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)){
			u8string s2=toUTF8((const unsigned short*)f.cFileName);
			if(containsPath){
				v.push_back(path+s2);
			}else{
				v.push_back(s2);
			}
		}
	}while(FindNextFileW(h,&f));

	FindClose(h);

	return v;
#else
	int len=0;
	if(extension!=NULL && *extension) len=strlen(extension);
	if(!path.empty()){
		char c=path[path.size()-1];
		if(c!='/'&&c!='\\') path+="/";
	}
	DIR *pDir;
	struct dirent *pDirent;
	pDir=opendir(path.c_str());
	if(pDir==NULL){
#ifdef ANDROID
		//ad-hoc workaround
		u8file *f=u8fopen((path+"list.txt").c_str(),"rb");
		if(f){
			u8string s;
			while(u8fgets2(s,f)){
				u8string::size_type lps=s.find_first_of("\r\n");
				if(lps!=u8string::npos) s=s.substr(0,lps);
				if(s.empty()) continue;

				//trim
				lps=s.find_first_not_of(" \t");
				if(lps>0) s=s.substr(lps);
				if(s.empty()) continue;

				lps=s.find_last_not_of(" \t");
				if(lps+1<s.size()) s=s.substr(0,lps+1);

				if(s.empty() || s[s.size()-1]=='/') continue;

				if(len>0){
					if((int)s.size()<len+1) continue;
					if(s[s.size()-len-1]!='.') continue;
					if(strcasecmp(&s[s.size()-len],extension)) continue;
				}

				if(containsPath){
					v.push_back(path+s);
				}else{
					v.push_back(s);
				}
			}
			u8fclose(f);
		}
#endif
		return v;
	}
	while((pDirent=readdir(pDir))!=NULL){
		if(pDirent->d_name[0]=='.'){
			if(pDirent->d_name[1]==0||
				(pDirent->d_name[1]=='.'&&pDirent->d_name[2]==0)) continue;
		}
		u8string s1=path+pDirent->d_name;
		struct stat S_stat;
		lstat(s1.c_str(),&S_stat);
		if(!S_ISDIR(S_stat.st_mode)){
			if(len>0){
				if((int)s1.size()<len+1) continue;
				if(s1[s1.size()-len-1]!='.') continue;
				if(strcasecmp(&s1[s1.size()-len],extension)) continue;
			}

			if(containsPath){
				v.push_back(s1);
			}else{
				v.push_back(u8string(pDirent->d_name));
			}
		}
	}
	closedir(pDir);
	return v;
#endif
}

std::vector<u8string> enumAllDirs(u8string path,bool containsPath){
	std::vector<u8string> v;
#ifdef __WIN32__
	WIN32_FIND_DATAW f;

	if(!path.empty()){
		char c=path[path.size()-1];
		if(c!='/' && c!='\\') path+="\\";
	}

	HANDLE h=NULL;
	{
		u16string s1b=toUTF16(path);
		s1b.push_back('*');
		h=FindFirstFileW((LPCWSTR)s1b.c_str(),&f);
	}

	if(h==NULL || h==INVALID_HANDLE_VALUE) return v;

	do{
		// skip '.' and '..' and hidden folders
		if(f.cFileName[0]=='.'){
			/*if(f.cFileName[1]==0||
				(f.cFileName[1]=='.'&&f.cFileName[2]==0))*/ continue;
		}
		if(f.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY){
			u8string s2=toUTF8((const unsigned short*)f.cFileName);
			if(containsPath){
				v.push_back(path+s2);
			}else{
				v.push_back(s2);
			}
		}
	}while(FindNextFileW(h,&f));

	FindClose(h);

	return v;
#else
	if(!path.empty()){
		char c=path[path.size()-1];
		if(c!='/'&&c!='\\') path+="/";
	}
	DIR *pDir;
	struct dirent *pDirent;
	pDir=opendir(path.c_str());
	if(pDir==NULL){
#ifdef ANDROID
		//ad-hoc workaround
		u8file *f=u8fopen((path+"list.txt").c_str(),"rb");
		if(f){
			u8string s;
			while(u8fgets2(s,f)){
				u8string::size_type lps=s.find_first_of("\r\n");
				if(lps!=u8string::npos) s=s.substr(0,lps);
				if(s.empty()) continue;

				//trim
				lps=s.find_first_not_of(" \t");
				if(lps>0) s=s.substr(lps);
				if(s.empty()) continue;

				lps=s.find_last_not_of(" \t");
				if(lps+1<s.size()) s=s.substr(0,lps+1);

				if(s.size()<2 || s[s.size()-1]!='/') continue;
				s=s.substr(0,s.size()-1);

				if(containsPath){
					v.push_back(path+s);
				}else{
					v.push_back(s);
				}
			}
			u8fclose(f);
		}
#endif
		return v;
	}
	while((pDirent=readdir(pDir))!=NULL){
		if(pDirent->d_name[0]=='.'){
			if(pDirent->d_name[1]==0||
				(pDirent->d_name[1]=='.'&&pDirent->d_name[2]==0)) continue;
		}
		u8string s1=path+pDirent->d_name;
		struct stat S_stat;
		lstat(s1.c_str(),&S_stat);
		if(S_ISDIR(S_stat.st_mode)){
			//Skip hidden folders.
			s1=u8string(pDirent->d_name);
			if(s1.find('.')==0) continue;
			
			//Add result to vector.
			if(containsPath){
				v.push_back(path+pDirent->d_name);
			}else{
				v.push_back(s1);
			}
		}
	}
	closedir(pDir);
	return v;
#endif
}

void setDataDirectory(const char* dir){
	//ad-hoc!
	chdir(dir);
}

void initPaths(){
	if(externalStoragePath.empty()){
#if defined(ANDROID)
		externalStoragePath=SDL_AndroidGetExternalStoragePath();
#elif defined(__IPHONEOS__)
		externalStoragePath="../Documents";
#elif defined(__WIN32__)
		const int size=65536;
		wchar_t *s=new wchar_t[size];
		SHGetSpecialFolderPathW(NULL,s,CSIDL_PERSONAL,1);
		externalStoragePath=toUTF8((const unsigned short*)s)+"/My Games/PuzzleBoy";
		delete[] s;
#else
		const char *env=getenv("HOME");
		if(env==NULL) externalStoragePath="local";
		else externalStoragePath=u8string(env)+"/.PuzzleBoy";
#endif
	}
	if(externalStoragePath.empty()) return;

	//Create subfolders.
	createDirectory(externalStoragePath);
	createDirectory(externalStoragePath+"/levels");

#ifndef ANDROID
	//try to detect data directory (which is the working directory)
	for (int i = 0; i < 3; i++) {
		//try to load a file
		u8file *f = u8fopen("data/gfx/adhoc.bmp", "rb");
		if (f) {
			u8fclose(f);

			//show the working directory
			char buf[1024];
			buf[0] = 0;
			getcwd(buf, sizeof(buf));
			printf("[initPaths] The working directory is set to '%s'\n", buf);

			break;
		}

		//up one level if this file is not found
		chdir("..");
		printf("[initPaths] Warning: Can't find necessary data in the working directory, will try parent directory\n");
	}
#endif
}

bool createDirectory(const u8string& path){
#ifdef __WIN32__
	const int size=65536;
	wchar_t *s0=new wchar_t[size],*s=new wchar_t[size];

	GetCurrentDirectoryW(size,s0);
	PathCombineW(s,s0,(LPCWSTR)toUTF16(path).c_str());

	for(int i=0;i<size;i++){
		if(s[i]=='\0') break;
		else if(s[i]=='/') s[i]='\\';
	}

	bool ret=(SHCreateDirectoryExW(NULL,s,NULL)!=0);

	delete[] s0;
	delete[] s;

	return ret;
#else
	return mkdir(path.c_str(),0777)==0;
#endif
}
