package schedule

import (
	"context"

	"github.com/gdg-eskisehir/events/backend/internal/application/policy"
	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
	"github.com/gdg-eskisehir/events/backend/internal/application/validation"
	"github.com/gdg-eskisehir/events/backend/internal/domain"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

// SessionWithSpeakers is a session plus resolved speakers (for GraphQL mapping).
type SessionWithSpeakers struct {
	Session  *domain.Session
	Speakers []*domain.Speaker
}

type ListEventScheduleUseCase struct {
	events   ports.EventRepository
	sessions ports.SessionRepository
	speakers ports.SpeakerRepository
}

func NewListEventScheduleUseCase(
	events ports.EventRepository,
	sessions ports.SessionRepository,
	speakers ports.SpeakerRepository,
) *ListEventScheduleUseCase {
	return &ListEventScheduleUseCase{events: events, sessions: sessions, speakers: speakers}
}

type ListEventScheduleInput struct {
	ActorRoles []domain.Role // used when RequirePublished is false (admin path)
	EventID   string
	// When true, event must be published (user-facing query).
	RequirePublished bool
}

func (uc *ListEventScheduleUseCase) Execute(ctx context.Context, in ListEventScheduleInput) ([]SessionWithSpeakers, error) {
	if err := validation.RequireUUID(in.EventID); err != nil {
		return nil, err
	}
	ev, err := uc.events.GetByID(ctx, in.EventID)
	if err != nil {
		return nil, err
	}
	if ev == nil {
		return nil, sharedErrors.ErrNotFound
	}
	if in.RequirePublished {
		if ev.Status != domain.EventStatusPublished {
			return nil, sharedErrors.ErrNotFound
		}
	} else {
		if err := policy.CanAccessAdminAPI(in.ActorRoles); err != nil {
			return nil, err
		}
	}

	sess, err := uc.sessions.ListByEventID(ctx, in.EventID)
	if err != nil {
		return nil, err
	}
	out := make([]SessionWithSpeakers, 0, len(sess))
	for _, s := range sess {
		sw := SessionWithSpeakers{Session: s}
		ids, err := uc.sessions.ListSpeakerIDsForSession(ctx, s.ID)
		if err != nil {
			return nil, err
		}
		for _, sid := range ids {
			sp, err := uc.speakers.GetByID(ctx, sid)
			if err != nil {
				return nil, err
			}
			if sp != nil {
				sw.Speakers = append(sw.Speakers, sp)
			}
		}
		out = append(out, sw)
	}
	return out, nil
}
