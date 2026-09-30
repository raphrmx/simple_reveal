import 'package:flutter/widgets.dart';

/// How long one wheel notch is eased over.
const Duration _wheelDuration = Duration(milliseconds: 220);

/// The curve a wheel notch is eased on.
const Curve _wheelCurve = Curves.easeOutCubic;

/// A [ScrollController] whose position eases the mouse wheel in.
///
/// A [Scrollable] lands a whole wheel notch on one frame, so on a desktop or
/// in a browser the page steps rather than scrolls, and a reveal that follows
/// the scroll steps with it. This has each notch animated instead. Dragging,
/// flinging and [ScrollPosition.jumpTo] behave as they do on any scroll view.
///
/// The example keeps it to itself: the package reveals blocks and leaves the
/// scroll views to the app.
class SmoothWheelController extends ScrollController {
  /// Creates a controller that eases the wheel while [eased].
  SmoothWheelController({this.eased = true});

  /// Whether a notch is eased rather than landed at once. Read on every notch.
  bool eased;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) =>
      _SmoothWheelPosition(
        physics: physics,
        context: context,
        oldPosition: oldPosition,
        initialPixels: initialScrollOffset,
        eased: () => eased,
      );
}

class _SmoothWheelPosition extends ScrollPositionWithSingleContext {
  _SmoothWheelPosition({
    required super.physics,
    required super.context,
    required bool Function() eased,
    super.oldPosition,
    super.initialPixels,
  }) : _eased = eased;

  final bool Function() _eased;

  /// Where the notch being eased is headed, `null` when none is.
  double? _target;

  @override
  void pointerScroll(double delta) {
    if (delta == 0 || !_eased()) {
      _target = null;
      super.pointerScroll(delta);
      return;
    }
    // A notch arriving while another runs carries on from where that one was
    // headed, so a quick turn of the wheel adds up rather than restarting.
    final double from = _target ?? pixels;
    final double to =
        (from + delta).clamp(minScrollExtent, maxScrollExtent).toDouble();
    if (to == pixels) {
      _target = null;
      return;
    }
    _target = to;
    animateTo(to, duration: _wheelDuration, curve: _wheelCurve).whenComplete(
      () {
        if (_target == to) _target = null;
      },
    );
  }

  @override
  void jumpTo(double value) {
    _target = null;
    super.jumpTo(value);
  }

  @override
  void applyUserOffset(double delta) {
    _target = null;
    super.applyUserOffset(delta);
  }
}

/// Builds a scroll view on a [SmoothWheelController] of its own.
///
/// The easing is off when the platform asks for reduced motion, where a notch
/// lands at once as it would anywhere else.
class SmoothWheel extends StatefulWidget {
  /// Builds the scroll view through [builder], which has to hand it the
  /// controller it is given.
  const SmoothWheel({required this.builder, super.key});

  /// Builds the scroll view on the controller it is handed.
  final Widget Function(BuildContext context, ScrollController controller)
      builder;

  @override
  State<SmoothWheel> createState() => _SmoothWheelState();
}

class _SmoothWheelState extends State<SmoothWheel> {
  final SmoothWheelController _controller = SmoothWheelController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _controller.eased = !MediaQuery.disableAnimationsOf(context);
    return widget.builder(context, _controller);
  }
}
