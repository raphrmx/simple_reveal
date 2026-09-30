import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_reveal/simple_reveal.dart';

import 'helpers.dart';

/// Every effect and every way of playing it, under reduced motion: nothing may
/// move, and no layer may be pushed for any effect, at any frame. The repaint
/// boundary each block and part keeps its content in is there either way.
void main() {
  const Key part = Key('part');

  /// A page of blocks using everything the package offers, [top] down the
  /// list, or plain boxes of the same sizes with [plain].
  Widget page({required bool plain, double top = 700}) {
    Widget block(Widget child) => plain
        ? child
        : SimpleReveal(
            slide: const SlideProperties.fromLeft(),
            zoom: const ZoomProperties(0.5),
            blur: const BlurProperties(8),
            rotate: const RotateProperties(0.1),
            flip: const FlipProperties.aroundY(0.2),
            overlay: const OverlayProperties.darken(0.8),
            wipe: const WipeProperties.circle(color: Colors.black),
            clipBehavior: Clip.hardEdge,
            stagger: const Duration(milliseconds: 100),
            child: child,
          );
    Widget piece(Key? key) => plain
        ? SizedBox(key: key, width: 100, height: 50)
        : RevealPart(
            slide: const SlideProperties.fromBottom(),
            overlay: const OverlayProperties.lighten(1),
            wipe: const WipeProperties.fromLeft(),
            child: SizedBox(key: key, width: 100, height: 50),
          );

    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[piece(part), piece(null)],
    );
    final Widget list = ListView(
      children: <Widget>[
        SizedBox(height: top),
        Align(alignment: Alignment.topLeft, child: block(content)),
        Align(
          alignment: Alignment.topLeft,
          child: plain
              ? testBlock
              : const SimpleReveal(
                  wipe: WipeProperties.fromTop(),
                  scrub: ScrubProperties(mirror: true),
                  child: testBlock,
                ),
        ),
        const SizedBox(height: 2000),
      ],
    );
    return reducedMotion(plain ? list : SimpleRevealGroup(child: list));
  }

  for (final double top in <double>[0, 700]) {
    testWidgets('pushes nothing and moves nothing, block at $top', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(app(page(plain: true, top: top)));
      final int plainLayers = effectLayers(tester);
      await tester.pumpWidget(app(page(plain: false, top: top)));

      Future<void> expectStill() async {
        expect(effectLayers(tester), plainLayers);
        expect(tester.hasRunningAnimations, isFalse);
        // Scrolled far enough, the list has let the block go.
        if (find.byKey(part, skipOffstage: false).evaluate().isEmpty) return;
        expect(stillToRiseOf(tester, part, RevealPart), 0);
        expect(drawnOffsetOf(tester, part, SimpleReveal), Offset.zero);
      }

      await expectStill();
      for (final double offset in <double>[100, 400, 800, 1200, 300]) {
        await scrollTo(tester, offset);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await expectStill();
      }
    });
  }
}
