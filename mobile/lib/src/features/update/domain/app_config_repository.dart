import '../../../core/error/result.dart';
import 'app_config.dart';

/// Reading `config/app`, as the rest of the app sees it.
abstract interface class AppConfigRepository {
    /// One read, no listener: the document changes a few times a year, and a snapshot
    /// listener on every running phone would spend the Firestore free tier on nothing.
    ///
    /// A missing document is `Success(AppConfig.none)`, not a failure — it is the normal
    /// state before the first release script runs.
    Future<Result<AppConfig>> fetch();
}

/// The default binding: no update information, ever. Same seam shape as
/// `pushArrivalsProvider` — `main.dart` overrides it with the Firestore one, so no
/// widget test that boots the app reaches Firestore through a startup read.
final class UnconfiguredAppConfigRepository implements AppConfigRepository {
    const UnconfiguredAppConfigRepository();

    @override
    Future<Result<AppConfig>> fetch() async => const Success(AppConfig.none);
}
