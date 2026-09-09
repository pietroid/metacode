package llm

import "fmt"

// Usage is what one request cost, in tokens. Cache fields are reported by
// providers that support prompt caching and stay zero elsewhere.
type Usage struct {
	InputTokens      int64
	OutputTokens     int64
	CacheReadTokens  int64
	CacheWriteTokens int64
}

// Total is every token the request touched, which is the number to watch when
// one run makes a handful of very large calls.
func (u Usage) Total() int64 {
	return u.InputTokens + u.OutputTokens + u.CacheReadTokens + u.CacheWriteTokens
}

// Add accumulates another call's usage into u.
func (u *Usage) Add(other Usage) {
	u.InputTokens += other.InputTokens
	u.OutputTokens += other.OutputTokens
	u.CacheReadTokens += other.CacheReadTokens
	u.CacheWriteTokens += other.CacheWriteTokens
}

// String renders usage for a log line: the two numbers that always exist, the
// cache numbers only when a provider reported them.
func (u Usage) String() string {
	s := fmt.Sprintf("%s in / %s out", humanCount(u.InputTokens), humanCount(u.OutputTokens))
	if u.CacheReadTokens > 0 || u.CacheWriteTokens > 0 {
		s += fmt.Sprintf(" / %s cache read / %s cache write",
			humanCount(u.CacheReadTokens), humanCount(u.CacheWriteTokens))
	}
	return s + fmt.Sprintf(" / %s total", humanCount(u.Total()))
}

// humanCount keeps large token counts readable without hiding small ones.
func humanCount(n int64) string {
	if n < 1000 {
		return fmt.Sprintf("%d", n)
	}
	return fmt.Sprintf("%.1fk", float64(n)/1000)
}

// Result is one completed request: the text the model returned and what it
// cost.
type Result struct {
	Text  string
	Usage Usage
}
