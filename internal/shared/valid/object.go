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
		fieldPath := o.buildFieldPath(path, fieldName)

		if o.shouldSkipFieldValidation(value, fieldName) {
			continue
		}

		result := o.validateField(fieldSchema, fieldValue, fieldPath)

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

func (o *ObjectSchema) buildFieldPath(path, fieldName string) string {
	if path == "" {
		return fieldName
	}
	return path + "." + fieldName
}

func (o *ObjectSchema) shouldSkipFieldValidation(value any, fieldName string) bool {
	originalValue := reflect.ValueOf(value)
	if originalValue.Kind() == reflect.Ptr {
		originalValue = originalValue.Elem()
	}

	if originalValue.Kind() != reflect.Struct {
		return false
	}

	return o.findStructFieldAndCheckNull(originalValue, fieldName)
}

func (o *ObjectSchema) findStructFieldAndCheckNull(originalValue reflect.Value, fieldName string) bool {
	structType := originalValue.Type()

	for i := range structType.NumField() {
		field := structType.Field(i)
		structFieldName := o.getFieldName(field)

		if structFieldName != fieldName {
			continue
		}

		structFieldValue := originalValue.Field(i)
		if !structFieldValue.CanInterface() {
			return false
		}

		originalFieldValue := structFieldValue.Interface()
		return isNullLibraryType(originalFieldValue)
	}

	return false
}

func (o *ObjectSchema) getFieldName(field reflect.StructField) string {
	jsonTag := field.Tag.Get("json")
	if jsonTag == "" || jsonTag == "-" {
		return field.Name
	}

	// Extract field name before comma
	for i, r := range jsonTag {
		if r == ',' {
			return jsonTag[:i]
		}
	}

	return jsonTag
}

func (o *ObjectSchema) validateField(fieldSchema Schema, fieldValue any, fieldPath string) *Result {
	switch schema := fieldSchema.(type) {
	case *StringSchema:
		return schema.parseWithPath(fieldValue, fieldPath)
	case *NumberSchema:
		return schema.parseWithPath(fieldValue, fieldPath)
	case *ObjectSchema:
		return schema.parseWithPath(fieldValue, fieldPath)
	case *ArraySchema:
		return schema.parseWithPath(fieldValue, fieldPath)
	default:
		result := fieldSchema.Parse(fieldValue)
		if len(result.Errors) > 0 {
			result.Errors = addPathPrefix(result.Errors, fieldPath)
		}
		return result
	}
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

func convertToMap(value any) (map[string]any, error) {
	if value == nil {
		return nil, nil
	}

	switch v := value.(type) {
	case map[string]any:
		return v, nil
	case map[string]string:
		result := make(map[string]any)
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

		var result map[string]any
		err = json.Unmarshal(jsonBytes, &result)
		return result, err
	}
}

func structToMap(value any) (map[string]any, error) {
	result := make(map[string]any)
	val := reflect.ValueOf(value)

	if val.Kind() == reflect.Ptr {
		val = val.Elem()
	}

	if val.Kind() != reflect.Struct {
		return nil, json.NewEncoder(nil).Encode(value)
	}

	typ := val.Type()
	for i := range val.NumField() {
		field := typ.Field(i)
		fieldValue := val.Field(i)

		if !fieldValue.CanInterface() {
			continue
		}

		fieldName := getJSONFieldName(field)
		fieldVal := fieldValue.Interface()
		result[fieldName] = extractNullValue(fieldVal)
	}

	return result, nil
}

func getJSONFieldName(field reflect.StructField) string {
	jsonTag := field.Tag.Get("json")
	if jsonTag == "" || jsonTag == "-" {
		return field.Name
	}

	// Extract field name before comma
	for i, r := range jsonTag {
		if r == ',' {
			return jsonTag[:i]
		}
	}

	return jsonTag
}

func extractNullValue(fieldVal any) any {
	switch v := fieldVal.(type) {
	case null.String:
		if v.Valid {
			return v.String
		}
		return nil
	case null.Int:
		if v.Valid {
			return v.Int64
		}
		return nil
	case null.Float:
		if v.Valid {
			return v.Float64
		}
		return nil
	case null.Bool:
		if v.Valid {
			return v.Bool
		}
		return nil
	case null.Time:
		if v.Valid {
			return v.Time
		}
		return nil
	case uuid.NullUUID:
		if v.Valid {
			return v.UUID
		}
		return nil
	default:
		return fieldVal
	}
}
