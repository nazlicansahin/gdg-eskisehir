package registration

import (
	"context"
	"testing"
	"time"

	"github.com/gdg-eskisehir/events/backend/internal/domain"
	"github.com/gdg-eskisehir/events/backend/internal/infrastructure/memory"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

func TestRegisterForEventUseCase_Success(t *testing.T) {
	repos := memory.NewRepositories()
	uow := memory.NewUnitOfWork()
	qr := memory.NewQRCodeService()
	repos.SeedEvent(&domain.Event{
		ID:       "event_1",
		Status:   domain.EventStatusPublished,
		Capacity: 2,
		StartsAt: time.Now().UTC().Add(24 * time.Hour),
		EndsAt:   time.Now().UTC().Add(26 * time.Hour),
	})

	uc := NewRegisterForEventUseCase(uow, repos, repos, qr)
	out, err := uc.Execute(context.Background(), RegisterForEventInput{
		ActorUserID: "user_1",
		EventID:     "event_1",
	})
	if err != nil {
		t.Fatalf("expected nil error, got %v", err)
	}
	if out == nil || out.RegistrationID == "" || out.QRCodeValue == "" {
		t.Fatalf("expected registration output with id and qr code")
	}
	if out.Status != domain.RegistrationStatusActive {
		t.Fatalf("expected active status, got %s", out.Status)
	}
}

func TestRegisterForEventUseCase_AlreadyRegistered(t *testing.T) {
	repos := memory.NewRepositories()
	uow := memory.NewUnitOfWork()
	qr := memory.NewQRCodeService()
	repos.SeedEvent(&domain.Event{
		ID:       "event_2",
		Status:   domain.EventStatusPublished,
		Capacity: 2,
		StartsAt: time.Now().UTC().Add(24 * time.Hour),
		EndsAt:   time.Now().UTC().Add(26 * time.Hour),
	})

	uc := NewRegisterForEventUseCase(uow, repos, repos, qr)
	_, err := uc.Execute(context.Background(), RegisterForEventInput{
		ActorUserID: "user_1",
		EventID:     "event_2",
	})
	if err != nil {
		t.Fatalf("expected first register to succeed, got %v", err)
	}

	_, err = uc.Execute(context.Background(), RegisterForEventInput{
		ActorUserID: "user_1",
		EventID:     "event_2",
	})
	if err != sharedErrors.ErrAlreadyRegistered {
		t.Fatalf("expected ErrAlreadyRegistered, got %v", err)
	}
}

func TestRegisterForEventUseCase_CapacityReached(t *testing.T) {
	repos := memory.NewRepositories()
	uow := memory.NewUnitOfWork()
	qr := memory.NewQRCodeService()
	repos.SeedEvent(&domain.Event{
		ID:       "event_3",
		Status:   domain.EventStatusPublished,
		Capacity: 1,
		StartsAt: time.Now().UTC().Add(24 * time.Hour),
		EndsAt:   time.Now().UTC().Add(26 * time.Hour),
	})

	uc := NewRegisterForEventUseCase(uow, repos, repos, qr)
	_, err := uc.Execute(context.Background(), RegisterForEventInput{
		ActorUserID: "user_1",
		EventID:     "event_3",
	})
	if err != nil {
		t.Fatalf("expected first register to succeed, got %v", err)
	}

	_, err = uc.Execute(context.Background(), RegisterForEventInput{
		ActorUserID: "user_2",
		EventID:     "event_3",
	})
	if err != sharedErrors.ErrCapacityReached {
		t.Fatalf("expected ErrCapacityReached, got %v", err)
	}
}
