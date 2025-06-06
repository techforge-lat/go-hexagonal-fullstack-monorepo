package server

import (
	"context"
	"fmt"
	"go-hexagonal-fullstack-monorepo/internal/shared/fault"
	"go-hexagonal-fullstack-monorepo/internal/shared/http/server/middleware"
	"go-hexagonal-fullstack-monorepo/internal/shared/http/server/response"
	"go-hexagonal-fullstack-monorepo/internal/shared/localconfig"
	"go-hexagonal-fullstack-monorepo/internal/shared/logger"
	"go-hexagonal-fullstack-monorepo/internal/shared/repository/postgres"
	"go-hexagonal-fullstack-monorepo/internal/shared/telemetry"
	"net"
	"net/http"
	"os"
	"os/signal"
	"time"

	"github.com/labstack/echo/v4"
	echomiddleware "github.com/labstack/echo/v4/middleware"
	"github.com/techforge-lat/linkit"
)

type Server struct {
	ServiceName string
	API         *echo.Echo
	PrivateAPI  *echo.Group
	PublicAPI   *echo.Group
	Config      *localconfig.Config
	Logger      *logger.Logger
	Database    *postgres.Adapter

	Container *linkit.DependencyContainer
}

func New(serviceName string, config *localconfig.Config, database *postgres.Adapter) (*Server, error) {
	container := linkit.New()

	appLogger := logger.NewFromConfig(config.Logger)
	container.Provide(logger.DependencyName, appLogger)

	container.Provide(postgres.DatabaseDependency, database)
	container.Provide(localconfig.ConfigDependency, config)

	api := echo.New()

	// HTTP Error Handler using custom middleware
	api.HTTPErrorHandler = middleware.ErrorHandler(appLogger.Logger)

	// Basic middleware
	api.Use(echomiddleware.RequestID())
	api.Use(echomiddleware.Recover())
	api.Use(middleware.RequestLogger(appLogger.Logger))

	// CORS middleware
	api.Use(echomiddleware.CORSWithConfig(echomiddleware.CORSConfig{
		AllowOrigins: config.HTTP.AllowedOrigins,
		AllowMethods: config.HTTP.AllowedMethods,
	}))

	// API groups
	publicAPI := api.Group("/api/v1")
	privateAPI := api.Group("/api/v1")

	server := &Server{
		ServiceName: serviceName,
		API:         api,
		PrivateAPI:  privateAPI,
		PublicAPI:   publicAPI,
		Config:      config,
		Logger:      appLogger,
		Database:    database,
		Container:   container,
	}

	// Add health check endpoint
	server.API.GET("/health", server.HealthCheckController)

	return server, nil
}

func (s *Server) Start() error {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt)
	defer stop()

	// Initialize OpenTelemetry
	otelShutdown, err := telemetry.NewOpenTelemetry(
		s.ServiceName,
		s.Config.OTEL.CollectorEndpoint,
		s.Config.OTEL.Environment,
	).Execute(ctx)
	if err != nil {
		return fault.Wrap(err)
	}

	defer func() {
		if shutdownErr := otelShutdown(context.Background()); shutdownErr != nil {
			s.Logger.Error("failed to shutdown OpenTelemetry", "error", shutdownErr.Error())
		}
	}()

	s.API.Server.BaseContext = func(listener net.Listener) context.Context {
		return ctx
	}

	srvErr := make(chan error, 1)

	// Start server
	go func() {
		s.Logger.Info("starting server", "port", s.Config.HTTP.Port, "service", s.ServiceName)
		srvErr <- s.API.Start(fmt.Sprintf(":%d", s.Config.HTTP.Port))
	}()

	// Wait for interruption
	select {
	case err = <-srvErr:
		s.Logger.Error("server error", "error", err.Error())
		return err
	case <-ctx.Done():
		s.Logger.Info("shutdown signal received")
		stop()
	}

	// Graceful shutdown
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := s.API.Shutdown(shutdownCtx); err != nil {
		return fault.Wrap(err)
	}

	s.Logger.Info("server stopped gracefully")
	return nil
}

// HealthCheckController handles health check requests
func (s *Server) HealthCheckController(c echo.Context) error {
	ctx := c.Request().Context()

	if s.Database != nil {
		if err := s.Database.Ping(ctx); err != nil {
			s.Logger.Error("database ping failed", "error", err.Error(), "service", s.ServiceName)

			resp := response.New[any]().
				Status(http.StatusServiceUnavailable).
				Title("Service Unavailable").
				Detail("Database connection failed").
				Extension("serviceName", s.ServiceName).
				Extension("serverTime", time.Now().UTC())

			return c.JSON(resp.GetStatus(), resp)
		}
	}

	healthData := response.HealthResponse{
		Status:      "healthy",
		ServiceName: s.ServiceName,
		ServerTime:  time.Now().UTC(),
	}

	resp := response.Ok(healthData)

	return c.JSON(resp.GetStatus(), resp)
}
