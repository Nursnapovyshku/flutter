import 'package:flutter/material.dart';

enum EventCategory {
  technology('Technology', Icons.computer),
  sports('Sports', Icons.sports_basketball),
  science('Science', Icons.science),
  arts('Arts', Icons.palette),
  community('Community', Icons.groups);

  const EventCategory(this.label, this.icon);
  final String label;
  final IconData icon;

  Color color(ColorScheme scheme) => switch (this) {
    EventCategory.technology => scheme.primary,
    EventCategory.sports => scheme.secondary,
    EventCategory.science => scheme.tertiary,
    EventCategory.arts => scheme.error,
    EventCategory.community => scheme.onSurfaceVariant,
  };
}

sealed class Countdown {
  const Countdown();
}

final class Upcoming extends Countdown {
  const Upcoming(this.remaining);
  final Duration remaining;
}

final class Started extends Countdown {
  const Started(this.elapsed);
  final Duration elapsed;
}

final class Ended extends Countdown {
  const Ended();
}

class Event {
  Event({
    required this.id,
    required this.title,
    required this.category,
    required this.starts,
    required this.place,
    required this.limit,
    required List<String> attendees,
    required this.online,
    required this.description,
    required this.favourite,
  }) : _attendees = List.unmodifiable(attendees);

  Event.empty()
    : id = '',
      title = '',
      category = EventCategory.technology,
      starts = DateTime.now().add(const Duration(days: 1)),
      place = '',
      limit = 20,
      _attendees = const [],
      online = false,
      description = null,
      favourite = false;

  final String id;
  final String title;
  final EventCategory category;
  final DateTime starts;
  final String place;
  final int limit;
  final List<String> _attendees;
  final bool online;
  final String? description;
  final bool favourite;

  List<String> get attendees => List.unmodifiable(_attendees);
  int get count => _attendees.length;
  int get freePlaces => limit - count;
  bool get isFull => freePlaces <= 0;
  bool get isPast => starts.isBefore(DateTime.now());
  bool contains(String name) =>
      name.trim().isNotEmpty && _attendees.contains(name.trim());
  ({int taken, int free}) get places => (taken: count, free: freePlaces);

  Countdown countdown(DateTime now) {
    final difference = starts.difference(now);
    if (difference > Duration.zero) return Upcoming(difference);
    final elapsed = now.difference(starts);
    if (elapsed < const Duration(hours: 1)) return Started(elapsed);
    return const Ended();
  }

  Event copyWith({
    String? id,
    String? title,
    EventCategory? category,
    DateTime? starts,
    String? place,
    int? limit,
    List<String>? attendees,
    bool? online,
    String? description,
    bool clearDescription = false,
    bool? favourite,
  }) => Event(
    id: id ?? this.id,
    title: title ?? this.title,
    category: category ?? this.category,
    starts: starts ?? this.starts,
    place: place ?? this.place,
    limit: limit ?? this.limit,
    attendees: attendees ?? _attendees,
    online: online ?? this.online,
    description: clearDescription ? null : description ?? this.description,
    favourite: favourite ?? this.favourite,
  );
}

class Profile {
  const Profile({required this.name, required this.group});
  const Profile.empty() : name = '', group = '';

  final String name;
  final String group;

  Profile copyWith({String? name, String? group}) =>
      Profile(name: name ?? this.name, group: group ?? this.group);
}
