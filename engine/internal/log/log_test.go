package log

import (
	"bytes"
	"errors"
	"strings"
	"testing"
)

func TestLoggerLevels(t *testing.T) {
	var buf bytes.Buffer
	log := New(&buf, DebugLevel)

	log.Debugf("debug %s", "message")
	log.Infof("info %d", 42)
	log.Warnf("warn")
	log.Errorf("error")

	out := buf.String()
	for _, want := range []string{"[DEBUG] debug message", "[INFO] info 42", "[WARN] warn", "[ERROR] error"} {
		if !strings.Contains(out, want) {
			t.Errorf("expected output to contain %q, got:\n%s", want, out)
		}
	}
}

func TestLoggerRespectsMinLevel(t *testing.T) {
	var buf bytes.Buffer
	log := New(&buf, WarnLevel)

	log.Debugf("debug")
	log.Infof("info")
	log.Warnf("warn")
	log.Errorf("error")

	out := buf.String()
	if strings.Contains(out, "[DEBUG]") || strings.Contains(out, "[INFO]") {
		t.Errorf("expected debug/info messages to be filtered, got:\n%s", out)
	}
	if !strings.Contains(out, "[WARN] warn") || !strings.Contains(out, "[ERROR] error") {
		t.Errorf("expected warn/error messages to be present, got:\n%s", out)
	}
}

func TestNopLogger(t *testing.T) {
	var buf bytes.Buffer
	log := New(&buf, ErrorLevel+1)
	log.Errorf("should not appear")
	if buf.Len() != 0 {
		t.Errorf("expected nop logger to write nothing, got:\n%s", buf.String())
	}
}

func TestReporterStartEnd(t *testing.T) {
	var buf bytes.Buffer
	r := NewReporter(&buf, Nop())

	r.Start("Parsing specs")
	r.End("Parsing specs", nil)

	out := buf.String()
	if !strings.Contains(out, "→ Parsing specs") {
		t.Errorf("expected start marker, got:\n%s", out)
	}
	if !strings.Contains(out, "✓ Parsing specs") {
		t.Errorf("expected success end marker, got:\n%s", out)
	}
}

func TestReporterEndError(t *testing.T) {
	var buf bytes.Buffer
	r := NewReporter(&buf, Nop())

	r.Start("Generating")
	r.End("Generating", errors.New("boom"))

	out := buf.String()
	if !strings.Contains(out, "✗ Generating: boom") {
		t.Errorf("expected failure marker with error, got:\n%s", out)
	}
}
