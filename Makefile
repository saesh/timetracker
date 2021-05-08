.PHONY: build
build:
	GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o target/timetracker cmd/timetracker.go

.PHONY: clean
clean:
	rm -rf target

.PHONY: release
release: build zip
	aws lambda update-function-code \
		--function-name "TimeTracker" \
		--zip-file fileb://target/timetracker.zip \
		--no-publish

.PHONY: zip
zip:
	zip -j target/timetracker.zip \
		target/timetracker