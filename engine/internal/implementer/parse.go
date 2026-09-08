package implementer

import (
	"fmt"
	"regexp"
	"strings"
)

// FileBlock is one file the model returned.
type FileBlock struct {
	Path string
	Code string
}

var fence = regexp.MustCompile("(?s)```(?:dart)?[ \t]*\n(.*?)\n?```")
var fileHeader = regexp.MustCompile(`^//\s*FILE:\s*(\S+)\s*$`)

// ParseFileBlocks reads the multi-file reply format: a series of Dart code
// fences, each opening with a `// FILE: <path>` line.
//
// A reply with fences but no headers is an error rather than a guess. The
// engine writes what comes back, and writing a store implementation over a
// wrapper because the path was inferred from position is worse than failing.
func ParseFileBlocks(raw string) ([]FileBlock, error) {
	matches := fence.FindAllStringSubmatch(raw, -1)
	if len(matches) == 0 {
		return nil, fmt.Errorf("no dart code fence found in the reply")
	}

	var blocks []FileBlock
	for _, m := range matches {
		body := m[1]
		path, code, ok := splitHeader(body)
		if !ok {
			continue
		}
		blocks = append(blocks, FileBlock{Path: path, Code: strings.TrimSpace(code)})
	}

	if len(blocks) == 0 {
		return nil, fmt.Errorf("the reply has %d code fence(s) but none opens with a \"// FILE: <path>\" line", len(matches))
	}
	return blocks, nil
}

// splitHeader pulls the FILE header off the top of a block, skipping blank
// lines before it.
func splitHeader(body string) (string, string, bool) {
	lines := strings.Split(body, "\n")
	for i, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed == "" {
			continue
		}
		m := fileHeader.FindStringSubmatch(trimmed)
		if m == nil {
			return "", "", false
		}
		return m[1], strings.Join(lines[i+1:], "\n"), true
	}
	return "", "", false
}
