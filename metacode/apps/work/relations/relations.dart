// Relations turn the state into values for the UI.

import '../generated/state.dart';

/// 1234567 -> "1,234,567".
String _groupDigits(num n) {
  final digits = (n < 0 ? 0 - n : n).round().toString();
  var out = n < 0 ? "-" : "";
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out += ',';
    out += digits[i];
  }
  return out;
}

List<Job> jobList(State state) => state.jobs;

String jobClient(State state, int index) => state.jobs[index].client;
String jobTask(State state, int index) => state.jobs[index].task;
String jobAmount(State state, int index) => '\$${_groupDigits(state.jobs[index].amount)}';
bool jobPaid(State state, int index) => state.jobs[index].paid;

num _received(State state) {
  num total = 0;
  for (final j in state.jobs) {
    if (j.paid) total += j.amount;
  }
  return total;
}

num _waiting(State state) {
  num total = 0;
  for (final j in state.jobs) {
    if (!j.paid) total += j.amount;
  }
  return total;
}

String receivedText(State state) => '\$${_groupDigits(_received(state))}';
String waitingText(State state) => '\$${_groupDigits(_waiting(state))}';

double taxRateValue(State state) => state.taxRate.toDouble();

String taxText(State state) {
  final reserve = _received(state) * state.taxRate / 100;
  return 'Set aside ${state.taxRate.round()}% for taxes: \$${_groupDigits(reserve)}';
}

String workTip(State state) {
  Job? biggest;
  for (final j in state.jobs) {
    if (!j.paid && (biggest == null || j.amount > biggest.amount)) biggest = j;
  }
  if (biggest == null) return 'Everyone paid. Nice month.';
  return '${biggest.client} still owes you \$${_groupDigits(biggest.amount)}. Want me to draft a friendly reminder?';
}
