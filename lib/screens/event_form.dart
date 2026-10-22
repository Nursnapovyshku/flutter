import 'package:flutter/material.dart';
import '../models/event.dart';
import '../routes.dart';
import '../utils/format.dart';

class EventForm extends StatefulWidget {
  const EventForm({super.key, required this.args});
  final FormArguments args;
  @override
  State<EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<EventForm> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _place;
  late final TextEditingController _limit;
  late final TextEditingController _description;
  late final TextEditingController _dateText;
  late final TextEditingController _timeText;
  late final FocusNode _titleFocus;
  late final FocusNode _placeFocus;
  late final FocusNode _limitFocus;
  late final FocusNode _descriptionFocus;
  late EventCategory _category;
  late DateTime _date;
  late TimeOfDay _time;
  late bool _online;
  bool _saving = false;
  bool _dirty = false;
  bool _allowExit = false;
  bool _closing = false;
  bool _initializing = true;
  late final String _initialSnapshot;

  Event get _original => widget.args.event ?? Event.empty();
  bool get _editing => widget.args.event != null;

  @override
  void initState() {
    super.initState();
    final event = _original;
    _title = TextEditingController(text: event.title);
    _place = TextEditingController(text: event.place);
    _limit = TextEditingController(text: event.limit.toString());
    _description = TextEditingController(text: event.description ?? '');
    _dateText = TextEditingController();
    _timeText = TextEditingController();
    _titleFocus = FocusNode();
    _placeFocus = FocusNode();
    _limitFocus = FocusNode();
    _descriptionFocus = FocusNode();
    _category = event.category;
    _online = event.online;
    _date = event.starts;
    _time = TimeOfDay.fromDateTime(event.starts);
    _updateDateLabels();
    for (final controller in [_title, _place, _limit, _description]) {
      controller.addListener(_checkDirty);
    }
    _initialSnapshot = _snapshot();
    _initializing = false;
  }

  String _snapshot() =>
      '${_title.text}\u0000${_place.text}\u0000${_limit.text}\u0000${_description.text}\u0000${_category.name}\u0000$_online\u0000${_date.year}-${_date.month}-${_date.day}\u0000${_time.hour}:${_time.minute}';

  void _checkDirty() {
    if (_initializing) return;
    setState(() => _dirty = _snapshot() != _initialSnapshot);
  }

  void _updateDateLabels() {
    _dateText.text = '${_date.day}/${_date.month}/${_date.year}';
    _timeText.text =
        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
  }

  DateTime get _starts =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  @override
  void dispose() {
    for (final controller in [
      _title,
      _place,
      _limit,
      _description,
      _dateText,
      _timeText,
    ]) {
      controller.dispose();
    }
    for (final focus in [
      _titleFocus,
      _placeFocus,
      _limitFocus,
      _descriptionFocus,
    ]) {
      focus.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (!mounted || date == null) return;
    setState(() {
      _date = date;
      _updateDateLabels();
    });
    _checkDirty();
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: _time);
    if (!mounted || time == null) return;
    setState(() {
      _time = time;
      _updateDateLabels();
    });
    _checkDirty();
  }

  Future<bool> _discard() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text('Unsaved changes will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep editing'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _tryClose() async {
    if (_saving || _closing) return;
    _closing = true;
    final discard = !_dirty || await _discard();
    if (!mounted) return;
    if (!discard) {
      _closing = false;
      return;
    }
    setState(() => _allowExit = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _save() async {
    if (_saving || !_key.currentState!.validate()) return;
    final original = _original;
    final event = original.copyWith(
      id: _editing
          ? original.id
          : DateTime.now().microsecondsSinceEpoch.toString(),
      title: _title.text.trim(),
      place: _place.text.trim(),
      limit: int.parse(_limit.text),
      category: _category,
      starts: _starts,
      online: _online,
      description: _description.text.trim(),
      clearDescription: _description.text.trim().isEmpty,
    );
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _allowExit = true;
      _saving = false;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    Navigator.pop(context, event);
  }

  @override
  Widget build(BuildContext context) => PopScope<Event>(
    canPop: _allowExit || (!_dirty && !_saving),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _tryClose();
    },
    child: Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit event' : 'New event')),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Form(
          key: _key,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _title,
                focusNode: _titleFocus,
                maxLength: 60,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value?.trim().length ?? 0) < 3
                    ? 'At least 3 characters'
                    : null,
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<EventCategory>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final category in EventCategory.values)
                    DropdownMenuItem(
                      value: category,
                      child: Text(category.label),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _category = value);
                  _checkDirty();
                },
                validator: (value) =>
                    value == null ? 'Choose a category' : null,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Online event'),
                value: _online,
                onChanged: (value) {
                  setState(() => _online = value);
                  _checkDirty();
                },
              ),
              TextFormField(
                controller: _place,
                focusNode: _placeFocus,
                textInputAction: TextInputAction.next,
                keyboardType: _online
                    ? TextInputType.url
                    : TextInputType.streetAddress,
                decoration: InputDecoration(
                  labelText: _online ? 'Meeting URL' : 'Location',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Required';
                  if (_online) {
                    final uri = Uri.tryParse(text);
                    if (uri == null ||
                        (uri.scheme != 'https' && uri.scheme != 'http') ||
                        !uri.hasAuthority ||
                        uri.host.isEmpty ||
                        uri.host.contains(RegExp(r'\s'))) {
                      return 'Enter a valid http:// or https:// URL';
                    }
                  }
                  return null;
                },
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _limit,
                focusNode: _limitFocus,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Capacity',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final number = int.tryParse(value ?? '');
                  if (number == null || number < 1 || number > 500) {
                    return 'Enter 1–500';
                  }
                  if (number < _original.count) {
                    return 'Cannot be below ${_original.count} attendees';
                  }
                  return null;
                },
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dateText,
                      readOnly: true,
                      onTap: _pickDate,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                      ),
                      validator: (_) =>
                          _date.year < 2020 ? 'Choose date' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _timeText,
                      readOnly: true,
                      onTap: _pickTime,
                      decoration: const InputDecoration(
                        labelText: 'Time',
                        border: OutlineInputBorder(),
                      ),
                      validator: (_) =>
                          !_editing && !_starts.isAfter(DateTime.now())
                          ? 'Choose future time'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                focusNode: _descriptionFocus,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
              const SizedBox(height: 16),
              Text(
                'Scheduled: ${formatDate(_starts)}',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
