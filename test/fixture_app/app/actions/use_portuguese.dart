// usePortuguese: Shows every app in Portuguese.
import '../../.generated/core.dart';
import '../../.generated/state.dart';

Future<void> usePortuguese(State state, Core core) async {
  await core.locale.set('pt_br');
}
