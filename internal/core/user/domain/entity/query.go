package entity

import (
	"time"

	"github.com/google/uuid"
	"gopkg.in/guregu/null.v4"
)

type User struct {
	ID        uuid.UUID     `json:"id"`
	FirstName string        `json:"firstName"`
	LastName  null.String   `json:"lastName"`
	Origin    string        `json:"origin"`
	CreatedAt time.Time     `json:"createdAt"`
	CreatedBy uuid.NullUUID `json:"createdId"`
	UpdatedAt null.Time     `json:"updatedAt"`
	UpdatedBy uuid.NullUUID `json:"updatedBy"`
}
