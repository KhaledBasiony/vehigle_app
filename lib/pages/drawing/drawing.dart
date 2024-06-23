import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_car_sim/common/provider.dart';
import 'package:mobile_car_sim/models/car.dart';

class MapCanvas extends StatelessWidget {
  const MapCanvas({super.key});

  @override
  Widget build(BuildContext context) {
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
        return Center(
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
  void _transfromMap(num dist, num angle) {
    print('$dist, $angle');
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
          (sensorReadings) => sensorReadings.translate(0, dist.toDouble()),
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
    ref.listen(messagesProvider, (_, next) {
      final prevReadings = jsonDecode(
        next.elementAtOrNull(max(next.length - 2, 0))?.text ?? '{}',
      ) as Map<String, dynamic>?;
      final readings = jsonDecode(next.last.text) as Map<String, dynamic>;
      CarModel.instance.readingsHistory.addFirst(
        SensorOffsets.fromReadings(
          frontLeft: readings['LF'] * CarModel.maxSensorReading,
          frontCenter: readings['CF'] * CarModel.maxSensorReading,
          frontRight: readings['RF'] * CarModel.maxSensorReading,
          backLeft: readings['LB'] * CarModel.maxSensorReading,
          backCenter: readings['CB'] * CarModel.maxSensorReading,
          backRight: readings['RB'] * CarModel.maxSensorReading,
          right: readings['RC'] * CarModel.maxSensorReading,
          left: readings['LC'] * CarModel.maxSensorReading,
        ),
      );

      if (CarModel.instance.readingsHistory.length > CarModel.maxHistory) {
        CarModel.instance.readingsHistory.removeLast();
      }

      final encoderReading = readings['ENC'] as num;
      final compassReading = readings['CMPS'] as num;
      final prevEncoderReading = prevReadings?['ENC'] as num?;
      final prevCompassReading = prevReadings?['CMPS'] as num?;

      final encoderDiff = encoderReading - (prevEncoderReading ?? 0);
      final angleDiff = (compassReading - (prevCompassReading ?? 0)) * pi / 180;
      _transfromMap(encoderDiff, angleDiff);

      setState(() {});
    });
    return CustomPaint(
      painter: CarPainter(),
      foregroundPainter: MapPainter(),
      size: Size.infinite,
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

class MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    const baseColor = Colors.white70;
    paint.color = baseColor;

    // Iterate over history elements.

    for (final element in CarModel.instance.readingsHistory.indexed) {
      final i = element.$1;
      final reading = element.$2;
      paint.color = baseColor.withAlpha(255 - (i / CarModel.instance.readingsHistory.length * 255).round());

      // Iterate over UltraSonic values in a single reading element.
      for (var readingLocation in reading
          .translate(
            MapModel.instance.center.dx,
            MapModel.instance.center.dy,
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
    return true;
  }
}
