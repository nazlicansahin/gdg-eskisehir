package event

import (
	"context"
	"strings"
	"time"

	"github.com/gdg-eskisehir/events/backend/internal/application/policy"
	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
	"github.com/gdg-eskisehir/events/backend/internal/application/validation"
	"github.com/gdg-eskisehir/events/backend/internal/domain"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

type CreateEventUseCase struct {
	events ports.EventRepository
}

func NewCreateEventUseCase(events ports.EventRepository) *CreateEventUseCase {
	return &CreateEventUseCase{events: events}
}

type CreateEventInput struct {
	ActorRoles  []domain.Role
	Title       string
	Description string
	Capacity    int
	StartsAt    time.Time
	EndsAt      time.Time
}

func (uc *CreateEventUseCase) Execute(ctx context.Context, in CreateEventInput) (*domain.Event, error) {
	if err := policy.CanCreateEvent(in.ActorRoles); err != nil {
		return nil, err
	}
	if err := validateEventTimesAndCapacity(in.Capacity, in.StartsAt, in.EndsAt); err != nil {
		return nil, err
	}
	title := strings.TrimSpace(in.Title)
	if title == "" {
		return nil, sharedErrors.ErrValidation
	}
	e := &domain.Event{
		Title:       title,
		Description: strings.TrimSpace(in.Description),
		Status:      domain.EventStatusDraft,
		Capacity:    in.Capacity,
		StartsAt:    in.StartsAt,
		EndsAt:      in.EndsAt,
	}
	if err := uc.events.Insert(ctx, e); err != nil {
		return nil, err
	}
	return e, nil
}

type UpdateEventUseCase struct {
	events ports.EventRepository
}

func NewUpdateEventUseCase(events ports.EventRepository) *UpdateEventUseCase {
	return &UpdateEventUseCase{events: events}
}

type UpdateEventInput struct {
	ActorRoles  []domain.Role
	EventID     string
	Title       *string
	Description *string
	Capacity    *int
	StartsAt    *time.Time
	EndsAt      *time.Time
}

func (uc *UpdateEventUseCase) Execute(ctx context.Context, in UpdateEventInput) (*domain.Event, error) {
	if err := policy.CanCreateEvent(in.ActorRoles); err != nil {
		return nil, err
	}
	if err := validation.RequireUUID(in.EventID); err != nil {
		return nil, err
	}
	cur, err := uc.events.GetByID(ctx, in.EventID)
	if err != nil {
		return nil, err
	}
	if cur == nil {
		return nil, sharedErrors.ErrNotFound
	}
	nextCap := cur.Capacity
	nextStart := cur.StartsAt
	nextEnd := cur.EndsAt
	if in.Capacity != nil {
		nextCap = *in.Capacity
	}
	if in.StartsAt != nil {
		nextStart = *in.StartsAt
	}
	if in.EndsAt != nil {
		nextEnd = *in.EndsAt
	}
	if err := validateEventTimesAndCapacity(nextCap, nextStart, nextEnd); err != nil {
		return nil, err
	}
	if in.Title != nil && strings.TrimSpace(*in.Title) == "" {
		return nil, sharedErrors.ErrValidation
	}
	t := in.Title
	if t != nil {
		trim := strings.TrimSpace(*t)
		t = &trim
	}
	if err := uc.events.Update(ctx, in.EventID, t, in.Description, in.Capacity, in.StartsAt, in.EndsAt); err != nil {
		return nil, err
	}
	return uc.events.GetByID(ctx, in.EventID)
}

type PublishEventUseCase struct {
	events ports.EventRepository
}

func NewPublishEventUseCase(events ports.EventRepository) *PublishEventUseCase {
	return &PublishEventUseCase{events: events}
}

type PublishEventInput struct {
	ActorRoles []domain.Role
	EventID   string
}

func (uc *PublishEventUseCase) Execute(ctx context.Context, in PublishEventInput) (*domain.Event, error) {
	if err := policy.CanPublishEvent(in.ActorRoles); err != nil {
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
	if e.Status == domain.EventStatusCancelled {
		return nil, sharedErrors.ErrConflict
	}
	if err := uc.events.SetStatus(ctx, in.EventID, domain.EventStatusPublished); err != nil {
		return nil, err
	}
	return uc.events.GetByID(ctx, in.EventID)
}

type CancelEventUseCase struct {
	events ports.EventRepository
}

func NewCancelEventUseCase(events ports.EventRepository) *CancelEventUseCase {
	return &CancelEventUseCase{events: events}
}

type CancelEventInput struct {
	ActorRoles []domain.Role
	EventID   string
	Reason    string
}

func (uc *CancelEventUseCase) Execute(ctx context.Context, in CancelEventInput) (*domain.Event, error) {
	if err := policy.CanCancelEvent(in.ActorRoles); err != nil {
		return nil, err
	}
	if err := validation.RequireUUID(in.EventID); err != nil {
		return nil, err
	}
	if strings.TrimSpace(in.Reason) == "" {
		return nil, sharedErrors.ErrValidation
	}
	e, err := uc.events.GetByID(ctx, in.EventID)
	if err != nil {
		return nil, err
	}
	if e == nil {
		return nil, sharedErrors.ErrNotFound
	}
	if e.Status == domain.EventStatusCancelled {
		return e, nil
	}
	if err := uc.events.SetStatus(ctx, in.EventID, domain.EventStatusCancelled); err != nil {
		return nil, err
	}
	return uc.events.GetByID(ctx, in.EventID)
}

func validateEventTimesAndCapacity(capacity int, start, end time.Time) error {
	if capacity < 0 {
		return sharedErrors.ErrValidation
	}
	if !end.After(start) {
		return sharedErrors.ErrValidation
	}
	return nil
}
