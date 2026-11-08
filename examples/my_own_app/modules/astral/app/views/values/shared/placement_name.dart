// placementName: The sign a placement sits in, counted [offset] signs on
// from the sun sign.
import '../../../../.generated/labels.dart';
import '../../../../.generated/state.dart';
import 'sign_name.dart';
import 'sun_sign.dart';

String placementName(State state, num offset, Labels labels) =>
    signName(sunSign(state) + offset.round(), labels);
