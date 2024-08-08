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

mixin HoldDownHandler {
  late final Duration? _setDuration;
  late Duration _duration;
  Timer? _timer;

  void holdDownInit([Duration? duration]) {
    _setDuration = duration;
    holdDownStop();
  }

  void holdDownStart(VoidCallback callback) {
    _timer?.cancel();

    callback();
    _timer = Timer.periodic(
      _duration,
      (_) {
        callback();
      },
    );
  }

  void holdDownStop() {
    _timer?.cancel();
    _duration = _setDuration ?? Duration(milliseconds: Db.instance.read(holdDownDelayKey) ?? 500);
  }
}

class _HoldDownButtonState extends State<HoldDownButton> with HoldDownHandler {
  @override
  void initState() {
    super.initState();
    holdDownInit(widget.duration);
  }

  void _onTapDown(_) => holdDownStart(widget.callback);

  void _onTapUp([dynamic _]) => holdDownStop();

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

class SemiCircularButton extends StatelessWidget {
  const SemiCircularButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.reverseDirection = false,
    this.roundAll = false,
  });

  final void Function()? onPressed;
  final Widget child;
  final bool reverseDirection;
  final bool roundAll;

  @override
  Widget build(BuildContext context) {
    const firstRadius = 60.0;
    const secondRadius = 6.0;
    return Card(
      elevation: 7,
      shape: RoundedRectangleBorder(
        borderRadius: roundAll
            ? BorderRadius.circular(firstRadius)
            : BorderRadius.only(
                topLeft: Radius.circular(reverseDirection ? secondRadius : firstRadius),
                topRight: Radius.circular(reverseDirection ? firstRadius : secondRadius),
                bottomLeft: Radius.circular(reverseDirection ? firstRadius : secondRadius),
                bottomRight: Radius.circular(reverseDirection ? secondRadius : firstRadius),
              ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: child,
          ),
        ),
      ),
    );
  }
}
