// [ms] as minutes, one decimal (`1.5 min`), for the run and history stats.
import '../../../../.generated/labels.dart';

String formatMinutes(num ms, Labels labels) {
  final minutes = ms / 60000;
  return '${minutes.toStringAsFixed(1)} ${labels.minutesText}';
}
