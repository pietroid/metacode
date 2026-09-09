package run

import (
	"fmt"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"

	"github.com/pietroid/metacode/engine/internal/log"
)

// counterLine is the shape of every progress line a Dart test run prints:
// "00:03 +7 -1: test/foo_test.dart: some scenario [E]". The counts are
// cumulative, so the last line seen is the current tally.
var counterLine = regexp.MustCompile(`^\d+:\d+\s+\+(\d+)(?:\s+-(\d+))?:\s*(.*)$`)

// testProgress reads the suite's output as it arrives and turns it into one
// live line, plus a log line for each test that fails.
//
// It exists because "Running tests" used to be a single stage marker that sat
// still for minutes and then printed several hundred lines at once. A suite
// reports per test; there is no reason to watch it in one lump.
type testProgress struct {
	spinner *log.Spinner
	logger  log.Logger
	// projectDir is stripped from the paths the suite reports, which name
	// every test by its absolute path and leave no room for anything else.
	projectDir string

	partial string
	passed  int
	failed  int
	current string
}

func newTestProgress(spinner *log.Spinner, logger log.Logger, projectDir string) *testProgress {
	if logger == nil {
		logger = log.Nop()
	}
	return &testProgress{spinner: spinner, logger: logger, projectDir: projectDir}
}

// Write implements io.Writer so it can be attached to the command's output. A
// chunk can end mid-line, so the tail is held until the rest arrives.
func (p *testProgress) Write(b []byte) (int, error) {
	text := p.partial + string(b)
	// A suite that thinks it is on a terminal separates updates with a
	// carriage return, so both count as a line break here.
	text = strings.ReplaceAll(text, "\r", "\n")
	lines := strings.Split(text, "\n")
	p.partial = lines[len(lines)-1]
	for _, line := range lines[:len(lines)-1] {
		p.line(line)
	}
	return len(b), nil
}

func (p *testProgress) line(line string) {
	m := counterLine.FindStringSubmatch(strings.TrimSpace(line))
	if m == nil {
		return
	}

	p.passed = atoi(m[1])
	p.failed = atoi(m[2])
	name := strings.TrimSuffix(strings.TrimSpace(m[3]), "[E]")
	name = strings.TrimSpace(p.relative(name))

	if strings.HasSuffix(line, "[E]") {
		p.logger.Errorf("✗ %s", name)
	} else if name != "" && name != p.current {
		p.logger.Debugf("✓ %s", name)
	}
	if name != "" {
		p.current = name
	}
	p.update()
}

// relative rewrites the project's own directory out of a reported name, so the
// line reads "test/increments_test.dart: increments from 0" and not the fifty
// characters of absolute path in front of it.
func (p *testProgress) relative(name string) string {
	if p.projectDir == "" {
		return name
	}
	return strings.ReplaceAll(name, p.projectDir+string(filepath.Separator), "")
}

func (p *testProgress) update() {
	if p.spinner == nil {
		return
	}
	p.spinner.Detail(p.tally() + " " + truncate(p.current, 60))
}

// tally is the running score, which is what a watcher of a long suite is
// actually reading.
func (p *testProgress) tally() string {
	if p.failed > 0 {
		return fmt.Sprintf("%d passed, %d failed", p.passed, p.failed)
	}
	return fmt.Sprintf("%d passed", p.passed)
}

// summary is the line the stage leaves behind once the suite has finished.
func (p *testProgress) summary() string {
	return p.tally()
}

func atoi(s string) int {
	n, err := strconv.Atoi(s)
	if err != nil {
		return 0
	}
	return n
}

// truncate cuts by rune, not by byte: a name cut mid-character renders as
// replacement junk on the one line the whole suite is being watched through.
func truncate(s string, max int) string {
	runes := []rune(s)
	if len(runes) <= max {
		return s
	}
	return string(runes[:max-1]) + "…"
}
