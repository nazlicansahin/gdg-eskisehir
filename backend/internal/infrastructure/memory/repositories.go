package memory

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/gdg-eskisehir/events/backend/internal/domain"
)

type Repositories struct {
	mu                 sync.RWMutex
	nextRegistrationID int64
	events             map[string]*domain.Event
	registrations      map[string]*domain.Registration
}

func NewRepositories() *Repositories {
	return &Repositories{
		nextRegistrationID: 1,
		events:             make(map[string]*domain.Event),
		registrations:      make(map[string]*domain.Registration),
	}
}

func (r *Repositories) SeedEvent(event *domain.Event) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.events[event.ID] = copyEvent(event)
}

func (r *Repositories) GetByID(_ context.Context, eventID string) (*domain.Event, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	event := r.events[eventID]
	if event == nil {
		return nil, nil
	}
	return copyEvent(event), nil
}

func (r *Repositories) GetRegistrationCount(_ context.Context, eventID string) (int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	count := 0
	for _, registration := range r.registrations {
		if registration.EventID == eventID && registration.Status == domain.RegistrationStatusActive {
			count++
		}
	}
	return count, nil
}

func (r *Repositories) GetByEventAndUser(
	_ context.Context,
	eventID, userID string,
) (*domain.Registration, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	for _, registration := range r.registrations {
		if registration.EventID == eventID && registration.UserID == userID {
			return copyRegistration(registration), nil
		}
	}
	return nil, nil
}

func (r *Repositories) Create(_ context.Context, registration *domain.Registration) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	registrationID := fmt.Sprintf("reg_%d", r.nextRegistrationID)
	r.nextRegistrationID++

	now := time.Now().UTC()
	registration.ID = registrationID
	registration.CreatedAt = now
	registration.UpdatedAt = now
	r.registrations[registration.ID] = copyRegistration(registration)
	return nil
}

func (r *Repositories) GetByEventAndQRCode(
	_ context.Context,
	eventID, qrCode string,
) (*domain.Registration, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	for _, registration := range r.registrations {
		if registration.EventID == eventID && registration.QRCodeValue == qrCode {
			return copyRegistration(registration), nil
		}
	}
	return nil, nil
}

func copyEvent(in *domain.Event) *domain.Event {
	if in == nil {
		return nil
	}
	out := *in
	return &out
}

func copyRegistration(in *domain.Registration) *domain.Registration {
	if in == nil {
		return nil
	}
	out := *in
	return &out
}
