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

// updateAppDart points lib/app.dart at the widgets the wrappers wrap and
// provides the Cubits they read. wrappers maps target file to wrapper class
// name.
//
// A routed app needs only the second half: the router already names every
// wrapper, and it is generated from navigation.yaml rather than patched here.
// What both shapes need is the provider, and it goes above the MaterialApp so
// that a route pushed onto the Navigator — a page, a sheet, a dialog — is
// still below it and reads the same store its opener was reading.
func updateAppDart(app *model.App, outDir string, wrappers map[string]string) error {
	if len(wrappers) == 0 && !app.Navigation.Declared() {
		return nil
	}

	appDartPath := filepath.Join(outDir, "lib", "app.dart")
	content, err := os.ReadFile(appDartPath)
	if err != nil {
		return fmt.Errorf("read app.dart: %w", err)
	}

	updated := string(content)
	if app.Navigation.Declared() {
		updated = provideStores(app, updated, "import 'navigation/router.dart';")
	} else {
		updated, err = pointAtPageWrapper(app, updated, wrappers)
		if err != nil {
			return err
		}
	}

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

// pointAtPageWrapper is the shape an app with no routes has: one page, reached
// directly, wrapped in place by its own wrapper.
func pointAtPageWrapper(app *model.App, updated string, wrappers map[string]string) (string, error) {
	pageName := dart.FirstPageName(app.UI)
	if pageName == "" {
		return updated, nil
	}

	wrapperFile := fmt.Sprintf("lib/wrappers/%s_wrapper.dart", dart.SnakeCase(pageName))
	wrapperClass, ok := wrappers[wrapperFile]
	if !ok {
		return updated, nil
	}

	pageImport := fmt.Sprintf("import 'pages/%s.dart';", dart.SnakeCase(pageName))
	wrapperImport := fmt.Sprintf("import 'wrappers/%s_wrapper.dart';", dart.SnakeCase(pageName))
	if !strings.Contains(updated, wrapperImport) {
		updated = strings.Replace(updated, "import 'pages/", wrapperImport+"\nimport 'pages/", 1)
	}

	updated = replacePageWithWrapper(updated, dart.WidgetClass(pageName), wrapperClass)
	updated = provideStores(app, updated, pageImport)

	// Remove the now-unused page import.
	updated = strings.Replace(updated, pageImport+"\n", "", 1)
	return strings.Replace(updated, pageImport, "", 1), nil
}

// provideStores wraps the MaterialApp in the Cubit every wrapper reads.
// anchor is an import line the new ones are inserted before, so the file keeps
// one import block whatever shape it has.
func provideStores(app *model.App, updated, anchor string) string {
	// One store, checked in the resolve stage: see datarules.CheckSupported.
	if len(app.Stores) != 1 {
		return updated
	}
	if !strings.Contains(updated, "import 'package:flutter_bloc/flutter_bloc.dart';") {
		updated = strings.Replace(updated, "import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:flutter_bloc/flutter_bloc.dart';", 1)
	}

	store := app.Stores[0]
	base := dart.StoreBaseName(store.Name)
	cubitImport := fmt.Sprintf("import 'stores/%s_cubit.dart';", dart.SnakeCase(base))
	if !strings.Contains(updated, cubitImport) {
		updated = strings.Replace(updated, anchor, cubitImport+"\n"+anchor, 1)
	}
	return wrapWithBlocProvider(updated, dart.PascalCase(base)+"Cubit")
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

	// Both shapes are matched: an app with routes returns MaterialApp.router,
	// an app without one returns MaterialApp, and the provider goes outside
	// either.
	idx := strings.Index(appDart, "return MaterialApp")
	if idx == -1 {
		return appDart
	}
	open := strings.Index(appDart[idx:], "(")
	if open == -1 {
		return appDart
	}
	constructor := appDart[idx+len("return ") : idx+open]

	before := appDart[:idx]
	after := appDart[idx+open+1:]

	// Find the closing paren of the MaterialApp call.
	closeIdx := findMatchingClose(after, '(', ')')
	if closeIdx == -1 {
		return appDart
	}

	// Insert BlocProvider open before MaterialApp and close after MaterialApp.
	inner := after[:closeIdx]
	tail := after[closeIdx:]

	wrapped := fmt.Sprintf(
		"return BlocProvider(\n      create: (_) => %s(),\n      child: %s(\n%s\n      ),\n    );",
		cubitClass, constructor, dart.IndentBy(inner, 8),
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
