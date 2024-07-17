import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import 'package:mobile_car_sim/common/db.dart';

class CarModel {
  CarModel._();
  static CarModel? _instance;
  static CarModel get instance => _instance ??= CarModel._();

  static const maxHistory = 50;
  static get maxReading => Db.instance.read<double>(maxSensorsReading) ?? 200;

  final double width = 20;
  final double height = 40;
  final double centerToAxle = 14.44;
  final double maxSteeringAngle = 40;
  double get axleToAxle => centerToAxle * 2;
  double get minRotationRadius => axleToAxle / tan(maxSteeringAngle * pi / 180);
  Queue<SensorOffsets> readingsHistory = Queue();
  Offset latestRotationCenter = Offset.zero;
}

class SensorOffsets {
  SensorOffsets({
    this.frontRight = Offset.zero,
    this.frontCenter = Offset.zero,
    this.frontLeft = Offset.zero,
    this.backRight = Offset.zero,
    this.backCenter = Offset.zero,
    this.backLeft = Offset.zero,
    this.right = Offset.zero,
    this.left = Offset.zero,
  });

  factory SensorOffsets.fromReadings({
    required double frontRight,
    required double frontCenter,
    required double frontLeft,
    required double backRight,
    required double backCenter,
    required double backLeft,
    required double right,
    required double left,
  }) {
    return SensorOffsets(
      frontRight: Offset(
        (CarModel.instance.width / 2 + frontRight / sqrt2) * MapModel.instance.scale,
        (-CarModel.instance.height / 2 - frontRight / sqrt2) * MapModel.instance.scale,
      ),
      frontCenter: Offset(
        0,
        (-CarModel.instance.height / 2 - frontCenter) * MapModel.instance.scale,
      ),
      frontLeft: Offset(
        (-CarModel.instance.width / 2 - frontLeft / sqrt2) * MapModel.instance.scale,
        (-CarModel.instance.height / 2 - frontLeft / sqrt2) * MapModel.instance.scale,
      ),
      backRight: Offset(
        (CarModel.instance.width / 2 + backRight / sqrt2) * MapModel.instance.scale,
        (CarModel.instance.height / 2 + backRight / sqrt2) * MapModel.instance.scale,
      ),
      backCenter: Offset(
        0,
        (CarModel.instance.height / 2 + backCenter) * MapModel.instance.scale,
      ),
      backLeft: Offset(
        (-CarModel.instance.width / 2 - backLeft / sqrt2) * MapModel.instance.scale,
        (CarModel.instance.height / 2 + backLeft / sqrt2) * MapModel.instance.scale,
      ),
      right: Offset(
        (CarModel.instance.width / 2 + right) * MapModel.instance.scale,
        0,
      ),
      left: Offset(
        (-CarModel.instance.width / 2 - left) * MapModel.instance.scale,
        0,
      ),
    );
  }

  SensorOffsets translate(double translateX, double translateY) => SensorOffsets(
        frontRight: frontRight.translate(translateX, translateY),
        frontCenter: frontCenter.translate(translateX, translateY),
        frontLeft: frontLeft.translate(translateX, translateY),
        backRight: backRight.translate(translateX, translateY),
        backCenter: backCenter.translate(translateX, translateY),
        backLeft: backLeft.translate(translateX, translateY),
        right: right.translate(translateX, translateY),
        left: left.translate(translateX, translateY),
      );

  /// Rotate all sensor readings about a certain rotation center.
  ///
  /// the [rotationCenter] should be relative to the center of current readings.
  ///
  /// the [angle] should be in radians from -pi to pi, measured clockwise
  /// from current reading to next reading.
  SensorOffsets rotateAbout(Offset rotationCenter, num angle) => SensorOffsets(
        frontRight: frontRight.rotateAbout(rotationCenter, angle),
        frontCenter: frontCenter.rotateAbout(rotationCenter, angle),
        frontLeft: frontLeft.rotateAbout(rotationCenter, angle),
        backRight: backRight.rotateAbout(rotationCenter, angle),
        backCenter: backCenter.rotateAbout(rotationCenter, angle),
        backLeft: backLeft.rotateAbout(rotationCenter, angle),
        right: right.rotateAbout(rotationCenter, angle),
        left: left.rotateAbout(rotationCenter, angle),
      );

  final Offset frontRight;
  final Offset frontCenter;
  final Offset frontLeft;

  final Offset backRight;
  final Offset backCenter;
  final Offset backLeft;

  final Offset right;
  final Offset left;

  List<Offset> toList() => [frontRight, frontCenter, frontLeft, backRight, backCenter, backLeft, right, left];
}

class MapModel {
  MapModel._();
  static MapModel? _instance;
  static MapModel get instance => _instance ??= MapModel._();

  double scale = 2;

  Size _size = Size.zero;

  set size(Size newSize) => _size = newSize;

  Offset get center => Offset(_size.width / 2, _size.height / 2);
}

extension on Offset {
  Offset rotateAbout(Offset center, num alpha) {
    final pBar = this - center;
    // alpha should be positive, but
    // it is negative because when these offsets are plotted
    // they are plotted on axes where the positive y direction is downwards not upwards
    final tBar = Offset.fromDirection(pBar.direction - alpha, pBar.distance);
    return tBar + center;
  }
}
