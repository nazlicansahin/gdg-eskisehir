package ports

import "context"

type PushMessage struct {
	Title string
	Body  string
	Data  map[string]string
}

type PushSender interface {
	SendToTokens(ctx context.Context, tokens []string, msg PushMessage) error
}
