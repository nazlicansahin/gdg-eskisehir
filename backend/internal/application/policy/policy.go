package policy

import (
	"github.com/gdg-eskisehir/events/backend/internal/domain"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

func CanCheckIn(role domain.Role) error {
	switch role {
	case domain.RoleTeamMember, domain.RoleOrganizer, domain.RoleSuperAdmin:
		return nil
	default:
		return sharedErrors.ErrForbidden
	}
}

func CanCreateEvent(role domain.Role) error {
	switch role {
	case domain.RoleOrganizer, domain.RoleSuperAdmin:
		return nil
	default:
		return sharedErrors.ErrForbidden
	}
}

func CanPublishEvent(role domain.Role) error {
	switch role {
	case domain.RoleOrganizer, domain.RoleSuperAdmin:
		return nil
	default:
		return sharedErrors.ErrForbidden
	}
}

func CanCancelRegistration(role domain.Role) error {
	if role == domain.RoleSuperAdmin {
		return nil
	}
	return sharedErrors.ErrForbidden
}

func CanManageRoles(role domain.Role) error {
	if role == domain.RoleSuperAdmin {
		return nil
	}
	return sharedErrors.ErrForbidden
}

// CanAccessAdminAPI allows organizer-facing queries (events list, registrations, users).
func CanAccessAdminAPI(role domain.Role) error {
	switch role {
	case domain.RoleOrganizer, domain.RoleSuperAdmin:
		return nil
	default:
		return sharedErrors.ErrForbidden
	}
}

// CanCancelEvent allows transitioning an event to cancelled.
func CanCancelEvent(role domain.Role) error {
	return CanPublishEvent(role)
}
