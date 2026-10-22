import 'package:flutter/material.dart';
import '../models/event.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({
    super.key,
    required this.profile,
    required this.events,
    required this.themeMode,
    required this.onChange,
    required this.onThemeMode,
  });
  final Profile profile;
  final List<Event> events;
  final ThemeMode themeMode;
  final ValueChanged<Profile> onChange;
  final ValueChanged<ThemeMode> onThemeMode;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late final TextEditingController _name;
  late final TextEditingController _group;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.name);
    _group = TextEditingController(text: widget.profile.group);
  }

  @override
  void didUpdateWidget(covariant ProfileTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.name != widget.profile.name &&
        _name.text != widget.profile.name) {
      _name.text = widget.profile.name;
    }
    if (oldWidget.profile.group != widget.profile.group &&
        _group.text != widget.profile.group) {
      _group.text = widget.profile.group;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _group.dispose();
    super.dispose();
  }

  void _save() {
    final group = _group.text.trim();
    if (group.isNotEmpty && !RegExp(r'^[a-zA-Z0-9 -]{2,20}$').hasMatch(group)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group: 2–20 letters, digits, spaces or hyphens'),
        ),
      );
      return;
    }
    widget.onChange(
      widget.profile.copyWith(name: _name.text.trim(), group: group),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memberships = widget.events
        .where((event) => event.contains(widget.profile.name))
        .length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextFormField(
          controller: _name,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Your name'),
          onFieldSubmitted: (_) => _save(),
        ),
        TextFormField(
          controller: _group,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: 'Group'),
          validator: (value) =>
              value != null &&
                  value.isNotEmpty &&
                  !RegExp(r'^[a-zA-Z0-9 -]{2,20}$').hasMatch(value)
              ? 'Invalid group'
              : null,
          onFieldSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: _save, child: const Text('Save profile')),
        const SizedBox(height: 20),
        Text(
          'You are on $memberships lists',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
        Wrap(
          spacing: 8,
          children: [
            for (final mode in ThemeMode.values)
              ChoiceChip(
                label: Text(switch (mode) {
                  ThemeMode.system => 'System',
                  ThemeMode.light => 'Light',
                  ThemeMode.dark => 'Dark',
                }),
                selected: widget.themeMode == mode,
                onSelected: (_) => widget.onThemeMode(mode),
              ),
          ],
        ),
      ],
    );
  }
}
