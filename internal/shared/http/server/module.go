package server

import (
	"context"
	"fmt"
	"api.system.soluciones-cloud.com/internal/shared/fault"
	"api.system.soluciones-cloud.com/internal/shared/http/server/middleware"
	"api.system.soluciones-cloud.com/internal/shared/localconfig"
	"api.system.soluciones-cloud.com/internal/shared/ports"
	"api.system.soluciones-cloud.com/internal/shared/telemetry"
	"net/http"
	"time"

	"github.com/labstack/echo/v4"
	echomiddleware "github.com/labstack/echo/v4/middleware"
	"go.opentelemetry.io/contrib/instrumentation/github.com/labstack/echo/otelecho"
	"go.uber.org/fx"
)

type EchoServer struct {
	API        *echo.Echo
	PrivateAPI *echo.Group
	PublicAPI  *echo.Group
}

type ServerParams struct {
	fx.In
	Config   *localconfig.Config
	Logger   ports.Logger
	Database ports.Database
}

var Module = fx.Module("http_server",
	fx.Provide(NewEchoServer),
)

func NewEchoServer(params ServerParams, lc fx.Lifecycle) *EchoServer {
	api := echo.New()

	// HTTP Error Handler using custom middleware
	api.HTTPErrorHandler = middleware.ErrorHandler(params.Logger)

	// Basic middleware
	api.Use(otelecho.Middleware("api"))
	api.Use(echomiddleware.RequestID())
	api.Use(echomiddleware.Recover())
	api.Use(echomiddleware.Logger())
	// api.Use(middleware.RequestLogger(params.Logger))

	// CORS middleware
	api.Use(echomiddleware.CORSWithConfig(echomiddleware.CORSConfig{
		AllowOrigins: params.Config.HTTP.AllowedOrigins,
		AllowMethods: params.Config.HTTP.AllowedMethods,
	}))

	// API groups
	publicAPI := api.Group("/api/v1")
	privateAPI := api.Group("/api/v1")

	server := &EchoServer{
		API:        api,
		PrivateAPI: privateAPI,
		PublicAPI:  publicAPI,
	}

	// Add health check endpoint
	api.GET("/health", func(c echo.Context) error {
		return healthCheckHandler(c, params.Database)
	})

	// Lifecycle management
	lc.Append(fx.Hook{
		OnStart: func(ctx context.Context) error {
			go func() {
				// Initialize OpenTelemetry
				if params.Config.OTEL.CollectorEndpoint != "" {
					otelShutdown, err := telemetry.NewOpenTelemetry(
						"http_server",
						params.Config.OTEL.CollectorEndpoint,
						params.Config.OTEL.Environment,
					).Execute(ctx)
					if err != nil {
						params.Logger.Error(ctx, "failed to initialize OpenTelemetry", "error", err.Error())
					} else {
						defer func() {
							if shutdownErr := otelShutdown(context.Background()); shutdownErr != nil {
								params.Logger.Error(ctx, "failed to shutdown OpenTelemetry", "error", shutdownErr.Error())
							}
						}()
					}
				}

				// // Set base context
				// api.Server.BaseContext = func(listener net.Listener) context.Context {
				// 	return ctx
				// }

				params.Logger.Info(ctx, "starting HTTP server", "port", params.Config.HTTP.Port)
				if err := api.Start(fmt.Sprintf(":%d", params.Config.HTTP.Port)); err != nil && err != http.ErrServerClosed {
					params.Logger.Error(ctx, "server error", "error", err.Error())
				}
			}()
			return nil
		},
		OnStop: func(ctx context.Context) error {
			params.Logger.Info(ctx, "shutting down HTTP server")
			shutdownCtx, cancel := context.WithTimeout(ctx, 10*time.Second)
			defer cancel()

			if err := api.Shutdown(shutdownCtx); err != nil {
				return fault.Wrap(err)
			}

			params.Logger.Info(ctx, "HTTP server stopped gracefully")
			return nil
		},
	})

	return server
}

func healthCheckHandler(c echo.Context, database ports.Database) error {
	if database != nil {
		if err := database.Ping(c.Request().Context()); err != nil {
			return c.JSON(http.StatusServiceUnavailable, map[string]any{
				"status": "unhealthy",
				"error":  "database connection failed",
				"cause":  err.Error(),
				"time":   time.Now().UTC(),
			})
		}
	}

	return c.JSON(http.StatusOK, map[string]any{
		"status": "healthy",
		"time":   time.Now().UTC(),
	})
}
