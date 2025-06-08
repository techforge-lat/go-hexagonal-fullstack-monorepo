package entity

import (
	"time"

	"github.com/google/uuid"
	"gopkg.in/guregu/null.v4"
)

type User struct {
	ID        uuid.UUID     `json:"id,omitzero"`
	FirstName string        `json:"firstName,omitzero"`
	LastName  null.String   `json:"lastName,omitzero"`
	Origin    string        `json:"origin,omitzero"`
	Picture   null.String   `json:"picture,omitzero"`
	CreatedAt time.Time     `json:"createdAt,omitzero"`
	CreatedBy uuid.NullUUID `json:"createdBy,omitzero"`
	UpdatedAt null.Time     `json:"updatedAt,omitzero"`
	UpdatedBy uuid.NullUUID `json:"updatedBy,omitzero"`
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
