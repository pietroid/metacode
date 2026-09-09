package llm

import (
	"context"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/pietroid/metacode/engine/internal/log"
)

// TraceDirName is the directory, relative to the project root, where every
// prompt and response of a run is written.
const TraceDirName = ".metacode/llm"

// Tracer wraps a Client and records every call: a one-line summary and the
// timing on the logger, the full prompt and response at debug level, and a
// transcript file per call under TraceDirName.
//
// Prompts are the main thing that goes wrong in this engine, and until now they
// were invisible: a run reported "generated wrappers" and nothing about what it
// asked for or what came back.
type Tracer struct {
	inner    Client
	logger   log.Logger
	dir      string
	progress io.Writer

	mu    sync.Mutex
	n     int
	usage Usage
}

// NewTracer wraps inner. dir is the project root; transcripts go into
// dir/TraceDirName. An empty dir disables transcript files, leaving the log.
// progress is where the waiting animation is drawn; a nil progress means a
// silent wait, which is what a test wants.
func NewTracer(inner Client, logger log.Logger, dir string, progress io.Writer) *Tracer {
	if logger == nil {
		logger = log.Nop()
	}
	traceDir := ""
	if dir != "" {
		traceDir = filepath.Join(dir, TraceDirName)
	}
	return &Tracer{inner: inner, logger: logger, dir: traceDir, progress: progress}
}

// Usage is everything this tracer's calls have cost so far.
func (t *Tracer) Usage() Usage {
	t.mu.Lock()
	defer t.mu.Unlock()
	return t.usage
}

// Calls is how many requests have been made.
func (t *Tracer) Calls() int {
	t.mu.Lock()
	defer t.mu.Unlock()
	return t.n
}

// Complete implements Client. It animates the wait, because a request to a
// model is the one part of a run that takes minutes and, until it returned,
// looked exactly like a hang.
func (t *Tracer) Complete(ctx context.Context, call Call) (Result, error) {
	t.mu.Lock()
	t.n++
	seq := t.n
	t.mu.Unlock()

	label := call.Label
	if label == "" {
		label = "call"
	}

	t.logger.Infof("LLM call #%d [%s]: sending %s", seq, label, humanBytes(len(call.Prompt)))
	t.logger.Debugf("LLM call #%d [%s] prompt:\n%s", seq, label, call.Prompt)

	spinner := log.NewSpinner(t.progress)
	spinner.Start(fmt.Sprintf("LLM call #%d [%s] waiting for the model", seq, label))
	spinner.Detail(fmt.Sprintf("prompt %s", humanBytes(len(call.Prompt))))

	start := time.Now()
	out, err := t.inner.Complete(ctx, call)
	elapsed := time.Since(start)
	spinner.Stop("")

	if err != nil {
		t.logger.Errorf("LLM call #%d [%s] failed after %s: %s", seq, label, elapsed.Round(time.Millisecond), err)
		t.write(seq, label, call.Prompt, "ERROR: "+err.Error(), elapsed, Usage{})
		return Result{}, err
	}

	t.mu.Lock()
	t.usage.Add(out.Usage)
	total := t.usage
	t.mu.Unlock()

	t.logger.Infof("LLM call #%d [%s]: received %s in %s (%s; run total %s tokens)",
		seq, label, humanBytes(len(out.Text)), elapsed.Round(time.Millisecond),
		out.Usage, humanCount(total.Total()))
	t.logger.Debugf("LLM call #%d [%s] response:\n%s", seq, label, out.Text)
	t.write(seq, label, call.Prompt, out.Text, elapsed, out.Usage)

	return out, nil
}

// write saves the transcript. A failure to write is reported and otherwise
// ignored: losing the trace must not fail the run that produced it.
func (t *Tracer) write(seq int, label, prompt, response string, elapsed time.Duration, usage Usage) {
	if t.dir == "" {
		return
	}
	if err := os.MkdirAll(t.dir, 0755); err != nil {
		t.logger.Warnf("could not create %s: %s", t.dir, err)
		return
	}

	name := fmt.Sprintf("%02d-%s.md", seq, slug(label))
	path := filepath.Join(t.dir, name)

	var b strings.Builder
	fmt.Fprintf(&b, "# call %d: %s\n\n", seq, label)
	fmt.Fprintf(&b, "elapsed: %s\nprompt: %d bytes\nresponse: %d bytes\ntokens: %s\n\n", elapsed.Round(time.Millisecond), len(prompt), len(response), usage)
	b.WriteString("## prompt\n\n")
	b.WriteString(prompt)
	b.WriteString("\n\n## response\n\n")
	b.WriteString(response)
	b.WriteString("\n")

	if err := os.WriteFile(path, []byte(b.String()), 0644); err != nil {
		t.logger.Warnf("could not write %s: %s", path, err)
		return
	}
	t.logger.Debugf("LLM transcript written to %s", path)
}

// ResetTraceDir clears transcripts from earlier runs, so what is on disk is
// always one run's worth of calls.
func ResetTraceDir(projectDir string) error {
	if projectDir == "" {
		return nil
	}
	return os.RemoveAll(filepath.Join(projectDir, TraceDirName))
}

func slug(s string) string {
	var b strings.Builder
	last := true
	for _, r := range strings.ToLower(s) {
		if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') {
			b.WriteRune(r)
			last = false
			continue
		}
		if !last {
			b.WriteByte('-')
			last = true
		}
	}
	return strings.Trim(b.String(), "-")
}

func humanBytes(n int) string {
	if n < 1024 {
		return fmt.Sprintf("%d B", n)
	}
	return fmt.Sprintf("%.1f KB", float64(n)/1024)
}
