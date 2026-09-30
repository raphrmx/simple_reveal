part of 'simple_reveal.dart';

/// A piece of the content of a [SimpleReveal] that comes in on its own once
/// the block is revealed.
///
/// Wrap a title, a line of text, a button or a picture inside a block, as deep
/// as it sits, and it plays its own reveal when the block does: with effects
/// of its own, [delay] after the block starts, and [SimpleReveal.stagger] after
/// the part before it in reading order. Three texts in a block come in one
/// after the other that way, each its own way.
///
/// It follows the block in everything else: hidden with it, played again with
/// it, in place with it under reduced motion, and drawn as it stands outside a
/// block or in one that is not enabled. [duration] and [curve] default to the
/// block's. It takes no threshold of its own: it is the block that is seen.
///
/// Leave the block itself with `fade: null` and no other effect to have only
/// the parts move, or give it effects too, and the parts come in within a block
/// that is coming in.
///
/// ---
///
/// ### Parameters:
/// - [child]: the piece to reveal.
/// - [fade], [slide], [zoom], [blur], [rotate], [flip], [overlay] and [wipe]:
///   the piece before its reveal, as on [SimpleReveal].
/// - [clipBehavior]: whether the piece is kept within its bounds while it
///   comes in.
/// - [duration] and [curve]: how it plays, `null` for the block's.
/// - [delay]: how long it waits after the block starts, on top of its turn.
///
/// ### Example:
/// ```dart
/// SimpleReveal(
///   fade: null,
///   stagger: const Duration(milliseconds: 150),
///   child: Column(
///     children: <Widget>[
///       RevealPart(
///         slide: const SlideProperties.fromLeft(60),
///         child: Text('Built to last', style: headline),
///       ),
///       RevealPart(
///         slide: const SlideProperties.fromBottom(20),
///         child: Text(body),
///       ),
///       RevealPart(
///         zoom: const ZoomProperties(0.6),
///         curve: Curves.easeOutBack,
///         delay: const Duration(milliseconds: 300),
///         child: FilledButton(onPressed: onStart, child: const Text('Start')),
///       ),
///     ],
///   ),
/// );
/// ```
class RevealPart extends StatefulWidget {
  /// Creates a piece that comes in with the block around it.
  const RevealPart({
    required this.child,
    this.fade = const FadeProperties(),
    this.slide,
    this.zoom,
    this.blur,
    this.rotate,
    this.flip,
    this.overlay,
    this.wipe,
    this.clipBehavior = Clip.none,
    this.duration,
    this.delay = Duration.zero,
    this.curve,
    super.key,
  });

  /// The piece to reveal.
  final Widget child;

  /// How transparent the piece starts, `null` for no fade.
  final FadeProperties? fade;

  /// Where the piece comes in from, `null` for where it stands.
  final SlideProperties? slide;

  /// How large the piece starts, `null` for its own size.
  final ZoomProperties? zoom;

  /// How blurred the piece starts, `null` for sharp.
  final BlurProperties? blur;

  /// How far the piece starts turned, `null` for straight.
  final RotateProperties? rotate;

  /// How far the piece starts turned in depth, `null` for flat.
  final FlipProperties? flip;

  /// How tinted the piece starts, `null` for its own colours.
  final OverlayProperties? overlay;

  /// How the piece is uncovered, `null` for all of it at once.
  final WipeProperties? wipe;

  /// Whether the piece is kept within its bounds while it comes in.
  final Clip clipBehavior;

  /// How long the piece takes to come in, `null` for the block's duration.
  final Duration? duration;

  /// How long the piece waits after the block starts, on top of its turn in
  /// the [SimpleReveal.stagger].
  final Duration delay;

  /// How the piece is eased, `null` for the block's curve.
  final Curve? curve;

  @override
  State<RevealPart> createState() => _RevealPartState();
}

class _RevealPartState extends State<RevealPart>
    with SingleTickerProviderStateMixin<RevealPart>, _Clocked<RevealPart> {
  /// The block the piece belongs to, `null` outside one.
  _SimpleRevealState? _block;

  @override
  Duration get _runFor =>
      widget.duration ?? _block?._runFor ?? _defaultDuration;

  @override
  Curve get _easing => widget.curve ?? _block?._easing ?? _defaultCurve;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final _SimpleRevealState? block = _RevealScope.maybeOf(context);
    if (block != _block) {
      _block?._detachPart(this);
      _block = block;
      block?._attachPart(this);
    }
    _retime();
  }

  @override
  void didUpdateWidget(RevealPart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _retime();
  }

  @override
  void dispose() {
    _block?._detachPart(this);
    super.dispose();
  }

  /// Plays the piece [lead] after now, then its own delay.
  @override
  void _play(Duration lead) => super._play(lead + widget.delay);

  /// How the piece is drawn under reduced motion: as its block is.
  double _stillShown() {
    final _SimpleRevealState? block = _block;
    if (block == null || block._scrubbing) return 1;
    return block._stillState == _Still.hidden ? 0 : 1;
  }

  @override
  Widget build(BuildContext context) {
    final _SimpleRevealState? block = _block;
    final double Function() shown;
    if (block == null || !block._enabled) {
      shown = _inPlace;
    } else if (block._still) {
      shown = _stillShown;
    } else {
      shown = _clocked;
    }

    return RevealBox(
      look: RevealLook(
        direction: Directionality.maybeOf(context) ?? TextDirection.ltr,
        fade: widget.fade,
        slide: widget.slide,
        zoom: widget.zoom,
        blur: widget.blur,
        rotate: widget.rotate,
        flip: widget.flip,
        overlay: widget.overlay,
        wipe: widget.wipe,
      ),
      shown: shown,
      clipBehavior: widget.clipBehavior,
      repaint: _clock,
      child: RepaintBoundary(child: widget.child),
    );
  }
}
