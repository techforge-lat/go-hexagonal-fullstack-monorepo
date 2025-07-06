package router

import (
	"api.system.soluciones-cloud.com/internal/shared/http/server"

	"go.uber.org/fx"
)

type RouterParams struct {
	fx.In
}

// SetAPIRoutes configures all API routes for the server
func SetAPIRoutes(echoServer *server.EchoServer, params RouterParams) error {
	// No routes configured yet - ready for new modules
	return nil
}
