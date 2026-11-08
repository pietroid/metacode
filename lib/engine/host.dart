// The two functions the interpreted program uses to reach the engine.
//
// User code never calls these directly: `.generated/core.dart` wraps them in
// `Core` (api, navigator) and `.generated/main.dart` uses [hostEmit] for the
// `emit` callback of actions. Inside dart_eval they are bridged by
// `host_plugin.dart`; these bodies only exist so the analyzer can type-check
// metacode/ and never run.

/// Runs a host operation (`api`, `navigator.push`, `navigator.pop`) with
/// JSON [args] and completes with its JSON result.
Future<String> hostCall(String op, String args) =>
    throw UnsupportedError('hostCall only runs inside the Metacode engine');

/// Applies a JSON-encoded `StateDelta` to the engine state.
void hostEmit(String delta) =>
    throw UnsupportedError('hostEmit only runs inside the Metacode engine');
