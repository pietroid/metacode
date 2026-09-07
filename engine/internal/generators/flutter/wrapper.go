package flutter

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/llm"
	"github.com/pietroid/metacode/engine/internal/modules/shared"
	"github.com/pietroid/metacode/engine/internal/planner"
)

// GenerateWrappers processes all wrapper tasks and writes the generated Dart
// files to outDir. It updates lib/app.dart to use the home page wrapper and
// provide the required Cubits.
func GenerateWrappers(ctx context.Context, app *ir.IR, tasks []planner.Task, client llm.Client, outDir string) error {
	wrappersDir := filepath.Join(outDir, "lib", "wrappers")
	if err := os.MkdirAll(wrappersDir, 0755); err != nil {
		return fmt.Errorf("create wrappers dir: %w", err)
	}

	generated := make(map[string]string) // target file -> wrapper class name
	for _, task := range tasks {
		if task.Type != planner.TaskWrapper {
			continue
		}
		className, err := generateWrapper(ctx, app, task, client, outDir)
		if err != nil {
			return fmt.Errorf("wrapper %s: %w", task.ID, err)
		}
		if className != "" {
			generated[task.TargetFile] = className
		}
	}

	if len(generated) > 0 {
		if err := updateAppDart(app, outDir, generated); err != nil {
			return fmt.Errorf("update app.dart: %w", err)
		}
	}

	return nil
}

func generateWrapper(ctx context.Context, app *ir.IR, task planner.Task, client llm.Client, outDir string) (string, error) {
	prompt, err := BuildWrapperPrompt(app, PromptTask{ScenarioID: task.ScenarioID}, outDir)
	if err != nil {
		return "", fmt.Errorf("build prompt: %w", err)
	}

	raw, err := client.Complete(ctx, prompt)
	if err != nil {
		return "", fmt.Errorf("llm complete: %w", err)
	}

	code, err := extractDartCode(raw)
	if err != nil {
		return "", fmt.Errorf("extract dart code: %w", err)
	}

	if err := validateDartSyntax(code); err != nil {
		return "", fmt.Errorf("syntax validation: %w", err)
	}

	targetPath := filepath.Join(outDir, task.TargetFile)
	if err := os.MkdirAll(filepath.Dir(targetPath), 0755); err != nil {
		return "", fmt.Errorf("create target dir: %w", err)
	}
	if err := os.WriteFile(targetPath, []byte(code), 0644); err != nil {
		return "", fmt.Errorf("write wrapper file: %w", err)
	}

	className := extractClassName(code)
	if className == "" {
		className = wrapperClassNameForTask(app, task)
	}
	return className, nil
}

func wrapperClassNameForTask(app *ir.IR, task planner.Task) string {
	scenario, err := findScenario(app, task.ScenarioID)
	if err != nil {
		return ""
	}
	widgetName, _, err := widgetAndMemberForTask(scenario, PromptTask{ScenarioID: task.ScenarioID})
	if err != nil {
		return ""
	}
	return wrapperClassName(widgetName)
}

var dartFence = regexp.MustCompile("```(?:dart)?\s*\n(?s)(.*?)\n```")
var classDecl = regexp.MustCompile(`class\s+(\w+)\s+extends\s+StatelessWidget`)

func extractClassName(code string) string {
	m := classDecl.FindStringSubmatch(code)
	if len(m) < 2 {
		return ""
	}
	return m[1]
}

func extractDartCode(raw string) (string, error) {
	matches := dartFence.FindAllStringSubmatch(raw, -1)
	if len(matches) == 0 {
		return "", fmt.Errorf("no dart code fence found")
	}
	return strings.TrimSpace(matches[len(matches)-1][1]), nil
}

func validateDartSyntax(code string) error {
	if !strings.Contains(code, "class ") {
		return fmt.Errorf("generated code missing class declaration")
	}
	if !balancedBraces(code) {
		return fmt.Errorf("generated code has unbalanced braces")
	}
	return nil
}

func balancedBraces(code string) bool {
	depth := 0
	inString := false
	stringChar := rune(0)
	for i, r := range code {
		if inString {
			if r == stringChar {
				inString = false
			} else if r == '\\' && i+1 < len(code) {
				// Skip escaped character.
				_ = code[i+1]
			}
			continue
		}
		if r == '"' || r == '\'' {
			inString = true
			stringChar = r
			continue
		}
		switch r {
		case '{', '(', '[':
			depth++
		case '}', ')', ']':
			depth--
			if depth < 0 {
				return false
			}
		}
	}
	return depth == 0 && !inString
}

func updateAppDart(app *ir.IR, outDir string, wrappers map[string]string) error {
	pageName := shared.FirstPageName(app.UI)
	if pageName == "" {
		return nil
	}

	wrapperFile := fmt.Sprintf("lib/wrappers/%s_wrapper.dart", shared.SnakeCase(pageName))
	wrapperClass, ok := wrappers[wrapperFile]
	if !ok {
		return nil
	}

	appDartPath := filepath.Join(outDir, "lib", "app.dart")
	content, err := os.ReadFile(appDartPath)
	if err != nil {
		return fmt.Errorf("read app.dart: %w", err)
	}

	updated := string(content)

	// Add required imports if missing.
	wrapperImport := fmt.Sprintf("import 'wrappers/%s_wrapper.dart';", shared.SnakeCase(pageName))
	if !strings.Contains(updated, wrapperImport) {
		updated = strings.Replace(updated, "import 'pages/", wrapperImport+"\nimport 'pages/", 1)
	}
	if !strings.Contains(updated, "import 'package:flutter_bloc/flutter_bloc.dart';") {
		updated = strings.Replace(updated, "import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:flutter_bloc/flutter_bloc.dart';", 1)
	}

	// Replace page instantiation with wrapper instantiation.
	pageClass := shared.PascalCase(pageName)
	re := regexp.MustCompile(fmt.Sprintf(`const\s+%s\s*\([^)]*\)`, pageClass))
	updated = re.ReplaceAllString(updated, fmt.Sprintf("const %s()", wrapperClass))

	// Wrap MaterialApp with BlocProvider for each store.
	if len(app.Stores) == 1 {
		store := app.Stores[0]
		base := shared.StoreBaseName(store.Name)
		cubitClass := shared.PascalCase(base) + "Cubit"
		cubitImport := fmt.Sprintf("import 'stores/%s_cubit.dart';", shared.SnakeCase(base))
		if !strings.Contains(updated, cubitImport) {
			updated = strings.Replace(updated, "import 'pages/", cubitImport+"\nimport 'pages/", 1)
		}
		updated = wrapWithBlocProvider(updated, cubitClass)
	}

	if updated == string(content) {
		return nil
	}
	return os.WriteFile(appDartPath, []byte(updated), 0644)
}

func wrapWithBlocProvider(appDart, cubitClass string) string {
	// Avoid double-wrapping.
	if strings.Contains(appDart, "BlocProvider") {
		return appDart
	}

	prefix := "return MaterialApp("
	idx := strings.Index(appDart, prefix)
	if idx == -1 {
		return appDart
	}

	before := appDart[:idx]
	after := appDart[idx+len(prefix):]

	// Find the closing paren of the MaterialApp call.
	closeIdx := findMatchingClose(after, '(', ')')
	if closeIdx == -1 {
		return appDart
	}

	// Insert BlocProvider open before MaterialApp and close after MaterialApp.
	inner := after[:closeIdx]
	tail := after[closeIdx:]

	wrapped := fmt.Sprintf(
		"return BlocProvider(\n      create: (_) => %s(),\n      child: MaterialApp(\n%s\n      ),\n    );",
		cubitClass, indent(inner, 8),
	)

	// tail starts with ");" — replace the leading ");" since wrapped already ends with ";".
	tail = strings.TrimPrefix(tail, ");")
	return before + wrapped + tail
}

func indent(s string, spaces int) string {
	pad := strings.Repeat(" ", spaces)
	lines := strings.Split(s, "\n")
	for i, line := range lines {
		if line != "" {
			lines[i] = pad + line
		}
	}
	return strings.Join(lines, "\n")
}

func findMatchingClose(s string, open, close rune) int {
	depth := 1
	inString := false
	var stringChar rune
	for i, r := range s {
		if inString {
			if r == stringChar {
				inString = false
			} else if r == '\\' && i+1 < len(s) {
				_ = s[i+1]
			}
			continue
		}
		if r == '"' || r == '\'' {
			inString = true
			stringChar = r
			continue
		}
		if r == open {
			depth++
		} else if r == close {
			depth--
			if depth == 0 {
				return i
			}
		}
	}
	return -1
}
