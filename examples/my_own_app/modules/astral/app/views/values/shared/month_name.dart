// monthName: A month's name, 1 January to 12 December.
import '../../../../.generated/labels.dart';

String monthName(int month, Labels labels) {
  final names = [
    labels.january, labels.february, labels.march, labels.april,
    labels.may, labels.june, labels.july, labels.august,
    labels.september, labels.october, labels.november, labels.december,
  ];
  return names[month - 1];
}
