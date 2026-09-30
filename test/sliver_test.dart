import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_reveal/simple_reveal.dart';

import 'helpers.dart';

void main() {
  const Key inList = Key('list');
  const Key inGrid = Key('grid');
  const Key inAdapter = Key('adapter');

  SimpleReveal rising(Key key, {ScrubProperties? scrub}) => SimpleReveal(
        fade: null,
        slide: rise,
        scrub: scrub,
        child: keyedBlock(key),
      );

  /// A page of slivers under a pinned app bar, one block in each.
  Widget page({ScrubProperties? scrub}) => CustomScrollView(
        slivers: <Widget>[
          const SliverAppBar(pinned: true, expandedHeight: 200),
          const SliverToBoxAdapter(child: SizedBox(height: 600)),
          SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.topLeft,
              child: rising(inAdapter, scrub: scrub),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(top: 400),
            sliver: SliverList(
              delegate: SliverChildListDelegate(<Widget>[
                Align(
                  alignment: Alignment.topLeft,
                  child: rising(inList, scrub: scrub),
                ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(top: 400),
            sliver: SliverGrid.count(
              crossAxisCount: 4,
              children: <Widget>[rising(inGrid, scrub: scrub)],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 2000)),
        ],
      );

  testWidgets('reveals a block in each kind of sliver as it comes in', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app(page()));
    await tester.pumpAndSettle();
    expect(stillToRiseOf(tester, inAdapter), 100);

    for (final Key key in <Key>[inAdapter, inList, inGrid]) {
      await tester.scrollUntilVisible(
        find.byKey(key),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(stillToRiseOf(tester, key), 0, reason: '$key');
    }
  });

  testWidgets('scrubs a block in a sliver list', (WidgetTester tester) async {
    await tester.pumpWidget(app(page(scrub: const ScrubProperties())));
    await tester.scrollUntilVisible(
      find.byKey(inList),
      50,
      scrollable: find.byType(Scrollable).first,
    );
    final double early = stillToRiseOf(tester, inList);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
    await tester.pump();

    expect(early, greaterThan(stillToRiseOf(tester, inList)));
  });
}
