import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_providers.g.dart';

/// True while the phone has no network interface up at all — airplane mode, wifi and
/// mobile data both off. What the offline banner reads.
///
/// An interface, not the internet: a phone on hotel wifi with no uplink reports
/// "connected" here. That case still lands on the section's own [NetworkFailure] copy
/// after the Dio timeout, so the banner only has to be right when it *does* show.
///
/// A plugin that is not there (every widget test) reads as online: a banner that
/// appears in tests because a platform channel is missing would be a lie.
@Riverpod(keepAlive: true)
Stream<bool> isOffline(IsOfflineRef ref) async* {
    final connectivity = Connectivity();
    try {
        yield _noInterface(await connectivity.checkConnectivity());
    } on Object {
        yield false;
        return;
    }
    yield* connectivity.onConnectivityChanged
        .map(_noInterface)
        .handleError((Object _) {});
}

bool _noInterface(List<ConnectivityResult> results) =>
    results.every((result) => result == ConnectivityResult.none);
