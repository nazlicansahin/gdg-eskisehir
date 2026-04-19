package fcm

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"time"

	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
)

// Sender delivers via FCM HTTP v1 REST (bypasses firebase.messaging transport — fixes missing Bearer on some setups).
type Sender struct {
	projectID string
	ts        oauth2.TokenSource
	httpClient *http.Client
}

func NewSender(ctx context.Context, projectID, serviceAccountJSONB64 string) (*Sender, error) {
	raw, err := base64.StdEncoding.DecodeString(serviceAccountJSONB64)
	if err != nil {
		return nil, fmt.Errorf("decode service account: %w", err)
	}

	creds, err := google.CredentialsFromJSON(ctx, raw,
		"https://www.googleapis.com/auth/firebase.messaging",
		"https://www.googleapis.com/auth/cloud-platform",
	)
	if err != nil {
		return nil, fmt.Errorf("service account credentials: %w", err)
	}
	if _, err := creds.TokenSource.Token(); err != nil {
		return nil, fmt.Errorf("oauth2 token from service account (revoked key or network): %w", err)
	}

	return &Sender{
		projectID: projectID,
		ts:        creds.TokenSource,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}, nil
}

type fcmRESTRequest struct {
	Message fcmRESTMessage `json:"message"`
}

type fcmRESTMessage struct {
	Token        string            `json:"token"`
	Notification *fcmNotification `json:"notification,omitempty"`
	Data         map[string]string `json:"data,omitempty"`
	// APNS headers/payload so iOS shows alerts reliably (alert + priority 10).
	Apns *fcmApns `json:"apns,omitempty"`
}

type fcmApns struct {
	Headers map[string]string      `json:"headers,omitempty"`
	Payload map[string]interface{} `json:"payload,omitempty"`
}

type fcmNotification struct {
	Title string `json:"title,omitempty"`
	Body  string `json:"body,omitempty"`
}

func (s *Sender) SendToTokens(ctx context.Context, deviceTokens []string, msg ports.PushMessage) error {
	if len(deviceTokens) == 0 {
		return nil
	}

	for _, deviceToken := range deviceTokens {
		payload := fcmRESTRequest{
			Message: fcmRESTMessage{
				Token: deviceToken,
				Data:  msg.Data,
			},
		}
		if msg.Title != "" || msg.Body != "" {
			payload.Message.Notification = &fcmNotification{Title: msg.Title, Body: msg.Body}
			payload.Message.Apns = &fcmApns{
				Headers: map[string]string{
					"apns-priority":  "10",
					"apns-push-type": "alert",
				},
				Payload: map[string]interface{}{
					"aps": map[string]interface{}{
						"sound": "default",
					},
				},
			}
		}

		body, err := json.Marshal(payload)
		if err != nil {
			log.Printf("fcm: marshal failed err=%v", err)
			continue
		}

		url := fmt.Sprintf("https://fcm.googleapis.com/v1/projects/%s/messages:send", s.projectID)
		req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(body))
		if err != nil {
			return err
		}
		req.Header.Set("Content-Type", "application/json")

		tok, err := s.ts.Token()
		if err != nil {
			log.Printf("fcm: oauth token failed err=%v", err)
			continue
		}
		if tok.AccessToken == "" {
			log.Printf("fcm: oauth access token empty (service account mis-configuration)")
			continue
		}
		req.Header.Set("Authorization", "Bearer "+tok.AccessToken)

		resp, err := s.httpClient.Do(req)
		if err != nil {
			log.Printf("fcm: http request failed err=%v", err)
			continue
		}
		respBody, _ := io.ReadAll(resp.Body)
		resp.Body.Close()

		if resp.StatusCode < 200 || resp.StatusCode >= 300 {
			prefix := deviceToken
			if len(prefix) > 12 {
				prefix = prefix[:12]
			}
			hint := parseFCMErrorHint(respBody)
			log.Printf("fcm: send failed status=%d token_prefix=%q%s body=%s", resp.StatusCode, prefix, hint, truncateBytes(respBody, 600))
			continue
		}
		okPrefix := deviceToken
		if len(okPrefix) > 12 {
			okPrefix = okPrefix[:12]
		}
		log.Printf("fcm: delivered token_prefix=%q", okPrefix)
	}
	return nil
}

func truncateBytes(b []byte, n int) string {
	if len(b) <= n {
		return string(b)
	}
	return string(b[:n]) + "..."
}

// googleAPIErrorBody matches FCM HTTP v1 error JSON (subset).
type googleAPIErrorBody struct {
	Error struct {
		Details []struct {
			ErrorCode string `json:"errorCode"`
		} `json:"details"`
	} `json:"error"`
}

func parseFCMErrorHint(body []byte) string {
	var parsed googleAPIErrorBody
	if err := json.Unmarshal(body, &parsed); err != nil {
		return ""
	}
	for _, d := range parsed.Error.Details {
		switch d.ErrorCode {
		case "THIRD_PARTY_AUTH_ERROR":
			return ` hint="FCM Apple/APNs: Firebase Console → Project settings → Cloud Messaging → Apple app → upload APNs Auth Key (.p8), Key ID, Team ID, Bundle ID"`
		case "SENDER_ID_MISMATCH":
			return ` hint="FCM token app does not match Firebase project (wrong GoogleService-Info.plist / google-services)"`
		}
	}
	return ""
}
