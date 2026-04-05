package ports

import "context"

type SecretReader interface {
	Read(ctx context.Context, secretName string) (string, error)
}
