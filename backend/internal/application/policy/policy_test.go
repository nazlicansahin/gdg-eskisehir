package policy

import (
	"testing"

	"github.com/gdg-eskisehir/events/backend/internal/domain"
)

func TestCanCancelRegistration(t *testing.T) {
	if err := CanCancelRegistration([]domain.Role{domain.RoleSuperAdmin}); err != nil {
		t.Fatalf("super_admin should cancel registrations: %v", err)
	}
	if err := CanCancelRegistration([]domain.Role{domain.RoleOrganizer}); err == nil {
		t.Fatalf("organizer should not cancel registrations")
	}
}

func TestCanCheckIn(t *testing.T) {
	allowed := [][]domain.Role{
		{domain.RoleTeamMember},
		{domain.RoleCrew},
		{domain.RoleOrganizer},
		{domain.RoleSuperAdmin},
		{domain.RoleMember, domain.RoleCrew},
	}
	for _, roles := range allowed {
		if err := CanCheckIn(roles); err != nil {
			t.Fatalf("expected roles %v to check in: %v", roles, err)
		}
	}
	if err := CanCheckIn([]domain.Role{domain.RoleMember}); err == nil {
		t.Fatalf("member-only should not check in")
	}
}

func TestCanGrantUserRole(t *testing.T) {
	if err := CanGrantUserRole(
		[]domain.Role{domain.RoleOrganizer},
		domain.RoleTeamMember,
	); err != nil {
		t.Fatalf("organizer should grant team_member: %v", err)
	}
	if err := CanGrantUserRole([]domain.Role{domain.RoleOrganizer}, domain.RoleOrganizer); err == nil {
		t.Fatalf("organizer should not grant organizer")
	}
	if err := CanGrantUserRole([]domain.Role{domain.RoleSuperAdmin}, domain.RoleOrganizer); err != nil {
		t.Fatalf("super_admin should grant organizer: %v", err)
	}
}

func TestCanRevokeUserRole(t *testing.T) {
	if err := CanRevokeUserRole([]domain.Role{domain.RoleOrganizer}, domain.RoleMember); err == nil {
		t.Fatalf("must not revoke member")
	}
	if err := CanRevokeUserRole(
		[]domain.Role{domain.RoleOrganizer},
		domain.RoleTeamMember,
	); err != nil {
		t.Fatalf("organizer should revoke team_member: %v", err)
	}
}
