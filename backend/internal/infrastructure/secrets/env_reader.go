package secrets

import (
	"context"
	"os"
)

// EnvReader is for local development fallback only.
type EnvReader struct{}

func NewEnvReader() *EnvReader { return &EnvReader{} }

func (r *EnvReader) Read(_ context.Context, secretName string) (string, error) {
	return os.Getenv(secretName), nil
}
