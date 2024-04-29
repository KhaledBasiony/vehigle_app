import 'dart:async';

import 'package:flutter/material.dart';

class HoldDownButton extends StatefulWidget {
  const HoldDownButton({
    super.key,
    required this.callback,
    required this.text,
    this.duration = const Duration(milliseconds: 500),
  });

  final void Function() callback;
  final String text;
  final Duration duration;

  @override
  State<HoldDownButton> createState() => _HoldDownButtonState();
}

class _HoldDownButtonState extends State<HoldDownButton> {
  bool _isTapped = false;

  void _recurse() async {
    widget.callback();
    print('Called');
    await Future.delayed(widget.duration);
    print(_isTapped);
  }

  void _onTapDown(_) {
    _isTapped = true;
    widget.callback();
    print(_isTapped);
  }

  void _onTapUp([dynamic _]) {
    _isTapped = false;
    print(_isTapped);
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
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 28),
            child: Text(
              widget.text,
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
