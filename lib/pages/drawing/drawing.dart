import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_car_sim/common/provider.dart';
import 'package:mobile_car_sim/common/theme.dart';
import 'package:mobile_car_sim/common/widgets.dart';
import 'package:mobile_car_sim/models/car.dart';

class MapCanvas extends ConsumerWidget {
  const MapCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const edgeInsets = EdgeInsets.all(16.0);
    const borderWidth = 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSide = min(constraints.maxHeight, constraints.maxWidth);

        // this will be used as both a padding and a margin
        final sidePadding = canvasSide == constraints.maxHeight
            ? edgeInsets.bottom + edgeInsets.top
            : edgeInsets.left + edgeInsets.right;

        final netCanvasSide = canvasSide - 2 * sidePadding - 2 * borderWidth;
        MapModel.instance.scale = netCanvasSide / (CarModel.maxSensorReading * 2 + CarModel.instance.height);

        final borderRadius = BorderRadius.circular(20);
        return Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: canvasSide,
                  maxWidth: canvasSide,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: borderWidth,
                    ),
                    borderRadius: borderRadius,
                  ),
                  margin: edgeInsets,
                  padding: edgeInsets,
                  child: ClipRRect(
                    borderRadius: borderRadius,
                    child: const MapDrawer(),
                  ),
                ),
              ),
            ),
            _RefresherButtons(callback: () => ref.read(_nextFrameCounter.notifier).state += 1),
          ],
        );
      },
    );
  }
}

class MapDrawer extends ConsumerStatefulWidget {
  const MapDrawer({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MapDrawerState();
}

class _MapDrawerState extends ConsumerState<MapDrawer> {
  Offset? carLocation;
  double? yaw;

  void _transfromMap(double dist, double angle) {
    if (angle < -pi || angle > pi) {
      print('Warning! angle must be from -Pi to Pi, received $angle, ignoring');
    }
    if (dist == 0) {
      return;
    }
    if (angle == 0) {
      // only move car linearly front or backwards.
      CarModel.instance.readingsHistory = Queue.of(
        CarModel.instance.readingsHistory.map(
          (sensorReadings) => sensorReadings.translate(0, dist.toDouble() * MapModel.instance.scale),
        ),
      );
    } else {
      // car is moving on an arc.

      final radius = dist / angle;
      final rotationCenter = Offset(
        radius * MapModel.instance.scale,
        CarModel.instance.centerToAxle * MapModel.instance.scale,
      );

      CarModel.instance.latestRotationCenter = rotationCenter;
      CarModel.instance.readingsHistory = Queue.of(
        CarModel.instance.readingsHistory.map(
          (sensorReadings) => sensorReadings.rotateAbout(rotationCenter, angle),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(_nextFrameCounter, (previous, next) {
      if (next != previous) {
        setState(() {});
      }
    });
    ref.listen(messagesProvider, (_, next) {
      final prevReadings = jsonDecode(
        next.elementAtOrNull(max(next.length - 2, 0))?.text ?? '{}',
      ) as Map<String, dynamic>?;
      final readings = jsonDecode(next.last.text) as Map<String, dynamic>;

      if (CarModel.instance.readingsHistory.length > CarModel.maxHistory) {
        CarModel.instance.readingsHistory.removeLast();
      }

      final newX = (readings['dX'] as num).toDouble();
      final newY = (readings['dY'] as num).toDouble();
      final encoderReading = (readings['ENC'] as num).toDouble();
      final compassReading = (readings['CMPS'] as num).toDouble();
      final prevEncoderReading = (prevReadings?['ENC'] as num?)?.toDouble();
      final prevCompassReading = (prevReadings?['CMPS'] as num?)?.toDouble();

      final encoderDiff = encoderReading - (prevEncoderReading ?? 0);
      final angleDiff = (compassReading - (prevCompassReading ?? 0)) * pi / 180;

      if (ref.read(carStatesProvider) == CarStates.searching) {
        CarModel.instance.readingsHistory.addFirst(
          SensorOffsets.fromReadings(
            frontLeft: (readings['LF'] as num).toDouble() * CarModel.maxSensorReading,
            frontCenter: (readings['CF'] as num).toDouble() * CarModel.maxSensorReading,
            frontRight: (readings['RF'] as num).toDouble() * CarModel.maxSensorReading,
            backLeft: (readings['LB'] as num).toDouble() * CarModel.maxSensorReading,
            backCenter: (readings['CB'] as num).toDouble() * CarModel.maxSensorReading,
            backRight: (readings['RB'] as num).toDouble() * CarModel.maxSensorReading,
            right: (readings['RC'] as num).toDouble() * CarModel.maxSensorReading,
            left: (readings['LC'] as num).toDouble() * CarModel.maxSensorReading,
          ),
        );
        carLocation = null;
        yaw = null;
        _transfromMap(encoderDiff.toDouble(), angleDiff);
      } else if (angleDiff == 0) {
        final newOffset = Offset(newX, -newY);
        carLocation = (carLocation ?? Offset.zero) + newOffset;
        yaw = compassReading * pi / 180;
      } else {
        carLocation = (carLocation ?? Offset.zero) + Offset(newX, -newY);

        yaw = compassReading * pi / 180;
      }

      if (ref.read(_autoRefreshProvider)) {
        setState(() {});
      }
    });

    final searchingPaint = CustomPaint(
      key: const ValueKey('Searching-Paint'),
      painter: CarPainter(),
      foregroundPainter: MapPainter(),
      size: Size.infinite,
    );

    final initCarCenter = MapModel.instance.center.translate(
      0,
      -MapModel.instance.center.dy / 2,
    );

    final parkingPaint = CustomPaint(
      key: const ValueKey('Parking-Paint'),
      painter: MapPainter(
        myShouldRepaint: false,
        centerOffset: Offset(0, -MapModel.instance.center.dy / 2),
      ),
      foregroundPainter: ParkingPainter(
        initCarCenter: initCarCenter,
        enteranceAngle: 65 * pi / 180,
        finalPoint: Offset(
          CarModel.instance.width * 2.25 * MapModel.instance.scale,
          CarModel.instance.height * 1.5 * MapModel.instance.scale,
        ),
        finalRadius: CarModel.instance.minRotationRadius * MapModel.instance.scale,
        carLocation: carLocation ?? Offset.zero,
        yaw: yaw ?? 0.0,
      ),
      size: Size.infinite,
    );

    return AnimatedSwitcher(
      duration: Durations.long4,
      child: ref.read(carStatesProvider) == CarStates.searching ? searchingPaint : parkingPaint,
    );
  }
}

class CarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = MapModel.instance.scale;
    MapModel.instance.size = size;

    final paint = Paint();
    paint.color = Colors.lightBlue;
    canvas.drawRect(
      Rect.fromCenter(
        center: MapModel.instance.center,
        width: CarModel.instance.width * scale,
        height: CarModel.instance.height * scale,
      ),
      paint,
    );
    return;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class ParkingPainter extends CustomPainter {
  const ParkingPainter({
    required this.initCarCenter,
    required this.finalPoint,
    required this.finalRadius,
    required this.enteranceAngle,
    required this.carLocation,
    required this.yaw,
  });

  final Offset initCarCenter;
  final Offset finalPoint;
  final double finalRadius;

  /// in radians.
  final double enteranceAngle;

  final Offset carLocation;
  final double yaw;

  void _paintPath(Canvas canvas) {
    final paint = Paint();
    paint.strokeWidth = 3;
    paint.style = PaintingStyle.stroke;

    canvas.save();
    canvas.translate(initCarCenter.dx, initCarCenter.dy + CarModel.instance.centerToAxle * MapModel.instance.scale);
    final pTan2 = Offset(
      finalPoint.dx - finalRadius + finalRadius * cos(enteranceAngle),
      finalPoint.dy - finalRadius * sin(enteranceAngle),
    );

    final c = pTan2.dx / tan(enteranceAngle) - pTan2.dy;
    final initRadius = -c * (sin(enteranceAngle) + 1 / tan(enteranceAngle) + cos(enteranceAngle) / tan(enteranceAngle));

    final xTan1 = -c * sin(enteranceAngle);
    final yTan1 = sqrt(pow(initRadius, 2) - pow(xTan1 - initRadius, 2));

    paint.color = Colors.red;
    canvas.drawCircle(finalPoint, 2 * MapModel.instance.scale, paint);
    canvas.drawCircle(Offset.zero, 2 * MapModel.instance.scale, paint);

    paint.color = Colors.amber;
    final initCenter = Offset(initRadius, 0);
    canvas.drawCircle(
      initCenter,
      MapModel.instance.scale,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: initCenter,
        radius: initRadius,
      ),
      pi,
      -acos(1 - xTan1 / initRadius),
      false,
      paint,
    );

    paint.color = Colors.deepPurple;
    canvas.drawLine(Offset(xTan1, yTan1), pTan2, paint);

    paint.color = Colors.lightBlue;
    final finalCenter = finalPoint.translate(-finalRadius, 0);
    canvas.drawCircle(
      finalCenter,
      MapModel.instance.scale,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: finalCenter,
        radius: finalRadius,
      ),
      -enteranceAngle,
      enteranceAngle,
      false,
      paint,
    );
    canvas.restore();
  }

  void _drawCar(Canvas canvas, double scale, [Paint? paint]) {
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: CarModel.instance.width * scale,
        height: CarModel.instance.height * scale,
      ),
      paint ?? Paint()
        ..color = AppTheme.instance.primaryColor,
    );
  }

  void _drawDirectionCenter(Canvas canvas, double scale, [Paint? paint]) {
    canvas.drawVertices(
      Vertices(
        VertexMode.triangles,
        [
          const Offset(0, 20),
          const Offset(5, 0),
          const Offset(-5, 0),
        ],
      ),
      BlendMode.dst,
      paint ?? Paint()
        ..color = Colors.amber,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = MapModel.instance.scale;
    MapModel.instance.size = size;

    final paint = Paint();
    paint.color = Colors.lightBlue;

    canvas.save();

    canvas.translate(initCarCenter.dx, initCarCenter.dy);
    canvas.translate(carLocation.dx * scale, carLocation.dy * scale);
    canvas.rotate(yaw);

    _drawCar(canvas, scale, paint);
    _drawDirectionCenter(canvas, scale);

    canvas.restore();
    _paintPath(canvas);
    return;
  }

  @override
  bool shouldRepaint(covariant ParkingPainter oldDelegate) {
    return oldDelegate.carLocation != carLocation || oldDelegate.yaw != yaw;
  }
}

class MapPainter extends CustomPainter {
  MapPainter({
    this.centerOffset = Offset.zero,
    this.myShouldRepaint = true,
  });

  Offset centerOffset;
  final bool myShouldRepaint;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    final baseColor = AppTheme.instance.theme.colorScheme.onBackground;
    paint.color = baseColor;

    // Iterate over history elements.

    for (final element in CarModel.instance.readingsHistory.indexed) {
      final i = element.$1;
      final reading = element.$2;
      paint.color = baseColor.withAlpha(255 - (i / CarModel.instance.readingsHistory.length * 255).round());

      // Iterate over UltraSonic values in a single reading element.
      for (var readingLocation in reading
          .translate(
            MapModel.instance.center.dx + centerOffset.dx,
            MapModel.instance.center.dy + centerOffset.dy,
          )
          .toList()) {
        canvas.drawCircle(
          readingLocation,
          2 * MapModel.instance.scale,
          paint,
        );
      }
    }
    paint.color = Colors.amber;
    canvas.drawCircle(
      CarModel.instance.latestRotationCenter.translate(
        MapModel.instance.center.dx,
        MapModel.instance.center.dy,
      ),
      2 * MapModel.instance.scale,
      paint,
    );
    return;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return myShouldRepaint;
  }
}

class _RefresherButtons extends ConsumerWidget {
  const _RefresherButtons({
    required this.callback,
  });

  final VoidCallback callback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        HoldDownButton(callback: callback, child: const Icon(Icons.navigate_next_rounded)),
        Switch(
          value: ref.watch(_autoRefreshProvider),
          onChanged: (value) => ref.read(_autoRefreshProvider.notifier).state = value,
        ),
      ],
    );
  }
}

final _autoRefreshProvider = StateProvider<bool>((ref) => true);

// the counter is just to indicate change
final _nextFrameCounter = StateProvider<int>((ref) => 0);
