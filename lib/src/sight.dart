/// Where a block stands against the scrollables around it.
///
/// Both measures read the block as it is laid out, not as it is drawn: a block
/// sliding in from off screen is seen when its place is, which is where the
/// reader is looking.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'properties.dart';

/// How much of a block can be seen.
enum Sight {
  /// None of it.
  out,

  /// Some of it, not enough to reveal it.
  partly,

  /// Enough of it to reveal it.
  shown,
}

/// Every scrollable around [context], nearest first.
///
/// All of them clip the block, so all of them decide what can be seen of it:
/// a card in a carousel in a page is out of sight if either has scrolled it
/// away.
List<ScrollableState> scrollablesAround(BuildContext context) {
  final List<ScrollableState> all = <ScrollableState>[];
  context.visitAncestorElements((Element element) {
    if (element case StatefulElement(state: final ScrollableState state)) {
      all.add(state);
    }
    return true;
  });
  return all;
}

/// How much of [block] can be seen through every one of [scrollables] and
/// within [view], `null` while there is no geometry to measure.
///
/// The block is [Sight.shown] once [threshold] of it can be seen on each axis.
/// A block larger than the room it has is measured against that room instead,
/// so a block taller than the screen is revealed once [threshold] of the screen
/// is taken by it, not [threshold] of the block. A block with no extent on an
/// axis is seen on that axis as soon as it lies within the room.
Sight? sightOf(
  RenderBox block,
  List<ScrollableState> scrollables, {
  required Rect view,
  required double threshold,
}) {
  if (!block.attached || !block.hasSize) return null;

  // Most blocks still waiting are well outside the nearest scrollable. That is
  // told through a walk up to it alone, shorter than the one to the screen.
  if (scrollables.isNotEmpty) {
    final RenderObject? near = scrollables.first.context.findRenderObject();
    if (near is! RenderBox || !near.attached || !near.hasSize) return null;
    final Rect local = MatrixUtils.transformRect(
      block.getTransformTo(near),
      Offset.zero & block.size,
    );
    if (!_meets(local, Offset.zero & near.size)) return Sight.out;
  }

  final Rect rect = _globalRect(block);
  Rect room = view;
  for (final ScrollableState scrollable in scrollables) {
    final RenderObject? box = scrollable.context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    room = room.intersect(_globalRect(box));
  }
  if (!_meets(rect, room)) return Sight.out;

  final Rect seen = rect.intersect(room);
  bool enough(double seen, double block, double room) =>
      block == 0 || seen >= threshold * math.min(block, room) - _tolerance;
  return enough(seen.width, rect.width, room.width) &&
          enough(seen.height, rect.height, room.height)
      ? Sight.shown
      : Sight.partly;
}

/// Whether [rect] shares some of [room] on both axes: an overlap on an axis
/// where it has an extent, lying within [room] on one where it has none.
bool _meets(Rect rect, Rect room) {
  bool along(double start, double end, double from, double to) =>
      start == end ? start >= from && start <= to : start < to && end > from;
  return along(rect.left, rect.right, room.left, room.right) &&
      along(rect.top, rect.bottom, room.top, room.bottom);
}

/// Slack for a block exactly at the threshold, which the transforms leave a
/// hair short of it.
const double _tolerance = 1e-6;

Rect _globalRect(RenderBox box) =>
    MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);

/// How far [block] is revealed by the scroll of [scrollable], from `0` to `1`,
/// `null` while there is no geometry to measure.
///
/// The reveal runs as the leading edge of the block comes in from the end of
/// the viewport content enters by, and is done once that edge has come
/// [ScrubProperties.reach] of the way across. With [ScrubProperties.mirror],
/// it runs backwards as the trailing edge nears the other end.
///
/// The ends are those of the scroll, not of the screen: a reversed list brings
/// the block in from the top, and a right-to-left one from the left.
double? scrubOf(
  ScrollableState scrollable,
  RenderBox block,
  ScrubProperties scrub,
) {
  final RenderObject? scrollBox = scrollable.context.findRenderObject();
  if (scrollBox is! RenderBox || !scrollBox.hasSize || !block.hasSize) {
    return null;
  }

  final ScrollPosition position = scrollable.position;
  if (!position.hasViewportDimension) return null;
  final double viewport = position.viewportDimension;
  if (viewport <= 0) return null;

  final bool horizontal = position.axis == Axis.horizontal;
  final double extent = horizontal ? block.size.width : block.size.height;
  final Offset at = block.localToGlobal(Offset.zero, ancestor: scrollBox);
  final double start = horizontal ? at.dx : at.dy;
  // Distance from the far end, the one blocks leave by, to the leading edge.
  final double lead = axisDirectionIsReversed(scrollable.axisDirection)
      ? viewport - start - extent
      : start;

  final double span = scrub.reach * viewport;
  double shown = ((viewport - lead) / span).clamp(0.0, 1.0);
  if (scrub.mirror) {
    shown = math.min(shown, ((lead + extent) / span).clamp(0.0, 1.0));
  }
  return scrub.curve.transform(shown);
}
