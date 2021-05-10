package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/aws/aws-lambda-go/events"
	"github.com/saesh/timetracker/pkg/timelog"
)

type taskPayload struct {
	Description *string `json:"description,omitempty"`
	Timestamp   *string `json:"timestamp,omitempty"`
}

func StartTask(service *timelog.TimelogService, request *events.APIGatewayProxyRequest) (*events.APIGatewayProxyResponse, error) {
	payload, err := deserialize(request.Body)
	if err != nil {
		return apiResponse(withStatusCode(http.StatusBadRequest), withBody(err.Error()))
	}

	if payload.Description == nil || payload.Timestamp == nil {
		return apiResponse(withStatusCode(http.StatusBadRequest), withBody("Description and Timestamp are required"))
	}

	err = service.Start(*payload.Description, *payload.Timestamp)
	if err != nil {
		// TODO: cast to custom error; if validation error 400 otherwise 500
		return apiResponse(withStatusCode(http.StatusInternalServerError), withBody(err.Error()))
	}

	return apiResponse(withStatusCode(http.StatusOK))
}

func StopTask(service *timelog.TimelogService, request *events.APIGatewayProxyRequest) (*events.APIGatewayProxyResponse, error) {
	payload, err := deserialize(request.Body)
	if err != nil {
		return apiResponse(withStatusCode(http.StatusBadRequest), withBody(err.Error()))
	}

	if payload.Timestamp == nil {
		return apiResponse(withStatusCode(http.StatusBadRequest), withBody("Timestamp is required"))
	}

	err = service.Stop(*payload.Timestamp)
	if err != nil {
		// TODO: cast to custom error; if validation error 400 otherwise 500
		return apiResponse(withStatusCode(http.StatusInternalServerError), withBody(err.Error()))
	}

	return apiResponse(withStatusCode(http.StatusOK))
}

func deserialize(body string) (*taskPayload, error) {
	var payload taskPayload
	err := json.Unmarshal([]byte(body), &payload)
	if err != nil {
		return nil, err
	}

	return &payload, nil
}
