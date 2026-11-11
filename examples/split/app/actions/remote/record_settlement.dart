// recordSettlement: Appends the transfer to shared transfers. Refuses amount
// <= 0 or from == to.

import '../../../.generated/remote_state.dart';

Future<void> recordSettlement(State state, void Function(StateDelta) emit, Transfer value) async {
  if (value.amount <= 0) throw RemoteError('amount');
  if (value.from == value.to) throw RemoteError('same');
  final List<Transfer> list = [...state.transfers, value];
  emit(StateDelta(transfers: list));
}
