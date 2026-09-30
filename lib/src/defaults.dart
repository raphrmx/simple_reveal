import 'package:flutter/widgets.dart';

/// Settles, for every block below it, what a `SimpleReveal` or a `RevealPart`
/// was not told.
///
/// Put one at the top of an app, around `MaterialApp` or in its `builder`, or
/// around a page, so
/// every reveal plays at the same pace without repeating it on each block. A
/// block that sets a value itself keeps it, and one left out here falls back
/// to the package default. The nearest one wins; they do not merge.
///
/// [enabled] turns every reveal below it off at once, in a test or on a
/// device too slow for them. Reduced motion is not settled here on purpose: it
/// is followed unless a block itself says otherwise, so that one line cannot
/// turn it off for a whole app.
///
/// ---
///
/// ### Parameters:
/// - [duration]: how long a reveal takes once it starts.
/// - [curve]: how it is eased.
/// - [threshold]: how much of a block has to be seen for it to start.
/// - [once]: whether a block stays revealed once it has been.
/// - [enabled]: whether blocks are revealed at all, or simply drawn.
/// - [child]: the part of the app these settings apply to.
///
/// ### Example:
/// ```dart
/// SimpleRevealDefaults(
///   duration: const Duration(milliseconds: 800),
///   curve: Curves.easeOutQuart,
///   threshold: 0.3,
///   child: page,
/// );
/// ```
class SimpleRevealDefaults extends InheritedWidget {
  /// Settles the reveals below it.
  const SimpleRevealDefaults({
    required super.child,
    this.duration,
    this.curve,
    this.threshold,
    this.once,
    this.enabled,
    super.key,
  }) : assert(
          threshold == null || (threshold >= 0 && threshold <= 1),
          'threshold must be between 0 and 1',
        );

  /// How long a reveal takes once it starts, `null` for the package default
  /// of 600 milliseconds.
  final Duration? duration;

  /// How a reveal is eased, `null` for the package default,
  /// [Curves.easeOutCubic].
  final Curve? curve;

  /// How much of a block has to be seen for it to start, `null` for the
  /// package default of `0.2`.
  final double? threshold;

  /// Whether a block stays revealed once it has been, `null` for the package
  /// default, `true`.
  final bool? once;

  /// Whether blocks are revealed at all, `null` for the package default,
  /// `true`. When `false`, every block is drawn in place and watches nothing.
  final bool? enabled;

  /// The nearest settings above [context], `null` for none.
  static SimpleRevealDefaults? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SimpleRevealDefaults>();

  @override
  bool updateShouldNotify(SimpleRevealDefaults oldWidget) =>
      duration != oldWidget.duration ||
      curve != oldWidget.curve ||
      threshold != oldWidget.threshold ||
      once != oldWidget.once ||
      enabled != oldWidget.enabled;
}
