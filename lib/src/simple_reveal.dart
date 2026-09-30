import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'defaults.dart';
import 'look.dart';
import 'properties.dart';
import 'reveal_box.dart';
import 'sight.dart';

part 'reveal_clock.dart';
part 'reveal_controller.dart';
part 'reveal_group.dart';
part 'reveal_part.dart';

/// How long a reveal takes when neither the block nor a
/// [SimpleRevealDefaults] says.
const Duration _defaultDuration = Duration(milliseconds: 600);

/// How a reveal is eased when neither the block nor a [SimpleRevealDefaults]
/// says.
const Curve _defaultCurve = Curves.easeOutCubic;

/// A block that fades, slides, zooms, blurs, turns, flips, clears or opens into
/// place as it comes into view.
///
/// Each effect describes the block before the reveal: [fade] how transparent
/// it is, [slide] where it comes in from, [zoom] how large it starts, [blur]
/// how soft, [rotate] how turned, [flip] how turned in depth, [overlay] how
/// tinted, [wipe] how much of it is uncovered. The reveal runs all of them to
/// the block as it is laid out. They combine freely, and only a [fade] is on by
/// default: pass `fade: null` to reveal without one.
///
/// By default the reveal plays over [duration], once [threshold] of the block
/// can be seen, after [delay] and eased by [curve]. Given [scrub], it follows
/// the scroll instead: how far the block is revealed is read from where it
/// stands in the viewport, and scrolling back runs the reveal backwards.
/// Given a [controller], it can also be revealed, hidden and played again from
/// code, and with [manual] only from code.
///
/// Pieces of the content can come in on their own once the block is revealed:
/// wrap each in a [RevealPart], with effects and a delay of its own, and they
/// follow one another [stagger] apart, in reading order.
///
/// The block finds the scrollables around it on its own, so it works inside a
/// [ListView], a [CustomScrollView] and its slivers, a [PageView], a carousel
/// inside a page or any other scrollable, whichever way they run. Outside a
/// scrollable it is revealed as soon as it is laid out within the screen, which
/// suits the top of a landing page.
///
/// Only the painting moves. The block keeps its place in the layout from the
/// first frame, so nothing around it jumps as it comes in, and its content is
/// in the semantics tree from the start, so a screen reader reads it whether it
/// has been revealed or not.
///
/// When the platform asks for reduced motion, nothing moves: the block and its
/// parts are drawn in place, without a single frame of any effect, unless
/// [respectReducedMotion] is turned off. [onReveal] and [onHide] still fire
/// when they would have, and a block hidden or revealed through its
/// [controller] still is, at once rather than over time.
///
/// ---
///
/// ### Parameters:
/// - [child]: the block to reveal.
/// - [fade], [slide], [zoom], [blur], [rotate], [flip], [overlay] and [wipe]:
///   the block before the reveal, each `null` for none.
/// - [clipBehavior]: whether the block is kept within its bounds while the
///   reveal runs, for a slide that rises from an invisible line.
/// - [duration], [curve], [threshold] and [once]: how the reveal plays, each
///   `null` for the [SimpleRevealDefaults] above, or the package default.
/// - [delay]: how long it waits once the block is seen, or told to.
/// - [stagger]: how far apart the [RevealPart]s inside come in.
/// - [scrub]: ties the reveal to the scroll instead, `null` for a timed one.
/// - [scrollAxis]: the axis of the scrollable a [scrub] follows, `null` for
///   the nearest one.
/// - [controller]: reveals, hides and plays the block again from code.
/// - [manual]: whether only the [controller] reveals the block.
/// - [enabled]: whether the block is revealed at all, or simply drawn.
/// - [onReveal] and [onHide]: called as the block is revealed and hidden.
/// - [respectReducedMotion]: whether the block is drawn in place when the
///   platform asks for reduced motion.
///
/// ### Example:
/// ```dart
/// ListView(
///   children: const <Widget>[
///     SimpleReveal(
///       slide: SlideProperties.fromLeft(),
///       child: Card(child: Text('Comes in from the left')),
///     ),
///     SimpleReveal(
///       slide: SlideProperties.fromRight(),
///       child: Card(child: Text('Then from the right')),
///     ),
///   ],
/// );
/// ```
///
/// A section whose title, text and button come in one after the other:
/// ```dart
/// SimpleReveal(
///   fade: null,
///   stagger: const Duration(milliseconds: 150),
///   child: Column(
///     children: <Widget>[
///       RevealPart(
///         slide: const SlideProperties.fromBottom(30),
///         child: Text('Our story', style: headline),
///       ),
///       RevealPart(child: Text(body)),
///       RevealPart(
///         zoom: const ZoomProperties(0.8),
///         delay: const Duration(milliseconds: 200),
///         child: FilledButton(onPressed: onRead, child: const Text('Read')),
///       ),
///     ],
///   ),
/// );
/// ```
///
/// A block that follows the scroll, in on the way up and out on the way off:
/// ```dart
/// SimpleReveal(
///   slide: const SlideProperties.fromStart(160),
///   blur: const BlurProperties(8),
///   scrub: const ScrubProperties(mirror: true),
///   child: const Text('Chapter one'),
/// );
/// ```
class SimpleReveal extends StatefulWidget {
  /// Creates a block revealed as it comes into view.
  const SimpleReveal({
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
    this.threshold,
    this.once,
    this.stagger = Duration.zero,
    this.scrub,
    this.scrollAxis,
    this.controller,
    this.manual = false,
    this.enabled,
    this.onReveal,
    this.onHide,
    this.respectReducedMotion = true,
    super.key,
  })  : assert(
          threshold == null || (threshold >= 0 && threshold <= 1),
          'threshold must be between 0 and 1',
        ),
        assert(
          scrub == null || (controller == null && !manual),
          'a scrubbed reveal follows the scroll, not a controller',
        );

  /// The block to reveal.
  final Widget child;

  /// How transparent the block starts, `null` for no fade.
  final FadeProperties? fade;

  /// Where the block comes in from, `null` for where it stands.
  final SlideProperties? slide;

  /// How large the block starts, `null` for its own size.
  final ZoomProperties? zoom;

  /// How blurred the block starts, `null` for sharp.
  final BlurProperties? blur;

  /// How far the block starts turned in the plane of the screen, `null` for
  /// straight.
  final RotateProperties? rotate;

  /// How far the block starts turned in depth, `null` for flat.
  ///
  /// The block is zoomed and turned first, then flipped, so it can come in
  /// both turned and flipped; [slide] moves the result.
  final FlipProperties? flip;

  /// How tinted the block starts, `null` for its own colours.
  final OverlayProperties? overlay;

  /// How the block is uncovered, `null` for all of it at once.
  final WipeProperties? wipe;

  /// Whether the block is kept within its bounds while the reveal runs.
  ///
  /// [Clip.none] by default, so a block sliding in is seen on its way. Any
  /// other value hides what lies outside the place of the block, so a line of
  /// text sliding up out of `SlideProperties.fromBottom` rises from an
  /// invisible line. Once in place the block is not clipped at all.
  final Clip clipBehavior;

  /// How long the reveal takes once it starts, `null` for the
  /// [SimpleRevealDefaults] above, or 600 milliseconds. Not read with a
  /// [scrub].
  final Duration? duration;

  /// How long the reveal waits once the block is seen, or told to by its
  /// [controller]. Not read with a [scrub].
  ///
  /// Blocks that come into view together, a row of cards for instance, come
  /// in one after the other when each waits a little longer than the last. A
  /// [SimpleRevealGroup] works that out on its own.
  final Duration delay;

  /// How the reveal is eased over [duration], `null` for the
  /// [SimpleRevealDefaults] above, or [Curves.easeOutCubic]. Not read with a
  /// [scrub], which takes a curve of its own.
  ///
  /// A curve that overshoots, such as [Curves.easeOutBack], carries the block
  /// past its place and back, which gives a slide or a zoom a bounce.
  final Curve? curve;

  /// How much of the block has to be seen for the reveal to start, from `0`
  /// to `1`, on each axis. `null` for the [SimpleRevealDefaults] above, or
  /// `0.2`. Not read with a [scrub].
  ///
  /// A block larger than the viewport is measured against the viewport
  /// instead, so it is not held back until a share of it that cannot fit on
  /// screen has come in.
  final double? threshold;

  /// Whether the block stays revealed once it has been, `null` for the
  /// [SimpleRevealDefaults] above, or `true`. Not read with a [scrub].
  ///
  /// When `false`, the block is hidden again the moment it is out of sight,
  /// where no one sees it happen, and plays its reveal each time it comes back.
  ///
  /// In a list that builds its children lazily, a block scrolled far enough
  /// away is disposed, and comes back as a new one. Give it a [PageStorageKey],
  /// or give one to the widget the list builds around it, and it remembers it
  /// was revealed: it comes back in place rather than playing again. A key on
  /// the list itself, or further up, is shared by every block in the list, so
  /// a block does not remember by it.
  final bool? once;

  /// How far apart the [RevealPart]s inside the block come in, in reading
  /// order, on top of the delay each has of its own.
  final Duration stagger;

  /// Ties the reveal to the scroll, `null` for a reveal played over
  /// [duration].
  ///
  /// Outside a scrollable, a scrubbed block is drawn in place. The
  /// [RevealPart]s of a scrubbed block play over time, as the block starts
  /// coming in, and back as it goes out again.
  final ScrubProperties? scrub;

  /// The axis of the scrollable a [scrub] follows, or `null` for the nearest
  /// scrollable, whichever way it runs. Not read without a [scrub].
  ///
  /// Only needed when scrollables are nested: a block in a horizontal carousel
  /// inside a vertical page follows the carousel by default, and the page with
  /// `Axis.vertical`.
  ///
  /// A timed reveal needs no such choice: it waits until the block can be seen
  /// through every scrollable around it.
  final Axis? scrollAxis;

  /// Reveals, hides and plays the block again from code, `null` for none.
  ///
  /// A controller drives one block at a time. It cannot drive a scrubbed one,
  /// which follows the scroll.
  final RevealController? controller;

  /// Whether the block waits for its [controller] rather than for being seen.
  ///
  /// A manual block is hidden until [RevealController.reveal] is called, for a
  /// block revealed once its data has loaded, or on a tap.
  final bool manual;

  /// Whether the block is revealed at all, `null` for the
  /// [SimpleRevealDefaults] above, or `true`.
  ///
  /// When `false`, the block and its parts are drawn in place, nothing is
  /// watched and no callback fires. Turning it on and off keeps the content,
  /// and its state, where it was.
  final bool? enabled;

  /// Called as the block is revealed: once it is seen, or told to by its
  /// [controller], before any delay runs. With a [scrub], as it starts coming
  /// in.
  ///
  /// Where to count a section as viewed, start a video or a counter.
  final VoidCallback? onReveal;

  /// Called as the block is hidden again: out of sight with [once] off, told
  /// to by its [controller], or, with a [scrub], scrolled back out.
  final VoidCallback? onHide;

  /// Whether nothing moves when the platform asks for reduced motion, through
  /// [MediaQueryData.disableAnimations].
  ///
  /// Content moving into place is one of the motions the setting exists to
  /// stop, which is why it is followed by default. The block and its parts are
  /// then drawn in place from the first frame, and a hide or a reveal asked of
  /// the [controller] happens at once.
  final bool respectReducedMotion;

  @override
  State<SimpleReveal> createState() => _SimpleRevealState();
}

/// The progress of a block drawn in place.
double _inPlace() => 1;

/// Whether a block is revealed in place under reduced motion, or hidden.
enum _Still { shown, hidden }

class _SimpleRevealState extends State<SimpleReveal>
    with SingleTickerProviderStateMixin<SimpleReveal>, _Clocked<SimpleReveal> {
  SimpleRevealDefaults? _defaults;
  _SimpleRevealGroupState? _group;

  /// Whether the platform asks for reduced motion, as of the last lookup.
  bool _reduce = false;

  /// Whether the block is revealed, or on its way: seen, or told to.
  bool _started = false;

  /// Whether the block was hidden through its controller while in sight, and
  /// waits to have gone out of it before it is revealed by sight again.
  bool _held = false;

  /// Where the block remembers it was revealed, `null` without a
  /// [PageStorageKey] to tell it apart.
  _RevealMemory? _memory;
  bool _memoryRead = false;

  /// The parts inside the block, in the order they joined it.
  final List<_RevealPartState> _parts = <_RevealPartState>[];

  /// The scrollables a timed reveal looks through, nearest first.
  List<ScrollableState> _scrollables = const <ScrollableState>[];

  /// Their scroll positions, merged, as handed to the box to watch.
  Listenable? _positions;
  List<ScrollPosition> _watched = const <ScrollPosition>[];

  /// The screen, in the same coordinates as the block.
  Rect _view = Rect.largest;

  /// The scrollable a scrub follows, `null` outside one.
  ScrollableState? _followed;

  bool _checkScheduled = false;
  bool _rebuildScheduled = false;

  /// Whether the block was enabled as of the last look, `null` before the
  /// first: turning it on or off changes what its controller reads.
  bool? _enabledBefore;

  @override
  Duration get _runFor =>
      widget.duration ?? _defaults?.duration ?? _defaultDuration;

  @override
  Curve get _easing => widget.curve ?? _defaults?.curve ?? _defaultCurve;

  double get _threshold => widget.threshold ?? _defaults?.threshold ?? 0.2;

  bool get _once => widget.once ?? _defaults?.once ?? true;

  bool get _enabled => widget.enabled ?? _defaults?.enabled ?? true;

  bool get _still => widget.respectReducedMotion && _reduce;

  bool get _scrubbing => widget.scrub != null;

  /// How the block is drawn under reduced motion: hidden only when a hand has
  /// hidden it, or a manual block has not been revealed yet.
  _Still get _stillState =>
      _held || (widget.manual && !_started) ? _Still.hidden : _Still.shown;

  /// Whether the block is watched, for coming into sight or going out of it.
  bool get _watching {
    if (!_enabled) return false;
    if (_scrubbing) {
      return widget.onReveal != null ||
          widget.onHide != null ||
          _parts.isNotEmpty;
    }
    if (widget.manual) return false;
    return !_started || !_once;
  }

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _defaults = SimpleRevealDefaults.maybeOf(context);
    _group = _GroupScope.maybeOf(context);
    final bool wasStill = _still;
    _reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!_memoryRead) {
      _memoryRead = true;
      _restore();
    }
    if (_still && !wasStill) _settle();
    _retime();
    _noteEnabled();
  }

  @override
  void didUpdateWidget(SimpleReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if ((widget.scrub == null) != (oldWidget.scrub == null)) {
      // The two ways of revealing keep their state apart: start again hidden,
      // and let the next look say what the other way makes of it.
      _started = false;
      _held = false;
      _jump(shown: false);
      for (final _RevealPartState part in _parts) {
        part._jump(shown: false);
      }
    }
    _retime();
    if (_still) _settle();
    _noteEnabled();
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    super.dispose();
  }

  /// Tells the controller when turning the block on or off changed what it
  /// reads, after the frame, as this runs while the tree is being built.
  void _noteEnabled() {
    final bool enabled = _enabled;
    final bool? before = _enabledBefore;
    _enabledBefore = enabled;
    if (before == null || before == enabled || widget.controller == null) {
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) widget.controller?._changed();
    });
  }

  /// Brings a reveal under way to its end at once, for reduced motion.
  void _settle() {
    if (_scrubbing || !_started) return;
    _jump(shown: true);
    for (final _RevealPartState part in _parts) {
      part._jump(shown: true);
    }
  }

  // Revealing and hiding.

  /// Reveals the block: once seen when [bySight], or when told to.
  void _reveal({required bool bySight}) {
    if (_started || !_enabled) return;
    _started = true;
    _held = false;
    if (_still) {
      _jump(shown: true);
      _startParts(Duration.zero);
    } else if (bySight && _group != null) {
      _group!._enqueue(this);
    } else {
      _start(Duration.zero);
    }
    _remember(revealed: true);
    _changed();
    widget.onReveal?.call();
  }

  /// Starts the reveal on its clock, [after] a wait handed out by a group,
  /// then the block's own [SimpleReveal.delay].
  void _start(Duration after) {
    // Hidden again, or gone, while it waited its turn.
    if (!mounted || !_started) return;
    final Duration lead = after + widget.delay;
    _play(lead);
    _startParts(lead);
  }

  /// Hides the block: by a hand, run backwards, or out of sight, at once.
  void _hide({required bool byHand}) {
    if (!_enabled) return;
    if (!_started) {
      // Hidden already; a hand still keeps it from being revealed by sight
      // while it stays in view.
      if (byHand && !widget.manual) {
        _held = true;
        _changed();
      }
      return;
    }
    _started = false;
    _held = byHand && !widget.manual;
    if (byHand && !_still) {
      _rewind();
      for (final _RevealPartState part in _parts) {
        part._rewind();
      }
    } else {
      _jump(shown: false);
      for (final _RevealPartState part in _parts) {
        part._jump(shown: false);
      }
    }
    _remember(revealed: false);
    _changed();
    widget.onHide?.call();
  }

  /// Hides the block at once and reveals it again.
  void _replay() {
    if (!_enabled) return;
    if (_started) {
      _started = false;
      _jump(shown: false);
      for (final _RevealPartState part in _parts) {
        part._jump(shown: false);
      }
      widget.onHide?.call();
    }
    _held = false;
    _reveal(bySight: false);
  }

  /// Tells the controller, lets the box stop or start watching, and paints it
  /// again: under reduced motion how it is drawn hangs on the state alone.
  void _changed() {
    widget.controller?._changed();
    context.findRenderObject()?.markNeedsPaint();
    if (_rebuildScheduled) return;
    _rebuildScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      _rebuildScheduled = false;
      if (mounted) setState(() {});
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  // Parts.

  void _attachPart(_RevealPartState part) {
    _parts.add(part);
    if (!_started) return;
    // Joining a block already revealed: in place if its reveal is over,
    // played on its own if it is under way, after whatever the block still
    // waits and its turn among the parts.
    final AnimationController? clock = _controller;
    if (_still || _scrubbing || clock == null || clock.isCompleted) {
      part._jump(shown: true);
    } else {
      part._play(_leadLeft(clock) + widget.stagger * (_parts.length - 1));
    }
  }

  /// How much longer the play under way on [clock] holds the block at `0`.
  Duration _leadLeft(AnimationController clock) {
    if (!clock.isAnimating) return Duration.zero;
    final Duration left =
        _lead - (clock.duration ?? Duration.zero) * clock.value;
    return left > Duration.zero ? left : Duration.zero;
  }

  void _detachPart(_RevealPartState part) => _parts.remove(part);

  /// Plays the parts [lead] after now, [SimpleReveal.stagger] apart in reading
  /// order.
  void _startParts(Duration lead) {
    if (_parts.isEmpty) return;
    if (_still) {
      for (final _RevealPartState part in _parts) {
        part._jump(shown: true);
      }
      return;
    }
    final List<_RevealPartState> ordered = List<_RevealPartState>.of(_parts);
    // Read where the parts are laid out in the block, not where the block,
    // turned or flipped before its reveal, draws them.
    final RenderObject? box = context.findRenderObject();
    _sortInReadingOrder(
      ordered,
      (_RevealPartState part) => part.context,
      Directionality.maybeOf(context) ?? TextDirection.ltr,
      within: box is RenderReveal ? box.child : null,
    );
    for (int i = 0; i < ordered.length; i++) {
      ordered[i]._play(lead + widget.stagger * i);
    }
  }

  // Remembering.

  void _restore() {
    if (_scrubbing || !_once || !_enabled) return;
    _memory = _RevealMemory.of(context);
    final _RevealMemory? memory = _memory;
    if (memory == null) return;
    if (PageStorage.maybeOf(context)?.readState(context, identifier: memory) ==
        true) {
      _started = true;
      _jump(shown: true);
    }
  }

  void _remember({required bool revealed}) {
    final _RevealMemory? memory = _memory;
    if (memory == null || !_once) return;
    PageStorage.maybeOf(context)
        ?.writeState(context, revealed, identifier: memory);
  }

  // Watching.

  /// How far a scrubbed reveal has come, measured where the block stands now.
  double _scrubbed() => _measureScrub() ?? 1;

  double? _measureScrub() {
    final ScrollableState? followed = _followed;
    final ScrubProperties? scrub = widget.scrub;
    final RenderObject? block = context.findRenderObject();
    if (followed == null || scrub == null || block is! RenderBox) return null;
    return scrubOf(followed, block, scrub);
  }

  /// Whether some of the block can be seen, as of now.
  bool get _inSight {
    final RenderObject? block = context.findRenderObject();
    if (block is! RenderBox) return false;
    return sightOf(block, _scrollables, view: _view, threshold: 0) != Sight.out;
  }

  /// How a timed block is drawn under reduced motion.
  double _stillShown() => _stillState == _Still.hidden ? 0 : 1;

  /// Looks again at the next frame, once the layout it will read is settled.
  ///
  /// A scroll notifies before the viewport has laid its content out again, so
  /// measuring there would read the frame before. Several notifications in one
  /// frame are looked at once.
  void _schedule() {
    if (_checkScheduled || !_watching) return;
    _checkScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((Duration _) => _check());
  }

  void _check() {
    _checkScheduled = false;
    if (!mounted || !_watching) return;

    if (_scrubbing) {
      final double? shown = _measureScrub();
      if (shown == null) return;
      if (shown > 0 && !_started) {
        _started = true;
        _startParts(Duration.zero);
        widget.onReveal?.call();
      } else if (shown == 0 && _started) {
        _started = false;
        for (final _RevealPartState part in _parts) {
          _still ? part._jump(shown: false) : part._rewind();
        }
        widget.onHide?.call();
      }
      return;
    }

    final RenderObject? block = context.findRenderObject();
    if (block is RenderBox) {
      switch (sightOf(
        block,
        _scrollables,
        view: _view,
        threshold: _threshold,
      )) {
        case Sight.shown when !_started && !_held:
          _reveal(bySight: true);
        case Sight.out when _held:
          _held = false;
          _changed();
        case Sight.out when _started && !_once:
          _hide(byHand: false);
        case _:
          break;
      }
    }

    // A block still waiting can come into view with no scroll and no paint of
    // its own: on a page sliding in, or as the content above it changes. So
    // it looks again after the next frame, whenever there is one. Waiting for
    // a frame does not ask for one, so a still screen costs nothing.
    if (!_started || _held) _schedule();
  }

  @override
  Widget build(BuildContext context) {
    // Checked here, a const constructor having no way to compare durations.
    assert(_runFor >= Duration.zero, 'duration cannot be negative');
    assert(widget.delay >= Duration.zero, 'delay cannot be negative');
    assert(widget.stagger >= Duration.zero, 'stagger cannot be negative');
    final Widget box = _enabled ? _box(context) : _plain(context);
    return _RevealScope(
      state: this,
      still: _still,
      enabled: _enabled,
      child: box,
    );
  }

  /// The block drawn in place, watching nothing.
  Widget _plain(BuildContext context) => RevealBox(
        look: _lookOf(context),
        shown: _inPlace,
        child: RepaintBoundary(child: widget.child),
      );

  Widget _box(BuildContext context) {
    final RevealLook look = _lookOf(context);
    // Recorded once, so a frame of the reveal only moves layers over it.
    final Widget child = RepaintBoundary(child: widget.child);

    if (_scrubbing) {
      final Axis? axis = widget.scrollAxis;
      _followed = axis == null
          ? Scrollable.maybeOf(context)
          : Scrollable.maybeOf(context, axis: axis);
      final ScrollPosition? position = _followed?.position;
      return RevealBox(
        look: look,
        shown: _still ? _inPlace : _scrubbed,
        clipBehavior: widget.clipBehavior,
        repaint: _still ? null : position,
        watch: position,
        onMoved: _schedule,
        child: child,
      );
    }

    final bool watching = _watching;
    if (watching) {
      // Rebuilt when the nearest scrollable swaps its position, and when the
      // window is resized, which moves the block without a scroll.
      Scrollable.maybeOf(context);
      final Size? screen = MediaQuery.maybeSizeOf(context);
      _view = screen == null ? Rect.largest : Offset.zero & screen;
      _scrollables = scrollablesAround(context);
      final List<ScrollPosition> positions = <ScrollPosition>[
        for (final ScrollableState scrollable in _scrollables)
          scrollable.position,
      ];
      if (!listEquals(positions, _watched)) {
        _watched = positions;
        _positions = positions.isEmpty ? null : Listenable.merge(positions);
      }
    }

    return RevealBox(
      look: look,
      shown: _still ? _stillShown : _clocked,
      clipBehavior: widget.clipBehavior,
      repaint: _clock,
      watch: watching ? _positions : null,
      onMoved: watching ? _schedule : null,
      child: child,
    );
  }

  RevealLook _lookOf(BuildContext context) => RevealLook(
        direction: Directionality.maybeOf(context) ?? TextDirection.ltr,
        fade: widget.fade,
        slide: widget.slide,
        zoom: widget.zoom,
        blur: widget.blur,
        rotate: widget.rotate,
        flip: widget.flip,
        overlay: widget.overlay,
        wipe: widget.wipe,
      );
}

/// Hands the parts inside a block the block they belong to.
class _RevealScope extends InheritedWidget {
  const _RevealScope({
    required this.state,
    required this.still,
    required this.enabled,
    required super.child,
  });

  final _SimpleRevealState state;
  final bool still;
  final bool enabled;

  static _SimpleRevealState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_RevealScope>()?.state;

  @override
  bool updateShouldNotify(_RevealScope oldWidget) =>
      state != oldWidget.state ||
      still != oldWidget.still ||
      enabled != oldWidget.enabled;
}

/// Where a block remembers it was revealed: the [PageStorageKey]s on it and
/// around it, as [PageStorage] itself tells blocks apart.
///
/// Only a block with a key of its own remembers: on it, or on a widget between
/// it and the nearest scrollable, such as the item a list builds around it. A
/// key on the list or above it is shared by every block in the list.
///
/// Kept under an identifier of its own rather than the one [PageStorage] would
/// work out, which a scrollable inside the block uses for its offset.
@immutable
class _RevealMemory {
  const _RevealMemory(this.keys);

  final List<PageStorageKey<dynamic>> keys;

  /// The memory of the block at [context], `null` without a [PageStorageKey]
  /// of its own.
  static _RevealMemory? of(BuildContext context) {
    final List<PageStorageKey<dynamic>> keys = <PageStorageKey<dynamic>>[];
    final Key? key = context.widget.key;
    bool own = false;
    if (key is PageStorageKey<dynamic>) {
      keys.add(key);
      own = true;
    }
    bool inItem = true;
    context.visitAncestorElements((Element element) {
      if (element.widget is Scrollable) inItem = false;
      final Key? key = element.widget.key;
      if (key is PageStorageKey<dynamic>) {
        keys.add(key);
        own = own || inItem;
      }
      return true;
    });
    return own ? _RevealMemory(keys) : null;
  }

  @override
  bool operator ==(Object other) =>
      other is _RevealMemory && listEquals(other.keys, keys);

  @override
  int get hashCode => Object.hashAll(keys);
}

/// Sorts [items] in reading order by where [contextOf] each is laid out: row
/// by row, then from the side lines start in [direction]. Items not laid out
/// yet keep their order, after the others.
///
/// Positions are read within [within], an ancestor of every item, or on the
/// screen when `null`.
void _sortInReadingOrder<T>(
  List<T> items,
  BuildContext Function(T item) contextOf,
  TextDirection direction, {
  RenderObject? within,
}) {
  final RenderObject? ancestor =
      within != null && within.attached ? within : null;
  Rect? rectOf(T item) {
    final RenderObject? box = contextOf(item).findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return MatrixUtils.transformRect(
      box.getTransformTo(ancestor),
      Offset.zero & box.size,
    );
  }

  final Map<T, Rect?> rects = <T, Rect?>{
    for (final T item in items) item: rectOf(item),
  };
  mergeSort<T>(
    items,
    compare: (T a, T b) {
      final Rect? ra = rects[a];
      final Rect? rb = rects[b];
      if (ra == null || rb == null) {
        return ra == null ? (rb == null ? 0 : 1) : -1;
      }
      // Tops within a pixel are one row.
      if ((ra.top - rb.top).abs() > 1) return ra.top.compareTo(rb.top);
      return direction == TextDirection.rtl
          ? rb.right.compareTo(ra.right)
          : ra.left.compareTo(rb.left);
    },
  );
}
