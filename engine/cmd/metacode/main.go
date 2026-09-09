package main

import (
	"os"

	"github.com/pietroid/metacode/engine/internal/behavior/codegen/flutter"
	"github.com/pietroid/metacode/engine/internal/codegen/flutter"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/core/plan"
	"github.com/pietroid/metacode/engine/internal/core/run"
	"github.com/pietroid/metacode/engine/internal/llm"
	"github.com/pietroid/metacode/engine/internal/log"
)

// main assembles the target and hands it to the pipeline. This is the one place
// that names a language: everything below it works from run.Target.
func main() {
	flutterTarget := run.Target{
		Name:     "flutter",
		Scaffold: flutter.GenerateAll,
		Wrappers: flutter.GenerateWrappers,
		Tests:    flutter.GenerateTests,
		Prune:    flutter.PruneStaleOutput,
		NewImplementer: func(client llm.Client, logger log.Logger, app *model.App, work plan.Work, outDir string) run.Implementer {
			return behaviorflutter.New(client, logger, app, work, outDir)
		},
		TestCommand: []string{"flutter", "test"},
	}

	if err := run.Execute(flutterTarget); err != nil {
		os.Exit(1)
	}
}
