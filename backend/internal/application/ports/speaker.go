package ports

import (
	"context"

	"github.com/gdg-eskisehir/events/backend/internal/domain"
)

type SpeakerRepository interface {
	GetByID(ctx context.Context, id string) (*domain.Speaker, error)
	List(ctx context.Context, query *string) ([]*domain.Speaker, error)
	Create(ctx context.Context, s *domain.Speaker) error
	Update(ctx context.Context, id string, fullName, bio, avatarURL *string) error
}
