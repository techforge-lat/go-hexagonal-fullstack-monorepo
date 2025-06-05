# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Go hexagonal architecture starter template within a monorepo structure. The project uses Go 1.24.3 and is designed to support multiple applications (api, cms, wizard) with a shared core and infrastructure.

## Architecture

### Hexagonal Architecture Structure
- `internal/core/`: Domain logic and business rules (currently empty - to be implemented)
- `internal/shared/`: Shared infrastructure and utilities
- `cmd/`: Application entry points for different services (api, cms, wizard)

### Key Shared Components
- **Fault Handling**: Custom error tracing system at `internal/shared/fault/` with HTTP status code mapping and enhanced error context
- **HTTP Server**: Echo-based server setup in `internal/shared/http/server/`
- **Database**: PostgreSQL connection and health checks in `internal/shared/repository/postgres/`
- **Configuration**: Local config management in `internal/shared/localconfig/`
- **Logging**: Centralized logging in `internal/shared/logger/`

## Development Commands

Since the Makefile and docker-compose.yaml are currently empty, use standard Go commands:

```bash
# Build the project
go build ./...

# Run tests
go test ./...

# Run tests with coverage
go test -cover ./...

# Run a specific test
go test ./internal/shared/fault/

# Format code
go fmt ./...

# Vet code
go vet ./...

# Tidy dependencies
go mod tidy
```

## Application Structure

The project supports multiple applications through the `cmd/` directory:
- `cmd/api/`: API server application
- `cmd/cms/`: CMS application  
- `cmd/wizard/`: Wizard application
- `cmd/runner.go`: Shared runner functionality

## Error Handling

This project uses a custom fault package for enhanced error handling:
- Location: `internal/shared/fault/`
- Provides error tracing with caller information
- Maps errors to HTTP status codes
- Supports chaining errors with metadata
- See `internal/shared/fault/README.md` for detailed usage

## Infrastructure

- Database: PostgreSQL (connection setup in `internal/shared/repository/postgres/`)
- HTTP Framework: Echo (server setup in `internal/shared/http/server/`)
- Observability: Ready for Grafana, Loki, Tempo, and OpenTelemetry (config files in `devops/`)