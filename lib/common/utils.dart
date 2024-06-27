import 'dart:math';
import 'dart:ui';

Offset arcToOffset(double thetaStart, double thetaDelta, double distance) {
  final thetaEnd = thetaStart + thetaDelta;
  if (thetaDelta != 0) {
    final r = distance.abs() / thetaDelta.abs();
    var offset = Offset(
      r * (cos(thetaStart) - cos(thetaEnd)),
      r * (sin(thetaStart) - sin(thetaEnd)),
    );
    return offset;
  } else {
    throw ArgumentError.value(thetaEnd);
  }
}
