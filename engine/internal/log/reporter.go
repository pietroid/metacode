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
	color  bool

	mu      sync.Mutex
	started map[Stage]time.Time
	printed bool
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
	return &Reporter{w: w, logger: logger, color: isTerminal(w)}
}

// Start records the stage's start time and announces it.
func (r *Reporter) Start(stage Stage) {
	r.mu.Lock()
	if r.started == nil {
		r.started = make(map[Stage]time.Time)
	}
	r.started[stage] = time.Now()
	r.mu.Unlock()

	clearActiveSpinner()
	// A blank line before each stage, so a run reads as a list of steps rather
	// than as one wall of lines. The first stage does not need one.
	if r.wasPrinted() {
		fmt.Fprintln(r.w)
	}
	fmt.Fprintf(r.w, "%s %s\n", paint(r.color, ansiCyan+ansiBold, "→"), paint(r.color, ansiBold, string(stage)))
	r.logger.Debugf("stage started: %s", stage)
}

// End reports the outcome, with how long the stage took. The timing is what
// says which stage of a run is the slow one, and in this engine that is nearly
// always a stage that waits on a model.
func (r *Reporter) End(stage Stage, err error) {
	elapsed := r.elapsed(stage)

	if err != nil {
		r.mark(stage, false, elapsed, err.Error())
		r.logger.Errorf("stage failed: %s: %v", stage, err)
		return
	}
	r.mark(stage, true, elapsed, "")
	r.logger.Debugf("stage completed: %s in %s", stage, elapsed)
}

// EndStatus reports an outcome whose cause has already been printed by the
// stage that raised it. The run as a whole ends this way: it is red when
// anything under it failed, without repeating that failure's message.
func (r *Reporter) EndStatus(stage Stage, ok bool) {
	r.mark(stage, ok, r.elapsed(stage), "")
}

// mark prints the one line a stage is remembered by: a green tick or a red
// cross, the stage name, and how long it took.
func (r *Reporter) mark(stage Stage, ok bool, elapsed time.Duration, detail string) {
	clearActiveSpinner()
	mark, color := "✓", ansiGreen
	if !ok {
		mark, color = "✗", ansiRed
	}
	line := fmt.Sprintf("%s %s %s",
		paint(r.color, color+ansiBold, mark),
		paint(r.color, color, string(stage)),
		paint(r.color, ansiDim, "("+elapsed.String()+")"))
	if detail != "" {
		line += ": " + paint(r.color, color, detail)
	}
	fmt.Fprintln(r.w, line)
}

// wasPrinted reports whether this reporter has written anything yet, and
// records that it is about to.
func (r *Reporter) wasPrinted() bool {
	r.mu.Lock()
	defer r.mu.Unlock()
	was := r.printed
	r.printed = true
	return was
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
