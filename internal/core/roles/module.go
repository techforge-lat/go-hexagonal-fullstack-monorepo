package roles

import (
	"go-hexagonal-fullstack-monorepo/internal/core/roles/application"
	"go-hexagonal-fullstack-monorepo/internal/core/roles/infrastructure/presentation"
	"go-hexagonal-fullstack-monorepo/internal/core/roles/infrastructure/repository/postgres"
	"go-hexagonal-fullstack-monorepo/internal/shared/ports"

	"go.uber.org/fx"
)

var Module = fx.Module("roles",
	fx.Provide(
		NewRoleRepository,
		NewRoleUseCase,
		presentation.NewHandler,
	),
)

func NewRoleRepository(db ports.Database) ports.RoleRepository {
	return postgres.NewRepository(db)
}

func NewRoleUseCase(repo ports.RoleRepository) ports.RoleUseCase {
	return application.NewUseCase(repo)
}