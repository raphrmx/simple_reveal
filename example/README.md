# simple_reveal_example

One app, eleven screens, reachable from a menu grouped by timed reveals and reveals that follow the
scroll:

| Screen | Shows |
| --- | --- |
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

They all live in [lib/main.dart](lib/main.dart), which opens on a menu listing them. pub.dev renders
that single file on the example tab, which is why they are not split across several.

`_DragScrollBehavior` adds the mouse to `dragDevices` for the whole app. Flutter leaves dragging to
touch, stylus and trackpad, which on a desktop leaves a sideways list with nothing to drag. It is an
app-wide decision, so the package does not make it for you.

```sh
flutter run
```
