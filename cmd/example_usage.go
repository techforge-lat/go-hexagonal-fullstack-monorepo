package cmd

import (
	"log"

	"github.com/labstack/echo/v4"
	"go-hexagonal-fullstack-monorepo/internal/shared/http/server/response"
	"go-hexagonal-fullstack-monorepo/internal/shared/localconfig"
)

// ExampleAPIService demonstrates how to create a complete API service
func ExampleAPIService() {
	// Create server with database
	server, err := NewServerInstance("my-api-service")
	if err != nil {
		log.Fatalf("Failed to create server: %v", err)
	}

	// Add public routes
	server.PublicAPI.GET("/users", func(c echo.Context) error {
		// Example: Get users from database
		users := []map[string]any{
			{"id": 1, "name": "John Doe", "email": "john@example.com"},
			{"id": 2, "name": "Jane Smith", "email": "jane@example.com"},
		}
		
		resp := response.Ok(users)
		return c.JSON(resp.GetStatus(), resp)
	})

	server.PublicAPI.POST("/users", func(c echo.Context) error {
		// Example: Create new user
		var user map[string]any
		if err := c.Bind(&user); err != nil {
			resp := response.BadRequest().Detail("Invalid request body")
			return c.JSON(resp.GetStatus(), resp)
		}

		// Add user logic here...
		user["id"] = 123 // Mock ID

		resp := response.Created(user)
		return c.JSON(resp.GetStatus(), resp)
	})

	// Add protected routes (would require JWT middleware)
	server.PrivateAPI.DELETE("/users/:id", func(c echo.Context) error {
		userID := c.Param("id")
		
		// Delete user logic here...
		
		resp := response.Ok(map[string]string{
			"message": "User deleted successfully",
			"user_id": userID,
		})
		return c.JSON(resp.GetStatus(), resp)
	})

	// Start server
	if err := server.Start(); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}

// ExampleStatelessService demonstrates how to create a stateless service without database
func ExampleStatelessService() {
	// Create server without database
	server, err := NewServerInstanceWithoutDatabase("gateway-service")
	if err != nil {
		log.Fatalf("Failed to create server: %v", err)
	}

	// Add routes for a stateless service
	server.PublicAPI.GET("/ping", func(c echo.Context) error {
		resp := response.Ok(map[string]string{"message": "pong"})
		return c.JSON(resp.GetStatus(), resp)
	})

	server.PublicAPI.GET("/version", func(c echo.Context) error {
		resp := response.Ok(map[string]string{
			"version": "1.0.0",
			"service": "gateway-service",
		})
		return c.JSON(resp.GetStatus(), resp)
	})

	// Start server
	if err := server.Start(); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}

// ExampleCustomConfiguration demonstrates how to use custom configuration for testing
func ExampleCustomConfiguration() {
	// This would typically be used in tests
	config := &localconfig.Config{
		Database: localconfig.DatabaseConfig{
			Host:     "test-db",
			Port:     5432,
			User:     "testuser",
			Password: "testpass",
			DBName:   "testdb",
			SSLMode:  "disable",
		},
		HTTP: localconfig.HTTPConfig{
			Port:           3000,
			AllowedOrigins: []string{"http://localhost:3000"},
			AllowedMethods: []string{"GET", "POST"},
		},
		JWT: localconfig.JWTConfig{
			Secret: "test-jwt-secret",
		},
		Logger: localconfig.LoggerConfig{
			Level:     "debug",
			Format:    "json",
			AddSource: true,
		},
		OTEL: localconfig.OTELConfig{
			CollectorEndpoint: "localhost:4318",
			Environment:       "testing",
		},
	}

	server, err := NewServerInstanceWithCustomConfig(config, "test-service")
	if err != nil {
		log.Fatalf("Failed to create server with custom config: %v", err)
	}

	// Add test routes...
	server.PublicAPI.GET("/test", func(c echo.Context) error {
		resp := response.Ok(map[string]string{"status": "testing"})
		return c.JSON(resp.GetStatus(), resp)
	})

	// In tests, you might not call Start() but instead use httptest
	_ = server
}

// ExampleStandaloneComponents demonstrates how to use individual components
func ExampleStandaloneComponents() {
	// Create logger independently
	logger, err := NewLogger("standalone-service")
	if err != nil {
		log.Fatalf("Failed to create logger: %v", err)
	}

	logger.Info("Starting standalone service")

	// Create database connection independently
	database, err := NewDatabase()
	if err != nil {
		logger.Error("Failed to create database connection", "error", err.Error())
		return
	}

	logger.Info("Database connected successfully")

	// Use components as needed...
	_ = database
}