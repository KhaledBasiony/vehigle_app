import 'dart:math';
import 'dart:ui';

const _maxHistory = 100;

class CarModel {
  CarModel._();
  static CarModel? _instance;
  static CarModel get instance => _instance ??= CarModel._();

  double width = 20;
  double height = 40;
  SensorReadings readings = SensorReadings();
  List<SensorReadings> readingsHistory = List.generate(_maxHistory, (index) {
    return SensorReadings();
  });
}

class SensorReadings {
  SensorReadings({
    this.frontLeft = 0,
    this.frontCenter = 0,
    this.frontRight = 0,
    this.backLeft = 0,
    this.backCenter = 0,
    this.backRight = 0,
  });

  final double frontLeft;
  final double frontRight;
  final double frontCenter;

  final double backLeft;
  final double backRight;
  final double backCenter;

  SensorOffsets toOffsets(Offset center) {
    return SensorOffsets(
      frontLeft: Offset(
        center.dx - CarModel.instance.width / 2 * MapModel.instance.scale - frontLeft / sqrt2 * MapModel.instance.scale,
        center.dy -
            CarModel.instance.height / 2 * MapModel.instance.scale -
            frontLeft / sqrt2 * MapModel.instance.scale,
      ),
      frontCenter: Offset(
        center.dx,
        center.dy - CarModel.instance.height / 2 * MapModel.instance.scale - frontCenter * MapModel.instance.scale,
      ),
      frontRight: Offset(
        center.dx +
            CarModel.instance.width / 2 * MapModel.instance.scale +
            frontRight / sqrt2 * MapModel.instance.scale,
        center.dy -
            CarModel.instance.height / 2 * MapModel.instance.scale -
            frontRight / sqrt2 * MapModel.instance.scale,
      ),
      backLeft: Offset(
        center.dx - CarModel.instance.width / 2 * MapModel.instance.scale - backLeft / sqrt2 * MapModel.instance.scale,
        center.dy + CarModel.instance.height / 2 * MapModel.instance.scale + backLeft / sqrt2 * MapModel.instance.scale,
      ),
      backCenter: Offset(
        center.dx,
        center.dy + CarModel.instance.height / 2 * MapModel.instance.scale + backCenter * MapModel.instance.scale,
      ),
      backRight: Offset(
        center.dx + CarModel.instance.width / 2 * MapModel.instance.scale + backRight / sqrt2 * MapModel.instance.scale,
        center.dy +
            CarModel.instance.height / 2 * MapModel.instance.scale +
            backRight / sqrt2 * MapModel.instance.scale,
      ),
    );
  }
}

class SensorOffsets {
  SensorOffsets({
    this.frontLeft = Offset.zero,
    this.frontCenter = Offset.zero,
    this.frontRight = Offset.zero,
    this.backLeft = Offset.zero,
    this.backCenter = Offset.zero,
    this.backRight = Offset.zero,
  });
  final Offset frontLeft;
  final Offset frontRight;
  final Offset frontCenter;

  final Offset backLeft;
  final Offset backRight;
  final Offset backCenter;

  List<Offset> toList() => [frontLeft, frontCenter, frontRight, backLeft, backCenter, backRight];
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
