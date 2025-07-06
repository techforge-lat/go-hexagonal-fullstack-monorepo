package users

import (
	"go.uber.org/fx"

	"api.system.soluciones-cloud.com/internal/core/users/application"
	"api.system.soluciones-cloud.com/internal/core/users/infrastructure/presentation"
	"api.system.soluciones-cloud.com/internal/core/users/infrastructure/repository"
	"api.system.soluciones-cloud.com/internal/shared/ports"
)

var Module = fx.Options(
	fx.Provide(
		fx.Annotate(
			repository.NewUserRepository,
			fx.As(new(ports.UserRepository)),
		),
		fx.Annotate(
			application.NewUserUseCase,
			fx.As(new(ports.UserUseCase)),
		),
		presentation.NewUserHandler,
	),
)