// openMusicLive: Opens the music example on its own page (the musicLive route).
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> openMusicLive(State state, Core core) async {
  core.navigator.push(Routes.musicLive);
}

void main() {
  test('openMusicLive pushes the music page', () async {
    await app.openMusicLive(sample());
    expect(app.navigation, ['push musicLive']);
  });
}
