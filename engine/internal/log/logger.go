package log

import (
	"fmt"
	"io"
)

// Level represents a logging severity level.
type Level int

const (
	DebugLevel Level = iota
	InfoLevel
	WarnLevel
	ErrorLevel
)

func (l Level) String() string {
	switch l {
	case DebugLevel:
		return "DEBUG"
	case InfoLevel:
		return "INFO"
	case WarnLevel:
		return "WARN"
	case ErrorLevel:
		return "ERROR"
	default:
		return "UNKNOWN"
	}
}

// Logger emits structured log messages.
type Logger interface {
	Debugf(format string, args ...any)
	Infof(format string, args ...any)
	Warnf(format string, args ...any)
	Errorf(format string, args ...any)
}

// New creates a Logger writing to w at the given minimum level.
func New(w io.Writer, minLevel Level) Logger {
	if w == nil {
		w = io.Discard
	}
	return &stdLogger{w: w, level: minLevel}
}

// Nop returns a logger that discards all output.
func Nop() Logger {
	return New(io.Discard, ErrorLevel+1)
}

type stdLogger struct {
	w     io.Writer
	level Level
}

func (l *stdLogger) log(level Level, format string, args ...any) {
	if level < l.level {
		return
	}
	msg := fmt.Sprintf(format, args...)
	fmt.Fprintf(l.w, "[%s] %s\n", level, msg)
}

func (l *stdLogger) Debugf(format string, args ...any) { l.log(DebugLevel, format, args...) }
func (l *stdLogger) Infof(format string, args ...any)  { l.log(InfoLevel, format, args...) }
func (l *stdLogger) Warnf(format string, args ...any)  { l.log(WarnLevel, format, args...) }
func (l *stdLogger) Errorf(format string, args ...any) { l.log(ErrorLevel, format, args...) }
