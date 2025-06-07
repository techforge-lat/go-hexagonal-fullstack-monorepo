package user

import (
	"go-hexagonal-fullstack-monorepo/internal/core/user/application"
	"go-hexagonal-fullstack-monorepo/internal/core/user/infrastructure/presentation"
	"go-hexagonal-fullstack-monorepo/internal/core/user/infrastructure/repository/postgres"
	"go-hexagonal-fullstack-monorepo/internal/shared/ports"

	"go.uber.org/fx"
)

var Module = fx.Module("user",
	fx.Provide(
		NewUserRepository,
		NewUserUseCase,
		presentation.NewHandler,
	),
)

func NewUserRepository(db ports.Database) ports.UserRepository {
	return postgres.NewRepository(db)
}

func NewUserUseCase(repo ports.UserRepository) ports.UserUseCase {
	return application.NewUseCase(repo)
}
