package shared

import (
	"context"
	"database/sql"
	"fmt"
	"io/ioutil"
	"path/filepath"
	"time"

	"github.com/golang-migrate/migrate/v4"
	migrationPostgres "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	_ "github.com/lib/pq"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/modules/postgres"
	"github.com/testcontainers/testcontainers-go/wait"
)

// PostgreSQLContainer wraps a PostgreSQL test container
type PostgreSQLContainer struct {
	Container testcontainers.Container
	Host      string
	Port      string
	Database  string
	Username  string
	Password  string
}

// GetDSN returns the PostgreSQL connection string
func (c *PostgreSQLContainer) GetDSN() string {
	return fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=disable",
		c.Username, c.Password, c.Host, c.Port, c.Database)
}

// Close terminates the container
func (c *PostgreSQLContainer) Close(ctx context.Context) error {
	return c.Container.Terminate(ctx)
}

// CreatePostgreSQLContainer creates and starts a PostgreSQL test container
func CreatePostgreSQLContainer(ctx context.Context) (*PostgreSQLContainer, error) {
	dbName := "test_db"
	dbUser := "test_user"
	dbPassword := "test_password"

	container, err := postgres.Run(ctx,
		"postgres:15-alpine",
		postgres.WithDatabase(dbName),
		postgres.WithUsername(dbUser),
		postgres.WithPassword(dbPassword),
		testcontainers.WithWaitStrategy(
			wait.ForLog("database system is ready to accept connections").
				WithOccurrence(2).
				WithStartupTimeout(30*time.Second),
		),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to start PostgreSQL container: %w", err)
	}

	// Get container connection details
	host, err := container.Host(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get container host: %w", err)
	}

	mappedPort, err := container.MappedPort(ctx, "5432")
	if err != nil {
		return nil, fmt.Errorf("failed to get mapped port: %w", err)
	}

	return &PostgreSQLContainer{
		Container: container,
		Host:      host,
		Port:      mappedPort.Port(),
		Database:  dbName,
		Username:  dbUser,
		Password:  dbPassword,
	}, nil
}

// APIContainer wraps an API service test container
type APIContainer struct {
	Container testcontainers.Container
	Host      string
	Port      string
	BaseURL   string
}

// Close terminates the container
func (c *APIContainer) Close(ctx context.Context) error {
	return c.Container.Terminate(ctx)
}

// CreateAPIContainer creates and starts an API service test container  
func CreateAPIContainer(ctx context.Context, dbContainer *PostgreSQLContainer) (*APIContainer, error) {
	// Get the container internal IP for database connection
	dbHost, err := dbContainer.Container.ContainerIP(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get database container IP: %w", err)
	}
	// Build the API image first
	req := testcontainers.ContainerRequest{
		FromDockerfile: testcontainers.FromDockerfile{
			Context:    "../../../..",
			Dockerfile: "tests/docker/api/Dockerfile",
		},
		ExposedPorts: []string{"8080/tcp"},
		Env: map[string]string{
			"DB_ENGINE":   "postgres",
			"DB_HOST":     dbHost,                     // Use container IP
			"DB_PORT":     "5432",                     // Internal port
			"DB_NAME":     dbContainer.Database,
			"DB_USER":     dbContainer.Username,
			"DB_PASSWORD": dbContainer.Password,
			"DB_SSL_MODE": "disable",
			"HTTP_PORT":   "8080",
			"JWT_SECRET":  "test-jwt-secret-key-for-integration-tests",
		},
		WaitingFor: wait.ForHTTP("/health").
			WithPort("8080/tcp").
			WithStartupTimeout(60 * time.Second).
			WithPollInterval(2 * time.Second),
	}

	container, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
		ContainerRequest: req,
		Started:          true,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to start API container: %w", err)
	}

	// Get container connection details
	host, err := container.Host(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get container host: %w", err)
	}

	mappedPort, err := container.MappedPort(ctx, "8080")
	if err != nil {
		return nil, fmt.Errorf("failed to get mapped port: %w", err)
	}

	port := mappedPort.Port()
	baseURL := fmt.Sprintf("http://%s:%s", host, port)

	return &APIContainer{
		Container: container,
		Host:      host,
		Port:      port,
		BaseURL:   baseURL,
	}, nil
}

// RunMigrations runs database migrations against the test database
func RunMigrations(ctx context.Context, dbDSN string) error {
	// Connect to the database
	db, err := sql.Open("postgres", dbDSN)
	if err != nil {
		return fmt.Errorf("failed to connect to database: %w", err)
	}
	defer db.Close()

	// Create migration driver
	driver, err := migrationPostgres.WithInstance(db, &migrationPostgres.Config{})
	if err != nil {
		return fmt.Errorf("failed to create migration driver: %w", err)
	}

	// Get the project root directory  
	// From tests/api/health/get we need to go up four levels to reach the project root
	migrationsPath, err := filepath.Abs("../../../../database/migrations")
	if err != nil {
		return fmt.Errorf("failed to get migrations path: %w", err)
	}

	// Create migrate instance
	m, err := migrate.NewWithDatabaseInstance(
		fmt.Sprintf("file://%s", migrationsPath),
		"postgres",
		driver,
	)
	if err != nil {
		return fmt.Errorf("failed to create migrate instance: %w", err)
	}

	// Run migrations
	if err := m.Up(); err != nil && err != migrate.ErrNoChange {
		return fmt.Errorf("failed to run migrations: %w", err)
	}

	return nil
}

// SeedDatabase executes SQL seed files against the test database
func SeedDatabase(ctx context.Context, dbDSN string, seedFiles ...string) error {
	// Connect to the database
	db, err := sql.Open("postgres", dbDSN)
	if err != nil {
		return fmt.Errorf("failed to connect to database: %w", err)
	}
	defer db.Close()

	// Execute each seed file
	for _, seedFile := range seedFiles {
		absPath, err := filepath.Abs(seedFile)
		if err != nil {
			return fmt.Errorf("failed to get absolute path for seed file %s: %w", seedFile, err)
		}

		content, err := ioutil.ReadFile(absPath)
		if err != nil {
			return fmt.Errorf("failed to read seed file %s: %w", seedFile, err)
		}

		if _, err := db.ExecContext(ctx, string(content)); err != nil {
			return fmt.Errorf("failed to execute seed file %s: %w", seedFile, err)
		}
	}

	return nil
}