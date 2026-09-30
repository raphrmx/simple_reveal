import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_reveal_example/main.dart';

/// Every screen the menu opens, in the order it lists them.
const List<String> _entries = <String>[
  'From either side',
  'Every effect',
  'One after the other',
  'Pieces one after the other',
  'Tints and curtains',
  'From code',
  'Every time it comes back',
  'A carousel in a page',
  'Five hundred rows',
  'Scrubbed',
  'In and out again',
];

/// Opens [entry] from the menu, scrolls it, and comes back.
Future<void> _visit(WidgetTester tester, String entry) async {
  await tester.scrollUntilVisible(
    find.text(entry),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text(entry));
  await tester.pumpAndSettle();

  final Finder scrollable = find.byType(Scrollable).first;
  for (int i = 0; i < 4; i++) {
    await tester.drag(scrollable, const Offset(0, -500));
    await tester.pumpAndSettle();
  }
  await tester.drag(scrollable, const Offset(0, 900));
  await tester.pumpAndSettle();

  await tester.tap(find.byIcon(Icons.arrow_back));
  await tester.pumpAndSettle();
}

void main() {
  for (final bool reduce in <bool>[false, true]) {
    testWidgets(
      'opens and scrolls every screen${reduce ? ' under reduced motion' : ''}',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1800);
        tester.view.devicePixelRatio = 1.5;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(const ExampleApp());
        if (reduce) {
          await tester.tap(find.byType(Switch));
          await tester.pumpAndSettle();
        }

        for (final String entry in _entries) {
          await _visit(tester, entry);
        }
        expect(find.text(_entries.last), findsOneWidget);
      },
    );
  }
}
