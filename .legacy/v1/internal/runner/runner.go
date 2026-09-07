package runner

import (
	"crypto/sha256"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	"metacode/internal/generator/dart"
	"metacode/internal/graph"
	"metacode/internal/report"
	"metacode/internal/spec"
)

// Run executes the full Metacode pipeline.
func Run(specDir, outputDir string) error {
	report.PrintHeader()

	// Stage 1: Parse specs.
	report.PrintStage("Parsing specs")
	set, err := spec.LoadSpecs(specDir)
	if err != nil {
		report.PrintError("parse specs", err)
		return err
	}
	report.PrintSpecSummary(set)

	// Stage 2: Build graph.
	report.PrintStage("Resolving symbol graph")
	g, err := graph.Build(set)
	if err != nil {
		report.PrintError("build graph", err)
		return err
	}
	report.PrintSuccess("graph resolved")

	// Stage 3: Generate code.
	report.PrintStage("Generating Flutter project")
	report.PrintSubStage(fmt.Sprintf("output: %s", outputDir))
	if err := dart.Generate(g, outputDir); err != nil {
		report.PrintError("generate code", err)
		return err
	}
	report.PrintSuccess("Dart files generated")

	// Stage 4: Format generated code.
	report.PrintStage("Formatting generated code")
	if err := runCommand(outputDir, "dart", "format", "."); err != nil {
		report.PrintError("dart format", err)
		// formatting failure is not fatal, keep going.
	} else {
		report.PrintSuccess("code formatted")
	}

	// Stage 5: Run tests.
	report.PrintStage("Running generated tests")
	out, err := execCommand(outputDir, "flutter", "test")
	report.PrintTestOutput(out, err)
	if err != nil {
		return fmt.Errorf("flutter tests failed")
	}

	// Stage 6: Update lockfile.
	report.PrintStage("Updating lockfile")
	if err := updateLockfile(specDir); err != nil {
		report.PrintError("lockfile", err)
		return err
	}
	report.PrintSuccess("lockfile updated")

	return nil
}

func runCommand(dir string, name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Dir = dir
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func execCommand(dir string, name string, args ...string) ([]byte, error) {
	cmd := exec.Command(name, args...)
	cmd.Dir = dir
	return cmd.CombinedOutput()
}

func updateLockfile(specDir string) error {
	lockPath := filepath.Join(specDir, ".lock")
	h := sha256.New()
	entries, err := os.ReadDir(specDir)
	if err != nil {
		return err
	}
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		name := entry.Name()
		if name == ".lock" {
			continue
		}
		if filepath.Ext(name) != ".yaml" && filepath.Ext(name) != ".yml" {
			continue
		}
		data, err := os.ReadFile(filepath.Join(specDir, name))
		if err != nil {
			return err
		}
		h.Write(data)
	}
	content := fmt.Sprintf("# Metacode lockfile (placeholder for incremental generation)\nlastRun: %s\nspecHash: %x\n", time.Now().UTC().Format(time.RFC3339), h.Sum(nil))
	return os.WriteFile(lockPath, []byte(content), 0644)
}
