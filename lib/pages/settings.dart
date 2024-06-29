import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_car_sim/common/db.dart';
import 'package:mobile_car_sim/common/widgets.dart';

class SettingsEditor extends StatelessWidget {
  const SettingsEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final holdDownRepeatDelayField = _TextConfig(
      labelText: 'Hold Down Repeat Delay (ms)',
      dbKey: holdDownDelayKey,
      isChangedProvider: _holdDownChangedProvider,
    );

    final simulatorReceiveIntervalField = _TextConfig(
      labelText: 'Simulator Readings Delay (ms)',
      dbKey: simulatorReadingsDelay,
      isChangedProvider: _simulatorDelayChangedProvider,
    );

    final steeringAngleStepField = _TextConfig(
      labelText: 'Steering Angle Step',
      dbKey: steeringAngleStep,
      isChangedProvider: _steeringAngleChangedProvider,
    );

    final useSimulatorSwitcher = _SwitchConfig(
      labelText: 'Use Simulator',
      dbKey: useSimulator,
      isChangedProvider: _useSimulatorChangedProvider,
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
          const _SectionDivider(title: 'Controls'),
          const SizedBox(height: 10),
          holdDownRepeatDelayField,
          const SizedBox(height: 10),
          steeringAngleStepField,
          const SizedBox(height: 10),
          const _SectionDivider(title: 'Simulator'),
          useSimulatorSwitcher,
          const SizedBox(height: 10),
          simulatorReceiveIntervalField,
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Text(
            title,
            textScaler: const TextScaler.linear(1.2),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Expanded(child: Divider(indent: 10)),
        ],
      ),
    );
  }
}

class _TextConfig extends ConsumerStatefulWidget {
  const _TextConfig({
    required this.labelText,
    required this.dbKey,
    required this.isChangedProvider,
  });

  final String labelText;
  final String dbKey;
  final StateProvider<bool> isChangedProvider;

  @override
  ConsumerState<_TextConfig> createState() => __TextConfigState();
}

class __TextConfigState extends ConsumerState<_TextConfig> {
  late String _initValue;
  late final TextEditingController _delayController;

  @override
  void initState() {
    super.initState();

    _initValue = (Db.instance.read<int>(widget.dbKey) ?? 500).toString();
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
    await Db.instance.write(widget.dbKey, int.parse(_delayController.text));
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

class _SwitchConfig extends ConsumerStatefulWidget {
  const _SwitchConfig({
    required this.labelText,
    required this.dbKey,
    required this.isChangedProvider,
  });

  final String labelText;
  final String dbKey;
  final StateProvider<bool> isChangedProvider;

  @override
  ConsumerState<_SwitchConfig> createState() => __SwitchConfigState();
}

class __SwitchConfigState extends ConsumerState<_SwitchConfig> {
  late bool _initValue;
  late bool _currentValue;

  @override
  void initState() {
    super.initState();

    _initValue = _currentValue = Db.instance.read<bool>(widget.dbKey) ?? false;
  }

  void _save() async {
    await Db.instance.write(widget.dbKey, _currentValue);
    ref.read(widget.isChangedProvider.notifier).state = false;
    _initValue = _currentValue;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SwitchListTile(
            title: Text(widget.labelText),
            value: _currentValue,
            onChanged: (value) {
              setState(() {
                _currentValue = value;
              });
              ref.read(widget.isChangedProvider.notifier).state = value != _initValue;
            },
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

final _holdDownChangedProvider = StateProvider<bool>((ref) => false);

final _simulatorDelayChangedProvider = StateProvider<bool>((ref) => false);

final _useSimulatorChangedProvider = StateProvider<bool>((ref) => false);

final _steeringAngleChangedProvider = StateProvider<bool>((ref) => false);
