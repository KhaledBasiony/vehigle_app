part of 'drawer.dart';

class _ButtonsCommandsEditor extends StatelessWidget {
  const _ButtonsCommandsEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Buttons Commands Editor'),
          centerTitle: true,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              shrinkWrap: true,
              children: [
                _ButtonCommandEntry(
                  title: 'Forward Button',
                  dbKey: cForwardButton,
                  isChangedProvider: _forwardCommandChangedProvider,
                ),
                _ButtonCommandEntry(
                  title: 'Backwards Button',
                  dbKey: cBackwardsButton,
                  isChangedProvider: _backwardsCommandChangedProvider,
                ),
                _ButtonCommandEntry(
                  title: 'Stop Button',
                  dbKey: cBrakesButton,
                  isChangedProvider: _brakesCommandChangedProvider,
                ),
                _ButtonCommandEntry(
                  title: 'Accelerate Button',
                  dbKey: cAccelerateButton,
                  isChangedProvider: _accelerateCommandChangedProvider,
                ),
                _ButtonCommandEntry(
                  title: 'Decelerate Button',
                  dbKey: cDecelerateButton,
                  isChangedProvider: _decelerateCommandChangedProvider,
                ),
                _ButtonCommandEntry(
                  title: 'Navigate Button',
                  dbKey: cNavigateButton,
                  isChangedProvider: _navigateCommandChangedProvider,
                ),
                _ButtonCommandEntry(
                  title: 'Park Button',
                  dbKey: cParkButton,
                  isChangedProvider: _parkCommandChangedProvider,
                ),
                _ButtonCommandEntry(
                  title: 'Drive Back Button',
                  dbKey: cDriveBackButton,
                  isChangedProvider: _driveBackCommandChangedProvider,
                ),
                _ButtonCommandEntry(
                  title: 'Record Parking Button',
                  dbKey: cRecordButton,
                  isChangedProvider: _recordCommandChangedProvider,
                ),
                _ButtonCommandEntry(
                  title: 'Replay Park Button',
                  dbKey: cReplayButton,
                  isChangedProvider: _replayCommandChangedProvider,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonCommandEntry extends ConsumerStatefulWidget {
  const _ButtonCommandEntry({
    required this.title,
    required this.dbKey,
    required this.isChangedProvider,
  });

  final String title;
  final String dbKey;
  final StateProvider<bool> isChangedProvider;

  @override
  ConsumerState<_ButtonCommandEntry> createState() => _ButtonCommandEntryState();
}

class _ButtonCommandEntryState extends ConsumerState<_ButtonCommandEntry> {
  _InputType _inputType = _InputType.byteList;
  late final TextEditingController _stringController;
  late final TextEditingController _bytesController;

  late List<int> _commandBytes;

  @override
  void initState() {
    super.initState();
    _commandBytes = Db.instance.read<List<int>>(widget.dbKey) ?? [];
    _stringController = TextEditingController(text: utf8.decode(_commandBytes));
    _bytesController = TextEditingController(text: _commandBytes.join(', '));
  }

  @override
  void dispose() {
    _stringController.dispose();
    _bytesController.dispose();
    super.dispose();
  }

  void _reset() {
    _commandBytes = Db.instance.read<List<int>>(widget.dbKey) ?? [];
    _stringController.text = utf8.decode(_commandBytes);
    _bytesController.text = _commandBytes.join(', ');
    ref.read(widget.isChangedProvider.notifier).state = false;
  }

  _saveCurrentBytes() {
    Db.instance.write(widget.dbKey, _commandBytes);
    _reset();
  }

  void _updateFromString(String value) {
    _commandBytes = value.trim().codeUnits;
    _bytesController.text = _commandBytes.join(', ');
    ref.read(widget.isChangedProvider.notifier).state = true;
  }

  void _updateFromBytesString(String value) {
    _commandBytes = value
        .trim()
        .split(RegExp(r',\s*'))
        .where((element) {
          final value = int.tryParse(element);
          if (value == null) return false;
          return (0 <= value) && (value <= 255);
        })
        .map((e) => int.parse(e))
        .toList();
    _stringController.text = utf8.decode(_commandBytes);
    ref.read(widget.isChangedProvider.notifier).state = true;
  }

  @override
  Widget build(BuildContext context) {
    final titleDisplay = Text(widget.title);

    final inputTypeSwitcher = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: Durations.short4,
          child: switch (_inputType) {
            _InputType.string => const Text(
                'String',
                key: ValueKey('String'),
              ),
            _InputType.byteList => const Text(
                'Bytes',
                key: ValueKey('Bytes'),
              ),
          },
        ),
        Switch(
          value: _inputType == _InputType.string,
          onChanged: (value) => setState(() {
            _inputType = value ? _InputType.string : _InputType.byteList;
          }),
        ),
      ],
    );

    final header = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        titleDisplay,
        inputTypeSwitcher,
      ],
    );

    final stringField = TextFormField(
      controller: _stringController,
      onChanged: _updateFromString,
    );
    final bytesField = TextFormField(
      controller: _bytesController,
      onChanged: _updateFromBytesString,
    );

    final saveButton = Consumer(
      builder: (context, ref, child) => ElevatedButton(
        onPressed: ref.watch(widget.isChangedProvider) ? _saveCurrentBytes : null,
        child: child,
      ),
      child: const Text('Save'),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            header,
            switch (_inputType) {
              _InputType.string => stringField,
              _InputType.byteList => bytesField,
            },
            Center(
                child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: saveButton,
            )),
          ],
        ),
      ),
    );
  }
}

enum _InputType { string, byteList }
