package checkin

import (
	"context"

	"github.com/gdg-eskisehir/events/backend/internal/application/policy"
	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
	"github.com/gdg-eskisehir/events/backend/internal/application/validation"
	"github.com/gdg-eskisehir/events/backend/internal/domain"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

type CheckInManualInput struct {
	ActorUserID    string
	ActorRoles     []domain.Role
	RegistrationID string
}

type CheckInManualOutput struct {
	RegistrationID string
	EventID        string
	Status         domain.RegistrationStatus
}

type CheckInManualUseCase struct {
	uow ports.UnitOfWork
	reg ports.RegistrationRepository
}

func NewCheckInManualUseCase(uow ports.UnitOfWork, reg ports.RegistrationRepository) *CheckInManualUseCase {
	return &CheckInManualUseCase{uow: uow, reg: reg}
}

func (uc *CheckInManualUseCase) Execute(
	ctx context.Context,
	in CheckInManualInput,
) (*CheckInManualOutput, error) {
	if err := policy.CanCheckIn(in.ActorRoles); err != nil {
		return nil, err
	}
	if err := validation.RequireUUID(in.ActorUserID); err != nil {
		return nil, err
	}
	if err := validation.RequireUUID(in.RegistrationID); err != nil {
		return nil, err
	}

	var out *CheckInManualOutput
	err := uc.uow.WithinTx(ctx, func(txCtx context.Context) error {
		registration, err := uc.reg.GetRegistrationByID(txCtx, in.RegistrationID)
		if err != nil {
			return err
		}
		if registration == nil {
			return sharedErrors.ErrNotFound
		}
		if registration.Status == domain.RegistrationStatusCancelled {
			return sharedErrors.ErrRegistrationCancelled
		}

		if err := uc.reg.CompleteCheckIn(
			txCtx,
			registration.ID,
			registration.EventID,
			in.ActorUserID,
			"manual",
		); err != nil {
			return err
		}

		out = &CheckInManualOutput{
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
