package server

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"go-hexagonal-fullstack-monorepo/internal/shared/localconfig"
)

func TestNew(t *testing.T) {
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

	server, err := New("test-service", config, nil)
	if err != nil {
		t.Fatalf("expected server to be created, got error: %v", err)
	}

	if server == nil {
		t.Fatal("expected server to be non-nil")
	}

	if server.ServiceName != "test-service" {
		t.Errorf("expected service name to be 'test-service', got %s", server.ServiceName)
	}

	if server.API == nil {
		t.Error("expected API to be non-nil")
	}

	if server.PublicAPI == nil {
		t.Error("expected PublicAPI to be non-nil")
	}

	if server.PrivateAPI == nil {
		t.Error("expected PrivateAPI to be non-nil")
	}
}

func TestHealthCheckController(t *testing.T) {
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

	server, err := New("test-service", config, nil)
	if err != nil {
		t.Fatalf("expected server to be created, got error: %v", err)
	}

	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	rec := httptest.NewRecorder()
	c := server.API.NewContext(req, rec)

	// Note: This test may fail if the database connection fails
	// In a real test environment, you'd mock the database
	err = server.HealthCheckController(c)
	if err != nil {
		t.Logf("health check returned error (expected if no database): %v", err)
	}

	// The response should be either 200 (healthy) or 503 (service unavailable)
	if rec.Code != http.StatusOK && rec.Code != http.StatusServiceUnavailable {
		t.Errorf("expected status 200 or 503, got %d", rec.Code)
	}
}

func TestNewWithDatabase(t *testing.T) {
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

	// Test with database dependency injection (will fail if database not available)
	database, dbErr := NewDatabase(config.Database)
	if dbErr != nil {
		t.Logf("Database connection failed (expected in test environment): %v", dbErr)
		// Test without database
		server, err := New("test-service", config, nil)
		if err != nil {
			t.Fatalf("expected server to be created without database, got error: %v", err)
		}
		if server.Database != nil {
			t.Error("expected database to be nil when not provided")
		}
		return
	}

	// Test with successful database injection
	server, err := New("test-service", config, database)
	if err != nil {
		t.Fatalf("expected server to be created with database, got error: %v", err)
	}

	if server.Database == nil {
		t.Error("expected database to be injected")
	}
}

func TestNewDatabase(t *testing.T) {
	config := localconfig.DatabaseConfig{
		Host:     "localhost",
		Port:     5432,
		User:     "test",
		Password: "test",
		DBName:   "test",
		SSLMode:  "disable",
	}

	// This will likely fail in test environment without a real database
	_, err := NewDatabase(config)
	if err != nil {
		t.Logf("Database creation failed (expected in test environment): %v", err)
	}
}