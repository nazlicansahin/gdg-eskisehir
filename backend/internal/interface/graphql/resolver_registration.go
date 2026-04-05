package graphql

import (
	"context"

	"github.com/gdg-eskisehir/events/backend/internal/application/usecase/registration"
)

func (m *MutationResolver) RegisterForEvent(
	ctx context.Context,
	eventID string,
) (*RegistrationTicket, error) {
	actor, err := ActorFromContext(ctx)
	if err != nil {
		return nil, WrapError(err)
	}

	out, err := m.root.registerForEvent.Execute(ctx, registration.RegisterForEventInput{
		ActorUserID: actor.UserID,
		EventID:     eventID,
	})
	if err != nil {
		return nil, WrapError(err)
	}

	return toTicket(out.RegistrationID, out.EventID, out.UserID, out.QRCodeValue, out.Status), nil
}

func (q *QueryResolver) MyTicket(
	ctx context.Context,
	eventID string,
) (*RegistrationTicket, error) {
	actor, err := ActorFromContext(ctx)
	if err != nil {
		return nil, WrapError(err)
	}

	out, err := q.root.getMyTicket.Execute(ctx, registration.GetMyTicketInput{
		ActorUserID: actor.UserID,
		EventID:     eventID,
	})
	if err != nil {
		return nil, WrapError(err)
	}

	return toTicket(out.RegistrationID, out.EventID, out.UserID, out.QRCodeValue, out.Status), nil
}
