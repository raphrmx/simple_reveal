import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_reveal/simple_reveal.dart';
import 'package:simple_reveal/src/look.dart';

void main() {
  const Size size = Size(100, 100);

  /// Where [look] draws [point] of a block, [shown] of the way through.
  Offset drawn(RevealLook look, double shown, Offset point) {
    final Matrix4? transform = look.transformAt(shown, size);
    return transform == null
        ? point
        : MatrixUtils.transformPoint(transform, point);
  }

  group('fade', () {
    const RevealLook look = RevealLook(
      direction: TextDirection.ltr,
      fade: FadeProperties(0.2),
    );

    test('runs from its opacity to fully opaque', () {
      expect(look.alphaAt(0), Color.getAlphaFromOpacity(0.2));
      expect(look.alphaAt(0.5), Color.getAlphaFromOpacity(0.6));
      expect(look.alphaAt(1), 255);
    });

    test('stays within range on a curve that overshoots', () {
      expect(look.alphaAt(1.2), 255);
      expect(look.alphaAt(-0.5), 0);
    });

    test('is fully opaque without a fade', () {
      const RevealLook none = RevealLook(direction: TextDirection.ltr);
      expect(none.alphaAt(0), 255);
    });
  });

  group('blur', () {
    const RevealLook look = RevealLook(
      direction: TextDirection.ltr,
      blur: BlurProperties(10),
    );

    test('clears as the reveal runs', () {
      expect(look.sigmaAt(0), 10);
      expect(look.sigmaAt(0.5), 5);
      expect(look.sigmaAt(1), 0);
    });

    test('clears continuously, without steps', () {
      expect(look.sigmaAt(0.51), closeTo(4.9, 1e-9));
      expect(look.sigmaAt(0.97), closeTo(0.3, 1e-9));
      expect(look.sigmaAt(0.999), closeTo(0.01, 1e-9));
      expect(look.sigmaAt(0.9995), 0);
    });

    test('leaves no blur past the end of an overshooting curve', () {
      expect(look.sigmaAt(1.1), 0);
    });
  });

  group('transform', () {
    test('is left out once in place, and without effects', () {
      const RevealLook look = RevealLook(
        direction: TextDirection.ltr,
        slide: SlideProperties(0, 100),
        zoom: ZoomProperties(0.5),
      );
      expect(look.transformAt(1, size), isNull);
      expect(
        const RevealLook(direction: TextDirection.ltr).transformAt(0, size),
        isNull,
      );
    });

    test('slides the block home', () {
      const RevealLook look = RevealLook(
        direction: TextDirection.ltr,
        slide: SlideProperties(-80, 40),
      );
      expect(drawn(look, 0, Offset.zero), const Offset(-80, 40));
      expect(drawn(look, 0.5, Offset.zero), const Offset(-40, 20));
    });

    test('carries it past its place on an overshooting curve', () {
      const RevealLook look = RevealLook(
        direction: TextDirection.ltr,
        slide: SlideProperties(0, 100),
      );
      expect(drawn(look, 1.1, Offset.zero).dy, closeTo(-10, 1e-9));
    });

    test('slides from the start on the right in a right-to-left language', () {
      const RevealLook look = RevealLook(
        direction: TextDirection.rtl,
        slide: SlideProperties.fromStart(50),
      );
      expect(drawn(look, 0, Offset.zero), const Offset(50, 0));
    });

    test('zooms about its alignment', () {
      const RevealLook centred = RevealLook(
        direction: TextDirection.ltr,
        zoom: ZoomProperties(0.5),
      );
      expect(drawn(centred, 0, Offset.zero), const Offset(25, 25));
      expect(drawn(centred, 0, const Offset(50, 50)), const Offset(50, 50));
      expect(drawn(centred, 0.5, Offset.zero), const Offset(12.5, 12.5));

      const RevealLook cornered = RevealLook(
        direction: TextDirection.ltr,
        zoom: ZoomProperties(0.5, alignment: Alignment.topLeft),
      );
      expect(drawn(cornered, 0, Offset.zero), Offset.zero);
      expect(drawn(cornered, 0, const Offset(100, 100)), const Offset(50, 50));
    });

    test('turns clockwise for a positive figure', () {
      const RevealLook look = RevealLook(
        direction: TextDirection.ltr,
        rotate: RotateProperties(0.25),
      );
      // A quarter turn clockwise about the middle takes the middle of the
      // right edge to the middle of the bottom one.
      final Offset at = drawn(look, 0, const Offset(100, 50));
      expect(at.dx, closeTo(50, 1e-9));
      expect(at.dy, closeTo(100, 1e-9));
    });

    test('flips its top edge towards the viewer about X', () {
      const RevealLook look = RevealLook(
        direction: TextDirection.ltr,
        flip: FlipProperties.aroundX(0.1, perspective: 200),
      );
      // Nearer is drawn larger.
      final double top = drawn(look, 0, const Offset(100, 0)).dx -
          drawn(look, 0, Offset.zero).dx;
      final double bottom = drawn(look, 0, const Offset(100, 100)).dx -
          drawn(look, 0, const Offset(0, 100)).dx;
      expect(top, greaterThan(bottom));
    });

    test('flips its right edge towards the viewer about Y', () {
      const RevealLook look = RevealLook(
        direction: TextDirection.ltr,
        flip: FlipProperties.aroundY(0.1, perspective: 200),
      );
      final double left = drawn(look, 0, const Offset(0, 100)).dy -
          drawn(look, 0, Offset.zero).dy;
      final double right = drawn(look, 0, const Offset(100, 100)).dy -
          drawn(look, 0, const Offset(100, 0)).dy;
      expect(right, greaterThan(left));
    });

    test('leaves the middle where it is through a flip', () {
      const RevealLook look = RevealLook(
        direction: TextDirection.ltr,
        flip: FlipProperties.aroundY(0.2),
      );
      final Offset middle = drawn(look, 0, const Offset(50, 50));
      expect(middle.dx, closeTo(50, 1e-9));
      expect(middle.dy, closeTo(50, 1e-9));
    });
  });

  test('compares by value', () {
    expect(
      const RevealLook(direction: TextDirection.ltr, zoom: ZoomProperties(0.8)),
      RevealLook(direction: TextDirection.ltr, zoom: ZoomProperties(0.4 * 2)),
    );
    expect(
      const RevealLook(direction: TextDirection.ltr),
      isNot(const RevealLook(direction: TextDirection.rtl)),
    );
  });
}
