package valid

import (
	"reflect"
)

type Schema interface {
	Parse(value interface{}) *Result
	Optional() Schema
	Required() Schema
	Custom(fn CustomValidatorFunc) Schema
}

type Result struct {
	Success bool
	Data    interface{}
	Errors  []ValidationError
}

type ValidationError struct {
	Path    string
	Message string
	Code    string
}

type CustomValidatorFunc func(value interface{}) error

type baseSchema struct {
	optional       bool
	required       bool
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

func (b *baseSchema) validateRequired(value interface{}, path string) []ValidationError {
	if b.required && isNilOrEmpty(value) {
		return []ValidationError{{
			Path:    path,
			Message: getMessage(msgs.Required),
			Code:    "required",
		}}
	}
	return nil
}

func (b *baseSchema) validateCustom(value interface{}, path string) []ValidationError {
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

func isNilOrEmpty(value interface{}) bool {
	if value == nil {
		return true
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

func newResult(success bool, data interface{}, errors []ValidationError) *Result {
	return &Result{
		Success: success,
		Data:    data,
		Errors:  errors,
	}
}