package main

import (
	"context"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/saesh/timetracker/pkg/authorization"
)

type Authorizer interface {
	Authorize(token string) (PrincipalID string, err error)
}

func main() {
	authorizer := &authorization.BasicAuthAuthorizer{
		CredentialsRepository: &authorization.EnvCredentialsRepository{},
	}

	lambda.Start(handler(authorizer))
}

func handler(authorizer Authorizer) func(context.Context, events.APIGatewayCustomAuthorizerRequest) (events.APIGatewayCustomAuthorizerResponse, error) {
	return func(_ context.Context, event events.APIGatewayCustomAuthorizerRequest) (events.APIGatewayCustomAuthorizerResponse, error) {
		principalID, err := authorizer.Authorize(event.AuthorizationToken)

		if err != nil {
			return errorResponse(err)
		}

		return allowResponse(principalID, event.MethodArn)
	}
}

func allowResponse(principalID, methodArn string) (events.APIGatewayCustomAuthorizerResponse, error) {
	return events.APIGatewayCustomAuthorizerResponse{
		PrincipalID: principalID,
		PolicyDocument: events.APIGatewayCustomAuthorizerPolicy{
			Version: "2012-10-17",
			Statement: []events.IAMPolicyStatement{
				{
					Action:   []string{"execute-api:Invoke"},
					Effect:   "Allow",
					Resource: []string{methodArn},
				},
			},
		},
	}, nil
}

func errorResponse(err error) (events.APIGatewayCustomAuthorizerResponse, error) {
	return events.APIGatewayCustomAuthorizerResponse{}, err
}
