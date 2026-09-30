import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// How transparent the block is before it is revealed.
///
/// Every effect describes the block as it stands before the reveal, and the
/// reveal runs it to the block as it is laid out. This one fades it in.
///
/// ---
///
/// ### Parameters:
/// - [opacity]: what the block is drawn at before the reveal, from `0`
///   (unseen) to `1` (no fade at all).
///
/// ### Example:
/// ```dart
/// SimpleReveal(
///   fade: const FadeProperties(0.2),
///   child: const Text('Chapter one'),
/// );
/// ```
class FadeProperties {
  /// Creates the fade, given the opacity the block starts at.
  const FadeProperties([this.opacity = 0])
      : assert(opacity >= 0 && opacity <= 1, 'opacity must be between 0 and 1');

  /// What the block is drawn at before the reveal.
  ///
  /// At `0` the block is not painted at all until the reveal starts, and does
  /// not answer taps. Its content stays in the semantics tree, so a screen
  /// reader reads it whether it has been revealed or not.
  final double opacity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FadeProperties && other.opacity == opacity;

  @override
  int get hashCode => opacity.hashCode;

  @override
  String toString() => 'FadeProperties($opacity)';
}

/// Where the block comes in from.
///
/// The block is drawn [dx] and [dy] logical pixels away from where it is laid
/// out, and the reveal brings it home. Only the painting moves: the layout, and
/// so the blocks around it, do not.
///
/// The named constructors cover the usual cases. [SlideProperties.fromStart]
/// and [SlideProperties.fromEnd] follow the reading direction, so a block that
/// comes in from the left in English comes in from the right in Arabic.
///
/// ---
///
/// ### Parameters:
/// - [dx]: how far right of its place the block starts, in logical pixels. A
///   negative figure starts it to the left.
/// - [dy]: how far below its place the block starts, in logical pixels. A
///   negative figure starts it above.
///
/// ### Example:
/// ```dart
/// SimpleReveal(
///   slide: const SlideProperties.fromLeft(120),
///   child: const Text('Chapter one'),
/// );
/// ```
class SlideProperties {
  /// Starts the block [dx] to the right and [dy] below its place.
  const SlideProperties(this.dx, this.dy) : directional = false;

  /// Starts the block [distance] to the left of its place.
  const SlideProperties.fromLeft([double distance = defaultDistance])
      : dx = -distance,
        dy = 0,
        directional = false;

  /// Starts the block [distance] to the right of its place.
  const SlideProperties.fromRight([double distance = defaultDistance])
      : dx = distance,
        dy = 0,
        directional = false;

  /// Starts the block [distance] above its place.
  const SlideProperties.fromTop([double distance = defaultDistance])
      : dx = 0,
        dy = -distance,
        directional = false;

  /// Starts the block [distance] below its place, so it rises into it.
  const SlideProperties.fromBottom([double distance = defaultDistance])
      : dx = 0,
        dy = distance,
        directional = false;

  /// Starts the block [distance] towards the side lines of text start from:
  /// the left in a left-to-right language, the right in a right-to-left one.
  const SlideProperties.fromStart([double distance = defaultDistance])
      : dx = -distance,
        dy = 0,
        directional = true;

  /// Starts the block [distance] towards the side lines of text end on.
  const SlideProperties.fromEnd([double distance = defaultDistance])
      : dx = distance,
        dy = 0,
        directional = true;

  /// How far the named constructors start the block from its place, in
  /// logical pixels, when they are not given a distance.
  static const double defaultDistance = 80;

  /// How far right of its place the block starts, in a left-to-right reading
  /// direction when [directional].
  final double dx;

  /// How far below its place the block starts.
  final double dy;

  /// Whether [dx] is read in the reading direction, and so turned round in a
  /// right-to-left one.
  final bool directional;

  /// Where the block starts, relative to its place, in [direction].
  Offset offsetIn(TextDirection direction) => Offset(
        directional && direction == TextDirection.rtl ? -dx : dx,
        dy,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlideProperties &&
          other.dx == dx &&
          other.dy == dy &&
          other.directional == directional;

  @override
  int get hashCode => Object.hash(dx, dy, directional);

  @override
  String toString() =>
      'SlideProperties($dx, $dy${directional ? ', directional' : ''})';
}

/// How large the block is drawn before it is revealed.
///
/// ---
///
/// ### Parameters:
/// - [scale]: the scale the block starts at. `0.8` starts it a fifth smaller
///   and grows it into place; `1.2` starts it larger and settles it.
/// - [alignment]: the point of the block the scale turns about, its middle
///   by default.
///
/// ### Example:
/// ```dart
/// SimpleReveal(
///   zoom: const ZoomProperties(0.85),
///   child: const Text('Chapter one'),
/// );
/// ```
class ZoomProperties {
  /// Creates the zoom, given the scale the block starts at.
  const ZoomProperties(this.scale, {this.alignment = Alignment.center})
      : assert(scale >= 0, 'scale cannot be negative');

  /// The scale the block starts at.
  ///
  /// Scaling up a block draws its content larger than it was laid out, text
  /// included, which goes soft while it lasts. Starting smaller than `1` is
  /// the safer way round.
  final double scale;

  /// The point of the block the scale turns about.
  final Alignment alignment;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ZoomProperties &&
          other.scale == scale &&
          other.alignment == alignment;

  @override
  int get hashCode => Object.hash(scale, alignment);

  @override
  String toString() => 'ZoomProperties($scale, alignment: $alignment)';
}

/// How blurred the block is before it is revealed.
///
/// This one is a filter rather than a transform, so it costs more than the
/// others while it runs: the block is blurred again on every frame of the
/// reveal. Once the block is in place no filter is left behind at all.
///
/// ---
///
/// ### Parameters:
/// - [sigma]: the gaussian sigma the block starts at, in logical pixels.
///
/// ### Example:
/// ```dart
/// SimpleReveal(
///   blur: const BlurProperties(12),
///   child: const Text('Chapter one'),
/// );
/// ```
class BlurProperties {
  /// Creates the blur, given the sigma the block starts at.
  const BlurProperties(this.sigma)
      : assert(sigma >= 0, 'sigma cannot be negative');

  /// The gaussian sigma the block starts at, in logical pixels.
  ///
  /// A sigma reads in pixels rather than as a fraction of the block, so the
  /// same figure blurs a small block more than a large one.
  final double sigma;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BlurProperties && other.sigma == sigma;

  @override
  int get hashCode => sigma.hashCode;

  @override
  String toString() => 'BlurProperties($sigma)';
}

/// How far the block is turned before it is revealed, in the plane of the
/// screen.
///
/// ---
///
/// ### Parameters:
/// - [turns]: the angle the block starts at, in full turns. `0.05` is
///   eighteen degrees clockwise; a negative figure turns it the other way.
/// - [alignment]: the point of the block it turns about, its middle by
///   default.
///
/// ### Example:
/// ```dart
/// SimpleReveal(
///   rotate: const RotateProperties(-0.03, alignment: Alignment.bottomLeft),
///   child: const Text('Chapter one'),
/// );
/// ```
class RotateProperties {
  /// Creates the rotation, given the angle the block starts at in turns.
  const RotateProperties(this.turns, {this.alignment = Alignment.center});

  /// The angle the block starts at, in full turns, clockwise when positive.
  final double turns;

  /// The point of the block it turns about.
  final Alignment alignment;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RotateProperties &&
          other.turns == turns &&
          other.alignment == alignment;

  @override
  int get hashCode => Object.hash(turns, alignment);

  @override
  String toString() => 'RotateProperties($turns, alignment: $alignment)';
}

/// How far the block is turned in depth before it is revealed, as a card
/// flipped over.
///
/// [FlipProperties.aroundX] swings the top and bottom edges through the
/// screen, [FlipProperties.aroundY] the left and right ones, as a door opens.
/// The block is drawn in perspective, the viewer standing [perspective]
/// logical pixels in front of it.
///
/// ---
///
/// ### Parameters:
/// - [turns]: the angle the block starts at, in full turns. `0.25` starts it
///   edge on, which is unseen; `0.15` is a strong tilt still readable.
/// - [alignment]: the point of the block it turns about, its middle by
///   default. `Alignment.topCenter` about the X axis hangs it from its top
///   edge.
/// - [perspective]: how far in front of the block the viewer stands, in
///   logical pixels. Nearer is more dramatic.
///
/// ### Example:
/// ```dart
/// SimpleReveal(
///   flip: const FlipProperties.aroundY(0.2),
///   child: const Text('Chapter one'),
/// );
/// ```
class FlipProperties {
  /// Turns the block about the horizontal line through [alignment]: a
  /// positive [turns] starts it with its top edge towards the viewer.
  const FlipProperties.aroundX(
    this.turns, {
    this.alignment = Alignment.center,
    this.perspective = defaultPerspective,
  })  : axis = Axis.horizontal,
        assert(perspective > 0, 'perspective must be positive');

  /// Turns the block about the vertical line through [alignment]: a positive
  /// [turns] starts it with its right edge towards the viewer.
  const FlipProperties.aroundY(
    this.turns, {
    this.alignment = Alignment.center,
    this.perspective = defaultPerspective,
  })  : axis = Axis.vertical,
        assert(perspective > 0, 'perspective must be positive');

  /// How far in front of the block the viewer stands when not told, in
  /// logical pixels.
  static const double defaultPerspective = 1000;

  /// The line the block turns about: [Axis.horizontal] for
  /// [FlipProperties.aroundX], [Axis.vertical] for [FlipProperties.aroundY].
  final Axis axis;

  /// The angle the block starts at, in full turns.
  final double turns;

  /// The point of the block it turns about.
  final Alignment alignment;

  /// How far in front of the block the viewer stands, in logical pixels.
  final double perspective;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlipProperties &&
          other.axis == axis &&
          other.turns == turns &&
          other.alignment == alignment &&
          other.perspective == perspective;

  @override
  int get hashCode => Object.hash(axis, turns, alignment, perspective);

  @override
  String toString() =>
      'FlipProperties.around${axis == Axis.horizontal ? 'X' : 'Y'}'
      '($turns, alignment: $alignment, perspective: $perspective)';
}

/// Ties the reveal to the scroll rather than to a clock.
///
/// Without it, a block plays its reveal over a duration once it is seen. With
/// it, how far the block is revealed follows where it stands in the viewport:
/// scrolling back hides it again, and stopping half way leaves it half
/// revealed.
///
/// The reveal starts the moment the leading edge of the block comes into the
/// viewport, and is done once that edge has come [reach] of the way across it.
/// With [mirror], the block hides again as it leaves, over the same distance
/// at the other end.
///
/// ---
///
/// ### Parameters:
/// - [reach]: how far across the viewport the leading edge of the block has
///   come when the reveal is done, from just above `0` to `1`. `0.4` has it
///   done four tenths of the way up a vertical list.
/// - [mirror]: whether the block hides again as it leaves, as its trailing
///   edge comes within [reach] of the far end.
/// - [curve]: how the reveal is eased along that distance. Linear by default,
///   so the block keeps pace with the finger.
///
/// ### Example:
/// ```dart
/// SimpleReveal(
///   slide: const SlideProperties.fromLeft(),
///   scrub: const ScrubProperties(reach: 0.5, mirror: true),
///   child: const Text('Chapter one'),
/// );
/// ```
class ScrubProperties {
  /// Creates the scrub settings.
  const ScrubProperties({
    this.reach = 0.4,
    this.mirror = false,
    this.curve = Curves.linear,
  }) : assert(reach > 0 && reach <= 1, 'reach must be above 0, at most 1');

  /// How far across the viewport the leading edge of the block has come when
  /// the reveal is done.
  ///
  /// It is measured along the viewport rather than along the crossing of the
  /// block, so a tall block and a short one are done at the same place on
  /// screen. A block the scroll cannot bring that far, near the end of a list,
  /// is done as the scroll ends instead, so it is never left part way.
  final double reach;

  /// Whether the block hides again as it leaves.
  ///
  /// A block already within [reach] of the far end when the scroll is at its
  /// start, at the top of a list, is whole there and hides from there on.
  final bool mirror;

  /// How the reveal is eased between the moment the block comes in and
  /// [reach].
  final Curve curve;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScrubProperties &&
          other.reach == reach &&
          other.mirror == mirror &&
          other.curve == curve;

  @override
  int get hashCode => Object.hash(reach, mirror, curve);

  @override
  String toString() =>
      'ScrubProperties(reach: $reach, mirror: $mirror, curve: $curve)';
}

/// A tint over the block before it is revealed, which clears as it comes in.
///
/// The tint only covers what the block draws: a card with rounded corners is
/// tinted inside its corners, a line of text on its letters, never on the
/// rectangle around them. It is blended onto the block rather than laid over
/// it.
///
/// ---
///
/// ### Parameters:
/// - [color]: a flat colour, its own alpha included. `null` when the overlay
///   was given a [gradient] instead.
/// - [gradient]: a gradient, for a tint that fades across the block. `null`
///   when the overlay was given a [color] instead.
/// - [opacity]: how strong the tint is before the reveal, on top of any alpha
///   the colour or the gradient already carries.
///
/// ### Example:
/// ```dart
/// SimpleReveal(
///   overlay: const OverlayProperties.darken(0.6),
///   child: Image.asset('assets/cover.webp'),
/// );
/// ```
class OverlayProperties {
  /// A flat colour over the block.
  const OverlayProperties(Color this.color, {this.opacity = 1})
      : gradient = null,
        assert(opacity >= 0 && opacity <= 1, 'opacity must be between 0 and 1');

  /// Black over the block, at [opacity].
  const OverlayProperties.darken(this.opacity)
      : color = const Color(0xFF000000),
        gradient = null,
        assert(opacity >= 0 && opacity <= 1, 'opacity must be between 0 and 1');

  /// White over the block, at [opacity].
  const OverlayProperties.lighten(this.opacity)
      : color = const Color(0xFFFFFFFF),
        gradient = null,
        assert(opacity >= 0 && opacity <= 1, 'opacity must be between 0 and 1');

  /// A gradient over the block.
  const OverlayProperties.gradient(Gradient this.gradient, {this.opacity = 1})
      : color = null,
        assert(opacity >= 0 && opacity <= 1, 'opacity must be between 0 and 1');

  /// Flat colour, or `null` when a [gradient] was given instead.
  final Color? color;

  /// Gradient, or `null` when a [color] was given instead.
  final Gradient? gradient;

  /// How strong the tint is before the reveal.
  final double opacity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OverlayProperties &&
          other.color == color &&
          other.gradient == gradient &&
          other.opacity == opacity;

  @override
  int get hashCode => Object.hash(color, gradient, opacity);

  @override
  String toString() => 'OverlayProperties(color: $color, gradient: $gradient, '
      'opacity: $opacity)';
}

/// Where a wipe uncovers the block from.
enum WipeFrom {
  /// The left edge.
  left,

  /// The right edge.
  right,

  /// The top edge.
  top,

  /// The bottom edge.
  bottom,

  /// The edge lines of text start from: the left in a left-to-right language.
  start,

  /// The edge lines of text end on.
  end,

  /// A point of the block, as a rectangle growing out of it.
  point,

  /// A point of the block, as a circle growing out of it.
  circle,
}

/// Uncovers the block through an opening that grows across it.
///
/// Before the reveal nothing of the block shows; the opening then grows from
/// an edge, from a point as a rectangle, or from a point as a circle, until
/// the whole block is uncovered. The opening moves with the block, so a wipe
/// combines with a slide or a zoom.
///
/// Given a [color], the part not uncovered yet is painted in it, so the block
/// comes out from under a panel. The panel is the rectangle of the block, and
/// it is drawn at full strength whatever the fade, which is what a panel over
/// a picture wants.
///
/// ---
///
/// ### Parameters:
/// - [from]: where the opening starts.
/// - [alignment]: for [WipeFrom.point] and [WipeFrom.circle], the point of the
///   block it grows out of, its middle by default.
/// - [color]: the panel over the part not uncovered yet, `null` for none.
///
/// ### Example:
/// ```dart
/// SimpleReveal(
///   fade: null,
///   wipe: const WipeProperties.fromLeft(color: Color(0xFF14110F)),
///   child: Image.asset('assets/cover.webp'),
/// );
/// ```
class WipeProperties {
  /// Opens from the left edge.
  const WipeProperties.fromLeft({this.color})
      : from = WipeFrom.left,
        alignment = Alignment.center;

  /// Opens from the right edge.
  const WipeProperties.fromRight({this.color})
      : from = WipeFrom.right,
        alignment = Alignment.center;

  /// Opens from the top edge.
  const WipeProperties.fromTop({this.color})
      : from = WipeFrom.top,
        alignment = Alignment.center;

  /// Opens from the bottom edge.
  const WipeProperties.fromBottom({this.color})
      : from = WipeFrom.bottom,
        alignment = Alignment.center;

  /// Opens from the edge lines of text start from.
  const WipeProperties.fromStart({this.color})
      : from = WipeFrom.start,
        alignment = Alignment.center;

  /// Opens from the edge lines of text end on.
  const WipeProperties.fromEnd({this.color})
      : from = WipeFrom.end,
        alignment = Alignment.center;

  /// Opens as a rectangle growing out of [alignment], the middle of the block
  /// by default.
  const WipeProperties.fromPoint({
    this.alignment = Alignment.center,
    this.color,
  }) : from = WipeFrom.point;

  /// Opens as a circle growing out of [alignment], until it reaches the
  /// farthest corner.
  const WipeProperties.circle({this.alignment = Alignment.center, this.color})
      : from = WipeFrom.circle;

  /// Where the opening starts.
  final WipeFrom from;

  /// The point a [WipeFrom.point] or [WipeFrom.circle] opening grows out of.
  final Alignment alignment;

  /// The panel over the part not uncovered yet, `null` for none.
  final Color? color;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WipeProperties &&
          other.from == from &&
          other.alignment == alignment &&
          other.color == color;

  @override
  int get hashCode => Object.hash(from, alignment, color);

  @override
  String toString() =>
      'WipeProperties(${from.name}, alignment: $alignment, color: $color)';
}
