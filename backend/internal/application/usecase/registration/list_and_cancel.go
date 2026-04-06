package registration

import (
	"context"
	"strings"

	"github.com/gdg-eskisehir/events/backend/internal/application/policy"
	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
	"github.com/gdg-eskisehir/events/backend/internal/application/validation"
	"github.com/gdg-eskisehir/events/backend/internal/domain"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

type ListMyRegistrationsUseCase struct {
	registrations ports.RegistrationRepository
}

func NewListMyRegistrationsUseCase(registrations ports.RegistrationRepository) *ListMyRegistrationsUseCase {
	return &ListMyRegistrationsUseCase{registrations: registrations}
}

func (uc *ListMyRegistrationsUseCase) Execute(ctx context.Context, actorUserID string) ([]*domain.Registration, error) {
	if err := validation.RequireUUID(actorUserID); err != nil {
		return nil, err
	}
	return uc.registrations.ListByUserID(ctx, actorUserID)
}

type AdminListRegistrationsUseCase struct {
	registrations ports.RegistrationRepository
}

func NewAdminListRegistrationsUseCase(registrations ports.RegistrationRepository) *AdminListRegistrationsUseCase {
	return &AdminListRegistrationsUseCase{registrations: registrations}
}

type AdminListRegistrationsInput struct {
	ActorRole domain.Role
	EventID   string
}

func (uc *AdminListRegistrationsUseCase) Execute(ctx context.Context, in AdminListRegistrationsInput) ([]*domain.Registration, error) {
	if err := policy.CanAccessAdminAPI(in.ActorRole); err != nil {
		return nil, err
	}
	if err := validation.RequireUUID(in.EventID); err != nil {
		return nil, err
	}
	return uc.registrations.ListByEventID(ctx, in.EventID)
}

type CancelRegistrationUseCase struct {
	registrations ports.RegistrationRepository
}

func NewCancelRegistrationUseCase(registrations ports.RegistrationRepository) *CancelRegistrationUseCase {
	return &CancelRegistrationUseCase{registrations: registrations}
}

type CancelRegistrationInput struct {
	ActorRole      domain.Role
	RegistrationID string
	Reason         string
}

func (uc *CancelRegistrationUseCase) Execute(ctx context.Context, in CancelRegistrationInput) (*domain.Registration, error) {
	if err := policy.CanCancelRegistration(in.ActorRole); err != nil {
		return nil, err
	}
	if err := validation.RequireUUID(in.RegistrationID); err != nil {
		return nil, err
	}
	reason := strings.TrimSpace(in.Reason)
	if reason == "" {
		return nil, sharedErrors.ErrValidation
	}
	if err := uc.registrations.Cancel(ctx, in.RegistrationID, reason); err != nil {
		return nil, err
	}
	return uc.registrations.GetRegistrationByID(ctx, in.RegistrationID)
}
