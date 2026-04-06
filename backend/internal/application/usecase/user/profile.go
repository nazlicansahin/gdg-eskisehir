package user

import (
	"context"
	"strings"

	"github.com/gdg-eskisehir/events/backend/internal/application/policy"
	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
	"github.com/gdg-eskisehir/events/backend/internal/application/validation"
	"github.com/gdg-eskisehir/events/backend/internal/domain"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

type UpdateMyProfileUseCase struct {
	users ports.UserRepository
}

func NewUpdateMyProfileUseCase(users ports.UserRepository) *UpdateMyProfileUseCase {
	return &UpdateMyProfileUseCase{users: users}
}

type UpdateMyProfileInput struct {
	ActorUserID string
	DisplayName string
}

func (uc *UpdateMyProfileUseCase) Execute(ctx context.Context, in UpdateMyProfileInput) (*domain.User, error) {
	if err := validation.RequireUUID(in.ActorUserID); err != nil {
		return nil, err
	}
	name := strings.TrimSpace(in.DisplayName)
	if name == "" {
		return nil, sharedErrors.ErrValidation
	}
	if err := uc.users.UpdateDisplayName(ctx, in.ActorUserID, name); err != nil {
		return nil, err
	}
	return uc.users.GetByID(ctx, in.ActorUserID)
}

type AssignUserRoleUseCase struct {
	users ports.UserRepository
}

func NewAssignUserRoleUseCase(users ports.UserRepository) *AssignUserRoleUseCase {
	return &AssignUserRoleUseCase{users: users}
}

type AssignUserRoleInput struct {
	ActorRole domain.Role
	UserID    string
	Role      domain.Role
}

func (uc *AssignUserRoleUseCase) Execute(ctx context.Context, in AssignUserRoleInput) (*domain.User, error) {
	if err := policy.CanManageRoles(in.ActorRole); err != nil {
		return nil, err
	}
	if err := validation.RequireUUID(in.UserID); err != nil {
		return nil, err
	}
	if !in.Role.IsValid() {
		return nil, sharedErrors.ErrValidation
	}
	if err := uc.users.UpdateRole(ctx, in.UserID, in.Role); err != nil {
		return nil, err
	}
	return uc.users.GetByID(ctx, in.UserID)
}

type AdminListUsersUseCase struct {
	users ports.UserRepository
}

func NewAdminListUsersUseCase(users ports.UserRepository) *AdminListUsersUseCase {
	return &AdminListUsersUseCase{users: users}
}

func (uc *AdminListUsersUseCase) Execute(ctx context.Context, actorRole domain.Role) ([]*domain.User, error) {
	if err := policy.CanAccessAdminAPI(actorRole); err != nil {
		return nil, err
	}
	return uc.users.ListAll(ctx)
}
