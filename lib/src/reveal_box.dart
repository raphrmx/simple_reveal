import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'look.dart';

/// Draws its child part way through a reveal, read at paint.
///
/// The progress is read through [shown] when the box is painted, and [repaint]
/// says when to paint again: the clock of a timed reveal, the scroll position
/// of a scrubbed one. So a frame of the reveal costs one paint of this box and
/// no widget work at all, whatever [child] holds.
///
/// Keep a [RepaintBoundary] over the child, so its content is recorded once and
/// only the layers pushed here change from frame to frame.
class RevealBox extends SingleChildRenderObjectWidget {
  /// Draws [child] as [look] describes it, [shown] of the way through.
  const RevealBox({
    required this.look,
    required this.shown,
    required Widget super.child,
    this.clipBehavior = Clip.none,
    this.repaint,
    this.watch,
    this.onMoved,
    super.key,
  });

  /// The effects to draw the child through.
  final RevealLook look;

  /// How far the reveal has come, read at paint: `0` hidden, `1` in place.
  final double Function() shown;

  /// Whether the child is clipped to the box while the reveal runs.
  final Clip clipBehavior;

  /// Paints the box again when it notifies, `null` for never.
  final Listenable? repaint;

  /// Calls [onMoved] when it notifies, `null` for never.
  final Listenable? watch;

  /// Called when [watch] notifies, and after every paint of the box: the two
  /// moments the block may have come into sight. `null` for never.
  final VoidCallback? onMoved;

  @override
  RenderReveal createRenderObject(BuildContext context) => RenderReveal(
        look: look,
        shown: shown,
        clipBehavior: clipBehavior,
        repaint: repaint,
        watch: watch,
        onMoved: onMoved,
      );

  @override
  void updateRenderObject(BuildContext context, RenderReveal renderObject) {
    renderObject
      ..look = look
      ..shown = shown
      ..clipBehavior = clipBehavior
      ..repaint = repaint
      ..watch = watch
      ..onMoved = onMoved;
  }
}

/// The render object behind [RevealBox].
///
/// In place, which is where a block spends nearly all its life, it paints its
/// child as it stands and pushes no layer at all. Part way, it pushes, from the
/// outside in, a clip to its bounds, a transform, the opening of a wipe, an
/// opacity, a tint and a blur, each only when it changes something, and paints
/// the panel of a wipe over what is not uncovered yet.
class RenderReveal extends RenderProxyBox {
  /// Draws its child as [look] describes it, [shown] of the way through.
  RenderReveal({
    required RevealLook look,
    required double Function() shown,
    Clip clipBehavior = Clip.none,
    Listenable? repaint,
    Listenable? watch,
    VoidCallback? onMoved,
  })  : _look = look,
        _shown = shown,
        _clipBehavior = clipBehavior,
        _repaint = repaint,
        _watch = watch,
        _onMoved = onMoved;

  RevealLook _look;

  /// The effects to draw the child through.
  set look(RevealLook value) {
    if (value == _look) return;
    _look = value;
    markNeedsPaint();
  }

  double Function() _shown;

  /// How far the reveal has come, read at paint.
  set shown(double Function() value) {
    if (value == _shown) return;
    _shown = value;
    markNeedsPaint();
  }

  Clip _clipBehavior;

  /// Whether the child is clipped to the box while the reveal runs.
  set clipBehavior(Clip value) {
    if (value == _clipBehavior) return;
    _clipBehavior = value;
    markNeedsPaint();
  }

  Listenable? _repaint;

  /// Paints the box again when it notifies.
  set repaint(Listenable? value) {
    if (value == _repaint) return;
    if (attached) _repaint?.removeListener(markNeedsPaint);
    _repaint = value;
    if (attached) _repaint?.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  Listenable? _watch;

  /// Calls [onMoved] when it notifies.
  set watch(Listenable? value) {
    if (value == _watch) return;
    if (attached) _watch?.removeListener(_moved);
    _watch = value;
    if (attached) _watch?.addListener(_moved);
  }

  VoidCallback? _onMoved;

  /// Called when [watch] notifies and after every paint.
  set onMoved(VoidCallback? value) => _onMoved = value;

  void _moved() => _onMoved?.call();

  /// What the paint under way draws, read by the painters it pushes layers
  /// for.
  int _alpha = 255;
  double _sigma = 0;
  Color? _tintColor;
  Gradient? _tintGradient;
  Rect? _opening;

  final LayerHandle<ClipRectLayer> _boundsLayer = LayerHandle<ClipRectLayer>();
  final LayerHandle<TransformLayer> _transformLayer =
      LayerHandle<TransformLayer>();
  final LayerHandle<ClipRectLayer> _openingLayer = LayerHandle<ClipRectLayer>();
  final LayerHandle<ClipPathLayer> _roundOpeningLayer =
      LayerHandle<ClipPathLayer>();
  final LayerHandle<OpacityLayer> _opacityLayer = LayerHandle<OpacityLayer>();
  final LayerHandle<ColorFilterLayer> _tintLayer =
      LayerHandle<ColorFilterLayer>();
  final LayerHandle<ShaderMaskLayer> _gradientTintLayer =
      LayerHandle<ShaderMaskLayer>();
  final LayerHandle<ImageFilterLayer> _filterLayer =
      LayerHandle<ImageFilterLayer>();

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _repaint?.addListener(markNeedsPaint);
    _watch?.addListener(_moved);
  }

  @override
  void detach() {
    _repaint?.removeListener(markNeedsPaint);
    _watch?.removeListener(_moved);
    super.detach();
  }

  @override
  void dispose() {
    _clearLayers();
    super.dispose();
  }

  void _clearLayers() {
    _boundsLayer.layer = null;
    _transformLayer.layer = null;
    _clearInner();
  }

  void _clearInner() {
    _openingLayer.layer = null;
    _roundOpeningLayer.layer = null;
    _opacityLayer.layer = null;
    _tintLayer.layer = null;
    _gradientTintLayer.layer = null;
    _filterLayer.layer = null;
  }

  /// Whether the content itself shows, [shown] of the way through: at an
  /// opacity above 0, and through an opening that is not closed.
  bool _contentShowsAt(double shown) {
    if (_look.alphaAt(shown) == 0) return false;
    return _isOpen(_look.openingAt(shown, size));
  }

  /// Whether [opening] lets anything through, `null` being no wipe at all.
  static bool _isOpen(Rect? opening) =>
      opening == null || (opening.width > 0 && opening.height > 0);

  @override
  void paint(PaintingContext context, Offset offset) {
    _moved();
    if (child == null) return;

    final double shown = _shown();
    if (shown == 1) {
      _clearLayers();
      context.paintChild(child!, offset);
      return;
    }
    if (!_look.drawsAt(shown, size)) {
      // Nothing to see, so nothing to paint.
      _clearLayers();
      return;
    }

    _alpha = _look.alphaAt(shown);
    _sigma = _look.sigmaAt(shown);
    _tintColor = _look.tintColorAt(shown);
    _tintGradient = _look.tintGradientAt(shown);
    _opening = _look.openingAt(shown, size);
    final Matrix4? transform = _look.transformAt(shown, size);

    void paintMoved(PaintingContext context, Offset offset) {
      if (transform == null) {
        _transformLayer.layer = null;
        _paintOpened(context, offset);
      } else {
        _transformLayer.layer = context.pushTransform(
          needsCompositing,
          offset,
          transform,
          _paintOpened,
          oldLayer: _transformLayer.layer,
        );
      }
    }

    if (_clipBehavior == Clip.none) {
      _boundsLayer.layer = null;
      paintMoved(context, offset);
    } else {
      _boundsLayer.layer = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        paintMoved,
        clipBehavior: _clipBehavior,
        oldLayer: _boundsLayer.layer,
      );
    }
  }

  /// The content through the opening of the wipe, and the panel over what the
  /// opening has not uncovered yet.
  void _paintOpened(PaintingContext context, Offset offset) {
    final Rect? opening = _opening;
    if (_alpha == 0 || !_isOpen(opening)) {
      _clearInner();
    } else if (opening == null) {
      _openingLayer.layer = null;
      _roundOpeningLayer.layer = null;
      _paintFaded(context, offset);
    } else if (_look.roundOpening) {
      _openingLayer.layer = null;
      _roundOpeningLayer.layer = context.pushClipPath(
        needsCompositing,
        offset,
        Offset.zero & size,
        Path()..addOval(opening),
        _paintFaded,
        oldLayer: _roundOpeningLayer.layer,
      );
    } else {
      _roundOpeningLayer.layer = null;
      _openingLayer.layer = context.pushClipRect(
        needsCompositing,
        offset,
        opening,
        _paintFaded,
        oldLayer: _openingLayer.layer,
      );
    }

    final Color? panel = _look.wipe?.color;
    if (panel == null || opening == null) return;
    final Path covered = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(offset & size);
    if (_look.roundOpening) {
      covered.addOval(opening.shift(offset));
    } else {
      covered.addRect(opening.shift(offset));
    }
    context.canvas.drawPath(covered, Paint()..color = panel);
  }

  void _paintFaded(PaintingContext context, Offset offset) {
    if (_alpha == 255) {
      _opacityLayer.layer = null;
      _paintTinted(context, offset);
    } else {
      _opacityLayer.layer = context.pushOpacity(
        offset,
        _alpha,
        _paintTinted,
        oldLayer: _opacityLayer.layer,
      );
    }
  }

  /// The content under the tint of the overlay, blended onto what it draws so
  /// the tint keeps to its shape.
  void _paintTinted(PaintingContext context, Offset offset) {
    final Color? color = _tintColor;
    final Gradient? gradient = _tintGradient;
    if (color != null) {
      _gradientTintLayer.layer = null;
      _tintLayer.layer = context.pushColorFilter(
        offset,
        ColorFilter.mode(color, BlendMode.srcATop),
        _paintBlurred,
        oldLayer: _tintLayer.layer,
      );
    } else if (gradient != null) {
      _tintLayer.layer = null;
      final ShaderMaskLayer mask =
          _gradientTintLayer.layer ??= ShaderMaskLayer();
      mask
        ..shader = gradient.createShader(
          Offset.zero & size,
          textDirection: _look.direction,
        )
        ..maskRect = offset & size
        ..blendMode = BlendMode.srcATop;
      context.pushLayer(mask, _paintBlurred, offset);
    } else {
      _tintLayer.layer = null;
      _gradientTintLayer.layer = null;
      _paintBlurred(context, offset);
    }
  }

  void _paintBlurred(PaintingContext context, Offset offset) {
    if (_sigma <= 0) {
      _filterLayer.layer = null;
      context.paintChild(child!, offset);
      return;
    }
    final ImageFilterLayer filter = _filterLayer.layer ??= ImageFilterLayer();
    // Decal rather than clamped: the edges of a block fade out as it softens,
    // where clamping would smear them.
    filter.imageFilter = ui.ImageFilter.blur(
      sigmaX: _sigma,
      sigmaY: _sigma,
      tileMode: TileMode.decal,
    );
    context.pushLayer(
      filter,
      (PaintingContext context, Offset offset) =>
          context.paintChild(child!, offset),
      offset,
    );
  }

  /// The transform the child is drawn through as the reveal stands now, `null`
  /// for none.
  ///
  /// Worked out afresh rather than kept from the last paint: a block waiting
  /// in the cache extent of a list is laid out but not painted, and a tap or a
  /// position read from inside it still has to land where it will be drawn.
  Matrix4? _transformNow() {
    final double shown = _shown();
    return shown == 1 ? null : _look.transformAt(shown, size);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final double shown = _shown();
    if (shown == 1) return super.hitTest(result, position: position);
    // Nothing to see, so nothing to tap, and nothing outside a clip either.
    if (!_contentShowsAt(shown)) return false;
    if (_clipBehavior != Clip.none && !size.contains(position)) return false;

    final Matrix4? transform = _look.transformAt(shown, size);
    if (transform == null) return super.hitTest(result, position: position);
    // Tested where the child is drawn, which may lie outside the box.
    return result.addWithPaintTransform(
      transform: transform,
      position: position,
      hitTest: (BoxHitTestResult result, Offset position) =>
          hitTestChildren(result, position: position),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final Matrix4? own = _transformNow();
    if (own != null) transform.multiply(own);
  }
}
