package main

import (
	"go-hexagonal-fullstack-monorepo/cmd"
	"go-hexagonal-fullstack-monorepo/cmd/api/router"
	"go-hexagonal-fullstack-monorepo/internal/shared/localconfig"
	"log"
)

const serviceName = "api-service"

// Run starts the API server with default configuration from environment variables
func Run() {
	// Create server instance with database
	server, err := cmd.NewServerInstance(serviceName)
	if err != nil {
		log.Fatalf("Failed to create server: %v", err)
	}

	// Setup API routes
	if err := router.SetAPIRoutes(server); err != nil {
		log.Fatalf("Failed to setup routes: %v", err)
	}

	// Start server with graceful shutdown
	if err := server.Start(); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}

// RunWithCustomConfig starts the API server with custom configuration.
// This is useful for testing purposes where you want to inject specific settings.
func RunWithCustomConfig(config *localconfig.Config) {
	// Create server instance with custom config
	server, err := cmd.NewServerInstanceWithCustomConfig(config, serviceName)
	if err != nil {
		log.Fatalf("Failed to create server with custom config: %v", err)
	}

	// Setup API routes
	if err := router.SetAPIRoutes(server); err != nil {
		log.Fatalf("Failed to setup routes: %v", err)
	}

	// Start server with graceful shutdown
	if err := server.Start(); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}

// RunWithoutDatabase starts the API server without database connection.
// This is useful for stateless API services or when database is not required.
func RunWithoutDatabase() {
	// Create server instance without database
	server, err := cmd.NewServerInstanceWithoutDatabase(serviceName)
	if err != nil {
		log.Fatalf("Failed to create stateless server: %v", err)
	}

	// Setup API routes (only routes that don't require database)
	if err := router.SetStatelessAPIRoutes(server); err != nil {
		log.Fatalf("Failed to setup stateless routes: %v", err)
	}

	// Start server with graceful shutdown
	if err := server.Start(); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
