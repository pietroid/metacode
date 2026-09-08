// Package planner analyzes a resolved IR and produces deterministic
// generation tasks for the AI wrapper layer and tests.
package planner

// TaskType classifies a generation task.
type TaskType string

const (
	TaskWrapper TaskType = "wrapper"
	TaskTest    TaskType = "test"
)

// Task is a single unit of work produced by the planner.
type Task struct {
	ID   string
	Type TaskType
	// Widget is the widget a wrapper task wraps. Empty for other task types.
	// It is carried rather than parsed back out of the task ID, which is a
	// slug and cannot be turned back into a symbol name.
	Widget          string
	TargetFile      string
	ScenarioID      string
	Description     string
	PromptContext   string
	ExpectedOutcome string
}

// IsWrapper reports whether the task is a wrapper generation task.
func (t Task) IsWrapper() bool { return t.Type == TaskWrapper }

// IsTest reports whether the task is a test generation task.
func (t Task) IsTest() bool { return t.Type == TaskTest }
