// Actions react to the UI. Each one receives the current [State] plus, by
// name: `emit` (apply a StateDelta), `core` (api + navigator), `index`
// inside list items and `value` from inputs.

import '../generated/state.dart';

// Jobs and taxes

Future<void> toggleJobPaid(State state, void Function(StateDelta) emit, int index, bool value) async {
  state.jobs[index].paid = value;
  emit(StateDelta(jobs: state.jobs));
}

Future<void> setTaxRate(State state, void Function(StateDelta) emit, double value) async =>
    emit(StateDelta(taxRate: value.round()));
