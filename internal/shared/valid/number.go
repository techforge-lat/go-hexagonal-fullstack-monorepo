package valid

import (
	"reflect"
)

type NumberSchema struct {
	baseSchema
	min         *float64
	max         *float64
	integer     bool
	positive    bool
	negative    bool
}

func Number() *NumberSchema {
	return &NumberSchema{
		baseSchema: baseSchema{},
	}
}

func Int() *NumberSchema {
	return &NumberSchema{
		baseSchema: baseSchema{},
		integer:    true,
	}
}

func (n *NumberSchema) Parse(value interface{}) *Result {
	return n.parseWithPath(value, "")
}

func (n *NumberSchema) parseWithPath(value interface{}, path string) *Result {
	// Skip all validations for null library types that are not valid
	if isNullLibraryType(value) {
		return newResult(true, value, nil)
	}

	if n.optional && isNilOrEmpty(value) {
		return newResult(true, value, nil)
	}

	if errors := n.validateRequired(value, path); len(errors) > 0 {
		return newResult(false, nil, errors)
	}

	if isNilOrEmpty(value) && !n.required {
		return newResult(true, value, nil)
	}

	num, ok := convertToFloat64(value)
	if !ok {
		return newResult(false, nil, []ValidationError{{
			Path:    path,
			Message: getMessage(msgs.TypeNumber),
			Code:    "type_error",
		}})
	}

	var errors []ValidationError

	if n.integer && !isInteger(num) {
		errors = append(errors, ValidationError{
			Path:    path,
			Message: getMessage(msgs.Integer),
			Code:    "integer",
		})
	}

	if n.positive && num <= 0 {
		errors = append(errors, ValidationError{
			Path:    path,
			Message: getMessage(msgs.Positive),
			Code:    "positive",
		})
	}

	if n.negative && num >= 0 {
		errors = append(errors, ValidationError{
			Path:    path,
			Message: getMessage(msgs.Negative),
			Code:    "negative",
		})
	}

	if n.min != nil && num < *n.min {
		errors = append(errors, ValidationError{
			Path:    path,
			Message: getMessage(msgs.Min, *n.min),
			Code:    "min",
		})
	}

	if n.max != nil && num > *n.max {
		errors = append(errors, ValidationError{
			Path:    path,
			Message: getMessage(msgs.Max, *n.max),
			Code:    "max",
		})
	}

	errors = append(errors, n.validateCustom(value, path)...)

	if len(errors) > 0 {
		return newResult(false, nil, errors)
	}

	return newResult(true, value, nil)
}

func (n *NumberSchema) Min(min float64) *NumberSchema {
	n.min = &min
	return n
}

func (n *NumberSchema) Max(max float64) *NumberSchema {
	n.max = &max
	return n
}

func (n *NumberSchema) Range(min, max float64) *NumberSchema {
	n.min = &min
	n.max = &max
	return n
}

func (n *NumberSchema) Positive() *NumberSchema {
	n.positive = true
	return n
}

func (n *NumberSchema) Negative() *NumberSchema {
	n.negative = true
	return n
}

func (n *NumberSchema) Integer() *NumberSchema {
	n.integer = true
	return n
}

func (n *NumberSchema) Optional() Schema {
	n.baseSchema.setOptional()
	return n
}

func (n *NumberSchema) Required() Schema {
	n.baseSchema.setRequired()
	return n
}

func (n *NumberSchema) Custom(fn CustomValidatorFunc) Schema {
	n.baseSchema.addCustom(fn)
	return n
}

func convertToFloat64(value interface{}) (float64, bool) {
	if value == nil {
		return 0, false
	}

	val := reflect.ValueOf(value)
	
	if val.Kind() == reflect.Ptr {
		if val.IsNil() {
			return 0, false
		}
		val = val.Elem()
	}

	switch val.Kind() {
	case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
		return float64(val.Int()), true
	case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64:
		return float64(val.Uint()), true
	case reflect.Float32, reflect.Float64:
		return val.Float(), true
	default:
		return 0, false
	}
}

func isInteger(num float64) bool {
	return num == float64(int64(num))
}