# Valid - Zod-inspired Validation Library for Go

A powerful, developer-friendly validation library for Go inspired by [Zod](https://zod.dev/). Built with a focus on excellent developer experience, schema reusability, and user-friendly error messages.

## Features

- 🎯 **Zod-inspired Fluent API** - Chainable method syntax for intuitive schema definition
- 🌍 **Multi-language Support** - English and Spanish error messages for end users
- 🔗 **Schema Reusability** - Define once, use across create/update structs
- 📍 **Structured Errors** - Clear field paths for nested validation errors
- 🛠️ **Custom Validators** - Easy custom validation logic integration
- 🚀 **Zero Dependencies** - Self-contained library (except UUID validation)
- 💪 **Type Safety** - Leverages Go generics and interfaces

## Quick Start

```go
package main

import (
    "fmt"
    "your-project/internal/shared/valid"
)

func main() {
    // Define a reusable schema
    userSchema := valid.Object(map[string]valid.Schema{
        "email": valid.String().Email().Required(),
        "name":  valid.String().MinLength(2).Required(),
        "age":   valid.Int().Min(0).Max(150).Optional(),
    })

    // Validate data
    userData := map[string]interface{}{
        "email": "user@example.com",
        "name":  "John Doe",
        "age":   30,
    }

    result := userSchema.Parse(userData)
    if result.Success {
        fmt.Println("Valid data:", result.Data)
    } else {
        fmt.Println("Validation errors:", result.Error())
    }
}
```

## Schema Types

### String Validation

```go
// Basic string validation
valid.String().Required()
valid.String().Optional()

// Length constraints
valid.String().MinLength(5).MaxLength(100)
valid.String().Length(8, 20) // min and max

// Format validation
valid.String().Email()
valid.String().URL()
valid.String().UUID()
valid.String().Pattern(`^[A-Z][a-z]+$`) // regex pattern

// Example
emailSchema := valid.String().Email().Required()
```

### Number Validation

```go
// Basic number validation
valid.Number().Required()
valid.Int().Optional()

// Range constraints
valid.Int().Min(0).Max(100)
valid.Number().Range(0.0, 99.99)

// Type constraints
valid.Int().Positive()
valid.Number().Negative()
valid.Int().Integer() // ensures whole numbers

// Example
ageSchema := valid.Int().Min(0).Max(150).Required()
```

### Object Validation

```go
// Nested object validation
addressSchema := valid.Object(map[string]valid.Schema{
    "street": valid.String().Required(),
    "city":   valid.String().Required(),
    "zip":    valid.String().Pattern(`^\d{5}$`).Required(),
})

userSchema := valid.Object(map[string]valid.Schema{
    "name":    valid.String().Required(),
    "email":   valid.String().Email().Required(),
    "address": addressSchema.Required(),
})
```

### Array Validation

```go
// Array with item validation
tagsSchema := valid.Array(valid.String().MinLength(1))

// Array with size constraints
numbersSchema := valid.Array(valid.Int().Min(0)).MinItems(1).MaxItems(10)

// Example usage
result := tagsSchema.Parse([]string{"go", "validation", "library"})
```

## Custom Validation

Add custom validation logic easily:

```go
passwordValidator := func(value interface{}) error {
    str, ok := value.(string)
    if !ok {
        return errors.New("password must be text")
    }
    if len(str) < 8 {
        return errors.New("password must be at least 8 characters")
    }
    // Add more custom rules...
    return nil
}

passwordSchema := valid.String().Custom(passwordValidator).Required()
```

## Multi-language Support

Set the language for user-friendly error messages:

```go
// Set language (English is default)
valid.SetLanguage(valid.Spanish)

result := valid.String().Email().Required().Parse("")
if !result.Success {
    fmt.Println(result.Error()) // "Este campo es obligatorio"
}

valid.SetLanguage(valid.English)
result = valid.String().Email().Required().Parse("")
if !result.Success {
    fmt.Println(result.Error()) // "This field is required"
}
```

## Error Handling

The library provides structured error information:

```go
result := userSchema.Parse(invalidData)
if !result.Success {
    // Get all errors as a formatted string
    fmt.Println("Errors:", result.Error())
    
    // Access individual errors
    for _, err := range result.Errors {
        fmt.Printf("Field %s: %s (code: %s)\n", err.Path, err.Message, err.Code)
    }
    
    // Get errors for a specific field
    emailErrors := result.GetErrorsForField("email")
}
```

## Schema Reusability

Perfect for create/update scenarios where you need different validation for the same data structure:

```go
// Base schema with common validation rules
baseUserSchema := valid.Object(map[string]valid.Schema{
    "email": valid.String().Email().Required(),
    "name":  valid.String().MinLength(2).Required(),
})

// Use with different struct types
type CreateUser struct {
    Email string `json:"email"`
    Name  string `json:"name"`
}

type UpdateUser struct {
    Email *string `json:"email"` // optional for updates
    Name  *string `json:"name"`  // optional for updates
}

// Same schema works for both
createResult := baseUserSchema.Parse(createUserData)
updateResult := baseUserSchema.Parse(updateUserData)
```

## API Reference

### Core Methods

All schema types support these methods:

- `.Required()` - Mark field as required
- `.Optional()` - Mark field as optional
- `.Custom(fn)` - Add custom validation function
- `.Parse(value)` - Validate and parse the value

### String Methods

- `.MinLength(n)` - Minimum length constraint
- `.MaxLength(n)` - Maximum length constraint
- `.Length(min, max)` - Both min and max length
- `.Email()` - Email format validation
- `.URL()` - URL format validation
- `.UUID()` - UUID format validation
- `.Pattern(regex)` - Regular expression validation

### Number Methods

- `.Min(n)` - Minimum value constraint
- `.Max(n)` - Maximum value constraint
- `.Range(min, max)` - Both min and max value
- `.Positive()` - Must be positive
- `.Negative()` - Must be negative
- `.Integer()` - Must be whole number

### Array Methods

- `.MinItems(n)` - Minimum number of items
- `.MaxItems(n)` - Maximum number of items
- `.Length(min, max)` - Both min and max items

### Result Methods

- `.Success` - Boolean indicating if validation passed
- `.Data` - The validated data (if successful)
- `.Errors` - Array of validation errors
- `.Error()` - Formatted error string
- `.HasErrors()` - Boolean indicating if there are errors
- `.GetErrorsForField(field)` - Get errors for specific field

## Supported Languages

- **English** (`valid.English`) - Default
- **Spanish** (`valid.Spanish`)

Error messages are designed to be user-friendly and non-technical, suitable for showing directly to end users.

## Best Practices

1. **Define schemas once** - Create reusable schemas for your data structures
2. **Chain methods properly** - Call specific validation methods before `.Required()` or `.Optional()`
3. **Use custom validators** - Add business-specific validation logic
4. **Handle errors gracefully** - Provide clear feedback to users
5. **Set appropriate language** - Use the user's preferred language for error messages

## Examples

Check out the `examples_test.go` file for comprehensive usage examples and patterns.