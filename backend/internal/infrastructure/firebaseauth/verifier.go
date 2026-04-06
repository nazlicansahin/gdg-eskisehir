package firebaseauth

import (
	"context"
	"encoding/base64"
	"fmt"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	apiauth "github.com/gdg-eskisehir/events/backend/internal/auth"
	"google.golang.org/api/option"
)

type Verifier struct {
	client *auth.Client
}

func NewVerifier(ctx context.Context, projectID, serviceAccountJSONB64 string) (*Verifier, error) {
	raw, err := base64.StdEncoding.DecodeString(serviceAccountJSONB64)
	if err != nil {
		return nil, fmt.Errorf("decode service account: %w", err)
	}
	opt := option.WithCredentialsJSON(raw)
	app, err := firebase.NewApp(ctx, &firebase.Config{ProjectID: projectID}, opt)
	if err != nil {
		return nil, err
	}
	client, err := app.Auth(ctx)
	if err != nil {
		return nil, err
	}
	return &Verifier{client: client}, nil
}

func (v *Verifier) VerifyIDToken(ctx context.Context, rawToken string) (*apiauth.VerifiedToken, error) {
	tok, err := v.client.VerifyIDToken(ctx, rawToken)
	if err != nil {
		return nil, err
	}
	email, _ := tok.Claims["email"].(string)
	name, _ := tok.Claims["name"].(string)
	return &apiauth.VerifiedToken{
		FirebaseUID: tok.UID,
		Email:       email,
		DisplayName: name,
	}, nil
}
