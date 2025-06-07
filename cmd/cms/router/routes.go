package router

import (
	"go-hexagonal-fullstack-monorepo/internal/shared/http/server"
)

// SetCMSRoutes configures all CMS routes for the server
func SetCMSRoutes(echoServer *server.EchoServer) error {
	// Health check is already handled in the server module
	// Add CMS-specific routes here

	return nil
}