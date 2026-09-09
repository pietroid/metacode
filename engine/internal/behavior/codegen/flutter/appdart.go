package behaviorflutter

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/pietroid/metacode/engine/internal/codegen/dart"
	"github.com/pietroid/metacode/engine/internal/core/model"
)

// updateAppDart points lib/app.dart at the home page wrapper and provides the
// Cubits the wrappers read. wrappers maps target file to wrapper class name.
func updateAppDart(app *model.App, outDir string, wrappers map[string]string) error {
	if len(wrappers) == 0 {
		return nil
	}

	pageName := dart.FirstPageName(app.UI)
	if pageName == "" {
		return nil
	}

	wrapperFile := fmt.Sprintf("lib/wrappers/%s_wrapper.dart", dart.SnakeCase(pageName))
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
	wrapperImport := fmt.Sprintf("import 'wrappers/%s_wrapper.dart';", dart.SnakeCase(pageName))
	if !strings.Contains(updated, wrapperImport) {
		updated = strings.Replace(updated, "import 'pages/", wrapperImport+"\nimport 'pages/", 1)
	}
	if !strings.Contains(updated, "import 'package:flutter_bloc/flutter_bloc.dart';") {
		updated = strings.Replace(updated, "import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:flutter_bloc/flutter_bloc.dart';", 1)
	}

	// Replace page instantiation with wrapper instantiation.
	updated = replacePageWithWrapper(updated, dart.WidgetClass(pageName), wrapperClass)

	// One store, checked in the resolve stage: see datarules.CheckSupported.
	if len(app.Stores) == 1 {
		store := app.Stores[0]
		base := dart.StoreBaseName(store.Name)
		cubitClass := dart.PascalCase(base) + "Cubit"
		cubitImport := fmt.Sprintf("import 'stores/%s_cubit.dart';", dart.SnakeCase(base))
		if !strings.Contains(updated, cubitImport) {
			updated = strings.Replace(updated, "import 'pages/", cubitImport+"\nimport 'pages/", 1)
		}
		updated = wrapWithBlocProvider(updated, cubitClass)
	}

	// Remove the now-unused page import.
	pageImport := fmt.Sprintf("import 'pages/%s.dart';", dart.SnakeCase(pageName))
	updated = strings.Replace(updated, pageImport+"\n", "", 1)
	updated = strings.Replace(updated, pageImport, "", 1)

	if updated == string(content) {
		return nil
	}
	// This function edits Dart as text, so it can produce a file that is not
	// Dart. Model output is shape-checked before it is kept and this was not,
	// which is how a stray paren reached disk and stayed there.
	if !dart.Balanced(updated) {
		return fmt.Errorf("rewriting app.dart produced unbalanced brackets; left the file as it was")
	}
	return os.WriteFile(appDartPath, []byte(updated), 0644)
}

// replacePageWithWrapper swaps `const HomePage(...)` for the wrapper, finding
// the end of the call by counting parens.
//
// A regex cannot do this. `const HomePage\([^)]*\)` stops at the first close
// paren, so `const HomePage(homeContent: SizedBox())` matched up to SizedBox's
// paren and left the page's behind. The app compiled for as long as no page
// took an argument that was itself a call.
func replacePageWithWrapper(src, pageClass, wrapperClass string) string {
	open := regexp.MustCompile(`const\s+` + regexp.QuoteMeta(pageClass) + `\b\s*\(`)
	for {
		loc := open.FindStringIndex(src)
		if loc == nil {
			return src
		}
		end := findMatchingClose(src[loc[1]:], '(', ')')
		if end == -1 {
			return src
		}
		src = src[:loc[0]] + fmt.Sprintf("const %s()", wrapperClass) + src[loc[1]+end+1:]
	}
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
		cubitClass, dart.IndentBy(inner, 8),
	)

	// tail starts with ");" — replace the leading ");" since wrapped already ends with ";".
	tail = strings.TrimPrefix(tail, ");")
	return before + wrapped + tail
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
