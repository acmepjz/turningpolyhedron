#pragma once

#include <vector>

#if defined(DEBUG) || defined(_DEBUG)
int _ArrayBoundsCheckVB6_1D(int i1, int L1, int M1);
int _ArrayBoundsCheckVB6_2D(int i1, int L1, int M1, int i2, int L2, int M2);
int _ArrayBoundsCheckVB6_3D(int i1, int L1, int M1, int i2, int L2, int M2, int i3, int L3, int M3);
#else
inline int _ArrayBoundsCheckVB6_1D(int i1, int L1, int M1) {
	return i1 - L1;
}
inline int _ArrayBoundsCheckVB6_2D(int i1, int L1, int M1, int i2, int L2, int M2) {
	return (i2 - L2) * M1 + (i1 - L1);
}
inline int _ArrayBoundsCheckVB6_3D(int i1, int L1, int M1, int i2, int M2, int U2, int i3, int L3, int M3) {
	return ((i3 - L3) * M2 + (i2 - L2)) * M1 + (i1 - L1);
}
#endif

template <typename T, int M>
struct FixedArray0 {
	T data[M];
	FixedArray0() {
		clear();
	}
	void clear() {
		fill(T());
	}
	void fill(const T& value) {
		for (int i = 0; i < M; i++) {
			data[i] = value;
		}
	}
	size_t size() const {
		return M;
	}
};

template <typename T, int L1, int U1>
struct FixedArray1D : public FixedArray0 < T, U1 - L1 + 1 > {
	const T& operator()(int i1) const {
		return data[_ArrayBoundsCheckVB6_1D(i1, L1, M1)];
	}
	T& operator()(int i1) {
		return data[_ArrayBoundsCheckVB6_1D(i1, L1, M1)];
	}
private:
	enum {
		M1 = U1 - L1 + 1,
	};
};

template <typename T, int L1, int U1, int L2, int U2>
struct FixedArray2D : public FixedArray0 < T, (U1 - L1 + 1) * (U2 - L2 + 1) > {
	const T& operator()(int i1, int i2) const {
		return data[_ArrayBoundsCheckVB6_2D(i1, L1, M1, i2, L2, M2)];
	}
	T& operator()(int i1, int i2) {
		return data[_ArrayBoundsCheckVB6_2D(i1, L1, M1, i2, L2, M2)];
	}
private:
	enum {
		M1 = U1 - L1 + 1,
		M2 = U2 - L2 + 1,
	};
};

template <typename T, int L1, int U1, int L2, int U2, int L3, int U3>
struct FixedArray3D : public FixedArray0 < T, (U1 - L1 + 1) * (U2 - L2 + 1) * (U3 - L3 + 1) > {
	const T& operator()(int i1, int i2, int i3) const {
		return data[_ArrayBoundsCheckVB6_3D(i1, L1, M1, i2, L2, M2, i3, L3, M3)];
	}
	T& operator()(int i1, int i2, int i3) {
		return data[_ArrayBoundsCheckVB6_3D(i1, L1, M1, i2, L2, M2, i3, L3, M3)];
	}
private:
	enum {
		M1 = U1 - L1 + 1,
		M2 = U2 - L2 + 1,
		M3 = U3 - L3 + 1,
	};
};

template <typename T>
struct Array0 {
	std::vector<T> data;
	void clear() {
		data.clear();
	}
	void fill(const T& value) {
		for (int i = 0, m = data.size(); i < m; i++) {
			data[i] = value;
		}
	}
	size_t size() const {
		return data.size();
	}
};

template <typename T, int L1>
struct Array1D : public Array0 < T > {
	const T& operator()(int i1) const {
		return data[_ArrayBoundsCheckVB6_1D(i1, L1, data.size())];
	}
	T& operator()(int i1) {
		return data[_ArrayBoundsCheckVB6_1D(i1, L1, data.size())];
	}
	void ReDim(int U1) {
		if (U1 >= L1) {
			data.resize(U1 - L1 + 1);
		} else {
			data.clear();
		}
	}
	void ReDimPreserve(int U1) {
		int M = U1 - L1 + 1;
		if (M <= 0) {
			data.clear();
		} else if (M < (int)data.size()) {
			data.erase(data.begin() + M, data.end());
		} else if (M > (int)data.size()) {
			data.insert(data.end(), M - data.size(), T());
		}
	}
};

template <typename T, int L1, int L2>
struct Array2D : public Array0 < T > {
	Array2D() : M1(0), M2(0) {}
	const T& operator()(int i1, int i2) const {
		return data[_ArrayBoundsCheckVB6_2D(i1, L1, M1, i2, L2, M2)];
	}
	T& operator()(int i1, int i2) {
		return data[_ArrayBoundsCheckVB6_2D(i1, L1, M1, i2, L2, M2)];
	}
	void clear() {
		data.clear();
		M1 = M2 = 0;
	}
	void ReDim(int U1, int U2) {
		M1 = U1 - L1 + 1;
		M2 = U2 - L2 + 1;
		if (M1 > 0 && M2 > 0) {
			data.resize(M1*M2);
		} else {
			clear();
		}
	}
	void ReDimPreserve(int U2) {
		if (M1 <= 0) return;
		int M = U2 - L2 + 1;
		if (M < 0) {
			clear();
		} else if (M < M2) {
			data.erase(data.begin() + (M1*M), data.end());
			M2 = M;
		} else if (M > M2) {
			data.insert(data.end(), (M1*M) - data.size(), T());
			M2 = M;
		}
	}
private:
	int M1, M2;
};

template <typename T, int L1, int L2, int L3>
struct Array3D : public Array0 < T > {
	Array3D() : M1(0), M2(0), M3(0) {}
	const T& operator()(int i1, int i2, int i3) const {
		return data[_ArrayBoundsCheckVB6_3D(i1, L1, M1, i2, L2, M2, i3, L3, M3)];
	}
	T& operator()(int i1, int i2, int i3) {
		return data[_ArrayBoundsCheckVB6_3D(i1, L1, M1, i2, L2, M2, i3, L3, M3)];
	}
	void clear() {
		data.clear();
		M1 = M2 = M3 = 0;
	}
	void ReDim(int U1, int U2, int U3) {
		M1 = U1 - L1 + 1;
		M2 = U2 - L2 + 1;
		M3 = U3 - L3 + 1;
		if (M1 > 0 && M2 > 0 && M3 > 0) {
			data.resize(M1*M2*M3);
		} else {
			clear();
		}
	}
	void ReDimPreserve(int U3) {
		if (M1 <= 0 || M2 <= 0) return;
		int M = U3 - L3 + 1;
		if (M < 0) {
			clear();
		} else if (M < M3) {
			data.erase(data.begin() + (M1*M2*M), data.end());
			M3 = M;
		} else if (M > M3) {
			data.insert(data.end(), (M1*M2*M) - data.size(), T());
			M3 = M;
		}
	}
private:
	int M1, M2, M3;
};
