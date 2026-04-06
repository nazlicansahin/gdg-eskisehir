package ports

import (
	"context"

	"github.com/gdg-eskisehir/events/backend/internal/domain"
)

type RegistrationRepository interface {
	GetRegistrationByID(ctx context.Context, id string) (*domain.Registration, error)
	GetByEventAndUser(ctx context.Context, eventID, userID string) (*domain.Registration, error)
	Create(ctx context.Context, registration *domain.Registration) error
	GetByEventAndQRCode(ctx context.Context, eventID, qrCode string) (*domain.Registration, error)
	CompleteCheckIn(ctx context.Context, registrationID, eventID, checkedInByUserID, method string) error
	ListByUserID(ctx context.Context, userID string) ([]*domain.Registration, error)
	ListByEventID(ctx context.Context, eventID string) ([]*domain.Registration, error)
	Cancel(ctx context.Context, registrationID, reason string) error
}
