package timelog

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
	Add(timelog Timelog) error
}

type TimelogService struct {
	Repository TimelogRepository
}

func (s *TimelogService) Start(timestamp, description string) error {
	return s.Repository.Add(Timelog{
		Type:        InType,
		Timestamp:   timestamp,
		Description: description,
	})
}

func (s *TimelogService) Stop(timestamp string) error {
	return s.Repository.Add(Timelog{
		Type:      OutType,
		Timestamp: timestamp,
	})
}
