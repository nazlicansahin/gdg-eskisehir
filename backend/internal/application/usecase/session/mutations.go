package session

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

type CreateSessionUseCase struct {
	events   ports.EventRepository
	sessions ports.SessionRepository
}

func NewCreateSessionUseCase(events ports.EventRepository, sessions ports.SessionRepository) *CreateSessionUseCase {
	return &CreateSessionUseCase{events: events, sessions: sessions}
}

type CreateSessionInput struct {
	ActorRoles  []domain.Role
	EventID     string
	Title       string
	Description string
	StartsAt    time.Time
	EndsAt      time.Time
	Room        string
}

func (uc *CreateSessionUseCase) Execute(ctx context.Context, in CreateSessionInput) (*domain.Session, error) {
	if err := policy.CanCreateEvent(in.ActorRoles); err != nil {
		return nil, err
	}
	if err := validation.RequireUUID(in.EventID); err != nil {
		return nil, err
	}
	title := strings.TrimSpace(in.Title)
	if title == "" {
		return nil, sharedErrors.ErrValidation
	}
	if !in.EndsAt.After(in.StartsAt) {
		return nil, sharedErrors.ErrValidation
	}
	ev, err := uc.events.GetByID(ctx, in.EventID)
	if err != nil {
		return nil, err
	}
	if ev == nil {
		return nil, sharedErrors.ErrNotFound
	}
	s := &domain.Session{
		EventID:     in.EventID,
		Title:       title,
		Description: strings.TrimSpace(in.Description),
		Room:        strings.TrimSpace(in.Room),
		StartsAt:    in.StartsAt,
		EndsAt:      in.EndsAt,
		SortOrder:   0,
	}
	if err := uc.sessions.Create(ctx, s); err != nil {
		return nil, err
	}
	return s, nil
}

type UpdateSessionUseCase struct {
	sessions ports.SessionRepository
}

func NewUpdateSessionUseCase(sessions ports.SessionRepository) *UpdateSessionUseCase {
	return &UpdateSessionUseCase{sessions: sessions}
}

type UpdateSessionInput struct {
	ActorRoles  []domain.Role
	SessionID   string
	Title       *string
	Description *string
	Room        *string
	StartsAt    *time.Time
	EndsAt      *time.Time
}

func (uc *UpdateSessionUseCase) Execute(ctx context.Context, in UpdateSessionInput) (*domain.Session, error) {
	if err := policy.CanCreateEvent(in.ActorRoles); err != nil {
		return nil, err
	}
	if err := validation.RequireUUID(in.SessionID); err != nil {
		return nil, err
	}
	cur, err := uc.sessions.GetByID(ctx, in.SessionID)
	if err != nil {
		return nil, err
	}
	if cur == nil {
		return nil, sharedErrors.ErrNotFound
	}
	nextStart := cur.StartsAt
	nextEnd := cur.EndsAt
	if in.StartsAt != nil {
		nextStart = *in.StartsAt
	}
	if in.EndsAt != nil {
		nextEnd = *in.EndsAt
	}
	if !nextEnd.After(nextStart) {
		return nil, sharedErrors.ErrValidation
	}
	if in.Title != nil && strings.TrimSpace(*in.Title) == "" {
		return nil, sharedErrors.ErrValidation
	}
	t := in.Title
	if t != nil {
		v := strings.TrimSpace(*t)
		t = &v
	}
	if err := uc.sessions.Update(ctx, in.SessionID, t, in.Description, in.Room, in.StartsAt, in.EndsAt); err != nil {
		return nil, err
	}
	return uc.sessions.GetByID(ctx, in.SessionID)
}
