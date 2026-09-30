import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_reveal/simple_reveal.dart';

import 'helpers.dart';

/// Blocks brought into view with no scroll: by a page sliding in, or by the
/// content above them changing.
void main() {
  /// Pumps a second of frames, the way a route transition is played.
  Future<void> playFrames(WidgetTester tester) async {
    for (int frame = 0; frame < 60; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  testWidgets('reveals a block on a page sliding in from the side', (
    WidgetTester tester,
  ) async {
    int reveals = 0;
    final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      CupertinoApp(navigatorKey: navigator, home: const SizedBox()),
    );

    // Painted once, off the screen, as the slide starts; after that only the
    // layer of the page moves.
    navigator.currentState!.push(
      CupertinoPageRoute<void>(
        builder: (BuildContext context) => Center(
          child: SimpleReveal(onReveal: () => reveals++, child: testBlock),
        ),
      ),
    );
    await playFrames(tester);

    expect(reveals, 1);
  });

  testWidgets('reveals a block brought into view by the content above it', (
    WidgetTester tester,
  ) async {
    int reveals = 0;
    double above = 560;
    late StateSetter setAbove;
    await tester.pumpWidget(
      app(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            setAbove = setState;
            return ListView(
              children: <Widget>[
                SizedBox(height: above),
                SimpleReveal(
                  threshold: 0.5,
                  onReveal: () => reveals++,
                  child: testBlock,
                ),
                const SizedBox(height: 2000),
              ],
            );
          },
        ),
      ),
    );
    await tester.pump();
    expect(reveals, 0);

    setAbove(() => above = 100);
    await tester.pump();
    await tester.pump();

    expect(reveals, 1);
  });

  testWidgets('asks for no frame while a block waits on a still screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app(listWith(timedBlock())));
    await tester.pump();
    await tester.pump();

    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
