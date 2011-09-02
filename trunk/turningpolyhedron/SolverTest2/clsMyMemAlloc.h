#ifndef __clsMyMemAlloc__
#define __clsMyMemAlloc__

#include <stdlib.h>

template <class T>
class clsMyMemAlloc{
protected:
	struct typeMyMemAllocItem{
		T* lp;
		T* lpCur;
		int nMax;
		int nRemaining;
	};
	typeMyMemAllocItem *itms;
	int itmsCount,itmsCurrent;
	int m_nCount;
public:
	clsMyMemAlloc(int m=256){
		if(m<=0) m=256;
		itmsCount=1;
		itmsCurrent=0;
		m_nCount=0;
		itms=(typeMyMemAllocItem*)malloc(sizeof(typeMyMemAllocItem));
		itms[0].lp=itms[0].lpCur=(T*)malloc(m*sizeof(T));
		itms[0].nMax=itms[0].nRemaining=m;
	}
	void Destroy(){
		int i;
		for(i=1;i<itmsCount;i++){
			free(itms[i].lp);
		}
		if(itmsCount>1) itms=(typeMyMemAllocItem*)realloc(itms,sizeof(typeMyMemAllocItem));
		itms[0].lpCur=itms[0].lp;
		itms[0].nRemaining=itms[0].nMax;
		itmsCount=1;
		itmsCurrent=0;
		m_nCount=0;
	}
	void Erase(){
		int i;
		for(i=0;i<itmsCount;i++){
			itms[i].lpCur=itms[i].lp;
			itms[i].nRemaining=itms[i].nMax;
		}
		itmsCurrent=0;
		m_nCount=0;
	}
	~clsMyMemAlloc(){
		int i;
		for(i=0;i<itmsCount;i++){
			free(itms[i].lp);
		}
		free(itms);
	}
	T* Alloc(){
		m_nCount++;
		if(itms[itmsCurrent].nRemaining||(++itmsCurrent)<itmsCount){
			itms[itmsCurrent].nRemaining--;
			return itms[itmsCurrent].lpCur++;
		}else{
			int m=itms[itmsCount-1].nMax*2;
			itmsCount++;
			itms=(typeMyMemAllocItem*)realloc(itms,sizeof(typeMyMemAllocItem)*itmsCount);
			itms[itmsCurrent].lp=itms[itmsCurrent].lpCur=(T*)malloc(m*sizeof(T));
			itms[itmsCurrent].nMax=m;
			itms[itmsCurrent].nRemaining=m-1;
			return itms[itmsCurrent].lpCur++;
		}
	}
	inline int ItemCount() const{
		return m_nCount;
	}
};

#endif
