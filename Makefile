# COLORS
ccgreen=$(shell printf "\033[32m")
ccred=$(shell printf "\033[0;31m")
ccyellow=$(shell printf "\033[0;33m")
ccend=$(shell printf "\033[0m")

# Environment variables for project
-include $(PWD)/cmd/api/.env

# Export all variables to sub-make
export

# Database migrations
migration-create:
	migrate create -ext sql -dir ./database/migrations $(name)

DB_URL=$(DB_ENGINE)://$(DB_USER):$(DB_PASSWORD)@$(DB_SERVER):$(DB_PORT)/$(DB_NAME)?sslmode=$(DB_SSLMODE)

migration-up:
	@echo $(DB_URL)
	migrate -source file://database/migrations -database $(DB_URL) up $(count)

migration-down:
	migrate -source file://database/migrations -database $(DB_URL) down $(count)

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

# Swagger documentation
swagger-generate:
	@printf "$(ccyellow)Generating swagger docs...$(ccend)\n"
	swag init -g cmd/api/main.go -o cmd/api/docs
	@printf "$(ccgreen)Swagger docs generated!$(ccend)\n"

# Installation targets
install-migrate:
	go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

install-swag:
	go install github.com/swaggo/swag/cmd/swag@latest

# Setup and run targets
create-logs:
	mkdir -p logs
	touch logs/app.log

setup: install-migrate install-swag create-logs
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

.PHONY: all fmt test test-cover vulnerability vet build tidy swagger-generate migration-create migration-up migration-down install-migrate install-swag create-logs setup run-api run-cms run-wizard
