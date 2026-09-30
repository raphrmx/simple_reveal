import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_reveal/simple_reveal.dart';

import 'helpers.dart';

void main() {
  group('a block in view from the start', () {
    testWidgets('is hidden on the first frame, then revealed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(app(listWith(timedBlock(), top: 0)));
      expect(stillToRise(tester), 100);

      await startClock(tester);
      await tester.pump(const Duration(milliseconds: 250));
      expect(stillToRise(tester), 75);

      await tester.pump(const Duration(milliseconds: 750));
      expect(stillToRise(tester), 0);
    });

    testWidgets('is revealed outside a scrollable too', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(app(Center(child: timedBlock())));
      await startClock(tester);
      await tester.pump(const Duration(seconds: 1));

      expect(stillToRise(tester), 0);
    });

    testWidgets('is not revealed outside a scrollable when off the screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          Stack(
            children: <Widget>[
              Positioned(left: 0, top: 700, child: timedBlock()),
            ],
          ),
        ),
      );
      await startClock(tester);
      await tester.pump(const Duration(seconds: 1));

      expect(stillToRise(tester), 100);
    });
  });

  group('a block below the fold', () {
    testWidgets('waits, however long, until it is scrolled in', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(app(listWith(timedBlock())));
      await tester.pump(const Duration(seconds: 3));
      expect(stillToRise(tester), 100);

      await scrollTo(tester, 300);
      await startClock(tester);
      await tester.pump(const Duration(milliseconds: 500));
      expect(stillToRise(tester), 50);

      await tester.pump(const Duration(milliseconds: 500));
      expect(stillToRise(tester), 0);
    });

    testWidgets('waits for the threshold', (WidgetTester tester) async {
      await tester.pumpWidget(app(listWith(timedBlock(threshold: 0.5))));

      // 40 of its 100 in the viewport, short of half.
      await scrollTo(tester, 140);
      await startClock(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(stillToRise(tester), 100);

      // 60 of them.
      await scrollTo(tester, 160);
      await startClock(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(stillToRise(tester), 0);
    });

    testWidgets('starts on its first pixel with a threshold of 0', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(app(listWith(timedBlock(threshold: 0))));

      await scrollTo(tester, 101);
      await startClock(tester);
      await tester.pump(const Duration(seconds: 1));

      expect(stillToRise(tester), 0);
    });

    testWidgets('is measured where it is laid out, not where it is drawn', (
      WidgetTester tester,
    ) async {
      // Its place is in view, 100 above the bottom; drawn 100 lower, it is
      // not, and it is revealed all the same.
      await tester.pumpWidget(app(listWith(timedBlock(), top: 400)));
      await startClock(tester);
      await tester.pump(const Duration(seconds: 1));

      expect(stillToRise(tester), 0);
    });
  });

  group('delay', () {
    testWidgets('holds the block before the reveal starts', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          listWith(
            timedBlock(delay: const Duration(milliseconds: 500)),
            top: 0,
          ),
        ),
      );
      await startClock(tester);

      await tester.pump(const Duration(milliseconds: 400));
      expect(stillToRise(tester), 100);

      await tester.pump(const Duration(milliseconds: 600));
      expect(stillToRise(tester), 50);

      await tester.pump(const Duration(milliseconds: 500));
      expect(stillToRise(tester), 0);
    });

    testWidgets('works with a zero duration', (WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          listWith(
            const SimpleReveal(
              fade: null,
              slide: rise,
              duration: Duration.zero,
              delay: Duration(milliseconds: 200),
              child: testBlock,
            ),
            top: 0,
          ),
        ),
      );
      await startClock(tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(stillToRise(tester), 100);

      await tester.pump(const Duration(milliseconds: 100));
      expect(stillToRise(tester), 0);
    });
  });

  group('once', () {
    Future<void> revealThenLeave(
      WidgetTester tester, {
      required bool once,
    }) async {
      await tester.pumpWidget(app(listWith(timedBlock(once: once))));
      await scrollTo(tester, 300);
      await startClock(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(stillToRise(tester), 0);

      // Scrolled right off the top, then back.
      await scrollTo(tester, 900);
      await scrollTo(tester, 300);
    }

    testWidgets('keeps a block revealed by default', (
      WidgetTester tester,
    ) async {
      await revealThenLeave(tester, once: true);
      expect(stillToRise(tester), 0);
    });

    testWidgets('plays the reveal again each time when false', (
      WidgetTester tester,
    ) async {
      await revealThenLeave(tester, once: false);
      expect(stillToRise(tester), 100);

      await startClock(tester);
      await tester.pump(const Duration(milliseconds: 500));
      expect(stillToRise(tester), 50);
    });

    testWidgets('does not reset a block still partly in view', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(app(listWith(timedBlock(once: false))));
      await scrollTo(tester, 300);
      await startClock(tester);
      await tester.pump(const Duration(seconds: 1));

      // 10 of it left at the top.
      await scrollTo(tester, 790);
      expect(stillToRise(tester), 0);
    });
  });

  group('reduced motion', () {
    testWidgets('draws the block in place at once', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(app(reducedMotion(listWith(timedBlock()))));
      expect(stillToRise(tester), 0);

      await scrollTo(tester, 300);
      expect(stillToRise(tester), 0);
    });

    testWidgets('is ignored when told to', (WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          reducedMotion(
            listWith(timedBlock(respectReducedMotion: false), top: 0),
          ),
        ),
      );
      expect(stillToRise(tester), 100);
    });
  });

  group('sideways', () {
    testWidgets('waits until the block is scrolled in from the side', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(app(rowWith(timedBlock())));
      await tester.pump(const Duration(seconds: 1));
      expect(stillToRise(tester), 100);

      await scrollTo(tester, 300);
      await startClock(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(stillToRise(tester), 0);
    });
  });

  group('painting', () {
    testWidgets('pushes no layer once in place', (WidgetTester tester) async {
      // The app pushes layers of its own, counted without a reveal first.
      await tester.pumpWidget(app(listWith(testBlock, top: 0)));
      final int opacities = opacityLayers(tester).length;
      final int filters = tester.layers.whereType<ImageFilterLayer>().length;

      await tester.pumpWidget(
        app(
          listWith(
            const SimpleReveal(
              fade: FadeProperties(),
              zoom: ZoomProperties(0.5),
              blur: BlurProperties(8),
              child: testBlock,
            ),
            top: 0,
          ),
        ),
      );
      await startClock(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(opacityLayers(tester).length, opacities + 1);
      expect(tester.layers.whereType<ImageFilterLayer>().length, filters + 1);

      await tester.pumpAndSettle();
      expect(opacityLayers(tester).length, opacities);
      expect(tester.layers.whereType<ImageFilterLayer>().length, filters);
    });

    testWidgets('leaves a hidden block out of hit testing', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        app(
          listWith(
            SimpleReveal(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
                child: testBlock,
              ),
            ),
          ),
        ),
      );
      // 10 of it in view, short of its threshold, so still at an opacity of 0.
      await scrollTo(tester, 110);
      await tester.tapAt(const Offset(50, 595));
      expect(taps, 0);

      // 60 of it, enough to reveal it: it answers from the first frame on.
      await scrollTo(tester, 160);
      await startClock(tester);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(const Offset(50, 595));
      expect(taps, 1);
    });

    testWidgets('is tapped where it is drawn while it slides', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        app(
          listWith(
            SimpleReveal(
              fade: null,
              slide: const SlideProperties(200, 0),
              duration: const Duration(seconds: 1),
              curve: Curves.linear,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
                child: testBlock,
              ),
            ),
            top: 0,
          ),
        ),
      );
      await startClock(tester);
      await tester.pump(const Duration(milliseconds: 500));

      // Laid out from 0 to 100, drawn from 100 to 200.
      await tester.tapAt(const Offset(50, 50));
      expect(taps, 0);
      await tester.tapAt(const Offset(150, 50));
      expect(taps, 1);
    });

    testWidgets('does not rebuild the content as it plays', (
      WidgetTester tester,
    ) async {
      int builds = 0;
      await tester.pumpWidget(
        app(
          listWith(
            timedBlock(
              child: Builder(
                builder: (BuildContext context) {
                  builds++;
                  return testBlock;
                },
              ),
            ),
            top: 0,
          ),
        ),
      );
      final int before = builds;
      await startClock(tester);
      await tester.pumpAndSettle();

      expect(builds, before);
    });
  });

  testWidgets('follows a new duration mid-way', (WidgetTester tester) async {
    Widget page(Duration duration) => app(
          listWith(
            SimpleReveal(
              fade: null,
              slide: rise,
              duration: duration,
              curve: Curves.linear,
              child: testBlock,
            ),
            top: 0,
          ),
        );

    await tester.pumpWidget(page(const Duration(seconds: 1)));
    await startClock(tester);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpWidget(page(const Duration(seconds: 2)));
    await tester.pumpAndSettle();

    expect(stillToRise(tester), 0);
  });

  testWidgets('reveals a block with no height once its line is in view', (
    WidgetTester tester,
  ) async {
    int reveals = 0;
    await tester.pumpWidget(
      app(
        listWith(
          SimpleReveal(
            onReveal: () => reveals++,
            child: const SizedBox(width: 100, height: 0),
          ),
          top: 100,
        ),
      ),
    );
    await tester.pump();

    expect(reveals, 1);
  });

  testWidgets('paints only itself while it plays', (
    WidgetTester tester,
  ) async {
    final _CountingPainter beside = _CountingPainter();
    await tester.pumpWidget(
      app(
        Column(
          children: <Widget>[
            timedBlock(),
            CustomPaint(painter: beside, size: const Size(10, 10)),
          ],
        ),
      ),
    );
    await startClock(tester);
    await tester.pump(const Duration(milliseconds: 100));
    final int before = beside.paints;

    for (int frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(beside.paints, before);
  });
}

/// Counts how often it is painted.
class _CountingPainter extends CustomPainter {
  int paints = 0;

  @override
  void paint(Canvas canvas, Size size) => paints++;

  @override
  bool shouldRepaint(_CountingPainter oldDelegate) => false;
}
