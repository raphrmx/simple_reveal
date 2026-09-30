/// What the tests share: the app around a widget, a block to reveal, and ways
/// to scroll it and read back where it is drawn.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_reveal/simple_reveal.dart';

Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Marks the content of the block under test.
const Key blockKey = Key('block');

/// A block of 100 by 100, the size every geometry in the tests is worked out
/// from.
const Widget testBlock = SizedBox(key: blockKey, width: 100, height: 100);

/// A slide of 100 straight up with nothing else, so how far the block still has
/// to go reads as how far it is from being revealed, in hundredths.
const SlideProperties rise = SlideProperties(0, 100);

/// A timed reveal of [rise] alone over a second, linear, so a time reads as a
/// progress.
SimpleReveal timedBlock({
  Duration delay = Duration.zero,
  double threshold = 0.2,
  bool once = true,
  bool respectReducedMotion = true,
  Widget child = testBlock,
}) =>
    SimpleReveal(
      fade: null,
      slide: rise,
      duration: const Duration(seconds: 1),
      delay: delay,
      curve: Curves.linear,
      threshold: threshold,
      once: once,
      respectReducedMotion: respectReducedMotion,
      child: child,
    );

/// A scrubbed reveal of [rise] alone, done half way across the viewport.
SimpleReveal scrubbedBlock({
  bool mirror = false,
  Axis? scrollAxis,
  Widget child = testBlock,
}) =>
    SimpleReveal(
      fade: null,
      slide: rise,
      scrub: ScrubProperties(reach: 0.5, mirror: mirror),
      scrollAxis: scrollAxis,
      child: child,
    );

/// Where the content of the block is drawn, relative to its place in the
/// layout.
///
/// Offstage blocks are included: a block waiting in the cache extent of a
/// list, below the viewport, is exactly what several tests look at.
Offset drawnOffset(WidgetTester tester) =>
    tester.getTopLeft(find.byKey(blockKey, skipOffstage: false)) -
    tester.getTopLeft(find.byType(SimpleReveal, skipOffstage: false));

/// How far the block still has to rise, `100` hidden and `0` in place, for a
/// block revealed by [rise].
double stillToRise(WidgetTester tester) => drawnOffset(tester).dy;

/// Starts the clock of a reveal that was triggered on the frame before: a
/// ticker started after a frame takes its first tick, at zero, on the next.
Future<void> startClock(WidgetTester tester) => tester.pump();

/// The position of the scroll view found by [finder], the first by default.
ScrollPosition scrollPosition(WidgetTester tester, [Finder? finder]) => tester
    .state<ScrollableState>(finder ?? find.byType(Scrollable).first)
    .position;

/// Scrolls the view found by [finder] to [offset] and lets the frame that
/// follows, and the look taken after it, run.
Future<void> scrollTo(
  WidgetTester tester,
  double offset, [
  Finder? finder,
]) async {
  scrollPosition(tester, finder).jumpTo(offset);
  await tester.pump();
}

/// [child] on a platform that asks for reduced motion.
Widget reducedMotion(Widget child) => Builder(
      builder: (BuildContext context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child,
      ),
    );

/// A vertical list with the block [top] down it, and room to scroll it off.
Widget listWith(Widget block, {double top = 700, bool reverse = false}) =>
    ListView(
      reverse: reverse,
      children: <Widget>[
        SizedBox(height: top),
        Align(alignment: Alignment.topLeft, child: block),
        const SizedBox(height: 2000),
      ],
    );

/// A horizontal list with the block [start] along it, and room to scroll it
/// off.
Widget rowWith(Widget block, {double start = 900}) => ListView(
      scrollDirection: Axis.horizontal,
      children: <Widget>[
        SizedBox(width: start),
        Align(alignment: Alignment.topLeft, child: block),
        const SizedBox(width: 2000),
      ],
    );

/// The opacity layers pushed under the block, which a block in place has none
/// of.
Iterable<OpacityLayer> opacityLayers(WidgetTester tester) =>
    tester.layers.whereType<OpacityLayer>();

/// Where the content keyed [key] is drawn, relative to its place in the
/// layout inside the nearest [wrapper] around it, a [SimpleReveal] or a
/// [RevealPart].
Offset drawnOffsetOf(WidgetTester tester, Key key, Type wrapper) {
  final Finder content = find.byKey(key, skipOffstage: false);
  final Finder around = find
      .ancestor(
        of: content,
        matching: find.byType(wrapper, skipOffstage: false),
      )
      .first;
  return tester.getTopLeft(content) - tester.getTopLeft(around);
}

/// How far the content keyed [key] still has to rise, for a reveal of [rise]
/// in the nearest [wrapper] around it.
double stillToRiseOf(
  WidgetTester tester,
  Key key, [
  Type wrapper = SimpleReveal,
]) =>
    drawnOffsetOf(tester, key, wrapper).dy;

/// A block of 100 by 100 marked with [key].
Widget keyedBlock(Key key) => SizedBox(key: key, width: 100, height: 100);

/// A part rising by [rise] alone over a second, linear, around a block keyed
/// [key].
RevealPart risingPart(Key key, {Duration delay = Duration.zero}) => RevealPart(
      fade: null,
      slide: rise,
      duration: const Duration(seconds: 1),
      curve: Curves.linear,
      delay: delay,
      child: keyedBlock(key),
    );

/// How many layers of the kinds an effect pushes are on screen: transforms,
/// opacities, clips, tints and filters. A repaint boundary is not one of them.
int effectLayers(WidgetTester tester) => tester.layers
    .where(
      (Layer layer) =>
          layer is TransformLayer ||
          layer is OpacityLayer ||
          layer is ClipRectLayer ||
          layer is ClipPathLayer ||
          layer is ColorFilterLayer ||
          layer is ShaderMaskLayer ||
          layer is ImageFilterLayer,
    )
    .length;
