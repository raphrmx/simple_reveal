import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:simple_reveal/simple_reveal.dart';

import 'showcase.dart';
import 'smooth_wheel.dart';

void main() => runApp(const ExampleApp());

const Color _ink = Color(0xFF14110F);
const Color _card = Color(0xF7FCFAF8);
const Color _dusk = Color(0xFF241C18);
const Color _muted = Color(0xFF6B635C);

/// One entry of the content revealed, the same copy on every screen.
class _Note {
  const _Note(this.dot, this.title, this.detail);

  final Color dot;
  final String title;
  final String detail;
}

const List<_Note> _notes = <_Note>[
  _Note(
    Color(0xFF2F6FED),
    'Coastal ridge',
    'Eleven kilometres, four hours, no shade after the pass.',
  ),
  _Note(
    Color(0xFFE0446B),
    'Trail notes',
    'Water at the refuge only. The upper section stays icy.',
  ),
  _Note(
    Color(0xFF2FA36B),
    'Gear list',
    'Poles, two litres, a shell. Leave the rope behind.',
  ),
  _Note(
    Color(0xFFEBB53C),
    'Weather',
    'Clear until the afternoon, then wind from the south.',
  ),
  _Note(
    Color(0xFF7A5AF0),
    'Getting there',
    'Bus at 6.40 from the village, last one back at 19.10.',
  ),
  _Note(
    Color(0xFFE8734A),
    'Permits',
    'None needed below the col. The reserve asks for one.',
  ),
  _Note(
    Color(0xFF3FB6C4),
    'Signal',
    'Patchy along the ridge, nothing at all in the valley.',
  ),
];

/// The note a row at [index] shows, cycling through [_notes].
_Note _noteAt(int index) => _notes[index % _notes.length];

/// Stands in for the platform's reduced motion setting, so every demo can be
/// seen the way someone who turned it on sees it.
final ValueNotifier<bool> _reduceMotion = ValueNotifier<bool>(false);

/// Every combination the package offers, behind a menu.
class ExampleApp extends StatelessWidget {
  /// Creates the example app.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Reveal',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _DragScrollBehavior(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE07A3F),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: _dusk,
        useMaterial3: true,
      ),
      // The switch on the menu reaches the demos the way the platform would,
      // through MediaQuery.
      builder: (BuildContext context, Widget? child) =>
          ValueListenableBuilder<bool>(
        valueListenable: _reduceMotion,
        builder: (BuildContext context, bool reduce, Widget? _) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations:
                reduce || MediaQuery.disableAnimationsOf(context),
          ),
          child: child!,
        ),
      ),
      home: const _Menu(),
    );
  }
}

/// Lets a mouse drag a scroll view.
///
/// Flutter hands dragging to touch, stylus and trackpad, never to a mouse, so a
/// sideways list has nothing to drag with on a desktop.
class _DragScrollBehavior extends MaterialScrollBehavior {
  const _DragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class _Menu extends StatelessWidget {
  const _Menu();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SmoothWheel(
          builder: (BuildContext context, ScrollController controller) =>
              ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
            children: <Widget>[
              const Text(
                'Simple Reveal',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Blocks that come into place as they come into view: faded, '
                'slid, zoomed, blurred, turned or flipped, on a timer or with '
                'the scroll.',
                style: TextStyle(fontSize: 15, color: Color(0x99FFFFFF)),
              ),
              const SizedBox(height: 20),
              const _ReduceMotionSwitch(),
              const _Section('Put together'),
              _entry(
                context,
                'A travel page',
                'A landing page whose sections come in as it scrolls',
                const ShowcaseDemo(),
              ),
              const _Section('Played once seen'),
              _entry(
                context,
                'From either side',
                'One block from the left, the next from the right',
                const SidesDemo(),
              ),
              _entry(
                context,
                'Every effect',
                'Each one on its own, then a few together',
                const EffectsDemo(),
              ),
              _entry(
                context,
                'One after the other',
                'A grid whose cards come in in turn, in reading order',
                const StaggerDemo(),
              ),
              _entry(
                context,
                'Pieces one after the other',
                'A title, a text and a button, each its own way',
                const PartsDemo(),
              ),
              _entry(
                context,
                'Tints and curtains',
                'Clearing a tint, opening a wipe, rising from a line',
                const TintWipeDemo(),
              ),
              _entry(
                context,
                'From code',
                'Revealed on a tap, hidden, played again, counted',
                const ControllerDemo(),
              ),
              _entry(
                context,
                'Every time it comes back',
                'Hidden again once out of sight, played again',
                const ReplayDemo(),
              ),
              _entry(
                context,
                'A carousel in a page',
                'Cards revealed as either one brings them in',
                const CarouselDemo(),
              ),
              _entry(
                context,
                'Five hundred rows',
                'Built one at a time as they scroll in',
                const BuilderDemo(),
              ),
              const _Section('Following the scroll'),
              _entry(
                context,
                'Scrubbed',
                'As far in as the scroll has brought it',
                const ScrubDemo(),
              ),
              _entry(
                context,
                'In and out again',
                'Revealed on the way up, hidden on the way off',
                const MirrorDemo(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _entry(
    BuildContext context,
    String label,
    String detail,
    Widget demo,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (BuildContext context) => demo),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0x99FFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0x66FFFFFF)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A heading over a group of menu entries.
class _Section extends StatelessWidget {
  const _Section(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.4,
          color: Color(0x99FFFFFF),
        ),
      ),
    );
  }
}

/// Turns [_reduceMotion] on and off.
class _ReduceMotionSwitch extends StatelessWidget {
  const _ReduceMotionSwitch();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x14FFFFFF),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: ValueListenableBuilder<bool>(
        valueListenable: _reduceMotion,
        builder: (BuildContext context, bool reduce, Widget? _) =>
            SwitchListTile(
          value: reduce,
          onChanged: (bool value) => _reduceMotion.value = value,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          title: const Text(
            'Reduce motion',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'What the demos look like with the system setting on: every '
            'block is simply in place.',
            style: TextStyle(fontSize: 13, color: Color(0x99FFFFFF)),
          ),
        ),
      ),
    );
  }
}

/// A demo filling the window, with a title and a way back over it.
class _Screen extends StatelessWidget {
  const _Screen({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: _dusk,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: child,
    );
  }
}

/// A line of prose over the blocks, saying what to look for.
class _Lead extends StatelessWidget {
  const _Lead(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          height: 1.5,
          color: Color(0xB3FFFFFF),
        ),
      ),
    );
  }
}

/// Room to scroll before the first block, so it comes in from below rather
/// than being on screen when the page opens.
class _Gap extends StatelessWidget {
  const _Gap();

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: MediaQuery.sizeOf(context).height * 0.6);
}

/// A note as a row, inset from the edges of the page.
class _Row extends StatelessWidget {
  const _Row(this.note, {this.label});

  final _Note note;

  /// A tag over the title, naming what the row shows, `null` for none.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final String? label = this.label;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: note.dot,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (label != null) ...<Widget>[
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                          color: note.dot,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      note.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      note.detail,
                      style: const TextStyle(fontSize: 13, color: _muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A note as a card, for grids and carousels.
class _Card extends StatelessWidget {
  const _Card(this.note);

  final _Note note;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: note.dot, shape: BoxShape.circle),
          ),
          const Spacer(),
          Text(
            note.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            note.detail,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, height: 1.45, color: _muted),
          ),
        ],
      ),
    );
  }
}

/// The blocks of a page coming in one from the left, the next from the right,
/// the way the sections of a web page often do.
class SidesDemo extends StatelessWidget {
  /// Creates the demo.
  const SidesDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _Screen(
      title: 'From either side',
      child: SmoothWheel(
        builder: (BuildContext context, ScrollController controller) =>
            ListView(
          controller: controller,
          children: <Widget>[
            const _Lead(
              'Scroll down. Each row waits until a fifth of it is on screen, '
              'then fades in from its side.',
            ),
            const _Gap(),
            for (int i = 0; i < 14; i++)
              SimpleReveal(
                slide: i.isEven
                    ? const SlideProperties.fromLeft(120)
                    : const SlideProperties.fromRight(120),
                child: _Row(_noteAt(i)),
              ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}

/// One effect the effects screen shows, and the reveal that shows it.
class _Effect {
  const _Effect(this.label, this.reveal);

  final String label;
  final SimpleReveal Function(Widget child) reveal;
}

final List<_Effect> _effects = <_Effect>[
  _Effect(
    'FADE',
    (Widget child) => SimpleReveal(child: child),
  ),
  _Effect(
    'SLIDE FROM THE BOTTOM',
    (Widget child) => SimpleReveal(
      slide: const SlideProperties.fromBottom(),
      child: child,
    ),
  ),
  _Effect(
    'SLIDE FROM THE START',
    (Widget child) => SimpleReveal(
      slide: const SlideProperties.fromStart(160),
      child: child,
    ),
  ),
  _Effect(
    'ZOOM IN',
    (Widget child) => SimpleReveal(
      zoom: const ZoomProperties(0.6),
      child: child,
    ),
  ),
  _Effect(
    'ZOOM OUT',
    (Widget child) => SimpleReveal(
      zoom: const ZoomProperties(1.3),
      child: child,
    ),
  ),
  _Effect(
    'BLUR',
    (Widget child) => SimpleReveal(
      blur: const BlurProperties(14),
      duration: const Duration(milliseconds: 900),
      child: child,
    ),
  ),
  _Effect(
    'ROTATE',
    (Widget child) => SimpleReveal(
      rotate: const RotateProperties(-0.04, alignment: Alignment.bottomLeft),
      slide: const SlideProperties.fromBottom(40),
      child: child,
    ),
  ),
  _Effect(
    'FLIP ABOUT X',
    (Widget child) => SimpleReveal(
      flip: const FlipProperties.aroundX(
        -0.2,
        alignment: Alignment.topCenter,
      ),
      duration: const Duration(milliseconds: 800),
      child: child,
    ),
  ),
  _Effect(
    'FLIP ABOUT Y',
    (Widget child) => SimpleReveal(
      flip: const FlipProperties.aroundY(0.22),
      duration: const Duration(milliseconds: 800),
      child: child,
    ),
  ),
  _Effect(
    'NO FADE, WITH A BOUNCE',
    (Widget child) => SimpleReveal(
      fade: null,
      zoom: const ZoomProperties(0.4),
      curve: Curves.easeOutBack,
      duration: const Duration(milliseconds: 700),
      child: child,
    ),
  ),
  _Effect(
    'ZOOM, BLUR AND SLIDE',
    (Widget child) => SimpleReveal(
      slide: const SlideProperties.fromRight(),
      zoom: const ZoomProperties(0.85),
      blur: const BlurProperties(8),
      duration: const Duration(milliseconds: 800),
      child: child,
    ),
  ),
];

/// Every effect on a row of its own, named on the row.
class EffectsDemo extends StatelessWidget {
  /// Creates the demo.
  const EffectsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _Screen(
      title: 'Every effect',
      child: SmoothWheel(
        builder: (BuildContext context, ScrollController controller) =>
            ListView(
          controller: controller,
          children: <Widget>[
            const _Lead(
              'Each row is revealed by the effect it names. Any of them combine, '
              'as the last row shows.',
            ),
            const _Gap(),
            for (int i = 0; i < _effects.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: _effects[i].reveal(
                  _Row(_noteAt(i), label: _effects[i].label),
                ),
              ),
            const SizedBox(height: 160),
          ],
        ),
      ),
    );
  }
}

/// A grid whose cards come into view together, row by row, and come in one
/// after the other through a growing delay.
class StaggerDemo extends StatelessWidget {
  /// Creates the demo.
  const StaggerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _Screen(
      title: 'One after the other',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final int columns = (constraints.maxWidth / 260).floor().clamp(2, 4);
          return SimpleRevealGroup(
            interval: const Duration(milliseconds: 120),
            child: SmoothWheel(
              builder: (BuildContext context, ScrollController controller) =>
                  CustomScrollView(
                controller: controller,
                slivers: <Widget>[
                  const SliverToBoxAdapter(
                    child: _Lead(
                      'A row of cards comes into view at once, and a group has '
                      'them come in 120 milliseconds apart, in reading order, '
                      'however many columns the window has room for.',
                    ),
                  ),
                  const SliverToBoxAdapter(child: _Gap()),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        mainAxisExtent: 200,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) => SimpleReveal(
                          slide: const SlideProperties.fromBottom(48),
                          zoom: const ZoomProperties(0.92),
                          child: _Card(_noteAt(index)),
                        ),
                        childCount: columns * 6,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Rows revealed each time they come back into view.
class ReplayDemo extends StatelessWidget {
  /// Creates the demo.
  const ReplayDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _Screen(
      title: 'Every time it comes back',
      child: SmoothWheel(
        builder: (BuildContext context, ScrollController controller) =>
            ListView(
          controller: controller,
          children: <Widget>[
            const _Lead(
              'Scroll down, then back up. A row out of sight is hidden again, '
              'where no one sees it, and comes in again the next time.',
            ),
            const _Gap(),
            for (int i = 0; i < 14; i++)
              SimpleReveal(
                slide: const SlideProperties.fromStart(100),
                blur: const BlurProperties(6),
                once: false,
                child: _Row(_noteAt(i)),
              ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}

/// Cards in a sideways row, in a page: each is revealed once both the page and
/// the row have brought it in.
class CarouselDemo extends StatelessWidget {
  /// Creates the demo.
  const CarouselDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _Screen(
      title: 'A carousel in a page',
      child: SmoothWheel(
        builder: (BuildContext context, ScrollController controller) =>
            ListView(
          controller: controller,
          children: <Widget>[
            const _Lead(
              'Scroll the page to bring the row in, then the row to bring more '
              'cards in. A card has to be seen through both.',
            ),
            const _Gap(),
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: 12,
                itemBuilder: (BuildContext context, int index) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 20,
                  ),
                  child: SizedBox(
                    width: 200,
                    child: SimpleReveal(
                      slide: const SlideProperties.fromEnd(60),
                      zoom: const ZoomProperties(0.9),
                      threshold: 0.5,
                      child: _Card(_noteAt(index)),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.sizeOf(context).height),
          ],
        ),
      ),
    );
  }
}

/// Five hundred rows built as they scroll in, each revealed as it comes.
class BuilderDemo extends StatelessWidget {
  /// Creates the demo.
  const BuilderDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _Screen(
      title: 'Five hundred rows',
      child: SmoothWheel(
        builder: (BuildContext context, ScrollController controller) =>
            ListView.builder(
          controller: controller,
          padding: const EdgeInsets.only(top: 12),
          itemCount: 500,
          itemBuilder: (BuildContext context, int index) => SimpleReveal(
            // Remembers it was revealed once the list has let it go.
            key: PageStorageKey<int>(index),
            slide: const SlideProperties.fromBottom(32),
            duration: const Duration(milliseconds: 450),
            child: _Row(_noteAt(index)),
          ),
        ),
      ),
    );
  }
}

/// Rows from either side again, now as far in as the scroll has brought them.
class ScrubDemo extends StatelessWidget {
  /// Creates the demo.
  const ScrubDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _Screen(
      title: 'Scrubbed',
      child: SmoothWheel(
        builder: (BuildContext context, ScrollController controller) =>
            ListView(
          controller: controller,
          children: <Widget>[
            const _Lead(
              'Scroll slowly, and stop half way. Each row is as far in as the '
              'scroll has brought it, done once its top is half way up, and runs '
              'backwards when scrolled back.',
            ),
            const _Gap(),
            for (int i = 0; i < 14; i++)
              SimpleReveal(
                slide: i.isEven
                    ? const SlideProperties.fromLeft(240)
                    : const SlideProperties.fromRight(240),
                rotate: RotateProperties(i.isEven ? -0.03 : 0.03),
                scrub: const ScrubProperties(reach: 0.5),
                child: _Row(_noteAt(i)),
              ),
            const SizedBox(height: 240),
          ],
        ),
      ),
    );
  }
}

/// Rows that come in on the way up and go out on the way off.
class MirrorDemo extends StatelessWidget {
  /// Creates the demo.
  const MirrorDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _Screen(
      title: 'In and out again',
      child: SmoothWheel(
        builder: (BuildContext context, ScrollController controller) =>
            ListView(
          controller: controller,
          children: <Widget>[
            const _Lead(
              'Each row grows and clears as it comes up, holds in the middle, '
              'and shrinks and softens as it leaves at the top.',
            ),
            const _Gap(),
            for (int i = 0; i < 14; i++)
              SimpleReveal(
                zoom: const ZoomProperties(0.7),
                blur: const BlurProperties(10),
                scrub: const ScrubProperties(
                  reach: 0.3,
                  mirror: true,
                  curve: Curves.easeOut,
                ),
                child: _Row(_noteAt(i)),
              ),
            const SizedBox(height: 240),
          ],
        ),
      ),
    );
  }
}

/// A section of a page as a web builder would lay it out: an overline, a
/// title, a line of text and a button, each coming in its own way, one after
/// the other, once the section is seen.
class _Chapter extends StatelessWidget {
  const _Chapter(this.index);

  final int index;

  @override
  Widget build(BuildContext context) {
    final _Note note = _noteAt(index);
    final bool fromLeft = index.isEven;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(20),
          ),
          // The block itself does not move: only its pieces do, 150
          // milliseconds apart.
          child: SimpleReveal(
            fade: null,
            stagger: const Duration(milliseconds: 150),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                RevealPart(
                  slide: SlideProperties.fromLeft(fromLeft ? 40 : -40),
                  child: Text(
                    'CHAPTER ${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.4,
                      color: note.dot,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Rises out of an invisible line under it.
                RevealPart(
                  fade: null,
                  slide: const SlideProperties.fromBottom(44),
                  clipBehavior: Clip.hardEdge,
                  duration: const Duration(milliseconds: 700),
                  child: Text(
                    note.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                      color: _ink,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                RevealPart(
                  blur: const BlurProperties(6),
                  child: Text(
                    '${note.detail} ${_noteAt(index + 3).detail}',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: _muted,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                RevealPart(
                  zoom: const ZoomProperties(0.6),
                  curve: Curves.easeOutBack,
                  delay: const Duration(milliseconds: 150),
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(backgroundColor: note.dot),
                    child: const Text('Read more'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sections whose pieces come in one after the other.
class PartsDemo extends StatelessWidget {
  /// Creates the demo.
  const PartsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _Screen(
      title: 'Pieces one after the other',
      child: SmoothWheel(
        builder: (BuildContext context, ScrollController controller) =>
            ListView(
          controller: controller,
          children: <Widget>[
            const _Lead(
              'Each section waits to be seen, then its overline, its title, its '
              'text and its button come in 150 milliseconds apart, each its own '
              'way. The button waits a little longer still.',
            ),
            const _Gap(),
            for (int i = 0; i < 6; i++) _Chapter(i),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}

/// A tile to show a tint or a wipe on: a coloured card with a large title, so
/// the shape the tint keeps to can be seen.
class _Tile extends StatelessWidget {
  const _Tile(this.note, this.label);

  final _Note note;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[note.dot, _noteAt(_notes.indexOf(note) + 1).dot],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: Color(0xCCFFFFFF),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            note.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}

/// One tint or wipe of the tints screen, and the reveal that shows it.
class _Tinted {
  const _Tinted(this.label, this.reveal);

  final String label;
  final SimpleReveal Function(Widget child) reveal;
}

final List<_Tinted> _tinted = <_Tinted>[
  _Tinted(
    'DARKENED, CLEARING',
    (Widget child) => SimpleReveal(
      fade: null,
      overlay: const OverlayProperties.darken(0.85),
      duration: const Duration(milliseconds: 1200),
      child: child,
    ),
  ),
  _Tinted(
    'WASHED OUT, CLEARING',
    (Widget child) => SimpleReveal(
      fade: null,
      overlay: const OverlayProperties.lighten(0.9),
      zoom: const ZoomProperties(0.95),
      duration: const Duration(milliseconds: 1000),
      child: child,
    ),
  ),
  _Tinted(
    'WIPED FROM THE START',
    (Widget child) => SimpleReveal(
      fade: null,
      wipe: const WipeProperties.fromStart(),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOutCubic,
      child: child,
    ),
  ),
  _Tinted(
    'OUT FROM UNDER A PANEL',
    (Widget child) => SimpleReveal(
      fade: null,
      wipe: const WipeProperties.fromBottom(color: _ink),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOutQuart,
      child: child,
    ),
  ),
  _Tinted(
    'A CIRCLE OPENING',
    (Widget child) => SimpleReveal(
      fade: null,
      wipe: const WipeProperties.circle(alignment: Alignment.bottomLeft),
      duration: const Duration(milliseconds: 1000),
      child: child,
    ),
  ),
  _Tinted(
    'OPENING FROM THE MIDDLE, TINTED',
    (Widget child) => SimpleReveal(
      fade: null,
      wipe: const WipeProperties.fromCenter(),
      overlay: const OverlayProperties.darken(0.6),
      duration: const Duration(milliseconds: 1000),
      child: child,
    ),
  ),
];

/// Tints that clear and wipes that open.
class TintWipeDemo extends StatelessWidget {
  /// Creates the demo.
  const TintWipeDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return _Screen(
      title: 'Tints and curtains',
      child: SmoothWheel(
        builder: (BuildContext context, ScrollController controller) =>
            ListView(
          controller: controller,
          children: <Widget>[
            const _Lead(
              'A tint keeps to the shape of the card, rounded corners and all, '
              'and clears as it comes in. A wipe uncovers it from an edge, from '
              'a point, or from under a panel.',
            ),
            const _Gap(),
            for (int i = 0; i < _tinted.length; i++)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: _tinted[i].reveal(
                      _Tile(_noteAt(i), _tinted[i].label),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 160),
          ],
        ),
      ),
    );
  }
}

/// A block revealed, hidden and played again from buttons, and counted as it
/// is seen.
class ControllerDemo extends StatefulWidget {
  /// Creates the demo.
  const ControllerDemo({super.key});

  @override
  State<ControllerDemo> createState() => _ControllerDemoState();
}

class _ControllerDemoState extends State<ControllerDemo> {
  final RevealController _manual = RevealController();
  final RevealController _seen = RevealController();

  /// How many times the second block was revealed by being seen.
  final ValueNotifier<int> _views = ValueNotifier<int>(0);

  @override
  void dispose() {
    _manual.dispose();
    _seen.dispose();
    _views.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Screen(
      title: 'From code',
      child: SmoothWheel(
        builder: (BuildContext context, ScrollController controller) =>
            ListView(
          controller: controller,
          padding: const EdgeInsets.only(bottom: 160),
          children: <Widget>[
            const _Lead(
              'The first card waits for its button, wherever it is. The second '
              'is revealed when seen, hides again once out of sight, and counts '
              'how often; its buttons hide it and play it again.',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  FilledButton(
                    onPressed: _manual.reveal,
                    child: const Text('Reveal the first'),
                  ),
                  OutlinedButton(
                    onPressed: _manual.hide,
                    child: const Text('Hide it'),
                  ),
                ],
              ),
            ),
            SimpleReveal(
              controller: _manual,
              manual: true,
              slide: const SlideProperties.fromBottom(40),
              overlay: const OverlayProperties.lighten(0.8),
              child: _Row(_noteAt(0), label: 'MANUAL'),
            ),
            const _Gap(),
            ValueListenableBuilder<int>(
              valueListenable: _views,
              builder: (BuildContext context, int views, Widget? _) => _Lead(
                'Seen $views ${views == 1 ? 'time' : 'times'}. Scroll it out '
                'and back to count again.',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  FilledButton(
                    onPressed: _seen.replay,
                    child: const Text('Play it again'),
                  ),
                  OutlinedButton(
                    onPressed: _seen.hide,
                    child: const Text('Hide it'),
                  ),
                ],
              ),
            ),
            SimpleReveal(
              controller: _seen,
              once: false,
              flip: const FlipProperties.aroundX(-0.2),
              duration: const Duration(milliseconds: 800),
              onReveal: () => _views.value++,
              child: _Row(_noteAt(1), label: 'COUNTED'),
            ),
            SizedBox(height: MediaQuery.sizeOf(context).height),
          ],
        ),
      ),
    );
  }
}
