import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_reveal/simple_reveal.dart';
import 'package:simple_reveal/src/look.dart';

import 'helpers.dart';

void main() {
  const Size size = Size(100, 50);

  group('overlay', () {
    test('clears as the reveal runs', () {
      const RevealLook look = RevealLook(
        direction: TextDirection.ltr,
        overlay: OverlayProperties.darken(0.8),
      );
      expect(look.tintColorAt(0), Color.lerp(null, Colors.black, 0.8));
      expect(look.tintColorAt(0.5), Color.lerp(null, Colors.black, 0.4));
      expect(look.tintColorAt(1), isNull);
      expect(look.tintColorAt(1.2), isNull);
      expect(look.tintGradientAt(0), isNull);
    });

    test('scales a gradient down as the reveal runs', () {
      const LinearGradient gradient = LinearGradient(
        colors: <Color>[Colors.black, Colors.white],
      );
      const RevealLook look = RevealLook(
        direction: TextDirection.ltr,
        overlay: OverlayProperties.gradient(gradient),
      );
      expect(look.tintGradientAt(0.25), gradient.scale(0.75));
      expect(look.tintGradientAt(1), isNull);
      expect(look.tintColorAt(0), isNull);
    });

    testWidgets('is blended onto the block, then left out', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          listWith(
            const SimpleReveal(
              overlay: OverlayProperties.darken(0.6),
              child: testBlock,
            ),
            top: 0,
          ),
        ),
      );
      await startClock(tester);
      await tester.pump(const Duration(milliseconds: 100));
      final ColorFilterLayer tint =
          tester.layers.whereType<ColorFilterLayer>().single;
      expect(tint.colorFilter, isNotNull);

      await tester.pumpAndSettle();
      expect(tester.layers.whereType<ColorFilterLayer>(), isEmpty);
    });

    testWidgets('masks a gradient onto the block', (WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          listWith(
            const SimpleReveal(
              overlay: OverlayProperties.gradient(
                LinearGradient(colors: <Color>[Colors.black, Colors.white]),
              ),
              child: testBlock,
            ),
            top: 0,
          ),
        ),
      );
      await startClock(tester);
      await tester.pump(const Duration(milliseconds: 100));
      final ShaderMaskLayer mask =
          tester.layers.whereType<ShaderMaskLayer>().single;
      expect(mask.blendMode, BlendMode.srcATop);

      await tester.pumpAndSettle();
      expect(tester.layers.whereType<ShaderMaskLayer>(), isEmpty);
    });
  });

  group('wipe', () {
    RevealLook wipe(WipeProperties wipe, [TextDirection? direction]) =>
        RevealLook(direction: direction ?? TextDirection.ltr, wipe: wipe);

    test('opens from each edge', () {
      expect(
        wipe(const WipeProperties.fromLeft()).openingAt(0.25, size),
        const Rect.fromLTRB(0, 0, 25, 50),
      );
      expect(
        wipe(const WipeProperties.fromRight()).openingAt(0.25, size),
        const Rect.fromLTRB(75, 0, 100, 50),
      );
      expect(
        wipe(const WipeProperties.fromTop()).openingAt(0.5, size),
        const Rect.fromLTRB(0, 0, 100, 25),
      );
      expect(
        wipe(const WipeProperties.fromBottom()).openingAt(0.5, size),
        const Rect.fromLTRB(0, 25, 100, 50),
      );
    });

    test('opens from the start on the right in a right-to-left language', () {
      expect(
        wipe(const WipeProperties.fromStart()).openingAt(0.25, size),
        const Rect.fromLTRB(0, 0, 25, 50),
      );
      expect(
        wipe(const WipeProperties.fromStart(), TextDirection.rtl)
            .openingAt(0.25, size),
        const Rect.fromLTRB(75, 0, 100, 50),
      );
    });

    test('grows out of a point, as a rectangle or as a circle', () {
      expect(
        wipe(const WipeProperties.fromCenter()).openingAt(0.5, size),
        const Rect.fromLTRB(25, 12.5, 75, 37.5),
      );
      expect(
        wipe(const WipeProperties.fromCenter(alignment: Alignment.topLeft))
            .openingAt(0.5, size),
        const Rect.fromLTRB(0, 0, 50, 25),
      );
      final RevealLook circle = wipe(
        const WipeProperties.circle(alignment: Alignment.topLeft),
      );
      expect(circle.roundOpening, isTrue);
      // The farthest corner is sqrt(100² + 50²) away.
      final Rect half = circle.openingAt(0.5, size)!;
      expect(half.center, Offset.zero);
      expect(half.width / 2, closeTo(55.9017, 1e-3));
    });

    test('is left out once open, and draws nothing while closed', () {
      final RevealLook look = wipe(const WipeProperties.fromLeft());
      expect(look.openingAt(1, size), isNull);
      expect(look.drawsAt(0, size), isFalse);
      expect(look.drawsAt(0.1, size), isTrue);
    });

    test('still draws its panel while closed', () {
      final RevealLook look = wipe(
        const WipeProperties.fromLeft(color: Colors.black),
      );
      expect(look.drawsAt(0, size), isTrue);
    });

    testWidgets('clips the block to the opening, then lets it be', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          listWith(
            const SimpleReveal(
              fade: null,
              wipe: WipeProperties.fromLeft(),
              duration: Duration(seconds: 1),
              curve: Curves.linear,
              child: testBlock,
            ),
            top: 0,
          ),
        ),
      );
      await startClock(tester);
      await tester.pump(const Duration(milliseconds: 300));
      final ClipRectLayer clip = tester.layers
          .whereType<ClipRectLayer>()
          .singleWhere((ClipRectLayer layer) => layer.clipRect!.width == 30);
      expect(clip.clipRect!.height, 100);

      await tester.pumpAndSettle();
      expect(
        tester.layers
            .whereType<ClipRectLayer>()
            .where((ClipRectLayer layer) => layer.clipRect!.width == 100),
        isEmpty,
      );
    });

    testWidgets('does not answer taps while closed', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        app(
          listWith(
            SimpleReveal(
              fade: null,
              wipe: const WipeProperties.fromLeft(),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
                child: testBlock,
              ),
            ),
            top: 0,
          ),
        ),
      );
      await tester.tapAt(const Offset(50, 50));
      expect(taps, 0);

      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(50, 50));
      expect(taps, 1);
    });
  });

  group('clipBehavior', () {
    testWidgets('keeps a slide within the bounds while it runs', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        app(
          listWith(
            SimpleReveal(
              fade: null,
              slide: const SlideProperties(0, 50),
              clipBehavior: Clip.hardEdge,
              duration: const Duration(seconds: 1),
              curve: Curves.linear,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
                child: testBlock,
              ),
            ),
            top: 0,
          ),
        ),
      );
      await startClock(tester);
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        tester.layers.whereType<ClipRectLayer>().where(
              (ClipRectLayer layer) =>
                  layer.clipRect == const Rect.fromLTWH(0, 0, 100, 100),
            ),
        isNotEmpty,
      );

      // Drawn from 25 to 125, clipped at 100.
      await tester.tapAt(const Offset(50, 110));
      expect(taps, 0);
      await tester.tapAt(const Offset(50, 60));
      expect(taps, 1);
    });
  });
}
