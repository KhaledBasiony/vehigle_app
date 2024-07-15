import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_car_sim/common/db.dart';

class HoldDownButton extends StatefulWidget {
  const HoldDownButton({
    super.key,
    required this.callback,
    this.text,
    this.child,
    this.duration,
  }) : assert(child != null || text != null);

  final void Function() callback;
  final String? text;
  final Widget? child;
  final Duration? duration;

  @override
  State<HoldDownButton> createState() => _HoldDownButtonState();
}

class _HoldDownButtonState extends State<HoldDownButton> {
  late Duration _duration;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initDuration();
  }

  void _initDuration() {
    _duration = widget.duration ?? Duration(milliseconds: Db.instance.read(holdDownDelayKey) ?? 500);
  }

  void _onTapDown(_) {
    _timer?.cancel();

    widget.callback();
    _timer = Timer.periodic(
      _duration,
      (_) {
        widget.callback();
      },
    );
  }

  void _onTapUp([dynamic _]) {
    _timer?.cancel();
    _initDuration();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Card(
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(500))),
        child: InkWell(
          onTapDown: _onTapDown,
          onTap: _onTapUp,
          onTapCancel: _onTapUp,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: widget.child ??
                Text(
                  widget.text!,
                  style: textStyle?.copyWith(
                    color: primaryColor,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

class RoundedTextField extends StatelessWidget {
  const RoundedTextField({
    super.key,
    required this.text,
    required this.controller,
    this.onChanged,
    InputType? inputType,
  }) : inputType = inputType ?? InputType.strings;

  final String text;
  final TextEditingController controller;
  final InputType inputType;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      inputFormatters: [
        if (inputType == InputType.integers) FilteringTextInputFormatter.allow(r'[0-9]'),
        if (inputType == InputType.decimals) FilteringTextInputFormatter.allow(r'[0-9\.]'),
      ],
      validator: switch (inputType) {
        InputType.integers => (value) => int.tryParse(value ?? '') == null ? 'Enter a valid Integer' : null,
        InputType.decimals => (value) => num.tryParse(value ?? '') == null ? 'Enter a valid Decimal' : null,
        _ => (_) => null,
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: onChanged,
      decoration: InputDecoration(
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(48)),
        ),
        labelText: text,
      ),
    );
  }
}

enum InputType { integers, decimals, strings }
