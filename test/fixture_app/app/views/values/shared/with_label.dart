// withLabel: A label and a number, joined: the fixture's shared helper (one
// public function per file in shared/, any signature), called by countText.
String withLabel(String label, num n) => [label, n.toString()].join(' ');
