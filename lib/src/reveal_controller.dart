part of 'simple_reveal.dart';

/// Reveals, hides and plays a [SimpleReveal] again from code.
///
/// Handed to one block through [SimpleReveal.controller], it drives that
/// block and its parts: reveal it once its data has loaded, hide it when a tab
/// is left, play it again from a button. With [SimpleReveal.manual], it is the
/// only thing that reveals the block. It notifies its listeners whenever
/// [isRevealed] changes, however it changed.
///
/// Until it is handed to a block, and after that block is gone, it does
/// nothing. Under reduced motion a reveal or a hide asked of it happens at
/// once rather than over time.
///
/// ---
///
/// ### Example:
/// ```dart
/// final RevealController reveal = RevealController();
///
/// SimpleReveal(
///   controller: reveal,
///   manual: true,
///   child: results,
/// );
///
/// // Once the results are in:
/// reveal.reveal();
/// ```
class RevealController extends ChangeNotifier {
  _SimpleRevealState? _state;

  /// Whether the block is revealed, or on its way. `true` for a block that is
  /// not enabled, which is drawn in place; `false` before a block is attached.
  bool get isRevealed {
    final _SimpleRevealState? state = _state;
    if (state == null) return false;
    return !state._enabled || state._started;
  }

  /// Reveals the block now, whether it is in sight or not.
  ///
  /// Does nothing if it is revealed already.
  void reveal() => _state?._reveal(bySight: false);

  /// Hides the block, running its reveal backwards.
  ///
  /// A block that reveals itself when seen is not revealed again by being in
  /// sight until it has gone out of it, so hiding a block on screen keeps it
  /// hidden. [reveal] brings it back at any time.
  void hide() => _state?._hide(byHand: true);

  /// Hides the block at once and plays its reveal again.
  void replay() => _state?._replay();

  void _attach(_SimpleRevealState state) {
    assert(
      _state == null || _state == state,
      'A RevealController drives one SimpleReveal at a time.',
    );
    _state = state;
  }

  void _detach(_SimpleRevealState state) {
    if (_state == state) _state = null;
  }

  void _changed() => notifyListeners();
}
