/// Scroll reveal widgets for Flutter, in pure Dart and with no dependencies.
///
/// [SimpleReveal] wraps a block that comes into place as it comes into view,
/// the way the sections of a web page do as it is scrolled: one from the left,
/// the next from the right, another fading in.
///
/// Each effect is configured on an object of its own, and each describes the
/// block before it is revealed: [FadeProperties] how transparent it is,
/// [SlideProperties] where it comes in from, [ZoomProperties] how large it
/// starts, [BlurProperties] how soft, [RotateProperties] how turned,
/// [FlipProperties] how turned in depth, [OverlayProperties] how tinted and
/// [WipeProperties] how much of it is uncovered. They combine freely.
///
/// The reveal plays over a duration once the block is seen, with a delay and a
/// curve, once or every time it comes back. Given a [ScrubProperties], it
/// follows the scroll instead, forwards and backwards. A [RevealController]
/// reveals, hides and plays it again from code.
///
/// Inside a block, each [RevealPart] comes in on its own once the block is
/// revealed, with effects and a delay of its own, one after the other. A
/// [SimpleRevealGroup] does the same for blocks that come into view together,
/// and [SimpleRevealDefaults] sets the pace of every reveal below it.
///
/// Only the painting moves: the layout is left alone, so nothing jumps, and
/// the content is in the semantics tree from the start. A frame of the reveal
/// costs one paint and no widget work, and a block in place pushes no layer at
/// all.
///
/// Nothing moves when the platform asks for reduced motion: blocks and parts
/// are drawn in place, unless `respectReducedMotion` is turned off.
///
/// ### Example:
/// ```dart
/// SimpleReveal(
///   slide: const SlideProperties.fromLeft(),
///   child: const Card(child: Text('Comes in from the left')),
/// );
/// ```
library;

import 'src/defaults.dart';
import 'src/properties.dart';
import 'src/simple_reveal.dart';

export 'src/defaults.dart';
export 'src/properties.dart';
export 'src/simple_reveal.dart';
