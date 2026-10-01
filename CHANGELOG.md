# SimpleReveal Versions

## 0.1.3

### Added

- Lists loaded page by page: a README section on using the package with
  `infinite_scroll_pagination`, a screen of the example that fetches its rows a page at a time, and
  tests for a list that grows while in view. No change to the package itself.

## 0.1.2

### Changed

- No change to the package itself.
- The pub.dev screenshots open on a cover.
- The README links to the new video tour.

## 0.1.1

### Fixed

- A scrubbed block that the end of the scroll stops short of its `reach`, the last rows of a list,
  is done as the scroll ends, rather than left part way.
- With `mirror`, a scrubbed block already near the far end when the scroll starts, at the top of a
  list, is whole there rather than part hidden.
- The panel of a wipe given a `color` keeps to what the block draws, as the tint of an overlay
  does, rather than covering its whole rectangle: a picture with rounded corners comes out from
  under a panel with the same corners. The panel now fades with the block; leave the fade out for
  a panel at full strength from the start.

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
