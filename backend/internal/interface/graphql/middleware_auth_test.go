package graphql

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gdg-eskisehir/events/backend/internal/domain"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

type fakeVerifier struct {
	tokenToUID map[string]string
}

func (f *fakeVerifier) VerifyIDToken(_ context.Context, rawToken string) (*VerifiedToken, error) {
	uid, ok := f.tokenToUID[rawToken]
	if !ok {
		return nil, sharedErrors.ErrUnauthorized
	}
	return &VerifiedToken{FirebaseUID: uid}, nil
}

type fakeLookup struct {
	uidToUserID map[string]string
	uidToRole   map[string]domain.Role
}

func (f *fakeLookup) GetUserRoleByFirebaseUID(
	_ context.Context,
	firebaseUID string,
) (string, domain.Role, error) {
	userID := f.uidToUserID[firebaseUID]
	role := f.uidToRole[firebaseUID]
	if userID == "" || !role.IsValid() {
		return "", "", sharedErrors.ErrUnauthorized
	}
	return userID, role, nil
}

func TestActorMiddleware_InjectsActorOnValidBearer(t *testing.T) {
	verifier := &fakeVerifier{tokenToUID: map[string]string{"valid-token": "firebase_1"}}
	lookup := &fakeLookup{
		uidToUserID: map[string]string{"firebase_1": "user_1"},
		uidToRole:   map[string]domain.Role{"firebase_1": domain.RoleMember},
	}

	var gotActor Actor
	next := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		actor, err := ActorFromContext(r.Context())
		if err != nil {
			t.Fatalf("expected actor in context, got error: %v", err)
		}
		gotActor = actor
		w.WriteHeader(http.StatusOK)
	})

	handler := ActorMiddleware(verifier, lookup, next)
	req := httptest.NewRequest(http.MethodGet, "/graphql", nil)
	req.Header.Set("Authorization", "Bearer valid-token")
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rec.Code)
	}
	if gotActor.UserID != "user_1" || gotActor.Role != domain.RoleMember {
		t.Fatalf("unexpected actor: %+v", gotActor)
	}
}

func TestActorMiddleware_NoHeaderKeepsAnonymousContext(t *testing.T) {
	verifier := &fakeVerifier{tokenToUID: map[string]string{}}
	lookup := &fakeLookup{
		uidToUserID: map[string]string{},
		uidToRole:   map[string]domain.Role{},
	}

	next := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, err := ActorFromContext(r.Context())
		if err == nil {
			t.Fatalf("expected missing actor for anonymous request")
		}
		w.WriteHeader(http.StatusOK)
	})

	handler := ActorMiddleware(verifier, lookup, next)
	req := httptest.NewRequest(http.MethodGet, "/graphql", nil)
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rec.Code)
	}
}

func TestActorMiddleware_InvalidBearerSetsAuthErrorInContext(t *testing.T) {
	verifier := &fakeVerifier{tokenToUID: map[string]string{}}
	lookup := &fakeLookup{
		uidToUserID: map[string]string{},
		uidToRole:   map[string]domain.Role{},
	}

	next := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if err := AuthErrorFromContext(r.Context()); err == nil {
			t.Fatalf("expected auth error in context")
		}
		w.WriteHeader(http.StatusOK)
	})

	handler := ActorMiddleware(verifier, lookup, next)
	req := httptest.NewRequest(http.MethodGet, "/graphql", nil)
	req.Header.Set("Authorization", "NotBearer x")
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rec.Code)
	}
}
