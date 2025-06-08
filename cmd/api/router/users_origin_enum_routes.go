package router

import (
	"go-hexagonal-fullstack-monorepo/internal/core/users_origin_enum/infrastructure/presentation"
	"go-hexagonal-fullstack-monorepo/internal/shared/http/server"
)

// SetUsersOriginEnumRoutes configures users origin enum-related API routes
func SetUsersOriginEnumRoutes(echoServer *server.EchoServer, handler *presentation.Handler) {
	group := echoServer.PublicAPI.Group("/users-origin-enum")

	group.POST("", handler.Create)
	group.PATCH("/:code", handler.Update)
	group.DELETE("/:code", handler.Delete)
	group.GET("/:code", handler.Find)
	group.GET("", handler.List)
	group.HEAD("", handler.Exists)
	group.GET("/count", handler.Count)
}