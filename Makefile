MAKEFLAGS += --no-print-directory

GOOS ?= $(shell go env GOOS)
GOARCH ?= $(shell go env GOARCH)
GOBIN ?= $(shell go env GOPATH)/bin

netscanner_version :=  $(shell cat version.txt)
netscanner_module := github.com/hdecarne-github/netscanner

LDFLAGS := $(LDFLAGS) -X $(netscanner_module)/internal/version.buildVersion=$(netscanner_version) -X $(netscanner_module)/internal/version.buildTimestamp=$(shell date +%Y%m%d%H%M%S)

.DEFAULT_GOAL := build

.PHONY: deps
deps:
	go mod download -x

.PHONY: testdeps
testdeps: deps
	go install honnef.co/go/tools/cmd/staticcheck@2022.1.3

.PHONY: tidy
tidy:
	go mod verify
	go mod tidy

.PHONY: build
build: deps
ifneq (windows, $(GOOS))
	go build -ldflags "$(LDFLAGS)" -o build/bin/netscanner-cli ./cmd/netscanner-cli
	go build -ldflags "$(LDFLAGS)" -o build/bin/netscanner ./cmd/netscanner
else
	go build -ldflags "$(LDFLAGS)" -o build/bin/netscanner-cli.exe ./cmd/netscanner-cli
	go build -ldflags "$(LDFLAGS)" -o build/bin/netscanner.exe ./cmd/netscanner
endif

.PHONY: dist
dist: build
	mkdir -p build/dist
	tar czvf build/dist/$(plugin_name)-$(GOOS)-$(GOARCH)-$(plugin_version).tar.gz -C build/bin .
ifneq (, $(shell command -v zip 2>/dev/null))
	zip -j build/dist/$(plugin_name)-$(GOOS)-$(GOARCH)-$(plugin_version).zip build/bin/*
else ifneq (, $(shell command -v 7z 2>/dev/null))
	7z a -bd build/dist/$(plugin_name)-$(GOOS)-$(GOARCH)-$(plugin_version).zip ./build/bin/*
endif

.PHONY: vet
vet: testdeps
	go vet ./...

.PHONY: staticcheck
staticcheck: testdeps
	$(GOBIN)/staticcheck ./...

.PHONY: lint
lint: vet staticcheck

.PHONY: test
test:
	go test -v -covermode=atomic -coverprofile=build/coverage.out ./...

.PHONY: check
check: test lint

.PHONY: clean
clean:
	go clean ./...
	rm -rf build
