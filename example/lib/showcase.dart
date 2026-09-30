import 'package:flutter/material.dart';
import 'package:simple_reveal/simple_reveal.dart';

import 'smooth_wheel.dart';

const String _photo = 'assets/images/trail.webp';

const Color _paper = Color(0xFFF6F1EA);
const Color _sand = Color(0xFFEDE4D8);
const Color _ink = Color(0xFF1D1712);
const Color _muted = Color(0xFF6F665E);
const Color _accent = Color(0xFFD9692E);
const Color _night = Color(0xFF1A1411);

/// The width from which sections sit side by side rather than stacked.
const double _wide = 760;

/// A page of a travel site, the way a landing page reveals its sections: every
/// block and every piece of text on it is a [SimpleReveal] or a [RevealPart].
class ShowcaseDemo extends StatelessWidget {
  /// Creates the demo.
  const ShowcaseDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: Stack(
        children: <Widget>[
          SmoothWheel(
            builder: (BuildContext context, ScrollController controller) =>
                ListView(
              controller: controller,
              padding: EdgeInsets.zero,
              children: const <Widget>[
                _Hero(),
                _Intro(),
                _Stats(),
                _Feature(
                  index: 0,
                  overline: 'DAY ONE',
                  title: 'Through the long grass',
                  text:
                      'The path leaves the village by the old mill and climbs '
                      'through meadows that come up to the waist by June. Keep '
                      'to the trail: the grass hides the ditches.',
                  alignment: Alignment(-1, 0.1),
                  closer: 2,
                  wipe: WipeProperties.fromStart(),
                ),
                _Feature(
                  index: 1,
                  overline: 'DAY TWO',
                  title: 'Over the pass',
                  text: 'A steady climb to the col, then the refuge a little '
                      'below it. There is water there only, so fill up before '
                      'the last stretch, and book ahead in August.',
                  alignment: Alignment(0.8, -0.5),
                  closer: 1.6,
                  mirrored: true,
                  wipe: WipeProperties.circle(),
                ),
                _Feature(
                  index: 2,
                  overline: 'DAY THREE',
                  title: 'Down to the lake',
                  text: 'The descent follows the stream through the pines to '
                      'the shore. The last bus leaves at ten past seven, from '
                      'the stop by the jetty.',
                  alignment: Alignment(0, 0.95),
                  wipe: WipeProperties.fromBottom(color: _night),
                ),
                _Pack(),
                _Closing(),
                _Footer(),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: const Color(0x59000000),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Whether the page is wide enough to set sections side by side.
bool _isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= _wide;

/// A crop of the trail photo, filling its box.
class _Photo extends StatelessWidget {
  const _Photo({
    this.alignment = Alignment.center,
    this.mirrored = false,
    this.closer = 1,
    this.radius = 0,
  });

  final Alignment alignment;
  final bool mirrored;

  /// How much closer than the whole photo the crop is, about [alignment].
  final double closer;

  final double radius;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      _photo,
      fit: BoxFit.cover,
      alignment: alignment,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
    );
    if (closer != 1) {
      image =
          Transform.scale(scale: closer, alignment: alignment, child: image);
    }
    if (mirrored) image = Transform.flip(flipX: true, child: image);
    if (radius == 0) return ClipRect(child: image);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: image,
    );
  }
}

/// Content kept to a readable width, centred, with room on either side.
class _Band extends StatelessWidget {
  const _Band({
    required this.child,
    this.color,
    this.top = 96,
    this.bottom = 96,
  });

  final Widget child;
  final Color? color;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    final double side = _isWide(context) ? 56 : 24;
    return ColoredBox(
      color: color ?? _paper,
      child: Padding(
        padding: EdgeInsets.fromLTRB(side, top, side, bottom),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// The photo settling into place as the page opens, and its title coming in
/// piece by piece over it.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool wide = size.width >= _wide;
    return SizedBox(
      height: (size.height * 0.9).clamp(440.0, 820.0),
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const SimpleReveal(
              fade: null,
              zoom: ZoomProperties(1.2),
              overlay: OverlayProperties.darken(0.8),
              duration: Duration(milliseconds: 2400),
              curve: Curves.easeOutCubic,
              child: _Photo(alignment: Alignment(0, -0.35)),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: <double>[0.25, 0.6, 1],
                  colors: <Color>[
                    Color(0x00140F0C),
                    Color(0x40140F0C),
                    Color(0xE6140F0C),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                wide ? 72 : 24,
                0,
                wide ? 72 : 24,
                wide ? 80 : 44,
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: SimpleReveal(
                    fade: null,
                    delay: const Duration(milliseconds: 300),
                    stagger: const Duration(milliseconds: 160),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const RevealPart(
                          slide: SlideProperties.fromStart(40),
                          child: Text(
                            'THREE DAYS IN THE HILLS',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3,
                              color: Color(0xCCFFFFFF),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Rises out of an invisible line under it.
                        RevealPart(
                          fade: null,
                          slide: SlideProperties.fromBottom(wide ? 84 : 56),
                          clipBehavior: Clip.hardEdge,
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          child: Text(
                            'The southern pass',
                            style: TextStyle(
                              fontSize: wide ? 68 : 42,
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                              letterSpacing: wide ? -2 : -1,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const RevealPart(
                          blur: BlurProperties(8),
                          duration: Duration(milliseconds: 800),
                          child: Text(
                            'Eleven kilometres of trail, a refuge below the col '
                            'and a lake at the end of it.',
                            style: TextStyle(
                              fontSize: 18,
                              height: 1.5,
                              color: Color(0xE6FFFFFF),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        RevealPart(
                          zoom: const ZoomProperties(0.6),
                          curve: Curves.easeOutBack,
                          delay: const Duration(milliseconds: 120),
                          child: FilledButton(
                            onPressed: () {},
                            style: FilledButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 26,
                                vertical: 18,
                              ),
                            ),
                            child: const Text(
                              'Plan the walk',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A statement from one side and a paragraph from the other.
class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    final bool wide = _isWide(context);
    const Widget statement = SimpleReveal(
      slide: SlideProperties.fromLeft(60),
      duration: Duration(milliseconds: 800),
      child: Text(
        'A walk that starts in the grass and ends at the water.',
        style: TextStyle(
          fontSize: 36,
          height: 1.2,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
          color: _ink,
        ),
      ),
    );
    final Widget paragraph = SimpleReveal(
      slide: const SlideProperties.fromRight(60),
      delay: Duration(milliseconds: wide ? 200 : 0),
      duration: const Duration(milliseconds: 800),
      child: const Text(
        'The trail climbs through the long grass of the lower slopes, crosses '
        'the pass by the old refuge and drops to the lake in the afternoon. '
        'Nothing technical, only long, and best walked over three days.',
        style: TextStyle(fontSize: 17, height: 1.65, color: _muted),
      ),
    );
    return _Band(
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Expanded(flex: 5, child: statement),
                const SizedBox(width: 64),
                Expanded(flex: 4, child: paragraph),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                statement,
                const SizedBox(height: 24),
                paragraph,
              ],
            ),
    );
  }
}

/// Three figures, coming up one after the other.
class _Stats extends StatelessWidget {
  const _Stats();

  static const List<(String, String)> _figures = <(String, String)>[
    ('11 km', 'from the mill to the jetty'),
    ('1,240 m', 'climbed on the second day'),
    ('3 days', 'with two nights under a roof'),
  ];

  @override
  Widget build(BuildContext context) {
    final bool wide = _isWide(context);
    return _Band(
      color: _sand,
      top: 64,
      bottom: 64,
      child: SimpleRevealGroup(
        interval: const Duration(milliseconds: 140),
        child: Flex(
          direction: wide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (int i = 0; i < _figures.length; i++) ...<Widget>[
              if (i > 0) SizedBox(width: 40, height: wide ? 0 : 32),
              _flexed(
                wide,
                SimpleReveal(
                  slide: const SlideProperties.fromBottom(36),
                  zoom: const ZoomProperties(
                    0.9,
                    alignment: Alignment.bottomLeft,
                  ),
                  child: _Figure(_figures[i].$1, _figures[i].$2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _flexed(bool wide, Widget child) =>
      wide ? Expanded(child: child) : child;
}

class _Figure extends StatelessWidget {
  const _Figure(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 18),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x33000000))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              fontSize: 48,
              height: 1.1,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.5,
              color: _accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 15, color: _muted)),
        ],
      ),
    );
  }
}

/// A photo uncovered by a wipe beside a text whose pieces follow it in.
class _Feature extends StatelessWidget {
  const _Feature({
    required this.index,
    required this.overline,
    required this.title,
    required this.text,
    required this.alignment,
    required this.wipe,
    this.closer = 1,
    this.mirrored = false,
  });

  final int index;
  final String overline;
  final String title;
  final String text;
  final Alignment alignment;
  final WipeProperties wipe;
  final double closer;
  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    final bool wide = _isWide(context);
    // The text comes in from the side of the photo.
    final bool photoFirst = index.isEven;
    final Widget photo = SizedBox(
      height: wide ? 380 : 240,
      child: SimpleReveal(
        fade: null,
        wipe: wipe,
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeInOutCubic,
        child: _Photo(
          alignment: alignment,
          mirrored: mirrored,
          closer: closer,
          radius: 24,
        ),
      ),
    );
    final Widget words = SimpleReveal(
      fade: null,
      delay: const Duration(milliseconds: 350),
      stagger: const Duration(milliseconds: 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          RevealPart(
            slide: photoFirst || !wide
                ? const SlideProperties.fromRight(40)
                : const SlideProperties.fromLeft(40),
            child: Text(
              overline,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: _accent,
              ),
            ),
          ),
          const SizedBox(height: 12),
          RevealPart(
            slide: const SlideProperties.fromBottom(28),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 32,
                height: 1.15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
                color: _ink,
              ),
            ),
          ),
          const SizedBox(height: 14),
          RevealPart(
            blur: const BlurProperties(6),
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, height: 1.65, color: _muted),
            ),
          ),
        ],
      ),
    );
    return _Band(
      top: index == 0 ? 96 : 40,
      bottom: 40,
      child: wide
          ? Row(
              children: <Widget>[
                if (photoFirst) Expanded(flex: 6, child: photo),
                if (photoFirst) const SizedBox(width: 64),
                Expanded(flex: 5, child: words),
                if (!photoFirst) const SizedBox(width: 64),
                if (!photoFirst) Expanded(flex: 6, child: photo),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[photo, const SizedBox(height: 28), words],
            ),
    );
  }
}

/// A grid of cards brought in one after the other, in reading order.
class _Pack extends StatelessWidget {
  const _Pack();

  static const List<(IconData, String, String)> _items =
      <(IconData, String, String)>[
    (Icons.hiking, 'Poles', 'For the way down more than the way up.'),
    (Icons.water_drop, 'Two litres', 'Nothing to fill up before the refuge.'),
    (Icons.map, 'A paper map', 'There is no signal along the ridge.'),
    (Icons.flashlight_on, 'A head torch', 'For the refuge, and just in case.'),
    (Icons.cloud, 'A shell', 'The wind turns south after noon.'),
    (Icons.restaurant, 'Lunch', 'The refuge serves soup and little else.'),
  ];

  @override
  Widget build(BuildContext context) {
    return _Band(
      top: 96,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SimpleReveal(
            slide: SlideProperties.fromBottom(30),
            child: Text(
              'What to bring',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
                color: _ink,
              ),
            ),
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              const double gap = 20;
              final int columns = constraints.maxWidth >= 720
                  ? 3
                  : constraints.maxWidth >= 440
                      ? 2
                      : 1;
              final double width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return SimpleRevealGroup(
                interval: const Duration(milliseconds: 100),
                child: Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: <Widget>[
                    for (final (IconData, String, String) item in _items)
                      SizedBox(
                        width: width,
                        child: SimpleReveal(
                          slide: const SlideProperties.fromBottom(40),
                          zoom: const ZoomProperties(0.94),
                          child: _Item(item.$1, item.$2, item.$3),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item(this.icon, this.title, this.detail);

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0x1FD9692E),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _accent, size: 24),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A photo that eases back as the scroll brings it up, under a quote turning
/// into place.
class _Closing extends StatelessWidget {
  const _Closing();

  @override
  Widget build(BuildContext context) {
    final bool wide = _isWide(context);
    return SizedBox(
      height: wide ? 520 : 420,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // Follows the scroll: as far back as the scroll has brought it.
            const SimpleReveal(
              fade: null,
              zoom: ZoomProperties(1.3),
              scrub: ScrubProperties(reach: 0.9),
              child: _Photo(alignment: Alignment(0, -0.6), mirrored: true),
            ),
            const ColoredBox(color: Color(0x8C140F0C)),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: SimpleReveal(
                    fade: null,
                    stagger: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        RevealPart(
                          flip: const FlipProperties.aroundX(
                            -0.22,
                            alignment: Alignment.topCenter,
                          ),
                          duration: const Duration(milliseconds: 900),
                          child: Text(
                            '“Take your time on the ridge. The lake will wait, '
                            'the last bus will not.”',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: wide ? 38 : 28,
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.6,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        const RevealPart(
                          child: Text(
                            'THE REFUGE KEEPER',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3,
                              color: Color(0xB3FFFFFF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return const _Band(
      color: _night,
      top: 56,
      bottom: 72,
      child: SimpleReveal(
        child: Text(
          'Every block and every line on this page comes in through a '
          'SimpleReveal or a RevealPart.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.6, color: Color(0x99FFFFFF)),
        ),
      ),
    );
  }
}
