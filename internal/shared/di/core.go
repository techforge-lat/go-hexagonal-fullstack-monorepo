package di

import (
	"go-hexagonal-fullstack-monorepo/internal/core/user"
	"go-hexagonal-fullstack-monorepo/internal/shared/fault"
	"go-hexagonal-fullstack-monorepo/internal/shared/ports"
	"go-hexagonal-fullstack-monorepo/internal/shared/repository/postgres"

	"github.com/techforge-lat/linkit"
)

func ProvideDependencies(container *linkit.DependencyContainer) error {
	db, err := linkit.Resolve[ports.Database](container, postgres.DatabaseDependency)
	if err != nil {
		return fault.Wrap(err)
	}

	dbTx := postgres.NewPostgresUnitOfWork(db)
	container.Provide(postgres.UnitOfWorkDependency, dbTx)

	user.ProvideModuleDependencies(container, db)

	return nil
}
