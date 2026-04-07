package graphql

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	apiauth "github.com/gdg-eskisehir/events/backend/internal/auth"
	"github.com/gdg-eskisehir/events/backend/internal/domain"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

type fakeVerifier struct {
	tokenToUID map[string]string
}

func (f *fakeVerifier) VerifyIDToken(_ context.Context, rawToken string) (*apiauth.VerifiedToken, error) {
	uid, ok := f.tokenToUID[rawToken]
	if !ok {
		return nil, sharedErrors.ErrUnauthorized
	}
	return &apiauth.VerifiedToken{FirebaseUID: uid}, nil
}

type fakeUsers struct {
	uidToUser map[string]*domain.User
}

func (f *fakeUsers) EnsureFromFirebase(
	_ context.Context,
	firebaseUID, _, _ string,
) (*domain.User, error) {
	u := f.uidToUser[firebaseUID]
	if u == nil || u.ID == "" || !domain.RolesValid(u.Roles) {
		return nil, sharedErrors.ErrUnauthorized
	}
	return u, nil
}

func (f *fakeUsers) GetByID(_ context.Context, id string) (*domain.User, error) {
	for _, u := range f.uidToUser {
		if u != nil && u.ID == id {
			return u, nil
		}
	}
	return nil, sharedErrors.ErrNotFound
}

func (f *fakeUsers) UpdateDisplayName(_ context.Context, _, _ string) error {
	return nil
}

func (f *fakeUsers) ListAll(_ context.Context) ([]*domain.User, error) {
	var out []*domain.User
	for _, u := range f.uidToUser {
		if u != nil {
			out = append(out, u)
		}
	}
	return out, nil
}

func (f *fakeUsers) GrantRole(_ context.Context, _ string, _ domain.Role) error {
	return nil
}

func (f *fakeUsers) RevokeRole(_ context.Context, _ string, _ domain.Role) error {
	return nil
}

func TestActorMiddleware_InjectsActorOnValidBearer(t *testing.T) {
	verifier := &fakeVerifier{tokenToUID: map[string]string{"valid-token": "firebase_1"}}
	users := &fakeUsers{
		uidToUser: map[string]*domain.User{
			"firebase_1": {ID: "user_1", Roles: []domain.Role{domain.RoleMember}},
		},
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

	handler := ActorMiddleware(verifier, users, next)
	req := httptest.NewRequest(http.MethodGet, "/graphql", nil)
	req.Header.Set("Authorization", "Bearer valid-token")
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rec.Code)
	}
	if gotActor.UserID != "user_1" || len(gotActor.Roles) != 1 || gotActor.Roles[0] != domain.RoleMember {
		t.Fatalf("unexpected actor: %+v", gotActor)
	}
}

func TestActorMiddleware_NoHeaderKeepsAnonymousContext(t *testing.T) {
	verifier := &fakeVerifier{tokenToUID: map[string]string{}}
	users := &fakeUsers{uidToUser: map[string]*domain.User{}}

	next := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, err := ActorFromContext(r.Context())
		if err == nil {
			t.Fatalf("expected missing actor for anonymous request")
		}
		w.WriteHeader(http.StatusOK)
	})

	handler := ActorMiddleware(verifier, users, next)
	req := httptest.NewRequest(http.MethodGet, "/graphql", nil)
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rec.Code)
	}
}

func TestActorMiddleware_InvalidBearerSetsAuthErrorInContext(t *testing.T) {
	verifier := &fakeVerifier{tokenToUID: map[string]string{}}
	users := &fakeUsers{uidToUser: map[string]*domain.User{}}

	next := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if err := AuthErrorFromContext(r.Context()); err == nil {
			t.Fatalf("expected auth error in context")
		}
		w.WriteHeader(http.StatusOK)
	})

	handler := ActorMiddleware(verifier, users, next)
	req := httptest.NewRequest(http.MethodGet, "/graphql", nil)
	req.Header.Set("Authorization", "NotBearer x")
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rec.Code)
	}
}
