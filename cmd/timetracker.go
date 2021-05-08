package main

import (
	"fmt"
	"net/http"
	"os"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"

	"github.com/saesh/timetracker/pkg/handlers"
	"github.com/saesh/timetracker/pkg/timelog"
)

func main() {
	bucket, ok := os.LookupEnv("s3_bucket")
	if !ok {
		panic("missing environment variable s3_bucket")
	}

	region, ok := os.LookupEnv("aws_region")
	if !ok {
		region = "eu-central-1"
	}

	awsSession := session.Must(session.NewSession(&aws.Config{
		Region: aws.String(region),
	}))

	repository := &timelog.S3TimelogRepository{
		AwsSession: awsSession,
		Bucket:     bucket,
		Key:        fmt.Sprintf("%v.timeclock", time.Now().Year()),
	}

	service := &timelog.TimelogService{Repository: repository}

	lambda.Start(handler(service))
}

func handler(service *timelog.TimelogService) func(events.APIGatewayProxyRequest) (*events.APIGatewayProxyResponse, error) {
	return func(request events.APIGatewayProxyRequest) (*events.APIGatewayProxyResponse, error) {

		switch request.HTTPMethod {
		case http.MethodPost:
			if request.Path == "/start" {
				return handlers.StartTask(service, &request)
			}

			if request.Path == "/stop" {
				return handlers.StopTask(service, &request)
			}

			return handlers.NotFound()
		default:
			return handlers.MethodNotSupported()
		}
	}
}
