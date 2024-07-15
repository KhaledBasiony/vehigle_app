part of 'drawer.dart';

class _BytesToJsonEditor extends StatefulWidget {
  const _BytesToJsonEditor();

  @override
  State<_BytesToJsonEditor> createState() => _BytesToJsonEditorState();
}

class _BytesToJsonEditorState extends State<_BytesToJsonEditor> {
  late final List<_ByteJsonMapperEntry> _valueMappers;

  @override
  void initState() {
    super.initState();
    final existingValues = List<Map>.from(Db.instance.read<List>(cBytesToJson) ?? []);

    _valueMappers = List.generate(
      existingValues.length,
      (index) => _ByteJsonMapperEntry(
        key: UniqueKey(),
        isChangedProvider: _isChangedProviders[index],
        onDelete: _removeMapper,
        onSave: _updateMapper,
        initialValue: Map<String, dynamic>.from(existingValues[index]),
      ),
    );
  }

  void _removeMapper(Key entryKey) {
    final index = _valueMappers.indexWhere((element) => element.key == entryKey);
    final currentState = Db.instance.read<List>(cBytesToJson)!;
    Db.instance.write(cBytesToJson, currentState..removeAt(index));
    _isChangedProviders.removeAt(index);
    setState(() {
      _valueMappers.removeAt(index);
    });
  }

  void _insertMapper() {
    final currentState = Db.instance.read<List>(cBytesToJson) ?? [];
    Db.instance.write(cBytesToJson, currentState..add({}));
    _isChangedProviders.add(StateProvider((ref) => false));
    setState(() {
      _valueMappers.add(
        _ByteJsonMapperEntry(
          key: UniqueKey(),
          isChangedProvider: _isChangedProviders.last,
          onDelete: _removeMapper,
          onSave: _updateMapper,
        ),
      );
    });
  }

  void _reorderMappers(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final currentState = Db.instance.read<List>(cBytesToJson)!;
    final reorderedMapper = currentState.removeAt(oldIndex);
    Db.instance.write(
      cBytesToJson,
      currentState..insert(newIndex, reorderedMapper),
    );
    final currentProvider = _isChangedProviders.removeAt(oldIndex);
    _isChangedProviders.insert(newIndex, currentProvider);
    setState(() {
      final item = _valueMappers.removeAt(oldIndex);
      _valueMappers.insert(newIndex, item);
    });
  }

  void _updateMapper(Map newValue, _ByteJsonMapperEntry mapper) {
    final index = _valueMappers.indexOf(mapper);
    final currentState = Db.instance.read<List>(cBytesToJson)!;
    currentState[index] = newValue;
    print(newValue);
    Db.instance.write(cBytesToJson, currentState);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ordered Bytes Decoder'),
          centerTitle: true,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ReorderableListView(
              shrinkWrap: true,
              onReorder: _reorderMappers,
              children: _valueMappers,
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _insertMapper,
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }
}

class _ByteJsonMapperEntry extends ConsumerStatefulWidget {
  const _ByteJsonMapperEntry({
    required Key key,
    required this.isChangedProvider,
    required this.onDelete,
    required this.onSave,
    this.initialValue,
  }) : super(key: key);

  final Map<String, dynamic>? initialValue;
  final StateProvider<bool> isChangedProvider;
  final void Function(Key) onDelete;
  final void Function(Map<String, dynamic> value, _ByteJsonMapperEntry) onSave;

  @override
  ConsumerState<_ByteJsonMapperEntry> createState() => _ByteJsonMapperEntryState();
}

class _ByteJsonMapperEntryState extends ConsumerState<_ByteJsonMapperEntry> {
  late final BytesJsonMapperModel _mapper;
  late final TextEditingController _nameController;

  late final TextEditingController _delimiterController;

  @override
  void initState() {
    super.initState();

    _mapper = BytesJsonMapperModel.fromJson(widget.initialValue ?? {});
    _nameController = TextEditingController(text: _mapper.title);
    _delimiterController = TextEditingController(text: _mapper.delimiterBytes?.join(', '));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _delimiterController.dispose();
    super.dispose();
  }

  _saveCurrentBytes() {
    widget.onSave(_mapper.toJson(), widget);
    ref.read(widget.isChangedProvider.notifier).state = false;
  }

  void _updateBytesString(String value) {
    _mapper.delimiterBytes = value
        .trim()
        .split(RegExp(r',\s*'))
        .where((element) {
          final value = int.tryParse(element);
          if (value == null) return false;
          return (0 <= value) && (value <= 255);
        })
        .map((e) => int.parse(e))
        .toList();

    // if the result is not parse-able as a list of int disable save button.
    ref.read(widget.isChangedProvider.notifier).state = _mapper.delimiterBytes!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final titleField = RoundedTextField(
      text: 'Json Key Name',
      controller: _nameController,
      onChanged: (newValue) {
        ref.read(widget.isChangedProvider.notifier).state = newValue.isNotEmpty;
        _mapper.title = newValue;
      },
    );

    final inputTypeSwitcher = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: Durations.short4,
          child: switch (_mapper.dataLengthType) {
            DataLengthType.fixed => const Text(
                'Fixed',
                key: ValueKey('Fixed'),
              ),
            DataLengthType.variable => const Text(
                'Variable',
                key: ValueKey('Variable'),
              ),
          },
        ),
        Switch(
          value: _mapper.dataLengthType == DataLengthType.fixed,
          onChanged: (value) {
            ref.read(widget.isChangedProvider.notifier).state = true;
            setState(() {
              _mapper.dataLengthType = value ? DataLengthType.fixed : DataLengthType.variable;
            });
          },
        ),
      ],
    );

    final deleteButton = IconButton(
      onPressed: () => widget.onDelete(widget.key!),
      icon: const Icon(Icons.delete),
      color: AppTheme.instance.theme.colorScheme.error,
    );

    final header = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        deleteButton,
        Expanded(child: titleField),
        const SizedBox(width: 10),
        inputTypeSwitcher,
      ],
    );

    final dataTypeSelector = DropdownButtonFormField(
      decoration: const InputDecoration(labelText: 'Data Type'),
      value: _mapper.dataType,
      items: DataType.values
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e.name),
            ),
          )
          .toList(),
      onChanged: (newValue) {
        setState(() {
          _mapper.dataType = newValue!;
          _mapper.byteLength = newValue.validLenghts.first;
        });
        ref.read(widget.isChangedProvider.notifier).state = true;
      },
    );

    final dataLengthSelector = DropdownButtonFormField(
      decoration: const InputDecoration(labelText: 'No. of Bytes'),
      value: _mapper.byteLength,
      items: _mapper.dataType.validLenghts
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e.toString()),
            ),
          )
          .toList(),
      onChanged: (newValue) {
        _mapper.byteLength = newValue!;
        ref.read(widget.isChangedProvider.notifier).state = true;
      },
    );

    final endDelimiterField = RoundedTextField(
      text: 'End Delimiter Byte Sequence',
      controller: _delimiterController,
      onChanged: _updateBytesString,
    );

    final saveButton = Consumer(
      key: ValueKey('${widget.key}-Consumer'),
      builder: (context, ref, child) {
        // TODO: when isEnabled does not match provider, confusing logical errors could happen.
        final bool isEnabled = (!ref.watch(widget.isChangedProvider))
            ? false
            : (_nameController.text.isEmpty)
                ? false
                : (_mapper.dataLengthType == DataLengthType.fixed)
                    ? true
                    : (_mapper.delimiterBytes?.isEmpty ?? true)
                        ? false
                        : true;

        return ElevatedButton(
          onPressed: isEnabled ? _saveCurrentBytes : null,
          child: child,
        );
      },
      child: const Text('Save'),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 8.0, 35.0, 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            header,
            Row(
              children: [
                Expanded(child: dataTypeSelector),
                const SizedBox(width: 10),
                Expanded(child: dataLengthSelector),
              ],
            ),
            if (_mapper.dataLengthType == DataLengthType.variable)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15.0),
                child: endDelimiterField,
              ),
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

final _isChangedProviders = List.generate(
  (Db.instance.read(cBytesToJson) ?? []).length,
  (index) => StateProvider<bool>((ref) => false),
);
