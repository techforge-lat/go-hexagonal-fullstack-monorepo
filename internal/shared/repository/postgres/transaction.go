/*
Package postgres implements PostgreSQL database transaction management using the Unit of Work pattern.

The package provides the following main components:
  - PostgresTransaction: A wrapper for database transactions
  - PostgresUnitOfWork: Manages transaction lifecycle (begin, commit, rollback)

Example usage:

	db := // initialize your database connection
	uow := postgres.NewPostgresUnitOfWork(db)

	// Begin a transaction
	tx, err := uow.Begin(ctx)
	if err != nil {
	    // handle error
	}

	// Perform database operations...

	// Commit the transaction
	if err := uow.Commit(ctx, tx); err != nil {
	    // handle error
	}

	// In case of error, rollback
	if err := uow.Rollback(ctx, tx); err != nil {
	    // handle error
	}

Note: This implementation assumes the existence of ports.Database, ports.Tx, and ports.Transaction
interfaces in the domain ports package.
*/
package postgres

import (
	"context"
	"fmt"
	"go-hexagonal-fullstack-monorepo/internal/shared/fault"
	"go-hexagonal-fullstack-monorepo/internal/shared/ports"
)

// PostgresTransaction represents a PostgreSQL database transaction wrapper
// It implements the ports.Transaction interface and holds the actual transaction
type PostgresTransaction struct {
	tx ports.Tx // The underlying database transaction
}

// GetTx returns the underlying transaction object
// This method is used to access the transaction for executing queries
func (t *PostgresTransaction) GetTx() ports.Tx {
	return t.tx
}

// PostgresUnitOfWork implements the Unit of Work pattern for PostgreSQL
// It manages database transactions and provides methods for beginning,
// committing, and rolling back transactions
type PostgresUnitOfWork struct {
	db ports.Database // The database connection interface
}

// NewPostgresUnitOfWork creates a new instance of PostgresUnitOfWork
// Parameters:
//   - db: Database interface that provides access to the PostgreSQL database
//
// Returns:
//   - *PostgresUnitOfWork: A new instance of the unit of work
func NewPostgresUnitOfWork(db ports.Database) *PostgresUnitOfWork {
	return &PostgresUnitOfWork{db: db}
}

// Begin starts a new database transaction
// Parameters:
//   - ctx: Context for transaction timeout and cancellation
//
// Returns:
//   - ports.Transaction: A new transaction wrapper
//   - error: An error if the transaction couldn't be started
func (uow PostgresUnitOfWork) Begin(ctx context.Context) (ports.Transaction, error) {
	tx, err := uow.db.Begin(ctx)
	if err != nil {
		return nil, fault.Wrap(fmt.Errorf("error starting transaction: %w", err))
	}

	return &PostgresTransaction{tx: tx}, nil
}

// Commit finalizes the given transaction, making all changes permanent
// Parameters:
//   - ctx: Context for transaction timeout and cancellation
//   - tx: The transaction to commit
//
// Returns:
//   - error: An error if the transaction couldn't be committed
func (uow PostgresUnitOfWork) Commit(ctx context.Context, tx ports.Transaction) error {
	if err := tx.GetTx().Commit(ctx); err != nil {
		return fault.Wrap(fmt.Errorf("error committing transaction: %w", err))
	}

	return nil
}

// Rollback reverts all changes made in the given transaction
// Parameters:
//   - ctx: Context for transaction timeout and cancellation
//   - tx: The transaction to rollback
//
// Returns:
//   - error: An error if the transaction couldn't be rolled back
func (uow PostgresUnitOfWork) Rollback(ctx context.Context, tx ports.Transaction) error {
	if err := tx.GetTx().Rollback(ctx); err != nil {
		return fault.Wrap(fmt.Errorf("error rolling back transaction: %w", err))
	}

	return nil
}
