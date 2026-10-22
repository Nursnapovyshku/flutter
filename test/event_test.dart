import 'package:campus_events_lab/data/seed.dart';
import 'package:campus_events_lab/models/event.dart';
import 'package:campus_events_lab/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

Event makeEvent({List<String> attendees = const ['Aruzhan'], int limit = 3}) =>
    Event(
      id: 'test-event',
      title: 'Test event',
      category: EventCategory.science,
      starts: DateTime(2030, 1, 2, 12),
      place: 'Room 101',
      limit: limit,
      attendees: attendees,
      online: false,
      description: 'Description',
      favourite: true,
    );

void main() {
  test('attendees are copied and exposed as an immutable collection', () {
    final attendees = ['Aruzhan'];
    final event = makeEvent(attendees: attendees);
    attendees.add('Dias');
    expect(event.attendees, ['Aruzhan']);
    expect(() => event.attendees.add('Miras'), throwsUnsupportedError);
    expect(event.count, 1);
    expect(event.places, (taken: 1, free: 2));
    expect(event.contains(' Aruzhan '), isTrue);
    expect(event.contains('   '), isFalse);
    expect(event.isFull, isFalse);
    expect(event.copyWith(limit: 1).isFull, isTrue);
  });

  test(
    'copyWith preserves identity and attendees while allowing description removal',
    () {
      final original = makeEvent();
      final updated = original.copyWith(
        title: 'Updated',
        clearDescription: true,
      );
      expect(updated.id, original.id);
      expect(updated.attendees, original.attendees);
      expect(updated.favourite, isTrue);
      expect(updated.title, 'Updated');
      expect(updated.description, isNull);
      expect(original.title, 'Test event');
      expect(original.description, 'Description');
    },
  );

  test('countdown changes at the start and one-hour end boundaries', () {
    final event = makeEvent();
    final before = event.countdown(
      event.starts.subtract(const Duration(minutes: 1)),
    );
    expect(before, isA<Upcoming>());
    expect((before as Upcoming).remaining, const Duration(minutes: 1));
    final atStart = event.countdown(event.starts);
    expect(atStart, isA<Started>());
    expect((atStart as Started).elapsed, Duration.zero);
    expect(
      event.countdown(event.starts.add(const Duration(minutes: 59))),
      isA<Started>(),
    );
    expect(
      event.countdown(event.starts.add(const Duration(hours: 1))),
      isA<Ended>(),
    );
  });

  test(
    'sample data has unique IDs, all categories and full and past examples',
    () {
      final events = seedEvents();
      expect(events.length, 12);
      expect(events.map((event) => event.id).toSet().length, events.length);
      expect(
        events.map((event) => event.category).toSet(),
        EventCategory.values.toSet(),
      );
      expect(events.any((event) => event.isFull), isTrue);
      expect(events.any((event) => event.isPast), isTrue);
      expect(events.any((event) => event.online), isTrue);
    },
  );

  test('date and countdown formatting use readable padded values', () {
    expect(formatDate(DateTime(2030, 1, 2, 9, 5)), '2 Jan, 09:05');
    expect(formatCountdown(const Duration(days: 2, hours: 3)), '2d left');
    expect(formatCountdown(const Duration(hours: 3, minutes: 5)), '3h left');
    expect(formatCountdown(const Duration(minutes: 5)), '5m left');
    expect(formatCountdown(Duration.zero), '0m left');
  });
}
