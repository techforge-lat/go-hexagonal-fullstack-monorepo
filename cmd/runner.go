package cmd

import (
	"go-hexagonal-fullstack-monorepo/internal/shared/fault"
	"go-hexagonal-fullstack-monorepo/internal/shared/http/server"
	"go-hexagonal-fullstack-monorepo/internal/shared/localconfig"
	"go-hexagonal-fullstack-monorepo/internal/shared/logger"
	"go-hexagonal-fullstack-monorepo/internal/shared/repository/postgres"
)

// NewServerInstance creates a server instance with default configuration loading.
// It loads configuration from environment variables and creates all necessary dependencies.
func NewServerInstance(serviceName string) (*server.Server, error) {
	config, err := localconfig.LoadConfig()
	if err != nil {
		return nil, fault.Wrap(err)
	}

	return NewServerInstanceWithCustomConfig(config, serviceName)
}

// NewServerInstanceWithCustomConfig creates a server instance with the provided configuration.
// This function is useful for testing purposes where you want to inject custom configuration.
func NewServerInstanceWithCustomConfig(config *localconfig.Config, serviceName string) (*server.Server, error) {
	// Create database connection
	database, err := postgres.New(config.Database)
	if err != nil {
		return nil, fault.Wrap(err)
	}

	// Create server with injected dependencies
	srv, err := server.New(serviceName, config, database)
	if err != nil {
		return nil, fault.Wrap(err)
	}

	return srv, nil
}

// NewLogger creates a new logger instance with the provided service name.
// This function can be used independently when you only need logging capabilities.
func NewLogger(serviceName string) (*logger.Logger, error) {
	config, err := localconfig.LoadConfig()
	if err != nil {
		return nil, fault.Wrap(err)
	}

	appLogger := logger.NewFromConfig(config.Logger).With("service", serviceName)
	return appLogger, nil
}

// NewServerInstanceWithoutDatabase creates a server instance without database connection.
// This is useful for stateless services or services that don't require database access.
func NewServerInstanceWithoutDatabase(serviceName string) (*server.Server, error) {
	config, err := localconfig.LoadConfig()
	if err != nil {
		return nil, fault.Wrap(err)
	}

	return NewServerInstanceWithoutDatabaseAndCustomConfig(config, serviceName)
}

// NewServerInstanceWithoutDatabaseAndCustomConfig creates a server instance without database
// using the provided configuration. Useful for testing stateless services.
func NewServerInstanceWithoutDatabaseAndCustomConfig(config *localconfig.Config, serviceName string) (*server.Server, error) {
	// Create server without database (nil dependency)
	srv, err := server.New(serviceName, config, nil)
	if err != nil {
		return nil, fault.Wrap(err)
	}

	return srv, nil
}

// NewDatabase creates a new database connection using the default configuration.
// This function can be used independently when you only need database access.
func NewDatabase() (*postgres.Adapter, error) {
	config, err := localconfig.LoadConfig()
	if err != nil {
		return nil, fault.Wrap(err)
	}

	return postgres.New(config.Database)
}
