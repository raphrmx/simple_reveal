part of 'simple_reveal.dart';

/// Has the blocks below it come in one after the other, [interval] apart.
///
/// Blocks that come into view together, a row of cards in a grid, are revealed
/// in reading order, each [interval] after the one before, on top of its own
/// [SimpleReveal.delay]. The order is read from where the blocks are laid out,
/// so a grid that has two columns on a phone and four on a desktop needs
/// nothing more. A block that comes into view while the ones before it are
/// still waiting their turn joins the end of the line, so a quick scroll
/// through a long grid does not set everything off at once.
///
/// Scrubbed blocks follow the scroll and take no part. Under reduced motion
/// the blocks are in place anyway, and nothing waits.
///
/// ---
///
/// ### Parameters:
/// - [interval]: how long each block waits after the one before it.
/// - [child]: the part of the page whose blocks come in in turn.
///
/// ### Example:
/// ```dart
/// SimpleRevealGroup(
///   interval: const Duration(milliseconds: 120),
///   child: GridView.count(
///     crossAxisCount: columns,
///     children: <Widget>[
///       for (final Widget card in cards)
///         SimpleReveal(
///           slide: const SlideProperties.fromBottom(40),
///           child: card,
///         ),
///     ],
///   ),
/// );
/// ```
class SimpleRevealGroup extends StatefulWidget {
  /// Has the blocks below come in [interval] apart.
  const SimpleRevealGroup({
    required this.child,
    this.interval = const Duration(milliseconds: 100),
    super.key,
  });

  /// How long each block waits after the one before it.
  final Duration interval;

  /// The part of the page whose blocks come in in turn.
  final Widget child;

  @override
  State<SimpleRevealGroup> createState() => _SimpleRevealGroupState();
}

class _SimpleRevealGroupState extends State<SimpleRevealGroup> {
  /// Blocks seen in the frame under way, waiting to be put in order.
  final List<_SimpleRevealState> _queue = <_SimpleRevealState>[];
  bool _flushScheduled = false;

  /// The time of the frame the queued blocks were seen in, read while it is
  /// being handled, which is the only time the scheduler has it.
  Duration _seenAt = Duration.zero;

  /// When the last block handed a turn starts, in frame time, and so when
  /// the next may.
  Duration _nextTurn = Duration.zero;

  /// Takes [block] in, to be handed its turn with the others seen in the
  /// same frame.
  ///
  /// Blocks are seen one by one, each after the frame, so they are put in
  /// order once all of them have been, in a microtask that runs before the
  /// next frame.
  void _enqueue(_SimpleRevealState block) {
    _queue.add(block);
    if (_flushScheduled) return;
    _flushScheduled = true;
    final SchedulerBinding scheduler = SchedulerBinding.instance;
    _seenAt = scheduler.schedulerPhase == SchedulerPhase.idle
        ? _seenAt
        : scheduler.currentFrameTimeStamp;
    scheduleMicrotask(_flush);
  }

  void _flush() {
    _flushScheduled = false;
    final List<_SimpleRevealState> blocks = <_SimpleRevealState>[
      for (final _SimpleRevealState block in _queue)
        if (block.mounted) block,
    ];
    _queue.clear();
    if (!mounted || blocks.isEmpty) return;

    _sortInReadingOrder(
      blocks,
      (_SimpleRevealState block) => block.context,
      Directionality.maybeOf(context) ?? TextDirection.ltr,
    );
    final Duration now = _seenAt;
    Duration turn = _nextTurn > now ? _nextTurn : now;
    for (final _SimpleRevealState block in blocks) {
      block._start(turn - now);
      turn += widget.interval;
    }
    _nextTurn = turn;
  }

  @override
  Widget build(BuildContext context) =>
      _GroupScope(state: this, child: widget.child);
}

/// Hands the blocks below a group the group they belong to.
class _GroupScope extends InheritedWidget {
  const _GroupScope({required this.state, required super.child});

  final _SimpleRevealGroupState state;

  static _SimpleRevealGroupState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GroupScope>()?.state;

  @override
  bool updateShouldNotify(_GroupScope oldWidget) => state != oldWidget.state;
}
