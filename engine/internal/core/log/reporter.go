package log

import (
	"fmt"
	"io"
)

// Stage identifies a named pipeline stage.
type Stage string

// Reporter prints stage start/end markers.
type Reporter interface {
	Start(stage Stage)
	End(stage Stage, err error)
}

// NewReporter creates a Reporter writing to w.
func NewReporter(w io.Writer, logger Logger) Reporter {
	if w == nil {
		w = io.Discard
	}
	if logger == nil {
		logger = Nop()
	}
	return &stdReporter{w: w, logger: logger}
}

// NopReporter returns a reporter that discards all output.
func NopReporter() Reporter {
	return NewReporter(io.Discard, Nop())
}

type stdReporter struct {
	w      io.Writer
	logger Logger
}

func (r *stdReporter) Start(stage Stage) {
	fmt.Fprintf(r.w, "→ %s\n", stage)
	r.logger.Debugf("stage started: %s", stage)
}

func (r *stdReporter) End(stage Stage, err error) {
	if err != nil {
		fmt.Fprintf(r.w, "✗ %s: %v\n", stage, err)
		r.logger.Errorf("stage failed: %s: %v", stage, err)
		return
	}
	fmt.Fprintf(r.w, "✓ %s\n", stage)
	r.logger.Debugf("stage completed: %s", stage)
}
