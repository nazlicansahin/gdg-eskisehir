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

const (
	testEvChk    = "66666666-6666-4666-8666-666666666606"
	testUsReg    = "dddddddd-dddd-4ddd-8ddd-dddddddddddd"
	testUsStaff  = "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee"
	testEvChkEmp = "77777777-7777-4777-8777-777777777707"
)

func TestCheckInByQRUseCase_Success(t *testing.T) {
	repos := memory.NewRepositories()
	uow := memory.NewUnitOfWork()
	qr := memory.NewQRCodeService()
	repos.SeedEvent(&domain.Event{
		ID:       testEvChk,
		Status:   domain.EventStatusPublished,
		Capacity: 10,
		StartsAt: time.Now().UTC().Add(24 * time.Hour),
		EndsAt:   time.Now().UTC().Add(26 * time.Hour),
	})

	registerUC := registration.NewRegisterForEventUseCase(uow, repos, repos, qr)
	regOut, err := registerUC.Execute(context.Background(), registration.RegisterForEventInput{
		ActorUserID: testUsReg,
		EventID:     testEvChk,
	})
	if err != nil {
		t.Fatalf("register setup failed: %v", err)
	}

	checkinUC := NewCheckInByQRUseCase(uow, repos)
	out, err := checkinUC.Execute(context.Background(), CheckInByQRInput{
		ActorUserID: testUsStaff,
		ActorRoles:  []domain.Role{domain.RoleTeamMember},
		EventID:     testEvChk,
		QRCode:      regOut.QRCodeValue,
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
	uow := memory.NewUnitOfWork()
	uc := NewCheckInByQRUseCase(uow, repos)
	_, err := uc.Execute(context.Background(), CheckInByQRInput{
		ActorUserID: testUsReg,
		ActorRoles:  []domain.Role{domain.RoleMember},
		EventID:     testEvChk,
		QRCode:      "any",
	})
	if err != sharedErrors.ErrForbidden {
		t.Fatalf("expected ErrForbidden, got %v", err)
	}
}

func TestCheckInByQRUseCase_InvalidQRCode(t *testing.T) {
	repos := memory.NewRepositories()
	uow := memory.NewUnitOfWork()
	uc := NewCheckInByQRUseCase(uow, repos)
	_, err := uc.Execute(context.Background(), CheckInByQRInput{
		ActorUserID: testUsStaff,
		ActorRoles:  []domain.Role{domain.RoleOrganizer},
		EventID:     testEvChkEmp,
		QRCode:      "missing",
	})
	if err != sharedErrors.ErrInvalidQRCode {
		t.Fatalf("expected ErrInvalidQRCode, got %v", err)
	}
}
