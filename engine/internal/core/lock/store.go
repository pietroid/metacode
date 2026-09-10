// Package lock remembers the specs a run last understood, and works out what
// changed since.
//
// It exists so a second run does not pay for the first one again. The engine's
// deterministic stages are free and always run in full, so the only thing a
// diff is allowed to decide is how much of the one LLM request has to be
// re-asked. See docs/proposals/lock-and-diff.md.
//
// The lock holds the spec files and nothing derived from them. Storing the
// resolved model instead would pin the serialized shape of model.App, and that
// type changes whenever a spec kind or a field does, which turns every
// refactor into a migration. The specs are the source of truth and everything
// downstream is a pure function of them, so copies of them are a complete
// record of the input, and they read as a diff in a pull request.
package lock

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"

	"github.com/pietroid/metacode/engine/internal/core/spec"
)

// DirName is the lock directory, inside the metacode folder and committed
// alongside the specs so a teammate's first run after a pull is incremental
// too.
const DirName = ".lock"

// tmpDirName is where a write lands before it is renamed into place, so an
// interrupted run cannot leave a lock that is half of two states.
const tmpDirName = ".lock.tmp"

// stampFile records the one thing worth versioning. Stages 1 to 9 rerun in
// full on every run, so a generator change needs no invalidation at all; what
// invalidates a preserved implementation is a change to the instructions the
// model was working under.
const stampFile = "engine.json"

// Stamp is the lock's metadata. There is deliberately no field for whether the
// suite passed: the result of a run is observed on the next one rather than
// remembered, and a lock written after a red suite costs nothing because the
// repair loop unfreezes everything anyway.
type Stamp struct {
	RulesHash string `json:"rules_hash"`
}

// ErrNoLock reports that a project has never been run, or that its lock was
// deleted to force a full regeneration.
var ErrNoLock = errors.New("no lock")

// Locked is what a previous run recorded.
type Locked struct {
	Specs spec.RawSpecs
	Stamp Stamp
}

// specFiles is every file the lock copies: the name it takes inside the lock,
// and the field of spec.Paths that both sources it and receives it on the way
// back. models.yaml is optional in a project and so is optional here.
var specFiles = []struct {
	name string
	// field returns a pointer into a spec.Paths, so one table serves both the
	// copy out and the read back. Two tables drifted the first time a spec
	// kind was added to only one of them.
	field func(*spec.Paths) *string
}{
	{"project.yaml", func(p *spec.Paths) *string { return &p.Project }},
	{"data.yaml", func(p *spec.Paths) *string { return &p.Data }},
	{"ui.yaml", func(p *spec.Paths) *string { return &p.UI }},
	{"behaviors.yaml", func(p *spec.Paths) *string { return &p.Behaviors }},
	{"models.yaml", func(p *spec.Paths) *string { return &p.Models }},
	{"navigation.yaml", func(p *spec.Paths) *string { return &p.Navigation }},
}

// Dir is where the lock lives for a project.
func Dir(paths spec.Paths) string { return filepath.Join(paths.Metacode, DirName) }

// Read returns what the last run recorded, or ErrNoLock.
//
// The specs come back raw. Turning them into a model is the diff's job, and it
// is done with the current engine's rules so that both sides of a comparison
// were built the same way.
func Read(paths spec.Paths) (Locked, error) {
	dir := Dir(paths)
	if _, err := os.Stat(dir); err != nil {
		return Locked{}, ErrNoLock
	}

	lockedPaths := spec.Paths{Root: paths.Root, Metacode: dir}
	for _, f := range specFiles {
		path := filepath.Join(dir, f.name)
		if _, err := os.Stat(path); err == nil {
			*f.field(&lockedPaths) = path
		}
	}
	if !complete(lockedPaths) {
		return Locked{}, ErrNoLock
	}

	specs, err := spec.Parse(lockedPaths)
	if err != nil {
		return Locked{}, fmt.Errorf("parse locked specs: %w", err)
	}

	raw, err := os.ReadFile(filepath.Join(dir, stampFile))
	if err != nil {
		return Locked{}, ErrNoLock
	}
	var stamp Stamp
	if err := json.Unmarshal(raw, &stamp); err != nil {
		return Locked{}, fmt.Errorf("parse %s: %w", stampFile, err)
	}
	return Locked{Specs: specs, Stamp: stamp}, nil
}

// complete reports whether a lock holds every required spec. A partial lock is
// treated as no lock, because half a previous state is not one to diff against.
func complete(p spec.Paths) bool {
	return p.Project != "" && p.Data != "" && p.UI != "" && p.Behaviors != ""
}

// Write records the current specs as the ones this run understood.
//
// It is called by a run that got as far as running the suite, whether the
// suite passed or not. What must not write a lock is a run that never
// understood its input, because the next run would then diff against something
// that was never a coherent state.
//
// The write goes to a temporary directory and is renamed over the old one, so
// an interrupted run leaves the previous lock intact rather than a mixture.
func Write(paths spec.Paths, stamp Stamp) error {
	tmp := filepath.Join(paths.Metacode, tmpDirName)
	if err := os.RemoveAll(tmp); err != nil {
		return fmt.Errorf("clear %s: %w", tmpDirName, err)
	}
	if err := os.MkdirAll(tmp, 0755); err != nil {
		return fmt.Errorf("create %s: %w", tmpDirName, err)
	}

	for _, f := range specFiles {
		src := *f.field(&paths)
		if src == "" {
			continue
		}
		content, err := os.ReadFile(src)
		if err != nil {
			return fmt.Errorf("read %s: %w", src, err)
		}
		if err := os.WriteFile(filepath.Join(tmp, f.name), content, 0644); err != nil {
			return fmt.Errorf("write %s: %w", f.name, err)
		}
	}

	encoded, err := json.MarshalIndent(stamp, "", "  ")
	if err != nil {
		return fmt.Errorf("encode %s: %w", stampFile, err)
	}
	if err := os.WriteFile(filepath.Join(tmp, stampFile), append(encoded, '\n'), 0644); err != nil {
		return fmt.Errorf("write %s: %w", stampFile, err)
	}

	final := Dir(paths)
	if err := os.RemoveAll(final); err != nil {
		return fmt.Errorf("clear %s: %w", DirName, err)
	}
	if err := os.Rename(tmp, final); err != nil {
		return fmt.Errorf("install %s: %w", DirName, err)
	}
	return nil
}

// HashRules is the stamp of one engine's instructions. Only the prompt rules
// go into it: everything else a run does is deterministic and rerun in full,
// so nothing else can leave preserved code answering to a question that is no
// longer being asked.
func HashRules(rules string) string {
	sum := sha256.Sum256([]byte(rules))
	return hex.EncodeToString(sum[:])
}
