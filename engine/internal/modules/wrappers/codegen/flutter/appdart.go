package flutter

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/modules/shared"
)

// updateAppDart points lib/app.dart at the home page wrapper and provides the
// Cubits the wrappers read. wrappers maps target file to wrapper class name.
func updateAppDart(app *ir.IR, outDir string, wrappers map[string]string) error {
	if len(wrappers) == 0 {
		return nil
	}

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

	// Remove the now-unused page import.
	pageImport := fmt.Sprintf("import 'pages/%s.dart';", shared.SnakeCase(pageName))
	updated = strings.Replace(updated, pageImport+"\n", "", 1)
	updated = strings.Replace(updated, pageImport, "", 1)

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
