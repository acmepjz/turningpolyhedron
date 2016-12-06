#pragma once

#include "UTF8-16.h"
#include <stdio.h>
#include <vector>

struct u8file;

u8file *u8fopen(const char* filename,const char* mode);
int u8fseek(u8file* file,long offset,int whence);
long u8ftell(u8file* file);
size_t u8fread(void* ptr,size_t size,size_t nmemb,u8file* file);
size_t u8fwrite(const void* ptr,size_t size,size_t nmemb,u8file* file);
int u8fclose(u8file* file);
char* u8fgets(char* buf, int count, u8file* file);

inline int u8fgetc(u8file* file){
	unsigned char c;
	if (u8fread(&c, 1, 1, file) != 1) return EOF;
	return c;
}

inline int u8fputc(int ch, u8file* file){
	return u8fwrite(&ch, 1, 1, file) == 1 ? (int)(unsigned char)ch : EOF;
}

const char* u8fgets2(u8string& s,u8file* file);
size_t u8fputs2(const u8string& s,u8file* file);

void setDataDirectory(const char* dir);

void initPaths();

extern u8string externalStoragePath;

//Copied from Me and My Shadow, licensed under GPLv3 or above

//Method that returns a list of all the files in a given directory.
//path: The path to list the files of.
//extension: The extension the files must have.
//containsPath: Specifies if the return file name should contains path.
//Returns: A vector containing the names of the files.
std::vector<u8string> enumAllFiles(u8string path,const char* extension=NULL,bool containsPath=false);

//Method that returns a list of all the directories in a given directory.
//path: The path to list the directory of.
//containsPath: Specifies if the return file name should contains path.
//Returns: A vector containing the names of the directories.
std::vector<u8string> enumAllDirs(u8string path,bool containsPath=false);

//Method that will create a directory.
//path: The directory to create.
//Returns: True if it succeeds.
bool createDirectory(const u8string& path);
