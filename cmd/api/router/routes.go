package router

import (
	"fmt"

	"api.system.soluciones-cloud.com/internal/core/users/infrastructure/presentation"
	"api.system.soluciones-cloud.com/internal/shared/http/server"
	"github.com/MarceloPetrucio/go-scalar-api-reference"
	"github.com/labstack/echo/v4"

	"go.uber.org/fx"
)

type RouterParams struct {
	fx.In
	UserHandler *presentation.UserHandler
}

// SetAPIRoutes configures all API routes for the server
func SetAPIRoutes(echoServer *server.EchoServer, params RouterParams) error {
	echoServer.API.GET("/docs", func(c echo.Context) error {
		htmlContent, err := scalar.ApiReferenceHTML(&scalar.Options{
			// SpecURL: "https://generator3.swagger.io/openapi.json",// allow external URL or local path file
			SpecURL: "./cmd/api/docs/openapi.yaml",
			CustomOptions: scalar.CustomOptions{
				PageTitle: "Simple API",
			},
			DarkMode: true,
		})
		if err != nil {
			fmt.Printf("%v", err)
		}

		return c.HTML(200, htmlContent)
	})

	// Register users routes
	RegisterUserRoutes(echoServer.PublicAPI, params.UserHandler)

	return nil
}
