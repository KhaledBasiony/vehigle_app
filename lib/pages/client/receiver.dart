import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_car_sim/common/provider.dart';
import 'package:mobile_car_sim/models/client.dart';

class ReceiverCard extends ConsumerStatefulWidget {
  const ReceiverCard({super.key});

  @override
  ConsumerState<ReceiverCard> createState() => _ReceiverCardState();
}

class _ReceiverCardState extends ConsumerState<ReceiverCard> {
  final List<_Message> _messages = [];
  bool _isReceiving = false;

  void _onMessage(String text) {
    if (_isReceiving) {
      setState(() {
        print(text);
        _messages.insert(0, _Message(text: text));
      });
    }
  }

  void _clear() {
    setState(() {
      _messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      isConnectedProvider,
      (previous, next) {
        if (next) Client.singleton().addCallback(_onMessage);
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
                    title: const Text('Toggle Receiving'),
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

class _Message {
  _Message({
    required this.text,
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();
  final String text;
  final DateTime receivedAt;
}
