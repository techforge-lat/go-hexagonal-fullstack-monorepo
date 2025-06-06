package router

import (
	"go-hexagonal-fullstack-monorepo/internal/shared/http/server"
)

// SetCMSRoutes configures all CMS routes for the server
func SetCMSRoutes(srv *server.Server) error {
	srv.API.GET("/health", srv.HealthCheckController)

	return nil
}