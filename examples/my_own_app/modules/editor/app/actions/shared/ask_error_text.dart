/// What to show when a remote call to the Claude bridge failed with [code]:
/// `bridgeDown` (the bridge isn't running), `offline` (the backend can't be
/// reached or the call broke on the way back), or any other refusal.
String askErrorText(String code) {
  if (code == 'bridgeDown') {
    return 'The Claude bridge is not running: tool/claude_bridge.sh';
  }
  if (code == 'offline') return 'Lost the backend during the call (offline).';
  return 'The call failed ($code).';
}
