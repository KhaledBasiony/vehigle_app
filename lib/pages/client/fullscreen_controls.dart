import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_car_sim/common/db.dart';
import 'package:mobile_car_sim/common/provider.dart';
import 'package:mobile_car_sim/common/shortcuts/actions.dart';
import 'package:mobile_car_sim/common/theme.dart';
import 'package:mobile_car_sim/common/widgets.dart';

const _padding = 20.0;

class _ControlsConstraints extends ConsumerWidget {
  const _ControlsConstraints({
    required this.child,
    required this.maxWidth,
    this.onLayout,
  });

  final Widget child;
  final double maxWidth;

  final void Function(double width)? onLayout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = min(maxWidth, constraints.maxWidth);
        Future(() => (onLayout ?? (_) {})(width));
        return SizedBox(
          width: width,
          child: child,
        );
      },
    );
  }
}

class DrDriverControls extends ConsumerStatefulWidget {
  const DrDriverControls({super.key});

  @override
  ConsumerState<DrDriverControls> createState() => _DrDriverControlsState();
}

class _DrDriverControlsState extends ConsumerState<DrDriverControls> {
  Offset _startOffset = Offset.zero;
  int _overlaps = 0;

  Duration _steeringDuration = Durations.short3;

  void _startDragging(DragStartDetails details) {
    _startOffset = details.localPosition - ref.read(_wheelGeoProvider).center;
    _steeringDuration = Durations.short3;
  }

  void _updateAngle(DragUpdateDetails details) {
    final currentOffset = details.localPosition - ref.read(_wheelGeoProvider).center;
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
  }

  void _resetAngle(_) {
    _steeringDuration = Durations.medium4;
    ref.read(wheelAngleProvider.notifier).state = 0;
    ref.read(_steeringWheelAngleProvider.notifier).state = 0;
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
    // invoke action only when wheel angle changes
    ref.listen(wheelAngleProvider, (previous, next) {
      final angleStep = Db.instance.read<int>(steeringAngleStep) ?? 1;
      if (next.roundToBase(angleStep) == previous?.roundToBase(angleStep)) return;
      Actions.invoke(
        context,
        next < (previous ?? 0)
            ? TurnLeftIntent(value: next.roundToBase(angleStep))
            : TurnRightIntent(value: next.roundToBase(angleStep)),
      );
    });
    final wheel = _ControlsConstraints(
      maxWidth: 110,
      onLayout: (width) {
        ref.read(_wheelGeoProvider.notifier).state = _WheelGeo(size: Size.square(width));
      },
      child: Image.asset(
        'images/steering_wheel.png',
        color: AppTheme.instance.theme.colorScheme.primary,
      ),
    );

    final brakesPedal = _BrakesPedal(
      onPress: _pressBrakes,
      onRelease: _releaseBrakes,
    );

    final accelerationPedal = _AccelerationPedal(
      onPress: _pressAcceleration,
      onRelease: _releaseAcceleration,
    );

    final pedals = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Padding(
            padding: const EdgeInsets.all(_padding),
            child: brakesPedal,
          ),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.all(_padding),
            child: _ControlsConstraints(
              maxWidth: 80,
              child: accelerationPedal,
            ),
          ),
        ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(_padding),
                child: _TransmissionGear(),
              ),
              GestureDetector(
                onPanStart: _startDragging,
                onPanUpdate: _updateAngle,
                onPanEnd: _resetAngle,
                child: Padding(
                  padding: const EdgeInsets.all(_padding),
                  child: AnimatedRotation(
                    turns: _carWheelsToSteeringWheelTurns(ref.watch(wheelAngleProvider)),
                    duration: _steeringDuration,
                    child: wheel,
                  ),
                ),
              ),
            ],
          ),
        ),
        Flexible(child: pedals),
      ],
    );
  }
}

class _BrakesPedal extends ConsumerWidget {
  const _BrakesPedal({
    required this.onPress,
    required this.onRelease,
  });

  final VoidCallback onPress;
  final VoidCallback onRelease;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: ref.watch(_wheelGeoProvider).size.height),
      child: _Pedal(
        asset: 'images/brakes_pedal.png',
        onPress: onPress,
        onRelease: onRelease,
      ),
    );
  }
}

class _AccelerationPedal extends ConsumerWidget {
  const _AccelerationPedal({
    required this.onPress,
    required this.onRelease,
  });

  final VoidCallback onPress;
  final VoidCallback onRelease;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: ref.watch(_wheelGeoProvider).size.height),
      child: _Pedal(
        asset: 'images/accelerator_pedal.png',
        onPress: onPress,
        onRelease: onRelease,
      ),
    );
  }
}

class _Pedal extends StatefulWidget {
  const _Pedal({
    required this.asset,
    required this.onPress,
    required this.onRelease,
  });

  final String asset;

  final VoidCallback onPress;
  final VoidCallback onRelease;

  @override
  State<_Pedal> createState() => _PedalState();
}

class _PedalState extends State<_Pedal> with SingleTickerProviderStateMixin, HoldDownHandler {
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Durations.short3,
    );
    holdDownInit();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _press([_]) {
    _controller.forward();
    holdDownStart(widget.onPress);
  }

  void _release([_]) {
    _controller.reverse();
    widget.onRelease();
    holdDownStop();
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
    final baseWidth = ref.watch(_wheelGeoProvider).size.width * 2 / 3;
    final baseHeight = baseWidth * 431 / 354;
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

final _steeringWheelAngleProvider = StateProvider<double>((ref) => 0);
final _gearPositionProvider = StateProvider<_GearPositions>((ref) => _GearPositions.drive);

final _wheelGeoProvider = StateProvider<_WheelGeo>((ref) => _WheelGeo(size: const Size.square(150)));

class _WheelGeo {
  _WheelGeo({required this.size})
      : center = Offset(
              size.width / 2,
              size.height / 2,
            ) +
            const Offset(_padding, _padding);

  final Size size;
  final Offset center;
}

int _steeringWheelToCarWheels(double steeringWheelAngle) => (steeringWheelAngle / (360 * 5 / 3) * 40).round();
double _carWheelsToSteeringWheelTurns(int carWheelsAnlge) => carWheelsAnlge / 40 * 5 / 3;

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

extension on num {
  /// Rounds to a multiple of [step].
  int roundToBase(int step) => (this / step).round() * step;
}

enum _GearPositions { reverse, drive }
