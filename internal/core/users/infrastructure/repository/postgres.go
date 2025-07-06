package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/trace"

	"api.system.soluciones-cloud.com/internal/core/users/domain/entity"
	"api.system.soluciones-cloud.com/internal/shared/dafi"
	"api.system.soluciones-cloud.com/internal/shared/fault"
	"api.system.soluciones-cloud.com/internal/shared/ports"
	"api.system.soluciones-cloud.com/internal/shared/types"
)

type UserRepository struct {
	db     ports.Database
	tx     ports.Transaction
	tracer trace.Tracer
}

func NewUserRepository(db ports.Database) *UserRepository {
	return &UserRepository{
		db:     db,
		tracer: otel.Tracer("users-repository"),
	}
}

func (r *UserRepository) WithTx(tx ports.Transaction) ports.UserRepository {
	return &UserRepository{
		db:     r.db,
		tx:     tx,
		tracer: r.tracer,
	}
}

func (r *UserRepository) getExecutor() ports.DatabaseExecutor {
	if r.tx != nil {
		return r.tx.GetTx()
	}
	return r.db
}

func (r *UserRepository) Create(ctx context.Context, user entity.User) error {
	ctx, span := r.tracer.Start(ctx, "UserRepository.Create")
	defer span.End()

	query := `
		INSERT INTO auth.users (id, origin, first_name, last_name, picture, is_active, created_at, created_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`

	executor := r.getExecutor()
	_, err := executor.Exec(ctx, query,
		user.ID,
		user.Origin,
		user.FirstName,
		user.LastName,
		user.Picture,
		user.IsActive,
		user.CreatedAt,
		user.CreatedBy,
	)

	if err != nil {
		return fault.Wrap(err).Message("failed to create user")
	}

	return nil
}

func (r *UserRepository) CreateBulk(ctx context.Context, users types.List[entity.User]) error {
	ctx, span := r.tracer.Start(ctx, "UserRepository.CreateBulk")
	defer span.End()

	if len(users) == 0 {
		return nil
	}

	query := `
		INSERT INTO auth.users (id, origin, first_name, last_name, picture, is_active, created_at, created_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`

	executor := r.getExecutor()
	for _, user := range users {
		_, err := executor.Exec(ctx, query,
			user.ID,
			user.Origin,
			user.FirstName,
			user.LastName,
			user.Picture,
			user.IsActive,
			user.CreatedAt,
			user.CreatedBy,
		)
		if err != nil {
			return fault.Wrap(err).Message("failed to create user in bulk")
		}
	}

	return nil
}

func (r *UserRepository) Find(ctx context.Context, criteria dafi.Criteria) (entity.User, error) {
	ctx, span := r.tracer.Start(ctx, "UserRepository.Find")
	defer span.End()

	query := `
		SELECT id, origin, first_name, last_name, picture, is_active, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by
		FROM auth.users
		WHERE deleted_at IS NULL
	`

	// For now, use simple ID lookup - proper DAFI implementation would build the query dynamically
	var user entity.User
	executor := r.getExecutor()
	
	// Extract ID from criteria for simple implementation
	var id uuid.UUID
	for _, filter := range criteria.Filters {
		if filter.Field == "id" && filter.Operator == dafi.Equal {
			id = filter.Value.(uuid.UUID)
			break
		}
	}

	query += " AND id = $1"
	
	row := executor.QueryRow(ctx, query, id)
	err := row.Scan(
		&user.ID,
		&user.Origin,
		&user.FirstName,
		&user.LastName,
		&user.Picture,
		&user.IsActive,
		&user.CreatedAt,
		&user.CreatedBy,
		&user.UpdatedAt,
		&user.UpdatedBy,
		&user.DeletedAt,
		&user.DeletedBy,
	)

	if err != nil {
		return entity.User{}, fault.Wrap(err).Message("failed to find user")
	}

	return user, nil
}

func (r *UserRepository) List(ctx context.Context, criteria dafi.Criteria) (types.List[entity.User], error) {
	ctx, span := r.tracer.Start(ctx, "UserRepository.List")
	defer span.End()

	query := `
		SELECT id, origin, first_name, last_name, picture, is_active, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by
		FROM auth.users
		WHERE deleted_at IS NULL
		ORDER BY created_at DESC
	`

	// Apply pagination if specified
	if criteria.Pagination.PageSize > 0 {
		offset := (criteria.Pagination.PageNumber - 1) * criteria.Pagination.PageSize
		query += fmt.Sprintf(" LIMIT %d OFFSET %d", criteria.Pagination.PageSize, offset)
	}

	executor := r.getExecutor()
	rows, err := executor.Query(ctx, query)
	if err != nil {
		return nil, fault.Wrap(err).Message("failed to list users")
	}
	defer rows.Close()

	var users types.List[entity.User]
	for rows.Next() {
		var user entity.User
		err := rows.Scan(
			&user.ID,
			&user.Origin,
			&user.FirstName,
			&user.LastName,
			&user.Picture,
			&user.IsActive,
			&user.CreatedAt,
			&user.CreatedBy,
			&user.UpdatedAt,
			&user.UpdatedBy,
			&user.DeletedAt,
			&user.DeletedBy,
		)
		if err != nil {
			return nil, fault.Wrap(err).Message("failed to scan user")
		}
		users = append(users, user)
	}

	return users, nil
}

func (r *UserRepository) Update(ctx context.Context, user entity.User, filters ...dafi.Filter) error {
	ctx, span := r.tracer.Start(ctx, "UserRepository.Update")
	defer span.End()

	user.UpdatedAt = entity.NewNullTime(time.Now())

	query := `
		UPDATE auth.users
		SET origin = $2, first_name = $3, last_name = $4, picture = $5, is_active = $6, updated_at = $7, updated_by = $8
		WHERE id = $1 AND deleted_at IS NULL
	`

	executor := r.getExecutor()
	result, err := executor.Exec(ctx, query,
		user.ID,
		user.Origin,
		user.FirstName,
		user.LastName,
		user.Picture,
		user.IsActive,
		user.UpdatedAt,
		user.UpdatedBy,
	)

	if err != nil {
		return fault.Wrap(err).Message("failed to update user")
	}

	if result.RowsAffected() == 0 {
		return fault.Wrap(fmt.Errorf("user not found or already deleted")).Code(fault.NotFound).Message("user not found or already deleted")
	}

	return nil
}

func (r *UserRepository) Delete(ctx context.Context, filters ...dafi.Filter) error {
	ctx, span := r.tracer.Start(ctx, "UserRepository.Delete")
	defer span.End()

	// Extract ID from filters for simple implementation
	var id uuid.UUID
	for _, filter := range filters {
		if filter.Field == "id" && filter.Operator == dafi.Equal {
			id = filter.Value.(uuid.UUID)
			break
		}
	}

	query := `
		UPDATE auth.users
		SET deleted_at = $2, deleted_by = $3
		WHERE id = $1 AND deleted_at IS NULL
	`

	executor := r.getExecutor()
	result, err := executor.Exec(ctx, query, id, time.Now(), nil) // TODO: Get deleted_by from context
	if err != nil {
		return fault.Wrap(err).Message("failed to delete user")
	}

	if result.RowsAffected() == 0 {
		return fault.Wrap(fmt.Errorf("user not found or already deleted")).Code(fault.NotFound).Message("user not found or already deleted")
	}

	return nil
}

func (r *UserRepository) Exists(ctx context.Context, criteria dafi.Criteria) (bool, error) {
	ctx, span := r.tracer.Start(ctx, "UserRepository.Exists")
	defer span.End()

	query := `
		SELECT 1
		FROM auth.users
		WHERE deleted_at IS NULL
	`

	// Extract ID from criteria for simple implementation
	var id uuid.UUID
	for _, filter := range criteria.Filters {
		if filter.Field == "id" && filter.Operator == dafi.Equal {
			id = filter.Value.(uuid.UUID)
			break
		}
	}

	query += " AND id = $1 LIMIT 1"

	executor := r.getExecutor()
	var exists int
	err := executor.QueryRow(ctx, query, id).Scan(&exists)
	if err != nil {
		if err.Error() == "no rows in result set" {
			return false, nil
		}
		return false, fault.Wrap(err).Message("failed to check if user exists")
	}

	return exists == 1, nil
}

func (r *UserRepository) Count(ctx context.Context, criteria dafi.Criteria) (int64, error) {
	ctx, span := r.tracer.Start(ctx, "UserRepository.Count")
	defer span.End()

	query := `
		SELECT COUNT(*)
		FROM auth.users
		WHERE deleted_at IS NULL
	`

	executor := r.getExecutor()
	var count int64
	err := executor.QueryRow(ctx, query).Scan(&count)
	if err != nil {
		return 0, fault.Wrap(err).Message("failed to count users")
	}

	return count, nil
}