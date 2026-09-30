# simple_reveal_example

Rows from either side, then a section whose pieces follow one another:

```dart
import 'package:flutter/material.dart';
import 'package:simple_reveal/simple_reveal.dart';

void main() => runApp(const MaterialApp(home: Scaffold(body: Sections())));

class Sections extends StatelessWidget {
  const Sections({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        for (int i = 0; i < 12; i++)
          SimpleReveal(
            slide: i.isEven
                ? const SlideProperties.fromLeft()
                : const SlideProperties.fromRight(),
            child: Card(child: ListTile(title: Text('Row $i'))),
          ),
        SimpleReveal(
          fade: null,
          stagger: const Duration(milliseconds: 150),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const RevealPart(
                slide: SlideProperties.fromBottom(30),
                child: Text('Our story', style: TextStyle(fontSize: 32)),
              ),
              const RevealPart(
                blur: BlurProperties(6),
                child: Text('Three pieces, one after the other.'),
              ),
              RevealPart(
                zoom: const ZoomProperties(0.6),
                curve: Curves.easeOutBack,
                child: FilledButton(
                  onPressed: () {},
                  child: const Text('Read more'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

## The example app

One app, twelve screens, reachable from a menu: a whole page first, then timed reveals and reveals
that follow the scroll:

| Screen | Shows |
| --- | --- |
| `ShowcaseDemo` | A travel page put together from all of it: a photo settling, a title in pieces, wiped photos, a group of cards and a scrubbed photo |
| `SidesDemo` | Rows coming in from the left, then from the right |
| `EffectsDemo` | Every effect on a row of its own, then a bounce and a combination |
| `StaggerDemo` | A grid in slivers whose cards come in in turn, through a `SimpleRevealGroup` |
| `PartsDemo` | Sections whose overline, title, text and button come in one after the other, as `RevealPart`s |
| `TintWipeDemo` | Tints that clear and wipes that open, from an edge, a point, a circle or under a panel |
| `ControllerDemo` | A manual block revealed from a button, and one hidden, played again and counted |
| `ReplayDemo` | `once: false`, rows played again each time they come back |
| `CarouselDemo` | Cards in a sideways row inside a page, revealed once both bring them in |
| `BuilderDemo` | Five hundred rows from `ListView.builder`, remembered through a `PageStorageKey` |
| `ScrubDemo` | Rows from either side, as far in as the scroll has brought them |
| `MirrorDemo` | Rows revealed on the way up and hidden again on the way off |

The menu also carries a Reduce motion switch. It stands in for the system setting, through
`MediaQuery`, so every screen can be seen the way someone who turned that setting on sees it.

The screens showing one feature each live in [lib/main.dart](lib/main.dart), which opens on a menu
listing them. The travel page is a composition rather than a feature, with a look of its own, so it
has its own file, [lib/showcase.dart](lib/showcase.dart), and its photo in `assets/images/`.
The whole app runs in the browser as the [live demo](https://packages.comapps.be/simple_reveal/).

Every screen scrolls on a `SmoothWheel` (in [lib/smooth_wheel.dart](lib/smooth_wheel.dart)), which
eases each mouse wheel notch in rather than landing it in one step, and lands it at once under
reduced motion. The sideways carousel is left alone, so a wheel over it scrolls the page.

`_DragScrollBehavior` adds the mouse to `dragDevices` for the whole app. Flutter leaves dragging to
touch, stylus and trackpad, which on a desktop leaves a sideways list with nothing to drag. It is an
app-wide decision, so the package does not make it for you.

```sh
flutter run
```
