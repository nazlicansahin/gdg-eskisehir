package user

import (
	"context"

	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
	"github.com/gdg-eskisehir/events/backend/internal/application/validation"
)

type DeleteMyAccountUseCase struct {
	users ports.UserRepository
}

func NewDeleteMyAccountUseCase(users ports.UserRepository) *DeleteMyAccountUseCase {
	return &DeleteMyAccountUseCase{users: users}
}

type DeleteMyAccountInput struct {
	ActorUserID string
}

func (uc *DeleteMyAccountUseCase) Execute(ctx context.Context, in DeleteMyAccountInput) error {
	if err := validation.RequireUUID(in.ActorUserID); err != nil {
		return err
	}
	return uc.users.DeleteByID(ctx, in.ActorUserID)
}
