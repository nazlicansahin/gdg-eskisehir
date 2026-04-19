package ports

import (
	"context"

	"github.com/gdg-eskisehir/events/backend/internal/domain"
)

type SponsorRepository interface {
	Create(ctx context.Context, s *domain.Sponsor) error
	ListByEventID(ctx context.Context, eventID string) ([]*domain.Sponsor, error)
	ListGeneral(ctx context.Context) ([]*domain.Sponsor, error)
	ListAll(ctx context.Context) ([]*domain.Sponsor, error)
	Delete(ctx context.Context, id string) error
}
