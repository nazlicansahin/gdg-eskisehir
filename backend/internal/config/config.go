package config

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/joho/godotenv"
)

type Config struct {
	HTTPAddr string

	PostgresDSN string

	FirebaseProjectID             string
	FirebaseServiceAccountJSONB64 string
}

func Load() (*Config, error) {
	_ = loadEnvFiles()

	addr := os.Getenv("HTTP_ADDR")
	if addr == "" {
		addr = ":8080"
	}

	dsn := strings.TrimSpace(os.Getenv("BACKEND_DB_DSN"))
	if dsn == "" {
		return nil, fmt.Errorf("BACKEND_DB_DSN is required")
	}

	projectID := strings.TrimSpace(os.Getenv("BACKEND_FIREBASE_PROJECT_ID"))
	saB64 := strings.TrimSpace(os.Getenv("BACKEND_FIREBASE_SERVICE_ACCOUNT_JSON_BASE64"))
	if projectID == "" || saB64 == "" {
		return nil, fmt.Errorf("BACKEND_FIREBASE_PROJECT_ID and BACKEND_FIREBASE_SERVICE_ACCOUNT_JSON_BASE64 are required")
	}

	return &Config{
		HTTPAddr:                      addr,
		PostgresDSN:                   dsn,
		FirebaseProjectID:             projectID,
		FirebaseServiceAccountJSONB64: saB64,
	}, nil
}

func loadEnvFiles() error {
	paths := []string{
		".env.local",
		"../.env.local",
		"../../.env.local",
	}
	for _, p := range paths {
		abs, err := filepath.Abs(p)
		if err != nil {
			continue
		}
		if _, err := os.Stat(abs); err != nil {
			continue
		}
		_ = godotenv.Load(abs)
	}
	return nil
}
