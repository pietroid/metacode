// tr: A localized text in the language shown (Brazilian Portuguese for
// pt_br, English otherwise).
import '../../../../.generated/labels.dart';
import '../../../../.generated/state.dart';

String tr(Localized text, Labels labels) {
  if (labels.locale == 'pt_br') return text.ptBr;
  return text.en;
}
