# Launcher artwork

Source images for the app icon on both platforms. Committed, not generated at build
time — a launcher icon is a release artifact, and a build that reaches for a rendering
toolchain to produce one fails on the machine that does not have it.

## What these are

| File | Used for |
|---|---|
| `icon.png` | 1024×1024 master. iOS app icon, and the fallback for anything unspecified |
| `icon-round.png` | The same mark clipped to a circle — legacy Android launcher bitmap |
| `icon-adaptive-foreground.png` | Android adaptive foreground: droplet only, transparent |
| `icon-adaptive-background.png` | Android adaptive background: the gradient, no droplet |
| `splash.png` / `splash-dark.png` | Native launch screen art (Android ≤11, iOS), light and dark. Rendered from `BrandBadge` — see "Launch screen" below |
| `play-store-512.png` | The 512×512 the Play Console store listing asks for. Not consumed by any build — upload it by hand at deploy-runbook step 7 |

## Where the mark comes from

`Icons.bloodtype` (codepoint `0xe0e3`) in white, on the radial gradient `_BrandBadge`
draws in `sign_in_screen.dart`: `AppTheme._seed` (`0xFFC62828`) to
`Color.lerp(seed, black, 0.25)`.

Rendered from the same `MaterialIcons-Regular.otf` the app itself ships, so the
launcher icon and the sign-in badge are one mark rather than two drawings that drift.
It is not hand-traced — changing the badge and re-running the generator keeps them
together.

## Regenerating

The icons under `android/` and `ios/` are generated from these files:

```bash
cd mobile
dart run flutter_launcher_icons
```

Config lives in `pubspec.yaml` under `flutter_launcher_icons:`.

**Check `ios/Runner.xcodeproj/project.pbxproj` afterwards.** flutter_launcher_icons
0.14.4 also writes `AppIcon` into
`ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS`, which is a YES/NO
setting — it means to set `ASSETCATALOG_COMPILER_APPICON_NAME` and hits the wrong key
in two of the three build configurations. Revert that hunk; leave the
`ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` lines alone, they are correct and were
already there.

To change the mark itself, edit `_BrandBadge` and re-render the source art — the
script that produced these files is in the icon commit's message.

## Launch screen

What shows before Flutter draws its first frame — it used to be `flutter create`'s blank
white window. Config lives in `pubspec.yaml` under `flutter_native_splash:`.

```bash
cd mobile
flutter test tool/render_splash_art.dart     # re-renders splash*.png from BrandBadge
dart run flutter_native_splash:create        # writes android/ and ios/ resources
```

- **Colours must be the theme's `surface`.** The render script prints both; `color` /
  `color_dark` in `pubspec.yaml` must match, or the hand-off to Flutter shows a seam.
- **Android 12+ ignores `splash.png`.** The OS draws the launcher icon in a circle itself,
  so `android_12:` reuses `icon-adaptive-foreground.png` on the badge red.
- **`create` rewrites `ios/Runner/Info.plist`** to add `UIStatusBarHidden = false` (the
  default) and reindents the whole file. Revert that file; nothing in it is needed.
- The splash is **held past the first frame** (`main.dart` → `FlutterNativeSplash.preserve`)
  until `LifeLinkApp` sees the session restore resolve, with a 4 s backstop.

## Constraints worth not rediscovering

- **No alpha on the iOS icon.** The App Store rejects an app icon with an alpha
  channel; `remove_alpha_ios: true` in the config handles it, and `icon.png` is opaque
  to begin with.
- **The adaptive foreground is small on purpose.** Only the middle ~66% of an adaptive
  layer is guaranteed visible — the launcher masks the rest and animates into it on
  press. The droplet is sized against that safe zone, not the full canvas, which is
  why it looks undersized when you open the file on its own and correct on a device.
- **Android needs both.** The legacy bitmap serves pre-Android 8; the adaptive pair
  serves everything since. Ship only the bitmap and a round-mask launcher crops the
  droplet itself.
