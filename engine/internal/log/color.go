package log

import (
	"io"
	"os"
)

// ANSI escape codes. They are written only when the destination is a terminal,
// so a piped run or a test that captures a buffer still reads as plain text.
const (
	ansiReset  = "\033[0m"
	ansiBold   = "\033[1m"
	ansiDim    = "\033[2m"
	ansiRed    = "\033[31m"
	ansiGreen  = "\033[32m"
	ansiYellow = "\033[33m"
	ansiBlue   = "\033[34m"
	ansiCyan   = "\033[36m"
	ansiGray   = "\033[90m"

	// clearLine returns the cursor to the start of the line and erases it,
	// which is how one animated line replaces itself.
	clearLine = "\r\033[2K"
)

// isTerminal reports whether w is a terminal that should be painted. NO_COLOR
// turns colour off everywhere, which is the convention the rest of the CLI
// world follows.
func isTerminal(w io.Writer) bool {
	if os.Getenv("NO_COLOR") != "" || os.Getenv("TERM") == "dumb" {
		return false
	}
	f, ok := w.(*os.File)
	if !ok {
		return false
	}
	info, err := f.Stat()
	if err != nil {
		return false
	}
	return info.Mode()&os.ModeCharDevice != 0
}

// paint wraps s in codes when colour is on, and returns it untouched when off,
// so a caller never has to branch on it.
func paint(on bool, codes string, s string) string {
	if !on || codes == "" {
		return s
	}
	return codes + s + ansiReset
}

// levelColor is the colour each severity is printed in: debug recedes, info is
// neutral, a warning is yellow and an error is red.
func levelColor(l Level) string {
	switch l {
	case DebugLevel:
		return ansiGray
	case InfoLevel:
		return ansiBlue
	case WarnLevel:
		return ansiYellow
	case ErrorLevel:
		return ansiRed
	default:
		return ""
	}
}
