package postgres

import (
	"context"
	"errors"
	"strconv"

	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
	"github.com/gdg-eskisehir/events/backend/internal/domain"
	"github.com/jackc/pgx/v5"
)

type SpeakerRepository struct {
	db *DB
}

func NewSpeakerRepository(db *DB) *SpeakerRepository {
	return &SpeakerRepository{db: db}
}

func (r *SpeakerRepository) GetByID(ctx context.Context, id string) (*domain.Speaker, error) {
	row := r.db.QueryRow(ctx, `
		SELECT id::text, full_name, COALESCE(bio, ''), COALESCE(avatar_url, ''), created_at, updated_at
		FROM speakers
		WHERE id = $1::uuid
	`, id)

	var sp domain.Speaker
	if err := row.Scan(
		&sp.ID,
		&sp.FullName,
		&sp.Bio,
		&sp.AvatarURL,
		&sp.CreatedAt,
		&sp.UpdatedAt,
	); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	return &sp, nil
}

func (r *SpeakerRepository) List(ctx context.Context, query *string) ([]*domain.Speaker, error) {
	q := `
		SELECT id::text, full_name, COALESCE(bio, ''), COALESCE(avatar_url, ''), created_at, updated_at
		FROM speakers
		WHERE 1=1
	`
	args := []any{}
	if query != nil && *query != "" {
		args = append(args, "%"+*query+"%")
		q += ` AND full_name ILIKE $` + strconv.Itoa(len(args))
	}
	q += ` ORDER BY full_name ASC`

	rows, err := r.db.Query(ctx, q, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []*domain.Speaker
	for rows.Next() {
		var sp domain.Speaker
		if err := rows.Scan(
			&sp.ID,
			&sp.FullName,
			&sp.Bio,
			&sp.AvatarURL,
			&sp.CreatedAt,
			&sp.UpdatedAt,
		); err != nil {
			return nil, err
		}
		out = append(out, &sp)
	}
	return out, rows.Err()
}

func (r *SpeakerRepository) Create(ctx context.Context, s *domain.Speaker) error {
	row := r.db.QueryRow(ctx, `
		INSERT INTO speakers (full_name, bio, avatar_url)
		VALUES ($1, $2, $3)
		RETURNING id::text, created_at, updated_at
	`, s.FullName, nullIfEmpty(s.Bio), nullIfEmpty(s.AvatarURL))
	return row.Scan(&s.ID, &s.CreatedAt, &s.UpdatedAt)
}

func (r *SpeakerRepository) Update(ctx context.Context, id string, fullName, bio, avatarURL *string) error {
	return r.db.Exec(ctx, `
		UPDATE speakers SET
			full_name = COALESCE($2, full_name),
			bio = COALESCE($3, bio),
			avatar_url = COALESCE($4, avatar_url),
			updated_at = now()
		WHERE id = $1::uuid
	`, id, fullName, bio, avatarURL)
}

var _ ports.SpeakerRepository = (*SpeakerRepository)(nil)
