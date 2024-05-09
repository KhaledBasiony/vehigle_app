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
        _onSend();
      });

  @override
  void dispose() {
    _commandText.dispose();
    super.dispose();
  }

  void _onForward() {
    Client.singleton().send('f'.codeUnits);
  }

  void _onBackwards() {
    Client.singleton().send('r'.codeUnits);
  }

  void _onBrakes() {
    Client.singleton().send('b'.codeUnits);
  }

  void _onLeft() {
    setState(() {
      _angle = max(_angle - 1, -40);
    });
    Client.singleton().send([_angle + 40]);
  }

  void _onRight() {
    setState(() {
      _angle = min(_angle + 1, 40);
    });
    Client.singleton().send([_angle + 40]);
  }

  void _onSend() {
    Client.singleton().send(_commandText.text.codeUnits);
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
            Center(
              child: GestureDetector(
                child: HoldDownButton(callback: _onForward, text: 'Forward'),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HoldDownButton(callback: _onLeft, text: 'Left'),
                HoldDownButton(callback: _onBrakes, text: 'Brakes'),
                HoldDownButton(callback: _onRight, text: 'Right'),
              ],
            ),
            Center(
              child: HoldDownButton(callback: _onBackwards, text: 'Backwards'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commandText,
                  ),
                ),
                Switch(value: _isTransmittingText, onChanged: _onSwitchChanged),
                IconButton(onPressed: _onSend, icon: const Icon(Icons.send_outlined))
              ],
            ),
          ],
        ),
      ),
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
