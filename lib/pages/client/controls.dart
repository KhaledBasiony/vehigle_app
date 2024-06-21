import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_car_sim/common/provider.dart';
import 'package:mobile_car_sim/models/client.dart';
import 'package:mobile_car_sim/common/widgets.dart';

class ControlsCard extends ConsumerStatefulWidget {
  const ControlsCard({super.key});

  @override
  ConsumerState<ControlsCard> createState() => _ControlsCardState();
}

class _ControlsCardState extends ConsumerState<ControlsCard> {
  bool _isTransmittingText = false;
  late Timer _textTimer;
  late final TextEditingController _commandText;
  int _angle = 0;

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

  void _moveForward() {
    Client.singleton().send('f'.codeUnits);
  }

  void _moveBackwards() {
    Client.singleton().send('r'.codeUnits);
  }

  void _brake() {
    Client.singleton().send('b'.codeUnits);
  }

  void _moveLeft() {
    setState(() {
      _angle = max(_angle - 1, -40);
    });
    Client.singleton().send([_angle + 40]);
  }

  void _moveRight() {
    setState(() {
      _angle = min(_angle + 1, 40);
    });
    Client.singleton().send([_angle + 40]);
  }

  void _send([List<int>? bytes]) {
    Client.singleton().send(bytes ?? _commandText.text.codeUnits);
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
    return Card(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _OnOffSwitch(),
                      Text('Steering Angle: $_angle'),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                        child: _CarState(
                      onSend: (text) => _send(text.codeUnits),
                    )),
                    _MovementButtons(
                      onForward: _moveForward,
                      onBackwards: _moveBackwards,
                      onLeft: _moveLeft,
                      onRight: _moveRight,
                      onBrakes: _brake,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commandText,
                      ),
                    ),
                    Switch(value: _isTransmittingText, onChanged: _onSwitchChanged),
                    IconButton(onPressed: _send, icon: const Icon(Icons.send_outlined))
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CarState extends StatefulWidget {
  const _CarState({
    required this.onSend,
  });

  final void Function(String text) onSend;

  @override
  State<_CarState> createState() => _CarStateState();
}

class _CarStateState extends State<_CarState> {
  _CarStates _currentState = _CarStates.searching;
  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _currentState = _CarStates.waitingAlgoSelection;
        });
      }
    });
    final currentStateIndicator = Text(_currentState.name);

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
        widget.onSend(newValue!.name);
        setState(() {
          _currentState = _CarStates.parking;
        });
      },
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Current State:'),
        currentStateIndicator,
        Visibility(
          visible: _currentState != _CarStates.searching,
          child: selectAlgoButton,
        ),
      ],
    );
  }
}

class _MovementButtons extends StatelessWidget {
  const _MovementButtons({
    required this.onForward,
    required this.onLeft,
    required this.onRight,
    required this.onBrakes,
    required this.onBackwards,
  });

  final void Function() onForward;
  final void Function() onLeft;
  final void Function() onRight;
  final void Function() onBackwards;
  final void Function() onBrakes;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: GestureDetector(
            child: HoldDownButton(
              callback: onForward,
              text: 'Forward',
              child: const Icon(Icons.keyboard_arrow_up_rounded),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HoldDownButton(
              callback: onLeft,
              text: 'Left',
              child: const Icon(Icons.keyboard_arrow_left_rounded),
            ),
            HoldDownButton(
              callback: onBrakes,
              text: 'Stop',
              // child: const Icon(Icons.warning_amber_rounded),
            ),
            HoldDownButton(
              callback: onRight,
              text: 'Right',
              child: const Icon(Icons.keyboard_arrow_right_rounded),
            ),
          ],
        ),
        Center(
          child: HoldDownButton(
            callback: onBackwards,
            text: 'Backwards',
            child: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
        )
      ],
    );
  }
}

class _OnOffSwitch extends StatefulWidget {
  const _OnOffSwitch();

  @override
  State<_OnOffSwitch> createState() => __OnOffSwitchState();
}

class __OnOffSwitchState extends State<_OnOffSwitch> {
  bool _value = true;
  @override
  Widget build(BuildContext context) {
    final switchButton = Switch(
      value: _value,
      onChanged: (newValue) {
        setState(() {
          _value = newValue;
        });
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: switchButton,
        ),
        AnimatedSwitcher(
          duration: Durations.short3,
          child: _value ? onIcon : offIcon,
        ),
      ],
    );
  }
}

enum _CarStates {
  searching,
  waitingAlgoSelection,
  parking,
}

enum _ParkingAlgo {
  circleLineCircle,
  twoCircles,
}
