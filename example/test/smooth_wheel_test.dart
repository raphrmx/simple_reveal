import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_reveal_example/smooth_wheel.dart';

void main() {
  /// A long list on a smooth wheel, under [disableAnimations].
  Widget page({bool disableAnimations = false}) => MaterialApp(
        home: Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: disableAnimations),
            child: SmoothWheel(
              builder: (BuildContext context, ScrollController controller) =>
                  ListView(
                controller: controller,
                children: const <Widget>[SizedBox(height: 5000)],
              ),
            ),
          ),
        ),
      );

  Future<void> wheel(WidgetTester tester, double delta) async {
    final TestPointer pointer = TestPointer(1, PointerDeviceKind.mouse);
    final Offset middle = tester.getCenter(find.byType(Scrollable));
    await tester.sendEventToBinding(pointer.hover(middle));
    await tester.sendEventToBinding(pointer.scroll(Offset(0, delta)));
  }

  double pixels(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;

  testWidgets('eases a notch in over several frames', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(page());
    await wheel(tester, 100);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(pixels(tester), greaterThan(0));
    expect(pixels(tester), lessThan(100));

    await tester.pumpAndSettle();
    expect(pixels(tester), 100);
  });

  testWidgets('adds up notches turned quickly', (WidgetTester tester) async {
    await tester.pumpWidget(page());
    await wheel(tester, 100);
    await tester.pump(const Duration(milliseconds: 30));
    await wheel(tester, 100);
    await tester.pumpAndSettle();

    expect(pixels(tester), 200);
  });

  testWidgets('lands a notch at once under reduced motion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(page(disableAnimations: true));
    await wheel(tester, 100);
    await tester.pump();

    expect(pixels(tester), 100);
  });
}
