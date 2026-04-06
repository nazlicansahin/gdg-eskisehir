package event

import (
	"context"

	"github.com/gdg-eskisehir/events/backend/internal/application/policy"
	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
	"github.com/gdg-eskisehir/events/backend/internal/application/validation"
	"github.com/gdg-eskisehir/events/backend/internal/domain"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

type AdminListEventsUseCase struct {
	events ports.EventRepository
}

func NewAdminListEventsUseCase(events ports.EventRepository) *AdminListEventsUseCase {
	return &AdminListEventsUseCase{events: events}
}

type AdminListEventsInput struct {
	ActorRole domain.Role
	Status    *domain.EventStatus
}

func (uc *AdminListEventsUseCase) Execute(ctx context.Context, in AdminListEventsInput) ([]*domain.Event, error) {
	if err := policy.CanAccessAdminAPI(in.ActorRole); err != nil {
		return nil, err
	}
	return uc.events.List(ctx, ports.EventListFilter{PublishedOnly: false, Status: in.Status})
}

type AdminGetEventUseCase struct {
	events ports.EventRepository
}

func NewAdminGetEventUseCase(events ports.EventRepository) *AdminGetEventUseCase {
	return &AdminGetEventUseCase{events: events}
}

type AdminGetEventInput struct {
	ActorRole domain.Role
	EventID   string
}

func (uc *AdminGetEventUseCase) Execute(ctx context.Context, in AdminGetEventInput) (*domain.Event, error) {
	if err := policy.CanAccessAdminAPI(in.ActorRole); err != nil {
		return nil, err
	}
	if err := validation.RequireUUID(in.EventID); err != nil {
		return nil, err
	}
	e, err := uc.events.GetByID(ctx, in.EventID)
	if err != nil {
		return nil, err
	}
	if e == nil {
		return nil, sharedErrors.ErrNotFound
	}
	return e, nil
}
