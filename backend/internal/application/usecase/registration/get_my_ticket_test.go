package registration

import (
	"context"
	"testing"
	"time"

	"github.com/gdg-eskisehir/events/backend/internal/domain"
	"github.com/gdg-eskisehir/events/backend/internal/infrastructure/memory"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

const (
	testEvTicket = "44444444-4444-4444-8444-444444444404"
	testUsTicket = "cccccccc-cccc-4ccc-8ccc-ccccccccccc4"
	testEvAbsent = "55555555-5555-4555-8555-555555555505"
)

func TestGetMyTicketUseCase_Success(t *testing.T) {
	repos := memory.NewRepositories()
	uow := memory.NewUnitOfWork()
	qr := memory.NewQRCodeService()

	repos.SeedEvent(&domain.Event{
		ID:       testEvTicket,
		Status:   domain.EventStatusPublished,
		Capacity: 10,
		StartsAt: time.Now().UTC().Add(24 * time.Hour),
		EndsAt:   time.Now().UTC().Add(26 * time.Hour),
	})

	registerUC := NewRegisterForEventUseCase(uow, repos, repos, qr)
	_, err := registerUC.Execute(context.Background(), RegisterForEventInput{
		ActorUserID: testUsTicket,
		EventID:     testEvTicket,
	})
	if err != nil {
		t.Fatalf("register setup failed: %v", err)
	}

	getTicketUC := NewGetMyTicketUseCase(repos)
	out, err := getTicketUC.Execute(context.Background(), GetMyTicketInput{
		ActorUserID: testUsTicket,
		EventID:     testEvTicket,
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
		ActorUserID: testUser1,
		EventID:     testEvAbsent,
	})
	if err != sharedErrors.ErrNotFound {
		t.Fatalf("expected ErrNotFound, got %v", err)
	}
}
