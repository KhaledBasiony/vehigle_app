import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_car_sim/common/db.dart';
import 'package:mobile_car_sim/common/theme.dart';
import 'package:mobile_car_sim/common/widgets.dart';

part 'commands.dart';

class SettingsEditor extends StatelessWidget {
  const SettingsEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final holdDownRepeatDelayField = _TextConfig<int>(
      labelText: 'Hold Down Repeat Delay (ms)',
      dbKey: holdDownDelayKey,
      isChangedProvider: _holdDownChangedProvider,
      valueParser: int.parse,
      initialValue: 200,
    );

    final simulatorReceiveIntervalField = _TextConfig<int>(
      labelText: 'Simulator Readings Delay (ms)',
      dbKey: simulatorReadingsDelay,
      isChangedProvider: _simulatorDelayChangedProvider,
      valueParser: int.parse,
      initialValue: 100,
    );

    final steeringAngleStepField = _TextConfig<int>(
      labelText: 'Steering Angle Step',
      dbKey: steeringAngleStep,
      isChangedProvider: _steeringAngleChangedProvider,
      valueParser: int.parse,
      initialValue: 5,
    );

    final useSimulatorSwitcher = _SwitchConfig(
      labelText: 'Use Simulator',
      dbKey: useSimulator,
      isChangedProvider: _useSimulatorChangedProvider,
    );

    const uiTooltipViewer = Tooltip(
      message: 'UI Changes may need the application to restart',
      child: Icon(Icons.warning_amber_rounded),
    );

    final themeSwitcher = _SwitchConfig(
      labelText: 'Theme',
      offText: 'Dark Theme',
      onText: 'Light Theme',
      dbKey: useLightTheme,
      isChangedProvider: _useLightThemeProvider,
    );

    final textScaleField = _TextConfig<double>(
      labelText: 'Text Scale Factor',
      dbKey: textScaleFactor,
      isChangedProvider: _textScaleChangedProvider,
      valueParser: (text) => double.parse(text),
      initialValue: 1.0,
    );

    final buttonsCommandsPage = ListTile(
      title: const Text('Edit Control Buttons Commands'),
      trailing: const Icon(Icons.arrow_forward_ios_rounded),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const _ButtonsCommandsEditor(),
          ),
        );
      },
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
          buttonsCommandsPage,
          const SizedBox(height: 10),
          const _SectionDivider(title: 'Simulator'),
          useSimulatorSwitcher,
          const SizedBox(height: 10),
          simulatorReceiveIntervalField,
          const Row(
            children: [
              Expanded(child: _SectionDivider(title: 'UI')),
              uiTooltipViewer,
            ],
          ),
          const SizedBox(height: 10),
          themeSwitcher,
          const SizedBox(height: 10),
          textScaleField,
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

class _TextConfig<T> extends ConsumerStatefulWidget {
  const _TextConfig({
    required this.labelText,
    required this.dbKey,
    required this.isChangedProvider,
    required this.valueParser,
    required this.initialValue,
  });

  final String labelText;
  final String dbKey;
  final StateProvider<bool> isChangedProvider;
  final T Function(String text) valueParser;
  final T initialValue;

  @override
  ConsumerState<_TextConfig> createState() => __TextConfigState<T>();
}

class __TextConfigState<T> extends ConsumerState<_TextConfig> {
  late String _initValue;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _initValue = (Db.instance.read<T>(widget.dbKey) ?? widget.initialValue).toString();
    _controller = TextEditingController(text: _initValue);
    _controller.addListener(() {
      ref.read(widget.isChangedProvider.notifier).state = _controller.text != _initValue;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() async {
    final newValue = widget.valueParser(_controller.text);
    await Db.instance.write(widget.dbKey, newValue);
    ref.read(widget.isChangedProvider.notifier).state = false;
    _initValue = _controller.text;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RoundedTextField(
            text: widget.labelText,
            controller: _controller,
          ),
        ),
        IconButton(
          color: AppTheme.instance.theme.brightness == Brightness.dark ? Colors.greenAccent : Colors.green,
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
    this.offText,
    this.onText,
  });

  final String labelText;
  final String? offText;
  final String? onText;
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
            title: Text(
              _currentValue ? widget.onText ?? widget.labelText : widget.offText ?? widget.labelText,
            ),
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
          color: AppTheme.instance.theme.brightness == Brightness.dark ? Colors.greenAccent : Colors.green,
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

final _useLightThemeProvider = StateProvider<bool>((ref) => false);

final _textScaleChangedProvider = StateProvider<bool>((ref) => false);

final _forwardCommandChangedProvider = StateProvider<bool>((ref) => false);

final _backwardsCommandChangedProvider = StateProvider<bool>((ref) => false);

final _brakesCommandChangedProvider = StateProvider<bool>((ref) => false);
