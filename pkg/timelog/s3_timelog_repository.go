package timelog

import (
	"fmt"
	"io"
	"os"
	"strings"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/s3/s3manager"
)

type S3TimelogRepository struct {
	AwsSession *session.Session
	Bucket     string
	Key        string
}

// Add appends the timelog entry to the timelog file in an S3 bucket
func (r *S3TimelogRepository) Add(timelog Timelog) error {
	timeclockFile, err := os.Create("/tmp/" + r.Key)
	if err != nil {
		return err
	}
	defer timeclockFile.Close()

	err = downloadS3(r.AwsSession, timeclockFile, r.Bucket, r.Key)
	if err != nil {
		return err
	}

	fileEntry := fmt.Sprintf("%v %v %v\n", timelog.Type, strings.TrimSpace(timelog.Description), strings.TrimSpace(timelog.Timestamp))

	timeclockFile.Seek(0, 2)
	_, err = timeclockFile.WriteString(fileEntry)
	if err != nil {
		return err
	}

	timeclockFile.Seek(0, 0)
	err = uploadS3(r.AwsSession, timeclockFile, r.Bucket, r.Key)
	if err != nil {
		return err
	}

	return nil
}

func downloadS3(session *session.Session, writer io.WriterAt, bucket, key string) error {
	downloader := s3manager.NewDownloader(session)
	_, err := downloader.Download(writer, &s3.GetObjectInput{
		Bucket: aws.String(bucket),
		Key:    aws.String(key),
	})

	if err != nil {
		if aerr, ok := err.(awserr.Error); ok {
			switch aerr.Code() {
			case s3.ErrCodeNoSuchKey:
				return nil
			default:
				return err
			}
		}
	}

	return err
}

func uploadS3(session *session.Session, file io.Reader, bucket, key string) error {
	uploader := s3manager.NewUploader(session)

	_, err := uploader.Upload(&s3manager.UploadInput{
		Body:   file,
		Bucket: aws.String(bucket),
		Key:    aws.String(key),
	})

	return err
}
