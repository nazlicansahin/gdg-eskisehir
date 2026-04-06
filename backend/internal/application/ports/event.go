package ports

import (
	"context"
	"time"

	"github.com/gdg-eskisehir/events/backend/internal/domain"
)

// EventListFilter controls listing events for public vs admin surfaces.
type EventListFilter struct {
	PublishedOnly bool
	Status        *domain.EventStatus
}

type EventRepository interface {
	GetByID(ctx context.Context, eventID string) (*domain.Event, error)
	GetRegistrationCount(ctx context.Context, eventID string) (int, error)
	List(ctx context.Context, filter EventListFilter) ([]*domain.Event, error)
	Insert(ctx context.Context, e *domain.Event) error
	Update(
		ctx context.Context,
		id string,
		title, description *string,
		capacity *int,
		startsAt, endsAt *time.Time,
	) error
	SetStatus(ctx context.Context, id string, status domain.EventStatus) error
}
