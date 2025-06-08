# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Go hexagonal architecture monorepo using Go 1.24.3 with multiple applications (api, cms, wizard) sharing core business logic and infrastructure. The project uses Uber Fx for dependency injection and includes comprehensive observability tooling.

## Architecture

### Hexagonal Architecture Structure

- `internal/core/`: Domain modules (e.g., `user/`) with application, domain, and infrastructure layers
- `internal/shared/`: Shared infrastructure and utilities across all applications
- `cmd/`: Application entry points using fx.New() for dependency injection

### Key Dependencies

- **Dependency Injection**: Uber Fx (`go.uber.org/fx`) - all modules export fx.Module
- **HTTP Framework**: Echo (`github.com/labstack/echo/v4`) with OpenTelemetry instrumentation
- **Database**: PostgreSQL with pgx driver (`github.com/jackc/pgx/v5`) and Scany for scanning
- **Templates**: Templ (`github.com/a-h/templ`) for type-safe HTML templates
- **Observability**: OpenTelemetry, Grafana stack (Loki, Tempo, Promtail)

### Core Module Pattern

Each domain module follows this structure:
- `application/`: Use cases and business logic
- `domain/`: Entities, commands, and queries
- `infrastructure/presentation/`: HTTP handlers
- `infrastructure/repository/`: Data persistence
- `module.go`: Fx module definition with dependency wiring

**IMPORTANT**: When creating new modules, always refer to `MODULE_CREATION_GUIDE.md` for detailed step-by-step instructions and architectural guidelines. This guide contains critical requirements for AI implementation and ensures strict adherence to the provided database schema.

## Development Commands

### Using Makefile (Recommended)

```bash
# Complete development workflow
make all                    # Format, test, lint, and build

# Individual tasks
make fmt                    # Format code
make test                   # Run tests with race detection
make test-cover             # Run tests with coverage
make vet                    # Run go vet
make build                  # Build project
make tidy                   # Tidy modules
make vulnerability          # Check for vulnerabilities

# Database migrations
make migration-create name=migration_name
make migration-up count=1
make migration-down count=1

# Run applications
make run-api               # Start API server
make run-cms               # Start CMS server
make run-wizard           # Start wizard application

# Setup
make setup                # Install tools and create directories
```

### Direct Go Commands

```bash
# Run specific tests
go test ./internal/shared/fault/
go test -run TestSpecificFunction ./internal/core/user/

# Run applications directly
go run ./cmd/api
go run ./cmd/cms
```

## Custom Packages

### DAFI (Data Access and Filtering Interface)

Location: `internal/shared/dafi/`
- Fluent query builder for filtering, sorting, and pagination
- Usage: `dafi.Where("name", dafi.Equals, "John").SortBy("created_at", dafi.DESC).Limit(10)`

### SQLCraft

Location: `internal/shared/sqlcraft/`
- SQL query builder with type safety
- Supports SELECT, INSERT, UPDATE, DELETE operations

### Fault Package

Location: `internal/shared/fault/`
- Enhanced error handling with caller tracing
- HTTP status code mapping
- Error chaining with metadata

## Infrastructure Services

### Database Setup

```bash
# Start PostgreSQL and pgAdmin
docker-compose up database pgadmin

# Run migrations
make migration-up
```

### Observability Stack

```bash
# Start full observability stack
docker-compose up grafana tempo loki promtail collector

# Access services
# Grafana: http://localhost:3000
# pgAdmin: http://localhost:8888
```

## Git

- Always use conventional commits (see [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/))
