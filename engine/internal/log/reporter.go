package log

import (
	"fmt"
	"io"
	"sync"
	"time"
)

// Stage identifies a named pipeline stage.
type Stage string

// Reporter prints stage start and end markers, with how long each stage took.
type Reporter struct {
	w      io.Writer
	logger Logger

	mu      sync.Mutex
	started map[Stage]time.Time
}

// NewReporter creates a Reporter writing to w. A nil w discards, which is what
// a test that only cares about generated output wants.
func NewReporter(w io.Writer, logger Logger) *Reporter {
	if w == nil {
		w = io.Discard
	}
	if logger == nil {
		logger = Nop()
	}
	return &Reporter{w: w, logger: logger}
}

// Start records the stage's start time and announces it.
func (r *Reporter) Start(stage Stage) {
	r.mu.Lock()
	if r.started == nil {
		r.started = make(map[Stage]time.Time)
	}
	r.started[stage] = time.Now()
	r.mu.Unlock()

	fmt.Fprintf(r.w, "→ %s\n", stage)
	r.logger.Debugf("stage started: %s", stage)
}

// End reports the outcome, with how long the stage took. The timing is what
// says which stage of a run is the slow one, and in this engine that is nearly
// always a stage that waits on a model.
func (r *Reporter) End(stage Stage, err error) {
	elapsed := r.elapsed(stage)

	if err != nil {
		fmt.Fprintf(r.w, "✗ %s (%s): %v\n", stage, elapsed, err)
		r.logger.Errorf("stage failed: %s: %v", stage, err)
		return
	}
	fmt.Fprintf(r.w, "✓ %s (%s)\n", stage, elapsed)
	r.logger.Debugf("stage completed: %s in %s", stage, elapsed)
}

func (r *Reporter) elapsed(stage Stage) time.Duration {
	r.mu.Lock()
	defer r.mu.Unlock()
	start, ok := r.started[stage]
	if !ok {
		return 0
	}
	delete(r.started, stage)
	return time.Since(start).Round(time.Millisecond)
}
