# Counter App

This is a minimal Metacode example that generates a working Flutter counter application.

## Structure

```
counter_app/
├── metacode/
│   ├── project.yaml
│   ├── data.yaml
│   ├── ui.yaml
│   └── behaviors.yaml
├── pubspec.yaml
└── README.md
```

## Run

From the example directory:

```bash
cd examples/counter_app
go run ../../engine/cmd/metacode run
```

This discovers the Metacode specs, generates the Flutter project under `lib/` and `test/`, runs `flutter test`, and fixes failures automatically when an LLM is configured.

## Verify

After a successful run:

```bash
flutter test
```

All generated tests should pass.
