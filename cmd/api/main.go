package main

import (
	"flag"
	"fmt"
	"os"
)

func main() {
	var (
		stateless = flag.Bool("stateless", false, "Run API server without database connection")
		help      = flag.Bool("help", false, "Show help information")
	)
	flag.Parse()

	if *help {
		showHelp()
		return
	}

	if *stateless {
		fmt.Println("Starting API server in stateless mode...")
		RunWithoutDatabase()
	} else {
		fmt.Println("Starting API server with database...")
		Run()
	}
}

func showHelp() {
	fmt.Printf(`
API Service

USAGE:
    %s [OPTIONS]

OPTIONS:
    -stateless    Run API server without database connection
    -help         Show this help information

ENVIRONMENT VARIABLES:
    HTTP_PORT                 HTTP server port (default: 8080)
    DB_HOST                   Database host (default: localhost)
    DB_PORT                   Database port (default: 5432)
    DB_USER                   Database username (default: postgres)
    DB_PASSWORD               Database password (required)
    DB_NAME                   Database name (default: hexagonal_db)
    DB_SSL_MODE               Database SSL mode (default: disable)
    JWT_SECRET                JWT signing secret (required)
    LOG_LEVEL                 Log level: debug, info, warn, error (default: info)
    LOG_FORMAT                Log format: text, json (default: text)
    LOG_ADD_SOURCE            Add source location to logs: true, false (default: false)
    ALLOWED_ORIGINS           CORS allowed origins (default: *)
    ALLOWED_METHODS           CORS allowed methods (default: GET,POST,PUT,DELETE,PATCH,OPTIONS)
    OTEL_COLLECTOR_ENDPOINT   OpenTelemetry collector endpoint (default: localhost:4318)
    ENVIRONMENT               Environment name (default: development)

EXAMPLES:
    # Start API server with database
    %s

    # Start API server without database (stateless mode)
    %s -stateless

    # Set environment variables and start
    export JWT_SECRET=your-secret-key
    export DB_PASSWORD=your-db-password
    %s

`, os.Args[0], os.Args[0], os.Args[0], os.Args[0])
}