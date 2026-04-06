package ports

import (
	"context"

	"github.com/gdg-eskisehir/events/backend/internal/domain"
)

type UserRepository interface {
	EnsureFromFirebase(ctx context.Context, firebaseUID, email, displayName string) (*domain.User, error)
	GetByID(ctx context.Context, id string) (*domain.User, error)
	UpdateDisplayName(ctx context.Context, userID, displayName string) error
	ListAll(ctx context.Context) ([]*domain.User, error)
	UpdateRole(ctx context.Context, userID string, role domain.Role) error
}
