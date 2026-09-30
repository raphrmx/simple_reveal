import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_reveal/simple_reveal.dart';

import 'helpers.dart';

void main() {
  testWidgets('keeps a hidden block in the semantics tree', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    // On screen, but held at an opacity of 0 by its delay.
    await tester.pumpWidget(
      app(
        const Center(
          child: SimpleReveal(
            delay: Duration(seconds: 2),
            child: Text('Chapter one'),
          ),
        ),
      ),
    );
    await startClock(tester);
    await tester.pump(const Duration(seconds: 1));
    // Unseen, and so out of hit testing, which only an opacity of 0 does.
    expect(find.text('Chapter one').hitTestable(), findsNothing);

    expect(find.bySemanticsLabel('Chapter one'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('reads the reading direction for a slide from the start', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      app(
        const Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: SimpleReveal(
              fade: null,
              slide: SlideProperties.fromStart(60),
              child: testBlock,
            ),
          ),
        ),
      ),
    );

    expect(drawnOffset(tester), const Offset(60, 0));
  });

  testWidgets('draws in place when reduced motion comes on mid-way', (
    WidgetTester tester,
  ) async {
    bool reduce = false;
    late StateSetter setOuter;
    await tester.pumpWidget(
      app(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            setOuter = setState;
            final Widget page = listWith(timedBlock(), top: 0);
            return reduce ? reducedMotion(page) : page;
          },
        ),
      ),
    );
    await startClock(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(stillToRise(tester), 70);

    setOuter(() => reduce = true);
    await tester.pump();
    expect(stillToRise(tester), 0);
  });
}
