// Package actioncatalog is the vocabulary of actions a behavior can verify.
//
// It is the third closed table this engine ships, beside the widget catalog
// and the icons, and it is read the same way: a subject, the verbs it answers
// to, and what each verb maps to in the target language. A `then` naming a
// subject that is not here, or a verb the subject does not declare, is an
// error rather than something plausible.
//
// The table is data on purpose. Every future native — playing a sound, sending
// a notification — is a row rather than a branch, and the actions.yaml that
// declares a project's own actions builds rows of the same shape. A switch on
// the subject name here would have to be rewritten by the second one.
package actioncatalog

import "sort"

// ArgType is what a verb's argument holds. The words are the spec's, so a
// target language decides separately what they compile to.
type ArgType string

// The argument types a verb can take.
const (
	// ArgNone is a verb that takes nothing: `navigator should pop`.
	ArgNone ArgType = ""
	// ArgRoute is a name from navigation.yaml, checked at the resolve stage
	// the same way an icon name is checked against the icon vocabulary.
	ArgRoute ArgType = "route"
	// ArgText is a literal string the spec writes.
	ArgText ArgType = "text"
)

// Verb is one thing a subject can be asked to do.
type Verb struct {
	Name string
	Arg  ArgType
}

// Subject is a thing a behavior can address in a `then`, with the verbs it
// answers to.
type Subject struct {
	Name  string
	Verbs []Verb
	// Native says the engine ships this subject and knows how to call and
	// verify it. A subject declared by a project is not native, and the
	// generated code for it comes from its own declaration.
	Native bool
}

// Verb returns the named verb of a subject.
func (s Subject) Verb(name string) (Verb, bool) {
	for _, v := range s.Verbs {
		if v.Name == name {
			return v, true
		}
	}
	return Verb{}, false
}

// VerbNames lists a subject's verbs, for an error message that says what could
// have been written instead.
func (s Subject) VerbNames() []string {
	out := make([]string, 0, len(s.Verbs))
	for _, v := range s.Verbs {
		out = append(out, v.Name)
	}
	sort.Strings(out)
	return out
}

// Catalog is the set of subjects a project can address.
type Catalog struct {
	subjects map[string]Subject
}

// New builds a catalog from a list of subjects.
func New(subjects []Subject) *Catalog {
	c := &Catalog{subjects: make(map[string]Subject, len(subjects))}
	for _, s := range subjects {
		c.subjects[s.Name] = s
	}
	return c
}

// Find returns the named subject.
func (c *Catalog) Find(name string) (Subject, bool) {
	s, ok := c.subjects[name]
	return s, ok
}

// IsKnown reports whether a name is a subject this catalog declares.
func (c *Catalog) IsKnown(name string) bool {
	_, ok := c.subjects[name]
	return ok
}

// Names lists every subject, sorted, so output that mentions them is stable.
func (c *Catalog) Names() []string {
	out := make([]string, 0, len(c.subjects))
	for name := range c.subjects {
		out = append(out, name)
	}
	sort.Strings(out)
	return out
}
