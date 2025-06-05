package ports

import (
	"context"
	"go-hexagonal-fullstack-monorepo/internal/shared/dafi"
	"go-hexagonal-fullstack-monorepo/internal/shared/types"
)

// UseCaseTx defines a generic interface for usecases that support transactions.
// The type parameter T represents the concrete usecase type that will be returned
// with the transaction context.
//
// Example usage:
//
//	type UserUseCase interface {
//	    UseCaseTx[UserUseCase]
//	    // other methods...
//	}
type UseCaseTx[T any] interface {
	// WithTx creates a new instance of the usecase with the given transaction.
	// This allows for method chaining and transaction propagation across multiple usecases.
	//
	// Parameters:
	//   - tx: The transaction to be used by the usecase
	//
	// Returns:
	//   - T: A new instance of the usecase that will use the provided transaction
	WithTx(tx Transaction) T
}

// UseCaseCommand is a composite interface that combines create, update, and delete operations
// for use cases following the Command pattern in Clean Architecture.
//
// Type Parameters:
//   - C: The type for creation operations (e.g., UserCreate)
//   - U: The type for update operations (e.g., UserUpdate)
//
// This interface is typically implemented by service structs that handle business logic
// for write operations in your entity.
//
// Example usage:
//
//	type UserService struct{}
//	func (s *UserService) implements UseCaseCommand[UserCreate, UserUpdate]
type UseCaseCommand[C, U any] interface {
	UseCaseCreate[C] // Embeds create operations
	UseCaseUpdate[U] // Embeds update operations
	UseCaseDelete    // Embeds delete operations
}

// UseCaseCreate defines the contract for creating new entities in the system.
// This interface represents the "C" in CRUD operations at the use case level.
//
// Type Parameters:
//   - T: The type of entity to be created (e.g., UserCreate)
//
// This interface should be implemented by services that need to handle
// the creation of new domain entities with associated business rules.
type UseCaseCreate[T any] interface {
	// Create handles the creation of a new entity, applying business rules
	// and validations before persisting it.
	//
	// Parameters:
	//   - ctx: Context for the operation, carrying deadlines, cancellation signals, etc.
	//   - entity: Pointer to the entity to be created
	//
	// Returns:
	//   - error: Any error that occurred during the creation process,
	//     including validation errors or business rule violations
	Create(ctx context.Context, entity T) error
	CreateBulk(ctx context.Context, entities types.List[T]) error
}

// UseCaseUpdate defines the contract for updating existing entities in the system.
// This interface represents the "U" in CRUD operations at the use case level.
//
// Type Parameters:
//   - T: The type containing the update data (e.g., UserUpdate)
//
// The interface allows for flexible updates using filters to identify
// which entities should be modified.
type UseCaseUpdate[T any] interface {
	// Update modifies existing entities based on provided filters and update data.
	//
	// Parameters:
	//   - ctx: Context for the operation
	//   - entity: The data to update
	//   - filters: Optional set of filters to determine which entities to update
	//
	// Returns:
	//   - error: Any error during the update process, including validation errors
	Update(ctx context.Context, entity T, filters ...dafi.Filter) error
}

// UseCaseDelete defines the contract for removing entities from the system.
// This interface represents the "D" in CRUD operations at the use case level.
//
// Unlike other interfaces, this one doesn't use generics as deletion typically
// only requires identifying which entities to remove via filters.
type UseCaseDelete interface {
	// Delete removes entities that match the given filters.
	//
	// Parameters:
	//   - ctx: Context for the operation
	//   - filters: Optional set of filters to determine which entities to delete
	//
	// Returns:
	//   - error: Any error during the deletion process
	Delete(ctx context.Context, filters ...dafi.Filter) error
}

// UseCaseQuery is a composite interface for read operations in the system.
// It combines single-entity and collection query operations.
//
// Type Parameters:
//   - M: The single entity model type (e.g., User)
//   - MS: The slice/collection type of the entity model (e.g., []User)
//
// This interface follows the Query part of CQRS pattern, separating
// read operations from write operations.
type UseCaseQuery[M any] interface {
	UseCaseFind[M]             // For single entity queries
	UseCaseList[types.List[M]] // For collection queries
}

// UseCaseQueryRelation extends UseCaseQuery to handle queries that include
// related entities. This is useful for complex domain models with relationships.
//
// Type Parameters:
//   - M: The single entity model type with relations (e.g., UserWithPosts)
//   - MS: The slice type of the entity model with relations (e.g., []UserWithPosts)
type UseCaseQueryRelation[M any] interface {
	UseCaseFindRelation[M]   // For single entity queries with relations
	UseCaseListRelation[[]M] // For collection queries with relations
}

// UseCaseFind defines the contract for retrieving a single entity.
//
// Type Parameters:
//   - T: The type of entity to retrieve
type UseCaseFind[T any] interface {
	// Find retrieves a single entity matching the given criteria.
	//
	// Parameters:
	//   - ctx: Context for the operation
	//   - criteria: Search criteria including filters, sorting, etc.
	//
	// Returns:
	//   - T: The found entity
	//   - error: Any error during the query process
	Find(ctx context.Context, criteria dafi.Criteria) (T, error)
}

// UseCaseList defines the contract for retrieving multiple entities.
//
// Type Parameters:
//   - T: The collection type to retrieve (e.g., []User)
type UseCaseList[T any] interface {
	// List retrieves all entities matching the given criteria.
	//
	// Parameters:
	//   - ctx: Context for the operation
	//   - criteria: Search criteria including filters, sorting, pagination, etc.
	//
	// Returns:
	//   - T: Collection of found entities
	//   - error: Any error during the query process
	List(ctx context.Context, criteria dafi.Criteria) (T, error)
}

// UseCaseFindRelation defines the contract for retrieving a single entity
// along with its related entities.
//
// Type Parameters:
//   - T: The entity type with loaded relations
type UseCaseFindRelation[T any] interface {
	// FindRelation retrieves a single entity with its relations.
	//
	// Parameters:
	//   - ctx: Context for the operation
	//   - criteria: Search criteria with relationship specifications
	//
	// Returns:
	//   - T: The found entity with loaded relations
	//   - error: Any error during the query process
	FindRelation(ctx context.Context, criteria dafi.Criteria) (T, error)
}

// UseCaseListRelation defines the contract for retrieving multiple entities
// along with their related entities.
//
// Type Parameters:
//   - T: The collection type with loaded relations (e.g., []UserWithPosts)
type UseCaseListRelation[T any] interface {
	// ListRelation retrieves multiple entities with their relations.
	//
	// Parameters:
	//   - ctx: Context for the operation
	//   - criteria: Search criteria with relationship specifications
	//
	// Returns:
	//   - T: Collection of found entities with loaded relations
	//   - error: Any error during the query process
	ListRelation(ctx context.Context, criteria dafi.Criteria) (T, error)
}
