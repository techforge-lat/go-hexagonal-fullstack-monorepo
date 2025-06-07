package main

import (
	"go-hexagonal-fullstack-monorepo/cmd/cms/router"
	"go-hexagonal-fullstack-monorepo/internal/shared/http/server"
	"go-hexagonal-fullstack-monorepo/internal/shared/localconfig"
	"go-hexagonal-fullstack-monorepo/internal/shared/logger"
	"go-hexagonal-fullstack-monorepo/internal/shared/repository/postgres"

	"go.uber.org/fx"
)

const serviceName = "cms"

// Run starts the CMS server using fx dependency injection
func Run() {
	app := fx.New(
		localconfig.Module,
		logger.Module,
		postgres.Module,
		server.Module,
		fx.Invoke(setupCMSRoutes),
		fx.NopLogger, // Disable fx's own logging to use our custom logger
	)

	app.Run()
}

func setupCMSRoutes(echoServer *server.EchoServer) error {
	return router.SetCMSRoutes(echoServer)
}

