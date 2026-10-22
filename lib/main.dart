import 'package:flutter/material.dart';
import 'data/seed.dart';
import 'models/event.dart';
import 'routes.dart';
import 'screens/list_tab.dart';
import 'screens/profile_tab.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _mode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    final seed = ColorScheme.fromSeed(seedColor: const Color(0xFF5568C9));
    return MaterialApp(
      title: 'Campus Events',
      theme: ThemeData(colorScheme: seed, useMaterial3: true),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed.primary,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _mode,
      home: HomeShell(
        themeMode: _mode,
        onThemeMode: (value) => setState(() => _mode = value),
      ),
      onGenerateRoute: Routes.generate,
      onUnknownRoute: Routes.unknown,
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.themeMode,
    required this.onThemeMode,
  });
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeMode;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  List<Event> _events = seedEvents();
  Profile _profile = const Profile.empty();
  int _tab = 0;

  void _change(Event event) => setState(() {
    final index = _events.indexWhere((element) => element.id == event.id);
    if (index == -1) {
      _events = [..._events, event];
    } else {
      _events = [
        for (var i = 0; i < _events.length; i++)
          if (i == index) event else _events[i],
      ];
    }
  });

  void _delete(String id) => setState(
    () => _events = _events.where((event) => event.id != id).toList(),
  );
  void _favourite(Event event) =>
      _change(event.copyWith(favourite: !event.favourite));

  void _saveProfile(Profile profile) {
    final oldName = _profile.name.trim();
    final newName = profile.name.trim();
    setState(() {
      if (oldName.isNotEmpty && oldName != newName) {
        _events = [
          for (final event in _events)
            if (event.contains(oldName))
              event.copyWith(
                attendees: [
                  for (final name in event.attendees)
                    if (name != oldName) name,
                  if (newName.isNotEmpty && !event.contains(newName)) newName,
                ],
              )
            else
              event,
        ];
      }
      _profile = profile;
    });
  }

  Future<Event?> _edit(Event? event) async {
    final result = await Navigator.of(
      context,
    ).pushNamed<Event>(Routes.form, arguments: FormArguments(event: event));
    if (!mounted) return null;
    if (result != null) _change(result);
    return result;
  }

  Future<void> _open(Event event) async {
    await Navigator.of(context).pushNamed<void>(
      Routes.detail,
      arguments: DetailArguments(
        event: event,
        profile: _profile,
        onChange: _change,
        onDelete: _delete,
        onProfileTab: () => setState(() => _tab = 2),
        onEdit: (event) => _edit(event),
      ),
    );
  }

  Future<void> _reset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset data?'),
        content: const Text(
          'Restore all sample events and clear your profile?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (!mounted || confirm != true) return;
    setState(() {
      _events = seedEvents();
      _profile = const Profile.empty();
      _tab = 0;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(switch (_tab) {
        0 => 'Campus events',
        1 => 'Favourites',
        _ => 'Profile',
      }),
    ),
    drawer: Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const ListTile(
              title: Text('Campus Events'),
              subtitle: Text('Flutter Lab 01'),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('About'),
                    content: const Text(
                      'Campus Events — offline demonstration app.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.restart_alt),
              title: const Text('Reset data'),
              onTap: () {
                Navigator.pop(context);
                _reset();
              },
            ),
          ],
        ),
      ),
    ),
    body: IndexedStack(
      index: _tab,
      children: [
        ListTab(
          events: _events,
          onOpen: _open,
          onFavourite: _favourite,
          onAdd: () => _edit(null),
        ),
        ListTab(
          events: _events,
          onOpen: _open,
          onFavourite: _favourite,
          onAdd: () => _edit(null),
          favouritesOnly: true,
        ),
        ProfileTab(
          profile: _profile,
          events: _events,
          themeMode: widget.themeMode,
          onChange: _saveProfile,
          onThemeMode: widget.onThemeMode,
        ),
      ],
    ),
    floatingActionButton: _tab == 2
        ? null
        : FloatingActionButton(
            onPressed: () => _edit(null),
            child: const Icon(Icons.add),
          ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (value) => setState(() => _tab = value),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.event), label: 'Events'),
        NavigationDestination(icon: Icon(Icons.favorite), label: 'Favourites'),
        NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
      ],
    ),
  );
}
