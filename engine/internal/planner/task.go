// Package planner analyzes a resolved IR and produces deterministic
// generation tasks for the AI wrapper layer and tests.
package planner

// TaskType classifies a generation task.
type TaskType string

const (
	TaskWrapper TaskType = "wrapper"
	TaskTest    TaskType = "test"
	TaskFix     TaskType = "fix"
	// TaskStore is a store action whose body is business logic. The generator
	// scaffolds the signature; the fix loop fills the body from the scenarios.
	TaskStore TaskType = "store"
)

// Task is a single unit of work produced by the planner.
type Task struct {
	ID              string
	Type            TaskType
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

// IsFix reports whether the task is a fix task.
func (t Task) IsFix() bool { return t.Type == TaskFix }

// IsStore reports whether the task is a store action task.
func (t Task) IsStore() bool { return t.Type == TaskStore }
