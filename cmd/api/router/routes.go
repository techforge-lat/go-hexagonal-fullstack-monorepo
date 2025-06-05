package router

import (
	"go-hexagonal-fullstack-monorepo/internal/shared/http/server"
)

// SetAPIRoutes configures all API routes for the server
func SetAPIRoutes(srv *server.Server) error {
	srv.API.GET("/health", srv.HealthCheckController)

	return nil
}
