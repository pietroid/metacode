package plan

import "sort"

// Stale is the part of a run's work that a model still has to write.
//
// It names stores and widgets, not files, for the same reason Work does:
// where a generated file lands is answered once, in codegen/dart's layout
// rules, and a second answer here would be a second place a rename has to be
// made.
//
// Everything not named here is frozen. A frozen file is still shown to the
// model, as context it reads and must not change, so the app it is writing
// against is the whole app rather than the slice that changed.
type Stale struct {
	// All says every owned file may be rewritten: there is no lock to compare
	// against, the instructions the last run used have changed, or the diff
	// could not be computed.
	All bool
	// Stores names the stores whose Cubit bodies may be rewritten.
	Stores []string
	// Wrappers names the widgets whose wrappers may be rewritten.
	Wrappers []string
	// Reasons is why, in the words the run log prints.
	Reasons []string
}

// Everything is the stale set of a run with nothing to compare against.
func Everything(reason string) Stale {
	return Stale{All: true, Reasons: []string{reason}}
}

// Empty reports that no owned file needs a model. The one request of a run is
// skipped entirely when this is true, which is the whole point of the lock.
func (s Stale) Empty() bool {
	return !s.All && len(s.Stores) == 0 && len(s.Wrappers) == 0
}

// HasStore reports whether this store's Cubit may be rewritten.
func (s Stale) HasStore(name string) bool { return s.All || contains(s.Stores, name) }

// HasWrapper reports whether this widget's wrapper may be rewritten.
func (s Stale) HasWrapper(widget string) bool { return s.All || contains(s.Wrappers, widget) }

// AddStore marks a store stale, once.
func (s *Stale) AddStore(name string) { s.Stores = insert(s.Stores, name) }

// AddWrapper marks a wrapper stale, once.
func (s *Stale) AddWrapper(widget string) { s.Wrappers = insert(s.Wrappers, widget) }

// AddReason records why something was marked, for the run log.
func (s *Stale) AddReason(reason string) { s.Reasons = insert(s.Reasons, reason) }

func contains(list []string, want string) bool {
	for _, item := range list {
		if item == want {
			return true
		}
	}
	return false
}

// insert keeps the slice sorted and free of repeats, so the same change
// reached by two routes is named once and a run's log reads the same twice.
func insert(list []string, item string) []string {
	if contains(list, item) {
		return list
	}
	list = append(list, item)
	sort.Strings(list)
	return list
}
