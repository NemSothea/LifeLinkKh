import 'dart:ui' show Locale;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'locale_store.dart';

part 'locale_controller.g.dart';

/// Overridden in `main.dart` with the `SharedPreferences`-backed store. The default is
/// deliberately the forgetful one, so no test has to stub a platform channel to build a
/// screen.
@Riverpod(keepAlive: true)
LocaleStore localeStore(LocaleStoreRef ref) => InMemoryLocaleStore();

/// The app's language, and the only thing that decides it.
///
/// `FR-GLOBAL-001`'s mobile half. Khmer is the default — the users are Cambodian
/// (`docs/po/prd.md` section 5), and the web portal's `routing.ts` says the same with
/// `defaultLocale: 'km'`. What was missing until now was the other half of that
/// sentence: a way for someone whose Khmer is weak to say so. `MaterialApp.locale` was
/// pinned to `Locale('km')` with no override anywhere, which meant an English speaker
/// could not read a single screen of this app.
///
/// Device locale is deliberately *not* consulted. Most phones in the pilot are set to
/// English regardless of what their owner reads most comfortably, which is exactly the
/// resolution this pin was added to defeat.
@Riverpod(keepAlive: true)
class LocaleController extends _$LocaleController {
    /// The one list. `MaterialApp.supportedLocales` and the `MeTab` toggle both read it,
    /// so adding a third language is one edit, not three.
    static const List<Locale> supported = [Locale('km'), Locale('en')];

    static const Locale fallback = Locale('km');

    @override
    Locale build() {
        final stored = ref.read(localeStoreProvider).read();
        // A stored code this build no longer supports (a language removed in a later
        // release) resolves to nothing — fall back rather than render every string as
        // its key.
        return stored != null && supported.contains(stored) ? stored : fallback;
    }

    /// Switches the app's language, then persists it.
    ///
    /// That order is intentional: the toggle repaints the whole app on the next frame,
    /// and making that wait on a disk write would put a visible stall behind a control
    /// whose entire job is to feel instant. A failed write costs the choice at next
    /// launch, not this one.
    Future<void> select(Locale locale) async {
        if (!supported.contains(locale) || locale == state) return;
        state = locale;
        await ref.read(localeStoreProvider).write(locale);
    }
}
