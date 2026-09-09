package run

import (
	"bytes"
	"strings"
	"testing"

	"github.com/pietroid/metacode/engine/internal/log"
)

func TestProgressCountsPassesAndFailures(t *testing.T) {
	var buf bytes.Buffer
	p := newTestProgress(nil, log.New(&buf, log.DebugLevel), "")

	_, _ = p.Write([]byte("00:01 +1: test/a_test.dart: increments from 0\n"))
	_, _ = p.Write([]byte("00:02 +2: test/b_test.dart: increments from 1\n"))
	_, _ = p.Write([]byte("00:03 +2 -1: test/c_test.dart: decrements from 1 [E]\n"))

	if got := p.summary(); !strings.Contains(got, "2 passed, 1 failed") {
		t.Errorf("expected the running tally, got %q", got)
	}
	if !strings.Contains(buf.String(), "✗ test/c_test.dart: decrements from 1") {
		t.Errorf("expected the failing test named on its own line, got:\n%s", buf.String())
	}
}

// TestProgressHandlesSplitChunks is why the writer holds a tail: a pipe splits
// wherever it likes, and a half-read counter line would report the wrong score.
func TestProgressHandlesSplitChunks(t *testing.T) {
	p := newTestProgress(nil, log.Nop(), "")

	_, _ = p.Write([]byte("00:01 +1: test/a_test.dart: incre"))
	_, _ = p.Write([]byte("ments\n00:02 +7: test/b_test.dart: done\n"))

	if got := p.summary(); !strings.Contains(got, "7 passed") {
		t.Errorf("expected the last counter to win, got %q", got)
	}
}

// TestProgressReadsCarriageReturns covers a suite that thinks it is writing to
// a terminal and separates its updates with \r rather than \n.
func TestProgressReadsCarriageReturns(t *testing.T) {
	p := newTestProgress(nil, log.Nop(), "")

	_, _ = p.Write([]byte("00:01 +1: a\r00:02 +2: b\r"))

	if got := p.summary(); !strings.Contains(got, "2 passed") {
		t.Errorf("expected carriage-returned updates to count, got %q", got)
	}
}

// TestProgressStripsProjectDir keeps the live line readable: a suite names
// every test by absolute path, which fills the line before the test name.
func TestProgressStripsProjectDir(t *testing.T) {
	p := newTestProgress(nil, log.Nop(), "/home/me/app")

	_, _ = p.Write([]byte("00:01 +0 -1: /home/me/app/test/a_test.dart: increments [E]\n"))

	if p.current != "test/a_test.dart: increments" {
		t.Errorf("expected the project-relative name, got %q", p.current)
	}
}

// TestTruncateCutsByRune guards against a name cut mid-character, which prints
// as replacement junk on the line the whole suite is watched through.
func TestTruncateCutsByRune(t *testing.T) {
	got := truncate(strings.Repeat("é", 10), 5)
	if []rune(got)[4] != '…' || len([]rune(got)) != 5 {
		t.Errorf("expected a 5-rune truncation ending in an ellipsis, got %q", got)
	}
}
