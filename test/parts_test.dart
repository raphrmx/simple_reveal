import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_reveal/simple_reveal.dart';

import 'helpers.dart';

void main() {
  const Key title = Key('title');
  const Key text = Key('text');
  const Key button = Key('button');

  /// A block of three parts in a column, [title] on top, with nothing of its
  /// own moving.
  Widget section({
    Duration stagger = const Duration(milliseconds: 200),
    Duration buttonDelay = Duration.zero,
    RevealController? controller,
    bool manual = false,
    ScrubProperties? scrub,
  }) =>
      SimpleReveal(
        fade: null,
        stagger: stagger,
        controller: controller,
        manual: manual,
        scrub: scrub,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            risingPart(title),
            risingPart(text),
            risingPart(button, delay: buttonDelay),
          ],
        ),
      );

  double left(WidgetTester tester, Key key) =>
      stillToRiseOf(tester, key, RevealPart);

  testWidgets('wait for the block, then come in one after the other', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app(listWith(section())));
    await tester.pump(const Duration(seconds: 2));
    expect(left(tester, title), 100);

    await scrollTo(tester, 400);
    await startClock(tester);
    await tester.pump(const Duration(milliseconds: 500));

    expect(left(tester, title), 50);
    expect(left(tester, text), 70);
    expect(left(tester, button), 90);
  });

  testWidgets('add a delay of their own to their turn', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      app(
        listWith(
          section(buttonDelay: const Duration(milliseconds: 100)),
          top: 0,
        ),
      ),
    );
    await startClock(tester);
    await tester.pump(const Duration(milliseconds: 600));

    expect(left(tester, button), 90);
  });

  testWidgets('come in in reading order, not the order they are built in', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      app(
        const SimpleReveal(
          fade: null,
          stagger: Duration(milliseconds: 200),
          child: SizedBox(
            width: 300,
            height: 300,
            child: Stack(
              children: <Widget>[
                Positioned(top: 200, left: 0, child: _Part(button)),
                Positioned(top: 100, left: 0, child: _Part(text)),
                Positioned(top: 0, left: 0, child: _Part(title)),
              ],
            ),
          ),
        ),
      ),
    );
    await startClock(tester);
    await tester.pump(const Duration(milliseconds: 500));

    expect(left(tester, title), 50);
    expect(left(tester, button), 90);
  });

  testWidgets("take the block's pace when given none", (
    WidgetTester tester,
  ) async {
    const Key part = Key('part');
    await tester.pumpWidget(
      app(
        const SimpleReveal(
          fade: null,
          duration: Duration(seconds: 2),
          curve: Curves.linear,
          child: RevealPart(
            fade: null,
            slide: rise,
            child: SizedBox(key: part, width: 100, height: 100),
          ),
        ),
      ),
    );
    await startClock(tester);
    await tester.pump(const Duration(milliseconds: 500));

    expect(left(tester, part), 75);
  });

  testWidgets('are drawn in place outside a block', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app(Center(child: risingPart(title))));
    expect(left(tester, title), 0);
  });

  testWidgets('follow the controller of their block', (
    WidgetTester tester,
  ) async {
    final RevealController controller = RevealController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      app(listWith(section(controller: controller), top: 0)),
    );
    await tester.pumpAndSettle();
    expect(left(tester, button), 0);

    controller.hide();
    await tester.pumpAndSettle();
    expect(left(tester, button), 100);

    controller.replay();
    await tester.pump();
    expect(left(tester, title), 100);
    await tester.pump(const Duration(milliseconds: 500));
    expect(left(tester, title), 50);
  });

  testWidgets('join a block already revealed in place', (
    WidgetTester tester,
  ) async {
    bool withPart = false;
    late StateSetter setOuter;
    await tester.pumpWidget(
      app(
        SimpleReveal(
          fade: null,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              setOuter = setState;
              return withPart
                  ? risingPart(title)
                  : const SizedBox(width: 100, height: 100);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    setOuter(() => withPart = true);
    await tester.pump();
    expect(left(tester, title), 0);
  });

  testWidgets('play as a scrubbed block starts coming in, and back', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      app(listWith(section(scrub: const ScrubProperties()))),
    );
    await scrollTo(tester, 150);
    await startClock(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(left(tester, button), 0);

    await scrollTo(tester, 0);
    await tester.pumpAndSettle();
    expect(left(tester, title), 100);
  });

  testWidgets('are in place from the first frame under reduced motion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app(reducedMotion(listWith(section()))));
    expect(left(tester, title), 0);
    expect(left(tester, button), 0);

    await scrollTo(tester, 400);
    expect(left(tester, button), 0);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('stay hidden with a manual block under reduced motion', (
    WidgetTester tester,
  ) async {
    final RevealController controller = RevealController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      app(
        reducedMotion(
          listWith(section(controller: controller, manual: true), top: 0),
        ),
      ),
    );
    expect(left(tester, title), 100);

    controller.reveal();
    await tester.pump();
    expect(left(tester, title), 0);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('come in in reading order under a turned block', (
    WidgetTester tester,
  ) async {
    const List<Key> keys = <Key>[Key('first'), Key('second'), Key('third')];
    await tester.pumpWidget(
      app(
        SimpleReveal(
          fade: null,
          rotate: const RotateProperties(0.5),
          stagger: const Duration(milliseconds: 500),
          duration: const Duration(milliseconds: 100),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[for (final Key key in keys) risingPart(key)],
          ),
        ),
      ),
    );
    await startClock(tester);
    await tester.pump(const Duration(milliseconds: 1100));

    // A second each, half a second apart, in the order they are laid out.
    expect(stillToRiseOf(tester, keys[0], RevealPart), 0);
    expect(stillToRiseOf(tester, keys[1], RevealPart), closeTo(40, 1));
    expect(stillToRiseOf(tester, keys[2], RevealPart), closeTo(90, 1));
  });

  testWidgets('join a block still waiting its turn after it', (
    WidgetTester tester,
  ) async {
    const Key late = Key('late');
    bool joined = false;
    late StateSetter join;
    await tester.pumpWidget(
      app(
        SimpleRevealGroup(
          interval: const Duration(seconds: 2),
          child: Column(
            children: <Widget>[
              const SimpleReveal(child: SizedBox(width: 50, height: 50)),
              StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  join = setState;
                  return SimpleReveal(
                    fade: null,
                    child: Column(
                      children: <Widget>[
                        const SizedBox(width: 50, height: 50),
                        if (joined) risingPart(late),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    join(() => joined = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    // Its block starts at two seconds: the part has not moved yet.
    expect(stillToRiseOf(tester, late, RevealPart), 100);

    await tester.pump(const Duration(seconds: 2));
    expect(stillToRiseOf(tester, late, RevealPart), 0);
  });
}

class _Part extends StatelessWidget {
  const _Part(this.marker);

  final Key marker;

  @override
  Widget build(BuildContext context) => risingPart(marker);
}
