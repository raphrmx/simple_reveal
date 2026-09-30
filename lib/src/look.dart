/// How a block looks part way through its reveal.
///
/// The timed reveal and the scrubbed one only differ in where the progress
/// comes from; once there is one, the block is drawn the same way, so that is
/// worked out in one place.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'properties.dart';

/// Sigma under which the blur is left out, no longer changing a pixel.
const double _blurFloor = 0.01;

/// The effects of one block, and the reading direction a slide from the
/// start or the end is resolved in.
///
/// Compared by value, so a rebuild that hands over the same effects does not
/// repaint the block.
@immutable
class RevealLook {
  /// Gathers the effects of one block.
  const RevealLook({
    required this.direction,
    this.fade,
    this.slide,
    this.zoom,
    this.blur,
    this.rotate,
    this.flip,
    this.overlay,
    this.wipe,
  });

  /// The reading direction [slide] is resolved in.
  final TextDirection direction;

  /// The fade, `null` for none.
  final FadeProperties? fade;

  /// The slide, `null` for none.
  final SlideProperties? slide;

  /// The zoom, `null` for none.
  final ZoomProperties? zoom;

  /// The blur, `null` for none.
  final BlurProperties? blur;

  /// The turn in the plane of the screen, `null` for none.
  final RotateProperties? rotate;

  /// The turn in depth, `null` for none.
  final FlipProperties? flip;

  /// The tint that clears, `null` for none.
  final OverlayProperties? overlay;

  /// The opening the block is uncovered through, `null` for none.
  final WipeProperties? wipe;

  /// The alpha the block is drawn at, [shown] of the way through its reveal,
  /// from `0` to `255`.
  int alphaAt(double shown) {
    final FadeProperties? fade = this.fade;
    if (fade == null) return 255;
    final double opacity = fade.opacity + (1 - fade.opacity) * shown;
    return Color.getAlphaFromOpacity(opacity.clamp(0.0, 1.0));
  }

  /// The sigma the block is blurred with, [shown] of the way through its
  /// reveal. `0` when there is nothing left to blur.
  ///
  /// Not rounded: a reveal changes the sigma on every frame anyway, and the
  /// last steps of a rounded one, on the slow end of an easing curve, show as
  /// the block holding soft for a few frames and then snapping sharp.
  double sigmaAt(double shown) {
    final BlurProperties? blur = this.blur;
    if (blur == null) return 0;
    final double sigma = blur.sigma * (1 - shown);
    return sigma < _blurFloor ? 0 : sigma;
  }

  /// How strong the [overlay] still is, [shown] of the way through the reveal,
  /// from `0` to its opacity.
  double _tintAt(double shown) {
    final OverlayProperties? overlay = this.overlay;
    if (overlay == null) return 0;
    return overlay.opacity * (1 - shown).clamp(0.0, 1.0);
  }

  /// The flat colour the block is tinted with, [shown] of the way through its
  /// reveal, `null` for none.
  Color? tintColorAt(double shown) {
    final Color? color = overlay?.color;
    final double strength = _tintAt(shown);
    if (color == null || strength == 0) return null;
    return Color.lerp(null, color, strength);
  }

  /// The gradient the block is tinted with, [shown] of the way through its
  /// reveal, `null` for none.
  Gradient? tintGradientAt(double shown) {
    final Gradient? gradient = overlay?.gradient;
    final double strength = _tintAt(shown);
    if (gradient == null || strength == 0) return null;
    return gradient.scale(strength);
  }

  /// Whether the [wipe] opening is a circle rather than a rectangle.
  bool get roundOpening => wipe?.from == WipeFrom.circle;

  /// The part of a block of [size] the [wipe] has uncovered, [shown] of the
  /// way through its reveal: a rectangle, or the bounds of a circle when
  /// [roundOpening]. `null` without a wipe, or once it is fully open.
  Rect? openingAt(double shown, Size size) {
    final WipeProperties? wipe = this.wipe;
    if (wipe == null) return null;
    final double open = shown.clamp(0.0, 1.0);
    if (open == 1) return null;

    final double width = size.width;
    final double height = size.height;
    final bool rtl = direction == TextDirection.rtl;
    switch (wipe.from) {
      case WipeFrom.left:
        return Rect.fromLTRB(0, 0, width * open, height);
      case WipeFrom.right:
        return Rect.fromLTRB(width * (1 - open), 0, width, height);
      case WipeFrom.top:
        return Rect.fromLTRB(0, 0, width, height * open);
      case WipeFrom.bottom:
        return Rect.fromLTRB(0, height * (1 - open), width, height);
      case WipeFrom.start:
        return rtl
            ? Rect.fromLTRB(width * (1 - open), 0, width, height)
            : Rect.fromLTRB(0, 0, width * open, height);
      case WipeFrom.end:
        return rtl
            ? Rect.fromLTRB(0, 0, width * open, height)
            : Rect.fromLTRB(width * (1 - open), 0, width, height);
      case WipeFrom.center:
        final Offset at = wipe.alignment.alongSize(size);
        return Rect.fromLTRB(
          at.dx * (1 - open),
          at.dy * (1 - open),
          at.dx + (width - at.dx) * open,
          at.dy + (height - at.dy) * open,
        );
      case WipeFrom.circle:
        final Offset at = wipe.alignment.alongSize(size);
        // Far enough to reach the farthest corner once fully open.
        final double reach = math.sqrt(
          math.pow(math.max(at.dx, width - at.dx), 2) +
              math.pow(math.max(at.dy, height - at.dy), 2),
        );
        return Rect.fromCircle(center: at, radius: reach * open);
    }
  }

  /// Whether anything of the block is drawn, [shown] of the way through its
  /// reveal, for a block of [size]: its content, or the panel of its wipe.
  bool drawsAt(double shown, Size size) {
    if (wipe?.color != null) return true;
    if (alphaAt(shown) == 0) return false;
    final Rect? opening = openingAt(shown, size);
    return opening == null || (opening.width > 0 && opening.height > 0);
  }

  /// The transform the block is drawn through, [shown] of the way through its
  /// reveal, for a block of [size]. `null` when it would leave the block where
  /// it stands, so no layer is pushed for it.
  ///
  /// A curve that overshoots takes [shown] past `1`, and the block with it,
  /// past its place and back.
  ///
  /// Built from `translationValues`, `diagonal3Values`, `rotationX` and their
  /// kin, joined by `multiply`, rather than from `translateByDouble` and
  /// `scaleByDouble`, which the `vector_math` pinned by the oldest Flutter this
  /// package supports does not have.
  Matrix4? transformAt(double shown, Size size) {
    final double hidden = 1 - shown;
    if (hidden == 0) return null;

    Matrix4? transform;
    void then(Matrix4 step) =>
        transform = transform == null ? step : (transform!..multiply(step));

    final SlideProperties? slide = this.slide;
    if (slide != null) {
      final Offset from = slide.offsetIn(direction) * hidden;
      if (from != Offset.zero) {
        then(Matrix4.translationValues(from.dx, from.dy, 0));
      }
    }

    final FlipProperties? flip = this.flip;
    if (flip != null && flip.turns != 0) {
      final double angle = flip.turns * 2 * math.pi * hidden;
      then(
        _about(
          flip.alignment.alongSize(size),
          Matrix4.identity()
            ..setEntry(3, 2, 1 / flip.perspective)
            ..multiply(
              flip.axis == Axis.horizontal
                  ? Matrix4.rotationX(angle)
                  : Matrix4.rotationY(angle),
            ),
        ),
      );
    }

    final RotateProperties? rotate = this.rotate;
    if (rotate != null && rotate.turns != 0) {
      then(
        _about(
          rotate.alignment.alongSize(size),
          Matrix4.rotationZ(rotate.turns * 2 * math.pi * hidden),
        ),
      );
    }

    final ZoomProperties? zoom = this.zoom;
    if (zoom != null && zoom.scale != 1) {
      final double scale = 1 + (zoom.scale - 1) * hidden;
      then(
        _about(
          zoom.alignment.alongSize(size),
          Matrix4.diagonal3Values(scale, scale, 1),
        ),
      );
    }

    return transform;
  }

  /// [transform] applied about [pivot] rather than about the top left corner.
  static Matrix4 _about(Offset pivot, Matrix4 transform) =>
      Matrix4.translationValues(pivot.dx, pivot.dy, 0)
        ..multiply(transform)
        ..multiply(Matrix4.translationValues(-pivot.dx, -pivot.dy, 0));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RevealLook &&
          other.direction == direction &&
          other.fade == fade &&
          other.slide == slide &&
          other.zoom == zoom &&
          other.blur == blur &&
          other.rotate == rotate &&
          other.flip == flip &&
          other.overlay == overlay &&
          other.wipe == wipe;

  @override
  int get hashCode => Object.hash(
        direction,
        fade,
        slide,
        zoom,
        blur,
        rotate,
        flip,
        overlay,
        wipe,
      );
}
