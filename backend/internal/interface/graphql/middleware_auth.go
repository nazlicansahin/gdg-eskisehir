package graphql

import (
	"context"
	"net/http"
	"strings"

	"github.com/gdg-eskisehir/events/backend/internal/domain"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

type VerifiedToken struct {
	FirebaseUID string
}

type tokenVerifier interface {
	VerifyIDToken(ctx context.Context, rawToken string) (*VerifiedToken, error)
}

type userRoleLookup interface {
	GetUserRoleByFirebaseUID(ctx context.Context, firebaseUID string) (userID string, role domain.Role, err error)
}

func ActorMiddleware(
	verifier tokenVerifier,
	lookup userRoleLookup,
	next http.Handler,
) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			next.ServeHTTP(w, r)
			return
		}

		rawToken, err := parseBearerToken(authHeader)
		if err != nil {
			next.ServeHTTP(w, r.WithContext(withAuthError(r.Context(), err)))
			return
		}

		verified, err := verifier.VerifyIDToken(r.Context(), rawToken)
		if err != nil || verified == nil || verified.FirebaseUID == "" {
			next.ServeHTTP(w, r.WithContext(withAuthError(r.Context(), sharedErrors.ErrUnauthorized)))
			return
		}

		userID, role, err := lookup.GetUserRoleByFirebaseUID(r.Context(), verified.FirebaseUID)
		if err != nil || userID == "" || !role.IsValid() {
			next.ServeHTTP(w, r.WithContext(withAuthError(r.Context(), sharedErrors.ErrUnauthorized)))
			return
		}

		ctx := WithActor(r.Context(), Actor{
			UserID: userID,
			Role:   role,
		})
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func parseBearerToken(header string) (string, error) {
	parts := strings.SplitN(header, " ", 2)
	if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") || strings.TrimSpace(parts[1]) == "" {
		return "", sharedErrors.ErrUnauthorized
	}
	return strings.TrimSpace(parts[1]), nil
}

type authErrorContextKey struct{}

func withAuthError(ctx context.Context, err error) context.Context {
	return context.WithValue(ctx, authErrorContextKey{}, err)
}

func AuthErrorFromContext(ctx context.Context) error {
	value := ctx.Value(authErrorContextKey{})
	err, _ := value.(error)
	return err
}
