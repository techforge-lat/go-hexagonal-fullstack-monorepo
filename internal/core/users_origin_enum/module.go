package users_origin_enum

import (
	"go-hexagonal-fullstack-monorepo/internal/core/users_origin_enum/application"
	"go-hexagonal-fullstack-monorepo/internal/core/users_origin_enum/infrastructure/presentation"
	"go-hexagonal-fullstack-monorepo/internal/core/users_origin_enum/infrastructure/repository/postgres"
	"go-hexagonal-fullstack-monorepo/internal/shared/ports"

	"go.uber.org/fx"
)

var Module = fx.Module("users_origin_enum",
	fx.Provide(
		fx.Annotate(
			postgres.NewRepository,
			fx.As(new(ports.UsersOriginEnumRepository)),
		),
		fx.Annotate(
			application.NewUseCase,
			fx.As(new(ports.UsersOriginEnumUseCase)),
		),
		presentation.NewHandler,
	),
)