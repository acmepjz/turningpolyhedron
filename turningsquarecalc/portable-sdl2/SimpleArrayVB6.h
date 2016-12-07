#pragma once

#include <vector>

#if defined(DEBUG) || defined(_DEBUG)
int _ArrayBoundsCheckVB6_1D(int i, int L, int U);
int _ArrayBoundsCheckVB6_2D(int i1, int L1, int U1, int i2, int L2, int U2);
int _ArrayBoundsCheckVB6_3D(int i1, int L1, int U1, int i2, int L2, int U2, int i3, int L3, int U3);
#else
inline int _ArrayBoundsCheckVB6_1D(int i, int L, int U) {
	return i - L;
}
inline int _ArrayBoundsCheckVB6_2D(int i1, int L1, int U1, int i2, int L2, int U2) {
	return (i2 - L2) * (U1 - L1 + 1) + (i1 - L1);
}
inline int _ArrayBoundsCheckVB6_3D(int i1, int L1, int U1, int i2, int L2, int U2, int i3, int L3, int U3) {
	return ((i3 - L3) * (U2 - L2 + 1) + (i2 - L2)) * (U1 - L1 + 1) + (i1 - L1);
}
#endif

template <typename T, int L1, int U1>
struct FixedArray1D {
	T data[U1 - L1 + 1];
	const T& operator()(int i1) const {
		return data[_ArrayBoundsCheckVB6_1D(i1, L1, U1)];
	}
	T& operator()(int i1) {
		return data[_ArrayBoundsCheckVB6_1D(i1, L1, U1)];
	}
};

template <typename T, int L1, int U1, int L2, int U2>
struct FixedArray2D {
	T data[(U1 - L1 + 1) * (U2 - L2 + 1)];
	const T& operator()(int i1, int i2) const {
		return data[_ArrayBoundsCheckVB6_2D(i1, L1, U1, i2, L2, U2)];
	}
	T& operator()(int i1, int i2) {
		return data[_ArrayBoundsCheckVB6_2D(i1, L1, U1, i2, L2, U2)];
	}
};

template <typename T, int L1, int U1, int L2, int U2, int L3, int U3>
struct FixedArray3D {
	T data[(U1 - L1 + 1) * (U2 - L2 + 1) * (U3 - L3 + 1)];
	const T& operator()(int i1, int i2, int i3) const {
		return data[_ArrayBoundsCheckVB6_3D(i1, L1, U1, i2, L2, U2, i3, L3, U3)];
	}
	T& operator()(int i1, int i2, int i3) {
		return data[_ArrayBoundsCheckVB6_3D(i1, L1, U1, i2, L2, U2, i3, L3, U3)];
	}
};
