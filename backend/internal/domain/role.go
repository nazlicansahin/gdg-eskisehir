package domain

type Role string

const (
	RoleMember     Role = "member"
	RoleTeamMember Role = "team_member"
	RoleCrew       Role = "crew"
	RoleOrganizer  Role = "organizer"
	RoleSuperAdmin Role = "super_admin"
)

func (r Role) IsValid() bool {
	switch r {
	case RoleMember, RoleTeamMember, RoleCrew, RoleOrganizer, RoleSuperAdmin:
		return true
	default:
		return false
	}
}

func RolesContain(roles []Role, want Role) bool {
	for _, r := range roles {
		if r == want {
			return true
		}
	}
	return false
}

func RolesValid(roles []Role) bool {
	if len(roles) == 0 {
		return false
	}
	for _, r := range roles {
		if !r.IsValid() {
			return false
		}
	}
	return true
}
