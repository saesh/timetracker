package timelog

import "time"

const (
	InType  string = "i"
	OutType string = "o"
)

type Timelog struct {
	Type        string
	Description string
	Timestamp   string
}

type TimelogRepository interface {
	Add(timelog *Timelog) error
	GetLast() (*Timelog, error)
}

type TimelogService struct {
	Repository TimelogRepository
}

func (s *TimelogService) Start(timestamp, description string) error {
	timelog, err := s.Repository.GetLast()
	if err != nil {
		return err
	}

	if timelog.Type == InType {
		berlin, _ := time.LoadLocation("Europe/Berlin")
		s.Stop(time.Now().In(berlin).Format("2006-01-02 15:04:05"))
	}

	return s.Repository.Add(&Timelog{
		Type:        InType,
		Timestamp:   timestamp,
		Description: description,
	})
}

func (s *TimelogService) Stop(timestamp string) error {
	return s.Repository.Add(&Timelog{
		Type:      OutType,
		Timestamp: timestamp,
	})
}
