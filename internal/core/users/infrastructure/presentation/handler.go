package presentation

import (
	"net/http"
	"strconv"

	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/trace"

	"api.system.soluciones-cloud.com/internal/core/users/domain/entity"
	"api.system.soluciones-cloud.com/internal/shared/dafi"
	"api.system.soluciones-cloud.com/internal/shared/fault"
	"api.system.soluciones-cloud.com/internal/shared/ports"
)

type UserHandler struct {
	usecase ports.UserUseCase
	tracer  trace.Tracer
}

func NewUserHandler(usecase ports.UserUseCase) *UserHandler {
	return &UserHandler{
		usecase: usecase,
		tracer:  otel.Tracer("users-handler"),
	}
}

// CreateUser godoc
// @Summary Create a new user
// @Description Create a new user with the provided information
// @Tags users
// @Accept json
// @Produce json
// @Param user body entity.CreateUserRequest true "User creation request"
// @Success 201 {object} entity.User
// @Failure 400 {object} map[string]any
// @Failure 500 {object} map[string]any
// @Router /users [post]
func (h *UserHandler) CreateUser(c echo.Context) error {
	ctx, span := h.tracer.Start(c.Request().Context(), "UserHandler.CreateUser")
	defer span.End()

	var req entity.CreateUserRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]any{
			"error":   "invalid request body",
			"details": err.Error(),
		})
	}

	user, err := h.usecase.CreateUser(ctx, req)
	if err != nil {
		if faultErr, ok := err.(*fault.Error); ok && faultErr.HTTPStatus() == http.StatusBadRequest {
			return c.JSON(http.StatusBadRequest, map[string]any{
				"error":   "validation failed",
				"details": err.Error(),
			})
		}
		return c.JSON(http.StatusInternalServerError, map[string]any{
			"error":   "failed to create user",
			"details": err.Error(),
		})
	}

	return c.JSON(http.StatusCreated, user)
}

// GetUser godoc
// @Summary Get user by ID
// @Description Get a user by its ID
// @Tags users
// @Accept json
// @Produce json
// @Param id path string true "User ID"
// @Success 200 {object} entity.User
// @Failure 400 {object} map[string]any
// @Failure 404 {object} map[string]any
// @Failure 500 {object} map[string]any
// @Router /users/{id} [get]
func (h *UserHandler) GetUser(c echo.Context) error {
	ctx, span := h.tracer.Start(c.Request().Context(), "UserHandler.GetUser")
	defer span.End()

	idParam := c.Param("id")
	id, err := uuid.Parse(idParam)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]any{
			"error":   "invalid user ID",
			"details": err.Error(),
		})
	}

	user, err := h.usecase.GetUserByID(ctx, id)
	if err != nil {
		if faultErr, ok := err.(*fault.Error); ok && faultErr.HTTPStatus() == http.StatusNotFound {
			return c.JSON(http.StatusNotFound, map[string]any{
				"error":   "user not found",
				"details": err.Error(),
			})
		}
		return c.JSON(http.StatusInternalServerError, map[string]any{
			"error":   "failed to get user",
			"details": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, user)
}

// ListUsers godoc
// @Summary List users
// @Description List users with optional filtering, sorting, and pagination
// @Tags users
// @Accept json
// @Produce json
// @Param origin query string false "Filter by origin"
// @Param first_name query string false "Filter by first name (partial match)"
// @Param last_name query string false "Filter by last name (partial match)"
// @Param is_active query boolean false "Filter by active status"
// @Param page query int false "Page number (default: 1)"
// @Param page_size query int false "Page size (default: 10)"
// @Param sort_by query string false "Sort by field"
// @Param sort_order query string false "Sort order (asc/desc)"
// @Success 200 {object} []entity.User
// @Failure 400 {object} map[string]any
// @Failure 500 {object} map[string]any
// @Router /users [get]
func (h *UserHandler) ListUsers(c echo.Context) error {
	ctx, span := h.tracer.Start(c.Request().Context(), "UserHandler.ListUsers")
	defer span.End()

	criteria := dafi.New()

	// Add filters based on query parameters
	if origin := c.QueryParam("origin"); origin != "" {
		criteria = criteria.And("origin", dafi.Equal, origin)
	}

	if firstName := c.QueryParam("first_name"); firstName != "" {
		criteria = criteria.And("first_name", dafi.Like, "%"+firstName+"%")
	}

	if lastName := c.QueryParam("last_name"); lastName != "" {
		criteria = criteria.And("last_name", dafi.Like, "%"+lastName+"%")
	}

	if isActiveParam := c.QueryParam("is_active"); isActiveParam != "" {
		isActive, err := strconv.ParseBool(isActiveParam)
		if err != nil {
			return c.JSON(http.StatusBadRequest, map[string]any{
				"error":   "invalid is_active parameter",
				"details": err.Error(),
			})
		}
		criteria = criteria.And("is_active", dafi.Equal, isActive)
	}

	if createdByParam := c.QueryParam("created_by"); createdByParam != "" {
		createdBy, err := uuid.Parse(createdByParam)
		if err != nil {
			return c.JSON(http.StatusBadRequest, map[string]any{
				"error":   "invalid created_by parameter",
				"details": err.Error(),
			})
		}
		criteria = criteria.And("created_by", dafi.Equal, createdBy)
	}

	if updatedByParam := c.QueryParam("updated_by"); updatedByParam != "" {
		updatedBy, err := uuid.Parse(updatedByParam)
		if err != nil {
			return c.JSON(http.StatusBadRequest, map[string]any{
				"error":   "invalid updated_by parameter",
				"details": err.Error(),
			})
		}
		criteria = criteria.And("updated_by", dafi.Equal, updatedBy)
	}

	// Handle pagination
	page := uint(1)
	if pageParam := c.QueryParam("page"); pageParam != "" {
		p, err := strconv.ParseUint(pageParam, 10, 32)
		if err != nil || p < 1 {
			return c.JSON(http.StatusBadRequest, map[string]any{
				"error":   "invalid page parameter",
				"details": "page must be a positive integer",
			})
		}
		page = uint(p)
	}

	pageSize := uint(10)
	if pageSizeParam := c.QueryParam("page_size"); pageSizeParam != "" {
		ps, err := strconv.ParseUint(pageSizeParam, 10, 32)
		if err != nil || ps < 1 {
			return c.JSON(http.StatusBadRequest, map[string]any{
				"error":   "invalid page_size parameter",
				"details": "page_size must be a positive integer",
			})
		}
		pageSize = uint(ps)
	}

	criteria = criteria.Page(page).Limit(pageSize)

	// Handle sorting
	if sortBy := c.QueryParam("sort_by"); sortBy != "" {
		sortOrder := c.QueryParam("sort_order")
		if sortOrder == "desc" {
			criteria = criteria.SortBy(sortBy, dafi.Desc)
		} else {
			criteria = criteria.SortBy(sortBy, dafi.Asc)
		}
	}

	users, err := h.usecase.ListUsers(ctx, criteria)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]any{
			"error":   "failed to list users",
			"details": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, users)
}

// UpdateUser godoc
// @Summary Update user
// @Description Update an existing user with the provided information
// @Tags users
// @Accept json
// @Produce json
// @Param id path string true "User ID"
// @Param user body entity.UpdateUserRequest true "User update request"
// @Success 200 {object} entity.User
// @Failure 400 {object} map[string]any
// @Failure 404 {object} map[string]any
// @Failure 500 {object} map[string]any
// @Router /users/{id} [put]
func (h *UserHandler) UpdateUser(c echo.Context) error {
	ctx, span := h.tracer.Start(c.Request().Context(), "UserHandler.UpdateUser")
	defer span.End()

	idParam := c.Param("id")
	id, err := uuid.Parse(idParam)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]any{
			"error":   "invalid user ID",
			"details": err.Error(),
		})
	}

	var req entity.UpdateUserRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]any{
			"error":   "invalid request body",
			"details": err.Error(),
		})
	}

	req.ID = id

	user, err := h.usecase.UpdateUser(ctx, req)
	if err != nil {
		if faultErr, ok := err.(*fault.Error); ok {
			switch faultErr.HTTPStatus() {
			case http.StatusBadRequest:
				return c.JSON(http.StatusBadRequest, map[string]any{
					"error":   "validation failed",
					"details": err.Error(),
				})
			case http.StatusNotFound:
				return c.JSON(http.StatusNotFound, map[string]any{
					"error":   "user not found",
					"details": err.Error(),
				})
			}
		}
		return c.JSON(http.StatusInternalServerError, map[string]any{
			"error":   "failed to update user",
			"details": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, user)
}

// DeleteUser godoc
// @Summary Delete user
// @Description Soft delete a user by ID
// @Tags users
// @Accept json
// @Produce json
// @Param id path string true "User ID"
// @Param user body entity.DeleteUserRequest true "Delete request with deleted_by"
// @Success 204
// @Failure 400 {object} map[string]any
// @Failure 404 {object} map[string]any
// @Failure 500 {object} map[string]any
// @Router /users/{id} [delete]
func (h *UserHandler) DeleteUser(c echo.Context) error {
	ctx, span := h.tracer.Start(c.Request().Context(), "UserHandler.DeleteUser")
	defer span.End()

	idParam := c.Param("id")
	id, err := uuid.Parse(idParam)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]any{
			"error":   "invalid user ID",
			"details": err.Error(),
		})
	}

	var req entity.DeleteUserRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]any{
			"error":   "invalid request body",
			"details": err.Error(),
		})
	}

	req.ID = id

	err = h.usecase.DeleteUser(ctx, req)
	if err != nil {
		if faultErr, ok := err.(*fault.Error); ok {
			switch faultErr.HTTPStatus() {
			case http.StatusBadRequest:
				return c.JSON(http.StatusBadRequest, map[string]any{
					"error":   "validation failed",
					"details": err.Error(),
				})
			case http.StatusNotFound:
				return c.JSON(http.StatusNotFound, map[string]any{
					"error":   "user not found",
					"details": err.Error(),
				})
			}
		}
		return c.JSON(http.StatusInternalServerError, map[string]any{
			"error":   "failed to delete user",
			"details": err.Error(),
		})
	}

	return c.NoContent(http.StatusNoContent)
}

// UserExists godoc
// @Summary Check if user exists
// @Description Check if a user exists by ID
// @Tags users
// @Accept json
// @Produce json
// @Param id path string true "User ID"
// @Success 200 {object} map[string]bool
// @Failure 400 {object} map[string]any
// @Failure 500 {object} map[string]any
// @Router /users/{id}/exists [get]
func (h *UserHandler) UserExists(c echo.Context) error {
	ctx, span := h.tracer.Start(c.Request().Context(), "UserHandler.UserExists")
	defer span.End()

	idParam := c.Param("id")
	id, err := uuid.Parse(idParam)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]any{
			"error":   "invalid user ID",
			"details": err.Error(),
		})
	}

	exists, err := h.usecase.ExistsUser(ctx, id)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]any{
			"error":   "failed to check if user exists",
			"details": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, map[string]bool{
		"exists": exists,
	})
}

// CountUsers godoc
// @Summary Count users
// @Description Count users with optional filtering
// @Tags users
// @Accept json
// @Produce json
// @Param origin query string false "Filter by origin"
// @Param first_name query string false "Filter by first name (partial match)"
// @Param last_name query string false "Filter by last name (partial match)"
// @Param is_active query boolean false "Filter by active status"
// @Success 200 {object} map[string]int64
// @Failure 400 {object} map[string]any
// @Failure 500 {object} map[string]any
// @Router /users/count [get]
func (h *UserHandler) CountUsers(c echo.Context) error {
	ctx, span := h.tracer.Start(c.Request().Context(), "UserHandler.CountUsers")
	defer span.End()

	criteria := dafi.New()

	// Add filters based on query parameters
	if origin := c.QueryParam("origin"); origin != "" {
		criteria = criteria.And("origin", dafi.Equal, origin)
	}

	if firstName := c.QueryParam("first_name"); firstName != "" {
		criteria = criteria.And("first_name", dafi.Like, "%"+firstName+"%")
	}

	if lastName := c.QueryParam("last_name"); lastName != "" {
		criteria = criteria.And("last_name", dafi.Like, "%"+lastName+"%")
	}

	if isActiveParam := c.QueryParam("is_active"); isActiveParam != "" {
		isActive, err := strconv.ParseBool(isActiveParam)
		if err != nil {
			return c.JSON(http.StatusBadRequest, map[string]any{
				"error":   "invalid is_active parameter",
				"details": err.Error(),
			})
		}
		criteria = criteria.And("is_active", dafi.Equal, isActive)
	}

	if createdByParam := c.QueryParam("created_by"); createdByParam != "" {
		createdBy, err := uuid.Parse(createdByParam)
		if err != nil {
			return c.JSON(http.StatusBadRequest, map[string]any{
				"error":   "invalid created_by parameter",
				"details": err.Error(),
			})
		}
		criteria = criteria.And("created_by", dafi.Equal, createdBy)
	}

	if updatedByParam := c.QueryParam("updated_by"); updatedByParam != "" {
		updatedBy, err := uuid.Parse(updatedByParam)
		if err != nil {
			return c.JSON(http.StatusBadRequest, map[string]any{
				"error":   "invalid updated_by parameter",
				"details": err.Error(),
			})
		}
		criteria = criteria.And("updated_by", dafi.Equal, updatedBy)
	}

	count, err := h.usecase.CountUsers(ctx, criteria)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]any{
			"error":   "failed to count users",
			"details": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, map[string]int64{
		"count": count,
	})
}