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

func (r *UserRepository) EnsureFromFirebase(
	ctx context.Context,
	firebaseUID, email, displayName string,
) (*domain.User, error) {
	email = normalizeEmail(firebaseUID, email)
	displayName = normalizeDisplayName(email, displayName)

	row := r.db.QueryRow(ctx, `
		INSERT INTO users (firebase_uid, email, display_name, role)
		VALUES ($1, $2, $3, 'member')
		ON CONFLICT (firebase_uid) DO UPDATE SET
			email = EXCLUDED.email,
			display_name = EXCLUDED.display_name,
			updated_at = now()
		RETURNING id::text, firebase_uid, email, display_name, role::text, created_at, updated_at
	`, firebaseUID, email, displayName)

	var u domain.User
	var role string
	if err := row.Scan(&u.ID, &u.FirebaseUID, &u.Email, &u.DisplayName, &role, &u.CreatedAt, &u.UpdatedAt); err != nil {
		return nil, err
	}
	u.Role = domain.Role(role)
	return &u, nil
}

func (r *UserRepository) GetByID(ctx context.Context, id string) (*domain.User, error) {
	row := r.db.QueryRow(ctx, `
		SELECT id::text, firebase_uid, email, display_name, role::text, created_at, updated_at
		FROM users
		WHERE id = $1::uuid
	`, id)

	var u domain.User
	var role string
	if err := row.Scan(&u.ID, &u.FirebaseUID, &u.Email, &u.DisplayName, &role, &u.CreatedAt, &u.UpdatedAt); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, sharedErrors.ErrNotFound
		}
		return nil, err
	}
	u.Role = domain.Role(role)
	return &u, nil
}

func (r *UserRepository) UpdateDisplayName(ctx context.Context, userID, displayName string) error {
	return r.db.Exec(ctx, `
		UPDATE users SET display_name = $2, updated_at = now() WHERE id = $1::uuid
	`, userID, displayName)
}

func (r *UserRepository) ListAll(ctx context.Context) ([]*domain.User, error) {
	rows, err := r.db.Query(ctx, `
		SELECT id::text, firebase_uid, email, display_name, role::text, created_at, updated_at
		FROM users
		ORDER BY created_at ASC
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []*domain.User
	for rows.Next() {
		var u domain.User
		var role string
		if err := rows.Scan(&u.ID, &u.FirebaseUID, &u.Email, &u.DisplayName, &role, &u.CreatedAt, &u.UpdatedAt); err != nil {
			return nil, err
		}
		u.Role = domain.Role(role)
		out = append(out, &u)
	}
	return out, rows.Err()
}

func (r *UserRepository) UpdateRole(ctx context.Context, userID string, role domain.Role) error {
	return r.db.Exec(ctx, `
		UPDATE users SET role = $2, updated_at = now() WHERE id = $1::uuid
	`, userID, string(role))
}

var _ ports.UserRepository = (*UserRepository)(nil)
