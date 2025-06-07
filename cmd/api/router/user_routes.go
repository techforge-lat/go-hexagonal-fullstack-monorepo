package router

import (
	"go-hexagonal-fullstack-monorepo/internal/core/user/infrastructure/presentation"
	"go-hexagonal-fullstack-monorepo/internal/shared/http/server"
)

// SetUserRoutes configures user-related API routes
func SetUserRoutes(echoServer *server.EchoServer, userHandler *presentation.Handler) {
	group := echoServer.PublicAPI.Group("/users")

	group.POST("", userHandler.Create)
	group.PUT("", userHandler.Update)
	group.DELETE("", userHandler.Delete)
	group.GET("", userHandler.List)
	group.GET("/find", userHandler.Find)
}
