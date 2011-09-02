#ifndef __MultilevelSolverGA__
#define __MultilevelSolverGA__

#include <iostream>
#include <map>
#include "MultilevelSolver.h"
#include "GABase.h"
#include "mt19937.h"

//TEST ONLY

template <int N_Max>
class MultilevelSolverGA:public MultilevelSolver<N_Max>,public GABase{
public:
	struct MapSize{
		int Width,Height,PolyhedronCount;
		int MutationMaxCount,FailedMutationExtra;
		double InitialDensity,MutationDecay,FailedMutationDecay;
	};
protected:
	int MutationMaxCount,FailedMutationExtra;
	double InitialDensity,MutationDecay,FailedMutationDecay;
	int LastFitness;
public:
	MultilevelSolverGA(const MapSize& obj){
		SetSize(obj.Width,obj.Height);
		m_nPolyhedronCount=obj.PolyhedronCount;
		MutationMaxCount=obj.MutationMaxCount;
		InitialDensity=obj.InitialDensity;
		MutationDecay=obj.MutationDecay;
		FailedMutationDecay=obj.FailedMutationDecay;
		FailedMutationExtra=obj.FailedMutationExtra;
		//
		LastFitness=0;
	}
	~MultilevelSolverGA(){
	}
	void CreateRandom(){
		int i,j;
		//init default map
		memset(m_bMapData,-1,1<<(m_nWidthShift+m_nHeightShift));
		//init pohyhedron (fixed size test)
		for(i=0;i<m_nPolyhedronCount;i++){
			m_tPolyhedron[i].sx=1;
			m_tPolyhedron[i].sy=1;
			m_tPolyhedron[i].sz=2;
			m_tPolyhedron[i].TotalSize=m_tPolyhedron[i].sx+m_tPolyhedron[i].sy+m_tPolyhedron[i].sz;
			m_tPolyhedron[i].z=i;
			for(;;){
				int x=int(genrand_real2()*(m_nWidth-m_tPolyhedron[i].sx+1));
				int y=int(genrand_real2()*(m_nHeight-m_tPolyhedron[i].sy+1));
				bool b=true;
				for(j=0;j<i;j++){
					if(x>m_tPolyhedron[j].x-m_tPolyhedron[j].sx
						&& y>m_tPolyhedron[j].y-m_tPolyhedron[j].sy
						&& x<m_tPolyhedron[j].x+m_tPolyhedron[i].sx
						&& y<m_tPolyhedron[j].y+m_tPolyhedron[i].sy)
					{
						b=false;
						break;
					}
				}
				if(b){
					m_tPolyhedron[i].x=x;
					m_tPolyhedron[i].y=y;
					for(int jj=y;jj<y+m_tPolyhedron[i].sy;jj++){
						for(int ii=x;ii<x+m_tPolyhedron[i].sx;ii++){
							m_bMapData[(jj<<m_nWidthShift)+ii]=i;
						}
					}
					break;
				}
			}
		}
		//set end point (fixed size test)
		TargetIndex=m_nPolyhedronCount-1;
		TargetSizeX=1;
		TargetSizeY=1;
		TargetX=int(genrand_real2()*(m_nWidth-TargetSizeX+1));
		TargetY=int(genrand_real2()*(m_nHeight-TargetSizeY+1));
		//map
		for(j=0;j<m_nHeight;j++){
			for(i=0;i<m_nWidth;i++){
				if(m_bMapData[(j<<m_nWidthShift)+i]<0){
					int v=(genrand_real2()<InitialDensity)?0:1; //TEST ONLY
					m_bMapData[(j<<m_nWidthShift)+i]=v;
				}
			}
		}
	}
	int CalcFitness(){
		int n=0,m=0;
		if(!MultilevelSolver::Solve(NULL,&n,NULL,NULL,&m)){
			n=0xC0000000+m;
		}
		LastFitness=n;
		return n;
	}
	void CopyFrom(const GABase* src){
		const MultilevelSolverGA<N_Max>& obj=*(reinterpret_cast<const MultilevelSolverGA<N_Max>*>(src));
		memcpy(m_bMapData,obj.m_bMapData,1<<(m_nWidthShift+m_nHeightShift));
		memcpy(m_tPolyhedron,obj.m_tPolyhedron,sizeof(m_tPolyhedron));
		TargetIndex=obj.TargetIndex;
		TargetX=obj.TargetX;
		TargetY=obj.TargetY;
		TargetSizeX=obj.TargetSizeX;
		TargetSizeY=obj.TargetSizeY;
		LastFitness=obj.LastFitness;
	}
	//TEST ONLY
	void RandomMutation(){
		return;
		for(int t=0;t<MutationMaxCount;t++){
			int x=int(genrand_real2()*m_nWidth);
			int y=int(genrand_real2()*m_nHeight);
			bool b=true;
			//
			for(int i=0;i<m_nPolyhedronCount;i++){
				if(x>=m_tPolyhedron[i].x && y>=m_tPolyhedron[i].y
					&& x<m_tPolyhedron[i].x+m_tPolyhedron[i].sx
					&& y<m_tPolyhedron[i].y+m_tPolyhedron[i].sy)
				{
					b=false;
					break;
				}
			}
			if(b) continue;
			//
			int v=m_bMapData[(y<<m_nWidthShift)+x];
			if(v<=0) v++;
			else if(v>=m_nPolyhedronCount-1) v--;
			else if(genrand_int32()<0x80000000UL) v++;
			else v--;
			m_bMapData[(y<<m_nWidthShift)+x]=v;
			if(genrand_real2()>MutationDecay) break;
		}
	}
	void OutputXML(std::ostream& out,bool OutputSolution){
		MultilevelSolver::OutputXML(out,OutputSolution);
	}
};

#endif