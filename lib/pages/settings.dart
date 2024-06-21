import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_car_sim/common/db.dart';
import 'package:mobile_car_sim/common/widgets.dart';

class SettingsEditor extends StatelessWidget {
  const SettingsEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 34,
                ),
              ),
            ),
          ),
          _HoldDownDuration(),
          SizedBox(height: 10),
          _ConnectionSimulator(),
        ],
      ),
    );
  }
}

class _HoldDownDuration extends ConsumerStatefulWidget {
  const _HoldDownDuration();

  @override
  ConsumerState<_HoldDownDuration> createState() => __HoldDownDurationState();
}

class __HoldDownDurationState extends ConsumerState<_HoldDownDuration> {
  late String _initValue;
  late final TextEditingController _delayController;

  @override
  void initState() {
    super.initState();

    _initValue = (Db().read<int>(holdDownDelayKey) ?? 500).toString();
    _delayController = TextEditingController(text: _initValue);
    _delayController.addListener(() {
      ref.read(_delayValueChangedProvider.notifier).state = _delayController.text != _initValue;
    });
  }

  @override
  void dispose() {
    _delayController.dispose();
    super.dispose();
  }

  void _save() async {
    await Db().write(holdDownDelayKey, int.parse(_delayController.text));
    ref.read(_delayValueChangedProvider.notifier).state = false;
    _initValue = _delayController.text;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RoundedTextField(
            text: 'Hold Down Repeat Delay (ms)',
            controller: _delayController,
          ),
        ),
        IconButton(
          color: Colors.greenAccent,
          onPressed: ref.watch(_delayValueChangedProvider) ? _save : null,
          icon: const Icon(Icons.check_rounded),
        ),
      ],
    );
  }
}

class _ConnectionSimulator extends ConsumerStatefulWidget {
  const _ConnectionSimulator();

  @override
  ConsumerState<_ConnectionSimulator> createState() => __ConnectionSimulatorState();
}

class __ConnectionSimulatorState extends ConsumerState<_ConnectionSimulator> {
  late bool _initValue;
  late bool _currentValue;

  @override
  void initState() {
    super.initState();

    _initValue = _currentValue = Db().read<bool>(useSimulator) ?? false;
  }

  void _save() async {
    await Db().write(useSimulator, _currentValue);
    ref.read(_simulatorValueChangedProvider.notifier).state = false;
    _initValue = _currentValue;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SwitchListTile(
            title: const Text('Use Simulator'),
            value: _currentValue,
            onChanged: (value) {
              setState(() {
                _currentValue = value;
              });
              ref.read(_simulatorValueChangedProvider.notifier).state = value != _initValue;
            },
          ),
        ),
        IconButton(
          color: Colors.greenAccent,
          onPressed: ref.watch(_simulatorValueChangedProvider) ? _save : null,
          icon: const Icon(Icons.check_rounded),
        ),
      ],
    );
  }
}

final _delayValueChangedProvider = StateProvider<bool>((ref) {
  return false;
});

final _simulatorValueChangedProvider = StateProvider<bool>((ref) {
  return false;
});
