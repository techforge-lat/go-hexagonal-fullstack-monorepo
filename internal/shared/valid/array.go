package valid

import (
	"fmt"
	"reflect"
)

type ArraySchema struct {
	baseSchema
	itemSchema Schema
	minItems   *int
	maxItems   *int
}

func Array(itemSchema Schema) *ArraySchema {
	return &ArraySchema{
		baseSchema: baseSchema{},
		itemSchema: itemSchema,
	}
}

func (a *ArraySchema) Parse(value interface{}) *Result {
	return a.parseWithPath(value, "")
}

func (a *ArraySchema) parseWithPath(value interface{}, path string) *Result {
	if a.optional && value == nil {
		return newResult(true, value, nil)
	}

	if errors := a.validateRequired(value, path); len(errors) > 0 {
		return newResult(false, nil, errors)
	}

	if value == nil && !a.required {
		return newResult(true, value, nil)
	}

	items, ok := convertToSlice(value)
	if !ok {
		return newResult(false, nil, []ValidationError{{
			Path:    path,
			Message: getMessage(msgs.TypeArray),
			Code:    "type_error",
		}})
	}

	var errors []ValidationError

	if a.minItems != nil && len(items) < *a.minItems {
		errors = append(errors, ValidationError{
			Path:    path,
			Message: getMessage(msgs.MinItems, *a.minItems),
			Code:    "min_items",
		})
	}

	if a.maxItems != nil && len(items) > *a.maxItems {
		errors = append(errors, ValidationError{
			Path:    path,
			Message: getMessage(msgs.MaxItems, *a.maxItems),
			Code:    "max_items",
		})
	}

	var validatedItems []interface{}
	for i, item := range items {
		itemPath := fmt.Sprintf("%s[%d]", path, i)
		if len(path) == 0 {
			itemPath = fmt.Sprintf("[%d]", i)
		}

		var result *Result
		if stringSchema, ok := a.itemSchema.(*StringSchema); ok {
			result = stringSchema.parseWithPath(item, itemPath)
		} else if numberSchema, ok := a.itemSchema.(*NumberSchema); ok {
			result = numberSchema.parseWithPath(item, itemPath)
		} else if objectSchema, ok := a.itemSchema.(*ObjectSchema); ok {
			result = objectSchema.parseWithPath(item, itemPath)
		} else if arraySchema, ok := a.itemSchema.(*ArraySchema); ok {
			result = arraySchema.parseWithPath(item, itemPath)
		} else {
			result = a.itemSchema.Parse(item)
			if len(result.Errors) > 0 {
				result.Errors = addPathPrefix(result.Errors, itemPath)
			}
		}

		if result.HasErrors() {
			errors = append(errors, result.Errors...)
		} else {
			validatedItems = append(validatedItems, result.Data)
		}
	}

	errors = append(errors, a.validateCustom(validatedItems, path)...)

	if len(errors) > 0 {
		return newResult(false, nil, errors)
	}

	return newResult(true, validatedItems, nil)
}

func (a *ArraySchema) MinItems(min int) *ArraySchema {
	a.minItems = &min
	return a
}

func (a *ArraySchema) MaxItems(max int) *ArraySchema {
	a.maxItems = &max
	return a
}

func (a *ArraySchema) Length(min, max int) *ArraySchema {
	a.minItems = &min
	a.maxItems = &max
	return a
}

func (a *ArraySchema) Optional() Schema {
	a.baseSchema.setOptional()
	return a
}

func (a *ArraySchema) Required() Schema {
	a.baseSchema.setRequired()
	return a
}

func (a *ArraySchema) Custom(fn CustomValidatorFunc) Schema {
	a.baseSchema.addCustom(fn)
	return a
}

func convertToSlice(value interface{}) ([]interface{}, bool) {
	if value == nil {
		return nil, false
	}

	val := reflect.ValueOf(value)
	if val.Kind() == reflect.Ptr {
		if val.IsNil() {
			return nil, false
		}
		val = val.Elem()
	}

	switch val.Kind() {
	case reflect.Slice, reflect.Array:
		result := make([]interface{}, val.Len())
		for i := 0; i < val.Len(); i++ {
			result[i] = val.Index(i).Interface()
		}
		return result, true
	default:
		return nil, false
	}
}