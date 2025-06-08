package router

import (
	emailCredentialsHandler "go-hexagonal-fullstack-monorepo/internal/core/email_credentials/infrastructure/presentation"
	"go-hexagonal-fullstack-monorepo/internal/shared/http/server"
)

func SetEmailCredentialsRoutes(echoServer *server.EchoServer, handler *emailCredentialsHandler.Handler) {
	emailCredentialsGroup := echoServer.PublicAPI.Group("/email-credentials")

	emailCredentialsGroup.POST("", handler.Create)
	emailCredentialsGroup.GET("", handler.List)
	emailCredentialsGroup.GET("/:id", handler.Find)
	emailCredentialsGroup.PATCH("/:id", handler.Update)
	emailCredentialsGroup.DELETE("/:id", handler.Delete)
	emailCredentialsGroup.HEAD("", handler.Exists)
	emailCredentialsGroup.GET("/count", handler.Count)
}