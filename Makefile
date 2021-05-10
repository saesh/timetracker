.PHONY: build
build:
	GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o target/authorizer cmd/authorizer/main.go
	GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o target/timetracker cmd/timetracker/main.go

.PHONY: clean
clean:
	rm -rf target

.PHONY: release-authorizer
release-authorizer: build zip
	aws lambda update-function-code \
		--function-name "BasicAuth" \
		--zip-file fileb://target/authorizer.zip \
		--no-publish

.PHONY: release-timetracker
release-timetracker: build zip
	aws lambda update-function-code \
		--function-name "TimeTracker" \
		--zip-file fileb://target/timetracker.zip \
		--no-publish

.PHONY: zip
zip:
	zip -j target/timetracker.zip \
		target/timetracker
	zip -j target/authorizer.zip \
		target/authorizer