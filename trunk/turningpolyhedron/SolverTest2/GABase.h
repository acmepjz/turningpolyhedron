#ifndef __GABase__
#define __GABase__

#include <iostream>

class GABase{
public:
	virtual void CreateRandom()=0;
	virtual int CalcFitness()=0;
	virtual void CopyFrom(const GABase* src)=0;
	virtual void RandomMutation()=0;
	virtual void OutputXML(std::ostream& out,bool OutputSolution)=0;
	virtual ~GABase(){}
};

#endif