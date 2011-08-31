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
		int MutationMaxCount,FailedMutationExtra;
		double InitialDensity,MutationDecay,FailedMutationDecay;
	};
protected:
	int MutationMaxCount,FailedMutationExtra;
	double InitialDensity,MutationDecay,FailedMutationDecay;
	char *m_bMovedArea;
	char *m_bSolutionMovedArea;
	int LastFitness;
public:
	SimpleSolverGA(const MapSize& obj):SimpleSolver(obj.Width,obj.Height){
		SizeX=obj.SizeX;
		SizeY=obj.SizeY;
		SizeZ=obj.SizeZ;
		MutationMaxCount=obj.MutationMaxCount;
		InitialDensity=obj.InitialDensity;
		MutationDecay=obj.MutationDecay;
		FailedMutationDecay=obj.FailedMutationDecay;
		FailedMutationExtra=obj.FailedMutationExtra;
		//
		m_bMovedArea=(char*)malloc(1<<(m_nWidthShift+m_nHeightShift));
		m_bSolutionMovedArea=(char*)malloc(1<<(m_nWidthShift+m_nHeightShift));
		//
		LastFitness=0;
	}
	~SimpleSolverGA(){
		free(m_bMovedArea);
		free(m_bSolutionMovedArea);
	}
	void CreateRandom(){
		int i,j;
		i=m_nWidth-SizeX+1;
		j=m_nHeight-SizeY+1;
		StartX=int(genrand_real2()*(i/*>>2*/));
		StartY=int(genrand_real2()*(j/*>>2*/));
		//
		int sz[3]={SizeX,SizeY,SizeZ};
		i=int(genrand_real2()*3);
		EndSizeX=sz[i];
		sz[i]=sz[2];
		i=int(genrand_real2()*2);
		EndSizeY=sz[i];
		//
		i=m_nWidth-EndSizeX+1;
		j=m_nHeight-EndSizeY+1;
		EndX=/*i-(i>>2)+*/int(genrand_real2()*(i/*>>2*/));
		EndY=/*j-(j>>2)+*/int(genrand_real2()*(j/*>>2*/));
		//
		memset(m_bMapData,0,1<<(m_nWidthShift+m_nHeightShift));
		for(j=0;j<m_nHeight;j++){
			for(i=0;i<m_nWidth;i++){
				int v;
				if((i>=StartX&&i<StartX+SizeX&&j>=StartY&&j<StartY+SizeY)
					||(i>=EndX&&i<EndX+EndSizeX&&j>=EndY&&j<EndY+EndSizeY)) v=1;
				else v=(genrand_real2()<InitialDensity)?1:0;
				m_bMapData[(j<<m_nWidthShift)+i]=v;
			}
		}
	}
	int CalcFitness(){
		int n=0,m=0;
		memset(m_bMovedArea,0,1<<(m_nWidthShift+m_nHeightShift));
		memset(m_bSolutionMovedArea,0,1<<(m_nWidthShift+m_nHeightShift));
		if(!SimpleSolver::Solve(NULL,&n,m_bMovedArea,m_bSolutionMovedArea,&m)){
			n=0xC0000000+m;
		}
		LastFitness=n;
		return n;
	}
	void CopyFrom(const GABase* src){
		const SimpleSolverGA& obj=*(reinterpret_cast<const SimpleSolverGA*>(src));
		memcpy(m_bMapData,obj.m_bMapData,1<<(m_nWidthShift+m_nHeightShift));
		memcpy(m_bMovedArea,obj.m_bMovedArea,1<<(m_nWidthShift+m_nHeightShift));
		memcpy(m_bSolutionMovedArea,obj.m_bSolutionMovedArea,1<<(m_nWidthShift+m_nHeightShift));
		StartX=obj.StartX;
		StartY=obj.StartY;
		EndX=obj.EndX;
		EndY=obj.EndY;
		SizeX=obj.SizeX;
		SizeY=obj.SizeY;
		SizeZ=obj.SizeZ;
		EndSizeX=obj.EndSizeX;
		EndSizeY=obj.EndSizeY;
		LastFitness=obj.LastFitness;
	}
	void RandomMutation(){
		if(LastFitness<0){
			for(int t=0;t<MutationMaxCount;t++){
				int x=int(genrand_real2()*m_nWidth);
				int y=int(genrand_real2()*m_nHeight);
				if(x>=StartX&&x<StartX+SizeX&&y>=StartY&&y<StartY+SizeY) continue;
				if(x>=EndX&&x<EndX+EndSizeX&&y>=EndY&&y<EndY+EndSizeY) continue;
				//
				if(m_bMovedArea[(y<<m_nWidthShift)+x]) continue;
				if(x<=0 || !m_bMovedArea[(y<<m_nWidthShift)+x-1]){
					if(x>=m_nWidth-1 || !m_bMovedArea[(y<<m_nWidthShift)+x+1]){
						if(y<=0 || !m_bMovedArea[((y-1)<<m_nWidthShift)+x]){
							if(y>=m_nHeight-1 || !m_bMovedArea[((y+1)<<m_nWidthShift)+x]) continue;
						}
					}
				}
				//
				m_bMapData[(y<<m_nWidthShift)+x]=1;
				//
				if(genrand_real2()>FailedMutationDecay) break;
			}
			for(int t=0;t<FailedMutationExtra;t++){
				int x=int(genrand_real2()*m_nWidth);
				int y=int(genrand_real2()*m_nHeight);
				m_bMapData[(y<<m_nWidthShift)+x]=1;
			}
		}else{
			for(int t=0;t<MutationMaxCount;t++){
				int x=int(genrand_real2()*m_nWidth);
				int y=int(genrand_real2()*m_nHeight);
				if(x>=StartX&&x<StartX+SizeX&&y>=StartY&&y<StartY+SizeY) continue;
				if(x>=EndX&&x<EndX+EndSizeX&&y>=EndY&&y<EndY+EndSizeY) continue;
				//
				if(!m_bSolutionMovedArea[(y<<m_nWidthShift)+x]) continue;
				//
				m_bMapData[(y<<m_nWidthShift)+x]=0;
				///*
				switch(int(genrand_real2()*4)){
				case 0:
					if(x>0) m_bMapData[(y<<m_nWidthShift)+x-1]=1;
					break;
				case 1:
					if(x<m_nWidth-1) m_bMapData[(y<<m_nWidthShift)+x+1]=1;
					break;
				case 2:
					if(y>0) m_bMapData[((y-1)<<m_nWidthShift)+x]=1;
					break;
				case 3:
					if(y<m_nHeight-1) m_bMapData[((y+1)<<m_nWidthShift)+x]=1;
					break;
				}
				//*/
				if(genrand_real2()>MutationDecay) break;
			}
		}
	}
	void OutputXML(std::ostream& out,bool OutputSolution){
		SimpleSolver::OutputXML(out,OutputSolution);
	}
};

#endif