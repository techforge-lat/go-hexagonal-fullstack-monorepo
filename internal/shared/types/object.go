package types

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
	"fmt"
)

// Object is a generic type that implements sql.Scanner and driver.Valuer interfaces
// for handling single objects of any type as database values
// NOTE: always ensure that you use Object as a pointer, if not, the data will appear as a field in the json
type Object[T any] struct {
	data T
}

// NewObject creates a new Object instance with the provided data
func NewObject[T any](data T) Object[T] {
	return Object[T]{data: data}
}

func (op *Object[T]) Data() T {
	return op.data
}

// Value return json value, implement driver.Valuer interface
func (j Object[T]) Value() (driver.Value, error) {
	return json.Marshal(j.data)
}

// Scan scan value into JSONType[T], implements sql.Scanner interface
func (j *Object[T]) Scan(value any) error {
	var bytes []byte
	switch v := value.(type) {
	case []byte:
		bytes = v
	case string:
		bytes = []byte(v)
	default:
		return errors.New(fmt.Sprint("Failed to unmarshal JSONB value:", value))
	}

	return json.Unmarshal(bytes, &j.data)
}

// MarshalJSON to output non base64 encoded []byte
func (j Object[T]) MarshalJSON() ([]byte, error) {
	return json.Marshal(j.data)
}

// UnmarshalJSON to deserialize []byte
func (j *Object[T]) UnmarshalJSON(b []byte) error {
	return json.Unmarshal(b, &j.data)
}

