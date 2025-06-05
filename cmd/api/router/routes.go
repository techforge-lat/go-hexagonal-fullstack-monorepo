package router

import (
	_ "go-hexagonal-fullstack-monorepo/cmd/api/docs"
	"go-hexagonal-fullstack-monorepo/internal/shared/http/server"
	echoSwagger "github.com/swaggo/echo-swagger"
)

// SetAPIRoutes configures all API routes for the server
func SetAPIRoutes(srv *server.Server) error {
	srv.API.GET("/health", srv.HealthCheckController)

	// Add swagger documentation endpoint
	srv.API.GET("/swagger/*", echoSwagger.WrapHandler)

	return nil
}
