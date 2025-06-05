package main

import (
	"go-hexagonal-fullstack-monorepo/cmd"
	"go-hexagonal-fullstack-monorepo/cmd/api/router"
	"log"
)

const serviceName = "api"

// Run starts the API server with default configuration from environment variables
func Run() {
	server, err := cmd.NewServerInstance(serviceName)
	if err != nil {
		log.Fatalf("Failed to create server: %v", err)
	}

	if err := router.SetAPIRoutes(server); err != nil {
		log.Fatalf("Failed to setup routes: %v", err)
	}

	// Start server with graceful shutdown
	if err := server.Start(); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
