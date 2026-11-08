// playChat: Plays the example chat in stages (chatStage): 0 hides the card
// and clears its text, 1 fades it in and types the question, 2 types the
// answer. The typing itself is drawn by the animated promptReveal and
// replyReveal; this only steps the stages.
import '../../../.generated/state.dart';

Future<void> playChat(void Function(StateDelta) emit) async {
  emit(StateDelta(chatStage: 0));
  await Future.delayed(const Duration(milliseconds: 250));
  emit(StateDelta(chatStage: 1));
  await Future.delayed(const Duration(milliseconds: 1500));
  emit(StateDelta(chatStage: 2));
}
