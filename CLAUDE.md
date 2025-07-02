# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Go API backend using hexagonal architecture within a monorepo structure. The project implements a CRUD system with clean separation of concerns between domain logic, application use cases, and infrastructure.

## Architecture

The codebase follows hexagonal (ports and adapters) architecture with clear layers:

- **Domain Layer**: Business entities and rules (`domain/entity/`)
- **Application Layer**: Use cases and business logic (`application/`)
- **Infrastructure Layer**: External adapters like HTTP handlers and database repositories (`infrastructure/`)

Each module is organized under `internal/core/{module_name}/` and follows a consistent structure defined in the MODULE_CREATION_GUIDE.md.

## Development Commands

### Basic Development
- **Build**: `make build` or `go build ./...`
- **Run API server**: `make run-api` or `go run ./cmd/api`
- **Format code**: `make fmt` or `go fmt ./...`
- **Run tests**: `make test` or `go test -race ./...`
- **Test with coverage**: `make test-cover` or `go test -cover ./...`

### Code Quality
- **Lint and check**: `make all` (runs fmt, test, and build)
- **Vulnerability check**: `make vulnerability`
- **Vet code**: `make vet` or `go vet ./...`
- **Tidy modules**: `make tidy` or `go mod tidy`

### Database Migrations
- **Create migration**: `make migration-create name=migration_name`
- **Run migrations up**: `make migration-up count=N` (or omit count for all)
- **Run migrations down**: `make migration-down count=N`

### Integration Testing
- **Run all integration tests**: `make test-integration`
- **Run specific test**: `go test -v ./tests/api/health/get -tags=integration`
- **Watch integration tests**: `make test-integration-watch`

### Setup
- **Initial setup**: `make setup` (installs migrate tool and creates log directories)
- **Install migrate tool**: `make install-migrate`

## Key Technologies

- **Framework**: Echo (HTTP framework)
- **Database**: PostgreSQL with pgx driver
- **Dependency Injection**: Uber Fx
- **Query Builder**: Custom SQLCraft system
- **Validation**: Custom validation system
- **Telemetry**: OpenTelemetry with Grafana stack
- **Testing**: Testcontainers for integration tests

## Module Structure

Every CRUD module follows this exact structure:
```
internal/core/{module_name}/
├── application/usecase.go           # Business logic
├── domain/entity/
│   ├── command.go                   # Create/Update/Delete request types
│   └── query.go                     # Read response types
├── infrastructure/
│   ├── presentation/handler.go      # HTTP handlers
│   └── repository/postgres/
│       ├── psql.go                 # Repository implementation
│       └── query.go                # SQL queries and mappings
└── module.go                       # Fx module configuration
```

## Adding New Modules

1. Use the `/module` slash command or follow MODULE_CREATION_GUIDE.md exactly
2. **CRITICAL**: Only implement fields that exist in the provided database schema - never add audit fields unless explicitly present
3. Update `internal/shared/ports/{module_name}.go` with interfaces
4. Add module to `cmd/api/runner.go` imports and fx.New()
5. Create routes in `cmd/api/router/{module_name}_routes.go`
6. Create database migration with `make migration-create name=create_{table_name}_table`

## Database Query System (DAFI)

The project uses DAFI (Data Access and Filtering Interface) for standardized querying:
- **Filtering**: `?field=operator:value` (e.g., `?name=eq:John` or `?age=gte:18`)
- **Sorting**: `?field=sort:direction` (e.g., `?name=sort:asc`)
- **Pagination**: `?page=1&pageSize=10`
- **Field selection**: `?select=field1,field2`

## Key Files and Directories

- `cmd/api/main.go` & `cmd/api/runner.go`: Application entry point and configuration
- `internal/shared/`: Shared utilities, database connections, HTTP server
- `internal/core/`: Business modules following hexagonal architecture
- `database/migrations/`: Database schema migrations
- `tests/`: Integration tests using testcontainers
- `devops/`: Grafana, Tempo, Loki configuration for observability

## Development Environment

- **Local database**: `docker compose up database pgadmin`
- **Full observability stack**: `docker compose up`
- **Environment**: Copy `.env.example` to `.env` and configure
- **Database URL format**: `postgres://user:password@host:port/dbname?sslmode=disable`

## Testing

- **Unit tests**: Standard Go tests in each module
- **Integration tests**: Use testcontainers, run with `-tags=integration`
- **Test database**: Automatically managed by testcontainers
- **Coverage**: Use `make test-cover` for coverage reports

## Important Patterns

1. **Error Handling**: Use the `fault` package for consistent error wrapping
2. **Validation**: Define schemas in `command.go` using the shared validation system
3. **Repository Pattern**: Implement WithTx for transaction support
4. **HTTP Responses**: Use the shared response package for consistent API responses
5. **Dependency Injection**: All dependencies are wired through Uber Fx modules