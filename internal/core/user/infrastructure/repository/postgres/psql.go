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
	if entity.ID == uuid.Nil || entity.ID.String() == "" {
		entity.ID = uuid.New()
	}
	if !entity.CreatedAt.Valid {
		entity.CreatedAt.SetValid(time.Now())
	}

	result, err := insertQuery.WithValues(entity.ID, entity.FirstName, entity.LastName, entity.Origin, entity.CreatedAt, entity.CreatedBy).ToSQL()
	if err != nil {
		return fault.Wrap(err)
	}

	if _, err := r.conn().Exec(ctx, result.Sql, result.Args...); err != nil {
		return fault.Wrap(err)
	}

	return nil
}

func (r Repository) Update(ctx context.Context, entity entity.UserUpdateRequest, filters ...dafi.Filter) error {
	if !entity.UpdatedAt.Valid {
		entity.UpdatedAt.SetValid(time.Now())
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
	result, err := selectQuery.
		Where(criteria.Filters...).
		OrderBy(criteria.Sorts...).
		Limit(1).RequiredColumns(criteria.SelectColumns...).
		ToSQL()
	if err != nil {
		return entity.User{}, fault.Wrap(err)
	}

	var m entity.User
	if err := pgxscan.Get(ctx, r.conn(), &m, result.Sql, result.Args...); err != nil {
		return entity.User{}, fault.Wrap(err)
	}

	return m, nil
}

func (r Repository) List(ctx context.Context, criteria dafi.Criteria) (types.List[entity.User], error) {
	result, err := selectQuery.
		Where(criteria.Filters...).
		OrderBy(criteria.Sorts...).
		Limit(criteria.Pagination.PageSize).
		Page(criteria.Pagination.PageNumber).
		RequiredColumns(criteria.SelectColumns...).
		ToSQL()
	if err != nil {
		return nil, fault.Wrap(err)
	}

	var list []entity.User
	if err := pgxscan.Select(ctx, r.conn(), &list, result.Sql, result.Args...); err != nil {
		return nil, fault.Wrap(err)
	}

	return list, nil
}

// conn returns the database connection to use
// if there is a transaction, it returns the transaction connection
func (r Repository) conn() ports.DatabaseExecutor {
	if r.tx != nil {
		return r.tx
	}

	return r.db
}
