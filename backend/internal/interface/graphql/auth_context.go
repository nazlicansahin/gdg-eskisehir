package graphql

import (
	"context"

	"github.com/gdg-eskisehir/events/backend/internal/domain"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

type actorContextKey struct{}

type Actor struct {
	UserID string
	Roles  []domain.Role
}

func WithActor(ctx context.Context, actor Actor) context.Context {
	return context.WithValue(ctx, actorContextKey{}, actor)
}

func ActorFromContext(ctx context.Context) (Actor, error) {
	value := ctx.Value(actorContextKey{})
	actor, ok := value.(Actor)
	if !ok || actor.UserID == "" || !domain.RolesValid(actor.Roles) {
		return Actor{}, sharedErrors.ErrUnauthorized
	}
	return actor, nil
}
