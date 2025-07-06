package router

import (
	"github.com/labstack/echo/v4"

	"api.system.soluciones-cloud.com/internal/core/users/infrastructure/presentation"
)

func RegisterUserRoutes(g *echo.Group, handler *presentation.UserHandler) {
	usersGroup := g.Group("/users")

	usersGroup.POST("", handler.CreateUser)
	usersGroup.GET("", handler.ListUsers)
	usersGroup.GET("/count", handler.CountUsers)
	usersGroup.GET("/:id", handler.GetUser)
	usersGroup.PUT("/:id", handler.UpdateUser)
	usersGroup.DELETE("/:id", handler.DeleteUser)
	usersGroup.GET("/:id/exists", handler.UserExists)
}