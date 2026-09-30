import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_reveal/simple_reveal.dart';

import 'helpers.dart';

void main() {
  // The viewport is 600 high and 800 wide, and each scrub here is done half
  // way across it: 300 of travel down, 400 sideways.

  group('down a list', () {
    testWidgets('follows the leading edge up the viewport', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(app(listWith(scrubbedBlock())));

      // Just coming in at the bottom.
      await scrollTo(tester, 100);
      expect(stillToRise(tester), 100);

      // Its top 150 up.
      await scrollTo(tester, 250);
      expect(stillToRise(tester), 50);

      // Its top 300 up, done.
      await scrollTo(tester, 400);
      expect(stillToRise(tester), 0);
    });

    testWidgets('runs backwards as the list is scrolled back', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(app(listWith(scrubbedBlock())));
      await scrollTo(tester, 400);
      await scrollTo(tester, 175);

      expect(stillToRise(tester), 75);
    });

    testWidgets('stays in place on the way out without a mirror', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(app(listWith(scrubbedBlock())));
      await scrollTo(tester, 780);

      expect(stillToRise(tester), 0);
    });

    testWidgets('hides again on the way out with a mirror', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(app(listWith(scrubbedBlock(mirror: true))));

      // Its bottom 300 from the top: still in place.
      await scrollTo(tester, 500);
      expect(stillToRise(tester), 0);

      // Its bottom 150 from the top: half way out.
      await scrollTo(tester, 650);
      expect(stillToRise(tester), 50);
    });

    testWidgets('comes in from the top of a reversed list', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(app(listWith(scrubbedBlock(), reverse: true)));

      // Its bottom 150 down from the top.
      await scrollTo(tester, 250);
      expect(stillToRise(tester), 50);
    });

    testWidgets('eases the progress by its curve', (WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          listWith(
            const SimpleReveal(
              fade: null,
              slide: rise,
              scrub: ScrubProperties(reach: 0.5, curve: Curves.easeIn),
              child: testBlock,
            ),
          ),
        ),
      );
      await scrollTo(tester, 250);

      final double left = 100 * (1 - Curves.easeIn.transform(0.5));
      expect(stillToRise(tester), closeTo(left, 1e-9));
    });
  });

  testWidgets('follows the leading edge along a sideways list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app(rowWith(scrubbedBlock())));

    // Its leading edge 200 in, of the 400 it takes.
    await scrollTo(tester, 300);
    expect(stillToRise(tester), 50);
  });

  testWidgets('follows the page around a carousel when told to', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      app(
        listWith(
          SizedBox(
            width: 800,
            height: 100,
            child: rowWith(scrubbedBlock(scrollAxis: Axis.vertical), start: 0),
          ),
        ),
      ),
    );
    await scrollTo(tester, 250);

    expect(stillToRise(tester), 50);
  });

  testWidgets('draws the block in place outside a scrollable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app(Center(child: scrubbedBlock())));
    expect(stillToRise(tester), 0);
  });

  testWidgets('draws the block in place under reduced motion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app(reducedMotion(listWith(scrubbedBlock()))));
    await scrollTo(tester, 150);

    expect(stillToRise(tester), 0);
  });

  testWidgets('does not rebuild the content as it scrolls', (
    WidgetTester tester,
  ) async {
    int builds = 0;
    await tester.pumpWidget(
      app(
        listWith(
          scrubbedBlock(
            child: Builder(
              builder: (BuildContext context) {
                builds++;
                return testBlock;
              },
            ),
          ),
        ),
      ),
    );
    final int before = builds;
    for (double offset = 100; offset <= 400; offset += 50) {
      await scrollTo(tester, offset);
    }

    expect(builds, before);
  });

  testWidgets('turns from timed to scrubbed in place', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app(listWith(timedBlock())));
    await scrollTo(tester, 250);
    await tester.pumpWidget(app(listWith(scrubbedBlock())));

    expect(stillToRise(tester), 50);
  });

  testWidgets('turns from scrubbed to timed and plays', (
    WidgetTester tester,
  ) async {
    Widget page({required bool scrubbed}) => app(
          listWith(
            SimpleReveal(
              fade: null,
              slide: rise,
              scrub: scrubbed ? const ScrubProperties() : null,
              onReveal: () {},
              child: testBlock,
            ),
            top: 100,
          ),
        );
    await tester.pumpWidget(page(scrubbed: true));
    await tester.pump();

    await tester.pumpWidget(page(scrubbed: false));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(stillToRise(tester), 0);
  });

  testWidgets('says it hides a block before revealing it the other way', (
    WidgetTester tester,
  ) async {
    final List<String> calls = <String>[];
    Widget page({required bool scrubbed}) => app(
          listWith(
            SimpleReveal(
              scrub: scrubbed ? const ScrubProperties() : null,
              onReveal: () => calls.add('reveal'),
              onHide: () => calls.add('hide'),
              child: testBlock,
            ),
            top: 0,
          ),
        );
    await tester.pumpWidget(page(scrubbed: false));
    await tester.pump();
    await tester.pumpWidget(page(scrubbed: true));
    await tester.pump();

    expect(calls, <String>['reveal', 'hide', 'reveal']);
  });

  testWidgets('finishes a block the end of the list stops short of its reach', (
    WidgetTester tester,
  ) async {
    // The list ends 100 below the block: scrolled to its end, the block only
    // comes 400 up a viewport of 600, short of the 300 its reach asks for.
    await tester.pumpWidget(
      app(
        ListView(
          children: <Widget>[
            const SizedBox(height: 1000),
            Align(alignment: Alignment.topLeft, child: scrubbedBlock()),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );

    await scrollTo(tester, 500);
    expect(stillToRise(tester), closeTo(50, 0.01));
    await scrollTo(tester, 600);
    expect(stillToRise(tester), 0);
  });

  testWidgets('shows a mirrored block at the top of a list whole', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app(listWith(scrubbedBlock(mirror: true), top: 0)));
    await tester.pump();
    expect(stillToRise(tester), 0);

    // Hides from there as it leaves, half way when half of it has gone.
    await scrollTo(tester, 50);
    expect(stillToRise(tester), closeTo(50, 0.01));
  });
}
