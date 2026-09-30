part of 'simple_reveal.dart';

/// The clock of a reveal played over time, shared by a block and its parts.
///
/// One play holds the progress at `0` for a lead, the delays of the block and
/// of its group or of its part, then runs it to `1` over [_runFor], eased by
/// [_easing]. Both are read when the progress is, so a new duration or curve
/// applies at once.
mixin _Clocked<T extends StatefulWidget> on State<T>, TickerProvider {
  /// The clock, made the first time one is needed.
  AnimationController? _controller;

  AnimationController get _clock =>
      _controller ??= AnimationController(vsync: this, duration: _runFor);

  /// How long the play under way holds the progress at `0`.
  Duration _lead = Duration.zero;

  /// How long the reveal itself takes.
  Duration get _runFor;

  /// How the reveal is eased.
  Curve get _easing;

  /// How far the reveal has come on the clock, with the lead held at `0` and
  /// the rest eased.
  double _clocked() {
    final double t = _controller?.value ?? 0;
    if (t >= 1) return 1;
    final int total = (_lead + _runFor).inMicroseconds;
    if (total <= 0) return 0;
    final double start = _lead.inMicroseconds / total;
    if (t <= start) return 0;
    return _easing.transform((t - start) / (1 - start));
  }

  /// Plays the reveal, holding it at `0` for [lead] first.
  ///
  /// A reveal caught on its way back runs forwards again from where it
  /// stands, rather than jumping back to the start.
  void _play(Duration lead) {
    final AnimationController clock = _clock;
    if (clock.value > 0 && clock.value < 1) {
      clock.forward();
      return;
    }
    _lead = lead;
    clock
      ..duration = lead + _runFor
      ..forward(from: 0);
  }

  /// Runs the reveal backwards to hidden, from where it stands.
  void _rewind() => _clock.reverse();

  /// Sets the reveal in place or hidden at once, stopping any play.
  void _jump({required bool shown}) => _clock.value = shown ? 1 : 0;

  /// Follows a duration changed since the play started.
  void _retime() => _controller?.duration = _lead + _runFor;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
