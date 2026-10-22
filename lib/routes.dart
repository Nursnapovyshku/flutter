import 'package:flutter/material.dart';
import 'models/event.dart';
import 'screens/detail_screen.dart';
import 'screens/event_form.dart';

class Routes {
  static const home = '/';
  static const detail = '/detail';
  static const form = '/form';

  static Route<dynamic> generate(RouteSettings settings) {
    return switch (settings.name) {
      detail when settings.arguments is DetailArguments =>
        MaterialPageRoute<void>(
          settings: settings,
          builder: (_) =>
              DetailScreen(args: settings.arguments! as DetailArguments),
        ),
      form when settings.arguments is FormArguments => MaterialPageRoute<Event>(
        settings: settings,
        builder: (_) => EventForm(args: settings.arguments! as FormArguments),
      ),
      _ => unknown(settings),
    };
  }

  static Route<void> unknown(RouteSettings settings) => MaterialPageRoute<void>(
    settings: settings,
    builder: (_) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: const Center(child: Text('Not found')),
    ),
  );
}

class DetailArguments {
  const DetailArguments({
    required this.event,
    required this.profile,
    required this.onChange,
    required this.onDelete,
    required this.onProfileTab,
    required this.onEdit,
  });
  final Event event;
  final Profile profile;
  final ValueChanged<Event> onChange;
  final ValueChanged<String> onDelete;
  final VoidCallback onProfileTab;
  final Future<Event?> Function(Event) onEdit;
}

class FormArguments {
  const FormArguments({this.event});
  final Event? event;
}
