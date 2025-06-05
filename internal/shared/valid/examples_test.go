package valid

import (
	"errors"
)

func Example() {
	userSchema := Object(map[string]Schema{
		"email": String().Email().Required(),
		"name":  String().MinLength(2).Required(),
		"age":   Int().Min(0).Max(150).Optional(),
	})

	validData := map[string]interface{}{
		"email": "user@example.com",
		"name":  "John Doe",
		"age":   30,
	}

	result := userSchema.Parse(validData)
	if result.Success {
		// Data is valid
		_ = result.Data
	}

	invalidData := map[string]interface{}{
		"email": "invalid-email",
		"name":  "J",
		"age":   200,
	}

	result = userSchema.Parse(invalidData)
	if !result.Success {
		for _, err := range result.Errors {
			_ = err.Path + ": " + err.Message
		}
	}
}

func ExampleSetLanguage() {
	SetLanguage(Spanish)

	result := String().Email().Required().Parse("")
	if !result.Success {
		_ = result.Error() // "Este campo es obligatorio"
	}

	SetLanguage(English)
	result = String().Email().Required().Parse("")
	if !result.Success {
		_ = result.Error() // "This field is required"
	}
}

func ExampleStringSchema_Custom() {
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
	if !result.Success {
		_ = result.Error()
	}
}

func ExampleObject() {
	addressSchema := Object(map[string]Schema{
		"street": String().Required(),
		"city":   String().Required(),
		"zip":    String().Pattern(`^\d{5}$`).Required(),
	})

	userSchema := Object(map[string]Schema{
		"name":    String().Required(),
		"email":   String().Email().Required(),
		"address": addressSchema.Required(),
	})

	data := map[string]interface{}{
		"name":  "John Doe",
		"email": "john@example.com",
		"address": map[string]interface{}{
			"street": "123 Main St",
			"city":   "Anytown",
			"zip":    "12345",
		},
	}

	result := userSchema.Parse(data)
	_ = result.Success
}

func ExampleArray() {
	tagsSchema := Array(String().MinLength(1))
	numbersSchema := Array(Int().Min(0)).MinItems(1).MaxItems(10)

	result1 := tagsSchema.Parse([]string{"go", "validation", "library"})
	_ = result1.Success

	result2 := numbersSchema.Parse([]int{1, 2, 3, 4, 5})
	_ = result2.Success
}

func ExampleObject_reusingSchemas() {
	baseUserSchema := Object(map[string]Schema{
		"email": String().Email().Required(),
		"name":  String().MinLength(2).Required(),
	})

	type CreateUser struct {
		Email string `json:"email"`
		Name  string `json:"name"`
	}

	type UpdateUser struct {
		Email *string `json:"email"`
		Name  *string `json:"name"`
	}

	createUser := CreateUser{
		Email: "user@example.com",
		Name:  "John Doe",
	}

	updateUser := UpdateUser{
		Email: stringPtr("newemail@example.com"),
	}

	result1 := baseUserSchema.Parse(createUser)
	result2 := baseUserSchema.Parse(updateUser)

	_, _ = result1.Success, result2.Success
}

func stringPtr(s string) *string {
	return &s
}