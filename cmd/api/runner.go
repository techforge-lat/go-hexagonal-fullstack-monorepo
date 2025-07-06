package main

import (
	"api.system.soluciones-cloud.com/cmd/api/router"
	"api.system.soluciones-cloud.com/internal/core/users"
	"api.system.soluciones-cloud.com/internal/shared/http/server"
	"api.system.soluciones-cloud.com/internal/shared/localconfig"
	"api.system.soluciones-cloud.com/internal/shared/logger"
	"api.system.soluciones-cloud.com/internal/shared/repository/postgres"

	"go.uber.org/fx"
)

const serviceName = "api"

// Run starts the API server using fx dependency injection
func Run() {
	app := fx.New(
		localconfig.Module,
		logger.Module,
		postgres.Module,
		users.Module,
		server.Module,
		fx.Invoke(router.SetAPIRoutes),
		// fx.NopLogger, // Disable fx's own logging to use our custom logger
	)

	app.Run()
}
