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
#include "MultilevelSolverGA.h"
#include "GABase.h"
#include "GA.h"
using namespace std;

#ifndef WIN32
#define __stdcall
#endif

static const char *SimpleSolverGATypes[]={
	"SimpleSolverGA",
	"Width","15",
	"Height","10",
	"SizeX","1",
	"SizeY","1",
	"SizeZ","2",
	"InitialDensity","0.7",
	"MutationMaxCount","256",
	"MutationDecay","0.5",
	"FailedMutationDecay","0.8",
	"FailedMutationExtra","0",
	NULL
};
static const char *ColorZoneSolverGATypes[]={
	"ColorZoneSolverGA",
	"Width","8",
	"Height","8",
	"SizeX","1",
	"SizeY","1",
	"SizeZ","2",
	"ColorCount","2",
	"AllowEmpty","0",
	NULL
};
static const char *MultilevelSolverGATypes[]={
	"MultilevelSolverGA",
	"Width","8",
	"Height","8",
	"PolyhedronCount","2",
	"InitialDensity","0.7",
	"MutationMaxCount","256",
	"MutationDecay","0.5",
	"FailedMutationDecay","0.8",
	"FailedMutationExtra","0",
	NULL
};

static const char **RandomMapTypes[]={
	SimpleSolverGATypes,
	ColorZoneSolverGATypes,
	MultilevelSolverGATypes,
	NULL
};

static const char *GATypes[]={
	"RandomFitness","5",
	"FirstReproduce","1.0",
	"ReproduceDecay","1.0",
	"ReproduceCountDecay","0.5",
	"MutationProbability","0.5",
	"FailedPool","0",
	NULL
};

// -------- internal functions --------

static GABase* GAFactoryFunction(map<string,string>& obj){
	const string& Type=obj["Type"];
	if(Type=="SimpleSolverGA"){
		SimpleSolverGA::MapSize sz;
		sz.Width=atoi(obj["Width"].c_str());
		sz.Height=atoi(obj["Height"].c_str());
		sz.SizeX=atoi(obj["SizeX"].c_str());
		sz.SizeY=atoi(obj["SizeY"].c_str());
		sz.SizeZ=atoi(obj["SizeZ"].c_str());
		//
		sz.InitialDensity=atof(obj["InitialDensity"].c_str());
		if(sz.InitialDensity<0.0) sz.InitialDensity=0.0;
		else if(sz.InitialDensity>1.0) sz.InitialDensity=1.0;
		//
		sz.MutationMaxCount=atoi(obj["MutationMaxCount"].c_str());
		sz.MutationDecay=atof(obj["MutationDecay"].c_str());
		sz.FailedMutationDecay=atof(obj["FailedMutationDecay"].c_str());
		sz.FailedMutationExtra=atoi(obj["FailedMutationExtra"].c_str());
		//
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
	}else if(Type=="MultilevelSolverGA"){
		MultilevelSolverGA<7>::MapSize sz;
		sz.Width=atoi(obj["Width"].c_str());
		sz.Height=atoi(obj["Height"].c_str());
		sz.PolyhedronCount=atoi(obj["PolyhedronCount"].c_str());
		//
		sz.InitialDensity=atof(obj["InitialDensity"].c_str());
		if(sz.InitialDensity<0.0) sz.InitialDensity=0.0;
		else if(sz.InitialDensity>1.0) sz.InitialDensity=1.0;
		//
		sz.MutationMaxCount=atoi(obj["MutationMaxCount"].c_str());
		sz.MutationDecay=atof(obj["MutationDecay"].c_str());
		sz.FailedMutationDecay=atof(obj["FailedMutationDecay"].c_str());
		sz.FailedMutationExtra=atoi(obj["FailedMutationExtra"].c_str());
		//
		if(sz.Width>0&&sz.Height>0&&sz.PolyhedronCount>1
			&&sz.PolyhedronCount<=7){
			return new MultilevelSolverGA<7>(sz);
		}else{
			return NULL;
		}
	}
	return NULL;
}

// -------- library functions --------

// mersenne twister functions

void __stdcall MTInit(unsigned long s){
	init_genrand(s);
}
void __stdcall MTInitFromString(const char* lps){
	string s;
	if(lps) s=lps;
	int m=(s.size()+15)&(~7);
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
	if(!key) key="";
	if(!value) value="";
	(*obj)[key]=value;
}
void __stdcall StdMapAddFromString(map<string,string>* obj,const char* s,int delim1,int delim2,short bRemoveSpace){
	int c;
	int idx=0;
	int keys,keye;
	int vals,vale;
	//
	if(!s) return;
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
	if(!key) key="";
	map<string,string>::iterator it=obj->find(key);
	if(it!=obj->end()){
		if(value) strncpy(value,it->second.c_str(),len);
		return it->second.size();
	}else{
		if(value) value[0]='\0';
		return -1;
	}
}
map<string,string>* __stdcall StdMapCreateFromString(const char* s,int delim1,int delim2,short bRemoveSpace){
	map<string,string> *obj=new map<string,string>();
	if(s) StdMapAddFromString(obj,s,delim1,delim2,bRemoveSpace);
	return obj;
}

//GA base object function

GABase* __stdcall GABaseCreate(map<string,string>* objMap){
	return GAFactoryFunction(*objMap);
}
void __stdcall GABaseDestroy(GABase* obj){
	delete obj;
}
int __stdcall GABaseOutputToString(GABase* obj,char* s,int len,bool OutputSolution){
	stringstream out;
	obj->OutputXML(out,OutputSolution);
	if(s) strncpy(s,out.str().c_str(),len);
	return out.str().size();
}
void __stdcall GABaseOutputToFile(GABase* obj,char* fn,bool OutputSolution){
	if(!fn) return;
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
	if(objMap) return obj->Create(GAFactoryFunction,*objMap,PoolSize);
	else return false;
}
void __stdcall GADestroyPool(GA* obj){
	obj->Destroy();
}
bool __stdcall GARun(GA* obj,int GenerationCount,map<string,string>* objMap,GACallbackFunc Callback,void* UserData){
	//default value
	GA::Settings t={5,1,1.0,1.0,0.5,0.5};
	//
	if(objMap){
		map<string,string>::iterator it;
		it=objMap->find("RandomFitness");
		if(it!=objMap->end()) t.RandomFitness=atoi(it->second.c_str());
		it=objMap->find("FailedPool");
		if(it!=objMap->end()) t.SeparatePool=atoi(it->second.c_str());
		it=objMap->find("FirstReproduce");
		if(it!=objMap->end()) t.FirstReproduce=atof(it->second.c_str());
		it=objMap->find("ReproduceDecay");
		if(it!=objMap->end()) t.ReproduceDecay=atof(it->second.c_str());
		it=objMap->find("ReproduceCountDecay");
		if(it!=objMap->end()) t.ReproduceCountDecay=atof(it->second.c_str());
		it=objMap->find("MutationProbability");
		if(it!=objMap->end()) t.MutationProbability=atof(it->second.c_str());
	}
	//
#ifdef SOLVER_LIB
	return obj->Run(GenerationCount,t,NULL,Callback,UserData);
#else
	return obj->Run(GenerationCount,t,&cout,Callback,UserData);
#endif
}
GABase* __stdcall GAGetPoolItem(GA* obj,int Index){
	return (*obj)(Index);
}
int __stdcall GAGetFitness(GA* obj,int Index){
	return obj->Fitness(Index);
}

//settings function

int __stdcall GetAvaliableRandomMapGenerators(char* out,int SizePerString,int MaxCount){
	int i;
	for(i=0;RandomMapTypes[i]!=NULL;i++){
		if(out && i<MaxCount){
			strncpy(out,RandomMapTypes[i][0],SizePerString);
			out+=SizePerString;
		}
	}
	return i;
}

int __stdcall GetAvaliableRandomMapOptions(const char* sType,char* out,int SizePerString,int MaxCount){
	int i,j;
	for(i=0;RandomMapTypes[i]!=NULL;i++){
		if(!strcmp(sType,RandomMapTypes[i][0])){
			MaxCount*=2;
			for(j=1;RandomMapTypes[i][j]!=NULL;j++){
				if(out && j-1<MaxCount){
					strncpy(out,RandomMapTypes[i][j],SizePerString);
					out+=SizePerString;
				}
			}
			return (j-1)/2;
		}
	}
	return 0;
}

int __stdcall GetAvaliableGAOptions(char* out,int SizePerString,int MaxCount){
	int i;
	MaxCount*=2;
	for(i=0;GATypes[i]!=NULL;i++){
		if(out && i<MaxCount){
			strncpy(out,GATypes[i],SizePerString);
			out+=SizePerString;
		}
	}
	return i/2;
}

// -------- main functions --------

#ifndef SOLVER_LIB

int main(){
	////////random level test
	string s;
	//get seed
	cout<<"Random seed? ";
	cin>>s;
	int m=(s.size()+15)&(~7),i;
	s.append("0123456789ABCDEF");
	init_by_array((unsigned long*)s.c_str(),m/sizeof(unsigned long));
	//get GA settings
	int PoolSize,GenerationCount;
	map<string,string> sz;
	cout<<"PoolSize? [200] ";
	cin>>PoolSize;
	cout<<"GenerationCount? [30] ";
	cin>>GenerationCount;
	//
	for(i=0;GATypes[i]!=NULL;i+=2){
		cout<<GATypes[i]<<"? ["<<GATypes[i+1]<<"] ";
		cin>>sz[GATypes[i]];
	}
	//get type
	cout<<"Avaliable random map generators:"<<endl;
	for(m=0;RandomMapTypes[m]!=NULL;m++){
		cout<<m<<"="<<RandomMapTypes[m][0]<<endl;
	}
	cout<<"Type? [0-"<<(m-1)<<"] ";
	cin>>i;
	if(i<0||i>=m){
		cout<<"ERROR: Invalid type"<<endl;
		return -1;
	}
	m=i;
	//
	sz["Type"]=RandomMapTypes[m][0];
	//
	for(i=1;RandomMapTypes[m][i]!=NULL;i+=2){
		cout<<RandomMapTypes[m][i]<<"? ["<<RandomMapTypes[m][i+1]<<"] ";
		cin>>sz[RandomMapTypes[m][i]];
	}
	//
	GA test;
	if(!test.Create(GAFactoryFunction,sz,PoolSize)){
		cout<<"ERROR: Can't create object"<<endl;
		return -1;
	}
	//
	GARun(&test,GenerationCount,&sz,NULL,NULL);
	//output test
	ofstream f("out.xml");
	test(0)->OutputXML(f,true);
	//*/
	/*////////solver test
	MultilevelSolver<7> objSolver;
	int i,j,w,h,m;
	cout<<"Width Height? ";
	cin>>w>>h;
	objSolver.SetSize(w,h);
	cout<<"Map Data:\n";
	for(j=0;j<h;j++){
		for(i=0;i<w;i++){
			int c;
			cin>>c;
			objSolver(i,j)=c;
		}
	}
	cout<<"Polyhedron Count? ";
	cin>>m;
	objSolver.SetPolyhedronCount(m);
	for(i=0;i<m;i++){
		int c1,c2,c3,c4,c5,c6;
		cout<<"Polyhedron["<<i<<"] x y z sx sy sz? ";
		cin>>c1>>c2>>c3>>c4>>c5>>c6;
		objSolver.SetPolyhedron(i,c1,c2,c3,c4,c5,c6);
	}
	//
	{
		int c1,c2,c3,c4,c5;
		cout<<"TargetIndex x y sx sy? ";
		cin>>c1>>c2>>c3>>c4>>c5;
		objSolver.TargetIndex=c1;
		objSolver.TargetX=c2;
		objSolver.TargetY=c3;
		objSolver.TargetSizeX=c4;
		objSolver.TargetSizeY=c5;
	}
	//output test
	ofstream f("out.xml");
	objSolver.OutputXML(f,true);
	//over
	cout<<"Done."<<endl;
	//*/
	return 0;
}

#endif