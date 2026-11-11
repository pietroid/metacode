// pickColor: Gives the draft's buttons the palette color at `index`:
// rewrites the palette color in its CountButton file, so the running draft
// reloads in place, its count kept (and the remote draft syncs).
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';
import 'shared/draft_button.dart';
import 'shared/file_in.dart';
import 'shared/palette.dart';
import 'shared/with_file.dart';

Future<void> pickColor(
    State state, void Function(StateDelta) emit, int index) async {
  final color = palette()[index];
  final file = fileIn(state.draft, draftButton());
  if (file == null) return;
  var edited = file;
  for (final c in palette()) {
    edited = edited.replaceAll(c, color);
  }
  if (edited == file) return;
  emit(StateDelta(draft: withFile(state.draft, draftButton(), edited)));
}

void main() {
  test('pickColor recolors the draft buttons', () async {
    final state = await app.pickColor(sample(), 1);
    final file = fileIn(state.draft, draftButton())!;
    expect(file, contains("color: '#2F6FED'"));
    expect(file, isNot(contains('#111111')));
    expect(app.isPicked(state, 1), isTrue);
    expect(app.isPicked(state, 0), isFalse);
  });
}
