package main

import (
	"go-hexagonal-fullstack-monorepo/cmd/api/router"
	"go-hexagonal-fullstack-monorepo/internal/core/user"
	"go-hexagonal-fullstack-monorepo/internal/shared/http/server"
	"go-hexagonal-fullstack-monorepo/internal/shared/localconfig"
	"go-hexagonal-fullstack-monorepo/internal/shared/logger"
	"go-hexagonal-fullstack-monorepo/internal/shared/repository/postgres"

	"go.uber.org/fx"
)

const serviceName = "api"

// Run starts the API server using fx dependency injection
func Run() {
	app := fx.New(
		localconfig.Module,
		logger.Module,
		postgres.Module,
		server.Module,
		user.Module,
		fx.Invoke(router.SetAPIRoutes),
		// fx.NopLogger, // Disable fx's own logging to use our custom logger
	)

	app.Run()
}
