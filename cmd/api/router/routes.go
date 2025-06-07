package router

import (
	"go-hexagonal-fullstack-monorepo/internal/core/user/infrastructure/presentation"
	"go-hexagonal-fullstack-monorepo/internal/shared/http/server"

	"go.uber.org/fx"
)

type RouterParams struct {
	fx.In
	UserHandler *presentation.Handler
}

// SetAPIRoutes configures all API routes for the server
func SetAPIRoutes(echoServer *server.EchoServer, params RouterParams) error {
	SetUserRoutes(echoServer, params.UserHandler)

	return nil
}
