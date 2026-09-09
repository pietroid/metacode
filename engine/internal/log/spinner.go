package log

import (
	"fmt"
	"io"
	"sync"
	"time"
)

// frames are the animation. Braille dots read as motion at any width and cost
// one column.
var frames = []string{"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}

// spinnerInterval is how often the frame advances.
const spinnerInterval = 90 * time.Millisecond

// indent lines the animation up with the log lines of the stage it belongs to.
const indent = "  "

// activeMu guards the spinner that currently owns the last line of output, so
// a log line written while it animates can erase it first.
var (
	activeMu sync.Mutex
	active   *Spinner
)

func clearActiveSpinner() {
	activeMu.Lock()
	defer activeMu.Unlock()
	if active != nil {
		active.erase()
	}
}

// Spinner animates one line of progress while a slow stage runs: an LLM call
// waiting on a model, or a test suite reporting as it goes.
//
// On anything that is not a terminal it degrades to plain lines, which is what
// a piped run or a CI log wants: the message once at the start, the summary at
// the end, and nothing in between.
type Spinner struct {
	w         io.Writer
	animate   bool
	started   time.Time
	stop      chan struct{}
	done      chan struct{}
	mu        sync.Mutex
	message   string
	detail    string
	frame     int
	onScreen  bool
	isRunning bool
}

// NewSpinner creates a spinner writing to w. A nil w discards everything.
func NewSpinner(w io.Writer) *Spinner {
	if w == nil {
		w = io.Discard
	}
	return &Spinner{w: w, animate: isTerminal(w)}
}

// Start begins the animation under the given message.
func (s *Spinner) Start(message string) {
	s.mu.Lock()
	if s.isRunning {
		s.mu.Unlock()
		return
	}
	s.isRunning = true
	s.message = message
	s.detail = ""
	s.started = time.Now()
	s.stop = make(chan struct{})
	s.done = make(chan struct{})
	s.mu.Unlock()

	if !s.animate {
		fmt.Fprintf(s.w, "%s%s %s\n", indent, "…", message)
		close(s.done)
		return
	}

	activeMu.Lock()
	active = s
	activeMu.Unlock()

	go s.spin()
}

// Detail replaces the trailing part of the line: what the stage is doing right
// now, such as which test is running or how many have passed.
func (s *Spinner) Detail(detail string) {
	s.mu.Lock()
	s.detail = detail
	s.mu.Unlock()
}

// Stop ends the animation and, when final is non-empty, leaves it on screen as
// the one line the stage is remembered by.
func (s *Spinner) Stop(final string) {
	s.mu.Lock()
	if !s.isRunning {
		s.mu.Unlock()
		return
	}
	s.isRunning = false
	stop := s.stop
	done := s.done
	s.mu.Unlock()

	if s.animate {
		close(stop)
		<-done
		activeMu.Lock()
		if active == s {
			active = nil
		}
		activeMu.Unlock()
		s.erase()
	}

	if final != "" {
		fmt.Fprintln(s.w, final)
	}
}

// StopWith ends the animation and leaves a marked, coloured line behind: a
// green tick for a stage that succeeded, a red cross for one that did not.
func (s *Spinner) StopWith(ok bool, final string) {
	mark, color := "✓", ansiGreen
	if !ok {
		mark, color = "✗", ansiRed
	}
	s.Stop(indent + paint(s.animate, color, mark+" "+final))
}

func (s *Spinner) spin() {
	defer close(s.done)
	ticker := time.NewTicker(spinnerInterval)
	defer ticker.Stop()
	s.draw()
	for {
		select {
		case <-s.stop:
			return
		case <-ticker.C:
			s.draw()
		}
	}
}

func (s *Spinner) draw() {
	s.mu.Lock()
	frame := frames[s.frame%len(frames)]
	s.frame++
	line := s.message
	if s.detail != "" {
		line += " " + paint(true, ansiGray, s.detail)
	}
	elapsed := time.Since(s.started).Truncate(time.Second)
	s.onScreen = true
	s.mu.Unlock()

	fmt.Fprintf(s.w, "%s%s%s %s %s", clearLine, indent,
		paint(true, ansiCyan, frame), line,
		paint(true, ansiDim, fmt.Sprintf("(%s)", elapsed)))
}

// erase removes the animated line so something else can write where it was.
func (s *Spinner) erase() {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.onScreen {
		return
	}
	s.onScreen = false
	fmt.Fprint(s.w, clearLine)
}
