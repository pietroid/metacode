package run

// Failure describes a single failing test.
type Failure struct {
	File    string
	Name    string
	Message string
}

// TestResult is the structured output of running the Flutter test suite.
type TestResult struct {
	Success  bool
	Output   string
	Failures []Failure
}
