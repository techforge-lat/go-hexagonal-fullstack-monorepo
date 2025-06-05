package server

import (
	"go-hexagonal-fullstack-monorepo/internal/shared/localconfig"
	"go-hexagonal-fullstack-monorepo/internal/shared/repository/postgres"
	"log"

	"github.com/labstack/echo/v4"
)

// ExampleUsage demonstrates how to properly initialize the server with dependency injection
func ExampleUsage() {
	// 1. Load configuration
	config, err := localconfig.LoadConfig()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// 2. Create database connection (dependency injection)
	database, err := postgres.New(config.Database)
	if err != nil {
		log.Fatalf("Failed to create database connection: %v", err)
	}

	// 3. Create server with injected dependencies
	server, err := New("my-service", config, database)
	if err != nil {
		log.Fatalf("Failed to create server: %v", err)
	}

	// 4. Add your routes
	server.PublicAPI.GET("/users", func(c echo.Context) error {
		// Your handler implementation
		return c.JSON(200, map[string]string{"message": "Hello, World!"})
	})

	server.PrivateAPI.POST("/admin/users", func(c echo.Context) error {
		// Your protected handler implementation
		return c.JSON(201, map[string]string{"message": "User created"})
	})

	// 5. Start server with graceful shutdown
	if err := server.Start(); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}

// ExampleUsageWithoutDatabase demonstrates how to create a server without database
func ExampleUsageWithoutDatabase() {
	// For services that don't need a database
	config, err := localconfig.LoadConfig()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// Create server without database (pass nil)
	server, err := New("stateless-service", config, nil)
	if err != nil {
		log.Fatalf("Failed to create server: %v", err)
	}

	// Add routes
	server.PublicAPI.GET("/ping", func(c echo.Context) error {
		return c.JSON(200, map[string]string{"message": "pong"})
	})

	// Start server
	if err := server.Start(); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}

// ExampleUsageWithMockDatabase demonstrates how to inject a mock database for testing
func ExampleUsageWithMockDatabase() {
	config, _ := localconfig.LoadConfig()

	// In tests, you would create a mock database instead
	// mockDB := &MockDatabase{} // your mock implementation

	// For this example, we'll use nil to demonstrate the pattern
	server, err := New("test-service", config, nil)
	if err != nil {
		log.Fatalf("Failed to create server: %v", err)
	}

	// The server will handle nil database gracefully
	// Health check will return healthy status without database checks
	_ = server
}
