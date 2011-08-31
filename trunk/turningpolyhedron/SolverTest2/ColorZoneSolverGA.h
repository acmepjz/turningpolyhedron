#ifndef __ColorZoneSolverGA__
#define __ColorZoneSolverGA__

#include "ColorZoneSolver.h"
#include "GABase.h"
#include "mt19937.h"

class ColorZoneSolverGA:public ColorZoneSolver,public GABase{
protected:
	int ColorCount,AllowEmpty;
public:
	struct MapSize{
		int Width,Height,SizeX,SizeY,SizeZ,ColorCount,AllowEmpty;
	};
public:
	ColorZoneSolverGA(const MapSize& obj):ColorZoneSolver(obj.Width,obj.Height){
		SizeX=obj.SizeX;
		SizeY=obj.SizeY;
		SizeZ=obj.SizeZ;
		ColorCount=obj.ColorCount;
		if(ColorCount<=2) ColorCount=2;
		else if(ColorCount>ColorZoneColorsMax) ColorCount=ColorZoneColorsMax;
		AllowEmpty=obj.AllowEmpty;
	}
	void CreateRandom(){
		int i,j;
		StartX=int(genrand_real2()*(m_nWidth-SizeX+1));
		StartY=int(genrand_real2()*(m_nHeight-SizeY+1));
		int sz[3]={SizeX,SizeY,SizeZ};
		i=int(genrand_real2()*3);
		EndSizeX=sz[i];
		sz[i]=sz[2];
		i=int(genrand_real2()*2);
		EndSizeY=sz[i];
		//
		EndX=int(genrand_real2()*(m_nWidth-EndSizeX+1));
		EndY=int(genrand_real2()*(m_nHeight-EndSizeY+1));
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
		//TODO:
		if(ColorZoneSolver::Solve(NULL,&n,NULL,NULL,NULL)){
			return n;
		}else{
			return -10000;
		}
	}
	void CopyFrom(const GABase* src){
		const ColorZoneSolverGA& obj=*(reinterpret_cast<const ColorZoneSolverGA*>(src));
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
		ColorCount=obj.ColorCount;
		AllowEmpty=obj.AllowEmpty;
	}
	void RandomMutation(){
		int new_value;
		for(int t=0;t<8;t++){
			int x=int(genrand_real2()*m_nWidth);
			int y=int(genrand_real2()*m_nHeight);
			new_value=(AllowEmpty?0:1)+int(genrand_real2()*(ColorCount+(AllowEmpty?1:0)));
			if(new_value==0){
				if(x>=StartX&&x<StartX+SizeX&&y>=StartY&&y<StartY+SizeY) continue;
				if(x>=EndX&&x<EndX+EndSizeX&&y>=EndY&&y<EndY+EndSizeY) continue;
			}
			m_bMapData[(y<<m_nWidthShift)+x]=new_value;
		}
		new_value=m_bMapData[(StartY<<m_nWidthShift)+StartX];
		for(int y=StartY;y<StartY+SizeY;y++){
			for(int x=StartX;x<StartX+SizeX;x++){
				m_bMapData[(y<<m_nWidthShift)+x]=new_value;
			}
		}
		new_value=m_bMapData[(EndY<<m_nWidthShift)+EndX];
		for(int y=EndY;y<EndY+EndSizeY;y++){
			for(int x=EndX;x<EndX+EndSizeX;x++){
				m_bMapData[(y<<m_nWidthShift)+x]=new_value;
			}
		}
	}
	void OutputXML(std::ostream& out,bool OutputSolution){
		ColorZoneSolver::OutputXML(out,OutputSolution);
	}
};

#endif