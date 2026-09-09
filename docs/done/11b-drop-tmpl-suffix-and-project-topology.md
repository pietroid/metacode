# 23 — Mirror Real Project Topology (`.tmpl` kept)

## Goal

Reorganize the project template so it mirrors an actual Flutter project layout, while keeping the `.tmpl` suffix so IDEs/editors do not lint the template files as real Dart/YAML. The generator should be file-agnostic: it walks the template tree and renders everything, so adding/removing files in the template does not require generator code changes.

## Scope

1. **Keep the `.tmpl` suffix** on all template files so editors ignore them.
   - `widget.dart.tmpl`
   - `state.dart.tmpl`
   - `cubit.dart.tmpl`
   - `pubspec.yaml.tmpl`
   - `main.dart.tmpl`
   - `app.dart.tmpl`

2. **Reorganize the project module template** to mirror a real Flutter project:
   ```
   engine/internal/modules/project/code_generation/flutter/templates/
   ├── pubspec.yaml.tmpl
   └── lib/
       ├── main.dart.tmpl
       └── app.dart.tmpl
   ```

3. **Make the project generator generic.**
   - Walk the embedded template filesystem recursively.
   - For each directory, create the same directory under `outDir`.
   - For each file, parse it as a template and render it to the matching output path using a single project data struct.
   - Strip `.tmpl` from the output path.
   - The generator must not hard-code filenames like `pubspec.yaml`, `main.dart`, or `app.dart`.

4. **Keep data and UI templates flat** for now (they render one file per store/widget).

5. **Update tests** to reference the new template names only if necessary; test assertions remain focused on generated output.

## Acceptance criteria

1. All template files keep the `.tmpl` suffix.
2. The project template directory structure mirrors the generated project structure.
3. `go test ./...` passes in `engine/`.
4. `metacode run` in `examples/counter_app` produces the same generated files as before.
5. `flutter analyze` in `examples/counter_app` reports no issues.
6. Adding a new static file (e.g. `analysis_options.yaml.tmpl`) to the project template requires no generator code changes.

## Files to create/modify

```
engine/internal/modules/project/codegen/flutter/
├── project.go                       # generic tree walker, strips .tmpl on output
└── templates/
    ├── pubspec.yaml.tmpl
    └── lib/
        ├── main.dart.tmpl
        └── app.dart.tmpl

engine/internal/modules/data/codegen/flutter/
└── templates/
    ├── state.dart.tmpl
    └── cubit.dart.tmpl

engine/internal/modules/ui/codegen/flutter/
└── templates/
    └── widget.dart.tmpl
```

## Layering notes

- Using `embed` + `fs.WalkDir` keeps the generator decoupled from the exact file list.
- Template names are their relative paths, so `ExecuteTemplate` can target them directly.
- A single data struct is passed to every template; each template uses only the fields it needs.
- This pattern makes it trivial to add new languages later: create a new `code_generation/<lang>/templates/` tree and a thin generator wrapper.
