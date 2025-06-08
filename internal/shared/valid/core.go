package valid

import (
	"reflect"

	"github.com/google/uuid"
	"gopkg.in/guregu/null.v4"
)

type Schema interface {
	Parse(value any) *Result
	Optional() Schema
	Required() Schema
	Custom(fn CustomValidatorFunc) Schema
}

type Result struct {
	Success bool
	Data    any
	Errors  []ValidationError
}

type ValidationError struct {
	Path    string
	Message string
	Code    string
}

type CustomValidatorFunc func(value any) error

type baseSchema struct {
	optional         bool
	required         bool
	customValidators []CustomValidatorFunc
}

func (b *baseSchema) setOptional() {
	b.optional = true
	b.required = false
}

func (b *baseSchema) setRequired() {
	b.required = true
	b.optional = false
}

func (b *baseSchema) addCustom(fn CustomValidatorFunc) {
	b.customValidators = append(b.customValidators, fn)
}

func (b *baseSchema) validateRequired(value any, path string) []ValidationError {
	if b.required && isNilOrEmpty(value) {
		return []ValidationError{{
			Path:    path,
			Message: getMessage(msgs.Required),
			Code:    "required",
		}}
	}
	return nil
}

func (b *baseSchema) validateCustom(value any, path string) []ValidationError {
	var errors []ValidationError
	for _, validator := range b.customValidators {
		if err := validator(value); err != nil {
			errors = append(errors, ValidationError{
				Path:    path,
				Message: err.Error(),
				Code:    "custom",
			})
		}
	}
	return errors
}

func isNilOrEmpty(value any) bool {
	if value == nil {
		return true
	}

	// Handle null library types
	switch v := value.(type) {
	case null.String:
		return !v.Valid || v.String == ""
	case null.Int:
		return !v.Valid
	case null.Float:
		return !v.Valid
	case null.Bool:
		return !v.Valid
	case null.Time:
		return !v.Valid
	case uuid.NullUUID:
		return !v.Valid
	}

	v := reflect.ValueOf(value)
	switch v.Kind() {
	case reflect.String:
		return v.String() == ""
	case reflect.Ptr:
		return v.IsNil()
	case reflect.Slice, reflect.Map, reflect.Array:
		return v.Len() == 0
	default:
		return false
	}
}

func newResult(success bool, data any, errors []ValidationError) *Result {
	return &Result{
		Success: success,
		Data:    data,
		Errors:  errors,
	}
}
