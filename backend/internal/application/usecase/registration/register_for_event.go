package registration

import (
	"context"
	"errors"

	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
	"github.com/gdg-eskisehir/events/backend/internal/domain"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

type RegisterForEventInput struct {
	ActorUserID string
	EventID     string
}

type RegisterForEventOutput struct {
	RegistrationID string
	EventID        string
	UserID         string
	QRCodeValue    string
	Status         domain.RegistrationStatus
}

type RegisterForEventUseCase struct {
	uow           ports.UnitOfWork
	eventRepo     ports.EventRepository
	registerRepo  ports.RegistrationRepository
	qrCodeService ports.QRCodeService
}

func NewRegisterForEventUseCase(
	uow ports.UnitOfWork,
	eventRepo ports.EventRepository,
	registerRepo ports.RegistrationRepository,
	qrCodeService ports.QRCodeService,
) *RegisterForEventUseCase {
	return &RegisterForEventUseCase{
		uow:           uow,
		eventRepo:     eventRepo,
		registerRepo:  registerRepo,
		qrCodeService: qrCodeService,
	}
}

func (uc *RegisterForEventUseCase) Execute(
	ctx context.Context,
	in RegisterForEventInput,
) (*RegisterForEventOutput, error) {
	if in.ActorUserID == "" || in.EventID == "" {
		return nil, sharedErrors.ErrValidation
	}

	var output *RegisterForEventOutput
	err := uc.uow.WithinTx(ctx, func(txCtx context.Context) error {
		event, err := uc.eventRepo.GetByID(txCtx, in.EventID)
		if err != nil {
			return err
		}
		if event == nil {
			return sharedErrors.ErrNotFound
		}
		if !event.Status.IsRegisterable() {
			return sharedErrors.ErrConflict
		}

		existing, err := uc.registerRepo.GetByEventAndUser(txCtx, in.EventID, in.ActorUserID)
		if err != nil {
			return err
		}
		if existing != nil {
			return sharedErrors.ErrAlreadyRegistered
		}

		count, err := uc.eventRepo.GetRegistrationCount(txCtx, in.EventID)
		if err != nil {
			return err
		}
		if count >= event.Capacity {
			return sharedErrors.ErrCapacityReached
		}

		qrCode, err := uc.qrCodeService.GenerateRegistrationCode(txCtx, in.EventID, in.ActorUserID)
		if err != nil {
			return err
		}

		registration := &domain.Registration{
			ID:          "", // assigned by repository/DB
			EventID:     in.EventID,
			UserID:      in.ActorUserID,
			Status:      domain.RegistrationStatusActive,
			QRCodeValue: qrCode,
		}
		if err := uc.registerRepo.Create(txCtx, registration); err != nil {
			return err
		}

		output = &RegisterForEventOutput{
			RegistrationID: registration.ID,
			EventID:        registration.EventID,
			UserID:         registration.UserID,
			QRCodeValue:    registration.QRCodeValue,
			Status:         registration.Status,
		}
		return nil
	})
	if err != nil {
		return nil, mapRegisterError(err)
	}
	return output, nil
}

func mapRegisterError(err error) error {
	switch {
	case errors.Is(err, sharedErrors.ErrNotFound):
		return sharedErrors.ErrNotFound
	case errors.Is(err, sharedErrors.ErrValidation):
		return sharedErrors.ErrValidation
	case errors.Is(err, sharedErrors.ErrAlreadyRegistered):
		return sharedErrors.ErrAlreadyRegistered
	case errors.Is(err, sharedErrors.ErrCapacityReached):
		return sharedErrors.ErrCapacityReached
	case errors.Is(err, sharedErrors.ErrConflict):
		return sharedErrors.ErrConflict
	default:
		return err
	}
}
