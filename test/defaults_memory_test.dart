import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_reveal/simple_reveal.dart';

import 'helpers.dart';

void main() {
  group('SimpleRevealDefaults', () {
    testWidgets('sets the pace of a block that sets none', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          SimpleRevealDefaults(
            duration: const Duration(seconds: 2),
            curve: Curves.linear,
            child: listWith(
              const SimpleReveal(fade: null, slide: rise, child: testBlock),
              top: 0,
            ),
          ),
        ),
      );
      await startClock(tester);
      await tester.pump(const Duration(milliseconds: 500));

      expect(stillToRise(tester), 75);
    });

    testWidgets('gives way to what a block sets', (WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          SimpleRevealDefaults(
            duration: const Duration(seconds: 2),
            curve: Curves.linear,
            child: listWith(timedBlock(), top: 0),
          ),
        ),
      );
      await startClock(tester);
      await tester.pump(const Duration(milliseconds: 500));

      expect(stillToRise(tester), 50);
    });

    testWidgets('sets the threshold and once', (WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          SimpleRevealDefaults(
            threshold: 0.5,
            once: false,
            child: listWith(
              const SimpleReveal(fade: null, slide: rise, child: testBlock),
            ),
          ),
        ),
      );
      // 40 of 100 in view, short of half.
      await scrollTo(tester, 140);
      await tester.pumpAndSettle();
      expect(stillToRise(tester), 100);

      await scrollTo(tester, 400);
      await tester.pumpAndSettle();
      await scrollTo(tester, 1000);
      await scrollTo(tester, 400);
      expect(stillToRise(tester), 100);
    });

    testWidgets('turns every reveal off', (WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          SimpleRevealDefaults(
            enabled: false,
            child: listWith(
              const SimpleReveal(
                fade: null,
                slide: rise,
                child: RevealPart(fade: null, slide: rise, child: testBlock),
              ),
            ),
          ),
        ),
      );
      expect(stillToRise(tester), 0);
      expect(stillToRiseOf(tester, blockKey, RevealPart), 0);
    });

    testWidgets('keeps the content when turned back on', (
      WidgetTester tester,
    ) async {
      final GlobalKey<State<StatefulWidget>> inside = GlobalKey();
      Widget page({required bool enabled}) => app(
            SimpleRevealDefaults(
              enabled: enabled,
              child: listWith(
                SimpleReveal(child: TextField(key: inside)),
                top: 0,
              ),
            ),
          );

      await tester.pumpWidget(page(enabled: false));
      final State<StatefulWidget> before = inside.currentState!;
      await tester.pumpWidget(page(enabled: true));

      expect(inside.currentState, same(before));
    });
  });

  group('remembering', () {
    /// Fifty rows built lazily, each a block, the first with [key] on it.
    Widget rows(Key? key) => ListView.builder(
          itemCount: 50,
          itemBuilder: (BuildContext context, int index) => SimpleReveal(
            key: index == 0 ? key : null,
            fade: null,
            slide: rise,
            child: index == 0
                ? testBlock
                : const SizedBox(width: 100, height: 100),
          ),
        );

    Future<void> revealThenComeBack(WidgetTester tester, Key? key) async {
      await tester.pumpWidget(app(rows(key)));
      await tester.pumpAndSettle();
      expect(stillToRiseOf(tester, blockKey), 0);

      // Far enough for the first row to be disposed, then back.
      await scrollTo(tester, 3000);
      expect(find.byKey(blockKey, skipOffstage: false), findsNothing);
      await scrollTo(tester, 0);
    }

    testWidgets('brings a block with a PageStorageKey back in place', (
      WidgetTester tester,
    ) async {
      await revealThenComeBack(tester, const PageStorageKey<String>('first'));
      expect(stillToRiseOf(tester, blockKey), 0);
    });

    testWidgets('plays a block without one again', (
      WidgetTester tester,
    ) async {
      await revealThenComeBack(tester, null);
      expect(stillToRiseOf(tester, blockKey), 100);
    });

    testWidgets('does not collide with a scrollable inside the block', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          ListView.builder(
            itemCount: 50,
            itemBuilder: (BuildContext context, int index) => SimpleReveal(
              key: PageStorageKey<int>(index),
              child: SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const <Widget>[SizedBox(width: 2000)],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final Finder inner = find.byType(Scrollable).at(1);
      scrollPosition(tester, inner).jumpTo(50);
      await tester.pump();

      await scrollTo(tester, 3000);
      await scrollTo(tester, 0);

      expect(tester.takeException(), isNull);
      expect(scrollPosition(tester, find.byType(Scrollable).at(1)).pixels, 50);
    });

    testWidgets('does not remember by a key on the list itself', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          ListView.builder(
            key: const PageStorageKey<String>('list'),
            itemCount: 50,
            itemBuilder: (BuildContext context, int index) => SimpleReveal(
              fade: null,
              slide: rise,
              child: index == 20
                  ? testBlock
                  : const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The rows before it have been revealed; row 20 has not.
      await scrollTo(tester, 1700);
      expect(stillToRiseOf(tester, blockKey), 100);
    });

    testWidgets('remembers by a key on the item the list builds around it', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          ListView.builder(
            itemCount: 50,
            itemBuilder: (BuildContext context, int index) => Padding(
              key: PageStorageKey<int>(index),
              padding: EdgeInsets.zero,
              child: SimpleReveal(
                fade: null,
                slide: rise,
                child: index == 0
                    ? testBlock
                    : const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await scrollTo(tester, 3000);
      await scrollTo(tester, 0);
      expect(stillToRiseOf(tester, blockKey), 0);
    });
  });
}
