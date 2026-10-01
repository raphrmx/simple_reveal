import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_reveal/simple_reveal.dart';

import 'helpers.dart';

/// A list loaded page by page, the way a paginated feed grows: rows added at
/// its end once the last one comes into view, with no scroll of their own.
void main() {
  /// Rows of 100, [count] of them, then the row a feed shows while the next
  /// page loads, every row a block that rises.
  Widget feed(
    int count, {
    required void Function(int index) onReveal,
    bool grouped = false,
  }) {
    final Widget list = ListView.builder(
      itemCount: count + 1,
      itemBuilder: (BuildContext context, int index) => index == count
          ? const SizedBox(height: 100, child: Text('Loading'))
          : SimpleReveal(
              key: PageStorageKey<int>(index),
              fade: null,
              slide: rise,
              duration: const Duration(milliseconds: 100),
              curve: Curves.linear,
              onReveal: () => onReveal(index),
              child: SizedBox(key: ValueKey<int>(index), height: 100),
            ),
    );
    return app(grouped ? SimpleRevealGroup(child: list) : list);
  }

  testWidgets('reveals the rows of a page loaded in view', (
    WidgetTester tester,
  ) async {
    final List<int> revealed = <int>[];
    await tester.pumpWidget(feed(10, onReveal: revealed.add));
    await tester.pump();
    // Down to the loading row, at the bottom of the screen.
    await scrollTo(tester, scrollPosition(tester).maxScrollExtent);
    await tester.pump(const Duration(seconds: 1));
    revealed.clear();

    // The next page comes in where the loading row was.
    await tester.pumpWidget(feed(20, onReveal: revealed.add));
    await tester.pump();
    expect(revealed, contains(10));
    await tester.pump(const Duration(seconds: 1));
    expect(stillToRiseOf(tester, const ValueKey<int>(10)), 0);
  });

  testWidgets('brings the rows of a new page in one after the other', (
    WidgetTester tester,
  ) async {
    final List<int> revealed = <int>[];
    await tester.pumpWidget(feed(4, grouped: true, onReveal: revealed.add));
    await tester.pump(const Duration(seconds: 2));

    // The next page comes in under the last, its first two rows in view.
    await tester.pumpWidget(feed(8, grouped: true, onReveal: revealed.add));
    await startClock(tester);
    await tester.pump(const Duration(milliseconds: 50));
    // A tenth of a second apart: the first has risen half way, the second
    // has not started.
    expect(stillToRiseOf(tester, const ValueKey<int>(4)), closeTo(50, 1));
    expect(stillToRiseOf(tester, const ValueKey<int>(5)), 100);
  });

  testWidgets('does not play the rows of earlier pages again', (
    WidgetTester tester,
  ) async {
    final List<int> revealed = <int>[];
    await tester.pumpWidget(feed(30, onReveal: revealed.add));
    await tester.pump(const Duration(seconds: 1));
    expect(revealed, contains(0));

    // Far down, two pages later, then back to the top.
    await tester.pumpWidget(feed(50, onReveal: revealed.add));
    await scrollTo(tester, 4000);
    await scrollTo(tester, 0);
    expect(revealed.where((int index) => index == 0), hasLength(1));
    expect(stillToRiseOf(tester, const ValueKey<int>(0)), 0);
  });
}
