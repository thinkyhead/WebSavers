# WebSavers

WebKit-based screensavers for macOS implemented as HTML/CSS/JS in an Xcode project.

Adapted from [WebSaver](//github.com/brockgr/websaver) by @brockgr, *et.al.*, and modified to use a local `index.html` file loaded from each bundle's Resources.

Every saver is a separate `.saver` bundle (separate Xcode target) that shares the same base `WebSaverView` code plus a per-saver subclass that builds its own Options sheet.

## The Savers

`main` ships **nine** savers:

| Target | Display name | Theme |
|---|---|---|
| Matrix | Matrix | "Matrix Rain" HTML Canvas example, plus a scanline overlay |
| Matrix3D | Matrix 3D | Matrix Rain applied to the faces of a rotating cube (THREE.js) |
| MatrixGrid | Matrix Grid | Re-implementation of Matrix using CSS animations — a fixed grid of DIVs animated by `innerHTML`, `opacity`, `display`, `color` ([demo](https://www.thinkyhead.com/pub/MatrixGrid/index.html)) |
| Starfield | Starfield | Starfield animation (adapted from a [CodePen sketch](//codepen.io/nodws/pen/pejBNb), based on [demo code](//github.com/curran/HTML5Examples/tree/gh-pages/canvas/starfield) by @curran) |
| Stringy | Stringy | 3D "Strings" animation (adapted from a [CodePen sketch](//codepen.io/yashbhardwaj/pen/QWKKgb)) |
| VibeToroid | Toroid Vibe | Torus knot that morphs through 9 (p,q) winding-number shapes |
| VibeOrbit | Orbital Vibe | Orbital Vibe — glowing spheres |
| VibeSolarSystem | Solar System Vibe | "Solar System Vibe" |
| VibeSpheres | Spheres Vibe | Cyberpunk spheres |

The **HermesBoard** (live information dashboard driven by Hermes) and **P5Alert** (p5.js flow-field) savers are developed on the `hermesboard-dojo` feature branch.

## Configuration (Options sheets)

All savers expose an **Options** sheet (`hasConfigureSheet` returns YES) built programmatically — no nibs. Settings are applied to the running WebView via `window.applySettings(s)` injected with `evaluateJavaScript:`. Settings persist per-display via `ScreenSaverDefaults` (`com.thinkyhead.saver.<ClassName>.<CGDirectDisplayID>`), so each screen's saver has independent options.

The base `WebSaverView.m` builds the shared sheet window (OK/Cancel + per-saver controls); each saver subclass (`Matrix/MatrixView.m`, etc.) implements `buildConfigSheet`, `loadDefaultsIntoSheet`, `saveConfigSheet`, and `settingsJS`.

## Architecture

- `WebSaverView.h/.m` — base `WebSaverView : ScreenSaverView`. Owns the `WKWebView`, loads `index.html` from the bundle on `startAnimation`, injects `applySettings` JS after page load, and provides the config-sheet infrastructure. Disables window-occlusion detection so the view keeps animating behind the ScreenSaverEngine hierarchy. On `com.apple.screensaver.willstop` it calls `exit(0)` only when **not** in preview (`if (self.isPreview) return;`).
- `<Name>/<Name>View.m` — one subclass per saver implementing its Options-sheet controls/defaults/JS. Compiled into its target alongside the base, giving each bundle a distinct `NSPrincipalClass` (`MatrixView`, `Matrix3DView`, ...).
- `WKWebViewPrivate.h/.m` — private WebKit API shim for the occlusion-detection toggle.
- `WebSaver_Prefix.pch`, shared `Info.plist` (`NSPrincipalClass = $(WEBSAVER_CLASS)`), `Base.lproj/InfoPlist.strings`, `License.txt`.

## Build and Install

Build one target from the command line:

```
xcodebuild -project WebSavers.xcodeproj -scheme Matrix -configuration Release \
  -derivedDataPath /tmp/ws_dd \
  CODE_SIGN_IDENTITY="Apple Development: <Your Name> (<TEAMID>)" build
```

**Code signing matters.** macOS 26.5.2+ rejects ad-hoc-signed bundles (ScreenSaverEngine kills them with SIGKILL / "Code Signature Invalid"). Build with your Apple Development identity so the bundle gets a proper signature with a Team ID.

Install to the canonical location `/Library/Screen Savers/` (root-owned, requires sudo). Do not leave duplicate bundles in `~/Library/Screen Savers/`. After installing or switching savers, `killall ScreenSaverEngine` (and relaunch System Settings) so the new selection registers.

Alternatively open `WebSavers.xcodeproj` in Xcode, pick a scheme, and Build → Run; the `.saver` lands in the "Products" group. Double-click a `.saver` to install it.

## Add a ScreenSaver

- Create a fresh target (do **not** duplicate an existing one — duplicates carry over stale resource references).
- Add a per-saver subclass source file `<Name>/<Name>View.m` (mirror an existing one, e.g. `Matrix/MatrixView.m`).
- Set `WEBSAVER_CLASS = <Name>View`, `PRODUCT_BUNDLE_IDENTIFIER = com.thinkyhead.saver.<Name>`, `INFOPLIST_FILE = Info.plist`, `GENERATE_INFOPLIST_FILE = NO`, `WRAPPER_EXTENSION = saver` in the target's Debug + Release configs.
- Compile `WebSaverView.m` + `WKWebViewPrivate.m` + your subclass in the target; set `GCC_PREFIX_HEADER = WebSaver_Prefix.pch`; link ScreenSaver, WebKit, Cocoa, Foundation, AppKit, and IOKit frameworks.
- Drop a folder with your new `index.html` (+ assets) into Resources, restricted to the new target.
- Add a scheme (Product → Scheme → New Scheme) and add it to the "All Savers" aggregate scheme's Build list (Run + Archive only).

See the `websavers` skill for the full Xcode project recipe.
