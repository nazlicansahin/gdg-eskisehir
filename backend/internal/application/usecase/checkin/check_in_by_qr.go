package checkin

import (
	"context"
	"errors"

	"github.com/gdg-eskisehir/events/backend/internal/application/policy"
	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
	"github.com/gdg-eskisehir/events/backend/internal/application/validation"
	"github.com/gdg-eskisehir/events/backend/internal/domain"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

type CheckInByQRInput struct {
	ActorUserID string
	ActorRoles  []domain.Role
	EventID     string
	QRCode      string
}

type CheckInByQROutput struct {
	RegistrationID string
	EventID        string
	Status         domain.RegistrationStatus
}

type CheckInByQRUseCase struct {
	uow ports.UnitOfWork
	reg ports.RegistrationRepository
}

func NewCheckInByQRUseCase(uow ports.UnitOfWork, reg ports.RegistrationRepository) *CheckInByQRUseCase {
	return &CheckInByQRUseCase{uow: uow, reg: reg}
}

func (uc *CheckInByQRUseCase) Execute(
	ctx context.Context,
	in CheckInByQRInput,
) (*CheckInByQROutput, error) {
	if err := policy.CanCheckIn(in.ActorRoles); err != nil {
		return nil, err
	}
	if err := validation.RequireUUID(in.ActorUserID); err != nil {
		return nil, err
	}
	if err := validation.RequireUUID(in.EventID); err != nil {
		return nil, err
	}
	if in.QRCode == "" {
		return nil, sharedErrors.ErrValidation
	}

	var out *CheckInByQROutput
	err := uc.uow.WithinTx(ctx, func(txCtx context.Context) error {
		registration, err := uc.reg.GetByEventAndQRCode(txCtx, in.EventID, in.QRCode)
		if err != nil {
			return err
		}
		if registration == nil {
			return sharedErrors.ErrInvalidQRCode
		}
		if registration.Status == domain.RegistrationStatusCancelled {
			return sharedErrors.ErrRegistrationCancelled
		}

		if err := uc.reg.CompleteCheckIn(
			txCtx,
			registration.ID,
			registration.EventID,
			in.ActorUserID,
			"qr",
		); err != nil {
			return err
		}

		out = &CheckInByQROutput{
			RegistrationID: registration.ID,
			EventID:        registration.EventID,
			Status:         registration.Status,
		}
		return nil
	})
	if err != nil {
		return nil, mapCheckInError(err)
	}
	return out, nil
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
	case errors.Is(err, sharedErrors.ErrAlreadyCheckedIn):
		return sharedErrors.ErrAlreadyCheckedIn
	case errors.Is(err, sharedErrors.ErrNotFound):
		return sharedErrors.ErrNotFound
	default:
		return err
	}
}
