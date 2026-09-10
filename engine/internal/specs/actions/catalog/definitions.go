package actioncatalog

// The native subjects. This is the authoritative list: docs/language/actions.md
// is the readable version of it.
//
// navigator is the only one so far, and it is the cheapest one there is: a
// route push is verified with a NavigatorObserver, which Flutter already
// ships, so nothing in lib/ needs a seam for it. The second native will not be
// so lucky — playing a sound or sending a notification has nothing to observe,
// so it arrives with a generated port and a recording fake for the tests.
var natives = []Subject{
	{
		Name:   "navigator",
		Native: true,
		Verbs: []Verb{
			{Name: "push", Arg: ArgRoute},
			{Name: "pop", Arg: ArgNone},
		},
	},
}

// The verbs of the navigator, named where the generators can reach them
// without matching strings of their own.
const (
	SubjectNavigator = "navigator"
	VerbPush         = "push"
	VerbPop          = "pop"
)

// Default is the catalog a run uses: the natives, and nothing else until a
// project can declare its own.
func Default() *Catalog { return New(natives) }
