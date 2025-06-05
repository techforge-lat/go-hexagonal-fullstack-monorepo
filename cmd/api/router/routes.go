package router

import (
	"go-hexagonal-fullstack-monorepo/internal/shared/http/server"
)

// SetAPIRoutes configures all API routes for the server
func SetAPIRoutes(srv *server.Server) error {
	// The server already adds /api/v1/health endpoint automatically
	// No additional routes needed
	return nil
}

// SetStatelessAPIRoutes configures API routes that don't require database
func SetStatelessAPIRoutes(srv *server.Server) error {
	// The server already adds /api/v1/health endpoint automatically
	// No additional routes needed
	return nil
}
