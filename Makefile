# COLORS
ccgreen=$(shell printf "\033[32m")
ccred=$(shell printf "\033[0;31m")
ccyellow=$(shell printf "\033[0;33m")
ccend=$(shell printf "\033[0m")

# Environment variables for project
-include $(PWD)/.env

# Export all variables to sub-make
export

# Database migrations - Use Go bin migrate tool to avoid Snowflake dependency issues
MIGRATE_BIN := $(shell go env GOPATH)/bin/migrate

migration-create:
	$(MIGRATE_BIN) create -ext sql -dir ./database/migrations $(name)

DB_URL=$(DB_ENGINE)://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=$(DB_SSL_MODE)

migration-up:
	@echo $(DB_URL)
	$(MIGRATE_BIN) -source file://database/migrations -database $(DB_URL) up $(count)

migration-down:
	$(MIGRATE_BIN) -source file://database/migrations -database $(DB_URL) down $(count)

# SILENT MODE (avoid echoes)
.SILENT: all fmt test linter build

# Main targets
all: fmt test linter build

fmt:
	@printf "$(ccyellow)Formatting files...$(ccend)\n"
	go fmt ./...
	@printf "$(ccgreen)Formatting files done!$(ccend)\n"

test:
	@printf "$(ccyellow)Testing files...$(ccend)\n"
	go test -race ./...
	@printf "$(ccgreen)Finished testing files...$(ccend)\n"

test-cover:
	@printf "$(ccyellow)Testing with coverage...$(ccend)\n"
	go test -cover ./...
	@printf "$(ccgreen)Finished testing with coverage...$(ccend)\n"

vulnerability:
	@printf "$(ccyellow)Vulnerability check...$(ccend)\n"
	go install golang.org/x/vuln/cmd/govulncheck@latest
	govulncheck ./...
	@printf "$(ccgreen)Finished vulnerability check...$(ccend)\n"

vet:
	@printf "$(ccyellow)Vetting code...$(ccend)\n"
	go vet ./...
	@printf "$(ccgreen)Finished vetting code...$(ccend)\n"

build:
	@printf "$(ccyellow)Building project...$(ccend)\n"
	go build ./...
	@printf "$(ccgreen)Build complete!$(ccend)\n"

tidy:
	@printf "$(ccyellow)Tidying modules...$(ccend)\n"
	go mod tidy
	@printf "$(ccgreen)Modules tidied!$(ccend)\n"


# Installation targets
install-migrate:
	go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest


# Setup and run targets
create-logs:
	mkdir -p logs
	touch logs/app.log

setup: install-migrate create-logs
	@echo "Setup done!"

run-api:
	@printf "$(ccyellow)Running API server...$(ccend)\n"
	go run ./cmd/api

run-cms:
	@printf "$(ccyellow)Running CMS server...$(ccend)\n"
	go run ./cmd/cms

run-wizard:
	@printf "$(ccyellow)Running wizard...$(ccend)\n"
	go run ./cmd/wizard

.PHONY: all fmt test test-cover vulnerability vet build tidy migration-create migration-up migration-down install-migrate create-logs setup run-api run-cms run-wizard
