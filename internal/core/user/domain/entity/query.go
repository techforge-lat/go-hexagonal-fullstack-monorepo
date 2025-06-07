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
	CreatedBy uuid.NullUUID `json:"createdBy"`
	UpdatedAt null.Time     `json:"updatedAt"`
	UpdatedBy uuid.NullUUID `json:"updatedBy"`
	DeletedAt null.Time     `json:"deletedAt,omitzero"`
	DeletedBy uuid.NullUUID `json:"deletedBy,omitzero"`
}

// IsDeleted returns true if the user has been soft deleted
func (u User) IsDeleted() bool {
	return u.DeletedAt.Valid
}

// IsActive returns true if the user is not soft deleted
func (u User) IsActive() bool {
	return !u.IsDeleted()
}
