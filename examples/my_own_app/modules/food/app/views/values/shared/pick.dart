// pick: The English or Portuguese text of synthetic data, by the shown language.
import '../../../../.generated/labels.dart';

String pick(Labels labels, String en, String pt) =>
    labels.locale.startsWith('pt') ? pt : en;
