package ports

import (
	"context"
	"time"

	"github.com/gdg-eskisehir/events/backend/internal/domain"
)

type SessionRepository interface {
	GetByID(ctx context.Context, id string) (*domain.Session, error)
	ListByEventID(ctx context.Context, eventID string) ([]*domain.Session, error)
	Create(ctx context.Context, s *domain.Session) error
	Update(
		ctx context.Context,
		id string,
		title, description, room *string,
		startsAt, endsAt *time.Time,
	) error
	ListSpeakerIDsForSession(ctx context.Context, sessionID string) ([]string, error)
	AttachSpeaker(ctx context.Context, sessionID, speakerID string) error
}
