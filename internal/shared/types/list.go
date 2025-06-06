package types

type (
	ListIterator[T any] = func(k uint, v T) bool
)

type List[T any] []T

func (l List[T]) IsEmpty() bool {
	return len(l) == 0
}

func (l List[T]) Filter(iter ListIterator[T]) []T {
	res := make([]T, 0, len(l))
	for k, v := range l {
		if iter(uint(k), v) {
			res = append(res, v)
		}
	}

	return res
}

func (l List[T]) Find(iter ListIterator[T]) (T, bool) {
	for k, v := range l {
		if iter(uint(k), v) {
			return v, true
		}
	}

	return *new(T), false
}

func (l List[T]) MustFind(iter ListIterator[T]) T {
	for k, v := range l {
		if iter(uint(k), v) {
			return v
		}
	}

	return *new(T)
}
