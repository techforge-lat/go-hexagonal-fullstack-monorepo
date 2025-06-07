package postgres

import (
	"context"
	"go-hexagonal-fullstack-monorepo/internal/core/user/domain/entity"
	"go-hexagonal-fullstack-monorepo/internal/shared/dafi"
	"go-hexagonal-fullstack-monorepo/internal/shared/fault"
	"go-hexagonal-fullstack-monorepo/internal/shared/ports"
	"go-hexagonal-fullstack-monorepo/internal/shared/types"
	"time"

	"github.com/georgysavva/scany/v2/pgxscan"
	"github.com/google/uuid"
	"gopkg.in/guregu/null.v4"
)

type Repository struct {
	db ports.Database
	tx ports.Tx
}

func NewRepository(db ports.Database) *Repository {
	return &Repository{db: db}
}

// WithTx returns a new instance of the repository with the transaction set
func (r Repository) WithTx(tx ports.Transaction) ports.UserRepository {
	return &Repository{
		db: r.db,
		tx: tx.GetTx(),
	}
}

func (r Repository) CreateBulk(ctx context.Context, entities types.List[entity.UserCreateRequest]) error {
	query := insertQuery
	for _, entity := range entities {
		if entity.ID == uuid.Nil || entity.ID.String() == "" {
			entity.ID = uuid.New()
		}
		if !entity.CreatedAt.Valid {
			entity.CreatedAt.SetValid(time.Now())
		}

		query = query.WithValues(entity.ID, entity.FirstName, entity.LastName, entity.Origin, entity.CreatedAt, entity.CreatedBy)
	}

	result, err := query.ToSQL()
	if err != nil {
		return fault.Wrap(err)
	}

	if _, err := r.conn().Exec(ctx, result.Sql, result.Args...); err != nil {
		return fault.Wrap(err)
	}

	return nil
}

func (r Repository) Create(ctx context.Context, entity entity.UserCreateRequest) error {
	// Use fresh context with timeout instead of HTTP request context
	queryCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	
	_ = ctx // Keep original parameter for interface compatibility
	if entity.ID == uuid.Nil || entity.ID.String() == "" {
		entity.ID = uuid.New()
	}
	if !entity.CreatedAt.Valid {
		entity.CreatedAt.SetValid(time.Now())
	}

	if !entity.CreatedBy.Valid {
	}

	result, err := insertQuery.WithValues(entity.ID, entity.FirstName, entity.LastName, entity.Origin, entity.CreatedAt, entity.CreatedBy).ToSQL()
	if err != nil {
		return fault.Wrap(err)
	}

	if _, err := r.conn().Exec(queryCtx, result.Sql, result.Args...); err != nil {
		return fault.Wrap(err)
	}

	return nil
}

func (r Repository) Update(ctx context.Context, entity entity.UserUpdateRequest, filters ...dafi.Filter) error {
	if !entity.UpdatedAt.Valid {
		entity.UpdatedAt.SetValid(time.Now())
	}

	if !entity.UpdatedBy.Valid {
	}

	result, err := updateQuery.WithValues(entity.FirstName, entity.LastName, entity.Origin, entity.UpdatedAt, entity.UpdatedBy).Where(filters...).ToSQL()
	if err != nil {
		return fault.Wrap(err)
	}

	if _, err := r.conn().Exec(ctx, result.Sql, result.Args...); err != nil {
		return fault.Wrap(err)
	}

	return nil
}

func (r Repository) Delete(ctx context.Context, filters ...dafi.Filter) error {
	// Perform soft delete by setting deleted_at timestamp
	softDeleteReq := entity.UserDeleteRequest{
		DeletedAt: null.TimeFrom(time.Now()),
		// DeletedBy would be set by the application layer based on current user context
	}

	result, err := softDeleteQuery.Where(filters...).ToSQL()
	if err != nil {
		return fault.Wrap(err)
	}

	if _, err := r.conn().Exec(ctx, result.Sql, append([]any{
		softDeleteReq.DeletedAt,
		softDeleteReq.DeletedBy,
	}, result.Args...)...); err != nil {
		return fault.Wrap(err)
	}

	return nil
}

// HardDelete permanently removes records from the database
// This should only be used in specific cases like data cleanup or GDPR compliance
func (r Repository) HardDelete(ctx context.Context, filters ...dafi.Filter) error {
	result, err := deleteQuery.Where(filters...).ToSQL()
	if err != nil {
		return fault.Wrap(err)
	}

	if _, err := r.conn().Exec(ctx, result.Sql, result.Args...); err != nil {
		return fault.Wrap(err)
	}

	return nil
}

func (r Repository) Find(ctx context.Context, criteria dafi.Criteria) (entity.User, error) {
	// Use fresh context with timeout instead of HTTP request context
	queryCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Validate select fields if specified
	if err := dafi.ValidateSelectFields(criteria.SelectColumns, sqlColumnByDomainField); err != nil {
		return entity.User{}, fault.Wrap(err).Code(fault.BadRequest)
	}

	// Temporarily disable soft delete filter to isolate connection issues
	filters := criteria.Filters
	// TODO: Re-enable after fixing dafi.IsNull operator mapping
	// filters := append(criteria.Filters, dafi.Filter{
	//	Field:    "deletedAt",
	//	Operator: dafi.IsNull,
	//	Value:    nil,
	// })

	result, err := selectQuery.
		Where(filters...).
		OrderBy(criteria.Sorts...).
		Limit(1).RequiredColumns(criteria.SelectColumns...).
		ToSQL()
	if err != nil {
		return entity.User{}, fault.Wrap(err)
	}

	var m entity.User
	if err := pgxscan.Get(queryCtx, r.conn(), &m, result.Sql, result.Args...); err != nil {
		return entity.User{}, fault.Wrap(err)
	}

	return m, nil
}

func (r Repository) List(ctx context.Context, criteria dafi.Criteria) (types.List[entity.User], error) {
	// Use fresh context with timeout instead of HTTP request context
	queryCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Validate select fields if specified
	if err := dafi.ValidateSelectFields(criteria.SelectColumns, sqlColumnByDomainField); err != nil {
		return nil, fault.Wrap(err).Code(fault.BadRequest)
	}

	// Temporarily disable soft delete filter to isolate connection issues
	filters := criteria.Filters
	// TODO: Re-enable after fixing dafi.IsNull operator mapping
	// filters := append(criteria.Filters, dafi.Filter{
	//	Field:    "deletedAt",
	//	Operator: dafi.IsNull,
	//	Value:    nil,
	// })

	result, err := selectQuery.
		Where(filters...).
		OrderBy(criteria.Sorts...).
		Limit(criteria.Pagination.PageSize).
		Page(criteria.Pagination.PageNumber).
		RequiredColumns(criteria.SelectColumns...).
		ToSQL()
	if err != nil {
		return nil, fault.Wrap(err)
	}

	var list []entity.User
	if err := pgxscan.Select(queryCtx, r.conn(), &list, result.Sql, result.Args...); err != nil {
		return nil, fault.Wrap(err)
	}

	return list, nil
}

func (r Repository) Exists(ctx context.Context, criteria dafi.Criteria) (bool, error) {
	// Temporarily disable soft delete filter to isolate connection issues
	filters := criteria.Filters
	// TODO: Re-enable after fixing dafi.IsNull operator mapping
	// filters := append(criteria.Filters, dafi.Filter{
	//	Field:    "deletedAt",
	//	Operator: dafi.IsNull,
	//	Value:    nil,
	// })

	result, err := existsQuery.
		Where(filters...).
		Limit(1).
		ToSQL()
	if err != nil {
		return false, fault.Wrap(err)
	}

	var exists int
	row := r.conn().QueryRow(ctx, result.Sql, result.Args...)

	if err := row.Scan(&exists); err != nil {
		// If no rows found, EXISTS returns false
		if err.Error() == "no rows in result set" {
			return false, nil
		}
		return false, fault.Wrap(err)
	}

	return exists > 0, nil
}

func (r Repository) Count(ctx context.Context, criteria dafi.Criteria) (int64, error) {
	// Temporarily disable soft delete filter to isolate connection issues
	filters := criteria.Filters
	// TODO: Re-enable after fixing dafi.IsNull operator mapping
	// filters := append(criteria.Filters, dafi.Filter{
	//	Field:    "deletedAt",
	//	Operator: dafi.IsNull,
	//	Value:    nil,
	// })

	result, err := countQuery.
		Where(filters...).
		ToSQL()
	if err != nil {
		return 0, fault.Wrap(err)
	}

	var count int64
	row := r.conn().QueryRow(ctx, result.Sql, result.Args...)

	if err := row.Scan(&count); err != nil {
		return 0, fault.Wrap(err)
	}

	return count, nil
}

// conn returns the database connection to use
// if there is a transaction, it returns the transaction connection
func (r Repository) conn() ports.DatabaseExecutor {
	if r.tx != nil {
		return r.tx
	}

	return r.db
}
