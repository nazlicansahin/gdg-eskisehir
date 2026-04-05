package policy

import (
	"testing"

	"github.com/gdg-eskisehir/events/backend/internal/domain"
)

func TestCanCancelRegistration(t *testing.T) {
	if err := CanCancelRegistration(domain.RoleSuperAdmin); err != nil {
		t.Fatalf("super_admin should cancel registrations: %v", err)
	}
	if err := CanCancelRegistration(domain.RoleOrganizer); err == nil {
		t.Fatalf("organizer should not cancel registrations")
	}
}

func TestCanCheckIn(t *testing.T) {
	allowed := []domain.Role{domain.RoleTeamMember, domain.RoleOrganizer, domain.RoleSuperAdmin}
	for _, role := range allowed {
		if err := CanCheckIn(role); err != nil {
			t.Fatalf("expected role %s to check in: %v", role, err)
		}
	}
	if err := CanCheckIn(domain.RoleMember); err == nil {
		t.Fatalf("member should not check in")
	}
}
