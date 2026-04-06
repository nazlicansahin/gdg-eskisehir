package httpapi

import (
	"github.com/gdg-eskisehir/events/backend/internal/application/validation"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

func pathUUID(_, value string) error {
	if err := validation.RequireUUID(value); err != nil {
		return sharedErrors.ErrValidation
	}
	return nil
}
