package postgres

import (
	"context"
	"errors"
	"strings"

	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
	"github.com/gdg-eskisehir/events/backend/internal/domain"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
	"github.com/jackc/pgx/v5"
)

type UserRepository struct {
	db *DB
}

func NewUserRepository(db *DB) *UserRepository {
	return &UserRepository{db: db}
}

func normalizeEmail(firebaseUID, email string) string {
	email = strings.TrimSpace(email)
	if email != "" {
		return email
	}
	return firebaseUID + "@users.firebase.local"
}

func normalizeDisplayName(email, displayName string) string {
	displayName = strings.TrimSpace(displayName)
	if displayName != "" {
		return displayName
	}
	if email != "" && strings.Contains(email, "@") {
		return strings.Split(email, "@")[0]
	}
	return "Member"
}

func (r *UserRepository) loadRoles(ctx context.Context, userID string) ([]domain.Role, error) {
	rows, err := r.db.Query(ctx, `
		SELECT role::text FROM user_roles WHERE user_id = $1::uuid ORDER BY role
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var roles []domain.Role
	for rows.Next() {
		var s string
		if err := rows.Scan(&s); err != nil {
			return nil, err
		}
		roles = append(roles, domain.Role(s))
	}
	return roles, rows.Err()
}

func (r *UserRepository) EnsureFromFirebase(
	ctx context.Context,
	firebaseUID, email, displayName string,
) (*domain.User, error) {
	email = normalizeEmail(firebaseUID, email)
	displayName = normalizeDisplayName(email, displayName)

	row := r.db.QueryRow(ctx, `
		INSERT INTO users (firebase_uid, email, display_name)
		VALUES ($1, $2, $3)
		ON CONFLICT (firebase_uid) DO UPDATE SET
			email = EXCLUDED.email,
			display_name = EXCLUDED.display_name,
			updated_at = now()
		RETURNING id::text, firebase_uid, email, display_name, created_at, updated_at
	`, firebaseUID, email, displayName)

	var u domain.User
	if err := row.Scan(
		&u.ID,
		&u.FirebaseUID,
		&u.Email,
		&u.DisplayName,
		&u.CreatedAt,
		&u.UpdatedAt,
	); err != nil {
		return nil, err
	}
	if err := r.db.Exec(ctx, `
		INSERT INTO user_roles (user_id, role) VALUES ($1::uuid, 'member') ON CONFLICT DO NOTHING
	`, u.ID); err != nil {
		return nil, err
	}
	roles, err := r.loadRoles(ctx, u.ID)
	if err != nil {
		return nil, err
	}
	u.Roles = roles
	return &u, nil
}

func (r *UserRepository) GetByID(ctx context.Context, id string) (*domain.User, error) {
	row := r.db.QueryRow(ctx, `
		SELECT id::text, firebase_uid, email, display_name, created_at, updated_at
		FROM users
		WHERE id = $1::uuid
	`, id)

	var u domain.User
	if err := row.Scan(
		&u.ID,
		&u.FirebaseUID,
		&u.Email,
		&u.DisplayName,
		&u.CreatedAt,
		&u.UpdatedAt,
	); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, sharedErrors.ErrNotFound
		}
		return nil, err
	}
	roles, err := r.loadRoles(ctx, u.ID)
	if err != nil {
		return nil, err
	}
	u.Roles = roles
	return &u, nil
}

func (r *UserRepository) UpdateDisplayName(ctx context.Context, userID, displayName string) error {
	return r.db.Exec(ctx, `
		UPDATE users SET display_name = $2, updated_at = now() WHERE id = $1::uuid
	`, userID, displayName)
}

func (r *UserRepository) DeleteByID(ctx context.Context, userID string) error {
	tx, err := r.db.Pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback(ctx) }()

	if _, err := tx.Exec(ctx, `DELETE FROM announcements WHERE created_by = $1::uuid`, userID); err != nil {
		return err
	}
	if _, err := tx.Exec(ctx, `DELETE FROM users WHERE id = $1::uuid`, userID); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

func (r *UserRepository) ListAll(ctx context.Context) ([]*domain.User, error) {
	rows, err := r.db.Query(ctx, `
		SELECT
			u.id::text,
			u.firebase_uid,
			u.email,
			u.display_name,
			u.created_at,
			u.updated_at,
			COALESCE(
				(SELECT array_agg(ur.role ORDER BY ur.role) FROM user_roles ur WHERE ur.user_id = u.id),
				ARRAY[]::text[]
			)
		FROM users u
		ORDER BY u.created_at ASC
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []*domain.User
	for rows.Next() {
		var u domain.User
		var roles []string
		if err := rows.Scan(
			&u.ID,
			&u.FirebaseUID,
			&u.Email,
			&u.DisplayName,
			&u.CreatedAt,
			&u.UpdatedAt,
			&roles,
		); err != nil {
			return nil, err
		}
		u.Roles = make([]domain.Role, 0, len(roles))
		for _, s := range roles {
			u.Roles = append(u.Roles, domain.Role(s))
		}
		out = append(out, &u)
	}
	return out, rows.Err()
}

func (r *UserRepository) GrantRole(ctx context.Context, userID string, role domain.Role) error {
	return r.db.Exec(ctx, `
		INSERT INTO user_roles (user_id, role) VALUES ($1::uuid, $2) ON CONFLICT DO NOTHING
	`, userID, string(role))
}

func (r *UserRepository) RevokeRole(ctx context.Context, userID string, role domain.Role) error {
	return r.db.Exec(ctx, `
		DELETE FROM user_roles WHERE user_id = $1::uuid AND role = $2
	`, userID, string(role))
}

var _ ports.UserRepository = (*UserRepository)(nil)
