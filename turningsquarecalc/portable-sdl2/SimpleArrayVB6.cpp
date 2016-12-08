#include "SimpleArrayVB6.h"
#include <assert.h>

#if defined(DEBUG) || defined(_DEBUG)
int _ArrayBoundsCheckVB6_1D(int i1, int L1, int M1) {
	assert(i1 >= L1 && i1 < L1 + M1 && "Run-time error '9': subscript out of range");
	return i1 - L1;
}
int _ArrayBoundsCheckVB6_2D(int i1, int L1, int M1, int i2, int L2, int M2) {
	assert(i1 >= L1 && i1 < L1 + M1 && "Run-time error '9': subscript out of range");
	assert(i2 >= L2 && i2 < L2 + M2 && "Run-time error '9': subscript out of range");
	return (i2 - L2) * M1 + (i1 - L1);
}
int _ArrayBoundsCheckVB6_3D(int i1, int L1, int M1, int i2, int L2, int M2, int i3, int L3, int M3) {
	assert(i1 >= L1 && i1 < L1 + M1 && "Run-time error '9': subscript out of range");
	assert(i2 >= L2 && i2 < L2 + M2 && "Run-time error '9': subscript out of range");
	assert(i3 >= L3 && i3 < L3 + M3 && "Run-time error '9': subscript out of range");
	return ((i3 - L3) * M2 + (i2 - L2)) * M1 + (i1 - L1);
}
#endif
