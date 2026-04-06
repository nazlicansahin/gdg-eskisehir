package graphql

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
	testEvGQL  = "88888888-8888-4888-8888-888888888808"
	testUsGQL  = "ffffffff-ffff-4fff-8fff-ffffffffffff"
	testUsMiss = "99999999-9999-4999-8999-999999999909"
)

func setupResolverForTicketFlow(t *testing.T) *Resolver {
	t.Helper()

	repos := memory.NewRepositories()
	uow := memory.NewUnitOfWork()
	qr := memory.NewQRCodeService()

	repos.SeedEvent(&domain.Event{
		ID:       testEvGQL,
		Status:   domain.EventStatusPublished,
		Capacity: 5,
		StartsAt: time.Now().UTC().Add(24 * time.Hour),
		EndsAt:   time.Now().UTC().Add(26 * time.Hour),
	})

	registerUC := registration.NewRegisterForEventUseCase(uow, repos, repos, qr)
	myTicketUC := registration.NewGetMyTicketUseCase(repos)
	return NewResolver(registerUC, myTicketUC)
}

func TestRegisterForEventResolver_Unauthenticated(t *testing.T) {
	resolver := setupResolverForTicketFlow(t)
	_, err := resolver.Mutation().RegisterForEvent(context.Background(), testEvGQL)
	if err == nil {
		t.Fatalf("expected error for missing actor context")
	}

	gqlErr, ok := err.(*Error)
	if !ok {
		t.Fatalf("expected graphql Error type, got %T", err)
	}
	if gqlErr.Extensions["code"] != sharedErrors.CodeUnauthenticated {
		t.Fatalf("expected code %s, got %v", sharedErrors.CodeUnauthenticated, gqlErr.Extensions["code"])
	}
}

func TestRegisterAndMyTicketResolver_Success(t *testing.T) {
	resolver := setupResolverForTicketFlow(t)
	ctx := WithActor(context.Background(), Actor{
		UserID: testUsGQL,
		Role:   domain.RoleMember,
	})

	registerOut, err := resolver.Mutation().RegisterForEvent(ctx, testEvGQL)
	if err != nil {
		t.Fatalf("register resolver failed: %v", err)
	}
	if registerOut == nil || registerOut.ID == "" || registerOut.QRCodeValue == "" {
		t.Fatalf("expected registration ticket output")
	}

	myTicketOut, err := resolver.Query().MyTicket(ctx, testEvGQL)
	if err != nil {
		t.Fatalf("myTicket resolver failed: %v", err)
	}
	if myTicketOut == nil || myTicketOut.ID == "" {
		t.Fatalf("expected myTicket output")
	}
}

func TestMyTicketResolver_NotFoundMapsToGraphQLCode(t *testing.T) {
	resolver := setupResolverForTicketFlow(t)
	ctx := WithActor(context.Background(), Actor{
		UserID: testUsMiss,
		Role:   domain.RoleMember,
	})

	_, err := resolver.Query().MyTicket(ctx, testEvGQL)
	if err == nil {
		t.Fatalf("expected not found error")
	}
	gqlErr, ok := err.(*Error)
	if !ok {
		t.Fatalf("expected graphql Error type, got %T", err)
	}
	if gqlErr.Extensions["code"] != sharedErrors.CodeNotFound {
		t.Fatalf("expected code %s, got %v", sharedErrors.CodeNotFound, gqlErr.Extensions["code"])
	}
}
