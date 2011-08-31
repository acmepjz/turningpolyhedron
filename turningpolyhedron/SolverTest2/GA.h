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
public:
	struct Settings{
		int RandomFitness;
		int SeparatePool;
		double FirstReproduce;
		double ReproduceDecay;
		double ReproduceCountDecay;
		double MutationProbability;
	};
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
	bool Run(int GenerationCount,const Settings& t,std::ostream* out,GACallbackFunc Callback,void* UserData){
		int i,j;
		int Cancel=0;
		for(i=0;i<m_nPoolSize;i++){
			Pool[i]->CreateRandom();
		}
		for(int times=0;times<GenerationCount;times++){
			int pool_a=0;
			if(out) (*out)<<"Running generation "<<(times+1)<<"...\r";
			if(Callback){
				Callback(UserData,times,GenerationCount,&Cancel);
				if(Cancel) break;
			}
			for(i=0;i<m_nPoolSize;i++){
				Node[i].Index=i;
				Node[i].Fitness=Pool[i]->CalcFitness()+int(genrand_real2()*t.RandomFitness);
				if(Node[i].Fitness>0) pool_a++;
			}
			qsort(Node,m_nPoolSize,sizeof(GANode),GANode_Compare);
			//reproduce
			{
				double f=t.FirstReproduce;
				i=0;
				if(t.SeparatePool) j=pool_a-1;
				else j=m_nPoolSize-1;
				while(i<j){
					if(genrand_real2()<f){
						for(;i<j;j--){
							Pool[Node[j].Index]->CopyFrom(Pool[Node[i].Index]);
							if(genrand_real2()>t.ReproduceCountDecay) break;
						}
					}
					f*=t.ReproduceDecay;
					i++;
				}
				if(t.SeparatePool){
					f=t.FirstReproduce;
					i=pool_a;
					j=m_nPoolSize-1;
					while(i<j){
						if(genrand_real2()<f){
							for(;i<j;j--){
								Pool[Node[j].Index]->CopyFrom(Pool[Node[i].Index]);
								if(genrand_real2()>t.ReproduceCountDecay) break;
							}
						}
						f*=t.ReproduceDecay;
						i++;
					}
				}
			}
			//mutation
			for(i=0;i<m_nPoolSize;i++){
				if(genrand_real2()<t.MutationProbability){
					Pool[i]->RandomMutation();
				}
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