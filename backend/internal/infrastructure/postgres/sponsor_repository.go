package postgres

import (
	"context"

	"github.com/gdg-eskisehir/events/backend/internal/domain"
)

type SponsorRepository struct {
	db *DB
}

func NewSponsorRepository2(db *DB) *SponsorRepository {
	return &SponsorRepository{db: db}
}

func (r *SponsorRepository) Create(ctx context.Context, s *domain.Sponsor) error {
	return r.db.Pool.QueryRow(ctx, `
		INSERT INTO sponsors (event_id, name, logo_url, website_url, tier)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, created_at
	`, s.EventID, s.Name, s.LogoURL, s.WebsiteURL, s.Tier).Scan(&s.ID, &s.CreatedAt)
}

func (r *SponsorRepository) ListByEventID(ctx context.Context, eventID string) ([]*domain.Sponsor, error) {
	rows, err := r.db.Pool.Query(ctx, `
		SELECT id, event_id, name, logo_url, website_url, tier, created_at
		FROM sponsors WHERE event_id = $1 ORDER BY tier, name
	`, eventID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanSponsors(rows)
}

func (r *SponsorRepository) ListGeneral(ctx context.Context) ([]*domain.Sponsor, error) {
	rows, err := r.db.Pool.Query(ctx, `
		SELECT id, event_id, name, logo_url, website_url, tier, created_at
		FROM sponsors WHERE event_id IS NULL ORDER BY tier, name
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanSponsors(rows)
}

func (r *SponsorRepository) ListAll(ctx context.Context) ([]*domain.Sponsor, error) {
	rows, err := r.db.Pool.Query(ctx, `
		SELECT id, event_id, name, logo_url, website_url, tier, created_at
		FROM sponsors ORDER BY tier, name
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanSponsors(rows)
}

func (r *SponsorRepository) Delete(ctx context.Context, id string) error {
	_, err := r.db.Pool.Exec(ctx, `DELETE FROM sponsors WHERE id = $1`, id)
	return err
}

type sponsorScannable interface {
	Scan(dest ...any) error
	Next() bool
}

func scanSponsors(rows sponsorScannable) ([]*domain.Sponsor, error) {
	var out []*domain.Sponsor
	for rows.Next() {
		var s domain.Sponsor
		if err := rows.Scan(&s.ID, &s.EventID, &s.Name, &s.LogoURL, &s.WebsiteURL, &s.Tier, &s.CreatedAt); err != nil {
			return nil, err
		}
		out = append(out, &s)
	}
	return out, nil
}
