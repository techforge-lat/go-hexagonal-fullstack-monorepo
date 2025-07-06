package application

import (
	"context"
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

type UserUseCase struct {
	repo   ports.UserRepository
	tracer trace.Tracer
}

func NewUserUseCase(repo ports.UserRepository) *UserUseCase {
	return &UserUseCase{
		repo:   repo,
		tracer: otel.Tracer("users-usecase"),
	}
}

func (u *UserUseCase) CreateUser(ctx context.Context, req entity.CreateUserRequest) (entity.User, error) {
	ctx, span := u.tracer.Start(ctx, "CreateUser")
	defer span.End()

	if err := req.Validate(); err != nil {
		return entity.User{}, fault.Wrap(err).Code(fault.BadRequest).Message("validation failed")
	}

	user := entity.User{
		ID:        uuid.New(),
		Origin:    req.Origin,
		FirstName: req.FirstName,
		LastName:  entity.NewNullString(req.LastName),
		Picture:   entity.NewNullString(req.Picture),
		IsActive:  req.IsActive,
		CreatedAt: time.Now(),
		CreatedBy: req.CreatedBy,
	}

	if err := u.repo.Create(ctx, user); err != nil {
		return entity.User{}, fault.Wrap(err).Message("failed to create user")
	}

	return user, nil
}

func (u *UserUseCase) GetUserByID(ctx context.Context, id uuid.UUID) (entity.User, error) {
	ctx, span := u.tracer.Start(ctx, "GetUserByID")
	defer span.End()

	criteria := dafi.Where("id", dafi.Equal, id).
		And("deleted_at", dafi.IsNull, nil)

	user, err := u.repo.Find(ctx, criteria)
	if err != nil {
		return entity.User{}, fault.Wrap(err).Message("failed to get user by ID")
	}

	return user, nil
}

func (u *UserUseCase) ListUsers(ctx context.Context, criteria dafi.Criteria) (types.List[entity.User], error) {
	ctx, span := u.tracer.Start(ctx, "ListUsers")
	defer span.End()

	criteria.Filters = criteria.Filters.And("deleted_at", dafi.IsNull, nil)

	users, err := u.repo.List(ctx, criteria)
	if err != nil {
		return types.List[entity.User]{}, fault.Wrap(err).Message("failed to list users")
	}

	return users, nil
}

func (u *UserUseCase) UpdateUser(ctx context.Context, req entity.UpdateUserRequest) (entity.User, error) {
	ctx, span := u.tracer.Start(ctx, "UpdateUser")
	defer span.End()

	if err := req.Validate(); err != nil {
		return entity.User{}, fault.Wrap(err).Code(fault.BadRequest).Message("validation failed")
	}

	user, err := u.GetUserByID(ctx, req.ID)
	if err != nil {
		return entity.User{}, fault.Wrap(err).Message("failed to get user for update")
	}

	if req.Origin.Valid {
		user.Origin = req.Origin.String
	}
	if req.FirstName.Valid {
		user.FirstName = req.FirstName.String
	}
	if req.LastName.Valid {
		user.LastName = req.LastName
	}
	if req.Picture.Valid {
		user.Picture = req.Picture
	}
	if req.IsActive.Valid {
		user.IsActive = req.IsActive.Bool
	}
	user.UpdatedAt = entity.NewNullTime(time.Now())
	user.UpdatedBy = req.UpdatedBy

	filters := dafi.FilterBy("id", dafi.Equal, req.ID)
	if err := u.repo.Update(ctx, user, filters...); err != nil {
		return entity.User{}, fault.Wrap(err).Message("failed to update user")
	}

	return user, nil
}

func (u *UserUseCase) DeleteUser(ctx context.Context, req entity.DeleteUserRequest) error {
	ctx, span := u.tracer.Start(ctx, "DeleteUser")
	defer span.End()

	if err := req.Validate(); err != nil {
		return fault.Wrap(err).Code(fault.BadRequest).Message("validation failed")
	}

	filters := dafi.FilterBy("id", dafi.Equal, req.ID).
		And("deleted_at", dafi.IsNull, nil)

	if err := u.repo.Delete(ctx, filters...); err != nil {
		return fault.Wrap(err).Message("failed to delete user")
	}

	return nil
}

func (u *UserUseCase) ExistsUser(ctx context.Context, id uuid.UUID) (bool, error) {
	ctx, span := u.tracer.Start(ctx, "ExistsUser")
	defer span.End()

	criteria := dafi.Where("id", dafi.Equal, id).
		And("deleted_at", dafi.IsNull, nil)

	exists, err := u.repo.Exists(ctx, criteria)
	if err != nil {
		return false, fault.Wrap(err).Message("failed to check if user exists")
	}

	return exists, nil
}

func (u *UserUseCase) CountUsers(ctx context.Context, criteria dafi.Criteria) (int64, error) {
	ctx, span := u.tracer.Start(ctx, "CountUsers")
	defer span.End()

	criteria.Filters = criteria.Filters.And("deleted_at", dafi.IsNull, nil)

	count, err := u.repo.Count(ctx, criteria)
	if err != nil {
		return 0, fault.Wrap(err).Message("failed to count users")
	}

	return count, nil
}