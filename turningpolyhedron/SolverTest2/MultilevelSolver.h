#ifndef __MultilevelSolver__
#define __MultilevelSolver__

#include <stdlib.h>
#include <string.h>
#include <iostream>
#include <vector>
#include "clsSimpleHashAVLTree.h"
#include "crc32.h"

template <int N_Max>
class MultilevelSolver{
protected:
	struct SolverPolyhedron{
		char x,y,sx,sy;
	};
	struct SolverNode{
		SolverPolyhedron p[N_Max];
		SolverNode *lpPrev;
		//
		inline unsigned int HashValue() const{
			return crc32(this,sizeof(*this)-sizeof(void*));
		}
		inline int Compare(const SolverNode& other) const{
			return memcmp(this,&other,sizeof(*this)-sizeof(void*));
		}
	};
	struct Polyhedron{
		char x,y,z,sx,sy,sz;
		char TotalSize,Reserved;
	};
protected:
	int m_nWidthShift,m_nHeightShift;
	int m_nWidth,m_nHeight;
	char *m_bMapData; // -1=not passable, >=0 is terrain height
	Polyhedron m_tPolyhedron[N_Max];
	int m_nPolyhedronCount;
public:
	int TargetIndex;
	char TargetX,TargetY,TargetSizeX,TargetSizeY;
public:
	MultilevelSolver(){
		memset(m_tPolyhedron,0,sizeof(m_tPolyhedron));
		m_nPolyhedronCount=0;
		TargetIndex=0;
		TargetX=TargetY=TargetSizeX=TargetSizeY=0;
		m_nWidthShift=m_nHeightShift=0;
		m_nWidth=m_nHeight=0;
		m_bMapData=NULL;
	}
	~MultilevelSolver(){
		free(m_bMapData);
	}
	inline char operator()(int x,int y) const{
		return m_bMapData[(y<<m_nWidthShift)+x];
	}
	inline char& operator()(int x,int y){
		return m_bMapData[(y<<m_nWidthShift)+x];
	}
	void SetSize(int w,int h){
		free(m_bMapData);
		m_nWidth=w;
		m_nHeight=h;
		for(m_nWidthShift=0;(1<<m_nWidthShift)<w;m_nWidthShift++);
		for(m_nHeightShift=0;(1<<m_nHeightShift)<h;m_nHeightShift++);
		m_bMapData=(char*)malloc(1<<(m_nWidthShift+m_nHeightShift));
		memset(m_bMapData,0,1<<(m_nWidthShift+m_nHeightShift));
	}
	void SetPolyhedronCount(int n){
		if(n>=0&&n<=N_Max) m_nPolyhedronCount=n;
	}
	int PolyhedronCount(){
		return m_nPolyhedronCount;
	}
	void SetPolyhedron(int Index,char x,char y,char z,char sx,char sy,char sz){
		if(Index>=0&&Index<N_Max){
			m_tPolyhedron[Index].x=x;
			m_tPolyhedron[Index].y=y;
			m_tPolyhedron[Index].z=z;
			m_tPolyhedron[Index].sx=sx;
			m_tPolyhedron[Index].sy=sy;
			m_tPolyhedron[Index].sz=sz;
			m_tPolyhedron[Index].TotalSize=sx+sy+sz;
		}
	}
	bool Solve(std::ostream* out,int* step,char* MovedArea,char* SolutionMovedArea,int *NodesUsed){
		if(m_nPolyhedronCount<=0||m_nPolyhedronCount>N_Max) return false;
		if(m_nWidth<=0||m_nHeight<=0) return false;
		if(TargetIndex<0||TargetIndex>=m_nPolyhedronCount) return false;
		//
		clsSimpleHashAVLTreeWithQueue<SolverNode,12> objTree;
		SolverNode nd,*lpnd;
		char *bMapData2=(char*)malloc(1<<(m_nWidthShift+m_nHeightShift));
		int i,j;
		bool ret=false;
		//first node
		memset(&nd,0,sizeof(nd));
		for(i=0;i<m_nPolyhedronCount;i++){
			nd.p[i].x=m_tPolyhedron[i].x;
			nd.p[i].y=m_tPolyhedron[i].y;
			nd.p[i].sx=m_tPolyhedron[i].sx;
			nd.p[i].sy=m_tPolyhedron[i].sy;
		}
		objTree.Alloc(nd,NULL);
		//
		while((lpnd=objTree.Pop())!=NULL){
			if(lpnd->p[TargetIndex].x==TargetX && lpnd->p[TargetIndex].y==TargetY
				&& lpnd->p[TargetIndex].sx==TargetSizeX && lpnd->p[TargetIndex].sy==TargetSizeY)
			{
				//find a solution.
				if(out||step){
					int st=0;
					std::vector<SolverNode*> v;
					v.push_back(lpnd);
					while((lpnd=lpnd->lpPrev)!=NULL){
						st++;
						v.push_back(lpnd);
					}
					//
					if(out){
						int last_move=0;
						for(i=v.size()-2;i>=0;i--){
							lpnd=v[i];
							SolverNode *lpnd_prev=v[i+1];
							int current_move=0;
							char dir=0;
							//check which is move
							for(j=0;j<m_nPolyhedronCount;j++){
								if(lpnd->p[j].x > lpnd_prev->p[j].x){
									dir='R';
									current_move=j;
									break;
								}else if(lpnd->p[j].x < lpnd_prev->p[j].x){
									dir='L';
									current_move=j;
									break;
								}else if(lpnd->p[j].y > lpnd_prev->p[j].y){
									dir='D';
									current_move=j;
									break;
								}else if(lpnd->p[j].y < lpnd_prev->p[j].y){
									dir='U';
									current_move=j;
									break;
								}
							}
							//output
							while(last_move!=current_move){
								(*out)<<'S';
								last_move++;
								if(last_move>=m_nPolyhedronCount) last_move-=m_nPolyhedronCount;
							}
							(*out)<<dir;
						}
						(*out)<<",Step="<<st;
					}
					//
					if(step) *step=st;
				}
				//
				ret=true;
				break;
			}
			//get polyhedron height
			memcpy(bMapData2,m_bMapData,1<<(m_nWidthShift+m_nHeightShift));
			for(int idx=0;idx<m_nPolyhedronCount;idx++){
				char z=m_tPolyhedron[idx].z+m_tPolyhedron[idx].TotalSize-lpnd->p[idx].sx-lpnd->p[idx].sy;
				int startx=lpnd->p[idx].x,
					starty=lpnd->p[idx].y,
					endx=startx+lpnd->p[idx].sx,
					endy=starty+lpnd->p[idx].sy;
				for(j=starty;j<endy;j++){
					for(i=startx;i<endx;i++){
						if(bMapData2[(j<<m_nWidthShift)+i]<z) bMapData2[(j<<m_nWidthShift)+i]=z;
					}
				}
			}
			//expand node
			for(int idx=0;idx<m_nPolyhedronCount;idx++){
				bool b=true;
				//check if it can move
				char startx=lpnd->p[idx].x,
					starty=lpnd->p[idx].y,
					sx=lpnd->p[idx].sx,
					sy=lpnd->p[idx].sy,
					endx=startx+sx,
					endy=starty+sy;
				char sz=m_tPolyhedron[idx].TotalSize-sx-sy;
				{
					char z=m_tPolyhedron[idx].z+sz;
					for(i=0;i<m_nPolyhedronCount;i++){
						if(i!=idx && m_tPolyhedron[i].z==z){
							char x=lpnd->p[i].x;
							char y=lpnd->p[i].y;
							if(x<endx && y<endy && x+lpnd->p[i].sx>startx && y+lpnd->p[i].sy>starty){
								b=false;
								goto _skip1;
							}
						}
					}
_skip1:
					(void)0;
				}
				//move it
				if(b){
					char new_pos[4][4]={
						/* U */ {startx,starty-sz,sx,sz},
						/* L */ {startx-sz,starty,sz,sy},
						/* D */ {startx,endy,sx,sz},
						/* R */ {endx,starty,sz,sy},
					};
					char z=m_tPolyhedron[idx].z;
					for(int dir=0;dir<4;dir++){
						startx=new_pos[dir][0];
						starty=new_pos[dir][1];
						sx=new_pos[dir][2];
						sy=new_pos[dir][3];
						endx=startx+sx;
						endy=starty+sy;
						if(startx>=0 && endx<=m_nWidth && starty>=0 && endy<=m_nHeight){
							b=true;
							for(j=starty;j<endy;j++){
								for(i=startx;i<endx;i++){
									if(bMapData2[(j<<m_nWidthShift)+i]!=z){
										b=false;
										goto _skip2;
									}
								}
							}
_skip2:
							if(b){
								nd=(*lpnd);
								nd.p[idx].x=startx;
								nd.p[idx].y=starty;
								nd.p[idx].sx=sx;
								nd.p[idx].sy=sy;
								nd.lpPrev=lpnd;
								objTree.Alloc(nd,NULL);
							}
						}
					}
				}
			}
		}
		//over
		if(!ret && out) (*out)<<"No solution.";
		if(NodesUsed) *NodesUsed=objTree.ItemCount();
		return ret;
	}
	void OutputXML(std::ostream& out,bool OutputSolution){
		out<<"<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n"
			"<!-- Generated by MultilevelSolver -->\n"
			"<level>\n";
		if(m_nPolyhedronCount<=0||m_nPolyhedronCount>N_Max
			||m_nWidth<=0||m_nHeight<=0
			||TargetIndex<0||TargetIndex>=m_nPolyhedronCount)
		{
			out<<"\t<mapData shape=\"invalid\"/>\n"
				"</level>\n";
			return;
		}
		if(OutputSolution){
			out<<"\t<solution><![CDATA[";
			Solve(&out,NULL,NULL,NULL,NULL);
			out<<"]]></solution>\n";
		}
		//
		int max_z=0;
		for(int j=0;j<m_nHeight;j++){
			for(int i=0;i<m_nWidth;i++){
				int z=m_bMapData[(j<<m_nWidthShift)+i];
				if(z>max_z) max_z=z;
			}
		}
		max_z++;
		//
		if(max_z>1){
			out<<"\t<tileMapping id=\"block-ground\" index=\"-1\"/>\n";
		}
		out<<"\t<tileMapping id=\"floating-goal\" index=\"-2\"/>\n";
		out<<"\t<mapData id=\"m1\" shape=\"rect\" size=\""<<m_nWidth<<","<<m_nHeight<<","<<max_z<<"\">\n"
			"\t\t<typeArray><![CDATA[";
		for(int z=0;z<max_z;z++){
			for(int j=0;j<m_nHeight;j++){
				for(int i=0;i<m_nWidth;i++){
					if(m_bMapData[(j<<m_nWidthShift)+i]>=z){
						if(z>0) out<<"-1";
						else out<<"1";
					}
					out<<",";
				}
				out<<"\n";
			}
		}
		out<<"]]></typeArray>\n";
		for(int i=0;i<m_nPolyhedronCount;i++){
			const char* s;
			if(TargetIndex==i) s="0.4,0.3,0.2";
			else s="0.2,0.2,0.2";
			out<<"\t\t<polyhedron id=\"p"<<i<<"\" shape=\""<<int(m_tPolyhedron[i].sx)
				<<"x"<<int(m_tPolyhedron[i].sy)<<"x"<<int(m_tPolyhedron[i].sz)
				<<"\" p=\""<<int(m_tPolyhedron[i].x)<<","<<int(m_tPolyhedron[i].y)<<","<<int(m_tPolyhedron[i].z)
				<<"\" tiltable=\"false\" supportable=\"false\" autoSize=\"true\">\n"
				"\t\t\t<appearance><shader templateName=\"simple1_fixed\" ambient=\""<<s<<"\" diffuse=\""<<s<<"\" specular=\"0.4,0.4,0.3\" specularHardness=\"50\">\n"
				"\t\t\t\t<mesh type=\"cube\" bevel=\"1;0.05\" bevelNormalSmoothness=\"1\"/>\n"
				"\t\t\t</shader></appearance>\n"
				"\t\t</polyhedron>\n";
		}
		out<<"\t</mapData>\n"
			"\t<mapData id=\"overlay\" p=\""<<int(TargetX)<<","<<int(TargetY)<<","<<int(m_tPolyhedron[TargetIndex].z)
			<<"\" shape=\"rect\" size=\""<<int(TargetSizeX)<<","<<int(TargetSizeY)<<",1\">\n"
			"\t\t<typeArray>-2*"<<int(TargetSizeX)*int(TargetSizeY)<<"</typeArray>\n"
			"\t</mapData>\n"
			"\t<winningCondition>\n"
			"\t\t<moveCondition src=\"p"<<TargetIndex<<"\" target=\"m1("<<int(TargetX)<<","<<int(TargetY)<<","<<int(m_tPolyhedron[TargetIndex].z)
			<<")\" targetSize=\""<<int(TargetSizeX)<<","<<int(TargetSizeY)<<"\"/>\n"
			"\t</winningCondition>\n"
			"</level>\n";
	}
};

#endif