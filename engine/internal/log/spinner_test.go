package log

import (
	"bytes"
	"strings"
	"testing"
)

// TestSpinnerQuietOffTerminal is the behaviour that keeps a piped run readable:
// a buffer is not a terminal, so the animation degrades to the message and the
// summary, with no escape codes between them.
func TestSpinnerQuietOffTerminal(t *testing.T) {
	var buf bytes.Buffer
	s := NewSpinner(&buf)

	s.Start("running tests")
	s.Detail("3 passed")
	s.StopWith(true, "3 passed")

	out := buf.String()
	if !strings.Contains(out, "running tests") {
		t.Errorf("expected the start message, got:\n%q", out)
	}
	if !strings.Contains(out, "✓ 3 passed") {
		t.Errorf("expected the marked summary, got:\n%q", out)
	}
	if strings.Contains(out, "\033[") {
		t.Errorf("expected no escape codes off a terminal, got:\n%q", out)
	}
}

func TestSpinnerStopWithFailureMark(t *testing.T) {
	var buf bytes.Buffer
	s := NewSpinner(&buf)
	s.Start("running tests")
	s.StopWith(false, "1 failed")

	if !strings.Contains(buf.String(), "✗ 1 failed") {
		t.Errorf("expected a failure mark, got:\n%q", buf.String())
	}
}

// TestSpinnerStopBeforeStart makes sure a stage that never started cannot
// print a stray summary or block on a channel that was never made.
func TestSpinnerStopBeforeStart(t *testing.T) {
	var buf bytes.Buffer
	NewSpinner(&buf).Stop("never")
	if buf.Len() != 0 {
		t.Errorf("expected no output, got %q", buf.String())
	}
}
