import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_reveal/simple_reveal.dart';

import 'helpers.dart';

void main() {
  late RevealController controller;

  setUp(() => controller = RevealController());
  tearDown(() => controller.dispose());

  SimpleReveal controlled({bool manual = false}) => SimpleReveal(
        fade: null,
        slide: rise,
        duration: const Duration(seconds: 1),
        curve: Curves.linear,
        controller: controller,
        manual: manual,
        child: testBlock,
      );

  group('a manual block', () {
    testWidgets('waits for its controller, in sight or not', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(app(listWith(controlled(manual: true), top: 0)));
      await tester.pump(const Duration(seconds: 2));
      expect(stillToRise(tester), 100);
      expect(controller.isRevealed, isFalse);

      controller.reveal();
      await startClock(tester);
      await tester.pump(const Duration(milliseconds: 500));
      expect(stillToRise(tester), 50);
      expect(controller.isRevealed, isTrue);
    });

    testWidgets('is revealed below the fold as well', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(app(listWith(controlled(manual: true))));
      controller.reveal();
      await startClock(tester);
      await tester.pump(const Duration(seconds: 1));

      expect(stillToRise(tester), 0);
    });
  });

  group('hide', () {
    testWidgets('runs the reveal backwards', (WidgetTester tester) async {
      await tester.pumpWidget(app(listWith(controlled(), top: 0)));
      await startClock(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(stillToRise(tester), 0);

      controller.hide();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(stillToRise(tester), 25);
      expect(controller.isRevealed, isFalse);
    });

    testWidgets('keeps a block in sight hidden until it leaves and comes back',
        (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(app(listWith(controlled(), top: 300)));
      await startClock(tester);
      await tester.pump(const Duration(seconds: 1));

      controller.hide();
      await tester.pumpAndSettle();
      expect(stillToRise(tester), 100);

      // Still in sight: stays hidden.
      await scrollTo(tester, 50);
      await tester.pumpAndSettle();
      expect(stillToRise(tester), 100);

      // Out, and back.
      await scrollTo(tester, 1000);
      await scrollTo(tester, 0);
      await tester.pumpAndSettle();
      expect(stillToRise(tester), 0);
    });

    testWidgets('can be undone with reveal', (WidgetTester tester) async {
      await tester.pumpWidget(app(listWith(controlled(), top: 0)));
      await tester.pumpAndSettle();
      controller.hide();
      await tester.pumpAndSettle();

      controller.reveal();
      await tester.pumpAndSettle();
      expect(stillToRise(tester), 0);
    });
  });

  testWidgets('replay hides at once and plays again', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app(listWith(controlled(), top: 0)));
    await tester.pumpAndSettle();

    controller.replay();
    await tester.pump();
    expect(stillToRise(tester), 100);
    await tester.pump(const Duration(milliseconds: 500));
    expect(stillToRise(tester), 50);
  });

  testWidgets('notifies its listeners as the block comes and goes', (
    WidgetTester tester,
  ) async {
    final List<bool> seen = <bool>[];
    controller.addListener(() => seen.add(controller.isRevealed));
    await tester.pumpWidget(app(listWith(controlled(), top: 0)));
    await tester.pumpAndSettle();
    controller.hide();
    await tester.pumpAndSettle();

    expect(seen, <bool>[true, false]);
  });

  testWidgets('does nothing until handed to a block', (
    WidgetTester tester,
  ) async {
    controller.reveal();
    controller.hide();
    expect(controller.isRevealed, isFalse);
  });

  testWidgets('follows a block handed a new controller', (
    WidgetTester tester,
  ) async {
    final RevealController other = RevealController();
    addTearDown(other.dispose);
    await tester.pumpWidget(app(listWith(controlled(manual: true), top: 0)));
    await tester.pumpWidget(
      app(
        listWith(
          SimpleReveal(controller: other, manual: true, child: testBlock),
          top: 0,
        ),
      ),
    );

    controller.reveal();
    expect(other.isRevealed, isFalse);
    other.reveal();
    expect(other.isRevealed, isTrue);
  });

  test('cannot drive a scrubbed block', () {
    expect(
      () => SimpleReveal(
        scrub: const ScrubProperties(),
        controller: RevealController(),
        child: const SizedBox(),
      ),
      throwsAssertionError,
    );
  });

  group('under reduced motion', () {
    testWidgets('hides a block at once, and paints it so', (
      WidgetTester tester,
    ) async {
      // 10 of it on screen, short of its threshold: drawn in place, not
      // revealed yet.
      await tester.pumpWidget(
        app(reducedMotion(listWith(controlled(), top: 590))),
      );
      await tester.pump();
      expect(controller.isRevealed, isFalse);
      final int before = effectLayers(tester);

      controller.hide();
      await tester.pump();
      expect(stillToRise(tester), 100);
      // Painted hidden, not merely measured so.
      expect(effectLayers(tester), before + 1);
    });

    testWidgets('reveals and hides at once', (WidgetTester tester) async {
      await tester.pumpWidget(
        app(reducedMotion(listWith(controlled(manual: true), top: 0))),
      );
      expect(stillToRise(tester), 100);

      controller.reveal();
      await tester.pump();
      expect(stillToRise(tester), 0);
      expect(tester.hasRunningAnimations, isFalse);

      controller.hide();
      await tester.pump();
      expect(stillToRise(tester), 100);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  testWidgets('moves to a block that replaces its own in the same frame', (
    WidgetTester tester,
  ) async {
    Widget page(int key) => app(
          SimpleReveal(
            key: ValueKey<int>(key),
            controller: controller,
            manual: true,
            fade: null,
            slide: rise,
            child: testBlock,
          ),
        );
    await tester.pumpWidget(page(1));
    await tester.pumpWidget(page(2));
    await tester.pump();
    expect(tester.takeException(), isNull);

    controller.reveal();
    expect(controller.isRevealed, isTrue);
  });

  testWidgets('tells its listeners when its block is turned off', (
    WidgetTester tester,
  ) async {
    int notified = 0;
    controller.addListener(() => notified++);
    Widget page({required bool enabled}) => app(
          SimpleReveal(
            controller: controller,
            manual: true,
            enabled: enabled,
            child: testBlock,
          ),
        );
    await tester.pumpWidget(page(enabled: true));
    expect(controller.isRevealed, isFalse);

    await tester.pumpWidget(page(enabled: false));
    await tester.pump();
    expect(controller.isRevealed, isTrue);
    expect(notified, 1);
  });

  testWidgets('follows the block an AnimatedSwitcher brings in', (
    WidgetTester tester,
  ) async {
    Widget page(int key) => app(
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: SimpleReveal(
              key: ValueKey<int>(key),
              controller: controller,
              manual: true,
              child: Text('block $key'),
            ),
          ),
        );
    await tester.pumpWidget(page(1));
    await tester.pumpWidget(page(2));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    controller.reveal();
    expect(controller.isRevealed, isTrue);
  });

  testWidgets('lets a block turned from manual be revealed by sight', (
    WidgetTester tester,
  ) async {
    int reveals = 0;
    Widget page({required bool manual}) => app(
          SimpleReveal(
            manual: manual,
            onReveal: () => reveals++,
            child: testBlock,
          ),
        );
    await tester.pumpWidget(page(manual: true));
    await tester.pump();
    expect(reveals, 0);

    await tester.pumpWidget(page(manual: false));
    await tester.pump();
    expect(reveals, 1);
  });
}
