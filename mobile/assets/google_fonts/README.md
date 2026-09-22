# Bundled fonts

Inter and Kantumruy Pro, committed rather than downloaded at runtime.

`google_fonts` fetches from `fonts.gstatic.com` on first use and caches on the device.
That is two problems for this app. On a phone in Phnom Penh with no signal — the exact
situation the offline-first work is for — the fetch fails and every screen renders in the
platform fallback font, which for Khmer means tofu boxes on a blood request. And in CI it
fails too: `test/flutter_test_config.dart` turns runtime fetching off, so the golden tests
rendered macOS fallbacks locally and DejaVu on the Linux runner, and the goldens diffed by
12,132 pixels on a change that touched neither fonts nor UI.

`google_fonts` prefers a bundled asset over the network when the filename matches
`<Family>-<Variant>.ttf` (`findFamilyWithVariantAssetPath` in `google_fonts_base.dart`),
so the names here are load-bearing — renaming a file silently puts the network back in
the path.

These are the exact bytes `google_fonts` 8.2.1 would have downloaded: each file was
fetched from `https://fonts.gstatic.com/s/a/<hash>.ttf` using the hash in the package's
own variant map, and verified with `shasum -a 256` against that same hash.

| File | SHA-256 (also the gstatic path) |
|------|---------------------------------|
| `Inter-Regular.ttf` | `15b294b67f2f8bbc04d990023ef4aec66502b87dc9040d84abe5f896ccb693de` |
| `Inter-SemiBold.ttf` | `334bb2c51aeba5f566abac8d03a7e75ab3234d6926b52e92a85dc704129258b5` |
| `KantumruyPro-Regular.ttf` | `e74b62d542d5b45c3bc17ad07aa231bd62003ba4eefd1a8954e12e5ffd06ce61` |

Only the three weights the app actually renders are bundled — w400 and w600 Latin, w400
Khmer — because each Inter weight is ~325 KB. A new weight used in the UI will quietly go
back to fetching at runtime; add its file here when that happens. The variant map in
`~/.pub-cache/hosted/pub.dev/google_fonts-8.2.1/lib/src/google_fonts_parts/part_*.dart`
has the hash.

Both families are SIL Open Font License 1.1 — `OFL-Inter.txt`, `OFL-KantumruyPro.txt`.
