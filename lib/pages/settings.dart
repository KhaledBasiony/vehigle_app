import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_car_sim/common/db.dart';
import 'package:mobile_car_sim/common/widgets.dart';

class SettingsEditor extends StatelessWidget {
  const SettingsEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final holdDownRepeatDelayField = _DelayDuration(
      labelText: 'Hold Down Repeat Delay (ms)',
      dbKey: holdDownDelayKey,
      isChangedProvider: _holdDownChangedProvider,
    );

    final simulatorReceiveIntervalField = _DelayDuration(
      labelText: 'Simulator Readings Delay (ms)',
      dbKey: simulatorReadingsDelay,
      isChangedProvider: _simulatorDelayChangedProvider,
    );

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
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
          holdDownRepeatDelayField,
          const SizedBox(height: 10),
          simulatorReceiveIntervalField,
          const SizedBox(height: 10),
          const _ConnectionSimulator(),
        ],
      ),
    );
  }
}

class _DelayDuration extends ConsumerStatefulWidget {
  const _DelayDuration({
    required this.labelText,
    required this.dbKey,
    required this.isChangedProvider,
  });

  final String labelText;
  final String dbKey;
  final StateProvider<bool> isChangedProvider;

  @override
  ConsumerState<_DelayDuration> createState() => __DelayDurationState();
}

class __DelayDurationState extends ConsumerState<_DelayDuration> {
  late String _initValue;
  late final TextEditingController _delayController;

  @override
  void initState() {
    super.initState();

    _initValue = (Db().read<int>(widget.dbKey) ?? 500).toString();
    _delayController = TextEditingController(text: _initValue);
    _delayController.addListener(() {
      ref.read(widget.isChangedProvider.notifier).state = _delayController.text != _initValue;
    });
  }

  @override
  void dispose() {
    _delayController.dispose();
    super.dispose();
  }

  void _save() async {
    await Db().write(widget.dbKey, int.parse(_delayController.text));
    ref.read(widget.isChangedProvider.notifier).state = false;
    _initValue = _delayController.text;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RoundedTextField(
            text: widget.labelText,
            controller: _delayController,
          ),
        ),
        IconButton(
          color: Colors.greenAccent,
          onPressed: ref.watch(widget.isChangedProvider) ? _save : null,
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
    ref.read(_useSimulatorChangedProvider.notifier).state = false;
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
              ref.read(_useSimulatorChangedProvider.notifier).state = value != _initValue;
            },
          ),
        ),
        IconButton(
          color: Colors.greenAccent,
          onPressed: ref.watch(_useSimulatorChangedProvider) ? _save : null,
          icon: const Icon(Icons.check_rounded),
        ),
      ],
    );
  }
}

final _holdDownChangedProvider = StateProvider<bool>((ref) => false);

final _simulatorDelayChangedProvider = StateProvider<bool>((ref) => false);

final _useSimulatorChangedProvider = StateProvider<bool>((ref) => false);
