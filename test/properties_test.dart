import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_reveal/simple_reveal.dart';

import 'helpers.dart';

void main() {
  group('SlideProperties', () {
    test('starts each named side the right way', () {
      const TextDirection ltr = TextDirection.ltr;
      expect(
        const SlideProperties.fromLeft(10).offsetIn(ltr),
        const Offset(-10, 0),
      );
      expect(
        const SlideProperties.fromRight(10).offsetIn(ltr),
        const Offset(10, 0),
      );
      expect(
        const SlideProperties.fromTop(10).offsetIn(ltr),
        const Offset(0, -10),
      );
      expect(
        const SlideProperties.fromBottom(10).offsetIn(ltr),
        const Offset(0, 10),
      );
    });

    test('defaults to the documented distance', () {
      expect(
        const SlideProperties.fromLeft().offsetIn(TextDirection.ltr),
        const Offset(-SlideProperties.defaultDistance, 0),
      );
    });

    test('turns the start and the end round in a right-to-left language', () {
      expect(
        const SlideProperties.fromStart(10).offsetIn(TextDirection.ltr),
        const Offset(-10, 0),
      );
      expect(
        const SlideProperties.fromStart(10).offsetIn(TextDirection.rtl),
        const Offset(10, 0),
      );
      expect(
        const SlideProperties.fromEnd(10).offsetIn(TextDirection.rtl),
        const Offset(-10, 0),
      );
    });

    test('leaves left and right alone in a right-to-left language', () {
      expect(
        const SlideProperties.fromLeft(10).offsetIn(TextDirection.rtl),
        const Offset(-10, 0),
      );
    });

    test('tells a directional slide from a fixed one', () {
      expect(
        const SlideProperties.fromStart(10),
        isNot(const SlideProperties.fromLeft(10)),
      );
      expect(const SlideProperties.fromLeft(10), const SlideProperties(-10, 0));
    });
  });

  group('equality', () {
    test('holds between equal settings', () {
      expect(const FadeProperties(0.3), const FadeProperties(0.3));
      expect(const ZoomProperties(0.8), const ZoomProperties(0.8));
      expect(const BlurProperties(4), const BlurProperties(4));
      expect(const RotateProperties(0.1), const RotateProperties(0.1));
      expect(
        const FlipProperties.aroundX(0.2),
        const FlipProperties.aroundX(0.2),
      );
      expect(const ScrubProperties(), const ScrubProperties());
      expect(
        const ZoomProperties(0.8).hashCode,
        const ZoomProperties(0.8).hashCode,
      );
    });

    test('tells apart settings that differ', () {
      expect(const FadeProperties(0.3), isNot(const FadeProperties(0.4)));
      expect(
        const ZoomProperties(0.8),
        isNot(const ZoomProperties(0.8, alignment: Alignment.topLeft)),
      );
      expect(
        const FlipProperties.aroundX(0.2),
        isNot(const FlipProperties.aroundY(0.2)),
      );
      expect(
        const ScrubProperties(),
        isNot(const ScrubProperties(mirror: true)),
      );
    });
  });

  group('asserts', () {
    test('rejects an opacity outside 0 to 1', () {
      expect(() => FadeProperties(1.5), throwsAssertionError);
      expect(() => FadeProperties(-0.1), throwsAssertionError);
    });

    test('rejects a negative scale, sigma or perspective', () {
      expect(() => ZoomProperties(-1), throwsAssertionError);
      expect(() => BlurProperties(-1), throwsAssertionError);
      expect(
        () => FlipProperties.aroundX(0.2, perspective: 0),
        throwsAssertionError,
      );
    });

    test('rejects a reach outside the viewport', () {
      expect(() => ScrubProperties(reach: 0), throwsAssertionError);
      expect(() => ScrubProperties(reach: 1.2), throwsAssertionError);
    });

    test('rejects a threshold outside 0 to 1', () {
      expect(
        () => SimpleReveal(threshold: 2, child: const SizedBox()),
        throwsAssertionError,
      );
    });
  });

  group('durations', () {
    testWidgets('cannot be negative on a block', (WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          const SimpleReveal(
            delay: Duration(milliseconds: -1),
            child: testBlock,
          ),
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('cannot be negative on a part', (WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          const RevealPart(
            duration: Duration(milliseconds: -1),
            child: testBlock,
          ),
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('cannot be negative on a group', (WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          const SimpleRevealGroup(
            interval: Duration(milliseconds: -1),
            child: testBlock,
          ),
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });
  });
}
