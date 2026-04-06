package event

import (
	"context"

	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
	"github.com/gdg-eskisehir/events/backend/internal/application/validation"
	"github.com/gdg-eskisehir/events/backend/internal/domain"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

type ListPublicEventsUseCase struct {
	events ports.EventRepository
}

func NewListPublicEventsUseCase(events ports.EventRepository) *ListPublicEventsUseCase {
	return &ListPublicEventsUseCase{events: events}
}

// ListPublicEventsInput optionally filters by status; non-published filters yield an empty list for the public surface.
type ListPublicEventsInput struct {
	Status *domain.EventStatus
}

func (uc *ListPublicEventsUseCase) Execute(ctx context.Context, in ListPublicEventsInput) ([]*domain.Event, error) {
	if in.Status != nil && *in.Status != domain.EventStatusPublished {
		return []*domain.Event{}, nil
	}
	return uc.events.List(ctx, ports.EventListFilter{PublishedOnly: true, Status: in.Status})
}

type GetPublicEventUseCase struct {
	events ports.EventRepository
}

func NewGetPublicEventUseCase(events ports.EventRepository) *GetPublicEventUseCase {
	return &GetPublicEventUseCase{events: events}
}

func (uc *GetPublicEventUseCase) Execute(ctx context.Context, eventID string) (*domain.Event, error) {
	if err := validation.RequireUUID(eventID); err != nil {
		return nil, err
	}
	e, err := uc.events.GetByID(ctx, eventID)
	if err != nil {
		return nil, err
	}
	if e == nil || e.Status != domain.EventStatusPublished {
		return nil, sharedErrors.ErrNotFound
	}
	return e, nil
}
