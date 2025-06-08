package entity

import (
	"time"

	"github.com/google/uuid"
	"gopkg.in/guregu/null.v4"
)

type EmailCredentials struct {
	ID           uuid.UUID     `json:"id,omitzero"`
	UserID       uuid.UUID     `json:"userId,omitzero"`
	Email        string        `json:"email,omitzero"`
	PasswordHash null.String   `json:"-"`
	IsVerified   bool          `json:"isVerified,omitzero"`
	CreatedAt    time.Time     `json:"createdAt,omitzero"`
	CreatedBy    uuid.NullUUID `json:"-"`
	UpdatedAt    null.Time     `json:"updatedAt,omitzero"`
	UpdatedBy    uuid.NullUUID `json:"-"`
}
