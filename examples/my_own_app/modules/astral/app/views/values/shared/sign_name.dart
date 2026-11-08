// signName: A sign's name (0 Aries to 11 Pisces; any number wraps around).
import '../../../../.generated/labels.dart';

String signName(int sign, Labels labels) {
  final names = [
    labels.aries, labels.taurus, labels.gemini, labels.cancer,
    labels.leo, labels.virgo, labels.libra, labels.scorpio,
    labels.sagittarius, labels.capricorn, labels.aquarius, labels.pisces,
  ];
  return names[sign % 12];
}
