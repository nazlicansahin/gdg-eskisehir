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
	testEvReg1 = "11111111-1111-4111-8111-111111111101"
	testEvReg2 = "22222222-2222-4222-8222-222222222202"
	testEvReg3 = "33333333-3333-4333-8333-333333333303"
	testUser1  = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1"
	testUser2  = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2"
)

func TestRegisterForEventUseCase_Success(t *testing.T) {
	repos := memory.NewRepositories()
	uow := memory.NewUnitOfWork()
	qr := memory.NewQRCodeService()
	repos.SeedEvent(&domain.Event{
		ID:       testEvReg1,
		Status:   domain.EventStatusPublished,
		Capacity: 2,
		StartsAt: time.Now().UTC().Add(24 * time.Hour),
		EndsAt:   time.Now().UTC().Add(26 * time.Hour),
	})

	uc := NewRegisterForEventUseCase(uow, repos, repos, qr)
	out, err := uc.Execute(context.Background(), RegisterForEventInput{
		ActorUserID: testUser1,
		EventID:     testEvReg1,
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
		ID:       testEvReg2,
		Status:   domain.EventStatusPublished,
		Capacity: 2,
		StartsAt: time.Now().UTC().Add(24 * time.Hour),
		EndsAt:   time.Now().UTC().Add(26 * time.Hour),
	})

	uc := NewRegisterForEventUseCase(uow, repos, repos, qr)
	_, err := uc.Execute(context.Background(), RegisterForEventInput{
		ActorUserID: testUser1,
		EventID:     testEvReg2,
	})
	if err != nil {
		t.Fatalf("expected first register to succeed, got %v", err)
	}

	_, err = uc.Execute(context.Background(), RegisterForEventInput{
		ActorUserID: testUser1,
		EventID:     testEvReg2,
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
		ID:       testEvReg3,
		Status:   domain.EventStatusPublished,
		Capacity: 1,
		StartsAt: time.Now().UTC().Add(24 * time.Hour),
		EndsAt:   time.Now().UTC().Add(26 * time.Hour),
	})

	uc := NewRegisterForEventUseCase(uow, repos, repos, qr)
	_, err := uc.Execute(context.Background(), RegisterForEventInput{
		ActorUserID: testUser1,
		EventID:     testEvReg3,
	})
	if err != nil {
		t.Fatalf("expected first register to succeed, got %v", err)
	}

	_, err = uc.Execute(context.Background(), RegisterForEventInput{
		ActorUserID: testUser2,
		EventID:     testEvReg3,
	})
	if err != sharedErrors.ErrCapacityReached {
		t.Fatalf("expected ErrCapacityReached, got %v", err)
	}
}
