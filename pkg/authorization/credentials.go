package authorization

type Credentials struct {
	Username string
	Password string
}

func (credentials *Credentials) Match(otherCredentials *Credentials) bool {
	return otherCredentials.Username == credentials.Username &&
		otherCredentials.Password == credentials.Password
}
