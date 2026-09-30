import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_reveal/simple_reveal.dart';

import 'helpers.dart';

void main() {
  const Key a = Key('a');
  const Key b = Key('b');
  const Key c = Key('c');

  SimpleReveal rising(Key key) => SimpleReveal(
        fade: null,
        slide: rise,
        duration: const Duration(seconds: 1),
        curve: Curves.linear,
        child: keyedBlock(key),
      );

  /// Three blocks on one row, [c] on the left and [a] on the right, built
  /// right to left so the order they are built in is not the reading order.
  Widget row({TextDirection direction = TextDirection.ltr}) => Directionality(
        textDirection: direction,
        child: SimpleRevealGroup(
          child: SizedBox(
            height: 100,
            child: Stack(
              children: <Widget>[
                Positioned(left: 200, top: 0, child: rising(a)),
                Positioned(left: 100, top: 0, child: rising(b)),
                Positioned(left: 0, top: 0, child: rising(c)),
              ],
            ),
          ),
        ),
      );

  testWidgets('reveals blocks seen together in reading order, apart', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app(row()));
    await startClock(tester);
    await tester.pump(const Duration(milliseconds: 500));

    expect(stillToRiseOf(tester, c), 50);
    expect(stillToRiseOf(tester, b), 60);
    expect(stillToRiseOf(tester, a), 70);
  });

  testWidgets('reads a right-to-left row from the right', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app(row(direction: TextDirection.rtl)));
    await startClock(tester);
    await tester.pump(const Duration(milliseconds: 500));

    expect(stillToRiseOf(tester, a), 50);
    expect(stillToRiseOf(tester, c), 70);
  });

  testWidgets('puts a block seen while others wait at the end of the line', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      app(
        SimpleRevealGroup(
          child: ListView(
            children: <Widget>[
              Row(children: <Widget>[rising(a), rising(b)]),
              const SizedBox(height: 530),
              Align(alignment: Alignment.topLeft, child: rising(c)),
              const SizedBox(height: 2000),
            ],
          ),
        ),
      ),
    );
    // One frame later, [c] comes in while [b] still waits its turn.
    await scrollTo(tester, 50);
    await startClock(tester);
    await tester.pump(const Duration(milliseconds: 500));

    expect(stillToRiseOf(tester, b), closeTo(60, 2));
    expect(stillToRiseOf(tester, c), closeTo(70, 2));
  });

  testWidgets('holds nothing back under reduced motion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app(reducedMotion(row())));
    expect(stillToRiseOf(tester, a), 0);
    expect(stillToRiseOf(tester, c), 0);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('does not keep the blocks in view waiting for those flung past', (
    WidgetTester tester,
  ) async {
    const Key landing = Key('landing');
    await tester.pumpWidget(
      app(
        SimpleRevealGroup(
          child: ListView.builder(
            itemCount: 200,
            itemBuilder: (BuildContext context, int index) => SimpleReveal(
              fade: null,
              slide: rise,
              duration: const Duration(milliseconds: 100),
              child: SizedBox(
                key: index == 101 ? landing : null,
                width: 100,
                height: 100,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));

    // A hundred rows go by in a hundred frames, each seen on its way.
    for (int frame = 1; frame <= 100; frame++) {
      scrollPosition(tester).jumpTo(frame * 100.0);
      await tester.pump(const Duration(milliseconds: 16));
    }
    // Six rows are in view: the second of them is in place within a second.
    await tester.pump(const Duration(seconds: 1));
    expect(stillToRiseOf(tester, landing), 0);
  });

  testWidgets('does not start a block hidden while it waits its turn', (
    WidgetTester tester,
  ) async {
    final RevealController controller = RevealController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      app(
        SimpleRevealGroup(
          child: SimpleReveal(
            controller: controller,
            fade: null,
            slide: rise,
            onReveal: controller.hide,
            child: testBlock,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(controller.isRevealed, isFalse);
    expect(stillToRise(tester), 100);
  });
}
