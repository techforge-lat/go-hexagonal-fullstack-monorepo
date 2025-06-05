package response_test

import (
	"encoding/json"
	"fmt"
	"go-hexagonal-fullstack-monorepo/internal/shared/fault"
	"go-hexagonal-fullstack-monorepo/internal/shared/http/server/response"
	"log"
)

func ExampleOk() {
	// Create a successful response with data
	response := response.Ok(map[string]string{
		"message": "Hello, World!",
		"user_id": "123",
	})

	jsonData, _ := json.MarshalIndent(response, "", "  ")
	fmt.Printf("Success Response:\n%s\n", jsonData)

	// Output:
	// Success Response:
	// {
	//   "type": "about:blank",
	//   "status": 200,
	//   "data": {
	//     "message": "Hello, World!",
	//     "user_id": "123"
	//   }
	// }
}

func ExampleFromError() {
	// Create a fault error
	dbErr := fmt.Errorf("connection timeout")
	faultErr := fault.Wrap(dbErr).
		Code(fault.BadRequest).
		Message("Failed to save user data").
		Title("Database Error")

	// Convert to RFC 9457 response
	response := response.FromError(faultErr)

	jsonData, _ := json.MarshalIndent(response, "", "  ")
	fmt.Printf("Error Response:\n%s\n", jsonData)

	fmt.Printf("\nHTTP Status: %d\n", response.GetStatus())
	fmt.Printf("Is Error: %t\n", response.IsError())
}

func ExampleNew() {
	// Build a custom response
	response := response.New().
		Type("https://example.com/probs/user-validation").
		Title("User Validation Failed").
		Detail("The provided email address is already registered").
		Status(422).
		Instance("/users/register").
		Extension("field", "email").
		Extension("trace_id", "abc123def456")

	jsonData, _ := json.MarshalIndent(response, "", "  ")
	fmt.Printf("Custom Response:\n%s\n", jsonData)

	// Output:
	// Custom Response:
	// {
	//   "type": "https://example.com/probs/user-validation",
	//   "title": "User Validation Failed",
	//   "detail": "The provided email address is already registered",
	//   "status": 422,
	//   "instance": "/users/register",
	//   "field": "email",
	//   "trace_id": "abc123def456"
	// }
}

func ExampleCreated() {
	// Create a 201 Created response
	newUser := map[string]any{
		"id":    "user_123",
		"name":  "John Doe",
		"email": "john@example.com",
	}

	response := response.Created(newUser)

	jsonData, _ := json.MarshalIndent(response, "", "  ")
	fmt.Printf("Created Response:\n%s\n", jsonData)

	// Output:
	// Created Response:
	// {
	//   "type": "about:blank",
	//   "title": "Resource Created",
	//   "detail": "The resource was successfully created",
	//   "status": 201,
	//   "data": {
	//     "id": "user_123",
	//     "name": "John Doe",
	//     "email": "john@example.com"
	//   }
	// }
}

func ExampleNotFound() {
	// Create a 404 Not Found response
	response := response.NotFound().
		Detail("The user with ID '999' does not exist").
		Instance("/users/999")

	jsonData, _ := json.MarshalIndent(response, "", "  ")
	fmt.Printf("Not Found Response:\n%s\n", jsonData)

	// Output:
	// Not Found Response:
	// {
	//   "type": "about:blank",
	//   "title": "Resource Not Found",
	//   "detail": "The user with ID '999' does not exist",
	//   "status": 404,
	//   "instance": "/users/999"
	// }
}

func ExampleResponse_Extension() {
	// Create a response with multiple extensions
	response := response.BadRequest().
		Detail("Invalid JSON format in request body").
		Extension("error_code", "JSON_PARSE_ERROR").
		Extension("line", 15).
		Extension("column", 23).
		Extension("timestamp", "2024-01-15T10:30:00Z")

	jsonData, _ := json.MarshalIndent(response, "", "  ")
	fmt.Printf("Response with Extensions:\n%s\n", jsonData)

	// Output:
	// Response with Extensions:
	// {
	//   "type": "about:blank",
	//   "title": "Bad Request",
	//   "detail": "Invalid JSON format in request body",
	//   "status": 400,
	//   "error_code": "JSON_PARSE_ERROR",
	//   "line": 15,
	//   "column": 23,
	//   "timestamp": "2024-01-15T10:30:00Z"
	// }
}

func ExampleIntegrationWithFault() {
	// Simulate a service that might fail
	user, err := getUserFromDatabase("123")
	if err != nil {
		// Create fault error with context
		faultErr := fault.Wrap(err).
			Code(fault.NotFound).
			Message("User not found in database").
			Title("User Lookup Failed")

		// Convert to API response
		response := response.FromError(faultErr)

		// In a real HTTP handler, you would:
		// w.Header().Set("Content-Type", "application/problem+json")
		// w.WriteHeader(response.GetStatus())
		// json.NewEncoder(w).Encode(response)

		jsonData, _ := json.MarshalIndent(response, "", "  ")
		fmt.Printf("Integrated Error Response:\n%s\n", jsonData)
		return
	}

	// Success case
	response := response.Ok(user)
	jsonData, _ := json.MarshalIndent(response, "", "  ")
	fmt.Printf("Success Response:\n%s\n", jsonData)
}

// Mock function to simulate database interaction
func getUserFromDatabase(id string) (map[string]any, error) {
	if id == "123" {
		return nil, fmt.Errorf("user not found")
	}
	return map[string]any{
		"id":   id,
		"name": "John Doe",
	}, nil
}

func Example_httpHandler() {
	// Example of how to use in an HTTP handler
	// This would typically be in your HTTP handler

	faultErr := fault.Wrap(fmt.Errorf("database timeout")).
		Code(fault.InternalError).
		Message("Failed to process request").
		Title("Service Unavailable")

	response := response.FromError(faultErr)

	// Set content type for RFC 9457
	// w.Header().Set("Content-Type", "application/problem+json")
	// w.WriteHeader(response.GetStatus())
	// json.NewEncoder(w).Encode(response)

	log.Printf("Would return status %d with response", response.GetStatus())
}
