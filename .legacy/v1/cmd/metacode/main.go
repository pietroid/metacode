package main

import (
	"fmt"
	"os"

	"metacode/internal/runner"
)

func main() {
	if len(os.Args) < 2 {
		printUsage()
		os.Exit(1)
	}

	switch os.Args[1] {
	case "run":
		specDir := "metacode"
		outputDir := "counter_example"
		if err := runner.Run(specDir, outputDir); err != nil {
			os.Exit(1)
		}
	case "help", "--help", "-h":
		printUsage()
	default:
		fmt.Fprintf(os.Stderr, "unknown command: %s\n", os.Args[1])
		printUsage()
		os.Exit(1)
	}
}

func printUsage() {
	fmt.Println("Usage: metacode <command>")
	fmt.Println()
	fmt.Println("Commands:")
	fmt.Println("  run    Parse specs from ./metacode and generate code into ./counter_example")
	fmt.Println("  help   Show this help message")
}
