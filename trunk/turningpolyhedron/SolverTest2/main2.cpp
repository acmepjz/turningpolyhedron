#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <map>
#include "SimpleSolver.h"
#include "ColorZoneSolver.h"
#include "MultilevelSolver.h"
using namespace std;

#ifndef WIN32
#define __stdcall
#endif

class SolverBase{
public:
	virtual bool SetData(map<string,string>& obj)=0;
	virtual bool Solve(std::ostream* out,int* step,int *NodesUsed)=0;
	virtual void OutputXML(std::ostream& out,bool OutputSolution)=0;
	virtual ~SolverBase(){}
};

class SimpleSolver_1:public SimpleSolver,public SolverBase{
public:
	SimpleSolver_1(int w,int h):SimpleSolver(w,h){}
	bool SetData(map<string,string>& obj){
		StartX=atoi(obj["StartX"].c_str());
		StartY=atoi(obj["StartY"].c_str());
		EndX=atoi(obj["EndX"].c_str());
		EndY=atoi(obj["EndY"].c_str());
		SizeX=atoi(obj["SizeX"].c_str());
		SizeY=atoi(obj["SizeY"].c_str());
		SizeZ=atoi(obj["SizeZ"].c_str());
		EndSizeX=atoi(obj["EndSizeX"].c_str());
		EndSizeY=atoi(obj["EndSizeY"].c_str());
		//
		stringstream in(obj["MapData"]);
		for(int j=0;j<m_nHeight;j++){
			for(int i=0;i<m_nWidth;i++){
				int n;
				in>>n;
				m_bMapData[(j<<m_nWidthShift)+i]=n;
			}
		}
		return true;
	}
	bool Solve(std::ostream* out,int* step,int *NodesUsed){
		return SimpleSolver::Solve(out,step,NULL,NULL,NodesUsed);
	}
	void OutputXML(std::ostream& out,bool OutputSolution){
		return SimpleSolver::OutputXML(out,OutputSolution);
	}
};

class CZSolver_1:public ColorZoneSolver,public SolverBase{
public:
	CZSolver_1(int w,int h):ColorZoneSolver(w,h){}
	bool SetData(map<string,string>& obj){
		StartX=atoi(obj["StartX"].c_str());
		StartY=atoi(obj["StartY"].c_str());
		EndX=atoi(obj["EndX"].c_str());
		EndY=atoi(obj["EndY"].c_str());
		SizeX=atoi(obj["SizeX"].c_str());
		SizeY=atoi(obj["SizeY"].c_str());
		SizeZ=atoi(obj["SizeZ"].c_str());
		EndSizeX=atoi(obj["EndSizeX"].c_str());
		EndSizeY=atoi(obj["EndSizeY"].c_str());
		//
		stringstream in(obj["MapData"]);
		for(int j=0;j<m_nHeight;j++){
			for(int i=0;i<m_nWidth;i++){
				int n;
				in>>n;
				m_bMapData[(j<<m_nWidthShift)+i]=n;
			}
		}
		return true;
	}
	bool Solve(std::ostream* out,int* step,int *NodesUsed){
		return ColorZoneSolver::Solve(out,step,NULL,NULL,NodesUsed);
	}
	void OutputXML(std::ostream& out,bool OutputSolution){
		return ColorZoneSolver::OutputXML(out,OutputSolution);
	}
};

template <int N_Max>
class MultilevelSolver_1:public MultilevelSolver<N_Max>,public SolverBase{
public:
	MultilevelSolver_1(int w,int h){
		SetSize(w,h);
	}
	bool SetData(map<string,string>& obj){
		SetPolyhedronCount(atoi(obj["PolyhedronCount"].c_str()));
		//
		char s[64];
		for(int i=0;i<m_nPolyhedronCount;i++){
			int x,y,z,sx,sy,sz;
			sprintf(s,"Polyhedron%dStartX",i);
			x=atoi(obj[s].c_str());
			sprintf(s,"Polyhedron%dStartY",i);
			y=atoi(obj[s].c_str());
			sprintf(s,"Polyhedron%dStartZ",i);
			z=atoi(obj[s].c_str());
			sprintf(s,"Polyhedron%dSizeX",i);
			sx=atoi(obj[s].c_str());
			sprintf(s,"Polyhedron%dSizeY",i);
			sy=atoi(obj[s].c_str());
			sprintf(s,"Polyhedron%dSizeZ",i);
			sz=atoi(obj[s].c_str());
			SetPolyhedron(i,x,y,z,sx,sy,sz);
		}
		//
		TargetIndex=atoi(obj["TargetIndex"].c_str());
		TargetX=atoi(obj["TargetX"].c_str());
		TargetY=atoi(obj["TargetY"].c_str());
		TargetSizeX=atoi(obj["TargetSizeX"].c_str());
		TargetSizeY=atoi(obj["TargetSizeY"].c_str());
		//
		stringstream in(obj["MapData"]);
		for(int j=0;j<m_nHeight;j++){
			for(int i=0;i<m_nWidth;i++){
				int n;
				in>>n;
				m_bMapData[(j<<m_nWidthShift)+i]=n;
			}
		}
		return true;
	}
	bool Solve(std::ostream* out,int* step,int *NodesUsed){
		return MultilevelSolver::Solve(out,step,NULL,NULL,NodesUsed);
	}
	void OutputXML(std::ostream& out,bool OutputSolution){
		return MultilevelSolver::OutputXML(out,OutputSolution);
	}
};

struct typeSolverType{
	const char* sName;
	SolverBase* (*lpFunc)(map<string,string>& obj);
};

static SolverBase* SimpleSolverFactoryFunction(map<string,string>& obj){
	int w,h;
	w=atoi(obj["Width"].c_str());
	h=atoi(obj["Height"].c_str());
	if(w>0 && h>0) return new SimpleSolver_1(w,h);
	return NULL;
}

static SolverBase* ColorZoneSolverFactoryFunction(map<string,string>& obj){
	int w,h;
	w=atoi(obj["Width"].c_str());
	h=atoi(obj["Height"].c_str());
	if(w>0 && h>0) return new CZSolver_1(w,h);
	return NULL;
}

template <int N_Max>
static SolverBase* MultilevelSolverFactoryFunction(map<string,string>& obj){
	int w,h;
	w=atoi(obj["Width"].c_str());
	h=atoi(obj["Height"].c_str());
	if(w>0 && h>0) return new MultilevelSolver_1<N_Max>(w,h);
	return NULL;
}

static const typeSolverType SolverTypes[]={
	{"SimpleSolver",SimpleSolverFactoryFunction},
	{"ColorZoneSolver",ColorZoneSolverFactoryFunction},
	{"MultilevelSolver(MaxPolyhedron=7)",MultilevelSolverFactoryFunction<7>},
	{"MultilevelSolver(MaxPolyhedron=15)",MultilevelSolverFactoryFunction<15>},
	{NULL,NULL}
};

static SolverBase* SolverFactoryFunction(map<string,string>& obj){
	string& s=obj["Type"];
	for(int i=0;SolverTypes[i].sName!=NULL;i++){
		if(s==SolverTypes[i].sName){
			SolverBase* ret=SolverTypes[i].lpFunc(obj);
			if(ret && !ret->SetData(obj)){
				delete ret;
				ret=NULL;
			}
			return ret;
		}
	}
	return NULL;
}

// -------- export functions --------

int __stdcall GetAvaliableSolvers(char* out,int SizePerString,int MaxCount){
	int i;
	for(i=0;SolverTypes[i].sName!=NULL;i++){
		if(out && i<MaxCount){
			strncpy(out,SolverTypes[i].sName,SizePerString);
			out+=SizePerString;
		}
	}
	return i;
}

SolverBase* __stdcall SolverCreate(map<string,string>* obj){
	if(obj) return SolverFactoryFunction(*obj);
	else return NULL;
}

void __stdcall SolverDestroy(SolverBase* obj){
	delete obj;
}

bool __stdcall SolverSetData(SolverBase* obj,map<string,string>* objMap){
	if(!obj) return false;
	else if(objMap) return obj->SetData(*objMap);
	else{
		map<string,string> tmp;
		return obj->SetData(tmp);
	}
}

bool __stdcall SolverSolve(SolverBase* obj,char* s,int* len,int* step,int *NodesUsed){
	if(len){
		stringstream out;
		bool ret=obj->Solve(&out,step,NodesUsed);
		if(s) strncpy(s,out.str().c_str(),*len);
		*len=out.str().size();
		return ret;
	}else{
		return obj->Solve(NULL,step,NodesUsed);
	}
}

int __stdcall SolverOutputToString(SolverBase* obj,char* s,int len,bool OutputSolution){
	stringstream out;
	obj->OutputXML(out,OutputSolution);
	if(s) strncpy(s,out.str().c_str(),len);
	return out.str().size();
}

void __stdcall SolverOutputToFile(SolverBase* obj,char* fn,bool OutputSolution){
	if(!fn) return;
	ofstream out(fn);
	if(!out) return;
	obj->OutputXML(out,OutputSolution);
}
