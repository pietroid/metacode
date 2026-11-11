/// The Claude bridge (tool/claude_server.dart) at [path]: `claude` (one
/// POST edits the draft), `project?name=food` (an example app's source, for
/// loadProject and resetDraft) or `starter` (the starter counter).
String claudeUrl(String path) => 'http://localhost:8787/$path';
