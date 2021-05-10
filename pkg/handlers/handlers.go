package handlers

import (
	"net/http"

	"github.com/aws/aws-lambda-go/events"
)

func MethodNotSupported() (*events.APIGatewayProxyResponse, error) {
	return &events.APIGatewayProxyResponse{StatusCode: http.StatusMethodNotAllowed}, nil
}

func NotFound() (*events.APIGatewayProxyResponse, error) {
	return &events.APIGatewayProxyResponse{StatusCode: http.StatusNotFound}, nil
}
