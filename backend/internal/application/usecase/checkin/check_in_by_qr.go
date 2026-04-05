package checkin

import (
	"context"
	"errors"

	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
	"github.com/gdg-eskisehir/events/backend/internal/application/policy"
	"github.com/gdg-eskisehir/events/backend/internal/domain"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

type CheckInByQRInput struct {
	ActorRole domain.Role
	EventID   string
	QRCode    string
}

type CheckInByQROutput struct {
	RegistrationID string
	EventID        string
	Status         domain.RegistrationStatus
}

type CheckInByQRUseCase struct {
	registrationRepo ports.RegistrationRepository
}

func NewCheckInByQRUseCase(registrationRepo ports.RegistrationRepository) *CheckInByQRUseCase {
	return &CheckInByQRUseCase{registrationRepo: registrationRepo}
}

func (uc *CheckInByQRUseCase) Execute(
	ctx context.Context,
	in CheckInByQRInput,
) (*CheckInByQROutput, error) {
	if err := policy.CanCheckIn(in.ActorRole); err != nil {
		return nil, err
	}
	if in.EventID == "" || in.QRCode == "" {
		return nil, sharedErrors.ErrValidation
	}

	registration, err := uc.registrationRepo.GetByEventAndQRCode(ctx, in.EventID, in.QRCode)
	if err != nil {
		return nil, mapCheckInError(err)
	}
	if registration == nil {
		return nil, sharedErrors.ErrInvalidQRCode
	}
	if registration.Status == domain.RegistrationStatusCancelled {
		return nil, sharedErrors.ErrRegistrationCancelled
	}

	return &CheckInByQROutput{
		RegistrationID: registration.ID,
		EventID:        registration.EventID,
		Status:         registration.Status,
	}, nil
}

func mapCheckInError(err error) error {
	switch {
	case errors.Is(err, sharedErrors.ErrForbidden):
		return sharedErrors.ErrForbidden
	case errors.Is(err, sharedErrors.ErrValidation):
		return sharedErrors.ErrValidation
	case errors.Is(err, sharedErrors.ErrInvalidQRCode):
		return sharedErrors.ErrInvalidQRCode
	case errors.Is(err, sharedErrors.ErrRegistrationCancelled):
		return sharedErrors.ErrRegistrationCancelled
	default:
		return err
	}
}
