package ports

import (
	"context"

	"github.com/gdg-eskisehir/events/backend/internal/domain"
)

type EventRepository interface {
	GetByID(ctx context.Context, eventID string) (*domain.Event, error)
	GetRegistrationCount(ctx context.Context, eventID string) (int, error)
}

type RegistrationRepository interface {
	GetByEventAndUser(ctx context.Context, eventID, userID string) (*domain.Registration, error)
	Create(ctx context.Context, registration *domain.Registration) error
	GetByEventAndQRCode(ctx context.Context, eventID, qrCode string) (*domain.Registration, error)
}

type UnitOfWork interface {
	WithinTx(ctx context.Context, fn func(ctx context.Context) error) error
}
