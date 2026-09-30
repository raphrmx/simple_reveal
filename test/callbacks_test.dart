import 'package:flutter_test/flutter_test.dart';
import 'package:simple_reveal/simple_reveal.dart';

import 'helpers.dart';

void main() {
  final List<String> events = <String>[];
  setUp(events.clear);

  SimpleReveal reporting({bool once = true, ScrubProperties? scrub}) =>
      SimpleReveal(
        once: once,
        scrub: scrub,
        onReveal: () => events.add('reveal'),
        onHide: () => events.add('hide'),
        child: testBlock,
      );

  testWidgets('reports a block seen, once', (WidgetTester tester) async {
    await tester.pumpWidget(app(listWith(reporting())));
    await tester.pumpAndSettle();
    expect(events, isEmpty);

    await scrollTo(tester, 300);
    await tester.pumpAndSettle();
    await scrollTo(tester, 1000);
    await scrollTo(tester, 300);
    await tester.pumpAndSettle();

    expect(events, <String>['reveal']);
  });

  testWidgets('reports each coming and going without once', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app(listWith(reporting(once: false))));
    await scrollTo(tester, 300);
    await scrollTo(tester, 1000);
    await scrollTo(tester, 300);

    expect(events, <String>['reveal', 'hide', 'reveal']);
  });

  testWidgets('reports a scrubbed block coming in and scrolled back out', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      app(listWith(reporting(scrub: const ScrubProperties()))),
    );
    await scrollTo(tester, 150);
    await scrollTo(tester, 400);
    await scrollTo(tester, 0);

    expect(events, <String>['reveal', 'hide']);
  });

  testWidgets('still reports a block seen under reduced motion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app(reducedMotion(listWith(reporting()))));
    await tester.pump();
    expect(events, isEmpty);

    await scrollTo(tester, 300);
    expect(events, <String>['reveal']);
  });

  testWidgets('reports nothing when not enabled', (WidgetTester tester) async {
    await tester.pumpWidget(
      app(
        listWith(
          SimpleReveal(
            enabled: false,
            onReveal: () => events.add('reveal'),
            child: testBlock,
          ),
          top: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(events, isEmpty);
    expect(stillToRise(tester), 0);
  });
}
