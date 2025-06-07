package server

import (
	"go-hexagonal-fullstack-monorepo/internal/shared/localconfig"
	"go-hexagonal-fullstack-monorepo/internal/shared/logger"
	"go-hexagonal-fullstack-monorepo/internal/shared/repository/postgres"

	"github.com/labstack/echo/v4"
	"go.uber.org/fx"
)

// ExampleUsage demonstrates how to properly initialize the server with fx dependency injection
func ExampleUsage() {
	app := fx.New(
		localconfig.Module,
		logger.Module,
		postgres.Module,
		Module,
		fx.Invoke(setupExampleRoutes),
		fx.NopLogger, // Disable fx's own logging
	)

	app.Run()
}

func setupExampleRoutes(echoServer *EchoServer) {
	// Add your routes
	echoServer.PublicAPI.GET("/users", func(c echo.Context) error {
		// Your handler implementation
		return c.JSON(200, map[string]string{"message": "Hello, World!"})
	})

	echoServer.PrivateAPI.POST("/admin/users", func(c echo.Context) error {
		// Your protected handler implementation
		return c.JSON(201, map[string]string{"message": "User created"})
	})
}

// ExampleUsageWithoutDatabase demonstrates how to create a server without database
func ExampleUsageWithoutDatabase() {
	app := fx.New(
		localconfig.Module,
		logger.Module,
		// Note: postgres.Module is omitted - database will be optional
		Module,
		fx.Invoke(setupStatelessRoutes),
		fx.NopLogger,
	)

	app.Run()
}

func setupStatelessRoutes(echoServer *EchoServer) {
	// Add routes for stateless service
	echoServer.PublicAPI.GET("/ping", func(c echo.Context) error {
		return c.JSON(200, map[string]string{"message": "pong"})
	})
}

// ExampleUsageWithTestModules demonstrates how to use fx for testing with mock modules
func ExampleUsageWithTestModules() {
	app := fx.New(
		localconfig.Module,
		logger.Module,
		// Use test modules instead of real ones
		fx.Module("test",
			fx.Provide(func() string { return "test-mode" }),
		),
		Module,
		fx.Invoke(func(echoServer *EchoServer, testMode string) {
			// Setup test routes or behavior
			echoServer.PublicAPI.GET("/test", func(c echo.Context) error {
				return c.JSON(200, map[string]string{"mode": testMode})
			})
		}),
		fx.NopLogger,
	)

	app.Run()
}
