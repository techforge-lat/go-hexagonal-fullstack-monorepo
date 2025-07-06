package fault_test

import (
	"fmt"
	"api.system.soluciones-cloud.com/internal/shared/fault"
)

func ExampleWrap() {
	// Simulate a database error
	dbErr := fmt.Errorf("connection timeout")

	// Wrap the error with context
	err := fault.Wrap(dbErr).
		Code(fault.InternalError).
		Message("Failed to save user").
		Title("Database Connection Error")

	fmt.Printf("Error: %s\n", err.Error())
	fmt.Printf("HTTP Status: %d\n", err.HTTPStatus())
	fmt.Printf("Has Title: %t\n", err.HasTitle())

	// Output will vary due to stack trace, but structure will be:
	// Error: [stack=...] [code=internal_error] [error=Failed to save user: connection timeout]
	// HTTP Status: 500
	// Has Title: true
}

func ExampleError_chaining() {
	// Create a chain of errors
	originalErr := fmt.Errorf("network unreachable")

	// First wrap
	dbErr := fault.Wrap(originalErr).
		Code(fault.InternalError).
		Message("Database connection failed")

	// Second wrap (this will add to the stack)
	serviceErr := fault.Wrap(dbErr).
		Code(fault.BadRequest).
		Message("User service unavailable").
		Title("Service Error")

	fmt.Printf("Chained error: %s\n", serviceErr.Error())

	// Check if original error is in the chain
	if fault.Is(serviceErr, originalErr) {
		fmt.Println("Original error found in chain")
	}
}

func ExampleError_simple() {
	// Simple usage without all options
	err := fault.Wrap(fmt.Errorf("invalid input")).
		Message("Validation failed")

	fmt.Printf("Simple error: %s\n", err.Error())
	fmt.Printf("HTTP Status: %d\n", err.HTTPStatus()) // Will be 500 (default)
}
