package presentation

import (
	"go-hexagonal-fullstack-monorepo/internal/core/users_origin_enum/domain/entity"
	"go-hexagonal-fullstack-monorepo/internal/shared/dafi"
	"go-hexagonal-fullstack-monorepo/internal/shared/fault"
	"go-hexagonal-fullstack-monorepo/internal/shared/http/server/response"
	"go-hexagonal-fullstack-monorepo/internal/shared/ports"
	"net/http"

	"github.com/labstack/echo/v4"
)

type Handler struct {
	useCase ports.UsersOriginEnumUseCase
}

func NewHandler(useCase ports.UsersOriginEnumUseCase) *Handler {
	return &Handler{useCase: useCase}
}

func (h Handler) Create(c echo.Context) error {
	req := entity.UsersOriginEnumCreateRequest{}
	if err := c.Bind(&req); err != nil {
		return fault.Wrap(err).Code(fault.UnprocessableEntity)
	}

	if err := h.useCase.Create(c.Request().Context(), req); err != nil {
		return fault.Wrap(err)
	}

	return c.JSON(http.StatusCreated, response.Created(req))
}

func (h Handler) Update(c echo.Context) error {
	req := entity.UsersOriginEnumUpdateRequest{}
	if err := c.Bind(&req); err != nil {
		return fault.Wrap(err).Code(fault.UnprocessableEntity)
	}

	criteria, err := dafi.NewQueryParser().Parse(c.QueryParams())
	if err != nil {
		return fault.Wrap(err)
	}

	criteria = criteria.And("code", dafi.Equal, c.Param("code"))

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

	criteria = criteria.And("code", dafi.Equal, c.Param("code"))

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

	criteria = criteria.And("code", dafi.Equal, c.Param("code"))

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

	exists, err := h.useCase.Exists(c.Request().Context(), criteria)
	if err != nil {
		return fault.Wrap(err)
	}

	return c.JSON(http.StatusOK, response.Ok(map[string]bool{"exists": exists}))
}

func (h Handler) Count(c echo.Context) error {
	criteria, err := dafi.NewQueryParser().Parse(c.QueryParams())
	if err != nil {
		return fault.Wrap(err)
	}

	count, err := h.useCase.Count(c.Request().Context(), criteria)
	if err != nil {
		return fault.Wrap(err)
	}

	return c.JSON(http.StatusOK, response.Ok(map[string]int64{"count": count}))
}