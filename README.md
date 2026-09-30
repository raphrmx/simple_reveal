# Simple Reveal

Scroll reveal for Flutter, in pure Dart with no dependencies. Blocks fade, slide, zoom, blur, turn,
flip, clear or open into place as they come into view, the way the sections of a web page do, and
the pieces inside them can follow one after the other.

<p>
  <img src="https://public.comapps.be/packages/simple_reveal/page.webp" alt="A travel page whose photo settles, whose title comes in piece by piece, and whose sections, figures and photos come in as it scrolls" width="640">
</p>
<p>
  <img src="https://public.comapps.be/packages/simple_reveal/sides.webp" alt="Rows coming in from the left, then from the right" width="330">
  &nbsp;
  <img src="https://public.comapps.be/packages/simple_reveal/effects.webp" alt="Rows revealed by a zoom, a blur, a flip, a turn and a slide" width="330">
</p>
<p>
  <img src="https://public.comapps.be/packages/simple_reveal/curtains.webp" alt="Photos uncovered by a wipe, a circle, a panel and a tint that clears" width="330">
  &nbsp;
  <img src="https://public.comapps.be/packages/simple_reveal/scrub.webp" alt="Rows following the scroll, in on the way down and back out on the way up" width="330">
</p>

[![Live demo](https://img.shields.io/badge/Live_demo-packages.comapps.be-3c9a70)](https://packages.comapps.be/simple_reveal/)
[![Pub Version](https://img.shields.io/pub/v/simple_reveal?color=0175C2)](https://pub.dev/packages/simple_reveal)
[![Build](https://img.shields.io/github/actions/workflow/status/raphrmx/simple_reveal/ci.yml?branch=main&label=build)](https://github.com/raphrmx/simple_reveal/actions/workflows/ci.yml)
![Maintainer](https://img.shields.io/badge/Maintainer-Raphael_Vrient-733d90)
[![Licence](https://img.shields.io/badge/Licence-MIT-8C6A3F)](LICENSE)
![Platforms](https://img.shields.io/badge/Platforms-Android,_iOS,_macOS,_Windows,_Linux,_Web-22375C.svg)

## Install

```sh
flutter pub add simple_reveal
```

Requires Flutter 3.13 or later.

## One block

```dart
SimpleReveal(
  child: Card(child: Text('Fades in once seen')),
);
```

## From either side

```dart
ListView(
  children: <Widget>[
    for (int i = 0; i < sections.length; i++)
      SimpleReveal(
        slide: i.isEven
            ? const SlideProperties.fromLeft()
            : const SlideProperties.fromRight(),
        child: sections[i],
      ),
  ],
);
```

That is all it takes. Everything below is optional.

## Effects

Each effect describes the block before it is revealed, and the reveal runs it to the block as it is
laid out. They combine freely:

```dart
SimpleReveal(
  fade: const FadeProperties(),
  slide: const SlideProperties.fromBottom(40),
  zoom: const ZoomProperties(0.9),
  blur: const BlurProperties(8),
  rotate: const RotateProperties(-0.02),
  flip: const FlipProperties.aroundX(-0.15),
  overlay: const OverlayProperties.darken(0.6),
  wipe: const WipeProperties.fromStart(),
  child: card,
);
```

| Parameter | Before the reveal |
| --- | --- |
| `fade` | Transparent, `0` by default. On unless you pass `fade: null`. |
| `slide` | Away from its place, in pixels: `.fromLeft`, `.fromRight`, `.fromTop`, `.fromBottom`, and `.fromStart` and `.fromEnd`, which follow the reading direction. |
| `zoom` | At another scale: `0.8` grows into place, `1.2` settles into it. |
| `blur` | Soft, as a sigma in pixels. |
| `rotate` | Turned in the plane of the screen, in turns. |
| `flip` | Turned in depth, in perspective: `.aroundX` like a flap, `.aroundY` like a door. |
| `overlay` | Tinted: `.darken`, `.lighten`, a colour or a `.gradient`, clearing as it comes in. The tint keeps to what the block draws, rounded corners and text included. |
| `wipe` | Covered, then uncovered from an edge, from a point as a rectangle, or as a `.circle`. Given a `color`, it comes out from under a panel. |

`zoom`, `rotate` and `flip` turn about an `alignment`, the middle of the block by default.
`clipBehavior: Clip.hardEdge` keeps the block within its bounds while it comes in, so a title
sliding up out of `.fromBottom` rises from an invisible line.

## Pieces one after the other

Wrap pieces of a block in `RevealPart`, as deep as they sit. Once the block is revealed they come
in one after the other, `stagger` apart in reading order, each with its own effects and delay:

```dart
SimpleReveal(
  fade: null, // the block holds still, its pieces move
  stagger: const Duration(milliseconds: 150),
  child: Column(
    children: <Widget>[
      RevealPart(
        slide: const SlideProperties.fromBottom(40),
        clipBehavior: Clip.hardEdge,
        child: Text('Built to last', style: headline),
      ),
      RevealPart(blur: const BlurProperties(6), child: Text(body)),
      RevealPart(
        zoom: const ZoomProperties(0.6),
        curve: Curves.easeOutBack,
        delay: const Duration(milliseconds: 200),
        child: FilledButton(onPressed: onStart, child: const Text('Start')),
      ),
    ],
  ),
);
```

Parts take the block's duration and curve unless given their own, and follow it in everything
else: hidden with it, played again with it, in place with it.

## Timing

```dart
SimpleReveal(
  duration: const Duration(milliseconds: 800),
  delay: const Duration(milliseconds: 200),
  curve: Curves.easeOutBack,
  threshold: 0.5,
  once: false,
  child: card,
);
```

- `threshold` is how much of the block has to be on screen for it to start, `0.2` by default. A
  block taller than the screen is measured against the screen.
- `once: false` hides the block again once it is out of sight, and plays the reveal each time it
  comes back.
- A curve that overshoots, such as `Curves.easeOutBack`, gives a slide or a zoom a bounce.

A `SimpleRevealGroup` has the blocks below it that come into view together come in one after the
other, in reading order, so a grid needs no delay worked out by hand, whatever its number of
columns:

```dart
SimpleRevealGroup(
  interval: const Duration(milliseconds: 120),
  child: GridView.count(crossAxisCount: columns, children: revealedCards),
);
```

A `SimpleRevealDefaults` sets the duration, curve, threshold and `once` of every block below it,
and `enabled: false` turns them all off, in a test for instance.

## From code

```dart
final RevealController controller = RevealController();

SimpleReveal(
  controller: controller,
  manual: true, // waits for the controller alone
  onReveal: () => analytics.sectionViewed('pricing'),
  child: results,
);

controller.reveal(); // then hide(), replay(), isRevealed
```

`onReveal` and `onHide` fire as the block comes and goes, whether it was seen or told to.

## Following the scroll

With `scrub`, the reveal follows the scroll instead of a clock: a block half way in is half
revealed, and scrolling back runs it backwards.

```dart
SimpleReveal(
  slide: const SlideProperties.fromLeft(200),
  scrub: const ScrubProperties(reach: 0.5, mirror: true),
  child: card,
);
```

The reveal starts as the leading edge of the block comes in, and is done once that edge is `reach`
of the way across the viewport. `mirror` hides it again as it leaves at the other end.

## Reduced motion

When the platform asks for reduced motion, nothing moves, whatever the effect: blocks and their
parts are drawn in place from the first frame, groups hold nothing back, a scrubbed block does not
follow the scroll, and a reveal or a hide asked of a controller happens at once. `onReveal` and
`onHide` still fire, so a section is still counted as viewed. Pass `respectReducedMotion: false`
on a block to keep its reveal regardless; `SimpleRevealDefaults` deliberately cannot turn it off
for a whole app.

## Good to know

- Only the painting moves. The block keeps its place in the layout from the first frame, so
  nothing around it jumps.
- It works in any scrollable, either axis, reversed or not, slivers included: put it in a
  `SliverList`, a `SliverGrid` or a `SliverToBoxAdapter`. Nested ones too: a card in a carousel
  inside a page waits until both have brought it into view. With `scrub`, `scrollAxis` picks which
  one it follows.
- Outside a scrollable, the block is revealed as soon as it is laid out on screen, which suits the
  top of a landing page.
- A block not yet revealed stays in the semantics tree, so a screen reader reads it all the same.
  While nothing of it shows it does not answer taps.
- In a list built lazily, a block scrolled far away is disposed. Give it a `PageStorageKey` and it
  comes back in place rather than playing again.
- On a desktop and in a browser, Flutter lands each wheel notch in one step, and a scrubbed block
  steps with it. The example eases the wheel with a controller of its own, in
  `example/lib/smooth_wheel.dart`; the package leaves the scroll views to you.

Every parameter is documented in the
[API reference](https://pub.dev/documentation/simple_reveal/latest/).

## Performance

A frame of the reveal repaints the block and rebuilds no widget: its content sits in a repaint
boundary, recorded once, and only the layers of the effects over it change. A block in place
pushes no effect layer at all, so a page of revealed blocks costs little more than the same page
without them. A block waiting to be revealed looks at the scroll once per frame at most, and stops
once revealed. The blur is the one effect worth profiling on an older phone while it runs.

## Example

`example/` holds one screen per feature.

```sh
cd example && flutter run
```

## License

MIT, see [LICENSE](LICENSE).
