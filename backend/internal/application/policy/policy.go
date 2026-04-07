package policy

import (
	"github.com/gdg-eskisehir/events/backend/internal/domain"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

func CanCheckIn(roles []domain.Role) error {
	for _, r := range roles {
		switch r {
		case domain.RoleTeamMember, domain.RoleCrew, domain.RoleOrganizer, domain.RoleSuperAdmin:
			return nil
		}
	}
	return sharedErrors.ErrForbidden
}

func CanCreateEvent(roles []domain.Role) error {
	for _, r := range roles {
		switch r {
		case domain.RoleOrganizer, domain.RoleSuperAdmin:
			return nil
		}
	}
	return sharedErrors.ErrForbidden
}

func CanPublishEvent(roles []domain.Role) error {
	return CanCreateEvent(roles)
}

func CanCancelRegistration(roles []domain.Role) error {
	if domain.RolesContain(roles, domain.RoleSuperAdmin) {
		return nil
	}
	return sharedErrors.ErrForbidden
}

// CanGrantUserRole: super_admin may assign any valid role; organizer may assign team_member or crew only.
func CanGrantUserRole(actor []domain.Role, target domain.Role) error {
	if !target.IsValid() {
		return sharedErrors.ErrValidation
	}
	if domain.RolesContain(actor, domain.RoleSuperAdmin) {
		return nil
	}
	if domain.RolesContain(actor, domain.RoleOrganizer) {
		if target == domain.RoleTeamMember || target == domain.RoleCrew {
			return nil
		}
		return sharedErrors.ErrForbidden
	}
	return sharedErrors.ErrForbidden
}

// CanRevokeUserRole: cannot revoke baseline member; organizer may revoke team_member or crew only.
func CanRevokeUserRole(actor []domain.Role, target domain.Role) error {
	if target == domain.RoleMember {
		return sharedErrors.ErrForbidden
	}
	if !target.IsValid() {
		return sharedErrors.ErrValidation
	}
	if domain.RolesContain(actor, domain.RoleSuperAdmin) {
		return nil
	}
	if domain.RolesContain(actor, domain.RoleOrganizer) {
		if target == domain.RoleTeamMember || target == domain.RoleCrew {
			return nil
		}
		return sharedErrors.ErrForbidden
	}
	return sharedErrors.ErrForbidden
}

// CanAccessAdminAPI allows organizer-facing queries (events list, registrations, users).
func CanAccessAdminAPI(roles []domain.Role) error {
	for _, r := range roles {
		switch r {
		case domain.RoleOrganizer, domain.RoleSuperAdmin:
			return nil
		}
	}
	return sharedErrors.ErrForbidden
}

// CanCancelEvent allows transitioning an event to cancelled.
func CanCancelEvent(roles []domain.Role) error {
	return CanPublishEvent(roles)
}
