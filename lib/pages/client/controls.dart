import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_car_sim/common/db.dart';
import 'package:mobile_car_sim/common/provider.dart';
import 'package:mobile_car_sim/common/shortcuts/actions.dart';
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

    final steeringAngleIndicator = Consumer(builder: (context, ref, child) {
      final angle = ref.watch(wheelAngleProvider);
      return Text('Steering Angle: $angle');
    });
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
                      steeringAngleIndicator,
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                        child: _CarState(
                      onSend: (text) => _send(text.codeUnits),
                    )),
                    _MovementButtons(),
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
                if (Db().read<bool>(useSimulator) ?? false) const _ReadingsSetter(),
              ],
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
        onSend(newValue!.name);

        ref.read(carStatesProvider.notifier).update(CarStates.parking);
      },
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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

class _MovementButtons extends StatelessWidget {
  void _fallbackCallback() {
    print('Action not enabled or not found');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: GestureDetector(
            child: HoldDownButton(
              callback: Actions.handler(context, const MoveForwardIntent()) ?? _fallbackCallback,
              text: 'Forward',
              child: const Icon(Icons.keyboard_arrow_up_rounded),
            ),
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
            callback: Actions.handler(context, const StopIntent()) ?? _fallbackCallback,
            text: 'Backwards',
            child: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
        )
      ],
    );
  }
}

class _OnOffSwitch extends ConsumerStatefulWidget {
  const _OnOffSwitch();

  @override
  ConsumerState<_OnOffSwitch> createState() => __OnOffSwitchState();
}

class __OnOffSwitchState extends ConsumerState<_OnOffSwitch> {
  bool _value = false;

  @override
  void initState() {
    super.initState();

    Client.singleton().addCallback(_receiveMessage);
  }

  // receiving here because this widget is always visible while connected,
  // therefore `ref` is always available.
  void _receiveMessage(String text) {
    if (!_value) return;

    final lastReading = RegExp('.*({.*?})').firstMatch(text)?.group(1);
    if (lastReading == null) return; // <== should never happen

    ref.read(messagesProvider.notifier).add(lastReading);

    final data = jsonDecode(lastReading) as Map<String, dynamic>;
    ref.read(carStatesProvider.notifier).update(CarStates.values.elementAt(data['PHS'] as int));
  }

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
          child: _value ? onIcon : offIcon,
        ),
        const SizedBox(width: 4),
        _value ? onText : offText,
      ],
    );
  }
}

enum _ParkingAlgo {
  circleLineCircle,
  twoCircles,
}

class _ReadingsSetter extends StatefulWidget {
  const _ReadingsSetter();

  @override
  State<_ReadingsSetter> createState() => __ReadingsSetterState();
}

class __ReadingsSetterState extends State<_ReadingsSetter> {
  late final TextEditingController _stateController;
  late final TextEditingController _encoderController;

  @override
  void initState() {
    super.initState();
    _stateController = TextEditingController(text: '0');
    _encoderController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _stateController.dispose();
    _encoderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateSetter = TextFormField(
      decoration: const InputDecoration(labelText: 'Car State'),
      controller: _stateController,
      maxLength: 1,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[012]'))],
      onChanged: (value) {
        MockServer.singleton().carState.base = int.tryParse(value) ?? 0;
      },
    );

    final encoder = TextFormField(
      decoration: const InputDecoration(labelText: 'Encoder Reading'),
      controller: _encoderController,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\.-]'))],
      onChanged: (value) {
        MockServer.singleton().encoderStep = num.tryParse(value) ?? 0;
      },
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        stateSetter,
        encoder,
      ],
    );
  }
}
