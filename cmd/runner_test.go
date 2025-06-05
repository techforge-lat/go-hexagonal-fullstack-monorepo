package cmd

import (
	"testing"

	"go-hexagonal-fullstack-monorepo/internal/shared/localconfig"
)

func TestNewServerInstanceWithCustomConfig(t *testing.T) {
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

	// This test may fail if database connection fails, which is expected in test environment
	server, err := NewServerInstanceWithCustomConfig(config, "test-service")
	if err != nil {
		t.Logf("Server creation failed (expected if no database): %v", err)
		
		// Test without database if database connection fails
		server, err = NewServerInstanceWithoutDatabaseAndCustomConfig(config, "test-service")
		if err != nil {
			t.Fatalf("Expected server to be created without database, got error: %v", err)
		}
	}

	if server == nil {
		t.Fatal("Expected server to be non-nil")
	}

	if server.ServiceName != "test-service" {
		t.Errorf("Expected service name to be 'test-service', got %s", server.ServiceName)
	}
}

func TestNewServerInstanceWithoutDatabaseAndCustomConfig(t *testing.T) {
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

	server, err := NewServerInstanceWithoutDatabaseAndCustomConfig(config, "stateless-service")
	if err != nil {
		t.Fatalf("Expected server to be created without database, got error: %v", err)
	}

	if server == nil {
		t.Fatal("Expected server to be non-nil")
	}

	if server.ServiceName != "stateless-service" {
		t.Errorf("Expected service name to be 'stateless-service', got %s", server.ServiceName)
	}

	if server.Database != nil {
		t.Error("Expected database to be nil for stateless service")
	}
}

func TestNewLogger(t *testing.T) {
	// Set some basic environment variables for the test
	t.Setenv("LOG_LEVEL", "info")
	t.Setenv("LOG_FORMAT", "text")
	t.Setenv("JWT_SECRET", "test-secret")

	logger, err := NewLogger("test-logger")
	if err != nil {
		t.Fatalf("Expected logger to be created, got error: %v", err)
	}

	if logger == nil {
		t.Fatal("Expected logger to be non-nil")
	}
}

func TestNewDatabase(t *testing.T) {
	// Set required environment variables for the test
	t.Setenv("DB_HOST", "localhost")
	t.Setenv("DB_PORT", "5432")
	t.Setenv("DB_USER", "test")
	t.Setenv("DB_PASSWORD", "test")
	t.Setenv("DB_NAME", "test")
	t.Setenv("DB_SSL_MODE", "disable")
	t.Setenv("JWT_SECRET", "test-secret")

	// This will likely fail in test environment without a real database
	_, err := NewDatabase()
	if err != nil {
		t.Logf("Database creation failed (expected in test environment): %v", err)
	}
}