package postgres

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"

	"go-hexagonal-fullstack-monorepo/internal/shared/fault"
	"go-hexagonal-fullstack-monorepo/internal/shared/localconfig"
)

type Adapter struct {
	*pgxpool.Pool
}

func New(configDB localconfig.DatabaseConfig) (*Adapter, error) {
	config, err := pgxpool.ParseConfig(fmt.Sprintf("postgres://%s:%s@%s:%d/%s?sslmode=%s",
		configDB.User,
		configDB.Password,
		configDB.Host,
		configDB.Port,
		configDB.DBName,
		configDB.SSLMode,
	))
	if err != nil {
		return nil, fault.Wrap(fmt.Errorf("unable to parse config connection: %w", err))
	}

	dbPool, err := pgxpool.NewWithConfig(context.Background(), config)
	if err != nil {
		return nil, fault.Wrap(fmt.Errorf("unable to create connection pool: %w", err))
	}

	if err := dbPool.Ping(context.Background()); err != nil {
		return nil, fault.Wrap(fmt.Errorf("unable to ping database: %w", err))
	}

	return &Adapter{dbPool}, nil
}
