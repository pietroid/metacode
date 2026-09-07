package report

import (
	"fmt"
	"strings"

	"metacode/internal/spec"
)

func PrintHeader() {
	fmt.Println("╔══════════════════════════════════════╗")
	fmt.Println("║           Metacode v0.1.0            ║")
	fmt.Println("╚══════════════════════════════════════╝")
	fmt.Println()
}

func PrintSpecSummary(set *spec.SpecSet) {
	fmt.Printf("Loaded specs:\n")
	fmt.Printf("  • Data stores: %d\n", len(set.DataStores))
	for name := range set.DataStores {
		fmt.Printf("    - %s\n", name)
	}
	fmt.Printf("  • UI widgets : %d\n", len(set.UIWidgets))
	for name := range set.UIWidgets {
		fmt.Printf("    - %s\n", name)
	}
	fmt.Printf("  • Tests      : %d\n", len(set.Tests))
	fmt.Println()
}

func PrintStage(name string) {
	fmt.Printf("▶ %s\n", name)
}

func PrintSubStage(name string) {
	fmt.Printf("  → %s\n", name)
}

func PrintSuccess(msg string) {
	fmt.Printf("  ✓ %s\n", msg)
}

func PrintError(stage string, err error) {
	fmt.Printf("  ✗ %s: %v\n", stage, err)
}

func PrintTestOutput(output []byte, err error) {
	fmt.Println()
	fmt.Println("─── Flutter test output ───")
	fmt.Println(strings.TrimSpace(string(output)))
	fmt.Println("───────────────────────────")
	if err != nil {
		fmt.Println("  ✗ Flutter tests failed")
	} else {
		fmt.Println("  ✓ All Flutter tests passed")
	}
}
