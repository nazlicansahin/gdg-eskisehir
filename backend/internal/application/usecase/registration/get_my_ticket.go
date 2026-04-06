package registration

import (
	"context"
	"errors"

	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
	"github.com/gdg-eskisehir/events/backend/internal/application/validation"
	"github.com/gdg-eskisehir/events/backend/internal/domain"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

type GetMyTicketInput struct {
	ActorUserID string
	EventID     string
}

type GetMyTicketOutput struct {
	RegistrationID string
	EventID        string
	UserID         string
	Status         domain.RegistrationStatus
	QRCodeValue    string
}

type GetMyTicketUseCase struct {
	registrationRepo ports.RegistrationRepository
}

func NewGetMyTicketUseCase(registrationRepo ports.RegistrationRepository) *GetMyTicketUseCase {
	return &GetMyTicketUseCase{registrationRepo: registrationRepo}
}

func (uc *GetMyTicketUseCase) Execute(
	ctx context.Context,
	in GetMyTicketInput,
) (*GetMyTicketOutput, error) {
	if err := validation.RequireUUID(in.ActorUserID); err != nil {
		return nil, err
	}
	if err := validation.RequireUUID(in.EventID); err != nil {
		return nil, err
	}

	registration, err := uc.registrationRepo.GetByEventAndUser(ctx, in.EventID, in.ActorUserID)
	if err != nil {
		return nil, mapGetMyTicketError(err)
	}
	if registration == nil {
		return nil, sharedErrors.ErrNotFound
	}

	return &GetMyTicketOutput{
		RegistrationID: registration.ID,
		EventID:        registration.EventID,
		UserID:         registration.UserID,
		Status:         registration.Status,
		QRCodeValue:    registration.QRCodeValue,
	}, nil
}

func mapGetMyTicketError(err error) error {
	switch {
	case errors.Is(err, sharedErrors.ErrValidation):
		return sharedErrors.ErrValidation
	case errors.Is(err, sharedErrors.ErrNotFound):
		return sharedErrors.ErrNotFound
	default:
		return err
	}
}
