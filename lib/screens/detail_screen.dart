import 'dart:async';
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../routes.dart';
import '../utils/format.dart';
import '../widgets/empty_state.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.args});
  final DetailArguments args;
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Event _event;
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _event = widget.args.event;
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<bool> _confirm(String title) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _toggleAttendance() async {
    final name = widget.args.profile.name.trim();
    final joined = _event.contains(name);
    if (!joined && (_event.isFull || _event.isPast)) return;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter your name in Profile first'),
          action: SnackBarAction(
            label: 'Profile',
            onPressed: () {
              if (!mounted) return;
              widget.args.onProfileTab();
              Navigator.pop(context);
            },
          ),
        ),
      );
      return;
    }
    final allowed = await _confirm(
      joined ? 'Leave this event?' : 'Register for this event?',
    );
    if (!mounted || !allowed) return;
    final attendees = _event.attendees
        .where((person) => person != name)
        .toList();
    if (!joined) attendees.add(name);
    setState(() => _event = _event.copyWith(attendees: attendees));
    widget.args.onChange(_event);
  }

  Future<void> _edit() async {
    final result = await widget.args.onEdit(_event);
    if (!mounted || result == null) return;
    setState(() => _event = result);
  }

  Future<void> _delete() async {
    final confirmed = await _confirm('Delete event?');
    if (!mounted || !confirmed) return;
    widget.args.onDelete(_event.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final countdown = switch (_event.countdown(_now)) {
      Upcoming(:final remaining) => formatCountdown(remaining),
      Started(:final elapsed) => 'Started ${elapsed.inMinutes}m ago',
      Ended() => 'Ended',
    };
    final (:taken, :free) = _event.places;
    final name = widget.args.profile.name.trim();
    final isJoined = _event.contains(name);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event details'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') _edit();
              if (value == 'delete') _delete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Expanded(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        Image.asset(
                          'assets/images/campus.png',
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          top: 12,
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            spacing: 8,
                            children: [
                              Chip(
                                avatar: Icon(_event.category.icon),
                                label: Text(_event.category.label),
                              ),
                              Chip(label: Text(countdown)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _event.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                ],
                body: Column(
                  children: [
                    TabBar(
                      tabs: [
                        const Tab(text: 'About'),
                        Tab(text: 'Names ($taken)'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              ListTile(
                                leading: const Icon(Icons.schedule),
                                title: Text(formatDate(_event.starts)),
                              ),
                              ListTile(
                                leading: Icon(
                                  _event.online
                                      ? Icons.link
                                      : Icons.location_on,
                                ),
                                title: Text(_event.place),
                              ),
                              ListTile(
                                leading: const Icon(Icons.people),
                                title: Text(
                                  '$taken registered · $free free places',
                                ),
                              ),
                              if (_event.description
                                  case final String description)
                                ListTile(
                                  leading: const Icon(Icons.description),
                                  title: Text(description),
                                ),
                            ],
                          ),
                          _event.attendees.isEmpty
                              ? const EmptyState(
                                  icon: Icons.people_outline,
                                  message: 'Nobody registered yet',
                                )
                              : ListView(
                                  children: [
                                    for (final person in _event.attendees)
                                      ListTile(
                                        leading: Icon(
                                          Icons.person,
                                          color: person == name
                                              ? scheme.primary
                                              : null,
                                        ),
                                        title: Text(
                                          person == name
                                              ? '$person (You)'
                                              : person,
                                          style: person == name
                                              ? const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                )
                                              : null,
                                        ),
                                      ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        !isJoined &&
                            (_event.isFull || !_event.starts.isAfter(_now))
                        ? null
                        : _toggleAttendance,
                    child: Text(
                      isJoined
                          ? 'Leave event'
                          : !_event.starts.isAfter(_now)
                          ? 'Registration closed'
                          : 'Register',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
