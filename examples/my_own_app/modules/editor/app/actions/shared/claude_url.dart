/// The Claude bridge (tool/claude_server.dart) at [path]: `claude` (one
/// POST edits the draft) or `starter` (the starter draft, for resetDraft).
String claudeUrl(String path) => 'http://localhost:8787/$path';
