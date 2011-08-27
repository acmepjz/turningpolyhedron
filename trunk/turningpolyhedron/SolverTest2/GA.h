#ifndef __GA__
#define __GA__

#include <stdlib.h>
#include <iostream>
#include "GABase.h"
#include "mt19937.h"

struct GANode{
	int Index;
	int Fitness;
};

static int GANode_Compare(const void* a,const void* b){
	int f1=((GANode*)a)->Fitness;
	int f2=((GANode*)b)->Fitness;
	if(f1>f2) return -1;
	else if(f1<f2) return 1;
	else return 0;
}

typedef void (__stdcall * GACallbackFunc)(void* UserData,int CurrentGeneration,int GenerationCount,int* Cancel);

class GA{
private:
	int m_nPoolSize;
	GABase** Pool;
	GANode* Node;
public:
	GA():m_nPoolSize(0),Pool(NULL),Node(NULL){
	}
	~GA(){
		for(int i=0;i<m_nPoolSize;i++){
			delete Pool[i];
		}
		free(Pool);
		free(Node);
	}
	template <class T_Factory,class Tc>
	bool Create(T_Factory factory,Tc& obj,int PoolSize){
		Destroy();
		//
		m_nPoolSize=PoolSize;
		Pool=(GABase**)malloc(PoolSize*sizeof(GABase*));
		Node=(GANode*)malloc(PoolSize*sizeof(GANode));
		memset(Pool,0,PoolSize*sizeof(GABase*));
		memset(Node,0,PoolSize*sizeof(GANode));
		//
		for(int i=0;i<PoolSize;i++){
			if((Pool[i]=factory(obj))==NULL){
				Destroy();
				return false;
			}
		}
		//
		return true;
	}
	void Destroy(){
		for(int i=0;i<m_nPoolSize;i++){
			delete Pool[i];
		}
		free(Pool);
		free(Node);
		m_nPoolSize=0;
		Pool=NULL;
		Node=NULL;
	}
	bool Run(int GenerationCount,int RandomFitness,std::ostream* out,GACallbackFunc Callback,void* UserData){
		int i,j;
		int Cancel=0;
		for(i=0;i<m_nPoolSize;i++){
			Pool[i]->CreateRandom();
		}
		for(int t=0;t<GenerationCount;t++){
			if(out) (*out)<<"Running generation "<<(t+1)<<"...\r";
			if(Callback){
				Callback(UserData,t,GenerationCount,&Cancel);
				if(Cancel) break;
			}
			for(i=0;i<m_nPoolSize;i++){
				Node[i].Index=i;
				Node[i].Fitness=Pool[i]->CalcFitness()+int(genrand_real2()*RandomFitness);
			}
			qsort(Node,m_nPoolSize,sizeof(GANode),GANode_Compare);
			//
			i=0;
			j=m_nPoolSize-1;
			while(i<j){
				int m=1;
				for(int k=0;k<m&&i<j;k++,j--){
					Pool[Node[j].Index]->CopyFrom(Pool[Node[i].Index]);
					Pool[Node[j].Index]->RandomMutation();
				}
				i++;
			}
		}
		for(i=0;i<m_nPoolSize;i++){
			Node[i].Index=i;
			Node[i].Fitness=Pool[i]->CalcFitness();
		}
		qsort(Node,m_nPoolSize,sizeof(GANode),GANode_Compare);
		if(out) (*out)<<"\nDone.\n";
		return !Cancel;
	}
	GABase* operator()(int Index){
		return Pool[Node[Index].Index];
	}
	int Fitness(int Index){
		return Node[Index].Fitness;
	}
};

#endif