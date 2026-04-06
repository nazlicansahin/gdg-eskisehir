package auth

// VerifiedToken is produced by Firebase ID token verification.
type VerifiedToken struct {
	FirebaseUID string
	Email       string
	DisplayName string
}
