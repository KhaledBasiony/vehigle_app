import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_car_sim/common/db.dart';
import 'package:mobile_car_sim/common/provider.dart';
import 'package:mobile_car_sim/common/shortcuts/actions.dart';
import 'package:mobile_car_sim/common/theme.dart';
import 'package:mobile_car_sim/models/car.dart';
import 'package:mobile_car_sim/models/client.dart';
import 'package:mobile_car_sim/common/widgets.dart';
import 'package:mobile_car_sim/models/simulator.dart';

class ControlsCard extends ConsumerStatefulWidget {
  const ControlsCard({super.key});

  @override
  ConsumerState<ControlsCard> createState() => _ControlsCardState();
}

class _ControlsCardState extends ConsumerState<ControlsCard> {
  bool _isTransmittingText = false;
  late Timer _textTimer;
  late final TextEditingController _commandText;

  @override
  void initState() {
    super.initState();
    _commandText = TextEditingController();
    _assignTextTimer();
    _textTimer.cancel();
  }

  void _assignTextTimer() => _textTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
        _send();
      });

  @override
  void dispose() {
    _commandText.dispose();
    super.dispose();
  }

  void _send([List<int>? bytes]) {
    Client.instance.send(bytes ?? _commandText.text.codeUnits);
  }

  void _onSwitchChanged(bool newVale) {
    newVale ? _assignTextTimer() : _textTimer.cancel();
    setState(() {
      _isTransmittingText = newVale;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(isConnectedProvider)) {
      return const SizedBox.shrink();
    }

    final steeringAngleIndicator = Consumer(builder: (context, ref, child) {
      final angle = ref.watch(wheelAngleProvider);
      return RichText(
        text: TextSpan(
          style: TextStyle(color: AppTheme.instance.theme.colorScheme.onSurfaceVariant),
          text: 'Steering Angle: ',
          children: [
            TextSpan(
              text: '$angle',
              style: const TextStyle(fontSize: 32),
            ),
          ],
        ),
      );
    });
    return Card(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _OnOffSwitch(),
                        steeringAngleIndicator,
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _CarState(
                          onSend: (text) => _send(text.codeUnits),
                        ),
                      ),
                      (Db.instance.read<bool>(useJoystick) ?? true)
                          ? const Flexible(
                              child: Center(child: _MovementJoystick()),
                            )
                          : const _MovementButtons(),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: RoundedTextField(
                          text: 'Custom Command',
                          controller: _commandText,
                        ),
                      ),
                      Switch(value: _isTransmittingText, onChanged: _onSwitchChanged),
                      IconButton(onPressed: _send, icon: const Icon(Icons.send_outlined))
                    ],
                  ),
                  const _ReadingsSetter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CarState extends ConsumerWidget {
  const _CarState({
    required this.onSend,
  });

  final void Function(String text) onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentState = ref.watch(carStatesProvider);
    final currentStateIndicator = Text(currentState.disp);

    final selectAlgoButton = DropdownButtonFormField(
      decoration: const InputDecoration(labelText: 'Select Algorithm'),
      items: _ParkingAlgo.values
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e.name),
            ),
          )
          .toList(),
      onChanged: (newValue) {
        if (newValue == null) return;
        onSend(switch (newValue) {
          _ParkingAlgo.circleLineCircle => 'c',
          _ParkingAlgo.twoCircles => 'l',
        });

        ref.read(carStatesProvider.notifier).update(CarStates.parking);
      },
    );

    const underDevelopmentIndicator = Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber,
          ),
          SizedBox(width: 10),
          Text('Under Development'),
          SizedBox(width: 10),
          Icon(
            Icons.code_off_rounded,
            color: Colors.redAccent,
          ),
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        underDevelopmentIndicator,
        const Text('Current State:'),
        currentStateIndicator,
        Visibility(
          visible: currentState != CarStates.searching,
          child: selectAlgoButton,
        ),
      ],
    );
  }
}

class _MovementJoystick extends StatelessWidget {
  const _MovementJoystick();

  void _updateReadings(BuildContext context, StickDragDetails details) {
    final Function() movementCallback;
    if (details.y == 0.0) {
      movementCallback = Actions.handler(context, const StopIntent()) ?? () {};
    }
    // NOTE! positive y axis is downwards.
    else if (details.y < 0) {
      movementCallback = Actions.handler(context, const MoveForwardIntent()) ?? () {};
    } else {
      movementCallback = Actions.handler(context, const MoveBackwardsIntent()) ?? () {};
    }
    movementCallback();

    final Function() steeringCallback;
    final maxSteeringAngle = CarModel.instance.maxSteeringAngle;
    final steeringStep = Db.instance.read<int>(steeringAngleStep) ?? 1;
    if (details.x == 0.0) {
      steeringCallback = Actions.handler(context, const TurnLeftIntent(value: 0)) ?? () {};
    } else if (details.x < 0) {
      steeringCallback = Actions.handler(
            context,
            // Note: using power 2 to decrease sensitivity at the beginning and increase it at the end
            TurnLeftIntent(value: (-pow(details.x, 2) * maxSteeringAngle).roundToNearest(steeringStep)),
          ) ??
          () {};
    } else {
      steeringCallback = Actions.handler(
            context,
            TurnRightIntent(value: (pow(details.x, 2) * maxSteeringAngle).roundToNearest(steeringStep)),
          ) ??
          () {};
    }
    steeringCallback();
  }

  @override
  Widget build(BuildContext context) {
    const padding = 20.0;
    return Padding(
      padding: const EdgeInsets.all(padding),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final side = min(constraints.maxHeight, constraints.maxWidth) - padding;

          final joystickBase = JoystickSquareBase(
            size: side,
            decoration: JoystickBaseDecoration(
              color: AppTheme.instance.theme.colorScheme.primary,
              drawOuterCircle: false,
              drawMiddleCircle: false,
              drawInnerCircle: false,
              drawArrows: false,
            ),
          );

          return Joystick(
            listener: (details) => _updateReadings(context, details),
            period: Duration(milliseconds: Db.instance.read(holdDownDelayKey)),
            includeInitialAnimation: false,
            base: joystickBase,
            stickOffsetCalculator: const RectangleStickOffsetCalculator(),
            stick: JoystickStick(
              size: side / 4,
              decoration: JoystickStickDecoration(
                color: AppTheme.instance.theme.colorScheme.onPrimary,
                shadowColor: Colors.transparent,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MovementButtons extends StatelessWidget {
  const _MovementButtons();

  void _fallbackCallback() {
    print('Action not enabled or not found');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: HoldDownButton(
            callback: Actions.handler(context, const MoveForwardIntent()) ?? _fallbackCallback,
            text: 'Forward',
            child: const Icon(Icons.keyboard_arrow_up_rounded),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HoldDownButton(
              callback: Actions.handler(context, const TurnLeftIntent()) ?? _fallbackCallback,
              text: 'Left',
              child: const Icon(Icons.keyboard_arrow_left_rounded),
            ),
            HoldDownButton(
              callback: Actions.handler(context, const StopIntent()) ?? _fallbackCallback,
              text: 'Stop',
            ),
            HoldDownButton(
              callback: Actions.handler(context, const TurnRightIntent()) ?? _fallbackCallback,
              text: 'Right',
              child: const Icon(Icons.keyboard_arrow_right_rounded),
            ),
          ],
        ),
        Center(
          child: HoldDownButton(
            callback: Actions.handler(context, const MoveBackwardsIntent()) ?? _fallbackCallback,
            text: 'Backwards',
            child: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
        )
      ],
    );
  }
}

class _OnOffSwitch extends ConsumerWidget {
  const _OnOffSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReceiving = ref.watch(isReceivingProvider);

    final switchButton = Switch(
      value: isReceiving,
      onChanged: (newValue) {
        ref.read(isReceivingProvider.notifier).state = newValue;
        Actions.invoke(context, SwitchReceivingIntent(newValue));
      },
    );

    const offIcon = Icon(
      Icons.warning_amber_rounded,
      key: ValueKey('Off-Icon'),
      color: Colors.yellow,
    );
    const onIcon = Icon(
      Icons.check_circle_rounded,
      key: ValueKey('On-Icon'),
      color: Colors.green,
    );

    const onText = Text(
      'Receiving',
      key: ValueKey('On-Text'),
    );
    const offText = Text(
      'NOT Receiving',
      key: ValueKey('Off-Text'),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: switchButton,
        ),
        AnimatedSwitcher(
          duration: Durations.short3,
          child: isReceiving ? onIcon : offIcon,
        ),
        const SizedBox(width: 4),
        isReceiving ? onText : offText,
      ],
    );
  }
}

enum _ParkingAlgo {
  circleLineCircle,
  twoCircles,
}

class _ReadingsSetter extends ConsumerStatefulWidget {
  const _ReadingsSetter();

  @override
  ConsumerState<_ReadingsSetter> createState() => __ReadingsSetterState();
}

class __ReadingsSetterState extends ConsumerState<_ReadingsSetter> {
  late final TextEditingController _stateController;

  @override
  void initState() {
    super.initState();
    _stateController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parkingStates = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ElevatedButton(
            onPressed: Actions.handler(context, const NavigateIntent()) ??
                () {
                  MockServer.instance.carState.base = 0;
                },
            child: const Text('Navigate'),
          ),
          ElevatedButton(
            onPressed: Actions.handler(context, const ParkIntent()) ?? () {},
            child: const Text('Auto Park'),
          ),
        ],
      ),
    );

    final driveBack = ElevatedButton(
      onPressed: Actions.handler(context, const DriveBackIntent()) ?? () {},
      child: const Text('Drive Back'),
    );

    final selfParking = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ElevatedButton(
            onPressed: Actions.handler(context, const StartRecordingIntent()) ?? () {},
            child: const Text('Record Park'),
          ),
          ElevatedButton(
            onPressed: Actions.handler(context, const ReplayParkIntent()) ?? () {},
            child: const Text('Replay Park'),
          ),
        ],
      ),
    );

    final stateSetter = Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const ListTile(title: Center(child: Text('Car States'))),
            parkingStates,
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: driveBack,
            ),
            selfParking,
          ],
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: stateSetter,
        ),
      ],
    );
  }
}

extension on double {
  roundToNearest(int n) => (this / n).round() * n;
}
