# SimpleReveal Versions

## 0.1.0

### Added

- `SimpleReveal`, a block revealed as it comes into view, in any scrollable, slivers and nested
  ones included, or outside one.
- Eight effects, each on an object of its own, combined freely: `FadeProperties`,
  `SlideProperties` (from any side, or from the start or the end of the reading direction),
  `ZoomProperties`, `BlurProperties`, `RotateProperties`, `FlipProperties` (about X or Y, in
  perspective), `OverlayProperties` (a tint that clears, kept to the shape of the block) and
  `WipeProperties` (an opening from an edge, from a point or as a circle, optionally from under a
  panel). `clipBehavior` keeps a block within its bounds while it comes in.
- `RevealPart`, pieces of a block that come in on their own once it is revealed, `stagger` apart
  in reading order, each with its effects and delay.
- A timed reveal, with `duration`, `delay`, `curve`, `threshold` and `once`.
- A reveal that follows the scroll, through `ScrubProperties`, with `reach`, `mirror` and a
  `curve` of its own.
- `RevealController`, to reveal, hide and play a block again from code, and `manual` blocks that
  wait for it alone.
- `onReveal` and `onHide`.
- `SimpleRevealGroup`, blocks that come into view together revealed in turn, in reading order.
- `SimpleRevealDefaults`, the pace of every reveal below it, and a switch to turn them all off.
- Blocks with a `PageStorageKey`, on them or on the item a list builds around them, remember they
  were revealed once a lazy list lets them go.
- Reduced motion followed by default, through `respectReducedMotion`: nothing moves, for any
  effect, part, group, scrub or controller.
- An example app, one screen per feature, and a travel page putting them together.
