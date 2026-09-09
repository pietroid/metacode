package model

// Store represents a single piece of mutable application state.
type Store struct {
	Name         string
	ValueType    string
	InitialValue any
	Strategy     string // "ephemeral" for MVP; local/remote deferred
}
