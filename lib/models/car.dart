import 'dart:collection';
import 'dart:math';
import 'dart:ui';

class CarModel {
  CarModel._();
  static CarModel? _instance;
  static CarModel get instance => _instance ??= CarModel._();

  static const maxHistory = 50;
  static const maxSensorReading = 100;

  double width = 20;
  double height = 40;
  Queue<SensorOffsets> readingsHistory = Queue();
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
