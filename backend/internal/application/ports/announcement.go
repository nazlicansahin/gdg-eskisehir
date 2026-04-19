package ports

import (
	"context"

	"github.com/gdg-eskisehir/events/backend/internal/domain"
)

type AnnouncementRepository interface {
	Create(ctx context.Context, a *domain.Announcement) error
	ListByEventID(ctx context.Context, eventID string) ([]*domain.Announcement, error)
	ListGeneral(ctx context.Context) ([]*domain.Announcement, error)
	ListAll(ctx context.Context) ([]*domain.Announcement, error)
}
