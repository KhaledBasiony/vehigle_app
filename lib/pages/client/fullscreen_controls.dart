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
    print(_overlaps);
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

  void _resetAngle(_) {
    ref.read(wheelAngleProvider.notifier).state = 0;
    _overlaps = 0;
    Actions.invoke(
      context,
      const TurnRightIntent(value: 0),
    );
  }

  void _pressAcceleration() {
    final intent = switch (ref.read(_gearPositionProvider)) {
      _GearPositions.drive => const MoveForwardIntent(),
      _GearPositions.reverse => const MoveBackwardsIntent(),
    };
    Actions.maybeInvoke(context, intent);
  }

  void _releaseAcceleration() {}

  void _pressBrakes() {
    Actions.maybeInvoke(context, const StopIntent());
  }

  void _releaseBrakes() {}

  @override
  Widget build(BuildContext context) {
    const wheel = _SteeringWheel(side: _wheelSize);

    final pedals = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(_padding),
          child: _Pedal(
            asset: 'images/brakes_pedal.png',
            height: _wheelSize,
            onPress: _pressBrakes,
            onRelease: _releaseBrakes,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(_padding),
          child: _Pedal(
            asset: 'images/accelerator_pedal.png',
            height: _wheelSize,
            onPress: _pressAcceleration,
            onRelease: _releaseAcceleration,
          ),
        ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _TransmissionGear(),
            GestureDetector(
              onPanStart: _startDragging,
              onPanUpdate: _updateAngle,
              onPanEnd: _resetAngle,
              child: Padding(
                padding: const EdgeInsets.all(_padding),
                child: AnimatedRotation(
                  turns: _carWheelsToSteeringWheelTurns(ref.watch(wheelAngleProvider)),
                  duration: Durations.short3,
                  child: wheel,
                ),
              ),
            ),
          ],
        ),
        pedals,
      ],
    );
  }
}

class _Pedal extends StatefulWidget {
  const _Pedal({
    required this.asset,
    required this.onPress,
    required this.onRelease,
    this.height = 150,
  });

  final double height;
  final String asset;

  final VoidCallback onPress;
  final VoidCallback onRelease;

  @override
  State<_Pedal> createState() => _PedalState();
}

class _PedalState extends State<_Pedal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Durations.short3,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _press([_]) {
    _controller.forward();
    widget.onPress();
  }

  void _release([_]) {
    _controller.reverse();
    widget.onRelease();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _press,
      onTapUp: _release,
      onTapCancel: _release,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform(
          transform: Matrix4.rotationX(30 * _controller.value * pi / 180),
          child: child,
        ),
        child: Image.asset(
          widget.asset,
          height: widget.height,
          color: AppTheme.instance.theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _TransmissionGear extends ConsumerWidget {
  const _TransmissionGear();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const baseWidth = 100.0;
    const baseHeight = baseWidth * 431 / 354;
    final gearBase = Image.asset(
      'images/gear_base.png',
      width: baseWidth,
      color: AppTheme.instance.theme.colorScheme.primary,
    );

    final gearPosition = ref.watch(_gearPositionProvider);
    final gearTransmission = AnimatedPositioned(
      key: const ValueKey('Gear-Animator'),
      duration: Durations.medium3,
      top: switch (gearPosition) {
        _GearPositions.reverse => baseHeight / 3.75,
        _ => null,
      },
      bottom: switch (gearPosition) {
        _GearPositions.drive => baseHeight / 3.6,
        _ => null,
      },
      left: baseWidth / 3.8,
      child: Image.asset(
        'images/gear_transmission.png',
        width: baseWidth / 2,
        color: AppTheme.instance.theme.colorScheme.primary,
      ),
    );
    return GestureDetector(
      onVerticalDragUpdate: (details) => ref.read(_gearPositionProvider.notifier).state =
          details.delta.dy.isNegative ? _GearPositions.reverse : _GearPositions.drive,
      child: Stack(
        children: [
          gearBase,
          gearTransmission,
        ],
      ),
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
final _gearPositionProvider = StateProvider<_GearPositions>((ref) => _GearPositions.drive);

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

enum _GearPositions { reverse, drive }
