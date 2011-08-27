#ifndef __SimpleSolverGA__
#define __SimpleSolverGA__

#include <iostream>
#include "SimpleSolver.h"
#include "GABase.h"
#include "mt19937.h"

class SimpleSolverGA:public SimpleSolver,public GABase{
public:
	struct MapSize{
		int Width,Height,SizeX,SizeY,SizeZ;
	};
public:
	SimpleSolverGA(const MapSize& obj):SimpleSolver(obj.Width,obj.Height){
		SizeX=obj.SizeX;
		SizeY=obj.SizeY;
		SizeZ=obj.SizeZ;
	}
	void CreateRandom(){
		int i,j;
		StartX=int(genrand_real2()*(m_nWidth-SizeX+1));
		StartY=int(genrand_real2()*(m_nHeight-SizeY+1));
		EndX=int(genrand_real2()*(m_nWidth-SizeX+1));
		EndY=int(genrand_real2()*(m_nHeight-SizeY+1));
		int sz[3]={SizeX,SizeY,SizeZ};
		i=int(genrand_real2()*3);
		EndSizeX=sz[i];
		sz[i]=sz[2];
		i=int(genrand_real2()*2);
		EndSizeY=sz[i];
		//
		memset(m_bMapData,0,1<<(m_nWidthShift+m_nHeightShift));
		for(j=0;j<m_nHeight;j++){
			for(i=0;i<m_nWidth;i++){
				m_bMapData[(j<<m_nWidthShift)+i]=1;
			}
		}
	}
	int CalcFitness(){
		int n=0;
		if(SimpleSolver::Solve(NULL,&n)){
			return n;
		}else{
			return -10000;
		}
	}
	void CopyFrom(const GABase* src){
		const SimpleSolverGA& obj=*(reinterpret_cast<const SimpleSolverGA*>(src));
		memcpy(m_bMapData,obj.m_bMapData,1<<(m_nWidthShift+m_nHeightShift));
		StartX=obj.StartX;
		StartY=obj.StartY;
		EndX=obj.EndX;
		EndY=obj.EndY;
		SizeX=obj.SizeX;
		SizeY=obj.SizeY;
		SizeZ=obj.SizeZ;
		EndSizeX=obj.EndSizeX;
		EndSizeY=obj.EndSizeY;
	}
	void RandomMutation(){
		for(int t=0;t<8;t++){
			int x=int(genrand_real2()*m_nWidth);
			int y=int(genrand_real2()*m_nHeight);
			if(x>=StartX&&x<StartX+SizeX&&y>=StartY&&y<StartY+SizeY) continue;
			if(x>=EndX&&x<EndX+EndSizeX&&y>=EndY&&y<EndY+EndSizeY) continue;
			m_bMapData[(y<<m_nWidthShift)+x]^=1;
			break;
		}
	}
	void OutputXML(std::ostream& out,bool OutputSolution){
		SimpleSolver::OutputXML(out,OutputSolution);
	}
};

#endif