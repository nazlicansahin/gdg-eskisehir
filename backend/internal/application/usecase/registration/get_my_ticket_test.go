package registration

import (
	"context"
	"testing"
	"time"

	"github.com/gdg-eskisehir/events/backend/internal/domain"
	"github.com/gdg-eskisehir/events/backend/internal/infrastructure/memory"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

func TestGetMyTicketUseCase_Success(t *testing.T) {
	repos := memory.NewRepositories()
	uow := memory.NewUnitOfWork()
	qr := memory.NewQRCodeService()

	repos.SeedEvent(&domain.Event{
		ID:       "event_10",
		Status:   domain.EventStatusPublished,
		Capacity: 10,
		StartsAt: time.Now().UTC().Add(24 * time.Hour),
		EndsAt:   time.Now().UTC().Add(26 * time.Hour),
	})

	registerUC := NewRegisterForEventUseCase(uow, repos, repos, qr)
	_, err := registerUC.Execute(context.Background(), RegisterForEventInput{
		ActorUserID: "user_a",
		EventID:     "event_10",
	})
	if err != nil {
		t.Fatalf("register setup failed: %v", err)
	}

	getTicketUC := NewGetMyTicketUseCase(repos)
	out, err := getTicketUC.Execute(context.Background(), GetMyTicketInput{
		ActorUserID: "user_a",
		EventID:     "event_10",
	})
	if err != nil {
		t.Fatalf("expected ticket, got error: %v", err)
	}
	if out == nil || out.RegistrationID == "" || out.QRCodeValue == "" {
		t.Fatalf("expected valid ticket output")
	}
}

func TestGetMyTicketUseCase_NotFound(t *testing.T) {
	repos := memory.NewRepositories()
	uc := NewGetMyTicketUseCase(repos)

	_, err := uc.Execute(context.Background(), GetMyTicketInput{
		ActorUserID: "user_missing",
		EventID:     "event_missing",
	})
	if err != sharedErrors.ErrNotFound {
		t.Fatalf("expected ErrNotFound, got %v", err)
	}
}
