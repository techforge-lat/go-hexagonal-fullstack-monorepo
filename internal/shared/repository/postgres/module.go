package postgres

import (
	"context"
	"go-hexagonal-fullstack-monorepo/internal/shared/localconfig"
	"go-hexagonal-fullstack-monorepo/internal/shared/ports"

	"go.uber.org/fx"
)

var Module = fx.Module("postgres",
	fx.Provide(
		NewDatabase,
		NewUnitOfWork,
	),
)

func NewDatabase(config *localconfig.Config) (ports.Database, error) {
	return New(config.Database)
}

func NewUnitOfWork(db ports.Database, lc fx.Lifecycle) ports.UnitOfWork {
	uow := NewPostgresUnitOfWork(db)

	lc.Append(fx.Hook{
		OnStop: func(ctx context.Context) error {
			if adapter, ok := db.(*Adapter); ok {
				adapter.Close()
			}
			return nil
		},
	})

	return uow
}
