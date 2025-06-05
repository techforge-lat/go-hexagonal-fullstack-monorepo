package valid

import (
	"errors"
	"testing"
)

func TestBasicValidation(t *testing.T) {
	schema := String().MinLength(3).Required()
	
	result := schema.Parse("hello")
	if !result.Success {
		t.Errorf("Expected validation to pass, got errors: %v", result.Errors)
	}
	
	result = schema.Parse("hi")
	if result.Success {
		t.Error("Expected validation to fail for short string")
	}
	
	result = schema.Parse("")
	if result.Success {
		t.Error("Expected validation to fail for required empty string")
	}
}

func TestNumberValidation(t *testing.T) {
	schema := Int().Min(0).Max(100).Required()
	
	result := schema.Parse(50)
	if !result.Success {
		t.Errorf("Expected validation to pass, got errors: %v", result.Errors)
	}
	
	result = schema.Parse(-5)
	if result.Success {
		t.Error("Expected validation to fail for number below minimum")
	}
	
	result = schema.Parse(150)
	if result.Success {
		t.Error("Expected validation to fail for number above maximum")
	}
}

func TestObjectValidation(t *testing.T) {
	schema := Object(map[string]Schema{
		"name":  String().Required(),
		"age":   Int().Min(0).Optional(),
		"email": String().Email().Required(),
	})
	
	validData := map[string]interface{}{
		"name":  "John",
		"age":   25,
		"email": "john@example.com",
	}
	
	result := schema.Parse(validData)
	if !result.Success {
		t.Errorf("Expected validation to pass, got errors: %v", result.Errors)
	}
	
	invalidData := map[string]interface{}{
		"name":  "",
		"age":   -5,
		"email": "invalid-email",
	}
	
	result = schema.Parse(invalidData)
	if result.Success {
		t.Error("Expected validation to fail for invalid data")
	}
	
	if len(result.Errors) == 0 {
		t.Error("Expected validation errors")
	}
}

func TestLanguageSupport(t *testing.T) {
	SetLanguage(English)
	result := String().Required().Parse("")
	englishMessage := result.Error()
	
	SetLanguage(Spanish)
	result = String().Required().Parse("")
	spanishMessage := result.Error()
	
	if englishMessage == spanishMessage {
		t.Error("Expected different messages for different languages")
	}
	
	SetLanguage(English)
}

func TestCustomValidation(t *testing.T) {
	passwordValidator := func(value interface{}) error {
		str, ok := value.(string)
		if !ok {
			return errors.New("password must be a string")
		}
		if len(str) < 8 {
			return errors.New("password must be at least 8 characters")
		}
		return nil
	}

	schema := String().Custom(passwordValidator).Required()
	result := schema.Parse("123")
	if result.Success {
		t.Error("Expected validation to fail for short password")
	}

	result = schema.Parse("password123")
	if !result.Success {
		t.Errorf("Expected validation to pass, got errors: %v", result.Errors)
	}
}

func TestArrayValidation(t *testing.T) {
	schema := Array(String().MinLength(1)).MinItems(1).MaxItems(3)
	
	result := schema.Parse([]string{"hello", "world"})
	if !result.Success {
		t.Errorf("Expected validation to pass, got errors: %v", result.Errors)
	}
	
	result = schema.Parse([]string{})
	if result.Success {
		t.Errorf("Expected validation to fail for empty array, got: %+v", result)
	}
	
	result = schema.Parse([]string{"a", "b", "c", "d"})
	if result.Success {
		t.Error("Expected validation to fail for array with too many items")
	}
}