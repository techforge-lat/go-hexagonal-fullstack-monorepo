package request

import (
	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
)

func GetLoggedUserID(c echo.Context) uuid.NullUUID {
	id, ok := c.Get("user_id").(uuid.UUID)
	if !ok {
		return uuid.NullUUID{}
	}

	return uuid.NullUUID{UUID: id, Valid: true}
}
