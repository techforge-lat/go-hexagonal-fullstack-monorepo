package router

import (
	"go-hexagonal-fullstack-monorepo/internal/core/user/infrastructure/presentation"
	"go-hexagonal-fullstack-monorepo/internal/shared/http/server"
)

// SetUserRoutes configures user-related API routes
func SetUserRoutes(echoServer *server.EchoServer, handler *presentation.Handler) {
	group := echoServer.PublicAPI.Group("/users")

	group.POST("", handler.Create)
	group.PATCH("/:id", handler.Update)
	group.DELETE("/:id", handler.Delete)
	group.GET("/:id", handler.Find)
	group.GET("", handler.List)
}
