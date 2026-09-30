// A walk through the donor app for the README screenshots, on a real device.
//
// Nothing outside an iOS app can tap a real iPhone, so this test does the tapping and holds
// each screen long enough for the Mac to capture it (pymobiledevice3 screenshots, taken from
// outside, so the status bar is in them like the Android shots). Run it on the showcase seed,
// signed in as the `--me` donor, in profile mode so there is no DEBUG banner:
//
//   flutter drive --profile -d <iphone-id> \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshot_tour_test.dart \
//     --dart-define=FIRESTORE_EMULATOR=<mac-lan-ip>:8081 --dart-define=PORTAL_URL=http://<mac-lan-ip>:3001
//
// It signs out at the end, to show the sign-in screen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lifelink_kh/main.dart' as app;

void main() {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();

    testWidgets('screenshot tour', (tester) async {
        // The app installs its own crash handlers; hand the test's back at the end.
        final testOnError = FlutterError.onError;

        Future<void> hold([int seconds = 5]) async {
            await Future<void>.delayed(Duration(seconds: seconds));
            await tester.pump();
        }

        /// Pumps until [finder] shows up. Startup — Firebase, the session restore, Home's
        /// first reads over the LAN — takes a variable while on a real phone.
        Future<void> waitFor(Finder finder, {int seconds = 45}) async {
            final end = DateTime.now().add(Duration(seconds: seconds));
            while (finder.evaluate().isEmpty) {
                if (DateTime.now().isAfter(end)) throw StateError('timed out waiting for $finder');
                await Future<void>.delayed(const Duration(milliseconds: 500));
                await tester.pump();
            }
        }

        Future<void> tapKey(String key) async {
            final finder = find.byKey(Key(key));
            await tester.ensureVisible(finder);
            await tester.tap(finder);
            await tester.pump(const Duration(milliseconds: 600));
        }

        // The app's own AppBar back arrow — Material on both platforms, which is why the
        // test binding's `pageBack` (it looks for the Cupertino one on iOS) cannot be used.
        Future<void> back() async {
            await tester.tap(find.byType(BackButton).first);
            await tester.pump(const Duration(milliseconds: 600));
        }

        final alert = find.byWidgetPredicate(
            (w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('donor-home-match-'),
        );

        await app.main();
        // A fresh install or a sign-out shows the intro first; skip past it.
        await hold(6);
        if (find.text('រំលង').evaluate().isNotEmpty) {
            await tester.tap(find.text('រំលង'));
            await tester.pump(const Duration(milliseconds: 600));
        }
        if (find.byKey(const Key('sign-in-google')).evaluate().isNotEmpty) {
            throw StateError('Signed out — sign in on the phone once, then run the tour again.');
        }
        await waitFor(find.byKey(const Key('dashboard-tab-home')));
        await waitFor(alert); // Home is only worth a picture once the alerts are in
        await hold(3);

        // Home, then a little further down it.
        await hold();
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
        await hold();
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 500));
        await hold(2);

        // The first alert.
        await tester.tap(alert.first);
        await tester.pump(const Duration(milliseconds: 600));
        await hold();
        await back();
        await hold(2);

        await tapKey('dashboard-tab-history');
        await waitFor(find.textContaining('Calmette Hospital'));
        await hold();

        await tapKey('dashboard-tab-me');
        await hold();

        // The avatar picker, male then female, then closed.
        await tapKey('me-avatar');
        await hold();
        await tester.tap(find.byIcon(Icons.female));
        await tester.pump(const Duration(milliseconds: 600));
        await hold(6);
        await tester.tapAt(const Offset(20, 80)); // the barrier above the sheet
        await tester.pump(const Duration(milliseconds: 600));
        await hold(2);

        await tapKey('me-donor-profile');
        await hold();
        await back();
        await hold(2);

        // English, Home in English, then back to Khmer.
        await tester.tap(find.text('English'));
        await tester.pump(const Duration(milliseconds: 600));
        await hold(2);
        await tapKey('dashboard-tab-home');
        await hold();
        await tapKey('dashboard-tab-me');
        await hold(2);
        await tester.tap(find.text('ខ្មែរ'));
        await tester.pump(const Duration(milliseconds: 600));
        await hold(2);

        // Sign out, and the sign-in screen.
        await tapKey('sign-out');
        await waitFor(find.byKey(const Key('sign-in-google')), seconds: 30);
        await hold(6);

        FlutterError.onError = testOnError;
    });
}
