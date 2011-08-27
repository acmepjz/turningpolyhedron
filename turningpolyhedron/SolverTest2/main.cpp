#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <map>
#include "SimpleSolverGA.h"
#include "ColorZoneSolverGA.h"
#include "GABase.h"
#include "GA.h"
using namespace std;

GABase* FactoryFunction(map<string,string>& obj){
	const string& Type=obj["Type"];
	if(Type=="SimpleSolverGA"){
		SimpleSolverGA::MapSize sz;
		sz.Width=atoi(obj["Width"].c_str());
		sz.Height=atoi(obj["Height"].c_str());
		sz.SizeX=atoi(obj["SizeX"].c_str());
		sz.SizeY=atoi(obj["SizeY"].c_str());
		sz.SizeZ=atoi(obj["SizeZ"].c_str());
		if(sz.SizeX>0&&sz.SizeY>0&&sz.SizeZ>0
			&&sz.SizeX<sz.Width&&sz.SizeX<sz.Height
			&&sz.SizeY<sz.Width&&sz.SizeY<sz.Height
			&&sz.SizeZ<sz.Width&&sz.SizeZ<sz.Height){
			return new SimpleSolverGA(sz);
		}else{
			return NULL;
		}
	}else if(Type=="ColorZoneSolverGA"){
		ColorZoneSolverGA::MapSize sz;
		sz.Width=atoi(obj["Width"].c_str());
		sz.Height=atoi(obj["Height"].c_str());
		sz.SizeX=atoi(obj["SizeX"].c_str());
		sz.SizeY=atoi(obj["SizeY"].c_str());
		sz.SizeZ=atoi(obj["SizeZ"].c_str());
		sz.ColorCount=atoi(obj["ColorCount"].c_str());
		sz.AllowEmpty=atoi(obj["AllowEmpty"].c_str());
		if(sz.SizeX>0&&sz.SizeY>0&&sz.SizeZ>0
			&&sz.SizeX<sz.Width&&sz.SizeX<sz.Height
			&&sz.SizeY<sz.Width&&sz.SizeY<sz.Height
			&&sz.SizeZ<sz.Width&&sz.SizeZ<sz.Height){
			return new ColorZoneSolverGA(sz);
		}else{
			return NULL;
		}
	}
	return NULL;
}

#ifdef SOLVER_LIB

// mersenne twister functions

void __stdcall MTInit(unsigned long s){
	init_genrand(s);
}
void __stdcall MTInitFromString(const char* lps){
	string s;
	if(lps) s=lps;
	int m=(s.size()+15)&(~8);
	s.append("0123456789ABCDEF");
	init_by_array((unsigned long*)s.c_str(),m/sizeof(unsigned long));
}
unsigned long __stdcall MTGenRandInt32(){
	return genrand_int32();
}
long __stdcall MTGenRandInt31(){
	return genrand_int31();
}
double __stdcall MTGenRandReal1(){
	return genrand_real1();
}
double __stdcall MTGenRandReal2(){
	return genrand_real2();
}
double __stdcall MTGenRandReal3(){
	return genrand_real3();
}
double __stdcall MTGenRandRes53(){
	return genrand_res53();
}

//std::map functions

map<string,string>* __stdcall StdMapCreate(){
	return new map<string,string>();
}
void __stdcall StdMapDestroy(map<string,string>* obj){
	delete obj;
}
void __stdcall StdMapAdd(map<string,string>* obj,const char* key,const char* value){
	(*obj)[key]=value;
}
void __stdcall StdMapAddFromString(map<string,string>* obj,const char* s,int delim1,int delim2,short bRemoveSpace){
	int c;
	int idx=0;
	int keys,keye;
	int vals,vale;
	//
	c=s[idx];
	for(;;){
		if(bRemoveSpace){
			for(;c && isspace(c);c=s[++idx]);
		}
		if(c=='\0') break;
		keys=idx;
		for(;c && c!=delim1;c=s[++idx]);
		if(c=='\0') break;
		keye=idx;
		//
		c=s[++idx];
		if(bRemoveSpace){
			for(;c && isspace(c);c=s[++idx]);
		}
		if(c=='\0') break;
		vals=idx;
		for(;c && c!=delim2;c=s[++idx]);
		if(c=='\0'){
			(*obj)[string(s,keys,keye-keys)]=string(s,vals,string::npos);
			break;
		}
		vale=idx;
		(*obj)[string(s,keys,keye-keys)]=string(s,vals,vale-vals);
		//
		c=s[++idx];
	}
}
int __stdcall StdMapQuery(map<string,string>* obj,const char* key,char* value,int len){
	map<string,string>::iterator it=obj->find(key);
	if(it!=obj->end()){
		strncpy(value,it->second.c_str(),len);
		return it->second.size();
	}else{
		value[0]='\0';
		return -1;
	}
}
map<string,string>* __stdcall StdMapCreateFromString(const char* s,int delim1,int delim2,short bRemoveSpace){
	map<string,string> *obj=new map<string,string>();
	StdMapAddFromString(obj,s,delim1,delim2,bRemoveSpace);
	return obj;
}

//GA base object function

GABase* __stdcall GABaseCreate(map<string,string>* objMap){
	return FactoryFunction(*objMap);
}
void __stdcall GABaseDestroy(GABase* obj){
	delete obj;
}
int __stdcall GABaseOutputToString(GABase* obj,char* s,int len,bool OutputSolution){
	stringstream out;
	obj->OutputXML(out,OutputSolution);
	strncpy(s,out.str().c_str(),len);
	return out.str().size();
}
void __stdcall GABaseOutputToFile(GABase* obj,char* fn,bool OutputSolution){
	ofstream out(fn);
	if(!out) return;
	obj->OutputXML(out,OutputSolution);
}

//GA random level generator functions

GA* __stdcall GACreate(){
	return new GA();
}
void __stdcall GADestroy(GA* obj){
	delete obj;
}
bool __stdcall GACreatePool(GA* obj,map<string,string>* objMap,int PoolSize){
	return obj->Create(FactoryFunction,*objMap,PoolSize);
}
void __stdcall GADestroyPool(GA* obj){
	obj->Destroy();
}
bool __stdcall GARun(GA* obj,int GenerationCount,map<string,string>* objMap,GACallbackFunc Callback,void* UserData){
	int RandomFitness=0;
	//
	if(objMap){
		RandomFitness=atoi((*objMap)["RandomFitness"].c_str());
	}
	//
	return obj->Run(GenerationCount,RandomFitness,NULL,Callback,UserData);
}
GABase* __stdcall GAGetPoolItem(GA* obj,int Index){
	return (*obj)(Index);
}
int __stdcall GAGetFitness(GA* obj,int Index){
	return obj->Fitness(Index);
}

#else

int main(){
	string s;
	cout<<"Random seed? ";
	cin>>s;
	int m=(s.size()+15)&(~8);
	s.append("0123456789ABCDEF");
	init_by_array((unsigned long*)s.c_str(),m/sizeof(unsigned long));
	//
	map<string,string> sz;
	cout<<"Width,Height,SizeX,SizeY,SizeZ? ";
	//sz["Type"]="SimpleSolverGA";
	sz["Type"]="ColorZoneSolverGA";
	cin>>sz["Width"]>>sz["Height"]>>sz["SizeX"]>>sz["SizeY"]>>sz["SizeZ"];
	cout<<"ColorCount,AllowEmpty? ";
	cin>>sz["ColorCount"]>>sz["AllowEmpty"];
	//
	GA test;
	if(!test.Create(FactoryFunction,sz,100)){
		cout<<"ERROR: Can't create object"<<endl;
		return -1;
	}
	test.Run(100,5,&cout,NULL,NULL);
	//
	ofstream f("out.xml");
	test(0)->OutputXML(f,true);
	//
	return 0;
}

#endif