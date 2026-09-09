# Metacode development tasks. Run `make check` before every commit.

GO ?= go
ENGINE := ./engine

.PHONY: check test vet deadcode cyclo fmt

# check is the gate: it must be green on every commit.
check: fmt vet test deadcode cyclo

test:
	cd $(ENGINE) && $(GO) test ./...

vet:
	cd $(ENGINE) && $(GO) vet ./...

fmt:
	cd $(ENGINE) && $(GO) fmt ./... | (! grep .) || (echo "gofmt rewrote files; commit them" && exit 1)

# deadcode reports functions nothing reaches. The tree is kept at zero.
deadcode:
	cd $(ENGINE) && $(GO) run golang.org/x/tools/cmd/deadcode@latest -test ./... | (! grep .)

# cyclo caps branching per function in the code that ships. Tests are excluded:
# gocyclo counts every subtest closure into its parent, so a table of
# assertions scores like a branching algorithm while carrying none of the risk.
cyclo:
	cd $(ENGINE) && $(GO) run github.com/fzipp/gocyclo/cmd/gocyclo@latest -over 12 -ignore "_test\.go" . | (! grep .)
