package memory

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
	"github.com/gdg-eskisehir/events/backend/internal/domain"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

type Repositories struct {
	mu                 sync.RWMutex
	nextRegistrationID int64
	nextEventID        int64
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

func (r *Repositories) List(_ context.Context, filter ports.EventListFilter) ([]*domain.Event, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	var out []*domain.Event
	for _, e := range r.events {
		ev := copyEvent(e)
		if filter.PublishedOnly && ev.Status != domain.EventStatusPublished {
			continue
		}
		if filter.Status != nil && ev.Status != *filter.Status {
			continue
		}
		out = append(out, ev)
	}
	return out, nil
}

func (r *Repositories) Insert(_ context.Context, e *domain.Event) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if e.ID == "" {
		r.nextEventID++
		e.ID = fmt.Sprintf("eeeeeeee-eeee-4eee-8eee-%012d", r.nextEventID)
	}
	now := time.Now().UTC()
	if e.CreatedAt.IsZero() {
		e.CreatedAt = now
	}
	e.UpdatedAt = now
	r.events[e.ID] = copyEvent(e)
	return nil
}

func (r *Repositories) Update(
	_ context.Context,
	id string,
	title, description *string,
	capacity *int,
	startsAt, endsAt *time.Time,
) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	e := r.events[id]
	if e == nil {
		return sharedErrors.ErrNotFound
	}
	ev := copyEvent(e)
	if title != nil {
		ev.Title = *title
	}
	if description != nil {
		ev.Description = *description
	}
	if capacity != nil {
		ev.Capacity = *capacity
	}
	if startsAt != nil {
		ev.StartsAt = *startsAt
	}
	if endsAt != nil {
		ev.EndsAt = *endsAt
	}
	ev.UpdatedAt = time.Now().UTC()
	r.events[id] = ev
	return nil
}

func (r *Repositories) SetStatus(_ context.Context, id string, status domain.EventStatus) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	e := r.events[id]
	if e == nil {
		return sharedErrors.ErrNotFound
	}
	ev := copyEvent(e)
	ev.Status = status
	ev.UpdatedAt = time.Now().UTC()
	r.events[id] = ev
	return nil
}

func (r *Repositories) GetRegistrationByID(_ context.Context, id string) (*domain.Registration, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	for _, registration := range r.registrations {
		if registration.ID == id {
			return copyRegistration(registration), nil
		}
	}
	return nil, nil
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

func (r *Repositories) CompleteCheckIn(
	_ context.Context,
	registrationID, eventID, checkedInByUserID, method string,
) error {
	_ = checkedInByUserID
	_ = method
	r.mu.Lock()
	defer r.mu.Unlock()
	for id, registration := range r.registrations {
		if registration.ID != registrationID || registration.EventID != eventID {
			continue
		}
		if registration.Status != domain.RegistrationStatusActive {
			return nil
		}
		if registration.CheckedInAt != nil {
			return sharedErrors.ErrAlreadyCheckedIn
		}
		now := time.Now().UTC()
		registration.CheckedInAt = &now
		r.registrations[id] = copyRegistration(registration)
		return nil
	}
	return sharedErrors.ErrNotFound
}

func (r *Repositories) ListByUserID(_ context.Context, userID string) ([]*domain.Registration, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	var out []*domain.Registration
	for _, reg := range r.registrations {
		if reg.UserID == userID {
			out = append(out, copyRegistration(reg))
		}
	}
	return out, nil
}

func (r *Repositories) ListByEventID(_ context.Context, eventID string) ([]*domain.Registration, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	var out []*domain.Registration
	for _, reg := range r.registrations {
		if reg.EventID == eventID {
			out = append(out, copyRegistration(reg))
		}
	}
	return out, nil
}

func (r *Repositories) Cancel(_ context.Context, registrationID, reason string) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	for k, reg := range r.registrations {
		if reg.ID != registrationID {
			continue
		}
		if reg.Status != domain.RegistrationStatusActive {
			return sharedErrors.ErrConflict
		}
		now := time.Now().UTC()
		reasonCopy := reason
		reg.Status = domain.RegistrationStatusCancelled
		reg.CancelReason = &reasonCopy
		reg.CancelledAt = &now
		reg.UpdatedAt = now
		r.registrations[k] = copyRegistration(reg)
		return nil
	}
	return sharedErrors.ErrNotFound
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
