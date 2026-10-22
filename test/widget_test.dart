import 'package:campus_events_lab/main.dart';
import 'package:campus_events_lab/widgets/event_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder input(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Finder eventCard(String title) => find.widgetWithText(EventCard, title);

Future<void> pumpApp(
  WidgetTester tester, {
  Size size = const Size(800, 1000),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();
}

Future<void> navigateTo(WidgetTester tester, int destination) async {
  await tester.tap(find.byType(NavigationDestination).at(destination));
  await tester.pumpAndSettle();
}

Future<void> search(WidgetTester tester, String query) async {
  await tester.enterText(input('Search events'), query);
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> saveEvent(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Save'));
  await tester.tap(find.text('Save'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('search, categories, past events and clearing filters work', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Campus events'), findsOneWidget);
    expect(eventCard('Running Club'), findsOneWidget);

    await search(tester, '  RUNNING  ');
    expect(eventCard('Running Club'), findsOneWidget);
    expect(find.byType(EventCard), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Technology'));
    await tester.pumpAndSettle();
    expect(find.text('No matching events'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(input('Search events')).controller!.text,
      '',
    );
    await search(tester, 'Last Week Science Talk');
    expect(find.byType(EventCard), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Include past'));
    await tester.pumpAndSettle();
    expect(find.text('No matching events'), findsOneWidget);
  });

  testWidgets('favourites stay in sync between both event tabs', (
    tester,
  ) async {
    await pumpApp(tester);
    await search(tester, 'Running Club');
    await tester.tap(find.byTooltip('Favourite'));
    await tester.pumpAndSettle();
    await navigateTo(tester, 1);
    expect(eventCard('Running Club'), findsOneWidget);

    await tester.tap(find.byTooltip('Favourite'));
    await tester.pumpAndSettle();
    expect(find.text('No matching favourites'), findsOneWidget);

    await navigateTo(tester, 0);
    expect(eventCard('Running Club'), findsOneWidget);
    final card = tester.widget<EventCard>(find.byType(EventCard));
    expect(card.event.favourite, isFalse);
  });

  testWidgets('new event validates fields and saves to the event list', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(input('Title'), 'x');
    await tester.enterText(input('Capacity'), '0');
    await tapVisible(tester, find.text('Save'));
    expect(find.text('At least 3 characters'), findsOneWidget);
    expect(find.text('Required'), findsOneWidget);
    expect(find.text('New event'), findsOneWidget);

    await tester.enterText(input('Title'), 'Campus Testing Meetup');
    await tester.enterText(input('Location'), 'Room 101');
    await tester.enterText(input('Capacity'), '12');
    await saveEvent(tester);
    expect(find.text('Campus events'), findsOneWidget);
    await search(tester, 'Campus Testing Meetup');
    expect(find.byType(EventCard), findsOneWidget);
    final event = tester.widget<EventCard>(find.byType(EventCard)).event;
    expect(event.place, 'Room 101');
    expect(event.limit, 12);
    expect(event.starts.isAfter(DateTime.now()), isTrue);
  });

  testWidgets('online events reject an invalid meeting URL', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(input('Title'), 'Online Testing Meetup');
    await tester.tap(find.widgetWithText(SwitchListTile, 'Online event'));
    await tester.pumpAndSettle();
    for (final url in ['not-a-url', 'javascript://example.com', 'https://']) {
      await tester.enterText(input('Meeting URL'), url);
      await tapVisible(tester, find.text('Save'));
      final form = tester.state<FormFieldState<String>>(
        find.ancestor(
          of: input('Meeting URL'),
          matching: find.byType(TextFormField),
        ),
      );
      expect(form.hasError, isTrue, reason: 'Invalid meeting URL: $url');
      expect(find.text('New event'), findsOneWidget);
    }
    await tester.enterText(
      input('Meeting URL'),
      'https://meet.example.com/testing',
    );
    await saveEvent(tester);
    await search(tester, 'Online Testing Meetup');
    final event = tester.widget<EventCard>(find.byType(EventCard)).event;
    expect(event.online, isTrue);
    expect(event.place, 'https://meet.example.com/testing');
  });

  testWidgets('back navigation keeps or discards unsaved changes', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('Campus events'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(input('Title'), 'Unsaved meetup');
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(input('Title')).controller!.text,
      'Unsaved meetup',
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Campus events'), findsOneWidget);
    await search(tester, 'Unsaved meetup');
    expect(find.text('No matching events'), findsOneWidget);
  });

  testWidgets('profile is required for registration and membership updates', (
    tester,
  ) async {
    await pumpApp(tester);
    await search(tester, 'Running Club');
    await tester.tap(eventCard('Running Club'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your name in Profile first'), findsOneWidget);
    await tester.tap(find.widgetWithText(SnackBarAction, 'Profile'));
    await tester.pumpAndSettle();
    await tester.enterText(input('Your name'), 'Test Student');
    await tester.enterText(input('Group'), 'SE-01');
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(find.text('You are on 0 lists'), findsOneWidget);

    await navigateTo(tester, 0);
    await tester.tap(eventCard('Running Club'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Leave event'), findsOneWidget);
    await tester.tap(find.text('Names (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Test Student (You)'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await navigateTo(tester, 2);
    expect(find.text('You are on 1 lists'), findsOneWidget);
    await tester.enterText(input('Your name'), 'Renamed Student');
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(find.text('You are on 1 lists'), findsOneWidget);
    await navigateTo(tester, 0);
    await tester.tap(eventCard('Running Club'));
    await tester.pumpAndSettle();
    expect(find.text('Leave event'), findsOneWidget);
    await tester.tap(find.text('Names (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Renamed Student (You)'), findsOneWidget);
    expect(find.text('Test Student'), findsNothing);
    await tester.tap(find.text('Leave event'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Names (0)'), findsOneWidget);
  });

  testWidgets('full events disable registration', (tester) async {
    await pumpApp(tester);
    await search(tester, 'Campus Basketball Finals');
    await tester.tap(eventCard('Campus Basketball Finals'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Register'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('past events remain viewable but disable registration', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.widgetWithText(FilterChip, 'Include past'));
    await tester.pumpAndSettle();
    await search(tester, 'Last Week Science Talk');
    await tester.tap(eventCard('Last Week Science Talk'));
    await tester.pumpAndSettle();
    expect(find.text('Ended'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Registration closed'),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('editing and deleting an event update the home list', (
    tester,
  ) async {
    await pumpApp(tester);
    await search(tester, 'Running Club');
    await tester.tap(eventCard('Running Club'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(input('Title'), 'Running Club Updated');
    await saveEvent(tester);
    expect(find.text('Event details'), findsOneWidget);
    expect(find.text('Running Club Updated'), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Running Club Updated'), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Campus events'), findsOneWidget);
    expect(find.text('No matching events'), findsOneWidget);
  });

  testWidgets('theme selection and reset confirmation update shared state', (
    tester,
  ) async {
    await pumpApp(tester);
    await navigateTo(tester, 2);
    await tester.enterText(input('Your name'), 'Test Student');
    await tester.enterText(input('Group'), 'SE-01');
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Dark'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Dark'))
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'System'))
          .selected,
      isFalse,
    );

    await navigateTo(tester, 0);
    await search(tester, 'Running Club');
    await tester.tap(find.byTooltip('Favourite'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<EventCard>(eventCard('Running Club')).event.favourite,
      isTrue,
    );

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    await search(tester, 'Running Club');
    expect(
      tester.widget<EventCard>(eventCard('Running Club')).event.favourite,
      isFalse,
    );
    await navigateTo(tester, 2);
    expect(
      tester.widget<TextField>(input('Your name')).controller!.text,
      isEmpty,
    );
    expect(tester.widget<TextField>(input('Group')).controller!.text, isEmpty);
    expect(find.text('You are on 0 lists'), findsOneWidget);
  });

  testWidgets(
    'details keep the registration action visible in short landscape',
    (tester) async {
      await pumpApp(tester);
      await search(tester, 'Flutter and Dart Hackathon');
      await tester.tap(find.byType(EventCard));
      await tester.pumpAndSettle();
      await tester.binding.setSurfaceSize(const Size(640, 320));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Event details'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Register').hitTestable(),
        findsOneWidget,
      );
    },
  );

  for (final size in [const Size(320, 640), const Size(800, 1000)]) {
    testWidgets('event list fits ${size.width.toInt()}px with large text', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(tester, size: size);
      expect(tester.takeException(), isNull);
      await search(tester, 'Flutter and Dart Hackathon');
      expect(find.byType(EventCard), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(EventCard));
      await tester.pumpAndSettle();
      expect(find.text('Event details'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
