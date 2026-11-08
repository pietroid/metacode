// Picks the project's files for this platform:
//   desktop: the folder in `METACODE_PROJECT_DIR` (watched), else none
//            (the app runs the bundled bundle.json)
//   web:     localStorage, seeded with the project's default files
//            (`.generated/files.json`, written by the tool)
export 'open_none.dart'
    if (dart.library.io) 'open_io.dart'
    if (dart.library.js_interop) 'open_web.dart';
