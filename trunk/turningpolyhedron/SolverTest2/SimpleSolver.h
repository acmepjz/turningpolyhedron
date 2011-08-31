#ifndef __SimpleSolver__
#define __SimpleSolver__

#include <stdlib.h>
#include <string.h>
#include <iostream>
#include <vector>

class SimpleBaseSolver{
protected:
	int m_nWidthShift,m_nHeightShift;
	int m_nWidth,m_nHeight;
	char *m_bMapPassabilityData;
public:
	int StartX,StartY;
	int EndX,EndY;
	int SizeX,SizeY,SizeZ;
	int EndSizeX,EndSizeY;
public:
	SimpleBaseSolver(int w,int h){
		m_nWidth=w;
		m_nHeight=h;
		for(m_nWidthShift=0;(1<<m_nWidthShift)<w;m_nWidthShift++);
		for(m_nHeightShift=0;(1<<m_nHeightShift)<h;m_nHeightShift++);
		m_bMapPassabilityData=(char*)malloc(6<<(m_nWidthShift+m_nHeightShift));
		memset(m_bMapPassabilityData,0,6<<(m_nWidthShift+m_nHeightShift));
		//
		StartX=0;
		StartY=0;
		EndX=0;
		EndY=0;
		SizeX=0;
		SizeY=0;
		SizeZ=0;
		EndSizeX=0;
		EndSizeY=0;
	}
	~SimpleBaseSolver(){
		if(m_bMapPassabilityData) free(m_bMapPassabilityData);
	}
	bool Solve(std::ostream* out,int* step,char* MovedArea,char* SolutionMovedArea,int *NodesUsed){
		const int d1[6][2]={
			{SizeX,SizeY},{SizeY,SizeX},{SizeX,SizeZ},{SizeZ,SizeX},{SizeY,SizeZ},{SizeZ,SizeY}
		};
		const bool b1[6]={
			SizeX==EndSizeX&&SizeY==EndSizeY,
			SizeY==EndSizeX&&SizeX==EndSizeY,
			SizeX==EndSizeX&&SizeZ==EndSizeY,
			SizeZ==EndSizeX&&SizeX==EndSizeY,
			SizeY==EndSizeX&&SizeZ==EndSizeY,
			SizeZ==EndSizeX&&SizeY==EndSizeY
		};
		const int d2[6][4][4]={
			/* x,y */ {{2,0,-SizeZ,0},{5,-SizeZ,0,0},{2,0,SizeY,0},{5,SizeX,0,0}},
			/* y,x */ {{4,0,-SizeZ,0},{3,-SizeZ,0,0},{4,0,SizeX,0},{3,SizeY,0,0}},
			/* x,z */ {{0,0,-SizeY,0},{4,-SizeY,0,0},{0,0,SizeZ,0},{4,SizeX,0,0}},
			/* z,x */ {{5,0,-SizeY,0},{1,-SizeY,0,0},{5,0,SizeX,0},{1,SizeZ,0,0}},
			/* y,z */ {{1,0,-SizeX,0},{2,-SizeX,0,0},{1,0,SizeZ,0},{2,SizeY,0,0}},
			/* z,y */ {{3,0,-SizeX,0},{0,-SizeX,0,0},{3,0,SizeY,0},{0,SizeZ,0,0}}
		};
		//
		unsigned char *b=(unsigned char*)m_bMapPassabilityData;
		const int w=1<<m_nWidthShift,h=1<<m_nHeightShift;
		//
		if(NodesUsed) *NodesUsed=0;
		//
		std::vector<int> v;
		int i=(StartY<<m_nWidthShift)+StartX;
		v.push_back(i);
		b[i]=0xFF;
		for(unsigned int idx=0;idx<v.size();idx++){
			i=v[idx];
			int x0=i&((1<<m_nWidthShift)-1);
			int y0=(i>>m_nWidthShift)&((1<<m_nHeightShift)-1);
			int idx0=i>>(m_nWidthShift+m_nHeightShift);
			//
			if(MovedArea){
				for(int y=y0;y<y0+d1[idx0][1];y++){
					for(int x=x0;x<x0+d1[idx0][0];x++){
						MovedArea[(y<<m_nWidthShift)+x]=1;
					}
				}
			}
			//
			if(x0==EndX&&y0==EndY&&b1[idx0]){
				if(out||step||SolutionMovedArea){
					std::vector<char> *v1=NULL;
					if(out) v1=new std::vector<char>();
					int st=0;
					//
					if(SolutionMovedArea){
						for(int y=y0;y<y0+d1[idx0][1];y++){
							for(int x=x0;x<x0+d1[idx0][0];x++){
								SolutionMovedArea[(y<<m_nWidthShift)+x]=1;
							}
						}
					}
					//
					for(;;){
						int j=b[i];
						if(j==0xFF) break;
						st++;
						j&=0x3;
						if(v1) v1->push_back("ULDR"[j]);
						//
						j^=2;
						x0+=d2[idx0][j][1];
						y0+=d2[idx0][j][2];
						idx0=d2[idx0][j][0];
						//
						if(SolutionMovedArea){
							for(int y=y0;y<y0+d1[idx0][1];y++){
								for(int x=x0;x<x0+d1[idx0][0];x++){
									SolutionMovedArea[(y<<m_nWidthShift)+x]=1;
								}
							}
						}
						//
						i=(((idx0<<m_nHeightShift)+y0)<<m_nWidthShift)+x0;
					}
					if(out){
						for(i=v1->size()-1;i>=0;i--){
							(*out)<<(*v1)[i];
						}
						(*out)<<",Step="<<st;
						delete v1;
					}
					if(step) *step=st;
				}
				if(NodesUsed) *NodesUsed=v.size();
				return true;
			}
			//
			for(int j=0;j<4;j++){
				int x1=x0+d2[idx0][j][1],y1=y0+d2[idx0][j][2],idx1=d2[idx0][j][0];
				if(x1>=0&&y1>=0&&x1<(1<<m_nWidthShift)&&y1<(1<<m_nHeightShift)){
					x1|=(((idx1<<m_nHeightShift)+y1)<<m_nWidthShift);
					if((b[x1]&0x30)==0x20){
						b[x1]|=0x10|j;
						v.push_back(x1);
					}
				}
			}
		}
		if(out) (*out)<<"No solution";
		if(NodesUsed) *NodesUsed=v.size();
		return false;
	}
};

class SimpleSolver:public SimpleBaseSolver{
protected:
	char *m_bMapData;
public:
	SimpleSolver(int w,int h,char *data=NULL):SimpleBaseSolver(w,h){
		m_bMapData=(char*)malloc(1<<(m_nWidthShift+m_nHeightShift));
		memset(m_bMapData,0,1<<(m_nWidthShift+m_nHeightShift));
		if(data){
			for(int j=0;j<h;j++){
				for(int i=0;i<w;i++) m_bMapData[(j<<m_nWidthShift)+i]=data[j*w+i];
			}
		}
	}
	char operator()(int x,int y) const{
		return m_bMapData[(y<<m_nWidthShift)+x];
	}
	char& operator()(int x,int y){
		return m_bMapData[(y<<m_nWidthShift)+x];
	}
	bool Solve(std::ostream* out,int* step,char* MovedArea,char* SolutionMovedArea,int *NodesUsed){
		const int d1[6][2]={
			{SizeX,SizeY},{SizeY,SizeX},{SizeX,SizeZ},{SizeZ,SizeX},{SizeY,SizeZ},{SizeZ,SizeY}
		};
		//
		unsigned char *b=(unsigned char*)m_bMapPassabilityData;
		const int w=1<<m_nWidthShift,h=1<<m_nHeightShift;
		memset(b,0,6<<(m_nWidthShift+m_nHeightShift));
		for(int idx=0;idx<6;idx++){
			int w1=d1[idx][0];
			int h1=d1[idx][1];
			for(int j=0;j<=h-h1;j++){
				for(int i=0;i<=w-w1;i++){
					for(int jj=0;jj<h1;jj++){
						for(int ii=0;ii<w1;ii++){
							if(!m_bMapData[((j+jj)<<m_nWidthShift)+i+ii]) goto _skip;
						}
					}
					b[(((idx<<m_nHeightShift)+j)<<m_nWidthShift)+i]=0x20;
_skip:
					(void)0;
				}
			}
		}
		//
		return SimpleBaseSolver::Solve(out,step,MovedArea,SolutionMovedArea,NodesUsed);
	}
	~SimpleSolver(){
		if(m_bMapData) free(m_bMapData);
	}
	void OutputXML(std::ostream& out,bool OutputSolution){
		out<<"<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n"
			"<!-- Generated by SimpleSolver -->\n"
			"<level>\n";
		if(OutputSolution){
			out<<"\t<solution><![CDATA[";
			Solve(&out,NULL,NULL,NULL,NULL);
			out<<"]]></solution>\n";
		}
		out<<"\t<mapData id=\"m1\" shape=\"rect\" c=\"0.5,0.5,0\" size=\""<<m_nWidth<<","<<m_nHeight<<",1\">\n"
			"\t\t<typeArray><![CDATA[";
		for(int j=0;j<m_nHeight;j++){
			for(int i=0;i<m_nWidth;i++){
				if(i>=EndX&&i<EndX+EndSizeX&&j>=EndY&&j<EndY+EndSizeY) out<<"8";
				else if(m_bMapData[(j<<m_nWidthShift)+i]) out<<"1";
				out<<",";
			}
			out<<"\n";
		}
		out<<"]]></typeArray>\n"
			"\t\t<polyhedron id=\"main\" shape=\""<<SizeX<<"x"<<SizeY<<"x"<<SizeZ<<
			"\" p=\""<<StartX<<","<<StartY<<"\" tiltable=\"false\" supportable=\"false\" autoSize=\"true\">\n"
			"\t\t\t<appearance><shader templateName=\"simple1_fixed\" ambient=\"0.2,0.2,0.2\" diffuse=\"0.2,0.2,0.2\" specular=\"0.4,0.4,0.3\" specularHardness=\"50\">\n"
			"\t\t\t\t<mesh type=\"cube\" bevel=\"1;0.05\" bevelNormalSmoothness=\"1\"/>\n"
			"\t\t\t</shader></appearance>\n"
			"\t\t</polyhedron>\n"
			"\t</mapData>\n"
			"\t<winningCondition>\n"
			"\t\t<moveCondition src=\"main\" target=\"m1("<<EndX<<","<<EndY<<")\" targetSize=\""<<EndSizeX<<","<<EndSizeY<<"\"/>\n"
			"\t</winningCondition>\n"
			"</level>\n";
	}
};

#endif