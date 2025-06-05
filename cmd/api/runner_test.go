package main

import (
	"go-hexagonal-fullstack-monorepo/cmd"
	"go-hexagonal-fullstack-monorepo/cmd/api/router"
	"go-hexagonal-fullstack-monorepo/internal/shared/http/server"
	"go-hexagonal-fullstack-monorepo/internal/shared/localconfig"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestRunnerWithCustomConfig(t *testing.T) {
	config := &localconfig.Config{
		Database: localconfig.DatabaseConfig{
			Host:     "localhost",
			Port:     5432,
			User:     "test",
			Password: "test",
			DBName:   "test",
			SSLMode:  "disable",
		},
		HTTP: localconfig.HTTPConfig{
			Port:           8080,
			AllowedOrigins: []string{"*"},
			AllowedMethods: []string{"GET", "POST", "PUT", "DELETE"},
		},
		JWT: localconfig.JWTConfig{
			Secret: "test-secret",
		},
		Logger: localconfig.LoggerConfig{
			Level:     "info",
			Format:    "text",
			AddSource: false,
		},
		OTEL: localconfig.OTELConfig{
			CollectorEndpoint: "localhost:4318",
			Environment:       "test",
		},
	}

	// Test creating server with custom config (without starting it)
	server, err := cmd.NewServerInstanceWithCustomConfig(config, serviceName)
	if err != nil {
		// If database connection fails, try without database
		server, err = cmd.NewServerInstanceWithoutDatabaseAndCustomConfig(config, serviceName)
		if err != nil {
			t.Fatalf("Failed to create server: %v", err)
		}
	}

	// Setup routes
	if err := router.SetAPIRoutes(server); err != nil {
		t.Fatalf("Failed to setup routes: %v", err)
	}

	// Test that health endpoint is working
	testHealthEndpoint(t, server)
}

func TestRunnerWithoutDatabase(t *testing.T) {
	config := &localconfig.Config{
		Database: localconfig.DatabaseConfig{
			Host:     "localhost",
			Port:     5432,
			User:     "test",
			Password: "test",
			DBName:   "test",
			SSLMode:  "disable",
		},
		HTTP: localconfig.HTTPConfig{
			Port:           8080,
			AllowedOrigins: []string{"*"},
			AllowedMethods: []string{"GET", "POST", "PUT", "DELETE"},
		},
		JWT: localconfig.JWTConfig{
			Secret: "test-secret",
		},
		Logger: localconfig.LoggerConfig{
			Level:     "info",
			Format:    "text",
			AddSource: false,
		},
		OTEL: localconfig.OTELConfig{
			CollectorEndpoint: "localhost:4318",
			Environment:       "test",
		},
	}

	// Create server without database
	server, err := cmd.NewServerInstanceWithoutDatabaseAndCustomConfig(config, serviceName)
	if err != nil {
		t.Fatalf("Failed to create stateless server: %v", err)
	}

	// Setup stateless routes
	if err := router.SetStatelessAPIRoutes(server); err != nil {
		t.Fatalf("Failed to setup stateless routes: %v", err)
	}

	// Test health endpoint
	testHealthEndpoint(t, server)
}

func testHealthEndpoint(t *testing.T, server *server.Server) {
	// Test the health endpoint that's automatically added by the server
	req := httptest.NewRequest("GET", "/api/v1/health", nil)
	rec := httptest.NewRecorder()

	server.API.ServeHTTP(rec, req)

	// Health endpoint should return 200 (healthy) or 503 (service unavailable)
	if rec.Code != http.StatusOK && rec.Code != http.StatusServiceUnavailable {
		t.Errorf("Expected status 200 or 503, got %d for GET /api/v1/health", rec.Code)
	}
}

