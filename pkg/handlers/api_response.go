package handlers

import (
	"net/http"

	"github.com/aws/aws-lambda-go/events"
)

type ResponseOption func(*events.APIGatewayProxyResponse)

func apiResponse(responseOptions ...ResponseOption) (*events.APIGatewayProxyResponse, error) {
	response := &events.APIGatewayProxyResponse{StatusCode: http.StatusOK}

	for _, opt := range responseOptions {
		opt(response)
	}

	return response, nil
}

func withStatusCode(statusCode int) ResponseOption {
	return func(response *events.APIGatewayProxyResponse) {
		response.StatusCode = statusCode
	}
}

func withBody(body string) ResponseOption {
	return func(response *events.APIGatewayProxyResponse) {
		response.Body = body
	}
}
