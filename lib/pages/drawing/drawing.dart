import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapDrawer extends ConsumerStatefulWidget {
  const MapDrawer({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MapDrawerState();
}

class _MapDrawerState extends ConsumerState<MapDrawer> {
  @override
  Widget build(BuildContext context) {
    CustomPaint(
      painter: MyPainter(),
      size: Size.infinite,
    );
    return const Center(
      child: Text('Unimplemented'),
    );
  }
}

class MyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    canvas.drawCircle(Offset(200, 200), 20, paint);
    return;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
