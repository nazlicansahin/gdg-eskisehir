package checkin

import (
	"context"
	"testing"
	"time"

	"github.com/gdg-eskisehir/events/backend/internal/application/usecase/registration"
	"github.com/gdg-eskisehir/events/backend/internal/domain"
	"github.com/gdg-eskisehir/events/backend/internal/infrastructure/memory"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

func TestCheckInByQRUseCase_Success(t *testing.T) {
	repos := memory.NewRepositories()
	uow := memory.NewUnitOfWork()
	qr := memory.NewQRCodeService()
	repos.SeedEvent(&domain.Event{
		ID:       "event_ck_1",
		Status:   domain.EventStatusPublished,
		Capacity: 10,
		StartsAt: time.Now().UTC().Add(24 * time.Hour),
		EndsAt:   time.Now().UTC().Add(26 * time.Hour),
	})

	registerUC := registration.NewRegisterForEventUseCase(uow, repos, repos, qr)
	regOut, err := registerUC.Execute(context.Background(), registration.RegisterForEventInput{
		ActorUserID: "user_1",
		EventID:     "event_ck_1",
	})
	if err != nil {
		t.Fatalf("register setup failed: %v", err)
	}

	checkinUC := NewCheckInByQRUseCase(repos)
	out, err := checkinUC.Execute(context.Background(), CheckInByQRInput{
		ActorRole: domain.RoleTeamMember,
		EventID:   "event_ck_1",
		QRCode:    regOut.QRCodeValue,
	})
	if err != nil {
		t.Fatalf("expected successful check-in validation, got %v", err)
	}
	if out == nil || out.RegistrationID == "" {
		t.Fatalf("expected check-in output")
	}
}

func TestCheckInByQRUseCase_ForbiddenRole(t *testing.T) {
	repos := memory.NewRepositories()
	uc := NewCheckInByQRUseCase(repos)
	_, err := uc.Execute(context.Background(), CheckInByQRInput{
		ActorRole: domain.RoleMember,
		EventID:   "event_1",
		QRCode:    "any",
	})
	if err != sharedErrors.ErrForbidden {
		t.Fatalf("expected ErrForbidden, got %v", err)
	}
}

func TestCheckInByQRUseCase_InvalidQRCode(t *testing.T) {
	repos := memory.NewRepositories()
	uc := NewCheckInByQRUseCase(repos)
	_, err := uc.Execute(context.Background(), CheckInByQRInput{
		ActorRole: domain.RoleOrganizer,
		EventID:   "event_1",
		QRCode:    "missing",
	})
	if err != sharedErrors.ErrInvalidQRCode {
		t.Fatalf("expected ErrInvalidQRCode, got %v", err)
	}
}
