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

type GrantUserRoleUseCase struct {
	users ports.UserRepository
}

func NewGrantUserRoleUseCase(users ports.UserRepository) *GrantUserRoleUseCase {
	return &GrantUserRoleUseCase{users: users}
}

type GrantUserRoleInput struct {
	ActorRoles []domain.Role
	UserID     string
	Role       domain.Role
}

func (uc *GrantUserRoleUseCase) Execute(ctx context.Context, in GrantUserRoleInput) (*domain.User, error) {
	if err := policy.CanGrantUserRole(in.ActorRoles, in.Role); err != nil {
		return nil, err
	}
	if err := validation.RequireUUID(in.UserID); err != nil {
		return nil, err
	}
	if err := uc.users.GrantRole(ctx, in.UserID, in.Role); err != nil {
		return nil, err
	}
	return uc.users.GetByID(ctx, in.UserID)
}

type RevokeUserRoleUseCase struct {
	users ports.UserRepository
}

func NewRevokeUserRoleUseCase(users ports.UserRepository) *RevokeUserRoleUseCase {
	return &RevokeUserRoleUseCase{users: users}
}

type RevokeUserRoleInput struct {
	ActorRoles []domain.Role
	UserID     string
	Role       domain.Role
}

func (uc *RevokeUserRoleUseCase) Execute(ctx context.Context, in RevokeUserRoleInput) (*domain.User, error) {
	if err := policy.CanRevokeUserRole(in.ActorRoles, in.Role); err != nil {
		return nil, err
	}
	if err := validation.RequireUUID(in.UserID); err != nil {
		return nil, err
	}
	if err := uc.users.RevokeRole(ctx, in.UserID, in.Role); err != nil {
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

func (uc *AdminListUsersUseCase) Execute(ctx context.Context, actorRoles []domain.Role) ([]*domain.User, error) {
	if err := policy.CanAccessAdminAPI(actorRoles); err != nil {
		return nil, err
	}
	return uc.users.ListAll(ctx)
}
