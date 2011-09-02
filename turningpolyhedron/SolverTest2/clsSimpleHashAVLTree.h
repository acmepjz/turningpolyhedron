#ifndef __clsSimpleHashAVLTree__
#define __clsSimpleHashAVLTree__

#include <string.h>
#include "clsMyMemAlloc.h"

template <class T,unsigned int N>
class basic_clsSimpleHashAVLTree{
protected:
	clsMyMemAlloc<T> alloc;
	T** HashTable;
protected:
	static inline void pRotateL(T*& lp){
		T *lpLSon=lp;
		lp=lpLSon->lpRSon;
		lpLSon->lpRSon=lp->lpLSon;
		lp->lpLSon=lpLSon;
		lp->nBalanceFactor=0;
		lpLSon->nBalanceFactor=0;
	}
	static inline void pRotateR(T*& lp){
		T *lpRSon=lp;
		lp=lpRSon->lpLSon;
		lpRSon->lpLSon=lp->lpRSon;
		lp->lpRSon=lpRSon;
		lp->nBalanceFactor=0;
		lpRSon->nBalanceFactor=0;
	}
	static inline void pRotateLR(T*& lp){
		T *lpRSon=lp,*lpLSon=lp->lpLSon;
		lp=lpLSon->lpRSon;
		lpLSon->lpRSon=lp->lpLSon;
		lp->lpLSon=lpLSon;
		int i=lp->nBalanceFactor;
		lpLSon->nBalanceFactor=i<=0?0:-1;
		lpRSon->lpLSon=lp->lpRSon;
		lp->lpRSon=lpRSon;
		lpRSon->nBalanceFactor=i<0?1:0;
		lp->nBalanceFactor=0;
	}
	static inline void pRotateRL(T*& lp){
		T *lpLSon=lp,*lpRSon=lp->lpRSon;
		lp=lpRSon->lpLSon;
		lpRSon->lpLSon=lp->lpRSon;
		lp->lpRSon=lpRSon;
		int i=lp->nBalanceFactor;
		lpRSon->nBalanceFactor=i>=0?0:1;
		lpLSon->lpRSon=lp->lpLSon;
		lp->lpLSon=lpLSon;
		lpLSon->nBalanceFactor=i>0?-1:0;
		lp->nBalanceFactor=0;
	}
	inline void pAddItem(T* p,T* pr,unsigned int h,int d,T **st,int stIndex){
		if(pr){
			if(d<0) pr->lpLSon=p;
			else pr->lpRSon=p;
			while(stIndex>0){
				pr=st[--stIndex];
				d=pr->nBalanceFactor;
				if(p==pr->lpLSon) d--; else d++;
				if((pr->nBalanceFactor=d)==0) break;
				else if(d==1||d==-1) p=pr;
				else{
					d=d<0?-1:1;
					if(p->nBalanceFactor==d){
						if(d<0) pRotateR(pr); else pRotateL(pr);
					}else{
						if(d<0) pRotateLR(pr); else pRotateRL(pr);
					}
					break;
				}
			}
			if(stIndex==0) HashTable[h]=pr;
			else{
				p=st[stIndex-1];
				if(p->tData.Compare(pr->tData)>0) p->lpLSon=pr;
				else p->lpRSon=pr;
			}
		}else{
			HashTable[h]=p;
		}
	}
public:
	basic_clsSimpleHashAVLTree(int m=256):alloc(m){
		HashTable=(T**)malloc(sizeof(void*)<<N);
		memset(HashTable,0,sizeof(void*)<<N);
	}
	void Destroy(){
		alloc.Destroy();
		memset(HashTable,0,sizeof(void*)<<N);
	}
	void Erase(){
		alloc.Erase();
		memset(HashTable,0,sizeof(void*)<<N);
	}
	~basic_clsSimpleHashAVLTree(){
		free(HashTable);
	}
	template <class func_Iterator>
	void ForEachNodeDo(func_Iterator func){
		const unsigned int m=1UL<<N;
		unsigned int i;
		T *p,*st[32];
		int stIndex;
		char st2[32];
		for(i=0;i<m;i++){
			if((p=HashTable[i])!=NULL){
				st[0]=p;
				st2[0]=0;
				stIndex=1;
				for(;;){
					if(st2[stIndex-1]==0&&(p=st[stIndex-1]->lpLSon)!=NULL){
						st2[stIndex-1]=1;
						st[stIndex]=p;
						st2[stIndex]=0;
						stIndex++;
					}else{
						if(!func(st[stIndex-1]->tData)) return;
						if((p=st[stIndex-1]->lpRSon)!=NULL){
							st[stIndex-1]=p;
							st2[stIndex-1]=0;
						}else if((--stIndex)<=0) break;
					}
				}
			}
		}
	}
	inline int ItemCount() const{
		return alloc.ItemCount();
	}
};

template <class T>
struct typeSimpleHashAVLTreeNode{
	typeSimpleHashAVLTreeNode *lpLSon,*lpRSon;
	int nBalanceFactor;
	T tData;
};

template <class T,unsigned int N>
class clsSimpleHashAVLTree:
	public basic_clsSimpleHashAVLTree<typeSimpleHashAVLTreeNode<T>,N>
{
public:
	clsSimpleHashAVLTree(int m=256):basic_clsSimpleHashAVLTree(m){
	}
	T* Alloc(const T& objSrc,int* lpbExist=NULL){
		unsigned int h=((unsigned int)objSrc.HashValue())&((1UL<<N)-1);
		int stIndex=0,d=0;
		typeSimpleHashAVLTreeNode<T> *p,*pr=NULL,*st[32];
		T *ret;
		//========
		for(p=HashTable[h];p!=NULL;){
			if(!(d=objSrc.Compare(p->tData))){
				if(lpbExist) *lpbExist=1;
				return &p->tData;
			}
			st[stIndex++]=pr=p;
			p=d<0?p->lpLSon:p->lpRSon;
		}
		//========not found, add item
		p=alloc.Alloc();
		p->lpLSon=p->lpRSon=NULL;
		p->nBalanceFactor=0;
		p->tData=objSrc;
		ret=&(p->tData);
		pAddItem(p,pr,h,d,st,stIndex);
		//========
		if(lpbExist) *lpbExist=0;
		return ret;
	}
};

template <class T>
struct typeSimpleHashAVLTreeWithQueueNode{
	typeSimpleHashAVLTreeWithQueueNode *lpLSon,*lpRSon,*lpQueueNext;
	int nBalanceFactor;
	T tData;
};

template <class T,unsigned int N>
class clsSimpleHashAVLTreeWithQueue:
	public basic_clsSimpleHashAVLTree<typeSimpleHashAVLTreeWithQueueNode<T>,N>
{
protected:
	typeSimpleHashAVLTreeWithQueueNode<T> *m_lpHead,*m_lpTail;
public:
	clsSimpleHashAVLTreeWithQueue(int m=256):basic_clsSimpleHashAVLTree(m){
		m_lpHead=NULL;
		m_lpTail=NULL;
	}
	T* Alloc(const T& objSrc,int* lpbExist=NULL){
		unsigned int h=((unsigned int)objSrc.HashValue())&((1UL<<N)-1);
		int stIndex=0,d=0;
		typeSimpleHashAVLTreeWithQueueNode<T> *p,*pr=NULL,*st[32];
		T *ret;
		//========
		for(p=HashTable[h];p!=NULL;){
			if(!(d=objSrc.Compare(p->tData))){
				if(lpbExist) *lpbExist=1;
				return &p->tData;
			}
			st[stIndex++]=pr=p;
			p=d<0?p->lpLSon:p->lpRSon;
		}
		//========not found, add item
		p=alloc.Alloc();
		p->lpLSon=p->lpRSon=NULL;
		p->nBalanceFactor=0;
		p->tData=objSrc;
		p->lpQueueNext=NULL;
		if(m_lpTail!=NULL) m_lpTail->lpQueueNext=p;
		m_lpTail=p;
		if(m_lpHead==NULL) m_lpHead=p;
		ret=&(p->tData);
		pAddItem(p,pr,h,d,st,stIndex);
		//========
		if(lpbExist) *lpbExist=0;
		return ret;
	}
	T* Pop(){
		if(m_lpHead==NULL) return NULL;
		T *ret=&m_lpHead->tData;
		m_lpHead=m_lpHead->lpQueueNext;
		return ret;
	}
};

#endif