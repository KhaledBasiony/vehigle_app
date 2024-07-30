import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_car_sim/common/provider.dart';
import 'package:mobile_car_sim/common/shortcuts/actions.dart';
import 'package:mobile_car_sim/common/theme.dart';

class DrDriverControls extends ConsumerStatefulWidget {
  const DrDriverControls({super.key});

  @override
  ConsumerState<DrDriverControls> createState() => _DrDriverControlsState();
}

class _DrDriverControlsState extends ConsumerState<DrDriverControls> {
  static const _padding = 20.0;
  static const _wheelSize = 150.0;
  static const _wheelCenter = Offset(_wheelSize / 2 + _padding, _wheelSize / 2 + _padding);

  Offset _startOffset = Offset.zero;
  int _overlaps = 0;

  void _startDragging(DragStartDetails details) {
    _startOffset = details.localPosition - _wheelCenter;
  }

  void _updateAngle(DragUpdateDetails details) {
    final currentOffset = details.localPosition - _wheelCenter;
    final steeringWheelAngle = -(_startOffset.direction - currentOffset.direction) * 180 / pi + _overlaps * 360;

    final oldSteeringWheelAngle = ref.read(_steeringWheelAngleProvider);

    final int newOverlap;
    if (oldSteeringWheelAngle - steeringWheelAngle > 300) {
      _overlaps++;
      newOverlap = 1;
    } else if (steeringWheelAngle - oldSteeringWheelAngle > 300) {
      _overlaps--;
      newOverlap = -1;
    } else {
      newOverlap = 0;
    }

    final newSteeringWheelAngle = boundedValue(
      value: steeringWheelAngle + newOverlap * 360,
      lowerBound: -360 * 5 / 3,
      upperBound: 360 * 5 / 3,
    );

    ref.read(_steeringWheelAngleProvider.notifier).state = newSteeringWheelAngle;

    final newCarWheelsAngle = _steeringWheelToCarWheels(newSteeringWheelAngle);
    ref.read(wheelAngleProvider.notifier).state = newCarWheelsAngle;

    Actions.invoke(
      context,
      newSteeringWheelAngle > oldSteeringWheelAngle
          ? TurnLeftIntent(value: newCarWheelsAngle)
          : TurnRightIntent(value: newCarWheelsAngle),
    );
  }

  @override
  Widget build(BuildContext context) {
    const wheel = _SteeringWheel(side: _wheelSize);

    return Row(
      children: [
        GestureDetector(
          onPanStart: _startDragging,
          onPanUpdate: _updateAngle,
          child: Padding(
            padding: const EdgeInsets.all(_padding),
            child: AnimatedRotation(
              turns: _carWheelsToSteeringWheelTurns(ref.watch(wheelAngleProvider)),
              duration: Durations.short3,
              child: wheel,
            ),
          ),
        ),
        Text(ref.watch(_steeringWheelAngleProvider).toStringAsFixed(0)),
      ],
    );
  }
}

class _SteeringWheel extends StatelessWidget {
  const _SteeringWheel({
    this.side = 150,
  });

  final double side;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'images/steering_wheel.png',
      height: side,
      color: AppTheme.instance.theme.colorScheme.primary,
    );
  }
}

final _steeringWheelAngleProvider = StateProvider<double>((ref) => 0);

int _steeringWheelToCarWheels(double steeringWheelAngle) => (steeringWheelAngle / (360 * 5 / 3) * 40).round();
double _carWheelsToSteeringWheelTurns(int carWheelsAnlge) => carWheelsAnlge / 40 * 5 / 3;
int _turnsToCarWheels(double turns) => (turns * 40 * 3 / 5).round();

double boundedValue({
  required double value,
  double lowerBound = double.negativeInfinity,
  double upperBound = double.infinity,
}) =>
    value < lowerBound
        ? lowerBound
        : value > upperBound
            ? upperBound
            : value;
