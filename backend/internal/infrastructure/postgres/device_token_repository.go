package postgres

import (
	"context"

	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
)

type DeviceTokenRepository struct {
	db *DB
}

func NewDeviceTokenRepository(db *DB) *DeviceTokenRepository {
	return &DeviceTokenRepository{db: db}
}

func (r *DeviceTokenRepository) Upsert(ctx context.Context, userID, token, platform string) error {
	_, err := r.db.Pool.Exec(ctx, `
		INSERT INTO device_tokens (user_id, token, platform)
		VALUES ($1, $2, $3)
		ON CONFLICT (token) DO UPDATE SET user_id = $1, platform = $3, updated_at = now()
	`, userID, token, platform)
	return err
}

func (r *DeviceTokenRepository) ListByUserID(ctx context.Context, userID string) ([]ports.DeviceToken, error) {
	rows, err := r.db.Pool.Query(ctx, `
		SELECT id, user_id, token, platform FROM device_tokens WHERE user_id = $1
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var tokens []ports.DeviceToken
	for rows.Next() {
		var t ports.DeviceToken
		if err := rows.Scan(&t.ID, &t.UserID, &t.Token, &t.Platform); err != nil {
			return nil, err
		}
		tokens = append(tokens, t)
	}
	return tokens, nil
}

func (r *DeviceTokenRepository) ListByUserIDs(ctx context.Context, userIDs []string) ([]ports.DeviceToken, error) {
	if len(userIDs) == 0 {
		return nil, nil
	}
	rows, err := r.db.Pool.Query(ctx, `
		SELECT id, user_id, token, platform FROM device_tokens WHERE user_id = ANY($1)
	`, userIDs)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var tokens []ports.DeviceToken
	for rows.Next() {
		var t ports.DeviceToken
		if err := rows.Scan(&t.ID, &t.UserID, &t.Token, &t.Platform); err != nil {
			return nil, err
		}
		tokens = append(tokens, t)
	}
	return tokens, nil
}

func (r *DeviceTokenRepository) ListAll(ctx context.Context) ([]ports.DeviceToken, error) {
	rows, err := r.db.Pool.Query(ctx, `
		SELECT id, user_id, token, platform FROM device_tokens
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var tokens []ports.DeviceToken
	for rows.Next() {
		var t ports.DeviceToken
		if err := rows.Scan(&t.ID, &t.UserID, &t.Token, &t.Platform); err != nil {
			return nil, err
		}
		tokens = append(tokens, t)
	}
	return tokens, nil
}

func (r *DeviceTokenRepository) Delete(ctx context.Context, userID, token string) error {
	_, err := r.db.Pool.Exec(ctx, `
		DELETE FROM device_tokens WHERE user_id = $1 AND token = $2
	`, userID, token)
	return err
}
