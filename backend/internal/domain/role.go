package domain

type Role string

const (
	RoleMember     Role = "member"
	RoleTeamMember Role = "team_member"
	RoleOrganizer  Role = "organizer"
	RoleSuperAdmin Role = "super_admin"
)

func (r Role) IsValid() bool {
	switch r {
	case RoleMember, RoleTeamMember, RoleOrganizer, RoleSuperAdmin:
		return true
	default:
		return false
	}
}
