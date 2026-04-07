-- Multi-role users: staff (team_member, crew, organizer) may check in QR; member is baseline.

CREATE TABLE IF NOT EXISTS user_roles (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('member', 'team_member', 'crew', 'organizer', 'super_admin')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, role)
);

CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON user_roles(user_id);

INSERT INTO user_roles (user_id, role)
SELECT id, role FROM users
WHERE role IN ('member', 'team_member', 'crew', 'organizer', 'super_admin')
ON CONFLICT DO NOTHING;

ALTER TABLE users DROP COLUMN role;
