import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_car_sim/models/car.dart';

class MapCanvas extends StatelessWidget {
  const MapCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    const edgeInsets = EdgeInsets.all(16.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSide = min(constraints.maxHeight, constraints.maxWidth);
        MapModel.instance.scale = canvasSide / (CarModel.maxSensorReading * 2 + CarModel.instance.width);
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
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              margin: edgeInsets,
              padding: edgeInsets,
              child: const MapDrawer(),
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
  late Random rng;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    rng = Random(DateTime.now().millisecondsSinceEpoch);
    _timer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      CarModel.instance.readingsHistory.addFirst(
        SensorOffsets.fromReadings(
          frontLeft: rng.nextDouble() * CarModel.maxSensorReading,
          frontCenter: rng.nextDouble() * CarModel.maxSensorReading,
          frontRight: rng.nextDouble() * CarModel.maxSensorReading,
          backLeft: rng.nextDouble() * CarModel.maxSensorReading,
          backCenter: rng.nextDouble() * CarModel.maxSensorReading,
          backRight: rng.nextDouble() * CarModel.maxSensorReading,
          right: rng.nextDouble() * CarModel.maxSensorReading,
          left: rng.nextDouble() * CarModel.maxSensorReading,
        ),
      );

      if (CarModel.instance.readingsHistory.length > CarModel.maxHistory) {
        CarModel.instance.readingsHistory.removeLast();
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _moveForward(int dist) {
    CarModel.instance.readingsHistory = Queue.of(
      CarModel.instance.readingsHistory.map(
        (e) => e.translate(0, dist.toDouble()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
    return;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
