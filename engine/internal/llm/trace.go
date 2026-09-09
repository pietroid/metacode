package llm

import (
	"context"
	"fmt"
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
	inner  Client
	logger log.Logger
	dir    string

	mu sync.Mutex
	n  int
}

// NewTracer wraps inner. dir is the project root; transcripts go into
// dir/TraceDirName. An empty dir disables transcript files, leaving the log.
func NewTracer(inner Client, logger log.Logger, dir string) *Tracer {
	if logger == nil {
		logger = log.Nop()
	}
	traceDir := ""
	if dir != "" {
		traceDir = filepath.Join(dir, TraceDirName)
	}
	return &Tracer{inner: inner, logger: logger, dir: traceDir}
}

// Complete implements Client.
func (t *Tracer) Complete(ctx context.Context, call Call) (string, error) {
	t.mu.Lock()
	t.n++
	seq := t.n
	t.mu.Unlock()

	label := call.Label
	if label == "" {
		label = "call"
	}

	t.logger.Infof("llm call #%d [%s]: sending %s", seq, label, humanBytes(len(call.Prompt)))
	t.logger.Debugf("llm call #%d [%s] prompt:\n%s", seq, label, call.Prompt)

	start := time.Now()
	out, err := t.inner.Complete(ctx, call)
	elapsed := time.Since(start)

	if err != nil {
		t.logger.Errorf("llm call #%d [%s] failed after %s: %s", seq, label, elapsed.Round(time.Millisecond), err)
		t.write(seq, label, call.Prompt, "ERROR: "+err.Error(), elapsed)
		return "", err
	}

	t.logger.Infof("llm call #%d [%s]: received %s in %s", seq, label, humanBytes(len(out)), elapsed.Round(time.Millisecond))
	t.logger.Debugf("llm call #%d [%s] response:\n%s", seq, label, out)
	t.write(seq, label, call.Prompt, out, elapsed)

	return out, nil
}

// write saves the transcript. A failure to write is reported and otherwise
// ignored: losing the trace must not fail the run that produced it.
func (t *Tracer) write(seq int, label, prompt, response string, elapsed time.Duration) {
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
	fmt.Fprintf(&b, "elapsed: %s\nprompt: %d bytes\nresponse: %d bytes\n\n", elapsed.Round(time.Millisecond), len(prompt), len(response))
	b.WriteString("## prompt\n\n")
	b.WriteString(prompt)
	b.WriteString("\n\n## response\n\n")
	b.WriteString(response)
	b.WriteString("\n")

	if err := os.WriteFile(path, []byte(b.String()), 0644); err != nil {
		t.logger.Warnf("could not write %s: %s", path, err)
		return
	}
	t.logger.Debugf("llm transcript written to %s", path)
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
