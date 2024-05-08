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
            Center(
              child: Text('Steering Angle: $_angle'),
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
