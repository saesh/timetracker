package authorization

import (
	"encoding/base64"
	"errors"
	"strings"
)

var ErrUnauthorized error = errors.New("Unauthorized")

type CredentialsRepository interface {
	Get(username string) (*Credentials, error)
}

type BasicAuthAuthorizer struct {
	CredentialsRepository CredentialsRepository
}

func (a *BasicAuthAuthorizer) Authorize(token string) (PrincipalID string, err error) {
	basicAuthToken := strings.Split(token, " ")[1]

	credentials, err := decodeCredentials(basicAuthToken)
	if err != nil {
		return "", ErrUnauthorized
	}

	existingCredentials, err := a.CredentialsRepository.Get(credentials.Username)
	if err != nil {
		return "", ErrUnauthorized
	}

	if !existingCredentials.Match(credentials) {
		return "", ErrUnauthorized
	}

	return credentials.Username, nil
}

func decodeCredentials(token string) (credentials *Credentials, err error) {
	decodedToken, err := base64.StdEncoding.DecodeString(token)
	if err != nil {
		return nil, ErrUnauthorized
	}

	plainCredentials := strings.Split(string(decodedToken), ":")
	return &Credentials{
		Username: plainCredentials[0],
		Password: plainCredentials[1],
	}, nil
}
