package ports

import (
	"context"
	"go-hexagonal-fullstack-monorepo/internal/shared/dafi"
	"go-hexagonal-fullstack-monorepo/internal/shared/types"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

type Transaction interface {
	GetTx() Tx
}

type UnitOfWork interface {
	Begin(ctx context.Context) (Transaction, error)
	Commit(ctx context.Context, tx Transaction) error
	Rollback(ctx context.Context, tx Transaction) error
}

// DatabaseExecutor defines the common interface for database operations
// This interface is implemented by both Database and Tx for consistency
type DatabaseExecutor interface {
	Exec(ctx context.Context, sql string, args ...any) (pgconn.CommandTag, error)
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
}

type Database interface {
	DatabaseExecutor
	Begin(ctx context.Context) (pgx.Tx, error)
	Ping(ctx context.Context) error
}

type Tx interface {
	DatabaseExecutor
	Begin(ctx context.Context) (pgx.Tx, error)
	// Commit commits the transaction if this is a real transaction or releases the savepoint if this is a pseudo nested
	// transaction. Commit will return an error where errors.Is(ErrTxClosed) is true if the Tx is already closed, but is
	// otherwise safe to call multiple times. If the commit fails with a rollback status (e.g. the transaction was already
	// in a broken state) then an error where errors.Is(ErrTxCommitRollback) is true will be returned.
	Commit(ctx context.Context) error

	// Rollback rolls back the transaction if this is a real transaction or rolls back to the savepoint if this is a
	// pseudo nested transaction. Rollback will return an error where errors.Is(ErrTxClosed) is true if the Tx is already
	// closed, but is otherwise safe to call multiple times. Hence, a defer tx.Rollback() is safe even if tx.Commit() will
	// be called first in a non-error condition. Any other failure of a real transaction will result in the connection
	// being closed.
	Rollback(ctx context.Context) error
}

// RepositoryTx defines a generic interface for repositories that support transactions.
// The type parameter T represents the concrete repository type that will be returned
// with the transaction context.
//
// Example usage:
//
//	type UserRepository interface {
//	    RepositoryTx[UserRepository]
//	    // other methods...
//	}
type RepositoryTx[T any] interface {
	// WithTx creates a new instance of the repository with the given transaction.
	// This allows for method chaining and transaction propagation across multiple repositories.
	//
	// Parameters:
	//   - tx: The transaction to be used by the repository
	//
	// Returns:
	//   - T: A new instance of the repository that will use the provided transaction
	WithTx(tx Transaction) T
}

// RepositoryCommand combines create, update, and delete operations into a single interface.
// It uses two type parameters:
//   - C: The type for creation operations
//   - U: The type for update operations
//
// This interface follows the Command Query Responsibility Segregation (CQRS) pattern
// by separating command (write) operations from query (read) operations.
type RepositoryCommand[C, U any] interface {
	RepositoryCreate[C] // Embeds create operations
	RepositoryUpdate[U] // Embeds update operations
	RepositoryDelete    // Embeds delete operations
}

// RepositoryCreate defines the interface for creating new entities in the repository.
// The type parameter T represents the entity type to be created.
//
// Example usage:
//
//	type UserCreate struct {
//	    Name  string
//	    Email string
//	}
//	repo := RepositoryCreate[UserCreate]
type RepositoryCreate[T any] interface {
	// Create persists a new entity in the storage.
	//
	// Parameters:
	//   - ctx: Context for the operation, which can include deadlines, cancellation signals, etc.
	//   - entity: Pointer to the entity to be created
	//
	// Returns:
	//   - error: Any error that occurred during the creation process
	Create(ctx context.Context, entity T) error
	CreateBulk(ctx context.Context, entities types.List[T]) error
}

// RepositoryUpdate defines the interface for updating existing entities in the repository.
// The type parameter T represents the entity type to be updated.
//
// Example usage:
//
//	type UserUpdate struct {
//	    Name  string
//	    Email string
//	}
//	repo := RepositoryUpdate[UserUpdate]
type RepositoryUpdate[T any] interface {
	// Update modifies existing entities that match the given filters.
	//
	// Parameters:
	//   - ctx: Context for the operation
	//   - entity: The entity with updated values
	//   - filters: Optional set of filters to determine which entities to update
	//
	// Returns:
	//   - error: Any error that occurred during the update process
	Update(ctx context.Context, entity T, filters ...dafi.Filter) error
}

// RepositoryDelete defines the interface for removing entities from the repository.
// This interface doesn't use generics as deletion is typically based on filters
// rather than entity types.
type RepositoryDelete interface {
	// Delete removes entities that match the given filters.
	//
	// Parameters:
	//   - ctx: Context for the operation
	//   - filters: Optional set of filters to determine which entities to delete
	//
	// Returns:
	//   - error: Any error that occurred during the deletion process
	Delete(ctx context.Context, filters ...dafi.Filter) error
}

// RepositoryQuery defines the interface for reading entities from the repository.
// It uses one type parameters:
//   - M: The single entity model type
//
// Example usage:
//
//	type User struct {
//	    ID    string
//	    Name  string
//	    Email string
//	}
//	repo := RepositoryQuery[User]
type RepositoryQuery[M any] interface {
	// Find retrieves a single entity matching the given criteria.
	//
	// Parameters:
	//   - ctx: Context for the operation
	//   - criteria: Search criteria including filters, sorting, etc.
	//
	// Returns:
	//   - M: The found entity
	//   - error: Any error that occurred during the query
	Find(ctx context.Context, criteria dafi.Criteria) (M, error)

	// List retrieves all entities matching the given criteria.
	//
	// Parameters:
	//   - ctx: Context for the operation
	//   - criteria: Search criteria including filters, sorting, pagination, etc.
	//
	// Returns:
	//   - []M: A collection of found entities
	//   - error: Any error that occurred during the query
	List(ctx context.Context, criteria dafi.Criteria) (types.List[M], error)

	// Exists checks if any entity matches the given criteria.
	//
	// Parameters:
	//   - ctx: Context for the operation
	//   - criteria: Search criteria including filters
	//
	// Returns:
	//   - bool: True if at least one entity matches the criteria
	//   - error: Any error that occurred during the query
	Exists(ctx context.Context, criteria dafi.Criteria) (bool, error)

	// Count returns the number of entities matching the given criteria.
	//
	// Parameters:
	//   - ctx: Context for the operation
	//   - criteria: Search criteria including filters
	//
	// Returns:
	//   - int64: The count of entities matching the criteria
	//   - error: Any error that occurred during the query
	Count(ctx context.Context, criteria dafi.Criteria) (int64, error)
}

// RepositoryQueryRelation extends RepositoryQuery with methods for handling related entities.
// This interface is useful when you need to fetch entities along with their relationships.
// It uses the same type parameters as RepositoryQuery:
//   - M: The single entity model type
type RepositoryQueryRelation[M any] interface {
	// FindRelation retrieves a single entity with its related entities.
	//
	// Parameters:
	//   - ctx: Context for the operation
	//   - criteria: Search criteria including filters, sorting, and relationship specifications
	//
	// Returns:
	//   - M: The found entity with its relationships loaded
	//   - error: Any error that occurred during the query
	FindRelation(ctx context.Context, criteria dafi.Criteria) (M, error)

	// ListRelation retrieves all entities with their related entities.
	//
	// Parameters:
	//   - ctx: Context for the operation
	//   - criteria: Search criteria including filters, sorting, pagination, and relationship specifications
	//
	// Returns:
	//   - []M: A collection of found entities with their relationships loaded
	//   - error: Any error that occurred during the query
	ListRelation(ctx context.Context, criteria dafi.Criteria) ([]M, error)
}
