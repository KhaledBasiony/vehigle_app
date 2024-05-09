import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_car_sim/models/car.dart';

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
      CarModel.instance.readingsHistory = [
        SensorReadings(
          frontLeft: rng.nextDouble() * 100,
          frontCenter: rng.nextDouble() * 100,
          frontRight: rng.nextDouble() * 100,
          backLeft: rng.nextDouble() * 100,
          backCenter: rng.nextDouble() * 100,
          backRight: rng.nextDouble() * 100,
        ),
        ...CarModel.instance.readingsHistory.take(CarModel.instance.readingsHistory.length - 1),
      ];
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapCanvas = CustomPaint(
      painter: CarPainter(),
      foregroundPainter: MapPainter(),
      size: Size.infinite,
    );
    const edgeInsets = EdgeInsets.all(16.0);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      margin: edgeInsets,
      padding: edgeInsets,
      child: mapCanvas,
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
    for (int i = 0; i < CarModel.instance.readingsHistory.length; i++) {
      final reading = CarModel.instance.readingsHistory[i];
      paint.color = baseColor.withAlpha(255 - (i / CarModel.instance.readingsHistory.length * 255).round());

      // Iterate over UltraSonic values in a single reading element.
      for (var readingLocation in reading.toOffsets(MapModel.instance.center).toList()) {
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
