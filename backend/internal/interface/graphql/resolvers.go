package graphql

import (
	"context"

	"github.com/gdg-eskisehir/events/backend/internal/application/usecase/registration"
)

type registerForEventExecutor interface {
	Execute(
		ctx context.Context,
		in registration.RegisterForEventInput,
	) (*registration.RegisterForEventOutput, error)
}

type getMyTicketExecutor interface {
	Execute(
		ctx context.Context,
		in registration.GetMyTicketInput,
	) (*registration.GetMyTicketOutput, error)
}

type Resolver struct {
	registerForEvent registerForEventExecutor
	getMyTicket      getMyTicketExecutor
}

func NewResolver(
	registerForEvent registerForEventExecutor,
	getMyTicket getMyTicketExecutor,
) *Resolver {
	return &Resolver{
		registerForEvent: registerForEvent,
		getMyTicket:      getMyTicket,
	}
}

type MutationResolver struct {
	root *Resolver
}

type QueryResolver struct {
	root *Resolver
}

func (r *Resolver) Mutation() *MutationResolver {
	return &MutationResolver{root: r}
}

func (r *Resolver) Query() *QueryResolver {
	return &QueryResolver{root: r}
}
