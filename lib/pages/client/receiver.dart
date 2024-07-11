import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_car_sim/common/provider.dart';
import 'package:mobile_car_sim/common/theme.dart';
import 'package:mobile_car_sim/common/utils.dart';
import 'package:mobile_car_sim/common/widgets.dart';

class MessageLogger extends ConsumerStatefulWidget {
  const MessageLogger({super.key});

  @override
  ConsumerState<MessageLogger> createState() => _MessageLoggerState();
}

class _MessageLoggerState extends ConsumerState<MessageLogger> {
  final List<Message> _messages = [];
  bool _isReceiving = false;

  void _clear() {
    setState(() {
      _messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      messagesProvider,
      (previous, next) {
        if (_isReceiving) {
          setState(() {
            _messages.insert(0, next.last);
          });
        }
      },
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 1000),
      child: Card.outlined(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Toggle Logs'),
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _isReceiving,
                    onChanged: (newValue) {
                      setState(() {
                        _isReceiving = newValue;
                      });
                    },
                  ),
                ),
                IconButton(
                  onPressed: _clear,
                  icon: Icon(
                    Icons.clear_all,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(_messages[index].text),
                  subtitle: Text(_messages[index].receivedAt.toIso8601String().substring(11)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ValueWatcher extends ConsumerStatefulWidget {
  const ValueWatcher({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ValueWatcherState();
}

class _ValueWatcherState extends ConsumerState<ValueWatcher> {
  late final List<TextEditingController> _keyControllers;

  @override
  void initState() {
    super.initState();
    _keyControllers = pageBucket.readState(context, identifier: _keysFieldsIdentifier) ?? [];
  }

  @override
  void dispose() {
    pageBucket.writeState(context, _keyControllers, identifier: _keysFieldsIdentifier);
    super.dispose();
  }

  void _addWatcher() {
    setState(() {
      _keyControllers.add(TextEditingController());
    });
  }

  void _deleteWatcher(int index) {
    setState(() {
      _keyControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final message = ref.watch(messagesProvider).lastOrNull;
    final keyValueViewer = ListView.builder(
      shrinkWrap: true,
      itemCount: _keyControllers.length,
      itemBuilder: (context, index) {
        final deleteButton = IconButton(
          onPressed: () => _deleteWatcher(index),
          color: AppTheme.instance.theme.colorScheme.error,
          icon: const Icon(Icons.delete),
        );
        final field = RoundedTextField(
          text: 'Json Key',
          controller: _keyControllers[index],
        );

        final value = jsonDecode(message?.text ?? '{}')[_keyControllers[index].text];

        return Row(
          children: [
            deleteButton,
            Expanded(
              child: field,
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(value.toString()),
              ),
            ),
          ],
        );
      },
    );
    final addButton = IconButton(
      onPressed: _addWatcher,
      icon: const Icon(Icons.add),
    );
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Value Watcher'),
                addButton,
              ],
            ),
            keyValueViewer,
          ],
        ),
      ),
    );
  }
}

const _keysFieldsIdentifier = 'Keys-Controllers';
