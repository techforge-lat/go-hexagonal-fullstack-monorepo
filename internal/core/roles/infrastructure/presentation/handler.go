package presentation

import (
	"go-hexagonal-fullstack-monorepo/internal/core/roles/domain/entity"
	"go-hexagonal-fullstack-monorepo/internal/shared/dafi"
	"go-hexagonal-fullstack-monorepo/internal/shared/fault"
	"go-hexagonal-fullstack-monorepo/internal/shared/http/server/request"
	"go-hexagonal-fullstack-monorepo/internal/shared/http/server/response"
	"go-hexagonal-fullstack-monorepo/internal/shared/ports"
	"net/http"

	"github.com/labstack/echo/v4"
)

type Handler struct {
	useCase    ports.RoleUseCase
	unitOfWork ports.UnitOfWork
	logger     ports.Logger
}

func NewHandler(
	useCase ports.RoleUseCase,
	unitOfWork ports.UnitOfWork,
	logger ports.Logger,
) *Handler {
	return &Handler{
		useCase:    useCase,
		unitOfWork: unitOfWork,
		logger:     logger,
	}
}

func (h Handler) Create(c echo.Context) error {
	req := entity.RoleCreateRequest{}
	if err := c.Bind(&req); err != nil {
		return fault.Wrap(err).Code(fault.UnprocessableEntity)
	}
	req.CreatedBy = request.GetLoggedUserID(c)

	if err := h.useCase.Create(c.Request().Context(), req); err != nil {
		return fault.Wrap(err)
	}

	return c.JSON(http.StatusCreated, response.Created(req))
}

func (h Handler) Update(c echo.Context) error {
	req := entity.RoleUpdateRequest{}
	if err := c.Bind(&req); err != nil {
		return fault.Wrap(err).Code(fault.UnprocessableEntity)
	}
	req.UpdatedBy = request.GetLoggedUserID(c)

	criteria, err := dafi.NewQueryParser().Parse(c.QueryParams())
	if err != nil {
		return fault.Wrap(err)
	}

	criteria = criteria.And("id", dafi.Equal, c.Param("id"))

	if err := h.useCase.Update(c.Request().Context(), req, criteria.Filters...); err != nil {
		return fault.Wrap(err)
	}

	return c.JSON(http.StatusOK, response.Ok(req))
}

func (h Handler) Delete(c echo.Context) error {
	criteria, err := dafi.NewQueryParser().Parse(c.QueryParams())
	if err != nil {
		return fault.Wrap(err)
	}

	criteria = criteria.And("id", dafi.Equal, c.Param("id"))

	if err := h.useCase.Delete(c.Request().Context(), criteria.Filters...); err != nil {
		return fault.Wrap(err)
	}

	return c.NoContent(http.StatusNoContent)
}

func (h Handler) Find(c echo.Context) error {
	criteria, err := dafi.NewQueryParser().Parse(c.QueryParams())
	if err != nil {
		return fault.Wrap(err)
	}

	criteria = criteria.And("id", dafi.Equal, c.Param("id"))

	result, err := h.useCase.Find(c.Request().Context(), criteria)
	if err != nil {
		return fault.Wrap(err)
	}

	return c.JSON(http.StatusOK, response.Ok(result))
}

func (h Handler) List(c echo.Context) error {
	criteria, err := dafi.NewQueryParser().Parse(c.QueryParams())
	if err != nil {
		return fault.Wrap(err)
	}

	result, err := h.useCase.List(c.Request().Context(), criteria)
	if err != nil {
		return fault.Wrap(err)
	}

	return c.JSON(http.StatusOK, response.Ok(result))
}

func (h Handler) Exists(c echo.Context) error {
	criteria, err := dafi.NewQueryParser().Parse(c.QueryParams())
	if err != nil {
		return fault.Wrap(err)
	}

	result, err := h.useCase.Exists(c.Request().Context(), criteria)
	if err != nil {
		return fault.Wrap(err)
	}

	return c.JSON(http.StatusOK, response.Ok(map[string]bool{"exists": result}))
}

func (h Handler) Count(c echo.Context) error {
	criteria, err := dafi.NewQueryParser().Parse(c.QueryParams())
	if err != nil {
		return fault.Wrap(err)
	}

	result, err := h.useCase.Count(c.Request().Context(), criteria)
	if err != nil {
		return fault.Wrap(err)
	}

	return c.JSON(http.StatusOK, response.Ok(map[string]int64{"count": result}))
}