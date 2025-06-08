package router

import (
	"go-hexagonal-fullstack-monorepo/internal/core/user/infrastructure/presentation"
	usersOriginEnumPresentation "go-hexagonal-fullstack-monorepo/internal/core/users_origin_enum/infrastructure/presentation"
	emailCredentialsPresentation "go-hexagonal-fullstack-monorepo/internal/core/email_credentials/infrastructure/presentation"
	"go-hexagonal-fullstack-monorepo/internal/shared/http/server"

	"go.uber.org/fx"
)

type RouterParams struct {
	fx.In
	UserHandler            *presentation.Handler
	UsersOriginEnumHandler *usersOriginEnumPresentation.Handler
	EmailCredentialsHandler *emailCredentialsPresentation.Handler
}

// SetAPIRoutes configures all API routes for the server
func SetAPIRoutes(echoServer *server.EchoServer, params RouterParams) error {
	SetUserRoutes(echoServer, params.UserHandler)
	SetUsersOriginEnumRoutes(echoServer, params.UsersOriginEnumHandler)
	SetEmailCredentialsRoutes(echoServer, params.EmailCredentialsHandler)

	return nil
}
