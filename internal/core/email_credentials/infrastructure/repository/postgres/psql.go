package postgres

import (
	"context"
	"go-hexagonal-fullstack-monorepo/internal/core/email_credentials/domain/entity"
	"go-hexagonal-fullstack-monorepo/internal/shared/dafi"
	"go-hexagonal-fullstack-monorepo/internal/shared/fault"
	"go-hexagonal-fullstack-monorepo/internal/shared/ports"
	"go-hexagonal-fullstack-monorepo/internal/shared/sqlcraft"
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
func (r Repository) WithTx(tx ports.Transaction) ports.EmailCredentialsRepository {
	return &Repository{
		db: r.db,
		tx: tx.GetTx(),
	}
}

func (r Repository) CreateBulk(ctx context.Context, entities types.List[entity.EmailCredentialsCreateRequest]) error {
	query := insertQuery
	for _, entity := range entities {
		if entity.ID == uuid.Nil || entity.ID.String() == "" {
			entity.ID = uuid.New()
		}
		if !entity.CreatedAt.Valid {
			entity.CreatedAt.SetValid(time.Now())
		}

		query = query.WithValues(entity.ID, entity.UserID, entity.Email, entity.PasswordHash, entity.IsVerified, entity.CreatedAt, entity.CreatedBy)
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

func (r Repository) Create(ctx context.Context, entity entity.EmailCredentialsCreateRequest) error {
	if entity.ID == uuid.Nil || entity.ID.String() == "" {
		entity.ID = uuid.New()
	}
	if !entity.CreatedAt.Valid {
		entity.CreatedAt.SetValid(time.Now())
	}

	result, err := insertQuery.WithValues(entity.ID, entity.UserID, entity.Email, entity.PasswordHash, entity.IsVerified, entity.CreatedAt, entity.CreatedBy).ToSQL()
	if err != nil {
		return fault.Wrap(err)
	}

	if _, err := r.conn().Exec(ctx, result.Sql, result.Args...); err != nil {
		return fault.Wrap(err)
	}

	return nil
}

func (r Repository) Update(ctx context.Context, entity entity.EmailCredentialsUpdateRequest, filters ...dafi.Filter) error {
	if !entity.UpdatedAt.Valid {
		entity.UpdatedAt.SetValid(time.Now())
	}

	result, err := updateQuery.WithValues(entity.UserID, entity.Email, entity.PasswordHash, entity.IsVerified, entity.UpdatedAt, entity.UpdatedBy).Where(filters...).ToSQL()
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

// HardDelete permanently removes records from the database
// This should only be used in specific cases like data cleanup or GDPR compliance
func (r Repository) HardDelete(ctx context.Context, filters ...dafi.Filter) error {
	return r.Delete(ctx, filters...)
}

func (r Repository) Find(ctx context.Context, criteria dafi.Criteria) (entity.EmailCredentials, error) {
	if err := dafi.ValidateSelectFields(criteria.SelectColumns, sqlColumnByDomainField); err != nil {
		return entity.EmailCredentials{}, fault.Wrap(err).Code(fault.BadRequest)
	}

	query := sqlcraft.Select(selectAllColumns...).From(table).SQLColumnByDomainField(sqlColumnByDomainField)
	result, err := query.
		Where(criteria.Filters...).
		OrderBy(criteria.Sorts...).
		Limit(1).RequiredColumns(criteria.SelectColumns...).
		ToSQL()
	if err != nil {
		return entity.EmailCredentials{}, fault.Wrap(err)
	}

	var m entity.EmailCredentials
	if err := pgxscan.Get(ctx, r.conn(), &m, result.Sql, result.Args...); err != nil {
		return entity.EmailCredentials{}, fault.Wrap(err)
	}

	return m, nil
}

func (r Repository) List(ctx context.Context, criteria dafi.Criteria) (types.List[entity.EmailCredentials], error) {
	if err := dafi.ValidateSelectFields(criteria.SelectColumns, sqlColumnByDomainField); err != nil {
		return nil, fault.Wrap(err).Code(fault.BadRequest)
	}

	query := sqlcraft.Select(selectAllColumns...).From(table).SQLColumnByDomainField(sqlColumnByDomainField)
	result, err := query.
		Where(criteria.Filters...).
		OrderBy(criteria.Sorts...).
		Limit(criteria.Pagination.PageSize).
		Page(criteria.Pagination.PageNumber).
		RequiredColumns(criteria.SelectColumns...).
		ToSQL()
	if err != nil {
		return nil, fault.Wrap(err)
	}

	var list types.List[entity.EmailCredentials]
	if err := pgxscan.Select(ctx, r.conn(), &list, result.Sql, result.Args...); err != nil {
		return nil, fault.Wrap(err)
	}

	return list, nil
}

func (r Repository) Exists(ctx context.Context, criteria dafi.Criteria) (bool, error) {
	result, err := existsQuery.
		Where(criteria.Filters...).
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
	result, err := countQuery.
		Where(criteria.Filters...).
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