package validation

import (
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
	"github.com/google/uuid"
)

// RequireUUID returns ErrValidation if s is empty or not a valid UUID string.
func RequireUUID(s string) error {
	if s == "" {
		return sharedErrors.ErrValidation
	}
	if _, err := uuid.Parse(s); err != nil {
		return sharedErrors.ErrValidation
	}
	return nil
}
