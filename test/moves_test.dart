import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

  testWidgets('does not reveal a block on a hidden tab until it is shown', (
    WidgetTester tester,
  ) async {
    int reveals = 0;
    int tab = 0;
    double above = 1000;
    late StateSetter setPage;
    await tester.pumpWidget(
      app(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            setPage = setState;
            return IndexedStack(
              index: tab,
              children: <Widget>[
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(height: above),
                      SimpleReveal(
                        fade: null,
                        slide: rise,
                        onReveal: () => reveals++,
                        child: testBlock,
                      ),
                    ],
                  ),
                ),
                const SizedBox(),
              ],
            );
          },
        ),
      ),
    );
    await tester.pump();

    // Brought to the top of its tab while another tab is shown.
    setPage(() => tab = 1);
    await tester.pump();
    setPage(() => above = 0);
    await playFrames(tester);
    expect(reveals, 0);

    setPage(() => tab = 0);
    await tester.pump();
    await tester.pump();
    expect(reveals, 1);
    expect(stillToRise(tester), 100);
  });

  testWidgets('does not reveal a block on a page covered by another', (
    WidgetTester tester,
  ) async {
    int reveals = 0;
    double above = 1000;
    late StateSetter setPage;
    final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              setPage = setState;
              return SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    SizedBox(height: above),
                    SimpleReveal(
                      onReveal: () => reveals++,
                      child: const SizedBox(width: 800, height: 100),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const Scaffold(),
      ),
    );
    await tester.pumpAndSettle();

    setPage(() => above = 0);
    await playFrames(tester);
    expect(reveals, 0);
  });
}
