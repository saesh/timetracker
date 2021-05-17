package timelog

import (
	"errors"
	"fmt"
	"io"
	"os"
	"strings"
	"time"

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
func (r *S3TimelogRepository) Add(timelog *Timelog) error {
	timeclockFile, err := os.Create("/tmp/" + r.Key)
	if err != nil {
		return err
	}
	defer timeclockFile.Close()

	err = downloadS3(r.AwsSession, timeclockFile, r.Bucket, r.Key)
	if err != nil {
		return err
	}

	fileEntry, err := timelogToFileEntry(timelog)
	if err != nil {
		return err
	}

	timeclockFile.Seek(0, io.SeekEnd)
	_, err = timeclockFile.WriteString(fileEntry)
	if err != nil {
		return err
	}

	timeclockFile.Seek(0, io.SeekStart)
	err = uploadS3(r.AwsSession, timeclockFile, r.Bucket, r.Key)
	if err != nil {
		return err
	}

	return nil
}

func (r *S3TimelogRepository) GetLast() (*Timelog, error) {
	timeclockFile, err := os.Create(fmt.Sprintf("%v%v.%v", "/tmp/", r.Key, time.Now().Unix()))
	if err != nil {
		return nil, err
	}
	defer timeclockFile.Close()

	err = downloadS3(r.AwsSession, timeclockFile, r.Bucket, r.Key)
	if err != nil {
		return nil, err
	}

	timelog, err := lastTimelogEntry(timeclockFile)
	if err != nil {
		return nil, err
	}

	return timelog, nil
}

func timelogToFileEntry(timelog *Timelog) (string, error) {
	var fileEntry string

	if timelog.Type == "o" {
		fileEntry = fmt.Sprintf("%v %v\n", timelog.Type, strings.TrimSpace(timelog.Timestamp))
	} else if timelog.Type == "i" {
		fileEntry = fmt.Sprintf("%v %v %v\n", timelog.Type, strings.TrimSpace(timelog.Description), strings.TrimSpace(timelog.Timestamp))
	} else {
		return "", errors.New("unrecognized timelog type")
	}

	return fileEntry, nil
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

func lastTimelogEntry(file *os.File) (*Timelog, error) {
	line := ""
	var offset int64 = 0

	stat, _ := file.Stat()
	fileSize := stat.Size()

	for {
		offset -= 1
		file.Seek(offset, io.SeekEnd)
		char := make([]byte, 1)
		file.Read(char)

		if offset != -1 && (char[0] == 10 || char[0] == 13) {
			break
		}

		line = fmt.Sprintf("%s%s", string(char), line)

		if offset == -fileSize {
			break
		}
	}

	timelogElements := strings.Split(line, " ")

	timelog := &Timelog{
		Type:      timelogElements[0],
		Timestamp: timelogElements[1],
	}
	if len(timelogElements) == 3 {
		timelog.Description = timelogElements[2]
	}

	return timelog, nil
}
