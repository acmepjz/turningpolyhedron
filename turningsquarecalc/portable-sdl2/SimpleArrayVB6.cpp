#include "SimpleArrayVB6.h"
#include <assert.h>

#if defined(DEBUG) || defined(_DEBUG)
int _ArrayBoundsCheckVB6_1D(int i, int L, int U) {
	assert(i >= L && i <= U && "Run-time error '9': subscript out of range");
	return i - L;
}
int _ArrayBoundsCheckVB6_2D(int i1, int L1, int U1, int i2, int L2, int U2) {
	assert(i1 >= L1 && i1 <= U1 && "Run-time error '9': subscript out of range");
	assert(i2 >= L2 && i2 <= U2 && "Run-time error '9': subscript out of range");
	return (i2 - L2) * (U1 - L1 + 1) + (i1 - L1);
}
int _ArrayBoundsCheckVB6_3D(int i1, int L1, int U1, int i2, int L2, int U2, int i3, int L3, int U3) {
	assert(i1 >= L1 && i1 <= U1 && "Run-time error '9': subscript out of range");
	assert(i2 >= L2 && i2 <= U2 && "Run-time error '9': subscript out of range");
	assert(i3 >= L3 && i3 <= U3 && "Run-time error '9': subscript out of range");
	return ((i3 - L3) * (U2 - L2 + 1) + (i2 - L2)) * (U1 - L1 + 1) + (i1 - L1);
}
#endif
