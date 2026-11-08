// imagePath: A Forkcast illustration's path from its key (`bowl` -> forkcast_bowl.svg).
import 'package:flutter_test/flutter_test.dart';

String imagePath(String key) =>
    'examples/my_own_app/app/views/style/images/forkcast_$key.svg';

void main() {
  test('imagePath', () {
    expect(imagePath('bowl'), endsWith('/forkcast_bowl.svg'));
  });
}
