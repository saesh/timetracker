package authorization

import (
	"os"
)

type EnvCredentialsRepository struct {
}

func (repo *EnvCredentialsRepository) Get(_ string) (*Credentials, error) {
	username, found := os.LookupEnv("USERNAME")
	if !found {
		return nil, ErrUnauthorized
	}

	password, found := os.LookupEnv("PASSWORD")
	if !found {
		return nil, ErrUnauthorized
	}

	return &Credentials{Username: username, Password: password}, nil
}
