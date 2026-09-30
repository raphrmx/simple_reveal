import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_reveal/simple_reveal.dart';

import 'helpers.dart';

void main() {
  /// A page with a carousel 700 down it, 100 high, and the block 900 along the
  /// carousel, past its right edge.
  Widget carouselPage() => app(
        listWith(
          SizedBox(width: 800, height: 100, child: rowWith(timedBlock())),
        ),
      );

  final Finder page = find.byType(Scrollable, skipOffstage: false).first;
  final Finder carousel = find.byType(Scrollable, skipOffstage: false).last;

  Future<void> letItPlay(WidgetTester tester) async {
    await startClock(tester);
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('waits for the page to bring the carousel in', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(carouselPage());
    // Within the carousel, but the carousel is below the fold.
    await scrollTo(tester, 300, carousel);
    await letItPlay(tester);
    expect(stillToRise(tester), 100);

    await scrollTo(tester, 300, page);
    await letItPlay(tester);
    expect(stillToRise(tester), 0);
  });

  testWidgets('waits for the carousel to bring the block in', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(carouselPage());
    // The carousel is in view, the block past its edge.
    await scrollTo(tester, 300, page);
    await letItPlay(tester);
    expect(stillToRise(tester), 100);

    await scrollTo(tester, 300, carousel);
    await letItPlay(tester);
    expect(stillToRise(tester), 0);
  });

  testWidgets('waits for a page of a page view to be turned to', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      app(
        PageView(
          children: <Widget>[
            const SizedBox(),
            Align(alignment: Alignment.topLeft, child: timedBlock()),
          ],
        ),
      ),
    );
    await letItPlay(tester);

    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(stillToRise(tester), 0);
  });

  testWidgets('does not see a block where two clipping edges meet', (
    WidgetTester tester,
  ) async {
    int reveals = 0;
    final ScrollController page = ScrollController(initialScrollOffset: 410);
    addTearDown(page.dispose);
    await tester.pumpWidget(
      app(
        ListView(
          controller: page,
          children: <Widget>[
            SizedBox(
              height: 300,
              child: ListView(
                children: <Widget>[
                  const SizedBox(height: 250),
                  Align(
                    alignment: Alignment.topLeft,
                    child: SimpleReveal(
                      onReveal: () => reveals++,
                      child: testBlock,
                    ),
                  ),
                  const SizedBox(height: 1000),
                ],
              ),
            ),
            const SizedBox(height: 3000),
          ],
        ),
      ),
    );
    await tester.pump();

    // The inner list ends exactly at the top of the screen, and the block
    // straddles that edge: none of it can be seen.
    await scrollTo(tester, 300);
    await tester.pump();
    expect(reveals, 0);
  });
}
