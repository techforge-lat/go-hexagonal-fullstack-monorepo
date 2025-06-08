package valid

import (
	"encoding/json"
	"reflect"

	"github.com/google/uuid"
	"gopkg.in/guregu/null.v4"
)

type ObjectSchema struct {
	baseSchema
	fields map[string]Schema
}

func Object(fields map[string]Schema) *ObjectSchema {
	return &ObjectSchema{
		baseSchema: baseSchema{},
		fields:     fields,
	}
}

func (o *ObjectSchema) Parse(value any) *Result {
	return o.parseWithPath(value, "")
}

func (o *ObjectSchema) parseWithPath(value any, path string) *Result {
	// Skip all validations for null library types that are not valid
	if isNullLibraryType(value) {
		return newResult(true, value, nil)
	}

	if o.optional && isNilOrEmpty(value) {
		return newResult(true, value, nil)
	}

	if errors := o.validateRequired(value, path); len(errors) > 0 {
		return newResult(false, nil, errors)
	}

	if isNilOrEmpty(value) && !o.required {
		return newResult(true, value, nil)
	}

	data, err := convertToMap(value)
	if err != nil {
		return newResult(false, nil, []ValidationError{{
			Path:    path,
			Message: getMessage(msgs.TypeObject),
			Code:    "type_error",
		}})
	}

	var allErrors []ValidationError
	validatedData := make(map[string]any)

	for fieldName, fieldSchema := range o.fields {
		fieldValue, exists := data[fieldName]
		fieldPath := fieldName
		if path != "" {
			fieldPath = path + "." + fieldName
		}

		// Check if the original value in the struct is a null library type that is not valid
		shouldSkipValidation := false
		originalValue := reflect.ValueOf(value)
		if originalValue.Kind() == reflect.Ptr {
			originalValue = originalValue.Elem()
		}
		if originalValue.Kind() == reflect.Struct {
			// Find struct field by JSON tag or field name
			structType := originalValue.Type()
			for i := 0; i < structType.NumField(); i++ {
				field := structType.Field(i)
				jsonTag := field.Tag.Get("json")
				structFieldName := field.Name
				
				if jsonTag != "" && jsonTag != "-" {
					if commaIndex := len(jsonTag); commaIndex > 0 {
						for j, r := range jsonTag {
							if r == ',' {
								commaIndex = j
								break
							}
						}
						structFieldName = jsonTag[:commaIndex]
					}
				}
				
				if structFieldName == fieldName {
					structFieldValue := originalValue.Field(i)
					if structFieldValue.CanInterface() {
						originalFieldValue := structFieldValue.Interface()
						if isNullLibraryType(originalFieldValue) {
							shouldSkipValidation = true
						}
					}
					break
				}
			}
		}
		
		if shouldSkipValidation {
			continue
		}

		var result *Result
		if stringSchema, ok := fieldSchema.(*StringSchema); ok {
			result = stringSchema.parseWithPath(fieldValue, fieldPath)
		} else if numberSchema, ok := fieldSchema.(*NumberSchema); ok {
			result = numberSchema.parseWithPath(fieldValue, fieldPath)
		} else if objectSchema, ok := fieldSchema.(*ObjectSchema); ok {
			result = objectSchema.parseWithPath(fieldValue, fieldPath)
		} else if arraySchema, ok := fieldSchema.(*ArraySchema); ok {
			result = arraySchema.parseWithPath(fieldValue, fieldPath)
		} else {
			result = fieldSchema.Parse(fieldValue)
			if len(result.Errors) > 0 {
				result.Errors = addPathPrefix(result.Errors, fieldPath)
			}
		}

		if result.HasErrors() {
			allErrors = append(allErrors, result.Errors...)
			continue
		}
		
		if exists || result.Data != nil {
			validatedData[fieldName] = result.Data
		}
	}

	errors := append(allErrors, o.validateCustom(validatedData, path)...)

	if len(errors) > 0 {
		return newResult(false, nil, errors)
	}

	return newResult(true, validatedData, nil)
}

func (o *ObjectSchema) Optional() Schema {
	o.baseSchema.setOptional()
	return o
}

func (o *ObjectSchema) Required() Schema {
	o.baseSchema.setRequired()
	return o
}

func (o *ObjectSchema) Custom(fn CustomValidatorFunc) Schema {
	o.baseSchema.addCustom(fn)
	return o
}

func convertToMap(value interface{}) (map[string]interface{}, error) {
	if value == nil {
		return nil, nil
	}

	switch v := value.(type) {
	case map[string]interface{}:
		return v, nil
	case map[string]string:
		result := make(map[string]interface{})
		for k, val := range v {
			result[k] = val
		}
		return result, nil
	default:
		val := reflect.ValueOf(value)
		if val.Kind() == reflect.Ptr {
			if val.IsNil() {
				return nil, nil
			}
			val = val.Elem()
		}

		if val.Kind() == reflect.Struct {
			return structToMap(value)
		}

		jsonBytes, err := json.Marshal(value)
		if err != nil {
			return nil, err
		}

		var result map[string]interface{}
		err = json.Unmarshal(jsonBytes, &result)
		return result, err
	}
}

func structToMap(value interface{}) (map[string]interface{}, error) {
	result := make(map[string]interface{})
	val := reflect.ValueOf(value)

	if val.Kind() == reflect.Ptr {
		val = val.Elem()
	}

	if val.Kind() != reflect.Struct {
		return nil, json.NewEncoder(nil).Encode(value)
	}

	typ := val.Type()
	for i := 0; i < val.NumField(); i++ {
		field := typ.Field(i)
		fieldValue := val.Field(i)

		if !fieldValue.CanInterface() {
			continue
		}

		jsonTag := field.Tag.Get("json")
		fieldName := field.Name

		if jsonTag != "" && jsonTag != "-" {
			if commaIndex := len(jsonTag); commaIndex > 0 {
				for j, r := range jsonTag {
					if r == ',' {
						commaIndex = j
						break
					}
				}
				fieldName = jsonTag[:commaIndex]
			}
		}

		fieldVal := fieldValue.Interface()
		// Extract primitive values from null types for validation
		switch v := fieldVal.(type) {
		case null.String:
			if v.Valid {
				result[fieldName] = v.String
			} else {
				result[fieldName] = nil
			}
		case null.Int:
			if v.Valid {
				result[fieldName] = v.Int64
			} else {
				result[fieldName] = nil
			}
		case null.Float:
			if v.Valid {
				result[fieldName] = v.Float64
			} else {
				result[fieldName] = nil
			}
		case null.Bool:
			if v.Valid {
				result[fieldName] = v.Bool
			} else {
				result[fieldName] = nil
			}
		case null.Time:
			if v.Valid {
				result[fieldName] = v.Time
			} else {
				result[fieldName] = nil
			}
		case uuid.NullUUID:
			if v.Valid {
				result[fieldName] = v.UUID
			} else {
				result[fieldName] = nil
			}
		default:
			result[fieldName] = fieldVal
		}
	}

	return result, nil
}

