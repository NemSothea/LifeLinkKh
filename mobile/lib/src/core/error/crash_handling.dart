import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../widgets/screen_failure.dart';

/// Installs the app-wide safety net. Called once, from `main`, before `runApp`.
///
/// Three kinds of error escape a screen's own handling, and each had a bad default:
///
/// - **A widget that throws while building.** Flutter paints a red box in debug and a
///   plain grey rectangle in release — a donor sees a broken screen with nothing on it.
///   Release builds now show [ScreenFailure] instead: what happened and what to do.
///   Debug keeps the red box, because a developer needs the stack trace, not reassurance.
/// - **A framework error** (layout, painting, a gesture callback). Logged through
///   [FlutterError.presentError], same as the default, so it still reaches `adb logcat`.
/// - **An uncaught async error** (a `Future` nobody awaited). Logged, and marked handled
///   so it does not take the isolate down.
///
/// Nothing is sent anywhere. There is no crash-reporting service in this build — adding
/// one is a dependency and a privacy decision, not a default.
void installCrashHandlers() {
    FlutterError.onError = (details) {
        FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('Uncaught async error: $error\n$stack');
        return true;
    };

    ErrorWidget.builder = (details) => buildErrorWidget(details, debug: kDebugMode);
}

/// What replaces a widget that threw during build. Split out so a test can check both
/// branches without flipping the global.
Widget buildErrorWidget(FlutterErrorDetails details, {required bool debug}) =>
    debug ? ErrorWidget(details.exception) : const ScreenFailure();
