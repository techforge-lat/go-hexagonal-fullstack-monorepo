package entity

import (
	"time"

	"github.com/google/uuid"
	"gopkg.in/guregu/null.v4"
)

type Role struct {
	ID        uuid.UUID     `json:"id,omitempty"`
	Code      string        `json:"code,omitempty"`
	Name      string        `json:"name,omitempty"`
	CreatedAt time.Time     `json:"createdAt,omitempty"`
	CreatedBy uuid.NullUUID `json:"createdBy,omitempty"`
	UpdatedAt null.Time     `json:"updatedAt,omitempty"`
	UpdatedBy uuid.NullUUID `json:"updatedBy,omitempty"`
}

// IsActive returns true if the role is active
func (r Role) IsActive() bool {
	return r.ID.String() != ""
}