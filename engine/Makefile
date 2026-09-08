.PHONY: deps run test test-repeat fmt vet check build

# Resolves the module graph and writes go.sum. Run this first after pulling a
# change that adds a dependency.
deps:
	go mod tidy

run:
	go run ./cmd/metacode run

test:
	go test ./...

# Map iteration order is randomized per process, so a single pass can miss a
# nondeterminism regression. Repeat runs make it show up.
test-repeat:
	go test ./... -count=5

fmt:
	gofmt -w .

vet:
	go vet ./...

check: fmt vet test-repeat

build:
	go build -o bin/metacode ./cmd/metacode
